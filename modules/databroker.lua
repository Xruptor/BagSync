--[[
	databroker.lua
		A LibDataBroker plugin + LibDBIcon minimap icon for BagSync

	BagSync - All Rights Reserved - (c) 2025
	License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local DataBroker = BSYC:NewModule("DataBroker")
local UI = BSYC:GetModule("UI")
local L = BSYC.L

local LDB = _G.LibStub and _G.LibStub("LibDataBroker-1.1", true)
local LDBIcon = _G.LibStub and _G.LibStub("LibDBIcon-1.0", true)

if not LDB then return end
if not LDBIcon then return end

local function Debug(level, ...)
	if BSYC.DEBUG then BSYC.DEBUG(level, "DataBroker", ...) end
end

function DataBroker:BuildMinimapDropdown()
	if _G["bgsMinimapDD"] then _G["bgsMinimapDD"] = nil end

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

	bgsMinimapDD.initialize = function(_, level)
		if level == 1 then
			if PlaySound and SOUNDKIT and SOUNDKIT.GS_TITLE_OPTION_EXIT then
				PlaySound(SOUNDKIT.GS_TITLE_OPTION_EXIT)
			end
			addButton(level, "BagSync        ", 1, 1)
			addButton(level, L.Search, nil, 1, nil, "search", function()
				BSYC:GetModule("Search").frame:Show()
			end)
			if BSYC:CanDoCurrency() and BSYC.tracking.currency then
				addButton(level, L.Currency, nil, 1, nil, "currency", function()
					BSYC:GetModule("Currency").frame:Show()
				end)
			end
			if BSYC:CanDoProfessions() and BSYC.tracking.professions then
				addButton(level, L.Professions, nil, 1, nil, "professions", function()
					BSYC:GetModule("Professions").frame:Show()
				end)
			end
			addButton(level, L.Blacklist, nil, 1, nil, "blacklist", function()
				BSYC:GetModule("Blacklist").frame:Show()
			end)
			addButton(level, L.Whitelist, nil, 1, nil, "whitelist", function()
				BSYC:GetModule("Whitelist").frame:Show()
			end)
			addButton(level, L.Gold, nil, 1, nil, "gold", function()
				BSYC:GetModule("Gold").frame:Show()
			end)
			addButton(level, L.Profiles, nil, 1, nil, "profiles", function()
				BSYC:GetModule("Profiles").frame:Show()
			end)
			addButton(level, L.SortOrder, nil, 1, nil, "sortorder", function()
				BSYC:GetModule("SortOrder").frame:Show()
			end)
			addButton(level, L.FixDB, nil, 1, nil, "fixdb", function()
				BSYC:GetModule("Data"):FixDB()
			end)
			addButton(level, L.Debug, nil, 1, nil, "debug", function()
				BSYC:GetModule("Debug").frame:Show()
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
	if LDB.GetDataObjectByName then
		local existing = LDB:GetDataObjectByName("BagSync")
		if existing then
			DataBroker.BrokerPlugin = existing
			BSYC.LDBObject = existing
			return
		end
	end

	DataBroker.BrokerPlugin = LDB:NewDataObject("BagSync", {
		type = "launcher",
		icon = "Interface\\AddOns\\BagSync\\media\\icon",
		label = "BagSync",

		OnClick = function(_, button)
			if button == "LeftButton" then
				local search = BSYC:GetModule("Search")
				if search.frame:IsVisible() then
					search.frame:Hide()
					return
				end
				search.frame:Show()
			elseif button == "RightButton" then
				if LDBIcon.tooltip then LDBIcon.tooltip:Hide() end
				ToggleDropDownMenu(1, nil, DataBroker.dropdown, "cursor", 0, 0)
			end
		end,

		OnTooltipShow = function(self)
			self:AddLine("BagSync")
			self:AddLine(L.LeftClickSearch)
			self:AddLine(L.RightClickBagSyncMenu)
		end,
	})
	BSYC.LDBObject = DataBroker.BrokerPlugin
end

function BSYC:UpdateMinimapIconVisibility()
	BSYC.options = BSYC.options or {}
	BSYC.options.minimap = BSYC.options.minimap or {}
	local db = BSYC.options.minimap
	if db.hide == nil then db.hide = false end
	if LDBIcon.Refresh then
		LDBIcon:Refresh("BagSync", db)
	end
end

function BSYC:ResetMinimapIconPosition()
	BSYC.options = BSYC.options or {}
	BSYC.options.minimap = BSYC.options.minimap or {}
	local db = BSYC.options.minimap
	db.hide = false
	db.minimapPos = 220
	if LDBIcon.Refresh then
		LDBIcon:Refresh("BagSync", db)
	end
end

function DataBroker:UpdateAddonCompartment()
	if not LDBIcon.IsButtonCompartmentAvailable or not LDBIcon:IsButtonCompartmentAvailable() then
		return
	end
	if BSYC.options and BSYC.options.enableAddonCompartment == false then
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
	if not DataBroker or not DataBroker.UpdateAddonCompartment then return end
	DataBroker:UpdateAddonCompartment()
end

function DataBroker:OnEnable()
	self:BuildMinimapDropdown()
	self:CreatePlugin()

	--register and load the minimap button
	BSYC.options = BSYC.options or {}
	BSYC.options.minimap = BSYC.options.minimap or {}
	local db = BSYC.options.minimap
	if not LDBIcon.IsRegistered or not LDBIcon:IsRegistered("BagSync") then
		LDBIcon:Register("BagSync", DataBroker.BrokerPlugin, db)
	end
	if LDBIcon.Refresh then
		LDBIcon:Refresh("BagSync", db)
	end
	self:UpdateAddonCompartment()

	if not LDBIcon:IsButtonCompartmentAvailable() then
		local waitFrame = CreateFrame("Frame")
		waitFrame:RegisterEvent("PLAYER_LOGIN")
		waitFrame:SetScript("OnEvent", function()
			DataBroker:UpdateAddonCompartment()
			waitFrame:UnregisterEvent("PLAYER_LOGIN")
		end)
	end
end
