--[[
	config.lua
		A config frame for BagSync

		BagSync - All Rights Reserved - (c) 2024
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local config = LibStub("AceConfig-3.0")
local configDialog = LibStub("AceConfigDialog-3.0")
local MinimapIcon = LibStub("LibDBIcon-1.0")
local SML = LibStub("LibSharedMedia-3.0")
local SML_FONT = SML.MediaType and SML.MediaType.FONT or "font"

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Config", ...) end
end

local options = {}
local ReadyCheck = [[|TInterface\RaidFrame\ReadyCheck-Ready:0|t]]

local factionString = ""
local factionSmall = " "

if BSYC.IsRetail then
	factionString = [[|TInterface\FriendsFrame\PlusManz-Horde:20:20|t]]
	factionString = factionString.." "..[[|TInterface\FriendsFrame\PlusManz-Alliance:20:20|t]]
	factionSmall = factionString
	factionString = factionString.." "..[[|TInterface\Icons\Achievement_worldevent_brewmaster:20:20|t]]

else
	factionString = [[|TInterface\FriendsFrame\PlusManz-Horde:20:20|t]]
	factionString = factionString.." "..[[|TInterface\FriendsFrame\PlusManz-Alliance:20:20|t]]
	factionSmall = factionString
end

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

for i=1, #allowList do
	charLocations = charLocations.."|cFF4DD827"..L["TooltipSmall_"..allowList[i]].."|r=|cFFFFD580"..L["Tooltip_"..allowList[i]].."|r, "
	iconLocations = iconLocations..L["TooltipIcon_"..allowList[i]]:gsub("13:13", "16:16").."=|cFFFFD580"..L["Tooltip_"..allowList[i]].."|r, "
end

options.type = "group"
options.name = "BagSync"

options.args = {} --initiate the arguements for the options to display

local function get(info)

	local p, c = strsplit(".", info.arg)

	if p == "color" then
		return BSYC.colors[c].r, BSYC.colors[c].g, BSYC.colors[c].b
	elseif p == "tracking" then
		return BSYC.tracking[c]
	elseif p == "keybind" then
		return GetBindingKey(c)
	elseif c == "tooltipModifer" or c == "extTT_FontOutline" then
		return BSYC.options[c] or "NONE"
	elseif c == "extTT_FontSize" then
		return BSYC.options[c] or 12
	elseif c == "extTT_Font" then
		for i, v in next, SML:List(SML_FONT) do
			if v == (BSYC.options.extTT_Font or "Friz Quadrata TT") then return i end
		end
	else
		if BSYC.options[c] then --if this is nil then it will default to false
			return BSYC.options[c]
		else
			return false
		end
	end
end

local function set(info, arg1, arg2, arg3, arg4)

	local p, c = strsplit(".", info.arg)

	if p == "color" then
		BSYC.colors[c].r = arg1
		BSYC.colors[c].g = arg2
		BSYC.colors[c].b = arg3
	elseif p == "tracking" then
		BSYC.tracking[c] = arg1
		--rebuild the minimap if any options have changed
		if BSYC:GetModule("DataBroker", true) then
			BSYC:GetModule("DataBroker"):BuildMinimapDropdown()
		end
	elseif p == "keybind" then
	   local b1, b2 = GetBindingKey(c)
	   if b1 then SetBinding(b1) end
	   if b2 then SetBinding(b2) end
	   SetBinding(arg1, c)
	   SaveBindings(GetCurrentBindingSet())
	elseif c == "extTT_Font" then
		local list = SML:List(SML_FONT)
		BSYC.options[c] = list[arg1]
	else
		BSYC.options[c] = arg1

		if p == "minimap" then
			if arg1 then
				MinimapIcon:Show("BagSync")
				BSYC.options.minimap.hide = false
			else
				MinimapIcon:Hide("BagSync")
				BSYC.options.minimap.hide = true
			end
		elseif c == "enableRealmNames" and arg1 then
			BSYC.options.enableRealmAstrickName = false
			BSYC.options.enableRealmShortName = false

		elseif c == "enableRealmAstrickName" and arg1 then
			BSYC.options.enableRealmNames = false
			BSYC.options.enableRealmShortName = false

		elseif c == "enableRealmShortName" and arg1 then
			BSYC.options.enableRealmNames = false
			BSYC.options.enableRealmAstrickName = false

		elseif c == "sortByCustomOrder" and arg1 then
			BSYC.options.sortTooltipByTotals = false

		elseif c == "sortTooltipByTotals" and arg1 then
			BSYC.options.sortByCustomOrder = false
		end

	end

	if p == "font" then
		--recreate the fonts if we changed anything
		BSYC:CreateFonts()
	end

	--reset tooltips just in case we changed any options related to it
	if BSYC:GetModule("Tooltip", true) then
		BSYC:GetModule("Tooltip"):ResetCache()
		BSYC:GetModule("Tooltip"):ResetLastLink()
	end
end

local modValues = {
	["NONE"] = L.ModValue_NONE,
	["ALT"] = L.ModValue_ALT,
	["CTRL"] = L.ModValue_CTRL,
	["SHIFT"] = L.ModValue_SHIFT,
}

local modSorting = {
	[1] = "NONE",
	[2] = "ALT",
	[3] = "CTRL",
	[4] = "SHIFT",
}

options.args.heading = {
	type = "description",
	name = L.ConfigHeader,
	fontSize = "medium",
	order = 1,
	width = "full",
}

options.args.main = {
	type = "group",
	order = 2,
	name = L.ConfigMain,
	desc = L.ConfigMainHeader,
	args = {
		groupmain = {
			name = "BagSync",
			order = 1,
			type = "group",
			descStyle = "hide",
			guiInline = true,
			args = {
				enablebagsynctooltip = {
					order = 1,
					type = "toggle",
					name = L.EnableBagSyncTooltip,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "main.enableTooltips",
				},
				tooltipModifier = {
					order = 2,
					type = "select",
					name = L.ShowOnModifier,
					desc = L.ShowOnModifierDesc,
					values = modValues,
					sorting = modSorting,
					get = get,
					set = set,
					arg = "main.tooltipModifer",
				},
				enabletooltipsearchonly = {
					order = 3,
					type = "toggle",
					name = L.DisplayTooltipOnlySearch,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "main.tooltipOnlySearch",
				},
				enablecurrencytooltipdata = {
					order = 4,
					type = "toggle",
					name = L.DisplayTooltipCurrencyData,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "main.enableCurrencyWindowTooltipData",
				},
				focussearcheditbox = {
					order = 5,
					type = "toggle",
					name = L.FocusSearchEditBox,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "main.focusSearchEditBox",
				},
				alwaysshowadvsearch = {
					order = 6,
					type = "toggle",
					name = L.AlwaysShowAdvSearch,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "main.alwaysShowAdvSearch",
				},
				enableminimap = {
					order = 7,
					type = "toggle",
					name = L.DisplayMinimap,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "minimap.enableMinimap",
				},
				enableversiontext = {
					order = 8,
					type = "toggle",
					name = L.EnableLoginVersionInfo,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "main.enableLoginVersionInfo",
				},
			}
		},
		groupexternaltooltip = {
			name = L.ConfigExternalTooltip,
			order = 2,
			type = "group",
			descStyle = "hide",
			guiInline = true,
			args = {
				enableexternaltooltip = {
					order = 1,
					type = "toggle",
					name = L.EnableExtTooltip,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "main.enableExtTooltip",
					disabled = function() return not BSYC.options.enableTooltips end,
				},
				font = {
					type = "select",
					name = L.ConfigFont,
					order = 2,
					values = SML:List(SML_FONT),
					itemControl = "DDI-Font",
					get = get,
					set = set,
					arg = "font.extTT_Font",
				},
				outline = {
					type = "select",
					name = L.ConfigFontOutline,
					order = 3,
					values = {
						NONE = L.ConfigFontOutline_NONE,
						OUTLINE = L.ConfigFontOutline_OUTLINE,
						THICKOUTLINE = L.ConfigFontOutline_THICKOUTLINE,
					},
					get = get,
					set = set,
					arg = "font.extTT_FontOutline",
				},
				fontsize = {
					type = "range",
					name = L.ConfigFontSize,
					descStyle = "hide",
					order = 4,
					max = 200, softMax = 72,
					min = 10,
					step = 1,
					width = 2,
					get = get,
					set = set,
					arg = "font.extTT_FontSize",
				},
				monochrome = {
					type = "toggle",
					name = L.ConfigFontMonochrome,
					descStyle = "hide",
					order = 5,
					get = get,
					set = set,
					arg = "font.extTT_FontMonochrome",
				},
			}
		},
	},
}

options.args.keybindings = {
	type = "group",
	order = 3,
	name = L.ConfigKeybindings,
	desc = L.ConfigKeybindingsHeader,
	args = {
		keybindsearch = {
			order = 1,
			type = "keybinding",
			name = L.KeybindSearch,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCSEARCH",
		},
		keybindgold = {
			order = 2,
			type = "keybinding",
			name = L.KeybindGold,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCGOLD",
		},
		keybindblacklist = {
			order = 3,
			type = "keybinding",
			name = L.KeybindBlacklist,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCBLACKLIST",
		},
		keybindwhitelist = {
			order = 4,
			type = "keybinding",
			name = L.KeybindWhitelist,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCWHITELIST",
		},
		keybindcurrency = {
			order = 5,
			type = "keybinding",
			name = L.KeybindCurrency,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCCURRENCY",
			hidden = function() return not BSYC:CanDoCurrency() end,
		},
		keybindprofessions = {
			order = 6,
			type = "keybinding",
			name = L.KeybindProfessions,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCPROFESSIONS",
			hidden = function() return not BSYC:CanDoProfessions() end,
		},
		keybindprofiles = {
			order = 7,
			type = "keybinding",
			name = L.KeybindProfiles,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCPROFILES",
		},
	},
}

options.args.tracking = {
	type = "group",
	order = 4,
	name = L.ConfigTracking,
	desc = L.ConfigTrackingHeader,
	args = {
		groupinfo = {
			name = L.ConfigTrackingCaution,
			order = 1,
			type = "group",
			descStyle = "hide",
			guiInline = true,
			args = {
				infotext = {
					order = 0,
					fontSize = "medium",
					type = "description",
					name = L.ConfigTrackingInfo,
				  },
			}
		},
		groupmodules = {
			name = L.ConfigTrackingModules,
			order = 1,
			type = "group",
			descStyle = "hide",
			guiInline = true,
			args = {
				module_bag = {
					order = 1,
					type = "toggle",
					name = L.TrackingModule_Bag,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "tracking.bag",
				},
				module_bank = {
					order = 2,
					type = "toggle",
					name = L.TrackingModule_Bank,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "tracking.bank",
				},
				module_reagents = {
					order = 3,
					type = "toggle",
					name = L.TrackingModule_Reagents,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "tracking.reagents",
					hidden = function() return not IsReagentBankUnlocked end,
				},
				module_equip = {
					order = 4,
					type = "toggle",
					name = L.TrackingModule_Equip,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "tracking.equip",
				},
				module_mailbox = {
					order = 5,
					type = "toggle",
					name = L.TrackingModule_Mailbox,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "tracking.mailbox",
				},
				module_void = {
					order = 6,
					type = "toggle",
					name = L.TrackingModule_Void,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "tracking.void",
					hidden = function() return not CanUseVoidStorage end,
				},
				module_auction = {
					order = 7,
					type = "toggle",
					name = L.TrackingModule_Auction,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "tracking.auction",
				},
				module_guild = {
					order = 8,
					type = "toggle",
					name = L.TrackingModule_Guild,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "tracking.guild",
					hidden = function() return not CanGuildBankRepair end,
				},
				module_professions = {
					order = 9,
					type = "toggle",
					name = L.TrackingModule_Professions,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "tracking.professions",
					hidden = function() return not BSYC:CanDoProfessions() end,
				},
				module_currency = {
					order = 10,
					type = "toggle",
					name = L.TrackingModule_Currency,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "tracking.currency",
					hidden = function() return not BSYC:CanDoCurrency() end,
				},
				module_warband = {
					order = 11,
					type = "toggle",
					name = L.TrackingModule_WarbandBank,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "tracking.warband",
					hidden = function() return not BSYC.isWarbandActive end,
				},
			}
		},
	},
}

options.args.display = {
	type = "group",
	order = 5,
	name = L.ConfigDisplay,
	desc = L.ConfigTooltipHeader,
	args = {
		groupstorage = {
			order = 1,
			type = "group",
			name = L.DisplayTooltipStorage,
			guiInline = true,
			hidden = function() return not BSYC.IsRetail end,
			args = {
				accuratebattlepets = {
					order = 1,
					type = "toggle",
					name = L.DisplayAccurateBattlePets,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableAccurateBattlePets",
				},
			}
		},
		groupextra = {
			order = 2,
			type = "group",
			name = L.DisplayTooltipExtra,
			guiInline = true,
			args = {
				separator = {
					order = 0,
					type = "toggle",
					name = L.DisplayLineSeparator,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableTooltipSeparator",
				},
				itemid = {
					order = 1,
					type = "toggle",
					name = L.DisplayItemID,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableTooltipItemID",
				},
				total = {
					order = 2,
					type = "toggle",
					name = L.DisplayTotal,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.showTotal",
				},
				guildgoldtooltip = {
					order = 3,
					type = "toggle",
					name = L.DisplayGuildGoldInGoldWindow,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.showGuildInGoldTooltip",
					disabled = function() return not BSYC.tracking.guild end,
				},
				gscdisplay = {
					order = 4,
					type = "toggle",
					name = L.Display_GSC,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enable_GSC_Display",
				},
				faction = {
					order = 5,
					type = "toggle",
					name = L.DisplayFaction..factionSmall,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableFaction",
				},
				guildcurrentcharacter = {
					order = 6,
					type = "toggle",
					name = L.DisplayGuildCurrentCharacter,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.showGuildCurrentCharacter",
					disabled = function() return not BSYC.tracking.guild end,
					hidden = function() return not CanGuildBankRepair end,
				},
				whitelistonly = {
					order = 7,
					type = "toggle",
					name = L.DisplayWhiteListOnly,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableWhitelist",
				},
				whitelistbutton = {
					order = 8,
					type = "execute",
					name = L.Whitelist,
					func = function()
						BSYC:GetModule("Whitelist").frame:Show()
					end,
					disabled = function() return not BSYC.options.enableWhitelist end,
				},
				sourceexpansion = {
					order = 9,
					type = "toggle",
					name = L.DisplaySourceExpansion,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableSourceExpansion",
					hidden = function() return not BSYC.IsRetail end,
				},
				itemtypes = {
					order = 10,
					type = "toggle",
					name = L.DisplayItemTypes,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableItemTypes",
				},
				guildbanktabs = {
					order = 11,
					type = "toggle",
					name = L.DisplayGuildBankTabs,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.showGuildTabs",
					disabled = function() return not BSYC.tracking.guild end,
					hidden = function() return not CanGuildBankRepair end,
				},
				warbandbanktabs = {
					order = 12,
					type = "toggle",
					name = L.DisplayWarbandBankTabs,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.showWarbandTabs",
					disabled = function() return not BSYC.tracking.warband end,
					hidden = function() return not BSYC.isWarbandActive end,
				},
				equipbagslots = {
					order = 13,
					type = "toggle",
					name = L.DisplayEquipBagSlots,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.showEquipBagSlots",
				},
			}
		},
		currencyopts = {
			name = L.Currency,
			order = 3,
			type = "group",
			guiInline = true,
			hidden = function() return not BSYC:CanDoCurrency() end,
			args = {
				sortcurrencybyexpansion = {
					order = 0,
					type = "toggle",
					name = L.DisplaySortCurrencyByExpansionFirst,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.sortCurrencyByExpansion",
				},
			}
		},
		groupsorting = {
			name = L.DisplaySorting,
			order = 4,
			type = "group",
			guiInline = true,
			args = {
				groupsortingdesc = {
					order = 0,
					type = "description",
					name = "|cFFFFD700"..L.DisplaySortInfo.."|r",
					width = "full",
				},
				sorttooltipbytotals = {
					order = 1,
					type = "toggle",
					name = L.SortTooltipByTotals,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.sortTooltipByTotals",
					disabled = function() return BSYC.options.sortByCustomOrder end,
				},
				sortbycustomsortorder = {
					order = 2,
					type = "toggle",
					name = L.SortByCustomSortOrder,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.sortByCustomOrder",
					disabled = function() return BSYC.options.sortTooltipByTotals end,
				},
				customsortbutton = {
					order = 3,
					type = "execute",
					name = L.SortOrder,
					func = function()
						BSYC:GetModule("SortOrder").frame:Show()
					end,
					disabled = function() return BSYC.options.sortTooltipByTotals or not BSYC.options.sortByCustomOrder end,
				},
			}
		},
		grouptags = {
			order = 5,
			type = "group",
			name = L.DisplayTooltipTags,
			guiInline = true,
			args = {
				greencheck = {
					order = 0,
					type = "toggle",
					name = string.format(L.DisplayGreenCheck, ReadyCheck),
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableTooltipGreenCheck",
				},
				factionicon = {
					order = 1,
					type = "toggle",
					name = L.DisplayFactionIcons..factionString,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableFactionIcons",
				},
				raceicon = {
					order = 2,
					type = "toggle",
					name = L.DisplayRaceIcons,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.showRaceIcons",
				},
				singlecharlocs_1 = {
					order = 3,
					type = "toggle",
					name = L.DisplaySingleCharLocs,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.singleCharLocations",
					disabled = function() return BSYC.options.useIconLocations end,
				},
				singlecharlocs_2 = {
					order = 4,
					type = "description",
					name = "        "..charLocations,
					width = "full",
				},
				useiconlocs_1 = {
					order = 5,
					type = "toggle",
					name = L.DisplayIconLocs,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.useIconLocations",
					disabled = function() return BSYC.options.singleCharLocations end,
				},
				useiconlocs_2 = {
					order = 6,
					type = "description",
					name = "        "..iconLocations,
					width = "full",
				},
			}
		},
		groupcurrentplayer = {
			order = 6,
			type = "group",
			name = L.DisplayCurrentCharacter,
			guiInline = true,
			args = {
				DisplayCurrentCharacteronly = {
					order = 1,
					type = "toggle",
					name = L.DisplayCurrentCharacterOnly,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.showCurrentCharacterOnly",
					--mint warning |cFF44EE77Mint|r
				},
				DisplayBlacklistCurrentCharOnly = {
					order = 2,
					type = "toggle",
					name = L.DisplayBlacklistCurrentCharOnly,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.showBLCurrentCharacterOnly",
				},
			}
		},
		groupaccountwide = {
			order = 7,
			type = "group",
			name = L.DisplayTooltipAccountWide,
			guiInline = true,
			--hidden = function() return BSYC.options.showCurrentCharacterOnly end,
			args = {
				currentrealmname = {
					order = 0,
					type = "toggle",
					name = L.DisplayCurrentRealmName,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableCurrentRealmName",
				},
				currentrealmshortname = {
					order = 1,
					type = "toggle",
					name = L.DisplayCurrentRealmShortName,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableCurrentRealmShortName",
					disabled = function() return not BSYC.options.enableCurrentRealmName end,
				},
				connectedrealm = {
					order = 2,
					type = "toggle",
					name = L.DisplayCR,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableCR",
				},
				battlenet = {
					order = 3,
					type = "toggle",
					name = L.DisplayBNET,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableBNET",
				},
				realmtagsgroups = {
					name = L.DisplayAccountWideTagOpts,
					order = 4,
					type = "group",
					guiInline = true,
					--hidden = function() return BSYC.options.showCurrentCharacterOnly end,
					args = {
						realmidtags = {
							order = 0,
							type = "toggle",
							name = L.DisplayRealmIDTags,
							width = "full",
							descStyle = "hide",
							get = get,
							set = set,
							arg = "display.enableRealmIDTags",
							disabled = function() return not BSYC.options.enableCR and not BSYC.options.enableBNET end,
						},
						realmnames = {
							order = 1,
							type = "toggle",
							name = L.DisplayRealmNames,
							width = "full",
							descStyle = "hide",
							get = get,
							set = set,
							arg = "display.enableRealmNames",
							disabled = function()
								if not BSYC.options.enableCR and not BSYC.options.enableBNET then
									return true
								end
								return BSYC.options.enableRealmAstrickName or BSYC.options.enableRealmShortName
							end,
						},
						realmastrick = {
							order = 2,
							type = "toggle",
							name = L.DisplayRealmAstrick,
							width = "full",
							descStyle = "hide",
							get = get,
							set = set,
							arg = "display.enableRealmAstrickName",
							disabled = function()
								if not BSYC.options.enableCR and not BSYC.options.enableBNET then
									return true
								end
								return BSYC.options.enableRealmNames or BSYC.options.enableRealmShortName
							end,
						},
						realmshortname = {
							order = 3,
							type = "toggle",
							name = L.DisplayShortRealmName,
							width = "full",
							descStyle = "hide",
							get = get,
							set = set,
							arg = "display.enableRealmShortName",
							disabled = function()
								if not BSYC.options.enableCR and not BSYC.options.enableBNET then
									return true
								end
								return BSYC.options.enableRealmNames or BSYC.options.enableRealmAstrickName
							end,
						},
					}
				},
			}
		},
		showuniqueitemsgroup = {
			order = 8,
			name = L.DisplayShowUniqueItemsTotalsTitle,
			type = "group",
			guiInline = true,
			args = {
				title = {
				  order = 0,
				  fontSize = "medium",
				  type = "description",
				  name = L.DisplayShowUniqueItemsTotals,
				},
				title_2 = {
				  order = 1,
				  fontSize = "medium",
				  type = "description",
				  name = L.DisplayShowUniqueItemsTotals_2,
				},
				showuniqueitems = {
					order = 2,
					type = "toggle",
					name = L.DisplayShowUniqueItemsEnableText,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableShowUniqueItemsTotals",
				}
			}
		},
	},
}

options.args.color = {
	type = "group",
	order = 6,
	name = L.ConfigColor,
	desc = L.ConfigColorHeader,
	args = {
		first = {
			order = 1,
			type = "color",
			name = L.ColorPrimary,
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.first",
		},
		second = {
			order = 2,
			type = "color",
			name = L.ColorSecondary,
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.second",
		},
		total = {
			order = 3,
			type = "color",
			name = L.ColorTotal,
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.total",
		},
		guild = {
			order = 4,
			type = "color",
			name = L.ColorGuild,
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.guild",
		},
		warband = {
			order = 5,
			type = "color",
			name = L.ColorWarband,
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.warband",
		},
		bnet = {
			order = 6,
			type = "color",
			name = L.ColorBNET,
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.bnet",
		},
		itemid = {
			order = 7,
			type = "color",
			name = L.ColorItemID,
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.itemid",
		},
		expansion = {
			order = 8,
			type = "color",
			name = L.ColorExpansion,
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.expansion",
		},
		itemtypes = {
			order = 9,
			type = "color",
			name = L.ColorItemTypes,
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.itemtypes",
		},
		currentrealm = {
			order = 10,
			type = "color",
			name = L.ColorCurrentRealm,
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.currentrealm",
		},
		cr = {
			order = 11,
			type = "color",
			name = L.ColorCR,
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.cr",
		},
		guildtabs = {
			order = 12,
			type = "color",
			name = L.ColorGuildTabs,
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.guildtabs",
		},
		warbandtabs = {
			order = 13,
			type = "color",
			name = L.ColorWarbandTabs,
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.warbandtabs",
		},
		bagslots = {
			order = 14,
			type = "color",
			name = L.ColorBagSlots,
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.bagslots",
		},
		resetcolors = {
			order = 15,
			type = "execute",
			name = L.DefaultColors,
			func = function()
				BSYC:GetModule("Data"):ResetColors()
				if InterfaceOptionsFrame then InterfaceOptionsFrame:Hide() end
			end,
		},
		emptyseparator = {
			order = 16,
			fontSize = "medium",
			type = "description",
			name = " ",
		},
		showuniqueitemsgroup = {
			order = 17,
			name = L.ConfigDisplay,
			type = "group",
			guiInline = true,
			args = {
				class = {
					order = 0,
					type = "toggle",
					name = L.DisplayClassColor,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableUnitClass",
				},
				totalsbyclasscolor = {
					order = 1,
					type = "toggle",
					name = L.DisplayItemTotalsByClassColor,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.itemTotalsByClassColor",
				},
			}
		},
	},
}

options.args.faq = {
	type = "group",
	order = 7,
	name = L.ConfigFAQ,
	desc = L.ConfigFAQHeader,
	args = {
		question_1 = {
			order = 1,
			name = L.FAQ_Question_1,
			type = "group",
			guiInline = true,
			args = {
				title = {
				  order = 0,
				  fontSize = "medium",
				  type = "description",
				  name = L.FAQ_Question_1_p1,
				},
			}
		},
		question_2 = {
			order = 2,
			name = L.FAQ_Question_2,
			type = "group",
			guiInline = true,
			args = {
				title = {
				  order = 0,
				  fontSize = "medium",
				  type = "description",
				  name = L.FAQ_Question_2_p1,
				},
			}
		},
		question_3 = {
			order = 3,
			name = L.FAQ_Question_3,
			type = "group",
			guiInline = true,
			args = {
				title = {
				  order = 0,
				  fontSize = "medium",
				  type = "description",
				  name = L.FAQ_Question_3_p1,
				},
			}
		},
		question_4 = {
			order = 4,
			name = L.FAQ_Question_4,
			type = "group",
			guiInline = true,
			args = {
				title = {
				  order = 0,
				  fontSize = "medium",
				  type = "description",
				  name = L.FAQ_Question_4_p1,
				},
			}
		},
		question_5 = {
			order = 5,
			name = L.FAQ_Question_5,
			type = "group",
			guiInline = true,
			args = {
				title = {
				  order = 0,
				  fontSize = "medium",
				  type = "description",
				  name = L.FAQ_Question_5_p1,
				},
			}
		},
		question_6 = {
			order = 6,
			name = L.FAQ_Question_6,
			type = "group",
			guiInline = true,
			args = {
				title = {
				  order = 0,
				  fontSize = "medium",
				  type = "description",
				  name = L.FAQ_Question_6_p1,
				},
			}
		},
		question_7 = {
			order = 7,
			name = L.FAQ_Question_7,
			type = "group",
			guiInline = true,
			args = {
				title = {
				  order = 0,
				  fontSize = "medium",
				  type = "description",
				  name = L.FAQ_Question_7_p1,
				},
			}
		},
	},
}

local aboutOptions = {
	type = "group",
	args = {
		version = {
			order = 1,
			type = "description",
			name = function() return C_AddOns.GetAddOnMetadata("BagSync", "Notes")..
				"\n\n\n\n"..
				"|cFF52D386Version|r: "..C_AddOns.GetAddOnMetadata("BagSync", "Version")..
				"\n\n"..
				"|cFF52D386Author|r: "..C_AddOns.GetAddOnMetadata("BagSync", "Author")
			end,
		}
	},
}

local function LoadAboutFrame()

	--Code inspired from tekKonfigAboutPanel
	local about = CreateFrame("Frame", "BagSyncAboutPanel", InterfaceOptionsFramePanelContainer)
	about.name = "BagSync"
	about:Hide()

	local fields = {"Version", "Author"}
	local notes = C_AddOns.GetAddOnMetadata("BagSync", "Notes")

	local title = about:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")

	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("BagSync")

	local subtitle = about:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetHeight(32)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetPoint("RIGHT", about, -32, 0)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText(notes)

	local anchor
	for _,field in pairs(fields) do
		local val = C_AddOns.GetAddOnMetadata("BagSync", field)
		if val then
			local title = about:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			title:SetWidth(75)
			if not anchor then title:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", -2, -8)
			else title:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6) end
			title:SetJustifyH("RIGHT")
			title:SetText(field:gsub("X%-", ""))

			local detail = about:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			detail:SetPoint("LEFT", title, "RIGHT", 4, 0)
			detail:SetPoint("RIGHT", -16, 0)
			detail:SetJustifyH("LEFT")
			detail:SetText(val)

			anchor = title
		end
	end

	if InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(about)
	else
		local category, layout = _G.Settings.RegisterCanvasLayoutCategory(about, about.name);
		_G.Settings.RegisterAddOnCategory(category);
		addon.settingsCategory = category
	end

	return about
end

local function makeConfigPanel()
    local frame
	--this uses the new Settings Panel
    if _G.Settings and type(_G.Settings) == "table" and _G.Settings.RegisterAddOnCategory then
		config:RegisterOptionsTable("BagSync", aboutOptions)
		frame = configDialog:AddToBlizOptions("BagSync", "BagSync")
    else
		--this is for the old settings panel system
        frame = LoadAboutFrame()
    end
    frame:Hide()
    return frame
end

BSYC.aboutPanel = makeConfigPanel()

-- General Options
config:RegisterOptionsTable("BagSync-General", options.args.main)
BSYC.blizzPanel = configDialog:AddToBlizOptions("BagSync-General", options.args.main.name, "BagSync")

-- Keybindings Options
config:RegisterOptionsTable("BagSync-Keybindings", options.args.keybindings)
configDialog:AddToBlizOptions("BagSync-Keybindings", options.args.keybindings.name, "BagSync")

-- Tracking Options
config:RegisterOptionsTable("BagSync-Tracking", options.args.tracking)
configDialog:AddToBlizOptions("BagSync-Tracking", options.args.tracking.name, "BagSync")

-- Display Options
config:RegisterOptionsTable("BagSync-Display", options.args.display)
configDialog:AddToBlizOptions("BagSync-Display", options.args.display.name, "BagSync")

-- Color Options
config:RegisterOptionsTable("BagSync-Color", options.args.color)
configDialog:AddToBlizOptions("BagSync-Color", options.args.color.name, "BagSync")

-- FAQ / Help Options
config:RegisterOptionsTable("BagSync-FAQ", options.args.faq)
configDialog:AddToBlizOptions("BagSync-FAQ", options.args.faq.name, "BagSync")
