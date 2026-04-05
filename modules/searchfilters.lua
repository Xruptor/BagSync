--[[
	searchfilters.lua
		A search filters frame for BagSync items

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...) --grab the addon namespace
local UI = BSYC:GetModule("UI")
local SearchFilters = BSYC:NewModule("SearchFilters")
local Search = BSYC:GetModule("Search")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

-- Cache global references
local table_insert = table.insert
local HybridScrollFrame_GetButtons = HybridScrollFrame_GetButtons
local HybridScrollFrame_GetOffset = HybridScrollFrame_GetOffset
local HybridScrollFrame_Update = HybridScrollFrame_Update

local L = BSYC.L

---------------------
-- Helper Functions --
---------------------

-- Setup button handlers (PlusButton, RefreshButton)
local function SetupButtonHandlers(frame, buttonName, handlerName)
	local button = frame[buttonName]
	if button then
		button.parentHandler = SearchFilters
		button:SetScript("OnClick", function(self)
			UI:CallHandler(self, handlerName)
		end)
	end
end

-- Create font string with common settings
local function SetupFontString(parent, opts)
	return UI:CreateFontString(parent, opts)
end

-- Process selected items from a list (used by DoSearch)
local function ProcessSelectedItems(list, resultTable, keyFunc, count)
	for i = 1, #list do
		local item = list[i]
		if not item.isHeader and item.isSelected then
			local key = keyFunc(item)
			resultTable[key] = true
			count = count + 1
		end
	end
	return count
end

-- Refresh scroll frame (shared by player and location lists)
local function RefreshScrollFrame(scrollFrame, list, setupButtonFunc)
	local buttons = HybridScrollFrame_GetButtons(scrollFrame)
	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	if not buttons then return end

	for buttonIndex = 1, #buttons do
		local button = buttons[buttonIndex]
		UI:AttachListItemHandlers(button, SearchFilters)

		local itemIndex = buttonIndex + offset

		if itemIndex <= #list then
			local item = list[itemIndex]

			button:SetID(itemIndex)
			button.listData = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
			button.Text:SetTextColor(1, 1, 1)
			button:SetWidth(scrollFrame.scrollChild:GetWidth())
			button.DetailsButton:Hide()

			-- Setup button specific to list type
			setupButtonFunc(button, item)

			-- Force OnEnter update if mouse is over button
			if BSYC:IsMouseOver(button) then
				SearchFilters:Item_OnLeave()
				SearchFilters:Item_OnEnter(button)
			end

			button:Show()
		else
			button:Hide()
		end
	end

	local buttonHeight = scrollFrame.buttonHeight
	local totalHeight = #list * buttonHeight
	local shownHeight = #buttons * buttonHeight

	HybridScrollFrame_Update(scrollFrame, totalHeight, shownHeight)
end

-------------------------
-- UI Setup Functions --
-------------------------

local function SetupSearchBoxAndButtons(advFrame)
	local searchBox = advFrame.SearchBox
	if searchBox then
		UI:SetupSearchBox(searchBox, SearchFilters)
	end

	SetupButtonHandlers(advFrame, "PlusButton", "PlusClick")
	SetupButtonHandlers(advFrame, "RefreshButton", "RefreshClick")
end

local function SetupInformationTexts(advFrame)
	advFrame.infoText = SetupFontString(advFrame, {
		template = "GameFontHighlightSmall",
		text = L.SearchFiltersInformation,
		font = { STANDARD_TEXT_FONT, 12, "" },
		textColor = { 1, 165/255, 0 },
		point = { "LEFT", advFrame, "TOPLEFT", 15, -65 },
		justifyH = "LEFT",
		width = advFrame:GetWidth() - 15,
	})

	advFrame.unitTitle = SetupFontString(advFrame, {
		template = "GameFontHighlightSmall",
		text = L.Units,
		font = { STANDARD_TEXT_FONT, 12, "" },
		textColor = { 0, 1, 0 },
		point = { "LEFT", advFrame, "TOPLEFT", 15, -80 },
		justifyH = "LEFT",
		width = advFrame:GetWidth() - 15,
	})
end

local function SetupPlayerScrollFrame(advFrame)
	SearchFilters.playerScroll = UI:CreateHybridScrollFrame(advFrame, {
		width = 357,
		pointTopLeft = { "TOPLEFT", advFrame, "TOPLEFT", 13, -90 },
		pointBottomLeft = { "BOTTOMLEFT", advFrame, "BOTTOMLEFT", -25, 240 },
		buttonTemplate = "BagSyncListItemTemplate",
		update = function() SearchFilters:RefreshPlayerList() end,
	})
	SearchFilters.playerList = {}

	advFrame.locationTitle = SetupFontString(advFrame, {
		template = "GameFontHighlightSmall",
		text = L.Locations,
		font = { STANDARD_TEXT_FONT, 12, "" },
		textColor = { 0, 1, 0 },
		point = { "TOPLEFT", SearchFilters.playerScroll, "BOTTOMLEFT", 2, -10 },
		justifyH = "LEFT",
		width = advFrame:GetWidth() - 15,
	})

	advFrame.locationInfo = SetupFontString(advFrame, {
		template = "GameFontHighlightSmall",
		text = L.SearchFiltersLocationInformation,
		font = { STANDARD_TEXT_FONT, 12, "" },
		textColor = { 1, 165/255, 0 },
		point = { "TOPLEFT", advFrame.locationTitle, "BOTTOMLEFT", 0, -5 },
		justifyH = "LEFT",
		width = advFrame:GetWidth() - 15,
	})
end

local function SetupLocationScrollFrame(advFrame)
	SearchFilters.locationScroll = UI:CreateHybridScrollFrame(advFrame, {
		width = 357,
		pointTopLeft = { "TOPLEFT", advFrame.locationInfo, "BOTTOMLEFT", -2, -5 },
		pointBottomLeft = { "BOTTOMLEFT", advFrame, "BOTTOMLEFT", -25, 45 },
		buttonTemplate = "BagSyncListItemTemplate",
		update = function() SearchFilters:RefreshLocationList() end,
	})
	SearchFilters.locationList = {}
end

local function SetupActionButtons(advFrame)
	advFrame.resetButton = UI:CreateButton(advFrame, {
		template = "UIPanelButtonTemplate",
		text = L.Reset,
		height = 20,
		autoWidth = true,
		point = { "RIGHT", advFrame, "BOTTOMRIGHT", -10, 23 },
		onClick = function() SearchFilters:Reset() end,
	})

	advFrame.selectAllButton = UI:CreateButton(advFrame, {
		template = "UIPanelButtonTemplate",
		text = L.SelectAll,
		height = 20,
		autoWidth = true,
		point = { "LEFT", advFrame, "BOTTOMLEFT", 13, 23 },
		onClick = function() SearchFilters:SelectAll() end,
	})
end

---------------------------
-- Main Module Functions --
---------------------------

function SearchFilters:OnEnable()
	local advFrame = UI:CreateModuleFrame(SearchFilters, {
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

	SetupSearchBoxAndButtons(advFrame)
	SetupInformationTexts(advFrame)
	SetupPlayerScrollFrame(advFrame)
	SetupLocationScrollFrame(advFrame)
	SetupActionButtons(advFrame)

	advFrame:Hide()
end

function SearchFilters:OnShow()
	BSYC:SetBSYC_FrameLevel(SearchFilters)

	local Search_frame = Search.frame
	Search_frame.SearchBox:Hide()
	Search_frame.RefreshButton:Hide()
	Search_frame.PlusButton:Hide()
	Search_frame.resetButton:Hide()

	if BSYC.options.focusSearchEditBox then
		local searchBox = SearchFilters.frame.SearchBox
		searchBox:ClearFocus()
		searchBox:SetFocus()
	end

	SearchFilters:CreateLists()
	SearchFilters:RefreshLists()
end

function SearchFilters:OnHide()
	SearchFilters:Reset()

	local Search_frame = Search.frame
	Search_frame.SearchBox:Show()
	Search_frame.RefreshButton:Show()
	Search_frame.PlusButton:Show()
	Search_frame.resetButton:Show()
end

function SearchFilters:DoSearch(searchStr)
	if not searchStr then
		searchStr = SearchFilters.frame.SearchBox:GetText()
	end

	local advUnitList = {}
	local advAllowList = {}
	local unitCount = ProcessSelectedItems(SearchFilters.playerList, advUnitList, function(item)
		return item.unitObj.realm
	end, 0)

	local locCount = ProcessSelectedItems(SearchFilters.locationList, advAllowList, function(item)
		return item.source
	end, 0)

	-- Don't send to search unless we have something to work with
	if unitCount < 1 then advUnitList = nil end
	if locCount < 1 then advAllowList = nil end

	Search:DoSearch(searchStr, advUnitList, advAllowList, true)
end

local function BuildPlayerList()
	local playerListTable = {}

	for unitObj in Data:IterateUnits(false) do
		table_insert(playerListTable, {
			unitObj = unitObj,
			colorized = Tooltip:ColorizeUnit(unitObj, true)
		})
	end

	if #playerListTable > 0 then
		table.sort(playerListTable, function(a, b)
			if a.unitObj.realm == b.unitObj.realm then
				return a.unitObj.name < b.unitObj.name
			end
			return a.unitObj.realm < b.unitObj.realm
		end)

		local playerList = SearchFilters.playerList
		local lastHeader = ""

		for i = 1, #playerListTable do
			local entry = playerListTable[i]
			local realm = entry.unitObj.realm

			if lastHeader ~= realm then
				table_insert(playerList, {
					colorized = realm,
					isHeader = true,
					isSelected = false
				})
				lastHeader = realm
			end

			table_insert(playerList, {
				unitObj = entry.unitObj,
				colorized = entry.colorized,
				isSelected = false
			})
		end
	end
end

local function BuildLocationList()
	local allowList = BSYC:GetDefaultAllowListKeys(true)
	local locationList = SearchFilters.locationList

	for i = 1, #allowList do
		local v = allowList[i]
		if BSYC.tracking and BSYC.tracking[v] then
			table_insert(locationList, {
				name = L["Tooltip_"..v],
				source = v,
				isSelected = false
			})
		end
	end
end

function SearchFilters:CreateLists()
	SearchFilters.playerList = {}
	SearchFilters.locationList = {}

	BuildPlayerList()
	BuildLocationList()
end

-- Setup function for player list buttons
local function SetupPlayerButton(button, item)
	button.Icon:SetTexture(nil)
	button.Icon:Hide()

	if item.isSelected then
		button.Icon:Show()
		button.Icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
	end

	if item.isHeader then
		button.Text:SetJustifyH("CENTER")
		button.HeaderHighlight:SetAlpha(0.75)
		button.isHeader = true
	else
		button.Text:SetJustifyH("LEFT")
		button.HeaderHighlight:SetAlpha(0)
		button.isHeader = nil
	end
	button.Text:SetText(item.colorized or "")
end

function SearchFilters:RefreshPlayerList()
	RefreshScrollFrame(SearchFilters.playerScroll, SearchFilters.playerList, SetupPlayerButton)
end

-- Setup function for location list buttons
local function SetupLocationButton(button, item)
	button.Icon:SetTexture(nil)
	button.Icon:Hide()
	button.Text:SetJustifyH("LEFT")
	button.HeaderHighlight:SetAlpha(0)

	if item.isSelected then
		button.Icon:Show()
		button.Icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
	end

	button.Text:SetText(item.name or "")
end

function SearchFilters:RefreshLocationList()
	RefreshScrollFrame(SearchFilters.locationScroll, SearchFilters.locationList, SetupLocationButton)
end

function SearchFilters:RefreshLists()
	SearchFilters:RefreshPlayerList()
	SearchFilters:RefreshLocationList()
end

function SearchFilters:Reset()
	local frame = SearchFilters.frame
	frame.SearchBox:SetText("")
	SearchFilters:SelectAll(true)
	frame.SearchBox.ClearButton:Hide()
	frame.SearchBox.SearchInfo:Show()
	Search:Reset()
end

function SearchFilters:SelectAll(uncheck)
	local selected = not uncheck

	for i = 1, #SearchFilters.playerList do
		local item = SearchFilters.playerList[i]
		if not item.isHeader then
			item.isSelected = selected
		end
	end

	for i = 1, #SearchFilters.locationList do
		local item = SearchFilters.locationList[i]
		if not item.isHeader then
			item.isSelected = selected
		end
	end

	SearchFilters:RefreshLists()
end

function SearchFilters:RefreshClick()
	SearchFilters:DoSearch()
end

function SearchFilters:SearchBox_ResetSearch(btn)
	if btn then
		btn:Hide()
	end
	SearchFilters.frame.SearchBox:SetText("")
	SearchFilters.frame.SearchBox.SearchInfo:Show()
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
	if btn.isHeader then
		if btn.Highlight:IsVisible() then
			btn.Highlight:Hide()
		end
	else
		if not btn.Highlight:IsVisible() then
			btn.Highlight:Show()
		end
	end
end

function SearchFilters:Item_OnLeave()
	GameTooltip:Hide()
end

function SearchFilters:PlusClick()
	Search.savedSearch:SetShown(not Search.savedSearch:IsShown())
end
