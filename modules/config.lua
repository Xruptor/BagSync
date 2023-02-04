--[[
	config.lua
		A config frame for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local config = LibStub("AceConfig-3.0")
local configDialog = LibStub("AceConfigDialog-3.0")
local MinimapIcon = LibStub("LibDBIcon-1.0")

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
		return BSYC.options.colors[c].r, BSYC.options.colors[c].g, BSYC.options.colors[c].b
	elseif p == "keybind" then
		return GetBindingKey(c)
	elseif c == "tooltipModifer" then
		return BSYC.options[c] or "NONE"
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
		BSYC.options.colors[c].r = arg1
		BSYC.options.colors[c].g = arg2
		BSYC.options.colors[c].b = arg3
	elseif p == "keybind" then
	   local b1, b2 = GetBindingKey(c)
	   if b1 then SetBinding(b1) end
	   if b2 then SetBinding(b2) end
	   SetBinding(arg1, c)
	   SaveBindings(GetCurrentBindingSet())
	elseif c == "tooltipModifer" then
		BSYC.options[c] = arg1
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
		elseif c == "enableXR_BNETRealmNames" and arg1 then
			BSYC.options["enableRealmAstrickName"] = false
			BSYC.options["enableRealmShortName"] = false

		elseif c == "enableRealmAstrickName" and arg1 then
			BSYC.options["enableXR_BNETRealmNames"] = false
			BSYC.options["enableRealmShortName"] = false

		elseif c == "enableRealmShortName" and arg1 then
			BSYC.options["enableXR_BNETRealmNames"] = false
			BSYC.options["enableRealmAstrickName"] = false

		elseif c == "sortByCustomOrder" and arg1 then
			BSYC.options["sortTooltipByTotals"] = false

		elseif c == "sortTooltipByTotals" and arg1 then
			BSYC.options["sortByCustomOrder"] = false
		end

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
		enableexternaltooltip = {
			order = 3,
			type = "toggle",
			name = L.EnableExtTooltip,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "main.enableExtTooltip",
			disabled = function() return not BSYC.options["enableTooltips"] end,
		},
		enabletooltipsearchonly = {
			order = 4,
			type = "toggle",
			name = L.DisplayTooltipOnlySearch,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "main.tooltipOnlySearch",
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
		keybindblacklist = {
			order = 9,
			type = "keybinding",
			name = L.KeybindBlacklist,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCBLACKLIST",
		},
		keybindcurrency = {
			order = 10,
			type = "keybinding",
			name = L.KeybindCurrency,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCCURRENCY",
			hidden = function() return not BSYC.IsRetail end,
		},
		keybindgold = {
			order = 11,
			type = "keybinding",
			name = L.KeybindGold,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCGOLD",
		},
		keybindprofessions = {
			order = 12,
			type = "keybinding",
			name = L.KeybindProfessions,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCPROFESSIONS",
			hidden = function() return not BSYC.IsRetail end,
		},
		keybindprofiles = {
			order = 13,
			type = "keybinding",
			name = L.KeybindProfiles,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCPROFILES",
		},
		keybindsearch = {
			order = 14,
			type = "keybinding",
			name = L.KeybindSearch,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCSEARCH",
		},
	},
}

options.args.display = {
	type = "group",
	order = 3,
	name = L.ConfigDisplay,
	desc = L.ConfigTooltipHeader,
	args = {
		groupstorage = {
			order = 1,
			type = "group",
			name = L.DisplayTooltipStorage,
			guiInline = true,
			args = {
				mailbox = {
					order = 0,
					type = "toggle",
					name = L.DisplayMailbox,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableMailbox",
				},
				auction = {
					order = 1,
					type = "toggle",
					name = L.DisplayAuctionHouse,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableAuction",
				},
				guildbank = {
					order = 2,
					type = "toggle",
					name = L.DisplayGuildBank,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableGuild",
					hidden = function() return BSYC.IsClassic end,
				},
				guildseparately = {
					order = 3,
					type = "toggle",
					name = L.DisplayGuildSeparately,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.showGuildSeparately",
					hidden = function() return BSYC.IsClassic end,
				},
				guildbankscanalert = {
					order = 4,
					type = "toggle",
					name = L.DisplayGuildBankScanAlert,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.showGuildBankScanAlert",
					disabled = function() return not BSYC.options["enableGuild"] end,
					hidden = function() return BSYC.IsClassic end,
				},
				accuratebattlepets = {
					order = 5,
					type = "toggle",
					name = L.DisplayAccurateBattlePets,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableAccurateBattlePets",
					hidden = function() return not BSYC.IsRetail end,
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
				sourcedebuginfo = {
					order = 2,
					type = "toggle",
					name = L.DisplaySourceDebugInfo,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableSourceDebugInfo",
				},
				total = {
					order = 3,
					type = "toggle",
					name = L.DisplayTotal,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.showTotal",
				},
				guildgoldtooltip = {
					order = 4,
					type = "toggle",
					name = L.DisplayGuildGoldInGoldTooltip,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.showGuildInGoldTooltip",
					disabled = function() return not BSYC.options["enableGuild"] end,
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
					disabled = function() return not BSYC.options["enableGuild"] end,
					hidden = function() return BSYC.IsClassic end,
				},
				guildbanktabs = {
					order = 7,
					type = "toggle",
					name = L.DisplayGuildBankTabs,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.showGuildTabs",
					disabled = function() return not BSYC.options["enableGuild"] end,
					hidden = function() return BSYC.IsClassic end,
				},
			}
		},
		groupsorting = {
			name = L.DisplaySorting,
			order = 3,
			type = "group",
			desc = L.DisplaySortInfo,
			guiInline = true,
			args = {
				sorttooltipbytotals = {
					order = 0,
					type = "toggle",
					name = L.SortTooltipByTotals,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.sortTooltipByTotals",
					disabled = function() return BSYC.options["sortByCustomOrder"] end,
				},
				sortbycustomsortorder = {
					order = 1,
					type = "toggle",
					name = L.SortByCustomSortOrder,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.sortByCustomOrder",
					disabled = function() return BSYC.options["sortTooltipByTotals"] end,
				},
				customsortbutton = {
					order = 2,
					type = "execute",
					name = L.SortOrder,
					func = function()
						BSYC:GetModule("SortOrder").frame:Show()
					end,
					disabled = function() return BSYC.options["sortTooltipByTotals"] or not BSYC.options["sortByCustomOrder"] end,
				},
			}
		},
		grouptags = {
			order = 4,
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
					disabled = function() return BSYC.options["useIconLocations"] end,
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
					disabled = function() return BSYC.options["singleCharLocations"] end,
				},
				useiconlocs_2 = {
					order = 6,
					type = "description",
					name = "        "..iconLocations,
					width = "full",
				},
			}
		},
		groupaccountwide = {
			order = 5,
			type = "group",
			name = L.DisplayTooltipAccountWide,
			guiInline = true,
			args = {
				crossrealm = {
					order = 0,
					type = "toggle",
					name = L.DisplayCrossRealm,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableCrossRealmsItems",
				},
				battlenet = {
					order = 1,
					type = "toggle",
					name = L.DisplayBNET,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableBNetAccountItems",
				},
				realmtagsgroups = {
					name = L.DisplayAccountWideTagOpts,
					order = 2,
					type = "group",
					guiInline = true,
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
							disabled = function() return not BSYC.options["enableCrossRealmsItems"] and not BSYC.options["enableBNetAccountItems"] end,
						},
						realmnames = {
							order = 1,
							type = "toggle",
							name = L.DisplayRealmNames,
							width = "full",
							descStyle = "hide",
							get = get,
							set = set,
							arg = "display.enableXR_BNETRealmNames",
							disabled = function()
								if not BSYC.options["enableCrossRealmsItems"] and not BSYC.options["enableBNetAccountItems"] then
									return true
								end
								return BSYC.options["enableRealmAstrickName"] or BSYC.options["enableRealmShortName"]
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
								if not BSYC.options["enableCrossRealmsItems"] and not BSYC.options["enableBNetAccountItems"] then
									return true
								end
								return BSYC.options["enableXR_BNETRealmNames"] or BSYC.options["enableRealmShortName"]
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
								if not BSYC.options["enableCrossRealmsItems"] and not BSYC.options["enableBNetAccountItems"] then
									return true
								end
								return BSYC.options["enableXR_BNETRealmNames"] or BSYC.options["enableRealmAstrickName"]
							end,
						},
					}
				},
			}
		},
		showuniqueitemsgroup = {
			order = 6,
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
	order = 4,
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
		cross = {
			order = 5,
			type = "color",
			name = L.ColorCrossRealm,
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.cross",
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
		guildtabs = {
			order = 8,
			type = "color",
			name = L.ColorGuildTabs,
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.guildtabs",
		},
		resetcolors = {
			order = 9,
			type = "execute",
			name = L.DefaultColors,
			func = function()
				BSYC:GetModule("Data"):ResetColors()
				if InterfaceOptionsFrame then InterfaceOptionsFrame:Hide() end
			end,
		},
		emptyseparator = {
			order = 10,
			fontSize = "medium",
			type = "description",
			name = " ",
		},
		showuniqueitemsgroup = {
			order = 11,
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
	order = 5,
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

local function LoadAboutFrame()

	--Code inspired from tekKonfigAboutPanel
	local about = CreateFrame("Frame", "BagSyncAboutPanel", InterfaceOptionsFramePanelContainer)
	about.name = "BagSync"
	about:Hide()

	local fields = {"Version", "Author"}
	local notes = GetAddOnMetadata("BagSync", "Notes")

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
		local val = GetAddOnMetadata("BagSync", field)
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

	InterfaceOptions_AddCategory(about)

	return about
end

BSYC.aboutPanel = LoadAboutFrame()

-- General Options
config:RegisterOptionsTable("BagSync-General", options.args.main)
BSYC.blizzPanel = configDialog:AddToBlizOptions("BagSync-General", options.args.main.name, "BagSync")

-- Display Options
config:RegisterOptionsTable("BagSync-Display", options.args.display)
configDialog:AddToBlizOptions("BagSync-Display", options.args.display.name, "BagSync")

-- Color Options
config:RegisterOptionsTable("BagSync-Color", options.args.color)
configDialog:AddToBlizOptions("BagSync-Color", options.args.color.name, "BagSync")

-- FAQ / Help Options
config:RegisterOptionsTable("BagSync-FAQ", options.args.faq)
configDialog:AddToBlizOptions("BagSync-FAQ", options.args.faq.name, "BagSync")
