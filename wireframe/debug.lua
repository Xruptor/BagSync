--[[
	debug.lua
		Provides some debugging information to assist in squashing bugs.

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local Debug = BSYC:NewModule("Debug")

local xListLen = 500
local debugWidth = 880
local debugHeight = 465

local function unescape(str)
    str = gsub(str, "|T.-|t", "") --textures in chat like currency coins and such
	str = gsub(str, "|H.-|h(.-)|h", "%1") --links, just put the item description and chat color
	str = gsub(str, "{.-}", "") --remove raid icons from chat

    return str
end

function Debug:OnEnable()
    local DebugFrame = _G.CreateFrame("Frame", nil, UIParent, "BagSyncFrameTemplate")
	Mixin(DebugFrame, Debug) --implement new frame to our parent module Mixin, to have access to parent methods
	DebugFrame:Hide()

    DebugFrame.TitleText:SetText("BagSync - "..L.Debug)
	DebugFrame:SetWidth(debugWidth)
    DebugFrame:SetHeight(debugHeight)
    DebugFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    DebugFrame:EnableMouse(true) --don't allow clickthrough
    DebugFrame:SetMovable(true)
    DebugFrame:SetResizable(false)
    DebugFrame:SetFrameStrata("BACKGROUND")
	DebugFrame:RegisterForDrag("LeftButton")
	DebugFrame:SetClampedToScreen(true)
	DebugFrame:SetScript("OnDragStart", DebugFrame.StartMoving)
	DebugFrame:SetScript("OnDragStop", DebugFrame.StopMovingOrSizing)
	DebugFrame:SetScript("OnShow", function() Debug:OnShow() end)
	DebugFrame:SetScript("OnHide", function() Debug:OnHide() end)
	local closeBtn = CreateFrame("Button", nil, DebugFrame, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", C_EditMode and -3 or 2, C_EditMode and -3 or 1) --check for classic servers to adjust for positioning using a check for the new EditMode		
    DebugFrame.closeBtn = closeBtn
    Debug.frame = DebugFrame

    Debug.scrollFrame = _G.CreateFrame("ScrollFrame", nil, DebugFrame, "HybridScrollFrameTemplate")
    Debug.scrollFrame:SetWidth(debugWidth-44)
    Debug.scrollFrame:SetPoint("TOPLEFT", DebugFrame, "TOPLEFT", 13, -30)
    --set ScrollFrame height by altering the distance from the bottom of the frame
    Debug.scrollFrame:SetPoint("BOTTOMLEFT", DebugFrame, "BOTTOMLEFT", -25, 15)
    Debug.scrollFrame.scrollBar = CreateFrame("Slider", "$parentscrollBar", Debug.scrollFrame, "HybridScrollBarTemplate")
    Debug.scrollFrame.scrollBar:SetPoint("TOPLEFT", Debug.scrollFrame, "TOPRIGHT", 1, -16)
    Debug.scrollFrame.scrollBar:SetPoint("BOTTOMLEFT", Debug.scrollFrame, "BOTTOMRIGHT", 1, 12)
	--initiate the scrollFrame
    --the items we will work with
    Debug.debugItems = {}
	Debug.scrollFrame.update = function() Debug:RefreshList(); end
    HybridScrollFrame_SetDoNotHideScrollBar(Debug.scrollFrame, true)
	HybridScrollFrame_CreateButtons(Debug.scrollFrame, "BagSyncListSimpleItemTemplate")

	--Options Frame
	Debug.optionsFrame = CreateFrame("Frame", nil, DebugFrame, BackdropTemplateMixin and "BackdropTemplate")
	local optionsFrame = Debug.optionsFrame
	local backdrop = {
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
		tile = true,
		tileSize = 16,
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	}

	optionsFrame:SetHeight(120)
	optionsFrame:SetWidth(debugWidth-3)
	optionsFrame:SetBackdrop(backdrop)
	optionsFrame:SetBackdropColor(0, 0, 0, 0.6)
	optionsFrame:SetPoint("TOPLEFT", DebugFrame, "BOTTOMLEFT",2, 5)

	local enableDebugChk = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
	local debugChkText = enableDebugChk.Text or enableDebugChk.text --due to classic servers still using the old format
	debugChkText:SetText(L.DebugEnable)
	debugChkText:SetTextColor(1, 1, 1)
	enableDebugChk:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 10, -5)
	enableDebugChk:SetScript("OnClick", function(self)
		BSYC.options.debug.enable = enableDebugChk:GetChecked()
	end)
	enableDebugChk:SetChecked(BSYC.options.debug.enable)
	optionsFrame.enableDebugChk = enableDebugChk

	local disableCacheChk = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
	local cacheChkText = disableCacheChk.Text or disableCacheChk.text --due to classic servers still using the old format
	cacheChkText:SetText(L.DebugCache)
	cacheChkText:SetTextColor(1, 1, 1)
	disableCacheChk:SetPoint("LEFT", debugChkText, "RIGHT", 15, 0)
	disableCacheChk:SetScript("OnClick", function(self)
		BSYC.options.debug.cache = disableCacheChk:GetChecked()
	end)
	disableCacheChk:SetChecked(BSYC.options.debug.cache)
	optionsFrame.disableCacheChk = disableCacheChk

	local levels = {
		"DEBUG",
		"INFO",
		"TRACE",
		"WARN",
		"FINE",
		"SL1",
		"SL2",
		"SL3",
	}

	local lastPoint

	optionsFrame.debugLevels = {}

	for k=1, #levels do
		local tmpLevel = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
		tmpLevel.level = levels[k]
		local tmpText = tmpLevel.Text or tmpLevel.text --due to classic servers still using the old format
		tmpText:SetText(L["Debug_"..levels[k]])
		tmpText:SetTextColor(1, 1, 1)
		if not lastPoint then
			tmpLevel:SetPoint("BOTTOMLEFT", optionsFrame, "BOTTOMLEFT", 10, 3)
		else
			tmpLevel:SetPoint("LEFT", lastPoint, "RIGHT", 15, 0)
		end
		lastPoint = tmpText

		tmpLevel:SetScript("OnClick", function(self)
			BSYC.options.debug[self.level] = self:GetChecked()
		end)
		tmpLevel:SetChecked(BSYC.options.debug[levels[k]])
		table.insert(optionsFrame.debugLevels, tmpLevel)
	end

	--dump options
	local dumpOptions = _G.CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
	dumpOptions:SetText(L.DebugDumpOptions)
	dumpOptions:SetHeight(30)
	dumpOptions:SetWidth(dumpOptions:GetTextWidth() + 30)
	dumpOptions:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 10, -43)
	dumpOptions:SetScript("OnClick", function()
		Debug:AddMessage(1, "init-DebugDumpOptions")
		for k, v in pairs(BSYC.options) do
			if type(v) ~= "table" then
				Debug:AddMessage(1, "DumpOptions", k, tostring(v))
			else
				for x, y in pairs(v) do
					if type(y) ~= "table" then
						Debug:AddMessage(1, "DumpOptions", k, tostring(x), tostring(y))
					else
						if k == "colors" then
							Debug:AddMessage(1, "DumpOptions", k, tostring(x), y.r * 255, y.g * 255, y.b * 255)
						end
					end
				end
			end
		end
	end)
	optionsFrame.dumpOptions = dumpOptions

	--iterate units
	local iterateUnits = _G.CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
	iterateUnits:SetText(L.DebugIterateUnits)
	iterateUnits:SetHeight(30)
	iterateUnits:SetWidth(iterateUnits:GetTextWidth() + 30)
	iterateUnits:SetPoint("LEFT", dumpOptions, "RIGHT", 10, 0)
	iterateUnits:SetScript("OnClick", function(self)
		local player = BSYC:GetModule("Unit"):GetPlayerInfo(false, true)

		Debug:AddMessage(1, "IterateUnits", "UnitInfo-1", player.name, player.realm)
		Debug:AddMessage(1, "IterateUnits", "UnitInfo-2", player.class, player.race, player.gender, player.faction)
		Debug:AddMessage(1, "IterateUnits", "UnitInfo-3", player.guild, player.guildrealm)
		Debug:AddMessage(1, "IterateUnits", "RealmKey", player.realmKey)
		Debug:AddMessage(1, "IterateUnits", "RealmKey_RWS", player.rwsKey)
		Debug:AddMessage(1, "IterateUnits", "RealmKey_LC", player.lowerKey)

		for unitObj in BSYC:GetModule("Data"):IterateUnits() do
			if not unitObj.isGuild then
				Debug:AddMessage(1, "IterateUnits", "|cFFFFD580player|r",
					unitObj.name,
					unitObj.realm,
					unitObj.isConnectedRealm,
					unitObj.data.guild,
					unitObj.data.guildrealm
				)
				Debug:AddMessage(1, "IterateUnits", "|cFFe454fdPKey|r",
					unitObj.name,
					unitObj.data.realmKey, " | ",
					unitObj.data.rwsKey
				)
				Debug:AddMessage(1, " ") --extra space
			else
				Debug:AddMessage(1, "IterateUnits", "|cFFFFD580guild|r",
					unitObj.name,
					unitObj.realm,
					unitObj.isConnectedRealm,
					unitObj.isXRGuild
				)
				Debug:AddMessage(1, "IterateUnits", "|cFFe454fdGKey|r",
					unitObj.name,
					unitObj.data.realmKey, " | ",
					unitObj.data.rwsKey
				)
				Debug:AddMessage(1, " ") --extra space
			end
		end
	end)
	optionsFrame.iterateUnits = iterateUnits

	--dump totals
	local dumpTotals = _G.CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
	dumpTotals:SetText(L.DebugDBTotals)
	dumpTotals:SetHeight(30)
	dumpTotals:SetWidth(dumpTotals:GetTextWidth() + 30)
	dumpTotals:SetPoint("LEFT", iterateUnits, "RIGHT", 10, 0)
	dumpTotals:SetScript("OnClick", function(self)
		local totalUnits = 0
		local totalGuilds = 0
		local totalRealms = 0
		local biggestRealmName
		local biggestRealmCount = 0
		local toatlItems = 0

		local realmCount = 0
		local lastRealm

		local allowList = {
			bag = 0,
			bank = 0,
			reagents = 0,
			equip = 0,
			mailbox = 0,
			void = 0,
			auction = 0,
			guild = 0,
			equipbags = 0,
		}

		for unitObj in BSYC:GetModule("Data"):IterateUnits(true) do
			if not biggestRealmName then
				biggestRealmName = unitObj.realm
				lastRealm = unitObj.realm
				totalRealms = totalRealms + 1
			end

			--realm statistics
			if unitObj.realm == lastRealm then
				realmCount = realmCount + 1
			else
				--check to see if the realm count is larger then the one stored
				if realmCount > biggestRealmCount then
					biggestRealmName = lastRealm
					biggestRealmCount = realmCount
				end
				lastRealm = unitObj.realm
				totalRealms = totalRealms + 1
				realmCount = 1
			end

			if not unitObj.isGuild then
				totalUnits = totalUnits + 1
				local count = 0

				for k, v in pairs(unitObj.data) do
					if allowList[k] and type(v) == "table" and k ~= "guild" then
						--bags, bank, reagents are stored in individual bags
						if k == "bag" or k == "bank" or k == "reagents" then
							for bagID, bagData in pairs(v or {}) do
								toatlItems = toatlItems + (#bagData or 0)
							end
						else
							if k == "auction" then
								count = (v.bag and #v.bag) or 0
								toatlItems = toatlItems + count
							elseif k == "equipbags" then
								count = ((v.bag and #v.bag) or 0) + ((v.bank and #v.bank) or 0)
								toatlItems = toatlItems + count
							else
								toatlItems = toatlItems + (#v or 0)
							end
						end
					end
				end
			else
				totalGuilds = totalGuilds + 1
				for tabID, tabData in pairs(unitObj.data.tabs or {}) do
					toatlItems = toatlItems + (#tabData or 0)
				end
			end
		end

		Debug:AddMessage(1, "DBTotals", "totalUnits", totalUnits)
		Debug:AddMessage(1, "DBTotals", "totalGuilds", totalGuilds)
		Debug:AddMessage(1, "DBTotals", "totalRealms", totalRealms)
		Debug:AddMessage(1, "DBTotals", "biggestRealmName", biggestRealmName)
		Debug:AddMessage(1, "DBTotals", "biggestRealmCount", biggestRealmCount)
		Debug:AddMessage(1, "DBTotals", "toatlItems", toatlItems)

	end)
	optionsFrame.dumpTotals = dumpTotals

	--addon list
	local addonList = _G.CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
	addonList:SetText(L.DebugAddonList)
	addonList:SetHeight(30)
	addonList:SetWidth(addonList:GetTextWidth() + 30)
	addonList:SetPoint("LEFT", dumpTotals, "RIGHT", 10, 0)
	addonList:SetScript("OnClick", function(self)
		for i=1, GetNumAddOns() do
			local _, title = GetAddOnInfo(i)
			Debug:AddMessage(1, "AddonList", title)
		end
	end)
	optionsFrame.addonList = addonList

	--export frame
	local exportFrame = _G.CreateFrame("Frame", nil, DebugFrame, "BagSyncInfoFrameTemplate")
	exportFrame:Hide()
	exportFrame:SetWidth(850)
	exportFrame:SetHeight(500)
	exportFrame:SetBackdropColor(0, 0, 0, 0.75)
	exportFrame:EnableMouse(true) --don't allow clickthrough
	exportFrame:SetMovable(false)
	exportFrame:SetResizable(false)
	exportFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	exportFrame:ClearAllPoints()
	exportFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	exportFrame.TitleText:SetText(L.DebugExport)
	exportFrame.TitleText:SetFont(STANDARD_TEXT_FONT, 14, "")
	exportFrame.TitleText:SetTextColor(1, 1, 1)
	exportFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, exportFrame, "UIPanelScrollFrameTemplate")
	exportFrame.ScrollFrame:SetPoint("TOPLEFT", exportFrame, "TOPLEFT", 8, -30)
	exportFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", exportFrame, "BOTTOMRIGHT", -30, 8)
	exportFrame.EditBox = _G.CreateFrame("EditBox", nil, exportFrame.ScrollFrame)
	exportFrame.EditBox:SetAllPoints()
	exportFrame.EditBox:SetFont("Fonts\\ARIALN.TTF", 14, "")
	exportFrame.EditBox:SetMultiLine(true)
	exportFrame.EditBox:SetAutoFocus(false)
	exportFrame.EditBox:SetMaxLetters(0)
	exportFrame.EditBox:SetCountInvisibleLetters(false)
	--exportFrame.EditBox:SetText(L.SearchHelp)
	exportFrame.EditBox:SetWidth(815) --set the boundaries for word wrapping on the scrollbar, if smaller than the frame it will wrap it
	exportFrame.ScrollFrame:SetScrollChild(exportFrame.EditBox)
	--lets set it to disabled to prevent editing
	exportFrame.EditBox:ClearFocus()
	exportFrame.EditBox:EnableMouse(true)
	exportFrame.EditBox:SetTextColor(1, 1, 1) --set default to white
	exportFrame.ScrollFrame:EnableMouse(false)
	DebugFrame.exportFrame = exportFrame

	--export button
	local exportBtn = _G.CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
	exportBtn:SetText(L.DebugExport)
	exportBtn:SetHeight(20)
	exportBtn:SetWidth(exportBtn:GetTextWidth() + 30)
	exportBtn:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -5, -5)
	exportBtn:SetScript("OnClick", function(self)
		local lineText = ""
		for i=1, #Debug.debugItems do
			if (i == 1) then
				lineText = unescape(Debug.debugItems[i]).."|r"
			else
				lineText = lineText.."\n"..unescape(Debug.debugItems[i]).."|r"
			end
		end
		exportFrame.EditBox:SetText(lineText)
		exportFrame:Show()
	end)
	optionsFrame.exportBtn = exportBtn

	--clear button
	local clearBtn = _G.CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
	clearBtn:SetText(L.Clear)
	clearBtn:SetHeight(20)
	clearBtn:SetWidth(clearBtn:GetTextWidth() + 30)
	clearBtn:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -5, 7)
	clearBtn:SetScript("OnClick", function(self)
		Debug.debugItems = {}
		Debug:RefreshList()
	end)
	optionsFrame.clearBtn = clearBtn

	--only annoy the user if the option is enabled, making sure to remind them that debugging is on.
	--can you tell that I really don't want them to leave this on? LOL
	if BSYC.options.debug.enable then
		DebugFrame:Show()
	end
end

function Debug:OnShow()
    Debug:RefreshList()
end

function Debug:OnHide()
	if  BSYC.options.debug.enable then
		BSYC:Print(L.DebugWarning)
	end
end

function Debug:RefreshList()
    local items =  Debug.debugItems
    local buttons = HybridScrollFrame_GetButtons(Debug.scrollFrame)
    local offset = HybridScrollFrame_GetOffset(Debug.scrollFrame)

	if not buttons then return end

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
		button.parentHandler = Debug

        local itemIndex = buttonIndex + offset

        if itemIndex <= #items then
            local item = items[itemIndex]

            button:SetID(itemIndex)
			button.Text:SetFont("Fonts\\ARIALN.TTF", 14, "")
            button.Text:SetText(item or "")
			button.Text:SetTextColor(1, 1, 1) --set white
            button:SetWidth(Debug.scrollFrame.scrollChild:GetWidth())
            button:Show()
        else
            button:Hide()
        end
    end

    local buttonHeight = Debug.scrollFrame.buttonHeight
    local totalHeight = #items * buttonHeight
    local shownHeight = #buttons * buttonHeight

    HybridScrollFrame_Update(Debug.scrollFrame, totalHeight, shownHeight)
end

function Debug:AddMessage(level, sName, ...)
	if not BSYC.options or not BSYC.options.debug or not BSYC.options.debug.enable then return end

	if level == BSYC_DL.DEBUG and not BSYC.options.debug.DEBUG then return end
	if level == BSYC_DL.INFO and not BSYC.options.debug.INFO then return end
	if level == BSYC_DL.TRACE and not BSYC.options.debug.TRACE then return end
	if level == BSYC_DL.WARN and not BSYC.options.debug.WARN then return end
	if level == BSYC_DL.FINE and not BSYC.options.debug.FINE then return end
	if level == BSYC_DL.SL1 and not BSYC.options.debug.SL1 then return end
	if level == BSYC_DL.SL2 and not BSYC.options.debug.SL2 then return end
	if level == BSYC_DL.SL3 and not BSYC.options.debug.SL3 then return end

	local debugStr = string.join(", ", tostringall(...))
	local color = "778899" -- slate gray

	if level == BSYC_DL.DEBUG then
		--debug
		color = "FF4DD827" --fel green
	elseif level == BSYC_DL.INFO then
		--info
		color = "FFffff00" --yellow
	elseif level == BSYC_DL.TRACE then
		--trace
		color = "FF09DBE0" --teal blue
	elseif level == BSYC_DL.WARN then
		--warn
		color = "FFFF3C38" --rose red
	elseif level == BSYC_DL.FINE then
		--fine
		color = "FFe454fd" --dark lavender
	elseif level == BSYC_DL.SL1 then
		--SL1 (SUBLEVEL1)
		color = "FFCF9FFF" --light lavender
	elseif level == BSYC_DL.SL2 then
		--SL2 (SUBLEVEL2)
		color = "FFFFD580" --light orange
	elseif level == BSYC_DL.SL3 then
		--SL3 (SUBLEVEL3)
		color = "FFd1d1d1" --light gray
	end

	local moduleName = string.format("|c"..color.."[%s]|r: ", sName)
	debugStr = moduleName..debugStr
	debugStr = "|cff808080["..date("%X").."]:|r "..debugStr

	--if it exceeds the amount of labels then remove top most one before adding
	if #Debug.debugItems > xListLen then
		table.remove(Debug.debugItems, 1)
	end

	table.insert(Debug.debugItems, debugStr)
	Debug:RefreshList()

	--scroll to bottom by getting the current range and adjusting the scrollframe offset and scrollbar value
	HybridScrollFrame_SetOffset(Debug.scrollFrame, Debug.scrollFrame.range)
	Debug.scrollFrame.scrollBar:SetValue(Debug.scrollFrame.range)
end
