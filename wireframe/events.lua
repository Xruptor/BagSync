--[[
	events.lua
		Event module for BagSync, captures and processes events
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Events = BSYC:NewModule("Events", 'AceEvent-3.0', 'AceTimer-3.0')
local Unit = BSYC:GetModule("Unit")
local Scanner = BSYC:GetModule("Scanner")
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Events", ...) end
end

Events.canQueryAuctions = false

local alertTooltip = CreateFrame("GameTooltip", "BSYC_EventAlertTooltip", UIParent, "GameTooltipTemplate")
alertTooltip:SetOwner(UIParent, "ANCHOR_NONE")
alertTooltip:SetHeight(30)
alertTooltip:SetClampedToScreen(true)
alertTooltip:SetFrameStrata("FULLSCREEN_DIALOG")
alertTooltip:SetFrameLevel(1000)
alertTooltip:SetToplevel(true)
alertTooltip:ClearAllPoints()
alertTooltip:SetPoint("CENTER", UIParent, "CENTER")
alertTooltip:Hide()
Events.alertTooltip = alertTooltip

local function showEventAlert(text, alertType)
	Debug(2, "showEventAlert", text, alertType)
	
	Events.alertTooltip.alertType = alertType
	Events.alertTooltip:ClearAllPoints()
	Events.alertTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	Events.alertTooltip:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	Events.alertTooltip:ClearLines()
	Events.alertTooltip:AddLine("|cffff6600BagSync|r")
	Events.alertTooltip:AddLine("|cffddff00"..text.."|r")
	Events.alertTooltip:HookScript("OnUpdate", function(self, elapse)
		if self.alertType == "GUILDBANK" and not Unit.atGuildBank then
			self:Hide()
		end
	end)
	Events.alertTooltip:Show()
end

function Events:DoTimer(sName, sFunc, sDelay, sRepeat)
	Debug(3, "DoTimer", sName, sFunc, sDelay, sRepeat)
	
	if not self.timers then self.timers = {} end
	if not sRepeat then
		--stop and delete current timer to recreate
		self:StopTimer(sName)
		self.timers[sName] = self:ScheduleTimer(sFunc, sDelay)
	else
		--don't recreate a repeatingtimer if it already exists.
		if not self.timers[sName] then
			self.timers[sName] = self:ScheduleRepeatingTimer(sFunc, sDelay)
		end
	end
	return self.timers[sName]
end

function Events:StopTimer(sName)
	if not self.timers then return end
	if not sName then return end
	if not self.timers[sName] then return end
	self:CancelTimer(self.timers[sName])
	self.timers[sName] = nil
	Debug(3, "StopTimer", sName)
end

function Events:OnEnable()
	Debug(2, "OnEnable")
	
	self:RegisterEvent("PLAYER_MONEY")
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_GUILD_UPDATE")

	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
	self:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")

	--this event is when we trigger a CheckInbox()
	self:RegisterEvent("MAIL_INBOX_UPDATE", function()
		self:DoTimer("MailBoxScan", function() Scanner:SaveMailbox() end, 0.3)
	end)

	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", function(event, slotID)
		Scanner:SaveBank(true)
		if BSYC.IsRetail then
			--check if they crafted an item outside the bank, if so then do a parse check to update item count.
			self:DoTimer("SaveCraftedReagents", function() Scanner:SaveCraftedReagents() end, 1)
		end
	end)

	--register our custom Event Handlers
	self:RegisterMessage('BAGSYNC_EVENT_MAILBOX')
	self:RegisterMessage('BAGSYNC_EVENT_BANK')
	self:RegisterMessage('BAGSYNC_EVENT_AUCTION')
	self:RegisterMessage('BAGSYNC_EVENT_VOIDBANK')
	self:RegisterMessage('BAGSYNC_EVENT_GUILDBANK')

	--check to see if the ReagentBank is even enabled on server
	if IsReagentBankUnlocked then
		self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED", function(event, slotID)
			Scanner:SaveReagents()
			if BSYC.IsRetail then
				--check if they crafted an item outside the bank, if so then do a parse check to update item count.
				self:DoTimer("SaveCraftedReagents", function() Scanner:SaveCraftedReagents() end, 1)
			end
		end)
		self:RegisterEvent("REAGENTBANK_PURCHASED", function() Scanner:SaveReagents() end)
	end

	--check if voidbank is even enabled on server
	if CanUseVoidStorage then
		--scan when transfers of any kind are done at the void storage
		self:RegisterEvent("VOID_TRANSFER_DONE", function() Scanner:SaveVoidBank() end)
	end

	--check to see if guildbanks are even enabled on server
	if CanGuildBankRepair then
		self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED", function()
			self:DoTimer("GuildBankScan", function() self:GuildBank_Changed() end, 0.2)
		end)
	end

	--only do currency checks if the server even supports it
	if C_CurrencyInfo then
		self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
	end

	if BSYC.IsRetail then
		--save any crafted item info in case they aren't at a bank
		self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(event, unitTarget, castGUID, spellID) Scanner:ParseCraftedInfo(unitTarget, castGUID, spellID) end)
	end

	--Force guild roster update, so we can grab guild name.  Note this is nil on login, have to check for Classic and Retail though
	--https://wowpedia.fandom.com/wiki/API_C_GuildInfo.GuildRoster
	if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end  -- Retail
	if GuildRoster then GuildRoster() end -- Classic
	
	Scanner:StartupScans() --do the login player scans
	
	--BAG_UPDATE fires A LOT during login and when in between loading screens.  In general it's a very spammy event.
	--to combat this we are going to use the DELAYED event which fires after all the BAG_UPDATE are done.  Then go through the spam queue.
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("BAG_UPDATE_DELAYED")
	
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

	--if player isn't in a guild, then delete old guild data if found, sometimes this gets left behind for some reason
	if not IsInGuild() and (BSYC.db.player.guild or BSYC.db.player.guildrealm) then
		BSYC.db.player.guild = nil
		BSYC.db.player.guildrealm = nil
	end
end

function Events:BAGSYNC_EVENT_MAILBOX(event, isOpen)
	Debug(1, "BAGSYNC_EVENT_MAILBOX", isOpen)
	if isOpen then
		Scanner:SaveMailbox(true)
	end
end

function Events:BAGSYNC_EVENT_BANK(event, isOpen)
	Debug(1, "BAGSYNC_EVENT_BANK", isOpen)
	if isOpen then
		Scanner:SaveBank()
	end
end

function Events:BAGSYNC_EVENT_AUCTION(event, isOpen, isReady)
	Debug(1, "BAGSYNC_EVENT_AUCTION", isOpen, isReady)
	if isOpen and isReady then
		Scanner:SaveAuctionHouse()
	end
end

function Events:BAGSYNC_EVENT_VOIDBANK(event, isOpen)
	Debug(1, "BAGSYNC_EVENT_VOIDBANK", isOpen)
	if isOpen then
		Scanner:SaveVoidBank()
	end
end

function Events:BAGSYNC_EVENT_GUILDBANK(event, isOpen)
	Debug(1, "BAGSYNC_EVENT_GUILDBANK", isOpen)
	if isOpen then
		self:GuildBank_Open()
	else
		self:GuildBank_Close()
	end
end

function Events:PLAYER_MONEY()
	BSYC.db.player.money = Unit:GetUnitInfo().money
end

function Events:GUILD_ROSTER_UPDATE()
	BSYC.db.player.guild = Unit:GetUnitInfo().guild
	BSYC.db.player.guildrealm = Unit:GetUnitInfo().guildrealm
end

function Events:PLAYER_GUILD_UPDATE()
	BSYC.db.player.guild = Unit:GetUnitInfo().guild
	BSYC.db.player.guildrealm = Unit:GetUnitInfo().guildrealm
end

function Events:PLAYER_EQUIPMENT_CHANGED(event)
	Scanner:SaveEquipment()
end

function Events:BAG_UPDATE(event, bagid)
	if not self.SpamBagQueue then self.SpamBagQueue = {} end
	self.SpamBagQueue[bagid] = true
	self.SpamBagTotal = (self.SpamBagTotal or 0) + 1
end

function Events:BAG_UPDATE_DELAYED(event)
	if not self.SpamBagQueue then self.SpamBagQueue = {} end
	if not self.SpamBagTotal then self.SpamBagTotal = 0 end
	--NOTE: BSYC:GetHashTableLen(self.SpamBagQueue) may show more then is actually processed.  Example it has the banks in queue but we aren't at a bank.
	Debug(2, "SpamBagQueue", self.SpamBagTotal)
	
	local totalProcessed = 0
	
	for bagid in pairs(self.SpamBagQueue) do
		local bagname
	
		if Scanner:IsBackpack(bagid) or Scanner:IsBackpackBag(bagid) or Scanner:IsKeyring(bagid) then
			bagname = "bag"
		elseif Scanner:IsBank(bagid) or Scanner:IsBankBag(bagid) then
			--only do this while we are at a bank
			if Unit.atBank then
				bagname = "bank"
			end
		end

		if bagname then
			Scanner:SaveBag(bagname, bagid)
			totalProcessed = totalProcessed + 1
		end
		
		--remove it
		self.SpamBagQueue[bagid] = nil
	end
	self.SpamBagTotal = 0
	
	Debug(2, "SpamBagQueue", "totalProcessed", totalProcessed)
	
	if BSYC.IsRetail then
		--check if they crafted an item outside the bank, if so then do a parse check to update item count.
		self:DoTimer("SaveCraftedReagents", function() Scanner:SaveCraftedReagents() end, 1)
	end
end

function Events:GuildBank_Open()
	if not BSYC.options.enableGuild then return end
	if not self.GuildTabQueryQueue then self.GuildTabQueryQueue = {} end
	Debug(2, "GuildBank_Open")
	
	local numTabs = GetNumGuildBankTabs()
	for tab = 1, numTabs do
		local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals = GetGuildBankTabInfo(tab)
		if isViewable then
			self.GuildTabQueryQueue[tab] = true
			if not self.queryGuild then
				self.queryGuild  = true
			end
		end
	end
end

function Events:GuildBank_Close()
	if not BSYC.options.enableGuild then return end
	Debug(2, "GuildBank_Close")
	
	if self.queryGuild then
		BSYC:Print(L.ScanGuildBankError)
		self.queryGuild = false
	end
end

function Events:GuildBank_Changed()
	if not Unit.atGuildBank then return end
	if not BSYC.options.enableGuild then return end

	-- check if we need to process the queue
	local tab = next(self.GuildTabQueryQueue)
	if tab then
		QueryGuildBankTab(tab)
		self.GuildTabQueryQueue[tab] = nil
		--show the alert
		local numTab = string.format(L.ScanGuildBankScanInfo, tab or 0, GetNumGuildBankTabs() or 0)
		if BSYC.options.showGuildBankScanAlert then
			showEventAlert(numTab, "GUILDBANK")
		end
		Debug(3, "GuildBank_Changed", numTab)
	else
		if self.queryGuild then
			self.queryGuild = false
			BSYC:Print(L.ScanGuildBankDone)
			Events.alertTooltip:Hide()
		end
		-- the bank is ready for reading
		Scanner:SaveGuildBank()
	end
end

function Events:CURRENCY_DISPLAY_UPDATE()
	if Unit:InCombatLockdown() then
		if not self.doCurrencyUpdate then
			self.doCurrencyUpdate = true
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
		return
	end
	Scanner:SaveCurrency()
end

function Events:PLAYER_REGEN_ENABLED()
	--only run this if triggered by CURRENCY_DISPLAY_UPDATE and only if we are on Retail
	if Unit:InCombatLockdown() or not BSYC.IsRetail then return end
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self.doCurrencyUpdate = nil
	Scanner:SaveCurrency()
end

function Events:TRADE_SKILL_SHOW()
	if not self._TradeSkillEvent then
		self._TradeSkillEvent = true
	end
end

function Events:TRADE_SKILL_LIST_UPDATE()
	if self._TradeSkillEvent then
		self._TradeSkillEvent = nil
		Scanner:SaveProfessions()
	end
end

function Events:TRADE_SKILL_DATA_SOURCE_CHANGED()
	--this gets fired when they switch professions while still having the tradeskill window open
	if not self._TradeSkillEvent then
		self._TradeSkillEvent = true
		--this will trigger TRADE_SKILL_LIST_UPDATE and SaveProfessions which will save all the recipesIDs to Scanner.recipeIDs
	end
end