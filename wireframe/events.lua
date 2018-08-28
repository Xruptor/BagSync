--[[
	events.lua
		Event module for BagSync, captures and processes events
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Events = BSYC:NewModule("Events", 'AceEvent-3.0')
local Unit = BSYC:GetModule("Unit")

function Events:OnEnable()
	self:RegisterEvent('PLAYER_MONEY')
	self:RegisterEvent('GUILD_ROSTER_UPDATE')
end

function Events:PLAYER_MONEY()
	BSYC.db.player.money = Unit:GetUnitInfo().money
end

function Events:GUILD_ROSTER_UPDATE()
	BSYC.db.player.guild = Unit:GetUnitInfo().guild
end

--[[ 	

	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	self:RegisterEvent("GUILDBANKFRAME_OPENED")
	self:RegisterEvent("GUILDBANKFRAME_CLOSED")
	self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
	self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")

	self:RegisterEvent("MAIL_SHOW")
	self:RegisterEvent("MAIL_INBOX_UPDATE")
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
	
	--currency
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

	--void storage
	self:RegisterEvent("VOID_STORAGE_OPEN")
	self:RegisterEvent("VOID_STORAGE_CLOSE")
	self:RegisterEvent("VOID_STORAGE_UPDATE")
	self:RegisterEvent("VOID_STORAGE_CONTENTS_UPDATE")
	self:RegisterEvent("VOID_TRANSFER_DONE")
	
	--this will be used for getting the tradeskill link
	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
 ]]
