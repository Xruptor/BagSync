--[[
	advancedAdvancedSearch.lua
		A advanced search frame for BagSync items

		BagSync - All Rights Reserved - (c) 2024
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local AdvancedSearch = BSYC:NewModule("AdvancedSearch")
local Search = BSYC:GetModule("Search")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "AdvancedSearch", ...) end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

function AdvancedSearch:OnEnable()
    local advFrame = _G.CreateFrame("Frame", nil, UIParent, "BagSyncSearchFrameTemplate")
	Mixin(advFrame, AdvancedSearch) --implement new frame to our parent module Mixin, to have access to parent methods
    advFrame.TitleText:SetText(L.AdvancedSearch)
	advFrame:SetWidth(400)
    advFrame:SetHeight(570)
    advFrame:SetPoint("TOPRIGHT", Search.frame, "TOPLEFT", -10, 0)
    advFrame:EnableMouse(true) --don't allow clickthrough
    advFrame:SetMovable(true)
    advFrame:SetResizable(false)
    advFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	advFrame.HelpButton:Hide()
	advFrame:RegisterForDrag("LeftButton")
	advFrame:SetClampedToScreen(true)
	advFrame:SetScript("OnDragStart", advFrame.StartMoving)
	advFrame:SetScript("OnDragStop", advFrame.StopMovingOrSizing)
	local closeBtn = CreateFrame("Button", nil, advFrame, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", C_EditMode and -3 or 2, C_EditMode and -3 or 1) --check for classic servers to adjust for positioning using a check for the new EditMode
	advFrame.closeBtn = closeBtn
    advFrame:SetScript("OnShow", function() AdvancedSearch:OnShow() end)
	advFrame:SetScript("OnHide", function() AdvancedSearch:OnHide() end)
	AdvancedSearch.frame = advFrame

	--Advanced Search Information
	advFrame.infoText = advFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	advFrame.infoText:SetText(L.AdvancedSearchInformation)
	advFrame.infoText:SetFont(STANDARD_TEXT_FONT, 12, "")
	advFrame.infoText:SetTextColor(1, 165/255, 0)
	advFrame.infoText:SetPoint("LEFT", advFrame, "TOPLEFT", 15, -65)
	advFrame.infoText:SetJustifyH("LEFT")
	advFrame.infoText:SetWidth(advFrame:GetWidth() - 15)

	advFrame.unitTitle = advFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	advFrame.unitTitle:SetText(L.Units)
	advFrame.unitTitle:SetFont(STANDARD_TEXT_FONT, 12, "")
	advFrame.unitTitle:SetTextColor(0, 1, 0)
	advFrame.unitTitle:SetPoint("LEFT", advFrame, "TOPLEFT", 15, -80)
	advFrame.unitTitle:SetJustifyH("LEFT")
	advFrame.unitTitle:SetWidth(advFrame:GetWidth() - 15)

    AdvancedSearch.playerScroll = _G.CreateFrame("ScrollFrame", nil, advFrame, "HybridScrollFrameTemplate")
    AdvancedSearch.playerScroll:SetWidth(357)
    AdvancedSearch.playerScroll:SetPoint("TOPLEFT", advFrame, "TOPLEFT", 13, -90)
    --set ScrollFrame height by altering the distance from the bottom of the frame
    AdvancedSearch.playerScroll:SetPoint("BOTTOMLEFT", advFrame, "BOTTOMLEFT", -25, 240)
    AdvancedSearch.playerScroll.scrollBar = CreateFrame("Slider", "$parentscrollBar", AdvancedSearch.playerScroll, "HybridScrollBarTemplate")
    AdvancedSearch.playerScroll.scrollBar:SetPoint("TOPLEFT", AdvancedSearch.playerScroll, "TOPRIGHT", 1, -16)
    AdvancedSearch.playerScroll.scrollBar:SetPoint("BOTTOMLEFT", AdvancedSearch.playerScroll, "BOTTOMRIGHT", 1, 12)
	--initiate the playerScroll
    --the items we will work with
	AdvancedSearch.playerList = {}
	AdvancedSearch.playerScroll.update = function() AdvancedSearch:RefreshPlayerList(); end
    HybridScrollFrame_SetDoNotHideScrollBar(AdvancedSearch.playerScroll, true)
	HybridScrollFrame_CreateButtons(AdvancedSearch.playerScroll, "BagSyncListItemTemplate")

	advFrame.locationTitle = advFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	advFrame.locationTitle:SetText(L.Locations)
	advFrame.locationTitle:SetFont(STANDARD_TEXT_FONT, 12, "")
	advFrame.locationTitle:SetTextColor(0, 1, 0)
	advFrame.locationTitle:SetPoint("LEFT", advFrame, "TOPLEFT", 15, -320)
	advFrame.locationTitle:SetJustifyH("LEFT")
	advFrame.locationTitle:SetWidth(advFrame:GetWidth() - 15)

	advFrame.locationInfo = advFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	advFrame.locationInfo:SetText(L.AdvancedLocationInformation)
	advFrame.locationInfo:SetFont(STANDARD_TEXT_FONT, 12, "")
	advFrame.locationInfo:SetTextColor(1, 165/255, 0)
	advFrame.locationInfo:SetPoint("LEFT", advFrame, "TOPLEFT", 15, -335)
	advFrame.locationInfo:SetJustifyH("LEFT")
	advFrame.locationInfo:SetWidth(advFrame:GetWidth() - 15)

    AdvancedSearch.locationScroll = _G.CreateFrame("ScrollFrame", nil, advFrame, "HybridScrollFrameTemplate")
    AdvancedSearch.locationScroll:SetWidth(357)
    AdvancedSearch.locationScroll:SetPoint("TOPLEFT", advFrame, "TOPLEFT", 13, -345)
    --set ScrollFrame height by altering the distance from the bottom of the frame
    AdvancedSearch.locationScroll:SetPoint("BOTTOMLEFT", advFrame, "BOTTOMLEFT", -25, 45)
    AdvancedSearch.locationScroll.scrollBar = CreateFrame("Slider", "$parentscrollBar", AdvancedSearch.locationScroll, "HybridScrollBarTemplate")
    AdvancedSearch.locationScroll.scrollBar:SetPoint("TOPLEFT", AdvancedSearch.locationScroll, "TOPRIGHT", 1, -16)
    AdvancedSearch.locationScroll.scrollBar:SetPoint("BOTTOMLEFT", AdvancedSearch.locationScroll, "BOTTOMRIGHT", 1, 12)
	--initiate the locationScroll
    --the items we will work with
    AdvancedSearch.locationList = {}
	AdvancedSearch.locationScroll.update = function() AdvancedSearch:RefreshLocationList(); end
    HybridScrollFrame_SetDoNotHideScrollBar(AdvancedSearch.locationScroll, true)
	HybridScrollFrame_CreateButtons(AdvancedSearch.locationScroll, "BagSyncListItemTemplate")

	--Reset button
	advFrame.resetButton = _G.CreateFrame("Button", nil, advFrame, "UIPanelButtonTemplate")
	advFrame.resetButton:SetText(L.Reset)
	advFrame.resetButton:SetHeight(20)
	advFrame.resetButton:SetWidth(advFrame.resetButton:GetTextWidth() + 30)
	advFrame.resetButton:SetPoint("RIGHT", advFrame, "BOTTOMRIGHT", -10, 23)
	advFrame.resetButton:SetScript("OnClick", function() AdvancedSearch:Reset() end)

	--Select All button
	advFrame.selectAllButton = _G.CreateFrame("Button", nil, advFrame, "UIPanelButtonTemplate")
	advFrame.selectAllButton:SetText(L.SelectAll)
	advFrame.selectAllButton:SetHeight(20)
	advFrame.selectAllButton:SetWidth(advFrame.selectAllButton:GetTextWidth() + 30)
	advFrame.selectAllButton:SetPoint("LEFT", advFrame, "BOTTOMLEFT", 13, 23)
	advFrame.selectAllButton:SetScript("OnClick", function() AdvancedSearch:SelectAll() end)

	advFrame:Hide() --important
end

function AdvancedSearch:OnShow()
	BSYC:SetBSYC_FrameLevel(AdvancedSearch)

	--Hide some of the regular search frame stuff
	Search.frame.SearchBox:Hide()
	Search.frame.RefreshButton:Hide()
	Search.frame.PlusButton:Hide()
	Search.frame.resetButton:Hide()

	C_Timer.After(0.5, function()
		if BSYC.options.focusSearchEditBox then
			AdvancedSearch.frame.SearchBox:ClearFocus()
			AdvancedSearch.frame.SearchBox:SetFocus()
		end
	end)

	AdvancedSearch:CreateLists()
	AdvancedSearch:RefreshLists()
end

function AdvancedSearch:OnHide()
	AdvancedSearch:Reset()
	--Show some of the regular search frame stuff
	Search.frame.SearchBox:Show()
	Search.frame.RefreshButton:Show()
	Search.frame.PlusButton:Show()
	Search.frame.resetButton:Show()
end

function AdvancedSearch:DoSearch(searchStr)
	if not searchStr then searchStr = AdvancedSearch.frame.SearchBox:GetText() end

	local advUnitList = {}
	local advAllowList = {}
	local unitCount = 0
	local locCount = 0

	for i=1, #AdvancedSearch.playerList do
		local item = AdvancedSearch.playerList[i]
		if not item.isHeader and item.isSelected then
			if not advUnitList[item.unitObj.realm] then advUnitList[item.unitObj.realm] = {} end
			advUnitList[item.unitObj.realm][item.unitObj.name] = true
			unitCount = unitCount + 1
		end
	end
	for i=1, #AdvancedSearch.locationList do
		local item = AdvancedSearch.locationList[i]
		if not item.isHeader and item.isSelected then
			advAllowList[item.source] = true
			locCount = locCount + 1
		end
	end

	--don't send to search unless we have something to work with
	if unitCount < 1 then advUnitList = nil end
	if locCount < 1 then advAllowList = nil end

	--global for tooltip checks
	Search.advUnitList = advUnitList
	--send it off to the regular search
	Search:DoSearch(searchStr, advUnitList, advAllowList, true)
end

function AdvancedSearch:CreateLists()
	AdvancedSearch.playerList = {}
	AdvancedSearch.locationList = {}

	local playerListTable = {}

	--show simple for ColorizeUnit
	for unitObj in Data:IterateUnits(true) do
		table.insert(playerListTable, {
			unitObj = unitObj,
			colorized = Tooltip:ColorizeUnit(unitObj, true)
		})
	end

	--units
	if #playerListTable > 0 then
		table.sort(playerListTable, function(a, b)
			if a.unitObj.realm  == b.unitObj.realm then
				return a.unitObj.name < b.unitObj.name;
			end
			return a.unitObj.realm < b.unitObj.realm;
		end)

		local lastHeader = ""
		for i=1, #playerListTable do
			if lastHeader ~= playerListTable[i].unitObj.realm then
				--add header
				table.insert(AdvancedSearch.playerList, {
					colorized = playerListTable[i].unitObj.realm,
					isHeader = true,
					isSelected = false
				})
				lastHeader = playerListTable[i].unitObj.realm
			end
			--add player
			table.insert(AdvancedSearch.playerList, {
				unitObj = playerListTable[i].unitObj,
				colorized = playerListTable[i].colorized,
				isSelected = false
			})
		end
	end

	--locations
	local allowList = {
		"bag",
		"bank",
		"reagents",
		"equip",
		"mailbox",
		"void",
		"auction",
		"warband",
	}

	for k, v in ipairs(allowList) do
		if BSYC.tracking[v] then
			--only add if enabled
			table.insert(AdvancedSearch.locationList, {
				name = L["Tooltip_"..v],
				source = v,
				isSelected = false
			})
		end
	end
end

function AdvancedSearch:RefreshPlayerList()
    local items = AdvancedSearch.playerList
    local buttons = HybridScrollFrame_GetButtons(AdvancedSearch.playerScroll)
    local offset = HybridScrollFrame_GetOffset(AdvancedSearch.playerScroll)
	if not buttons then return end

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
		button.parentHandler = AdvancedSearch

        local itemIndex = buttonIndex + offset

        if itemIndex <= #items then
            local item = items[itemIndex]

            button:SetID(itemIndex)
			button.listData = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
			button.Text:SetTextColor(1, 1, 1)
            button:SetWidth(AdvancedSearch.playerScroll.scrollChild:GetWidth())
			button.DetailsButton:Hide()

			button.Icon:SetTexture(nil)
			button.Icon:Hide()
			if item.isSelected then
				button.Icon:Show()
				button.Icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
			end

			if item.isHeader then
				button.Text:SetJustifyH("CENTER")
				--button.HeaderHighlight:SetVertexColor(0.8, 0.7, 0, 1)
				button.HeaderHighlight:SetAlpha(0.75)
				button.isHeader = true
			else
				button.Text:SetJustifyH("LEFT")
				button.HeaderHighlight:SetAlpha(0)
				button.isHeader = nil
			end
			button.Text:SetText(item.colorized or "")

			--while we are updating the scrollframe, is the mouse currently over a button?
			--if so we need to force the OnEnter as the items will scroll up in data but the button remains the same position on our cursor
			if BSYC.GMF() == button then
				AdvancedSearch:Item_OnLeave() --hide first
				AdvancedSearch:Item_OnEnter(button)
			end

            button:Show()
        else
            button:Hide()
        end
    end

    local buttonHeight = AdvancedSearch.playerScroll.buttonHeight
    local totalHeight = #items * buttonHeight
    local shownHeight = #buttons * buttonHeight

    HybridScrollFrame_Update(AdvancedSearch.playerScroll, totalHeight, shownHeight)
end

function AdvancedSearch:RefreshLocationList()
    local items = AdvancedSearch.locationList
    local buttons = HybridScrollFrame_GetButtons(AdvancedSearch.locationScroll)
    local offset = HybridScrollFrame_GetOffset(AdvancedSearch.locationScroll)
	if not buttons then return end

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
		button.parentHandler = AdvancedSearch

        local itemIndex = buttonIndex + offset

        if itemIndex <= #items then
            local item = items[itemIndex]

            button:SetID(itemIndex)
			button.listData = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
			button.Text:SetTextColor(1, 1, 1)
            button:SetWidth(AdvancedSearch.locationScroll.scrollChild:GetWidth())
			button.DetailsButton:Hide()
			button.Text:SetJustifyH("LEFT")
			button.HeaderHighlight:SetAlpha(0)
			button.Text:SetText(item.name or "")

			button.Icon:SetTexture(nil)
			button.Icon:Hide()
			if item.isSelected then
				button.Icon:Show()
				button.Icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
			end

            button:Show()
        else
            button:Hide()
        end
    end

    local buttonHeight = AdvancedSearch.locationScroll.buttonHeight
    local totalHeight = #items * buttonHeight
    local shownHeight = #buttons * buttonHeight

    HybridScrollFrame_Update(AdvancedSearch.locationScroll, totalHeight, shownHeight)
end

function AdvancedSearch:RefreshLists()
	AdvancedSearch:RefreshPlayerList()
	AdvancedSearch:RefreshLocationList()
end

function AdvancedSearch:Reset()
	AdvancedSearch.frame.SearchBox:SetText("")
	AdvancedSearch:SelectAll(true)
	AdvancedSearch.frame.SearchBox.ClearButton:Hide()
	AdvancedSearch.frame.SearchBox.SearchInfo:Show()
	BSYC.advUnitList = nil
	Search:Reset()
end

function AdvancedSearch:SelectAll(uncheck)
	for i=1, #AdvancedSearch.playerList do
		local item = AdvancedSearch.playerList[i]
		if not item.isHeader then
			item.isSelected = (not uncheck and true) or false
		end
	end
	for i=1, #AdvancedSearch.locationList do
		local item = AdvancedSearch.locationList[i]
		if not item.isHeader then
			item.isSelected = (not uncheck and true) or false
		end
	end
	AdvancedSearch:RefreshLists()
end

function AdvancedSearch:RefreshClick()
	AdvancedSearch:DoSearch()
end

function AdvancedSearch:SearchBox_ResetSearch(btn)
	btn:Hide()
	AdvancedSearch.frame.SearchBox:SetText("")
end

function AdvancedSearch:Item_OnClick(btn)
	if not btn.isHeader then
		if not btn.listData.isSelected then
			btn.listData.isSelected = true
			btn.Icon:Show()
			btn.Icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
		else
			btn.listData.isSelected = false
			btn.Icon:Hide()
		end
	end
	Search:ClearList()
end

function AdvancedSearch:SearchBox_OnEnterPressed(text)
	AdvancedSearch:DoSearch(text)
end

function AdvancedSearch:Item_OnEnter(btn)
	if btn.isHeader and btn.Highlight:IsVisible() then
		btn.Highlight:Hide()
	elseif not btn.isHeader and not btn.Highlight:IsVisible() then
		btn.Highlight:Show()
	end
end

function AdvancedSearch:Item_OnLeave()
	GameTooltip:Hide()
end

function AdvancedSearch:PlusClick()
	Search.savedSearch:SetShown(not Search.savedSearch:IsShown())
end