local L = BAGSYNC_L
local currentPlayer = UnitName("player")
local currentRealm = select(2, UnitFullName("player"))
local ver = GetAddOnMetadata("BagSync","Version") or 0

local SO = LibStub("LibSimpleOptions-1.0")

function BSOpt_Startup()

	local panel = SO.AddOptionsPanel("BagSync", function() end)

	local title, subText = panel:MakeTitleTextAndSubText("|cFF99CC33BagSync|r [|cFFDF2B2B"..ver.."|r]", "These options allow you to customize the BagSync displays data.")

	--toggle BagSync tooltips
	panel:MakeToggle(
		"name", L["Enable BagSync Tooltips"],
		"description", "",
		"default", false,
		"getFunc", function() return BagSyncOpt["enableTooltips"] end,
		"setFunc", function(value)
			BagSyncOpt["enableTooltips"] = value
			BagSync:resetTooltip()
			end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -16)
	
	--tooltip seperator
	panel:MakeToggle(
		"name", L["Enable empty line seperator above BagSync tooltip display."],
		"description", "",
		"default", false,
		"getFunc", function() return BagSyncOpt["enableTooltipSeperator"] end,
		"setFunc", function(value)
			BagSyncOpt["enableTooltipSeperator"] = value
			BagSync:resetTooltip()
			end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -41)
	
	--total
	panel:MakeToggle(
		"name", L["Display [Total] in tooltips and gold display."],
		"description", "",
		"default", false,
		"getFunc", function() return BagSyncOpt["showTotal"] end,
		"setFunc", function(value)
			BagSyncOpt["showTotal"] = value
			BagSync:resetTooltip()
			end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -66)
	
	--guild names
	panel:MakeToggle(
		"name", L["Display [Guild Name] display in tooltips."],
		"description", "",
		"default", false,
		"getFunc", function() return BagSyncOpt["showGuildNames"] end,
		"setFunc", function(value)
			BagSyncOpt["showGuildNames"] = value
			BagSync:resetTooltip()
			end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -91)
	
	--factions
	panel:MakeToggle(
		"name", L["Display items for both factions (Alliance/Horde)."],
		"description", "",
		"default", false,
		"getFunc", function() return BagSyncOpt["enableFaction"] end,
		"setFunc", function(value)
			BagSyncOpt["enableFaction"] = value
			BagSync:resetTooltip()
			end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -116)
	
	--class colors
	panel:MakeToggle(
		"name", L["Display class colors for characters."],
		"description", "",
		"default", false,
		"getFunc", function() return BagSyncOpt["enableUnitClass"] end,
		"setFunc", function(value)
			BagSyncOpt["enableUnitClass"] = value
			BagSync:resetTooltip()
			end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -141)
	
	--minimap
	panel:MakeToggle(
		"name", L["Display BagSync minimap button."],
		"description", "",
		"default", false,
		"getFunc", function() return BagSyncOpt["enableMinimap"] end,
		"setFunc", function(value)
			BagSyncOpt["enableMinimap"] = value
			if value then BagSync_MinimapButton:Show() else BagSync_MinimapButton:Hide() end
			end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -166)
	
	--guild info
	panel:MakeToggle(
		"name", L["Enable guild bank items."],
		"description", "",
		"default", false,
		"getFunc", function() return BagSyncOpt["enableGuild"] end,
		"setFunc", function(value)
			BagSyncOpt["enableGuild"] = value
			BagSync:resetTooltip()
			end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -191)
	
	--mailbox info
	panel:MakeToggle(
		"name", L["Enable mailbox items."],
		"description", "",
		"default", false,
		"getFunc", function() return BagSyncOpt["enableMailbox"] end,
		"setFunc", function(value)
			BagSyncOpt["enableMailbox"] = value
			BagSync:resetTooltip()
			end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -216)
	
	--auction house
	panel:MakeToggle(
		"name", L["Enable auction house items."],
		"description", "",
		"default", false,
		"getFunc", function() return BagSyncOpt["enableAuction"] end,
		"setFunc", function(value)
			BagSyncOpt["enableAuction"] = value
			BagSync:resetTooltip()
			end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -241)
	
	--tooltip only on bagsync search window
	panel:MakeToggle(
		"name", L["Display modified tooltips ONLY in the BagSync Search window."],
		"description", "",
		"default", false,
		"getFunc", function() return BagSyncOpt["tooltipOnlySearch"] end,
		"setFunc", function(value)
			BagSyncOpt["tooltipOnlySearch"] = value
			BagSync:resetTooltip()
			end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -266)
	
	--cross realms
	panel:MakeToggle(
		"name", L["Enable items for Cross-Realms characters."],
		"description", "",
		"default", false,
		"getFunc", function() return BagSyncOpt["enableCrossRealmsItems"] end,
		"setFunc", function(value)
			BagSyncOpt["enableCrossRealmsItems"] = value
			BagSync:resetTooltip()
			end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -291)
	
	--battle.net account characters
	panel:MakeToggle(
		"name", L["Enable items for current Battle.Net Account characters. |cFFDF2B2B((Not Recommended))|r"],
		"description", "",
		"default", false,
		"getFunc", function() return BagSyncOpt["enableBNetAccountItems"] end,
		"setFunc", function(value)
			BagSyncOpt["enableBNetAccountItems"] = value
			BagSync:resetTooltip()
			end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -316)
	
	--first color (default moss)
	panel:MakeColorPicker(
	    "name", L["Primary BagSync tooltip color."],
	    "description", "",
	    "hasAlpha", false,
	    "defaultR", 128/255,
	    "defaultG", 1,
	    "defaultB", 0,
	    "getFunc", function() return BagSyncOpt.colors.FIRST.r, BagSyncOpt.colors.FIRST.g, BagSyncOpt.colors.FIRST.b end,
	    "setFunc", function(r, g, b) BagSyncOpt.colors.FIRST.r, BagSyncOpt.colors.FIRST.g, BagSyncOpt.colors.FIRST.b = r, g, b end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -341)
	
	--second color (default silver)
	panel:MakeColorPicker(
	    "name", L["Secondary BagSync tooltip color."],
	    "description", "",
	    "hasAlpha", false,
	    "defaultR", 199/255,
	    "defaultG", 199/255,
	    "defaultB", 207/255,
	    "getFunc", function() return BagSyncOpt.colors.SECOND.r, BagSyncOpt.colors.SECOND.g, BagSyncOpt.colors.SECOND.b end,
	    "setFunc", function(r, g, b) BagSyncOpt.colors.SECOND.r, BagSyncOpt.colors.SECOND.g, BagSyncOpt.colors.SECOND.b = r, g, b end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -366)
	
	--total color
	panel:MakeColorPicker(
	    "name", L["BagSync [Total] tooltip color."],
	    "description", "",
	    "hasAlpha", false,
	    "defaultR", 244/255,
	    "defaultG", 164/255,
	    "defaultB", 96/255,
	    "getFunc", function() return BagSyncOpt.colors.TOTAL.r, BagSyncOpt.colors.TOTAL.g, BagSyncOpt.colors.TOTAL.b end,
	    "setFunc", function(r, g, b) BagSyncOpt.colors.TOTAL.r, BagSyncOpt.colors.TOTAL.g, BagSyncOpt.colors.TOTAL.b = r, g, b end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -391)
	
	--guild color
	panel:MakeColorPicker(
	    "name", L["BagSync [Guild] tooltip color."],
	    "description", "",
	    "hasAlpha", false,
	    "defaultR", 101/255,
	    "defaultG", 184/255,
	    "defaultB", 192/255,
	    "getFunc", function() return BagSyncOpt.colors.GUILD.r, BagSyncOpt.colors.GUILD.g, BagSyncOpt.colors.GUILD.b end,
	    "setFunc", function(r, g, b) BagSyncOpt.colors.GUILD.r, BagSyncOpt.colors.GUILD.g, BagSyncOpt.colors.GUILD.b = r, g, b end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -416)
	
	--cross realm color
	panel:MakeColorPicker(
	    "name", L["BagSync [Cross-Realms] tooltip color."],
	    "description", "",
	    "hasAlpha", false,
	    "defaultR", 1,
	    "defaultG", 125/255,
	    "defaultB", 10/255,
	    "getFunc", function() return BagSyncOpt.colors.CROSS.r, BagSyncOpt.colors.CROSS.g, BagSyncOpt.colors.CROSS.b end,
	    "setFunc", function(r, g, b) BagSyncOpt.colors.CROSS.r, BagSyncOpt.colors.CROSS.g, BagSyncOpt.colors.CROSS.b = r, g, b end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -441)
	
	--bnet color
	panel:MakeColorPicker(
	    "name", L["BagSync [Battle.Net] tooltip color."],
	    "description", "",
	    "hasAlpha", false,
	    "defaultR", 53/255,
	    "defaultG", 136/255,
	    "defaultB", 1,
	    "getFunc", function() return BagSyncOpt.colors.BNET.r, BagSyncOpt.colors.BNET.g, BagSyncOpt.colors.BNET.b end,
	    "setFunc", function(r, g, b) BagSyncOpt.colors.BNET.r, BagSyncOpt.colors.BNET.g, BagSyncOpt.colors.BNET.b = r, g, b end
	):SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -466)
	

	--i'm calling a refresh for the panel, because sometimes (like the color picker) some of the items aren't refreshed on the screen due to a /reload
	--so instead I'm just going to force the getFunc for all the controls
	panel:Refresh()
	
end