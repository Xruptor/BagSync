--[[
	unit.lua
		Unit module for BagSync
		Special Thanks:  This module was inspired by LibItemCache-2.0.lua credit to jaliborc
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Unit = BSYC:NewModule("Unit")

local REALM = GetRealmName()
local PLAYER = UnitName('player')
local FACTION = UnitFactionGroup('player')

--[[ BSYC:RegisterEvent('BANKFRAME_OPENED', function() Unit.AtBank = true end)
BSYC:RegisterEvent('BANKFRAME_CLOSED', function() Unit.AtBank = false end)

BSYC:RegisterEvent('VOID_STORAGE_OPEN', function() Unit.AtVault = true end)
BSYC:RegisterEvent('VOID_STORAGE_CLOSE', function() Unit.AtVault = false end)

BSYC:RegisterEvent('GUILDBANKFRAME_OPENED', function() Unit.AtGuild = true end)
BSYC:RegisterEvent('GUILDBANKFRAME_CLOSED', function() Unit.AtGuild = false end)
 ]]
 
function Unit:GetUnitAddress(unit)
	if not unit then
		return REALM, PLAYER
	end

	local first, realm = strmatch(unit, '^(.-) *%- *(.+)$')
	local isguild, name = strmatch(first or unit, '^(®) *(.+)')
	return realm or REALM, name or first or unit, isguild and true
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

	unit.guild = unit.guild and ('® ' .. unit.guild .. ' - ' .. realm)
	unit.name, unit.realm, unit.isguild = name, realm, isguild
	unit.cached = cached

	return unit
end
