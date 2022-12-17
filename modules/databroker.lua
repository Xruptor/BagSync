--[[
	databrokerplugin.lua
		A libDataBroker plugin for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local DataBroker = BSYC:NewModule("DataBroker")

local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local MinimapIcon = LibStub("LibDBIcon-1.0")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "DataBrokerPlugin", ...) end
end

--lets do the dropdown menu of DOOM
local bgsMinimapDD = CreateFrame("Frame", "bgsMinimapDD")
bgsMinimapDD.displayMode = 'MENU'

DataBroker.dropdown = bgsMinimapDD

local function addButton(level, text, isTitle, notCheckable, hasArrow, value, func)
	local info = UIDropDownMenu_CreateInfo()
	info.text = text
	info.isTitle = isTitle
	info.notCheckable = notCheckable
	info.hasArrow = hasArrow
	info.value = value
	info.func = func
	UIDropDownMenu_AddButton(info, level)
end

bgsMinimapDD.initialize = function(self, level)

	if level == 1 then
		PlaySound(SOUNDKIT.GS_TITLE_OPTION_EXIT)
		addButton(level, 'BagSync        ', 1, 1)
		addButton(level, L.Search, nil, 1, nil, 'search', function(frame, ...)
			BSYC:GetModule("Search").frame:Show()
		end)
		if BSYC.IsRetail then
			addButton(level, L.Currency, nil, 1, nil, 'currency', function(frame, ...)
				BSYC:GetModule("Currency").frame:Show()
			end)
			addButton(level, L.Professions, nil, 1, nil, 'professions', function(frame, ...)
				BSYC:GetModule("Professions").frame:Show()
			end)
		end
		addButton(level, L.Blacklist, nil, 1, nil, 'blacklist', function(frame, ...)
			BSYC:GetModule("Blacklist").frame:Show()
		end)
		addButton(level, L.Gold, nil, 1, nil, 'gold', function(frame, ...)
			BSYC:GetModule("Tooltip"):MoneyTooltip()
		end)
		addButton(level, L.Profiles, nil, 1, nil, 'profiles', function(frame, ...)
			BSYC:GetModule("Profiles").frame:Show()
		end)
		addButton(level, L.FixDB, nil, 1, nil, 'fixdb', function(frame, ...)
			BSYC:GetModule("Data"):FixDB()
		end)
		addButton(level, L.Config, nil, 1, nil, 'config', function(frame, ...)
			if not BSYC.IsRetail then
				--only do this for Expansions less than Retail
				InterfaceOptionsFrame:Show() --has to be here to load the about frame onLoad
			else
				if InCombatLockdown() or GameMenuFrame:IsShown() or InterfaceOptionsFrame then
					return false
				end
			end
			InterfaceOptionsFrame_OpenToCategory(BSYC.aboutPanel) --force the panel to show
		end)
		addButton(level, "", nil, 1) --space ;)
		addButton(level, L.Close, nil, 1)

	end

end

--https://github.com/tekkub/libdatabroker-1-1/wiki/data-specifications
local Plugin = LDB:NewDataObject("BagSyncLDB", {
	type = "launcher",
	--icon = "Interface\\Icons\\INV_Misc_Bag_12",
	icon = "Interface\\AddOns\\BagSync\\media\\icon",
	label = "BagSync",

	OnClick = function(self, button)
		if button == "LeftButton" then
			if BSYC:GetModule("Search").frame:IsVisible() then
				BSYC:GetModule("Search").frame:Hide()
				return
			end
			BSYC:GetModule("Search").frame:Show()
		elseif button == "RightButton" then
			if MinimapIcon.tooltip then MinimapIcon.tooltip:Hide() end
			ToggleDropDownMenu(1, nil, bgsMinimapDD, 'cursor', 0, 0)
		end
	end,

	OnTooltipShow = function(self)
		self:AddLine("BagSync")
		self:AddLine(L.LeftClickSearch)
		self:AddLine(L.RightClickBagSyncMenu)
	end
})

function DataBroker:OnEnable()
	--register and load the minimap button
	if BSYC.options.minimap == nil then BSYC.options.minimap = {} end
	MinimapIcon:Register("BagSync", Plugin, BSYC.options.minimap)

	local iconSwitch = not BSYC.options.enableMinimap --the opposite of what the value is

	if BSYC.options.enableMinimap then
		BSYC.options.minimap.hide = iconSwitch
		MinimapIcon:Show("BagSync")
	elseif not BSYC.options.enableMinimap then
		BSYC.options.minimap.hide = iconSwitch
		MinimapIcon:Hide("BagSync")
	end
end
