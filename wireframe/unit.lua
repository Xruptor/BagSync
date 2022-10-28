--[[
	unit.lua
		Unit module for BagSync
		Special Thanks:  This module was inspired by LibItemCache-2.0.lua credit to jaliborc
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Unit = BSYC:NewModule("Unit", 'AceEvent-3.0')

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
local function Debug(...)
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", "Unit")
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end
end

local REALM = GetRealmName()
local PLAYER = UnitName('player')
local FACTION = UnitFactionGroup('player')

local BROKEN_REALMS = {
	['Aggra(Português)'] = 'Aggra (Português)',
	['AzjolNerub'] = 'Azjol-Nerub',
	['Arakarahm'] = 'Arak-arahm',
	['Корольлич'] = 'Король-лич',
}

local Realms = GetAutoCompleteRealms()
local RealmsCR = {}

if not Realms or #Realms == 0 then
	Realms = {REALM}
end

for i,realm in ipairs(Realms) do
		realm = BROKEN_REALMS[realm] or realm
		realm = realm:gsub('(%l)(%u)', '%1 %2') -- names like Blade'sEdge to Blade's Edge
		Realms[i] = realm
		RealmsCR[realm] = true
end

--this is used to identify cross servers as a unique key.
--for example guilds that are on cross servers with players from different servers in same guild
table.sort(Realms, function(a,b) return (a < b) end) --sort them alphabetically
local realmKey = table.concat(Realms, ";") --concat them together

--Do old calls for non-retail
if not BSYC.IsRetail then
	Unit:RegisterEvent('BANKFRAME_OPENED', function() Unit.atBank = true end)
	Unit:RegisterEvent('BANKFRAME_CLOSED', function() Unit.atBank = false end)
	Unit:RegisterEvent('MAIL_SHOW', function() Unit.atMailbox = true end)
	Unit:RegisterEvent('MAIL_CLOSED', function() Unit.atMailbox = false end)
	Unit:RegisterEvent('AUCTION_HOUSE_SHOW', function() Unit.atAuction = true end)
	Unit:RegisterEvent('AUCTION_HOUSE_CLOSED', function() Unit.atAuction = false end)
	
	--WOTLK or higher
	if not BSYC.IsClassic then
		Unit:RegisterEvent('GUILDBANKFRAME_OPENED', function() Unit.atGuildBank = true end)
		Unit:RegisterEvent('GUILDBANKFRAME_CLOSED', function() Unit.atGuildBank = false end)
	end
end

if BSYC.IsRetail then
	--Introduced in Dragonflight (https://wowpedia.fandom.com/wiki/PLAYER_INTERACTION_MANAGER_FRAME_SHOW)
	Unit:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(event, winArg)
		winArg = tonumber(winArg) or 0

		--mailbox
		if winArg == 17 then Unit.atMailbox = true end
		--bank
		if winArg == 8 then Unit.atBank = true end
		--Auction
		if winArg == 21 then Unit.atAuction = true end
		--void storage
		if winArg == 26 then Unit.atVoidBank = true end
		--Guildbank
		if winArg == 10 then Unit.atGuildBank = true end

	end)

	--Introduced in Dragonflight (https://wowpedia.fandom.com/wiki/PLAYER_INTERACTION_MANAGER_FRAME_SHOW)
	Unit:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(event, winArg)
		winArg = tonumber(winArg) or 0

		--mailbox
		if winArg == 17 then Unit.atMailbox = false end
		--bank
		if winArg == 8 then Unit.atBank = false end
		--Auction
		if winArg == 21 then Unit.atAuction = false end
		--void storage
		if winArg == 26 then Unit.atVoidBank = false end
		--Guildbank
		if winArg == 10 then Unit.atGuildBank = false end

	end)
end

function Unit:GetUnitAddress(unit)
	if not unit then
		return REALM, PLAYER
	end

	local name, realm = strmatch(unit, '^(.-) *%- *(.+)$')
	local guildName = strmatch(name or unit, '(.+)©')
	return realm or REALM, guildName or unit, guildName and true
end

function Unit:GetUnitInfo(unit)
	local realm, name, isguild = self:GetUnitAddress(unit)
	local unit = {}
	
	unit.faction = FACTION

	if not isguild then
		unit.money = (GetMoney() or 0) - GetCursorMoney() - GetPlayerTradeMoney()
		unit.class = select(2, UnitClass('player'))
		unit.race = select(2, UnitRace('player'))
		unit.guild = GetGuildInfo('player')
		unit.gender = UnitSex('player')
	end

	unit.guild = unit.guild and (unit.guild..'©')
	unit.name, unit.realm, unit.isguild = name, realm, isguild
	unit.realmKey = realmKey

	return unit
end

function Unit:isConnectedRealm(realm)
	return RealmsCR[realm]
end

function Unit:GetRealmKey()
	return realmKey
end

function Unit:IsInBG()
	if (GetNumBattlefieldScores() > 0) then
		return true
	end
	return false
end

function Unit:IsInArena()
	if not BSYC.IsRetail then return false end
	local a,b = IsActiveBattlefieldArena()
	if not a then
		return false
	end
	return true
end

function Unit:InCombatLockdown()
	return self:IsInBG() or self:IsInArena() or InCombatLockdown() or UnitAffectingCombat("player") or (BSYC.IsRetail and C_PetBattles.IsInBattle())
end