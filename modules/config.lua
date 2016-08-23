local L = LibStub("AceLocale-3.0"):GetLocale("BagSync", true)
local currentPlayer = UnitName("player")
local currentRealm = select(2, UnitFullName("player"))
local ver = GetAddOnMetadata("BagSync","Version") or 0

local config = LibStub("AceConfig-3.0")
local configDialog = LibStub("AceConfigDialog-3.0")

local options = {}

options.type = "group"
options.name = "BagSync"

options.args = {} --initiate the arguements for the options to display

local function get(info)

	local p, c = string.split(".", info.arg)
	
	if p ~= "color" then
		if BagSyncOpt[c] then --if this is nil then it will default to false
			return BagSyncOpt[c]
		else
			return false
		end
	elseif p == "color" then
		return BagSyncOpt.colors[c].r, BagSyncOpt.colors[c].g, BagSyncOpt.colors[c].b
	end
	
end

local function set(info, arg1, arg2, arg3, arg4)

	local p, c = string.split(".", info.arg)
	
	if p ~= "color" then
		BagSyncOpt[c] = arg1
		if p == "minimap" then
			if arg1 then BagSync_MinimapButton:Show() else BagSync_MinimapButton:Hide() end
		else
			BagSync:resetTooltip()
		end
	elseif p == "color" then
		BagSyncOpt.colors[c].r = arg1
		BagSyncOpt.colors[c].g = arg2
		BagSyncOpt.colors[c].b = arg3
	end
	
end

options.args.heading = {
	type = "description",
	name = L["Settings for various BagSync features."],
	fontSize = "medium",
	order = 1,
	width = "full",
}

options.args.main = {
	type = "group",
	order = 2,
	name = L["Main"],
	desc = L["Main settings for BagSync."],
	args = {
		tooltip = {
			order = 1,
			type = "toggle",
			name = L["Enable BagSync Tooltips"],
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "main.enableTooltips",
		},
		enable = {
			order = 2,
			type = "toggle",
			name = L["Display BagSync tooltip ONLY in the search window."],
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "main.tooltipOnlySearch",
		},
		enable = {
			order = 3,
			type = "toggle",
			name = L["Display BagSync minimap button."],
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "minimap.enableMinimap",
		},
	},
}

options.args.display = {
	type = "group",
	order = 3,
	name = L["Display"],
	desc = L["Settings for the displayed BagSync tooltip information."],
	args = {
		seperator = {
			order = 1,
			type = "toggle",
			name = L["Display empty line seperator."],
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableTooltipSeperator",
		},
		total = {
			order = 2,
			type = "toggle",
			name = L["Display [Total] amount."],
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.showTotal",
		},
		guildbank = {
			order = 3,
			type = "toggle",
			name = L["Display guild bank items."],
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableGuild",
		},
		guildname = {
			order = 4,
			type = "toggle",
			name = L["Display [Guild Name] for guild bank items."],
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.showGuildNames",
		},
		faction = {
			order = 5,
			type = "toggle",
			name = L["Display items for both factions (Alliance/Horde)."],
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableFaction",
		},
		class = {
			order = 6,
			type = "toggle",
			name = L["Display class colors for characters."],
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableUnitClass",
		},
		mailbox = {
			order = 7,
			type = "toggle",
			name = L["Display mailbox items."],
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableMailbox",
		},
		auction = {
			order = 8,
			type = "toggle",
			name = L["Display auction house items."],
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableAuction",
		},
		crossrealm = {
			order = 9,
			type = "toggle",
			name = L["Display Cross-Realms characters."],
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableCrossRealmsItems",
		},
		battlenet = {
			order = 10,
			type = "toggle",
			name = L["Display Battle.Net Account characters |cFFDF2B2B(Not Recommended)|r."],
			width = "full",
			descStyle = "hide",
			get = get,
			set = set,
			arg = "display.enableBNetAccountItems",
		},

	},
}
	
options.args.color = {
	type = "group",
	order = 4,
	name = L["Color"],
	desc = L["Color settings for BagSync tooltip information."],
	args = {
		first = {
			order = 1,
			type = "color",
			name = L["Primary BagSync tooltip color."],
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
			name = L["Secondary BagSync tooltip color."],
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
			name = L["BagSync [Total] tooltip color."],
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
			name = L["BagSync [Guild] tooltip color."],
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
			name = L["BagSync [Cross-Realms] tooltip color."],
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
			name = L["BagSync [Battle.Net] tooltip color."],
			width = "full",
			hasAlpha = false,
			descStyle = "hide",
			get = get,
			set = set,
			arg = "color.bnet",
		},
	},
}

config:RegisterOptionsTable("BagSync", options)
configDialog:AddToBlizOptions("BagSync", "BagSync")
