--[[
	scanner.lua
		Scanner module for BagSync, scans bags, bank, currency, etc...
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Scanner = BSYC:NewModule("Scanner", 'AceEvent-3.0')
local Unit = BSYC:GetModule("Unit")

