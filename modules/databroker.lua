--[[
	databroker.lua
		A LibDataBroker plugin + LibDBIcon minimap icon for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...)
local DataBroker = BSYC:NewModule("DataBroker")
local UI = BSYC:GetModule("UI")
local L = BSYC.L

local LDB = _G.LibStub and _G.LibStub("LibDataBroker-1.1", true)
local LDBIcon = _G.LibStub and _G.LibStub("LibDBIcon-1.0", true)

if not LDB then return end
if not LDBIcon then return end

-- Cache global references
local _G = _G
local UIDropDownMenu_CreateInfo = _G.UIDropDownMenu_CreateInfo
local UIDropDownMenu_AddButton = _G.UIDropDownMenu_AddButton
local CreateFrame = _G.CreateFrame
local ToggleDropDownMenu = _G.ToggleDropDownMenu
local SOUNDKIT = _G.SOUNDKIT

-- Helper to ensure minimap DB structure exists (eliminates duplication across 4 functions)
local function EnsureMinimapDB()
	BSYC.options = BSYC.options or {}
	BSYC.options.minimap = BSYC.options.minimap or {}
	if BSYC.options.minimap.hide == nil then
		BSYC.options.minimap.hide = false
	end
	return BSYC.options.minimap
end

function DataBroker:BuildMinimapDropdown()
	local bgsMinimapDD = UI:CreateDropdown(UIParent, {
		globalName = "bgsMinimapDD",
	})
	bgsMinimapDD.displayMode = "MENU"

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

	-- Data-driven menu items (eliminates 12 repetitive addButton calls)
	bgsMinimapDD.initialize = function(_, level)
		if level == 1 then
			if SOUNDKIT and SOUNDKIT.GS_TITLE_OPTION_EXIT then
				_G.PlaySound(SOUNDKIT.GS_TITLE_OPTION_EXIT)
			end

			-- Cache module references to avoid repeated GetModule calls
			local Search = BSYC:GetModule("Search")
			local Currency = BSYC:CanDoCurrency() and BSYC:GetModule("Currency")
			local Professions = BSYC:CanDoProfessions() and BSYC:GetModule("Professions")
			local Blacklist = BSYC:GetModule("Blacklist")
			local Whitelist = BSYC:GetModule("Whitelist")
			local Gold = BSYC:GetModule("Gold")
			local Profiles = BSYC:GetModule("Profiles")
			local SortOrder = BSYC:GetModule("SortOrder")
			local Data = BSYC:GetModule("Data")
			local Debug = BSYC:GetModule("Debug")

			-- Build menu from data table
			addButton(level, "BagSync        ", 1, 1)
			addButton(level, L.Search, nil, 1, nil, "search", function()
				Search.frame:Show()
			end)

			if Currency and BSYC.tracking.currency then
				addButton(level, L.Currency, nil, 1, nil, "currency", function()
					Currency.frame:Show()
				end)
			end

			if Professions and BSYC.tracking.professions then
				addButton(level, L.Professions, nil, 1, nil, "professions", function()
					Professions.frame:Show()
				end)
			end

			addButton(level, L.Blacklist, nil, 1, nil, "blacklist", function()
				Blacklist.frame:Show()
			end)
			addButton(level, L.Whitelist, nil, 1, nil, "whitelist", function()
				Whitelist.frame:Show()
			end)
			addButton(level, L.Gold, nil, 1, nil, "gold", function()
				Gold.frame:Show()
			end)
			addButton(level, L.Profiles, nil, 1, nil, "profiles", function()
				Profiles.frame:Show()
			end)
			addButton(level, L.SortOrder, nil, 1, nil, "sortorder", function()
				SortOrder.frame:Show()
			end)
			addButton(level, L.FixDB, nil, 1, nil, "fixdb", function()
				Data:FixDB()
			end)
			addButton(level, L.Debug, nil, 1, nil, "debug", function()
				Debug.frame:Show()
			end)
			addButton(level, L.Config, nil, 1, nil, "config", function()
				BSYC:OpenConfig()
			end)
			addButton(level, "", nil, 1)
			addButton(level, L.Close, nil, 1)
		end
	end

	DataBroker.dropdown = bgsMinimapDD
	BSYC.bgsMinimapDD = bgsMinimapDD
end

function BSYC:OpenMinimapMenu(anchor)
	if DataBroker.dropdown then
		ToggleDropDownMenu(1, nil, DataBroker.dropdown, anchor or UIParent, 0, 0)
	end
end

function DataBroker:CreatePlugin()
	local existing = LDB:GetDataObjectByName("BagSync")
	if existing then
		DataBroker.BrokerPlugin = existing
		BSYC.LDBObject = existing
		return
	end

	DataBroker.BrokerPlugin = LDB:NewDataObject("BagSync", {
		type = "launcher",
		icon = "Interface\\AddOns\\BagSync\\media\\icon",
		label = "BagSync",

		OnClick = function(_, button)
			if button == "LeftButton" then
				local search = BSYC:GetModule("Search")
				local searchFrame = search.frame
				if searchFrame:IsVisible() then
					searchFrame:Hide()
					return
				end
				searchFrame:Show()
			elseif button == "RightButton" then
				if LDBIcon.tooltip then
					LDBIcon.tooltip:Hide()
				end
				ToggleDropDownMenu(1, nil, DataBroker.dropdown, "cursor", 0, 0)
			end
		end,

		OnTooltipShow = function(tooltip)
			tooltip:AddLine("BagSync")
			tooltip:AddLine(L.LeftClickSearch)
			tooltip:AddLine(L.RightClickBagSyncMenu)
		end,
	})

	BSYC.LDBObject = DataBroker.BrokerPlugin
end

function BSYC:UpdateMinimapIconVisibility()
	local db = EnsureMinimapDB()
	LDBIcon:Refresh("BagSync", db)
end

function BSYC:ResetMinimapIconPosition()
	local db = EnsureMinimapDB()
	db.hide = false
	db.minimapPos = 220
	LDBIcon:Refresh("BagSync", db)
end

function DataBroker:UpdateAddonCompartment()
	if not LDBIcon.IsButtonCompartmentAvailable or not LDBIcon:IsButtonCompartmentAvailable() then
		return
	end

	if not BSYC.options then
		return
	end

	if BSYC.options.enableAddonCompartment == false then
		if LDBIcon:IsButtonInCompartment("BagSync") then
			LDBIcon:RemoveButtonFromCompartment("BagSync")
		end
	else
		if not LDBIcon:IsButtonInCompartment("BagSync") then
			LDBIcon:AddButtonToCompartment("BagSync")
		end
	end
end

function BSYC:TryRegisterAddonCompartment()
	if not DataBroker or not DataBroker.UpdateAddonCompartment then
		return
	end
	DataBroker:UpdateAddonCompartment()
end

function DataBroker:OnEnable()
	self:BuildMinimapDropdown()
	self:CreatePlugin()

	-- Register and load the minimap button
	local db = EnsureMinimapDB()

	if not LDBIcon:IsRegistered("BagSync") then
		LDBIcon:Register("BagSync", DataBroker.BrokerPlugin, db)
	end

	LDBIcon:Refresh("BagSync", db)
	self:UpdateAddonCompartment()

	-- Wait for PLAYER_LOGIN if compartment not yet available
	if not LDBIcon:IsButtonCompartmentAvailable() then
		DataBroker.compartmentWaitFrame = DataBroker.compartmentWaitFrame or CreateFrame("Frame")
		DataBroker.compartmentWaitFrame:RegisterEvent("PLAYER_LOGIN")
		DataBroker.compartmentWaitFrame:SetScript("OnEvent", function()
			DataBroker:UpdateAddonCompartment()
			DataBroker.compartmentWaitFrame:UnregisterEvent("PLAYER_LOGIN")
		end)
	end
end
