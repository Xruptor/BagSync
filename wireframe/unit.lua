--[[
	unit.lua
		Unit module for BagSync
		Special Thanks:  This module was inspired by LibItemCache-2.0.lua credit to jaliborc
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Unit = BSYC:NewModule("Unit", 'AceEvent-3.0')

local REALM = GetRealmName()
local PLAYER = UnitName('player')
local FACTION = UnitFactionGroup('player')

Unit:RegisterEvent('BANKFRAME_OPENED', function() Unit.atBank = true end)
Unit:RegisterEvent('BANKFRAME_CLOSED', function() Unit.atBank = false end)

Unit:RegisterEvent('VOID_STORAGE_OPEN', function() Unit.atVault = true end)
Unit:RegisterEvent('VOID_STORAGE_CLOSE', function() Unit.atVault = false end)

Unit:RegisterEvent('GUILDBANKFRAME_OPENED', function() Unit.atGuild = true end)
Unit:RegisterEvent('GUILDBANKFRAME_CLOSED', function() Unit.atGuild = false end)

function Unit:GetUnitAddress(unit)
	if not unit then
		return REALM, PLAYER
	end

	local guildName = strmatch(unit, '(.+)©')
	return REALM, guildName or unit, guildName and true
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

	return unit
end

function Unit:GetUnitTag(unit)
	--return here the full unit tag for the tooltip
	
end
