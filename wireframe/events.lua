--[[
	events.lua
		Event module for BagSync, captures and processes events
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Events = BSYC:NewModule("Events", 'AceEvent-3.0', 'AceTimer-3.0')
local Unit = BSYC:GetModule("Unit")
local Scanner = BSYC:GetModule("Scanner")
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
local function Debug(...)
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", "Events")
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end
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
	self:CancelTimer(self.timers[sName])
	self.timers[sName] = nil
end

function Events:OnEnable()
	
	self:RegisterEvent("PLAYER_MONEY")
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_GUILD_UPDATE")

	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("BAG_UPDATE")
	
	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
	self:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")

	self:RegisterEvent("MAIL_INBOX_UPDATE", function()
		self:DoTimer("MailBoxScan", function() Scanner:SaveMailbox() end, 0.3)
	end)

	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", function(event, slotID)
		Scanner:SaveBank(true)
		--check if they crafted an item outside the bank, if so then do a parse check to update item count.
		self:DoTimer("SaveCraftedReagents", function() Scanner:SaveCraftedReagents() end, 1)
	end)

	--Force guild roster update, so we can grab guild name.  Note this is nil on login, have to check for Classic and Retail though
	--https://wow.gamepedia.com/API_GetGuildInfo
	if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end  -- Retail
	if GuildRoster then GuildRoster() end -- Classic
	
	--Do old calls for non-retail
	if not BSYC.IsRetail then
		self:RegisterEvent("MAIL_SHOW", function() Scanner:SaveMailbox(true) end)
		self:RegisterEvent("BANKFRAME_OPENED", function() Scanner:SaveBank() end)
		
		--WOTLK or higher
		if not BSYC.IsClassic then
			self:RegisterEvent("GUILDBANKFRAME_OPENED", function() self:GuildBank_Open() end)
			self:RegisterEvent("GUILDBANKFRAME_CLOSED", function() self:GuildBank_Close() end)
		end
	end
	
	if BSYC.IsRetail then
		
		--Introduced in Dragonflight (https://wowpedia.fandom.com/wiki/PLAYER_INTERACTION_MANAGER_FRAME_SHOW)
		self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(event, winArg)
			winArg = tonumber(winArg) or 0

			--mailbox
			if winArg == 17 then Scanner:SaveMailbox(true) end
			--bank
			if winArg == 8 then Scanner:SaveBank() end
			--void storage
			if winArg == 26 then Scanner:SaveVoidBank() end
			--Guildbank
			if winArg == 10 then self:GuildBank_Open() end

		end)
		
		--Introduced in Dragonflight (https://wowpedia.fandom.com/wiki/PLAYER_INTERACTION_MANAGER_FRAME_SHOW)
		self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(event, winArg)
			winArg = tonumber(winArg) or 0
			
			--Guildbank
			if winArg == 10 then self:GuildBank_Close() end
		end)
	
		self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
		
		--save any crafted item info in case they aren't at a bank
		self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(event, unitTarget, castGUID, spellID) Scanner:ParseCraftedInfo(unitTarget, castGUID, spellID) end)
		
		self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED", function(event, slotID)
			Scanner:SaveReagents()
			--check if they crafted an item outside the bank, if so then do a parse check to update item count.
			self:DoTimer("SaveCraftedReagents", function() Scanner:SaveCraftedReagents() end, 1)
		end)
		self:RegisterEvent("REAGENTBANK_PURCHASED", function() Scanner:SaveReagents() end)
		
		self:RegisterEvent("VOID_STORAGE_UPDATE", function() Scanner:SaveVoidBank() end)
		self:RegisterEvent("VOID_STORAGE_CONTENTS_UPDATE", function() Scanner:SaveVoidBank() end)
		self:RegisterEvent("VOID_TRANSFER_DONE", function() Scanner:SaveVoidBank() end)
		
		local timerName = "QueryOwnedAuctions"
		
		local function doAuctionUpdate()
            --stop the timer first, to prevent it causing conflicts with current actions being done by the Auction House
			--each time we recreate it, it just pushes the timer forward to wait until all actions are done
            self:StopTimer(timerName)
			--recreate the timer
			self:DoTimer(timerName, function()
				if not Events.canQueryAuctions or not Unit.atAuction then
					self:StopTimer(timerName)
					return
				end
				--check to see if it's okay to query the server
				if C_AuctionHouse.IsThrottledMessageSystemReady() then
					C_AuctionHouse.QueryOwnedAuctions({})
					self:StopTimer(timerName)
					return
				end
			end, 0.6, true)
		end
		self:RegisterEvent("AUCTION_HOUSE_AUCTION_CREATED", function()
			if not BSYC.options.enableAuction then return end
			--the user posted an item to sell, so lets schedule an auction scan
			Events.canQueryAuctions = true
		end)		
		self:RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED", function()
			if not BSYC.options.enableAuction then return end
			--if we have an auction scan scheduled, then run it only if the server is ready
			if Events.canQueryAuctions then doAuctionUpdate() end
		end)
		self:RegisterEvent("OWNED_AUCTIONS_UPDATED", function()
			if not BSYC.options.enableAuction then return end
			Events.canQueryAuctions = false --reset this
			self:DoTimer("ScanAuction", function() Scanner:SaveAuctionHouse() end, 0.5)
		end)

	else
		--classic auction house
		self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE", function() Scanner:SaveAuctionHouse() end)
	end
	
	--only load certain things if NOT in classic
	if not BSYC.IsClassic then
		self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED", function()
			self:DoTimer("GuildBankScan", function() self:GUILDBANKBAGSLOTS_CHANGED() end, 0.2)
		end)
	end
	
	Scanner:StartupScans() --do the login player scans
end

function Events:PLAYER_MONEY()
	BSYC.db.player.money = Unit:GetUnitInfo().money
end

function Events:GUILD_ROSTER_UPDATE()
	BSYC.db.player.guild = Unit:GetUnitInfo().guild
end

function Events:PLAYER_GUILD_UPDATE()
	BSYC.db.player.guild = Unit:GetUnitInfo().guild
end

function Events:UNIT_INVENTORY_CHANGED(event, unit)
	if unit == "player" then
		Scanner:SaveEquipment()
	end
end

function Events:BAG_UPDATE(event, bagid)
	local bagname

	if Scanner:IsBackpack(bagid) or Scanner:IsBackpackBag(bagid) or Scanner:IsKeyring(bagid) then
		bagname = "bag"
	elseif Scanner:IsBank(bagid) or Scanner:IsBankBag(bagid) or Scanner:IsReagentBag(bagid) then
		--only do this while we are at a bank
		if Unit.atBank then
			if Scanner:IsReagentBag(bagid) then --just in case
				Scanner:SaveReagents()
				return
			end
			bagname = "bank"
		else
			return
		end
	else
		--unknown bag, don't save it
		return
	end

	Scanner:SaveBag(bagname, bagid)
	
	--check if they crafted an item outside the bank, if so then do a parse check to update item count.
	self:DoTimer("SaveCraftedReagents", function() Scanner:SaveCraftedReagents() end, 1)
end

function Events:GuildBank_Open()
	if not BSYC.options.enableGuild then return end
	if not self.GuildTabQueryQueue then self.GuildTabQueryQueue = {} end
	
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
	
	if self.queryGuild then
		BSYC:Print(L.ScanGuildBankError)
		self.queryGuild = false
	end
end

function Events:GUILDBANKBAGSLOTS_CHANGED()
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
	--only run this on retail
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