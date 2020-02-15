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
	--Force guild roster update, so we can grab guild name.  Note this is nil on login
	--https://wow.gamepedia.com/API_GetGuildInfo
	GuildRoster()
	
	self:RegisterEvent("PLAYER_MONEY")
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_GUILD_UPDATE")

	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("BAG_UPDATE")
	
	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
	self:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")

	self:RegisterEvent("MAIL_SHOW", function() Scanner:SaveMailbox() end)
	self:RegisterEvent("MAIL_INBOX_UPDATE", function()
		self:DoTimer("MailBoxScan", function() Scanner:SaveMailbox() end, 0.3)
	end)

	self:RegisterEvent("BANKFRAME_OPENED", function() Scanner:SaveBank() end)
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", function() Scanner:SaveBank(true) end)
	
	local function doAuctionUpdate(timerName)
		--stop the timer first
		self:StopTimer(timerName)
		--recreate the repeating timer
		self:DoTimer(timerName, function()
			if not Unit.atAuction then self:StopTimer(timerName) return end
			
			local dispMode = AuctionHouseFrame:GetDisplayMode()
			local state, spinner

			if dispMode == AuctionHouseFrameDisplayMode.CommoditiesSell then
				state = AuctionHouseFrame:GetCommoditiesSellListFrames().state
				spinner = AuctionHouseFrame:GetCommoditiesSellListFrames().LoadingSpinner
				
			elseif dispMode == AuctionHouseFrameDisplayMode.ItemSell then
				state = AuctionHouseFrame:GetItemSellList().state
				spinner = AuctionHouseFrame:GetItemSellList().LoadingSpinner
				
			elseif dispMode == AuctionHouseFrameDisplayMode.Buy then 
				state = AuctionHouseFrame:GetBrowseResultsFrame().ItemList.state
				spinner = AuctionHouseFrame:GetBrowseResultsFrame().ItemList.LoadingSpinner

			elseif dispMode == AuctionHouseFrameDisplayMode.Auctions then
				--don't run this while on auctions list frame
				self:StopTimer(timerName)
				return
			end
			
			if not state or not spinner then self:StopTimer(timerName) return end
			
			--state 3 = ResultsPending, and we don't have the LoadingSpinner Visible
			if state ~= 3 and not spinner:IsVisible() then
				AuctionHouseFrame:QueryAll(AuctionHouseSearchContext.AllAuctions)
				self:StopTimer(timerName)
			end
			
		end, 4, true)
	end
	
	local timerName = "QueryAuction"
	
	if BSYC.IsRetail then
		self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
		
		self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED", function() Scanner:SaveReagents() end)
		self:RegisterEvent("REAGENTBANK_PURCHASED", function() Scanner:SaveReagents() end)
		
		self:RegisterEvent("VOID_STORAGE_OPEN", function() Scanner:SaveVoidBank() end)
		self:RegisterEvent("VOID_STORAGE_UPDATE", function() Scanner:SaveVoidBank() end)
		self:RegisterEvent("VOID_STORAGE_CONTENTS_UPDATE", function() Scanner:SaveVoidBank() end)
		self:RegisterEvent("VOID_TRANSFER_DONE", function() Scanner:SaveVoidBank() end)
		
		self:RegisterEvent("GUILDBANKFRAME_OPENED")
		self:RegisterEvent("GUILDBANKFRAME_CLOSED")
		self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED", function()
			self:DoTimer("GuildBankScan", function() self:GUILDBANKBAGSLOTS_CHANGED() end, 0.2)
		end)
		
		self:RegisterEvent("AUCTION_HOUSE_SHOW", function()
			--query and update items being sold
			if AuctionHouseFrame then
				AuctionHouseFrame:QueryAll(AuctionHouseSearchContext.AllAuctions)
				--hook the post buttons only once
				if not self.auctionPostClick then
					self.auctionPostClick = true
					AuctionHouseFrame.CommoditiesSellFrame.PostButton:HookScript("OnClick", function()
						doAuctionUpdate(timerName)
					end)
					AuctionHouseFrame.ItemSellFrame.PostButton:HookScript("OnClick", function()
						doAuctionUpdate(timerName)
					end)
				end
			end
		end)

		self:RegisterEvent("OWNED_AUCTIONS_UPDATED", function()
			self:DoTimer("ScanAuction", function() Scanner:SaveAuctionHouse() end, 1)
		end)
	else
		--classic auction house
		self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE", function() Scanner:SaveAuctionHouse() end)
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
	
	--bag updates for the bank slots occur even when the player isn't at the bank, we have to check for that
	if ((bagid >= NUM_BAG_SLOTS + 1) and (bagid <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS) and Unit.atBank) then
		bagname = "bank"
	elseif (bagid >= BACKPACK_CONTAINER) and (bagid <= BACKPACK_CONTAINER + NUM_BAG_SLOTS) then
		bagname = "bag"
	else
		--probably bank update when user isn't at the bank, that or some bogus bag we don't care about
		return
	end

	Scanner:SaveBag(bagname, bagid)
end

function Events:GUILDBANKFRAME_OPENED()
	if not BSYC.options.enableGuild then return end
	if not self.GuildTabQueryQueue then self.GuildTabQueryQueue = {} end
		
	if Events.alertTooltip then
		Events.alertTooltip:ClearAllPoints()
		Events.alertTooltip:SetOwner(UIParent, "ANCHOR_NONE")
		Events.alertTooltip:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	
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

function Events:GUILDBANKFRAME_CLOSED()
	if not BSYC.options.enableGuild then return end
	
	if self.queryGuild then
		BSYC:Print(L.ScanGuildBankError)
		self.queryGuild = false
	end
	if Events.alertTooltip then
		Events.alertTooltip:Hide()
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

		if Events.alertTooltip then
			Events.alertTooltip:ClearLines()
			Events.alertTooltip:AddLine("|cffff6600BagSync|r")
			local numTab = string.format(L.ScanGuildBankScanInfo, tab or 0, GetNumGuildBankTabs() or 0)
			Events.alertTooltip:AddLine("|cffddff00"..numTab.."|r")
			Events.alertTooltip:Show()
		end
	else
		if self.queryGuild then
			self.queryGuild = false
			BSYC:Print(L.ScanGuildBankDone)
			if Events.alertTooltip then
				Events.alertTooltip:Hide()
			end
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
	end
end