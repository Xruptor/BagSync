--[[
	config.lua
		A config frame for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local config = LibStub("AceConfig-3.0")
local configDialog = LibStub("AceConfigDialog-3.0")

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
local function Debug(...)
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", "CONFIG")
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end
end

local options = {}
local ReadyCheck = [[|TInterface\RaidFrame\ReadyCheck-Ready:0|t]]

local 	factionString = " ( "..[[|TInterface\Icons\Inv_misc_tournaments_banner_orc:18|t]]
		factionString = factionString.." "..[[|TInterface\Icons\Inv_misc_tournaments_banner_human:18|t]]
		factionString = factionString.." "..[[|TInterface\Icons\Achievement_worldevent_brewmaster:18|t]]..")"

options.type = "group"
options.name = "BagSync"

options.args = {} --initiate the arguements for the options to display

local function get(info)

	local p, c = string.split(".", info.arg)
	
	if p == "color" then
		return BSYC.options.colors[c].r, BSYC.options.colors[c].g, BSYC.options.colors[c].b
	elseif p == "keybind" then
		return GetBindingKey(c)
	else
		if BSYC.options[c] then --if this is nil then it will default to false
			return BSYC.options[c]
		else
			return false
		end
	end
	
end

local function set(info, arg1, arg2, arg3, arg4)

	local p, c = string.split(".", info.arg)
	
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
	else
		BSYC.options[c] = arg1
		if p == "minimap" then
			if arg1 then BagSync_MinimapButton:Show() else BagSync_MinimapButton:Hide() end
		else
			--BSYC:ResetTooltip()
		end
	end
	
end

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
		enabletooltipsearchonly = {
			order = 2,
			type = "toggle",
			name = L.DisplayTooltipOnlySearch,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "main.tooltipOnlySearch",
		},
		enableminimap = {
			order = 3,
			type = "toggle",
			name = L.DisplayMinimap,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "minimap.enableMinimap",
		},
		enableversiontext = {
			order = 4,
			type = "toggle",
			name = L.EnableLoginVersionInfo,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "main.enableLoginVersionInfo",
		},
		keybindblacklist = {
			order = 5,
			type = "keybinding",
			name = L.KeybindBlacklist,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCBLACKLIST",
		},
		keybindcurrency = {
			order = 6,
			type = "keybinding",
			name = L.KeybindCurrency,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCCURRENCY",
		},
		keybindgold = {
			order = 7,
			type = "keybinding",
			name = L.KeybindGold,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCGOLD",
		},
		keybindprofessions = {
			order = 8,
			type = "keybinding",
			name = L.KeybindProfessions,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCPROFESSIONS",
		},
		keybindprofiles = {
			order = 9,
			type = "keybinding",
			name = L.KeybindProfiles,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "keybind.BAGSYNCPROFILES",
		},
		keybindsearch = {
			order = 10,
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
		seperator = {
			order = 1,
			type = "toggle",
			name = L.DisplayLineSeperator,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableTooltipSeperator",
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
		guildbank = {
			order = 3,
			type = "toggle",
			name = L.DisplayGuildBank,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableGuild",
		},
		guildname = {
			order = 4,
			type = "toggle",
			name = L.DisplayGuildName,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.showGuildNames",
		},
		guildgoldtooltip = {
			order = 5,
			type = "toggle",
			name = L.DisplayGuildGoldInGoldTooltip,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.showGuildInGoldTooltip",
		},
		faction = {
			order = 6,
			type = "toggle",
			name = L.DisplayFaction,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableFaction",
		},
		class = {
			order = 7,
			type = "toggle",
			name = L.DisplayClassColor,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableUnitClass",
		},
		mailbox = {
			order = 8,
			type = "toggle",
			name = L.DisplayMailbox,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableMailbox",
		},
		auction = {
			order = 9,
			type = "toggle",
			name = L.DisplayAuctionHouse,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableAuction",
		},
		crossrealm = {
			order = 10,
			type = "toggle",
			name = L.DisplayCrossRealm,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableCrossRealmsItems",
		},
		battlenet = {
			order = 11,
			type = "toggle",
			name = L.DisplayBNET,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableBNetAccountItems",
		},
		itemid = {
			order = 12,
			type = "toggle",
			name = L.DisplayItemID,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableTooltipItemID",
		},
		greencheck = {
			order = 13,
			type = "toggle",
			name = string.format(L.DisplayGreenCheck, ReadyCheck),
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableTooltipGreenCheck",
		},
		realmidtags = {
			order = 14,
			type = "toggle",
			name = L.DisplayRealmIDTags,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableRealmIDTags",
		},
		realmastrick = {
			order = 15,
			type = "toggle",
			name = L.DisplayRealmAstrick,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableRealmAstrickName",
		},
		realmshortname = {
			order = 16,
			type = "toggle",
			name = L.DisplayShortRealmName,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableRealmShortName",
		},
		factionicon = {
			order = 17,
			type = "toggle",
			name = L.DisplayFactionIcons..factionString,
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableFactionIcons",
		},
		showuniqueitemsgroup = {
			order = 18,
			name = L.DisplayShowUniqueItemsTotalsTitle,
			type = 'group',
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
					type = 'toggle',
					name = L.DisplayShowUniqueItemsEnableText,
					width = "full",
					descStyle = "hide",
					get = get,
					set = set,
					arg = "display.enableShowUniqueItemsTotals",
				}
			}
		}
	
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
			type = 'group',
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
			type = 'group',
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
			type = 'group',
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
			type = 'group',
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

