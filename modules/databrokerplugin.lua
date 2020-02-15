--[[
	databrokerplugin.lua
		A libDataBroker plugin for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
local function Debug(...)
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", "DataBrokerPlugin")
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end
end

local Plugin = LDB:NewDataObject("BagSyncLDB", {
	type = "data source",
	--icon = "Interface\\Icons\\INV_Misc_Bag_12",
	icon = "Interface\\AddOns\\BagSync\\media\\icon",
	label = "BagSync",
	text = "BagSync",
		
	OnClick = function(self, button)
		if button == "LeftButton" then
			if BSYC:GetModule("Search").frame:IsVisible() then
				BSYC:GetModule("Search").frame:Hide()
				return
			end
			BSYC:GetModule("Search").frame:Show()
		elseif button == "RightButton" then
			ToggleDropDownMenu(1, nil, BSYC:GetModule("Minimap").dropdown, "cursor", 0, 0)
		end
	end,

	OnTooltipShow = function(self)
		self:AddLine("BagSync")
		self:AddLine(L.LeftClickSearch)
		self:AddLine(L.RightClickBagSyncMenu)
	end
})
