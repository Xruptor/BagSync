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
		if self.alertType == "AUCTION" and not Unit.atAuction then
			self:Hide()
		end
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

	self:RegisterEvent("MAIL_SHOW", function() Scanner:SaveMailbox(true) end)
	self:RegisterEvent("MAIL_INBOX_UPDATE", function()
		self:DoTimer("MailBoxScan", function() Scanner:SaveMailbox() end, 0.3)
	end)

	self:RegisterEvent("BANKFRAME_OPENED", function() Scanner:SaveBank() end)
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", function() Scanner:SaveBank(true) end)

	if BSYC.IsRetail then
		
		local timerName = "QueryAuction"
		
		local AuctionsFrameDisplayMode = {
			AllAuctions = 1,
			BidsList = 2,
			Item = 3,
			Commodity = 4,
		}
					
		local function doAuctionUpdate(timerName, customDelay)
			
			--show the waiting alert for auction scanning
			showEventAlert(L.ScanAuctionsWait, "AUCTION")

			--stop the timer first
			self:StopTimer(timerName)
			
			--recreate the repeating timer
			self:DoTimer(timerName, function()
				if not Unit.atAuction then
					self:StopTimer(timerName)
					return
				end
				
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

				elseif dispMode == AuctionHouseFrameDisplayMode.CommoditiesBuy then 
					state = AuctionHouseFrame.CommoditiesBuyFrame.ItemList.state
					spinner = AuctionHouseFrame.CommoditiesBuyFrame.ItemList.LoadingSpinner
					
				elseif dispMode == AuctionHouseFrameDisplayMode.ItemBuy then 
					state = AuctionHouseFrame.ItemBuyFrame.ItemList.state
					spinner = AuctionHouseFrame.ItemBuyFrame.ItemList.LoadingSpinner
					
				elseif dispMode == AuctionHouseFrameDisplayMode.Auctions then
					local frame = AuctionHouseFrame.AuctionsFrame
					local dispMode = frame.displayMode
					
					if dispMode == AuctionsFrameDisplayMode.AllAuctions then
						state = frame.AllAuctionsList.state
						spinner = frame.AllAuctionsList.LoadingSpinner
					elseif dispMode == AuctionsFrameDisplayMode.BidsList then
						state = frame.BidsList.state
						spinner = frame.BidsList.LoadingSpinner
					elseif dispMode == AuctionsFrameDisplayMode.Item then
						state = frame.ItemList.state
						spinner = frame.ItemList.LoadingSpinner
					elseif dispMode == AuctionsFrameDisplayMode.Commodity then
						state = frame.CommoditiesList.state
						spinner = frame.CommoditiesList.LoadingSpinner
					end
				else
					--it's something else we don't know so return
					return
				end
				
				--if we have nothing to work with return until we do
				if not state or not spinner then return end

				--can we query? state 3 = ResultsPending, and we don't have the LoadingSpinner Visible
				if Events.canQueryAuctions and state ~= 3 and not spinner:IsVisible() then
					Events.canQueryAuctions = false --set to false so we wait for response query
					AuctionHouseFrame:QueryAll(AuctionHouseSearchContext.AllAuctions)
					self:StopTimer(timerName)
				end
				
			end, customDelay or 3, true)
		end
		
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
			--don't process auction or perform any timers unless we have it enabled
			if not BSYC.options.enableAuction then return end
			Events.canQueryAuctions = false --reset to false to check for query
			
			--do the initial grab
			doAuctionUpdate(timerName, 1.5)
			
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
		end)

		--set canQueryAuctions depending on event
		self:RegisterEvent("AUCTION_HOUSE_CLOSED", function() Events.canQueryAuctions = false end)
		--these occur at the start and end of a query so they should be sufficient for checking status
		self:RegisterEvent("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", function() Events.canQueryAuctions = true end)
		self:RegisterEvent("AUCTION_HOUSE_THROTTLED_MESSAGE_SENT", function() Events.canQueryAuctions = false end)
		self:RegisterEvent("OWNED_AUCTIONS_UPDATED", function()
			--don't process auction or perform any timers unless we have it enabled
			if not BSYC.options.enableAuction then return end
			self:DoTimer("ScanAuction", function() Scanner:SaveAuctionHouse() end, 1)
			Events.alertTooltip:Hide()
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
		showEventAlert(numTab, "GUILDBANK")
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