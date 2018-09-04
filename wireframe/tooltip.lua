--[[
	tooltip.lua
		Tooltip module for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Tooltip = BSYC:NewModule("Tooltip", 'AceEvent-3.0')
local Unit = BSYC:GetModule("Unit")
