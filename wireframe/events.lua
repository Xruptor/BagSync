--[[
	events.lua
		Event module for BagSync, captures and processes events
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Events = BSYC:NewModule("Events", 'AceEvent-3.0')
local Unit = BSYC:GetModule("Unit")
local Scanner = BSYC:GetModule("Scanner")

function Events:OnEnable()
	--Force guild roster update, so we can grab guild name.  Note this is nil on login
	--https://wow.gamepedia.com/API_GetGuildInfo
	GuildRoster()
	
	self:RegisterEvent('PLAYER_MONEY')
	self:RegisterEvent('GUILD_ROSTER_UPDATE')
	self:RegisterEvent('PLAYER_GUILD_UPDATE')

	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("BAG_UPDATE")
	
	self:RegisterEvent('VOID_STORAGE_OPEN', function() Scanner:ScanVoidBank() end)
	self:RegisterEvent('VOID_STORAGE_UPDATE', function() Scanner:ScanVoidBank() end)
	self:RegisterEvent('VOID_STORAGE_CONTENTS_UPDATE', function() Scanner:ScanVoidBank() end)
	self:RegisterEvent('VOID_TRANSFER_DONE', function() Scanner:ScanVoidBank() end)
	
	self:RegisterEvent('MAIL_SHOW', function() Scanner:ScanMailbox() end)
	self:RegisterEvent('MAIL_INBOX_UPDATE', function() Scanner:ScanMailbox() end)
	
	self:RegisterEvent("BANKFRAME_OPENED", function() Scanner:ScanBank() end)
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", function() Scanner:ScanBank(true) end)
	self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED", function() Scanner:ScanReagents() end)
	self:RegisterEvent("REAGENTBANK_PURCHASED", function() Scanner:ScanReagents() end)
	
	self:RegisterEvent("GUILDBANKFRAME_OPENED")
	self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
	
	self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE", function() Scanner:ScanAuctionHouse() end)
	
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
		end
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
		-- the bank is ready for reading
		Scanner:ScanGuildBank()
	end
end
