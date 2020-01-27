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

function Events:DoTimer(sName, sFunc, sDelay)
	if not self.timers then self.timers = {} end
	self:CancelTimer(self.timers[sName])
	self.timers[sName] = self:ScheduleTimer(sFunc, sDelay)
	return self.timers[sName]
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
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
	
	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
	self:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")

	self:RegisterEvent("VOID_STORAGE_OPEN", function() Scanner:SaveVoidBank() end)
	self:RegisterEvent("VOID_STORAGE_UPDATE", function() Scanner:SaveVoidBank() end)
	self:RegisterEvent("VOID_STORAGE_CONTENTS_UPDATE", function() Scanner:SaveVoidBank() end)
	self:RegisterEvent("VOID_TRANSFER_DONE", function() Scanner:SaveVoidBank() end)
	
	self:RegisterEvent("MAIL_SHOW", function() Scanner:SaveMailbox() end)
	self:RegisterEvent("MAIL_INBOX_UPDATE", function() Scanner:SaveMailbox() end)
	
	self:RegisterEvent("BANKFRAME_OPENED", function() Scanner:SaveBank() end)
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", function() Scanner:SaveBank(true) end)
	self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED", function() Scanner:SaveReagents() end)
	self:RegisterEvent("REAGENTBANK_PURCHASED", function() Scanner:SaveReagents() end)
	
	self:RegisterEvent("GUILDBANKFRAME_OPENED")
	self:RegisterEvent("GUILDBANKFRAME_CLOSED")
	self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED", function()
		self:DoTimer("GuildBankScan", function() self:GUILDBANKBAGSLOTS_CHANGED() end, 0.3)
	end)
	
	self:RegisterEvent("AUCTION_HOUSE_SHOW", function()
		--query and update items being sold
		if AuctionHouseFrame then AuctionHouseFrame:QueryAll(AuctionHouseSearchContext.AllAuctions) end
	end)
	self:RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED", function()
		if AuctionHouseFrame and AuctionHouseFrame:GetDisplayMode() == AuctionHouseFrameDisplayMode.CommoditiesSell or AuctionHouseFrameDisplayMode.ItemSell then
			self:DoTimer("QueryAuction", function() AuctionHouseFrame:QueryAll(AuctionHouseSearchContext.AllAuctions) end, 1)
		end
	end)
	self:RegisterEvent("ITEM_SEARCH_RESULTS_UPDATED", function()
		if AuctionHouseFrame and AuctionHouseFrame:GetDisplayMode() == AuctionHouseFrameDisplayMode.CommoditiesSell or AuctionHouseFrameDisplayMode.ItemSell then
			self:DoTimer("QueryAuction", function() AuctionHouseFrame:QueryAll(AuctionHouseSearchContext.AllAuctions) end, 1)
		end
	end)
	self:RegisterEvent("OWNED_AUCTIONS_UPDATED", function()
		self:DoTimer("ScanAuction", function() Scanner:SaveAuctionHouse() end, 1)
	end)
	
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
	if self.queryGuild then
		BSYC:Print(L.ScanGuildBankError)
		self.queryGuild = false
	end
end

function Events:GUILDBANKBAGSLOTS_CHANGED()
	if not Unit.atGuildBank then return end
	
	-- check if we need to process the queue
	local tab = next(self.GuildTabQueryQueue)
	if tab then
		QueryGuildBankTab(tab)
		self.GuildTabQueryQueue[tab] = nil
	else
		if self.queryGuild then
			self.queryGuild = false
			BSYC:Print(L.ScanGuildBankDone)
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
	if Unit:InCombatLockdown() then return end
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