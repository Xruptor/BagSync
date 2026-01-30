--[[
	searchfilters.lua
		A search filters frame for BagSync items

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local SearchFilters = BSYC:NewModule("SearchFilters")
local Search = BSYC:GetModule("Search")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "SearchFilters", ...) end
end

local L = BSYC.L

function SearchFilters:OnEnable()
	local advFrame = BSYC:UI_CreateModuleFrame(SearchFilters, {
		template = "BagSyncSearchFrameTemplate",
		title = L.SearchFilters,
		width = 400,
		height = 570,
		point = { "TOPRIGHT", Search.frame, "TOPLEFT", -10, 0 },
		onShow = function() SearchFilters:OnShow() end,
		onHide = function() SearchFilters:OnHide() end,
	})
	advFrame.HelpButton:Hide()
	SearchFilters.frame = advFrame

	--Search Filters Information
	advFrame.infoText = advFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	advFrame.infoText:SetText(L.SearchFiltersInformation)
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

	SearchFilters.playerScroll = BSYC:UI_CreateHybridScrollFrame(advFrame, {
		width = 357,
		pointTopLeft = { "TOPLEFT", advFrame, "TOPLEFT", 13, -90 },
		-- set ScrollFrame height by altering the distance from the bottom of the frame
		pointBottomLeft = { "BOTTOMLEFT", advFrame, "BOTTOMLEFT", -25, 240 },
		buttonTemplate = "BagSyncListItemTemplate",
		update = function() SearchFilters:RefreshPlayerList(); end,
	})
	--the items we will work with
	SearchFilters.playerList = {}

	advFrame.locationTitle = advFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	advFrame.locationTitle:SetText(L.Locations)
	advFrame.locationTitle:SetFont(STANDARD_TEXT_FONT, 12, "")
	advFrame.locationTitle:SetTextColor(0, 1, 0)
	advFrame.locationTitle:SetPoint("LEFT", advFrame, "TOPLEFT", 15, -320)
	advFrame.locationTitle:SetJustifyH("LEFT")
	advFrame.locationTitle:SetWidth(advFrame:GetWidth() - 15)

	advFrame.locationInfo = advFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	advFrame.locationInfo:SetText(L.SearchFiltersLocationInformation)
	advFrame.locationInfo:SetFont(STANDARD_TEXT_FONT, 12, "")
	advFrame.locationInfo:SetTextColor(1, 165/255, 0)
	advFrame.locationInfo:SetPoint("LEFT", advFrame, "TOPLEFT", 15, -335)
	advFrame.locationInfo:SetJustifyH("LEFT")
	advFrame.locationInfo:SetWidth(advFrame:GetWidth() - 15)

	SearchFilters.locationScroll = BSYC:UI_CreateHybridScrollFrame(advFrame, {
		width = 357,
		pointTopLeft = { "TOPLEFT", advFrame, "TOPLEFT", 13, -345 },
		-- set ScrollFrame height by altering the distance from the bottom of the frame
		pointBottomLeft = { "BOTTOMLEFT", advFrame, "BOTTOMLEFT", -25, 45 },
		buttonTemplate = "BagSyncListItemTemplate",
		update = function() SearchFilters:RefreshLocationList(); end,
	})
	--the items we will work with
	SearchFilters.locationList = {}

	--Reset button
	advFrame.resetButton = _G.CreateFrame("Button", nil, advFrame, "UIPanelButtonTemplate")
	advFrame.resetButton:SetText(L.Reset)
	advFrame.resetButton:SetHeight(20)
	advFrame.resetButton:SetWidth(advFrame.resetButton:GetTextWidth() + 30)
	advFrame.resetButton:SetPoint("RIGHT", advFrame, "BOTTOMRIGHT", -10, 23)
	advFrame.resetButton:SetScript("OnClick", function() SearchFilters:Reset() end)

	--Select All button
	advFrame.selectAllButton = _G.CreateFrame("Button", nil, advFrame, "UIPanelButtonTemplate")
	advFrame.selectAllButton:SetText(L.SelectAll)
	advFrame.selectAllButton:SetHeight(20)
	advFrame.selectAllButton:SetWidth(advFrame.selectAllButton:GetTextWidth() + 30)
	advFrame.selectAllButton:SetPoint("LEFT", advFrame, "BOTTOMLEFT", 13, 23)
	advFrame.selectAllButton:SetScript("OnClick", function() SearchFilters:SelectAll() end)

	advFrame:Hide() --important
end

function SearchFilters:OnShow()
	BSYC:SetBSYC_FrameLevel(SearchFilters)

	--Hide some of the regular search frame stuff
	Search.frame.SearchBox:Hide()
	Search.frame.RefreshButton:Hide()
	Search.frame.PlusButton:Hide()
	Search.frame.resetButton:Hide()

	C_Timer.After(0.5, function()
		if BSYC.options.focusSearchEditBox then
			SearchFilters.frame.SearchBox:ClearFocus()
			SearchFilters.frame.SearchBox:SetFocus()
		end
	end)

	SearchFilters:CreateLists()
	SearchFilters:RefreshLists()
end

function SearchFilters:OnHide()
	SearchFilters:Reset()
	--Show some of the regular search frame stuff
	Search.frame.SearchBox:Show()
	Search.frame.RefreshButton:Show()
	Search.frame.PlusButton:Show()
	Search.frame.resetButton:Show()
end

function SearchFilters:DoSearch(searchStr)
	if not searchStr then searchStr = SearchFilters.frame.SearchBox:GetText() end

	local advUnitList = {}
	local advAllowList = {}
	local unitCount = 0
	local locCount = 0

	for i=1, #SearchFilters.playerList do
		local item = SearchFilters.playerList[i]
		if not item.isHeader and item.isSelected then
			if not advUnitList[item.unitObj.realm] then advUnitList[item.unitObj.realm] = {} end
			advUnitList[item.unitObj.realm][item.unitObj.name] = true
			unitCount = unitCount + 1
		end
	end
	for i=1, #SearchFilters.locationList do
		local item = SearchFilters.locationList[i]
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

function SearchFilters:CreateLists()
	SearchFilters.playerList = {}
	SearchFilters.locationList = {}

	local playerListTable = {}

	--show simple for ColorizeUnit
	for unitObj in Data:IterateUnits(false) do
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
				table.insert(SearchFilters.playerList, {
					colorized = playerListTable[i].unitObj.realm,
					isHeader = true,
					isSelected = false
				})
				lastHeader = playerListTable[i].unitObj.realm
			end
			--add player
			table.insert(SearchFilters.playerList, {
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
		"guild",
		"warband",
	}

	for k, v in ipairs(allowList) do
		if BSYC.tracking[v] then
			--only add if enabled
			table.insert(SearchFilters.locationList, {
				name = L["Tooltip_"..v],
				source = v,
				isSelected = false
			})
		end
	end
end

function SearchFilters:RefreshPlayerList()
    local items = SearchFilters.playerList
    local buttons = HybridScrollFrame_GetButtons(SearchFilters.playerScroll)
    local offset = HybridScrollFrame_GetOffset(SearchFilters.playerScroll)
	if not buttons then return end

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
		button.parentHandler = SearchFilters

        local itemIndex = buttonIndex + offset

        if itemIndex <= #items then
            local item = items[itemIndex]

            button:SetID(itemIndex)
			button.listData = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
			button.Text:SetTextColor(1, 1, 1)
            button:SetWidth(SearchFilters.playerScroll.scrollChild:GetWidth())
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
			if BSYC:IsMouseOver(button) then
				SearchFilters:Item_OnLeave() --hide first
				SearchFilters:Item_OnEnter(button)
			end

            button:Show()
        else
            button:Hide()
        end
    end

    local buttonHeight = SearchFilters.playerScroll.buttonHeight
    local totalHeight = #items * buttonHeight
    local shownHeight = #buttons * buttonHeight

    HybridScrollFrame_Update(SearchFilters.playerScroll, totalHeight, shownHeight)
end

function SearchFilters:RefreshLocationList()
    local items = SearchFilters.locationList
    local buttons = HybridScrollFrame_GetButtons(SearchFilters.locationScroll)
    local offset = HybridScrollFrame_GetOffset(SearchFilters.locationScroll)
	if not buttons then return end

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
		button.parentHandler = SearchFilters

        local itemIndex = buttonIndex + offset

        if itemIndex <= #items then
            local item = items[itemIndex]

            button:SetID(itemIndex)
			button.listData = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
			button.Text:SetTextColor(1, 1, 1)
            button:SetWidth(SearchFilters.locationScroll.scrollChild:GetWidth())
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

    local buttonHeight = SearchFilters.locationScroll.buttonHeight
    local totalHeight = #items * buttonHeight
    local shownHeight = #buttons * buttonHeight

    HybridScrollFrame_Update(SearchFilters.locationScroll, totalHeight, shownHeight)
end

function SearchFilters:RefreshLists()
	SearchFilters:RefreshPlayerList()
	SearchFilters:RefreshLocationList()
end

function SearchFilters:Reset()
	SearchFilters.frame.SearchBox:SetText("")
	SearchFilters:SelectAll(true)
	SearchFilters.frame.SearchBox.ClearButton:Hide()
	SearchFilters.frame.SearchBox.SearchInfo:Show()
	BSYC.advUnitList = nil
	BSYC.advAllowList = nil
	Search:Reset()
end

function SearchFilters:SelectAll(uncheck)
	for i=1, #SearchFilters.playerList do
		local item = SearchFilters.playerList[i]
		if not item.isHeader then
			item.isSelected = (not uncheck and true) or false
		end
	end
	for i=1, #SearchFilters.locationList do
		local item = SearchFilters.locationList[i]
		if not item.isHeader then
			item.isSelected = (not uncheck and true) or false
		end
	end
	SearchFilters:RefreshLists()
end

function SearchFilters:RefreshClick()
	SearchFilters:DoSearch()
end

function SearchFilters:SearchBox_ResetSearch(btn)
	btn:Hide()
	SearchFilters.frame.SearchBox:SetText("")
end

function SearchFilters:Item_OnClick(btn)
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

function SearchFilters:SearchBox_OnEnterPressed(text)
	SearchFilters:DoSearch(text)
end

function SearchFilters:Item_OnEnter(btn)
	if btn.isHeader and btn.Highlight:IsVisible() then
		btn.Highlight:Hide()
	elseif not btn.isHeader and not btn.Highlight:IsVisible() then
		btn.Highlight:Show()
	end
end

function SearchFilters:Item_OnLeave()
	GameTooltip:Hide()
end

function SearchFilters:PlusClick()
	Search.savedSearch:SetShown(not Search.savedSearch:IsShown())
end
