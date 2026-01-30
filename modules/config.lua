--[[
	config.lua
		BagSync Settings UI (BagSync-only schema)

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local L = BSYC.L
local config = BSYC.Config
local configDialog = BSYC.ConfigDialog
local TITLE_WHITE = { 1, 1, 1 }

local function ShowModuleFrame(name)
	local module = BSYC.GetModule and BSYC:GetModule(name, true)
	if module and module.frame and module.frame.Show then
		module.frame:Show()
	end
end

local function buildFactionIcons()
	local horde = [[|TInterface\FriendsFrame\PlusManz-Horde:20:20|t]]
	local alliance = [[|TInterface\FriendsFrame\PlusManz-Alliance:20:20|t]]
	local brew = [[|TInterface\Icons\Achievement_worldevent_brewmaster:20:20|t]]

	local both = horde .. " " .. alliance
	if BSYC.IsRetail then
		return both .. " " .. brew, both
	end
	return both, both
end

local function buildLocationLegend()
	local allowList = {
		"bag",
		"bank",
		"reagents",
		"guild",
		"equip",
		"mailbox",
		"void",
		"auction",
		"warband",
	}

	local charLocations = ""
	local iconLocations = ""
	for i = 1, #allowList do
		local k = allowList[i]
		charLocations = charLocations .. "|cFF4DD827" .. (L["TooltipSmall_" .. k] or "") .. "|r=|cFFFFD580" .. (L["Tooltip_" .. k] or "") .. "|r, "
		iconLocations = iconLocations .. (L["TooltipIcon_" .. k] or ""):gsub("13:13", "16:16") .. "=|cFFFFD580" .. (L["Tooltip_" .. k] or "") .. "|r, "
	end
	return charLocations, iconLocations
end

local function getRealmNameStyle()
	if BSYC.options and BSYC.options.enableRealmNames then return "names" end
	if BSYC.options and BSYC.options.enableRealmAstrickName then return "asterisk" end
	if BSYC.options and BSYC.options.enableRealmShortName then return "short" end
	return "none"
end

local function setRealmNameStyle(style)
	BSYC.options = BSYC.options or {}
	BSYC.options.enableRealmNames = (style == "names")
	BSYC.options.enableRealmAstrickName = (style == "asterisk")
	BSYC.options.enableRealmShortName = (style == "short")
end

local function getLocationStyle()
	if BSYC.options and BSYC.options.useIconLocations then return "icons" end
	if BSYC.options and BSYC.options.singleCharLocations then return "short" end
	return "full"
end

local function setLocationStyle(style)
	BSYC.options = BSYC.options or {}
	if style == "icons" then
		BSYC.options.useIconLocations = true
		BSYC.options.singleCharLocations = false
	elseif style == "short" then
		BSYC.options.singleCharLocations = true
		BSYC.options.useIconLocations = false
	else
		BSYC.options.singleCharLocations = false
		BSYC.options.useIconLocations = false
	end
end

local function setTooltipSortMode(mode)
	BSYC.options = BSYC.options or {}
	BSYC.options.tooltipSortMode = mode
end

local ReadyCheck = [[|TInterface\RaidFrame\ReadyCheck-Ready:0|t]]
local factionString, factionSmall = buildFactionIcons()
local charLocations, iconLocations = buildLocationLegend()

local modifierValues = {
	{ "NONE", L.ModValue_NONE },
	{ "ALT", L.ModValue_ALT },
	{ "CTRL", L.ModValue_CTRL },
	{ "SHIFT", L.ModValue_SHIFT },
}

local fontOutlineValues = {
	{ "NONE", L.ConfigFontOutline_NONE },
	{ "OUTLINE", L.ConfigFontOutline_OUTLINE },
	{ "THICKOUTLINE", L.ConfigFontOutline_THICKOUTLINE },
}

local tooltipSortModes = {
	{ "realm_character", L.SortMode_RealmCharacter },
	{ "character", L.SortMode_Character },
	{ "class_character", L.SortMode_ClassCharacter },
	{ "totals", L.SortTooltipByTotals },
	{ "custom", L.SortByCustomSortOrder },
}

local realmNameStyleValues = {
	{ "none", L.None or "None" },
	{ "names", L.DisplayRealmNames },
	{ "asterisk", L.DisplayRealmAstrick },
	{ "short", L.DisplayShortRealmName },
}

local locationStyleValues = {
	{ "full", L.DisplayStorageLocStyle_Full or "Display full storage location text." },
	{ "short", L.DisplaySingleCharLocs },
	{ "icons", L.DisplayIconLocs },
}

local function getFontNames()
	if type(BSYC.GetAvailableFontNames) == "function" then
		return BSYC:GetAvailableFontNames()
	end
	return {}
end

local aboutTable = {
	title = "BagSync",
	items = {
		{
			type = "text",
			text = function()
				local getMeta = BSYC.API and BSYC.API.GetAddOnMetadata
				local notes = (getMeta and getMeta("BagSync", "Notes")) or ""
				local version = (getMeta and getMeta("BagSync", "Version")) or ""
				local author = (getMeta and getMeta("BagSync", "Author")) or ""
				return notes
					.. "\n\n\n\n"
					.. "|cFF52D386Version|r: " .. version
					.. "\n\n"
					.. "|cFF52D386Author|r: " .. author
			end,
		},
	},
}

local generalTable = {
	title = L.ConfigMain,
	description = L.ConfigMainHeader,
	items = {
		{
			type = "group",
			title = "BagSync",
			titleColor = TITLE_WHITE,
			inline = true,
			items = {
				{ type = "toggle", label = L.EnableBagSyncTooltip, bind = { "opt", "enableTooltips" }, dirty = "tooltips" },
				{ type = "select", label = L.ShowOnModifier, desc = L.ShowOnModifierDesc, values = modifierValues, bind = { "opt", "tooltipModifer" }, default = "NONE", dirty = "tooltips" },
				{ type = "toggle", label = L.DisplayTooltipOnlySearch, bind = { "opt", "tooltipOnlySearch" }, dirty = "tooltips" },
				{ type = "toggle", label = L.DisplayTooltipCurrencyData, bind = { "opt", "enableCurrencyWindowTooltipData" }, dirty = "tooltips" },
				{ type = "toggle", label = L.FocusSearchEditBox, bind = { "opt", "focusSearchEditBox" } },
				{ type = "toggle", label = L.AlwaysShowSearchFilters, bind = { "opt", "alwaysShowSearchFilters" } },
				{ type = "toggle", label = L.DisplayMinimap, bind = { "minimapEnable" }, dirty = "minimap" },
				{ type = "toggle", label = L.EnableLoginVersionInfo, bind = { "opt", "enableLoginVersionInfo" } },
			},
		},
		{
			type = "group",
			title = L.ConfigExternalTooltip,
			titleColor = TITLE_WHITE,
			inline = true,
			items = {
				{
					type = "toggle",
					label = L.EnableExtTooltip,
					bind = { "opt", "enableExtTooltip" },
					disabled = function() return BSYC.options and BSYC.options.enableTooltips == false end,
					dirty = "tooltips",
				},
				{
					type = "select",
					label = L.ConfigFont,
					values = getFontNames,
					control = "font",
					bind = { "opt", "extTT_Font" },
					default = BSYC.DEFAULT_FONT_NAME,
					dirty = { "fonts", "tooltips" },
				},
				{
					type = "select",
					label = L.ConfigFontOutline,
					values = fontOutlineValues,
					bind = { "opt", "extTT_FontOutline" },
					default = "NONE",
					dirty = { "fonts", "tooltips" },
				},
				{
					type = "range",
					label = L.ConfigFontSize,
					min = 12,
					max = 72,
					step = 1,
					showValue = true,
					bind = { "opt", "extTT_FontSize" },
					default = 12,
					dirty = { "fonts", "tooltips" },
				},
				{ type = "toggle", label = L.ConfigFontMonochrome, bind = { "opt", "extTT_FontMonochrome" }, dirty = { "fonts", "tooltips" } },
			},
		},
	},
}

local keybindingsTable = {
	title = L.ConfigKeybindings,
	description = L.ConfigKeybindingsHeader,
	items = {
		{ type = "keybind", label = L.KeybindSearch, bind = { "keybind", "BAGSYNCSEARCH" }, dirty = "bindings" },
		{ type = "keybind", label = L.KeybindGold, bind = { "keybind", "BAGSYNCGOLD" }, dirty = "bindings" },
		{ type = "keybind", label = L.KeybindBlacklist, bind = { "keybind", "BAGSYNCBLACKLIST" }, dirty = "bindings" },
		{ type = "keybind", label = L.KeybindWhitelist, bind = { "keybind", "BAGSYNCWHITELIST" }, dirty = "bindings" },
		{
			type = "keybind",
			label = L.KeybindCurrency,
			bind = { "keybind", "BAGSYNCCURRENCY" },
			hidden = function() return not (BSYC.CanDoCurrency and BSYC:CanDoCurrency()) end,
			dirty = "bindings",
		},
		{
			type = "keybind",
			label = L.KeybindProfessions,
			bind = { "keybind", "BAGSYNCPROFESSIONS" },
			hidden = function() return not (BSYC.CanDoProfessions and BSYC:CanDoProfessions()) end,
			dirty = "bindings",
		},
		{ type = "keybind", label = L.KeybindProfiles, bind = { "keybind", "BAGSYNCPROFILES" }, dirty = "bindings" },
	},
}

local trackingTable = {
	title = L.ConfigTracking,
	description = L.ConfigTrackingHeader,
	items = {
		{
			type = "group",
			title = L.ConfigTrackingCaution,
			inline = true,
			items = {
				{ type = "text", font = "GameFontNormal", text = L.ConfigTrackingInfo },
			},
		},
		{
			type = "group",
			title = L.ConfigTrackingModules,
			titleColor = TITLE_WHITE,
			inline = true,
			items = {
				{ type = "toggle", label = L.TrackingModule_Bag, bind = { "tracking", "bag" }, dirty = "tooltips" },
				{ type = "toggle", label = L.TrackingModule_Bank, bind = { "tracking", "bank" }, dirty = "tooltips" },
				{
					type = "toggle",
					label = L.TrackingModule_Reagents,
					bind = { "tracking", "reagents" },
					hidden = function() return not IsReagentBankUnlocked or BSYC.IsBankTabsActive end,
					dirty = "tooltips",
				},
				{ type = "toggle", label = L.TrackingModule_Equip, bind = { "tracking", "equip" }, dirty = "tooltips" },
				{ type = "toggle", label = L.TrackingModule_Mailbox, bind = { "tracking", "mailbox" }, dirty = "tooltips" },
				{
					type = "toggle",
					label = L.TrackingModule_Void,
					bind = { "tracking", "void" },
					hidden = function() return not CanUseVoidStorage or BSYC.IsBankTabsActive end,
					dirty = "tooltips",
				},
				{ type = "toggle", label = L.TrackingModule_Auction, bind = { "tracking", "auction" }, dirty = "tooltips" },
				{
					type = "toggle",
					label = L.TrackingModule_Guild,
					bind = { "tracking", "guild" },
					hidden = function() return not CanGuildBankRepair end,
					dirty = "tooltips",
				},
				{
					type = "toggle",
					label = L.TrackingModule_Professions,
					bind = { "tracking", "professions" },
					hidden = function() return not (BSYC.CanDoProfessions and BSYC:CanDoProfessions()) end,
					dirty = "tooltips",
				},
				{
					type = "toggle",
					label = L.TrackingModule_Currency,
					bind = { "tracking", "currency" },
					hidden = function() return not (BSYC.CanDoCurrency and BSYC:CanDoCurrency()) end,
					dirty = "tooltips",
				},
				{
					type = "toggle",
					label = L.TrackingModule_WarbandBank,
					bind = { "tracking", "warband" },
					hidden = function() return not BSYC.isWarbandActive end,
					dirty = "tooltips",
				},
			},
		},
	},
}

local displayTable = {
	title = L.ConfigDisplay,
	description = L.ConfigTooltipHeader,
	items = {
		{
			type = "group",
			title = L.DisplayTooltipStorage,
			titleColor = TITLE_WHITE,
			inline = true,
			hidden = function() return not BSYC.IsRetail end,
			items = {
				{ type = "toggle", label = L.DisplayAccurateBattlePets, bind = { "opt", "enableAccurateBattlePets" }, dirty = "tooltips" },
			},
		},
		{
			type = "group",
			title = L.DisplayTooltipExtra,
			titleColor = TITLE_WHITE,
			inline = true,
			items = {
				{ type = "toggle", label = L.DisplayLineSeparator, bind = { "opt", "enableTooltipSeparator" }, dirty = "tooltips" },
				{ type = "toggle", label = L.DisplayItemID, bind = { "opt", "enableTooltipItemID" }, dirty = "tooltips" },
				{ type = "toggle", label = L.DisplayTotal, bind = { "opt", "showTotal" }, dirty = "tooltips" },
				{
					type = "toggle",
					label = L.DisplayGuildGoldInGoldWindow,
					bind = { "opt", "showGuildInGoldTooltip" },
					disabled = function() return not (BSYC.tracking and BSYC.tracking.guild) end,
					dirty = "tooltips",
				},
				{ type = "toggle", label = L.Display_GSC, bind = { "opt", "enable_GSC_Display" }, dirty = "tooltips" },
				{ type = "toggle", label = L.DisplayFaction .. factionSmall, bind = { "opt", "enableFaction" }, dirty = "tooltips" },
				{ type = "toggle", label = L.DisplayWhiteListOnly, bind = { "opt", "enableWhitelist" }, dirty = "tooltips" },
				{
					type = "button",
					label = L.Whitelist,
					onClick = function() ShowModuleFrame("Whitelist") end,
					disabled = function() return not (BSYC.options and BSYC.options.enableWhitelist) end,
				},
				{
					type = "toggle",
					label = L.DisplaySourceExpansion,
					bind = { "opt", "enableSourceExpansion" },
					hidden = function() return not BSYC.IsRetail end,
					dirty = "tooltips",
				},
				{ type = "toggle", label = L.DisplayItemTypes, bind = { "opt", "enableItemTypes" }, dirty = "tooltips" },
				{
					type = "toggle",
					label = L.DisplayGuildBankTabs,
					bind = { "opt", "showGuildTabs" },
					disabled = function() return not (BSYC.tracking and BSYC.tracking.guild) end,
					hidden = function() return not CanGuildBankRepair end,
					dirty = "tooltips",
				},
				{
					type = "toggle",
					label = L.DisplayWarbandBankTabs,
					bind = { "opt", "showWarbandTabs" },
					disabled = function() return not (BSYC.tracking and BSYC.tracking.warband) end,
					hidden = function() return not BSYC.isWarbandActive end,
					dirty = "tooltips",
				},
				{
					type = "toggle",
					label = L.DisplayBankTabs,
					bind = { "opt", "showBankTabs" },
					disabled = function() return not (BSYC.tracking and BSYC.tracking.bank) end,
					hidden = function() return not BSYC.IsBankTabsActive end,
					dirty = "tooltips",
				},
				{ type = "toggle", label = L.DisplayEquipBagSlots, bind = { "opt", "showEquipBagSlots" }, dirty = "tooltips" },
			},
		},
		{
			type = "group",
			title = L.Currency,
			titleColor = TITLE_WHITE,
			inline = true,
			hidden = function() return not (BSYC.CanDoCurrency and BSYC:CanDoCurrency()) end,
			items = {
				{ type = "toggle", label = L.DisplaySortCurrencyByExpansionFirst, bind = { "opt", "sortCurrencyByExpansion" } },
			},
		},
		{
			type = "group",
			title = L.DisplaySorting,
			titleColor = TITLE_WHITE,
			inline = true,
			items = {
				{ type = "text", text = "|cFFFFD700" .. (L.DisplaySortInfo or "") .. "|r" },
				{
					type = "select",
					label = L.SortMode,
					values = tooltipSortModes,
					get = function() return (BSYC.options and BSYC.options.tooltipSortMode) or "realm_character" end,
					set = setTooltipSortMode,
					dirty = "tooltips",
				},
				{ type = "toggle", label = L.SortCurrentPlayerOnTop, bind = { "opt", "sortShowCurrentPlayerOnTop" }, dirty = "tooltips" },
				{
					type = "button",
					label = L.SortOrder,
					onClick = function() ShowModuleFrame("SortOrder") end,
					disabled = function() return not (BSYC.options and BSYC.options.tooltipSortMode == "custom") end,
				},
			},
		},
		{
			type = "group",
			title = L.DisplayTooltipTags,
			titleColor = TITLE_WHITE,
			inline = true,
			items = {
				{ type = "toggle", label = string.format(L.DisplayGreenCheck, ReadyCheck), bind = { "opt", "enableTooltipGreenCheck" }, dirty = "tooltips" },
				{ type = "toggle", label = L.DisplayFactionIcons .. factionString, bind = { "opt", "enableFactionIcons" }, dirty = "tooltips" },
				{ type = "toggle", label = L.DisplayRaceIcons, bind = { "opt", "showRaceIcons" }, dirty = "tooltips" },
				{
					type = "select",
					label = L.DisplayStorageLocStyle or "Storage location tags",
					values = locationStyleValues,
					get = getLocationStyle,
					set = setLocationStyle,
					dirty = "tooltips",
				},
				{ type = "text", font = "GameFontHighlightSmall", text = "        " .. charLocations },
				{ type = "text", font = "GameFontHighlightSmall", text = "        " .. iconLocations },
			},
		},
		{
			type = "group",
			title = L.DisplayCurrentCharacter,
			titleColor = TITLE_WHITE,
			inline = true,
			items = {
				{ type = "toggle", label = L.DisplayCurrentCharacterOnly, bind = { "opt", "showCurrentCharacterOnly" }, dirty = "tooltips" },
				{ type = "toggle", label = L.DisplayBlacklistCurrentCharOnly, bind = { "opt", "showBLCurrentCharacterOnly" }, dirty = "tooltips" },
			},
		},
		{
			type = "group",
			title = L.DisplayTooltipAccountWide,
			titleColor = TITLE_WHITE,
			inline = true,
			items = {
				{ type = "toggle", label = L.DisplayCurrentRealmName, bind = { "opt", "enableCurrentRealmName" }, dirty = "tooltips" },
				{
					type = "toggle",
					label = L.DisplayCurrentRealmShortName,
					bind = { "opt", "enableCurrentRealmShortName" },
					disabled = function() return not (BSYC.options and BSYC.options.enableCurrentRealmName) end,
					dirty = "tooltips",
				},
				{ type = "toggle", label = L.DisplayCR, bind = { "opt", "enableCR" }, dirty = "tooltips" },
				{ type = "toggle", label = L.DisplayBNET, bind = { "opt", "enableBNET" }, dirty = "tooltips" },
				{
					type = "group",
					title = L.DisplayAccountWideTagOpts,
					inline = true,
					items = {
						{
							type = "toggle",
							label = L.DisplayRealmIDTags,
							bind = { "opt", "enableRealmIDTags" },
							disabled = function()
								local enableCR = (BSYC.options and BSYC.options.enableCR ~= false) or false
								local enableBNET = (BSYC.options and BSYC.options.enableBNET == true) or false
								return not enableCR and not enableBNET
							end,
							dirty = "tooltips",
						},
						{
							type = "select",
							label = L.DisplayRealmNameStyle or "Realm name style",
							values = realmNameStyleValues,
							get = getRealmNameStyle,
							set = setRealmNameStyle,
							disabled = function()
								local enableCR = (BSYC.options and BSYC.options.enableCR ~= false) or false
								local enableBNET = (BSYC.options and BSYC.options.enableBNET == true) or false
								return not enableCR and not enableBNET
							end,
							dirty = "tooltips",
						},
					},
				},
			},
		},
		{
			type = "group",
			title = L.DisplayShowUniqueItemsTotalsTitle,
			titleColor = TITLE_WHITE,
			inline = true,
			items = {
				{ type = "text", font = "GameFontNormal", text = L.DisplayShowUniqueItemsTotals },
				{ type = "text", font = "GameFontNormal", text = L.DisplayShowUniqueItemsTotals_2 },
				{ type = "toggle", label = L.DisplayShowUniqueItemsEnableText, bind = { "opt", "enableShowUniqueItemsTotals" }, dirty = "tooltips" },
			},
		},
	},
}

local colorTable = {
	title = L.ConfigColor,
	description = L.ConfigColorHeader,
	items = {
		{ type = "color", label = L.ColorPrimary, bind = { "color", "first" }, dirty = "tooltips" },
		{ type = "color", label = L.ColorSecondary, bind = { "color", "second" }, dirty = "tooltips" },
		{ type = "color", label = L.ColorTotal, bind = { "color", "total" }, dirty = "tooltips" },
		{ type = "color", label = L.ColorGuild, bind = { "color", "guild" }, dirty = "tooltips" },
		{ type = "color", label = L.ColorWarband, bind = { "color", "warband" }, dirty = "tooltips" },
		{ type = "color", label = L.ColorBNET, bind = { "color", "bnet" }, dirty = "tooltips" },
		{ type = "color", label = L.ColorItemID, bind = { "color", "itemid" }, dirty = "tooltips" },
		{ type = "color", label = L.ColorExpansion, bind = { "color", "expansion" }, dirty = "tooltips" },
		{ type = "color", label = L.ColorItemTypes, bind = { "color", "itemtypes" }, dirty = "tooltips" },
		{ type = "color", label = L.ColorCurrentRealm, bind = { "color", "currentrealm" }, dirty = "tooltips" },
		{ type = "color", label = L.ColorCR, bind = { "color", "cr" }, dirty = "tooltips" },
		{ type = "color", label = L.ColorGuildTabs, bind = { "color", "guildtabs" }, dirty = "tooltips" },
		{ type = "color", label = L.ColorWarbandTabs, bind = { "color", "warbandtabs" }, dirty = "tooltips" },
		{ type = "color", label = L.ColorBankTabs, bind = { "color", "banktabs" }, dirty = "tooltips" },
		{ type = "color", label = L.ColorBagSlots, bind = { "color", "bagslots" }, dirty = "tooltips" },
		{ type = "text", text = "" },
		{
			type = "button",
			label = L.DefaultColors,
			onClick = function()
				local data = BSYC.GetModule and BSYC:GetModule("Data", true)
				if data and data.ResetColors then
					data:ResetColors()
				end
				if _G.InterfaceOptionsFrame then
					_G.InterfaceOptionsFrame:Hide()
				end
			end,
			dirty = "tooltips",
		},
		{ type = "text", text = " " },
		{
			type = "group",
			title = L.ConfigDisplay,
			titleColor = TITLE_WHITE,
			inline = true,
			items = {
				{ type = "toggle", label = L.DisplayClassColor, bind = { "opt", "enableUnitClass" }, dirty = "tooltips" },
				{ type = "toggle", label = L.DisplayItemTotalsByClassColor, bind = { "opt", "itemTotalsByClassColor" }, dirty = "tooltips" },
			},
		},
	},
}

local function buildFAQItems()
	local items = {}
	for i = 1, 7 do
		local qKey = "FAQ_Question_" .. i
		local aKey = qKey .. "_p1"
		local q = L[qKey]
		local a = L[aKey]
		if q and q ~= "" then
			items[#items + 1] = { type = "text", font = "GameFontNormalLarge", text = function() return "|cffffd200" .. (L[qKey] or "") .. "|r" end }
		end
		if a and a ~= "" then
			items[#items + 1] = {
				type = "group",
				title = "",
				inline = true,
				items = {
					{ type = "text", font = "GameFontHighlight", text = function() return L[aKey] or "" end },
				},
			}
		end
		if i < 7 then
			items[#items + 1] = { type = "text", text = " " }
		end
	end
	return items
end

local faqTable = {
	title = L.ConfigFAQ,
	description = L.ConfigFAQHeader,
	items = buildFAQItems(),
}

-- Root category (and used by BSYC:OpenConfig())
config:RegisterOptionsTable("BagSync", aboutTable)
BSYC.aboutPanel = configDialog:AddToBlizOptions("BagSync", "BagSync")

-- Sub-categories
config:RegisterOptionsTable("BagSync-General", generalTable)
BSYC.blizzPanel = configDialog:AddToBlizOptions("BagSync-General", generalTable.title, "BagSync")

config:RegisterOptionsTable("BagSync-Keybindings", keybindingsTable)
configDialog:AddToBlizOptions("BagSync-Keybindings", keybindingsTable.title, "BagSync")

config:RegisterOptionsTable("BagSync-Tracking", trackingTable)
configDialog:AddToBlizOptions("BagSync-Tracking", trackingTable.title, "BagSync")

config:RegisterOptionsTable("BagSync-Display", displayTable)
configDialog:AddToBlizOptions("BagSync-Display", displayTable.title, "BagSync")

config:RegisterOptionsTable("BagSync-Color", colorTable)
configDialog:AddToBlizOptions("BagSync-Color", colorTable.title, "BagSync")

config:RegisterOptionsTable("BagSync-FAQ", faqTable)
configDialog:AddToBlizOptions("BagSync-FAQ", faqTable.title, "BagSync")
