--[[
	search.lua
		A search frame for BagSync items

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...)
local UI = BSYC:GetModule("UI")
local Search = BSYC:NewModule("Search")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local L = BSYC.L
local ItemScout = LibStub("LibItemScout-1.0")

-- Cache global references
local _G = _G
local C_Timer = _G.C_Timer
local C_PetJournal = _G.C_PetJournal
local HybridScrollFrame_GetButtons = _G.HybridScrollFrame_GetButtons
local HybridScrollFrame_GetOffset = _G.HybridScrollFrame_GetOffset
local HybridScrollFrame_Update = _G.HybridScrollFrame_Update
local GetItemQualityColor = _G.GetItemQualityColor
local IsModifiedClick = _G.IsModifiedClick
local ChatEdit_InsertLink = _G.ChatEdit_InsertLink
local DressUpLink = _G.DressUpLink
local DressUpItemLink = _G.DressUpItemLink
local DressUpBattlePet = _G.DressUpBattlePet
local BattlePetTooltip = _G.BattlePetTooltip
local GameTooltip = _G.GameTooltip
local ToggleDropDownMenu = _G.ToggleDropDownMenu
local WOW_PROJECT_ID = _G.WOW_PROJECT_ID
local WOW_PROJECT_MAINLINE = _G.WOW_PROJECT_MAINLINE

local STANDARD_TEXT_FONT = _G.STANDARD_TEXT_FONT
local ChatFontNormal = _G.ChatFontNormal
local UIParent = _G.UIParent

-- Cache module references
local Details

local function Debug(level, ...)
	if BSYC.DEBUG then BSYC.DEBUG(level, "Search", ...) end
end

------------------------------------------------------------
-- UI SETUP HELPERS
------------------------------------------------------------

local function SetupCacheOverlay(searchFrame)
	local scrollFrame = Search.scrollFrame

	local cacheOverlay = UI:CreateFrame(searchFrame, {
		frameStrata = "DIALOG",
		frameLevel = searchFrame:GetFrameLevel() + 20,
		enableMouse = true,
		points = {
			{ "TOPLEFT", scrollFrame, "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 0 },
		},
	})
	cacheOverlay:Hide()

	cacheOverlay.bg = UI:CreateTexture(cacheOverlay, {
		layer = "BACKGROUND",
		allPoints = cacheOverlay,
		color = { 0, 0, 0, 0.35 },
	})

	cacheOverlay.spinner = UI:CreateTexture(cacheOverlay, {
		layer = "ARTWORK",
		size = { 32, 32 },
		texture = "Interface\\Common\\WaitSpinner",
		point = { "CENTER", cacheOverlay, "CENTER", 0, 10 },
	})

	cacheOverlay.spinner.anim = cacheOverlay.spinner:CreateAnimationGroup()
	cacheOverlay.spinner.anim:SetLooping("REPEAT")

	local rot = cacheOverlay.spinner.anim:CreateAnimation("Rotation")
	rot:SetDuration(1.0)
	rot:SetOrder(1)
	rot:SetDegrees(-360)

	cacheOverlay.text = UI:CreateFontString(cacheOverlay, {
		layer = "ARTWORK",
		template = "GameFontHighlight",
		point = { "TOP", cacheOverlay.spinner, "BOTTOM", 0, -6 },
		justifyH = "CENTER",
	})

	return cacheOverlay
end

local function SetupWarningFrame(searchFrame)
	local warningFrame = UI:CreateInfoFrame(searchFrame, {
		title = L.WarningHeader,
		point = { "BOTTOMLEFT", searchFrame, "BOTTOMRIGHT", 5, 0 },
		backdropColor = { 0, 0, 0, 0.75 },
	})

	warningFrame.infoText1 = UI:CreateFontString(warningFrame, {
		template = "GameFontHighlightSmall",
		text = L.WarningItemSearch,
		font = { STANDARD_TEXT_FONT, 14, "" },
		textColor = { 1, 165/255, 0 },
		justifyH = "CENTER",
		width = warningFrame:GetWidth() - 30,
		point = { "LEFT", warningFrame, "TOPLEFT", 10, -100 },
	})

	warningFrame.infoText2 = UI:CreateFontString(warningFrame, {
		template = "GameFontHighlightSmall",
		text = L.ObsoleteWarning,
		font = { STANDARD_TEXT_FONT, 14, "" },
		textColor = { 50/255, 165/255, 0 },
		width = warningFrame:GetWidth() - 30,
		point = { "LEFT", warningFrame.infoText1, "BOTTOMLEFT", 5, -70 },
		justifyH = "CENTER",
	})

	return warningFrame
end

local function SetupHelpFrame(searchFrame)
	local helpFrame = UI:CreateInfoFrame(searchFrame, {
		title = L.SearchHelpHeader,
		width = 500,
		height = 300,
		point = { "BOTTOMLEFT", searchFrame, "BOTTOMRIGHT", 5, 0 },
		backdropColor = { 0, 0, 0, 0.75 },
	})

	helpFrame.ScrollFrame = UI:CreateScrollFrame(helpFrame, {
		points = {
			{ "TOPLEFT", helpFrame, "TOPLEFT", 8, -30 },
			{ "BOTTOMRIGHT", helpFrame, "BOTTOMRIGHT", -30, 8 },
		},
	})

	helpFrame.EditBox = UI:CreateEditBox(helpFrame.ScrollFrame, {
		fontObject = ChatFontNormal,
		multiLine = true,
		autoFocus = false,
		maxLetters = 0,
		countInvisibleLetters = false,
		text = L.SearchHelp,
		width = 465,
	})

	helpFrame.EditBox:SetAllPoints()
	helpFrame.ScrollFrame:SetScrollChild(helpFrame.EditBox)
	helpFrame.EditBox:ClearFocus()
	helpFrame.EditBox:EnableMouse(false)
	helpFrame.EditBox:SetTextColor(1, 1, 1)
	helpFrame.ScrollFrame:EnableMouse(false)

	return helpFrame
end

local function SetupSavedSearchFrame(searchFrame)
	local savedSearch = UI:CreateInfoFrame(searchFrame, {
		title = L.SavedSearch,
		width = 400,
		height = 200,
		point = { "TOPLEFT", searchFrame, "TOPRIGHT", 5, 0 },
		backdropColor = { 0, 0, 0, 0.75 },
	})

	savedSearch:SetScript("OnShow", function() Search:SavedSearch_UpdateList() end)

	savedSearch.scrollFrame = UI:CreateHybridScrollFrame(savedSearch, {
		width = 357,
		pointTopLeft = { "TOPLEFT", savedSearch, "TOPLEFT", 13, -32 },
		pointBottomLeft = { "BOTTOMLEFT", savedSearch, "BOTTOMLEFT", -25, 36 },
		buttonTemplate = "BagSyncSavedListTemplate",
		update = function() Search:SavedSearch_RefreshList() end,
	})

	savedSearch.items = {}

	savedSearch.addSavedBtn = UI:CreateButton(savedSearch, {
		template = "UIPanelButtonTemplate",
		text = L.SavedSearch_Add,
		height = 20,
		autoWidth = true,
		point = { "BOTTOM", savedSearch, "BOTTOM", 0, 5 },
		onClick = function() Search:SavedSearch_AddItem() end,
	})

	return savedSearch
end

local function SetupModulesButton(searchFrame)
	local modulesButton = UI:CreateButton(searchFrame, {
		size = { 31, 31 },
		registerForClicks = "anyUp",
		highlightTexture = 136477,
		point = { "TOPLEFT", searchFrame, "TOPLEFT", 0, 0 },
		onClick = function()
			if BSYC.OpenMinimapMenu then
				BSYC:OpenMinimapMenu("cursor")
			elseif BSYC.bgsMinimapDD then
				ToggleDropDownMenu(1, nil, BSYC.bgsMinimapDD, "cursor", 0, 0)
			end
		end,
	})

	local modulesButtonOverlay = UI:CreateTexture(modulesButton, { layer = "OVERLAY" })
	local modulesButtonBG = UI:CreateTexture(modulesButton, { layer = "BACKGROUND" })
	local modulesButtonIcon = UI:CreateTexture(modulesButton, { layer = "ARTWORK" })

	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		modulesButtonOverlay:SetSize(50, 50)
		modulesButtonOverlay:SetTexture(136430)
		modulesButtonOverlay:SetPoint("TOPLEFT", modulesButton, "TOPLEFT", 0, 0)
		modulesButtonBG:SetSize(24, 24)
		modulesButtonBG:SetTexture(136467)
		modulesButtonBG:SetPoint("CENTER", modulesButton, "CENTER", 0, 1)
		modulesButtonIcon:SetSize(18, 18)
		modulesButtonIcon:SetTexture("Interface\\AddOns\\BagSync\\media\\icon")
		modulesButtonIcon:SetPoint("CENTER", modulesButton, "CENTER", 0, 1)
	else
		modulesButtonOverlay:SetSize(53, 53)
		modulesButtonOverlay:SetTexture(136430)
		modulesButtonOverlay:SetPoint("TOPLEFT")
		modulesButtonBG:SetSize(20, 20)
		modulesButtonBG:SetTexture(136467)
		modulesButtonBG:SetPoint("TOPLEFT", 7, -5)
		modulesButtonIcon:SetSize(17, 17)
		modulesButtonIcon:SetTexture("Interface\\AddOns\\BagSync\\media\\icon")
		modulesButtonIcon:SetPoint("TOPLEFT", 7, -6)
	end

	return modulesButton
end

local function SetupSearchBoxButtonHandlers(searchFrame)
	if searchFrame.PlusButton then
		searchFrame.PlusButton.parentHandler = Search
		searchFrame.PlusButton:SetScript("OnClick", function(self)
			UI:CallHandler(self, "PlusClick")
		end)
	end

	if searchFrame.RefreshButton then
		searchFrame.RefreshButton.parentHandler = Search
		searchFrame.RefreshButton:SetScript("OnClick", function(self)
			UI:CallHandler(self, "RefreshClick")
		end)
	end

	if searchFrame.HelpButton then
		searchFrame.HelpButton.parentHandler = Search
		searchFrame.HelpButton:SetScript("OnClick", function(self)
			UI:CallHandler(self, "HelpClick")
		end)
	end
end

------------------------------------------------------------
-- MAIN API
------------------------------------------------------------

function Search:Toggle()
	if not self.frame then return end
	if self.frame:IsShown() then
		self.frame:Hide()
	else
		self.frame:Show()
	end
end

function Search:OnEnable()
	local searchFrame = UI:CreateModuleFrame(Search, {
		template = "BagSyncSearchFrameTemplate",
		globalName = "BagSyncSearchFrame",
		title = "BagSync - "..L.Search,
		width = 400,
		height = 500,
		point = { "CENTER", UIParent, "CENTER", 0, 0 },
		onShow = function() Search:OnShow() end,
		onHide = function() Search:OnHide() end,
	})
	Search.frame = searchFrame

	Search.scrollFrame = UI:CreateHybridScrollFrame(searchFrame, {
		width = 357,
		pointTopLeft = { "TOPLEFT", searchFrame, "TOPLEFT", 13, -60 },
		pointBottomLeft = { "BOTTOMLEFT", searchFrame, "BOTTOMLEFT", -25, 42 },
		buttonTemplate = "BagSyncListItemTemplate",
		update = function() Search:RefreshList() end,
	})

	Search.items = {}

	-- Create UI components
	Search.cacheOverlay = SetupCacheOverlay(searchFrame)
	Search.warningFrame = SetupWarningFrame(searchFrame)
	Search.helpFrame = SetupHelpFrame(searchFrame)
	Search.savedSearch = SetupSavedSearchFrame(searchFrame)
	searchFrame.modulesButton = SetupModulesButton(searchFrame)

	-- Total counter
	searchFrame.totalText = UI:CreateFontString(searchFrame, {
		template = "GameFontHighlightSmall",
		text = L.TooltipTotal.." |cFFFFFFFF0|r",
		font = { STANDARD_TEXT_FONT, 12, "" },
		textColor = { 1, 165/255, 0 },
		point = { "LEFT", searchFrame, "BOTTOMLEFT", 15, 20 },
		justifyH = "LEFT",
	})

	-- Search Filters button
	searchFrame.searchFiltersBtn = UI:CreateButton(searchFrame, {
		template = "UIPanelButtonTemplate",
		text = L.SearchFilters,
		height = 20,
		autoWidth = true,
		point = { "RIGHT", searchFrame, "BOTTOMRIGHT", -10, 23 },
		onClick = function() Search:ShowSearchFilters() end,
	})

	-- Reset button
	searchFrame.resetButton = UI:CreateButton(searchFrame, {
		template = "UIPanelButtonTemplate",
		text = L.Reset,
		height = 20,
		autoWidth = true,
		point = { "RIGHT", searchFrame.searchFiltersBtn, "LEFT", 0, 0 },
		onClick = function() Search:Reset() end,
	})

	-- Setup search box
	local searchBox = searchFrame.SearchBox
	if searchBox then
		UI:SetupSearchBox(searchBox, Search)
	end

	-- Setup button handlers
	SetupSearchBoxButtonHandlers(searchFrame)

	searchFrame:Hide()
end

function Search:OnShow()
	BSYC:SetBSYC_FrameLevel(Search)

	if Data.IsCacheDisabled and Data:IsCacheDisabled() then
		Data:PopulateItemCache("full")
	else
		Data:PopulateItemCache("medium")
	end

	BSYC.advUnitList = nil
	BSYC.advAllowList = nil

	if not BSYC.options.alwaysShowSearchFilters then
		C_Timer.After(0.5, function()
			if BSYC.options.focusSearchEditBox then
				Search.frame.SearchBox:ClearFocus()
				Search.frame.SearchBox:SetFocus()
			end
		end)
	else
		Search:ShowSearchFilters(true)
	end

	Search:RefreshList()
end

function Search:OnHide()
	Search.warningFrame:Hide()
	Search.helpFrame:Hide()
	BSYC.advUnitList = nil
	BSYC.advAllowList = nil
	Search:ShowSearchFilters(false)
	Search:StopCacheOverlay()

	if Data.ApplyCacheSpeed then
		Data:ApplyCacheSpeed()
	else
		Data:SetCacheThrottle("background")
	end
end

function Search:ShowCacheOverlay(remaining)
	if not Search.cacheOverlay then return end
	if remaining and Search.cacheOverlay.text then
		Search.cacheOverlay.text:SetText(L.CachingItemData:format(remaining))
	end
	Search.cacheOverlay:Show()
	if Search.cacheOverlay.spinner and Search.cacheOverlay.spinner.anim then
		Search.cacheOverlay.spinner.anim:Play()
	end
end

function Search:HideCacheOverlay()
	if not Search.cacheOverlay then return end
	if Search.cacheOverlay.spinner and Search.cacheOverlay.spinner.anim then
		Search.cacheOverlay.spinner.anim:Stop()
	end
	Search.cacheOverlay:Hide()
end

function Search:UpdateCacheOverlay()
	if not Search.cacheBoostActive then return end

	local running, remaining = Data:GetItemCacheStatus()
	if running and remaining and remaining > 0 then
		Search:ShowCacheOverlay(remaining)
		BSYC:StartTimer("SearchCacheOverlay", 0.2, Search, "UpdateCacheOverlay")
		return
	end

	Search:StopCacheOverlay()
end

function Search:StartCacheOverlay()
	Search.cacheBoostActive = true
	Search:UpdateCacheOverlay()
end

function Search:StopCacheOverlay()
	Search.cacheBoostActive = nil
	BSYC:StopTimer("SearchCacheOverlay")
	Search:HideCacheOverlay()

	if Search.frame and Search.frame:IsShown() then
		if Data.IsCacheDisabled and Data:IsCacheDisabled() then
			Data:SetCacheThrottle("full")
		else
			Data:SetCacheThrottle("medium")
		end
	end
end

function Search:ShowSearchFilters(visible)
	local searchFilters = BSYC:GetModule("SearchFilters", true)
	-- Use rawget to bypass metatable when accessing .frame
	if not (searchFilters and rawget(searchFilters, "frame")) then return end

	local frame = rawget(searchFilters, "frame")
	if visible == nil then
		frame:SetShown(not frame:IsShown())
	elseif visible == true then
		frame:Show()
	else
		frame:Hide()
	end
end

-- Get the current active search frame (main or search filters)
-- This replaces 3 duplicate GetModule patterns throughout the file
local function GetCurrentSearchFrame()
	local searchFilters = BSYC:GetModule("SearchFilters", true)
	-- Use rawget to bypass metatable when accessing .frame
	local filterFrame = searchFilters and rawget(searchFilters, "frame")
	if filterFrame and filterFrame:IsVisible() then
		return filterFrame, true
	end
	return Search.frame, false
end

------------------------------------------------------------
-- ITEM SEARCH
------------------------------------------------------------

local function ParseItemData(data, compiled, checkList, atUserLoc)
	local iCount = 0

	for i = 1, #data do
		if data[i] then
			local link = BSYC:Split(data[i], true)
			if BSYC.options.enableShowUniqueItemsTotals and link then
				link = BSYC:GetShortItemID(link)
			end

			if link and not checkList[link] then
				local cacheObj = Data:CacheLink(link)
				if cacheObj then
					local entry = cacheObj.speciesName or cacheObj.itemLink
					local texture = cacheObj.speciesIcon or cacheObj.itemTexture
					local itemName = cacheObj.speciesName or cacheObj.itemName
					local testMatch = ItemScout:Find(entry, compiled, cacheObj)

					if entry and (testMatch or atUserLoc) then
						Debug(BSYC_DL.SL1, "FoundItem", entry)
					end

					checkList[link] = entry

					if testMatch or atUserLoc then
						table.insert(Search.items, {
							name = itemName,
							parseLink = link,
							entry = entry,
							link = cacheObj.itemLink,
							rarity = cacheObj.itemQuality,
							icon = texture,
							speciesID = BSYC:FakeIDToSpeciesID(link)
						})
					end
				elseif not Data.__cache.ignore[link] then
					iCount = iCount + 1
				end
			end
		end
	end

	return iCount
end

local function ProcessUnitTarget(unitObj, target, compiled, checkList, atUserLoc)
	local total = 0

	if not (unitObj.data[target] and BSYC.tracking[target]) then
		return total
	end

	if target == "bag" or target == "bank" or target == "reagents" then
		for _, bagData in pairs(unitObj.data[target] or {}) do
			total = total + ParseItemData(bagData, compiled, checkList, atUserLoc)
		end
		if (target == "bag" or target == "bank") and unitObj.data.equipbags then
			total = total + ParseItemData(unitObj.data.equipbags[target] or {}, compiled, checkList, atUserLoc)
		end
	elseif target == "auction" then
		total = ParseItemData(unitObj.data[target].bag or {}, compiled, checkList, atUserLoc)
	elseif target == "equip" or target == "void" or target == "mailbox" then
		total = ParseItemData(unitObj.data[target] or {}, compiled, checkList, atUserLoc)
	end

	return total
end

function Search:CheckItems(compiled, unitObj, target, checkList, atUserLoc)
	if not unitObj or not target then return 0 end
	if not compiled then return 0 end

	local total = ProcessUnitTarget(unitObj, target, compiled, checkList, atUserLoc)

	if target == "guild" and BSYC.tracking.guild then
		for _, tabData in pairs(unitObj.data.tabs or {}) do
			total = total + ParseItemData(tabData, compiled, checkList, atUserLoc)
		end
	end

	if target == "warband" and BSYC.tracking.warband then
		for _, tabData in pairs(unitObj.data.tabs or {}) do
			total = total + ParseItemData(tabData, compiled, checkList, atUserLoc)
		end
	end

	return total
end

local function GetSearchTargetLocation(searchStr, allowList)
	if #searchStr <= 1 then return nil end

	local atUserLoc = searchStr:match("@(.+)")
	if atUserLoc and (#atUserLoc < 1 or (atUserLoc ~= "guild" and not allowList[atUserLoc])) then
		return nil
	end

	return atUserLoc
end

local function ProcessSearchIteration(compiled, advUnitList, allowList, checkList, advAllowList)
	local warnTotal = 0
	local warbandObj = Data:GetWarbandBankObj()

	for unitObj in Data:IterateUnits(false, advUnitList) do
		if not unitObj.isGuild then
			for k in pairs(allowList) do
				if k ~= "guild" then
					warnTotal = warnTotal + Search:CheckItems(compiled, unitObj, k, checkList)
				end
			end
		else
			if not advAllowList or advAllowList.guild then
				warnTotal = warnTotal + Search:CheckItems(compiled, unitObj, "guild", checkList)
			end
		end
	end

	if warbandObj and allowList.warband then
		warnTotal = warnTotal + Search:CheckItems(compiled, warbandObj, "warband", checkList)
	end

	return warnTotal
end

local function ProcessPlayerLocationSearch(compiled, atUserLoc, checkList, advAllowList)
	local warnTotal = 0
	local playerObj = Data:GetPlayerObj()
	local warbandObj = Data:GetWarbandBankObj()

	if atUserLoc == "warband" and warbandObj then
		warnTotal = warnTotal + Search:CheckItems(compiled, warbandObj, atUserLoc, checkList, true)
	elseif atUserLoc ~= "guild" then
		warnTotal = warnTotal + Search:CheckItems(compiled, playerObj, atUserLoc, checkList, true)
	else
		if playerObj.data.guild and (not advAllowList or advAllowList.guild) then
			local guildObj = Data:GetPlayerGuildObj()
			if guildObj then
				warnTotal = warnTotal + Search:CheckItems(compiled, guildObj, atUserLoc, checkList, true)
			end
		end
	end

	return warnTotal
end

local function DisplaySearchWarning(warnTotal, searchStr, advUnitList, advAllowList, isSearchFilters, warnCount)
	if warnTotal > 0 then
		Search.helpFrame:Hide()
		Search.warningFrame.infoText1:SetText(L.WarningItemSearch:format(warnTotal))
		Search.warningFrame:Show()

		if not warnCount or warnCount <= 5 then
			warnCount = (warnCount or 0) + 1
			BSYC:StartTimer("SearchCacheChk", 0.5, Search, "DoSearch", searchStr, advUnitList, advAllowList, isSearchFilters, warnCount)
			return true
		end
	else
		Search.warningFrame:Hide()
	end

	return false
end

function Search:DoSearch(searchStr, advUnitList, advAllowList, isSearchFilters, warnCount)
	if not isSearchFilters then
		if not searchStr then searchStr = Search.frame.SearchBox:GetText() end
		if #searchStr <= 0 then return end
	end

	Data:PopulateItemCache("full")
	Search:StartCacheOverlay()

	Search.items = {}
	local checkList = {}

	Tooltip:ResetLastLink()

	BSYC.advUnitList = advUnitList
	BSYC.advAllowList = advAllowList

	local allowList = advAllowList or BSYC.DEFAULT_ALLOW_LIST
	local atUserLoc = not isSearchFilters and GetSearchTargetLocation(searchStr, BSYC.DEFAULT_ALLOW_LIST)
	local compiled = ItemScout:CompileSearch(searchStr)

	Debug(BSYC_DL.INFO, "init:DoSearch", searchStr, atUserLoc, advUnitList, advAllowList, isSearchFilters, warnCount)

	local warnTotal = atUserLoc
		and ProcessPlayerLocationSearch(compiled, atUserLoc, checkList, advAllowList)
		or ProcessSearchIteration(compiled, advUnitList, allowList, checkList, advAllowList)

	if DisplaySearchWarning(warnTotal, searchStr, advUnitList, advAllowList, isSearchFilters, warnCount) then
		return
	end

	table.sort(Search.items, function(a, b)
		return (a.name or "") < (b.name or "")
	end)

	Search:RefreshList()
end

function Search:RefreshList()
	local items = Search.items
	local buttons = HybridScrollFrame_GetButtons(Search.scrollFrame)
	local offset = HybridScrollFrame_GetOffset(Search.scrollFrame)

	if not buttons then return end

	for buttonIndex = 1, #buttons do
		local button = buttons[buttonIndex]
		UI:AttachListItemHandlers(button, Search, { detailsButton = "DetailsButton" })

		local itemIndex = buttonIndex + offset

		if itemIndex <= #items then
			local item = items[itemIndex]
			local r, g, b = GetItemQualityColor(item.rarity or 1)

			button:SetID(itemIndex)
			button.data = item
			button.Icon:SetTexture(item.icon)
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
			button.Text:SetText(item.name)
			button.Text:SetTextColor(r, g, b)
			button:SetWidth(Search.scrollFrame.scrollChild:GetWidth())

			if BSYC:IsMouseOver(button) then
				Search:Item_OnLeave()
				Search:Item_OnEnter(button)
			end

			button:Show()
		else
			button:Hide()
		end
	end

	Search.frame.totalText:SetText(L.TooltipTotal.." |cFFFFFFFF"..#items.."|r")

	local buttonHeight = Search.scrollFrame.buttonHeight
	local totalHeight = #items * buttonHeight
	local shownHeight = #buttons * buttonHeight

	HybridScrollFrame_Update(Search.scrollFrame, totalHeight, shownHeight)
end

function Search:Reset()
	Search.frame.SearchBox:SetText("")
	Search.frame.SearchBox.ClearButton:Hide()
	Search.frame.SearchBox.SearchInfo:Show()
	BSYC.advUnitList = nil
	BSYC.advAllowList = nil
	Search.items = {}
	Search:RefreshList()
end

function Search:ClearList()
	BSYC.advUnitList = nil
	BSYC.advAllowList = nil
	Search.items = {}
	Search:RefreshList()
end

function Search:RefreshClick()
	Search:DoSearch()
end

function Search:HelpClick()
	Search.helpFrame:SetShown(not Search.helpFrame:IsShown())
end

function Search:SearchBox_ResetSearch(btn)
	if btn then
		btn:Hide()
	end
	Search:Reset()
end

------------------------------------------------------------
-- ITEM INTERACTION
------------------------------------------------------------

local function SetupItemTooltip(btn, data, isBattlePet)
	if isBattlePet then
		GameTooltip:SetOwner(btn, "ANCHOR_BOTTOMRIGHT")
		BattlePetTooltip.isBSYCSearch = true
		if _G.BattlePetToolTip_Show then
			_G.BattlePetToolTip_Show(tonumber(data.speciesID), 0, 0, 0, 0, 0, nil)
		end
	else
		GameTooltip.isBSYCSearch = true
		GameTooltip:SetOwner(btn, "ANCHOR_BOTTOMRIGHT")
		GameTooltip:SetHyperlink("item:"..data.parseLink)
		GameTooltip:Show()
	end
end

function Search:ItemDetails(btn)
	Details = Details or BSYC:GetModule("Details", true)
	if Details and Details.ShowItem then
		local item = btn:GetParent()
		if item and item.data then
			Details:ShowItem(item.data.parseLink, item.data.entry)
		end
	end
end

function Search:Item_OnClick(btn)
	if not btn.data then return end

	if btn.data.speciesID then
		if IsModifiedClick("DRESSUP") then
			local petJournal = C_PetJournal or _G.C_PetJournal
			if petJournal and petJournal.GetPetInfoBySpeciesID then
				local _, _, _, creatureID, _, _, _, _, _, _, _, displayID = petJournal.GetPetInfoBySpeciesID(btn.data.speciesID)
				DressUpBattlePet(creatureID, displayID, btn.data.speciesID)
			end
		end
		return
	end

	if IsModifiedClick("CHATLINK") then
		ChatEdit_InsertLink(btn.data.link)
	elseif IsModifiedClick("DRESSUP") then
		if BSYC.IsRetail then
			DressUpLink(btn.data.link)
		else
			DressUpItemLink(btn.data.link)
		end
	end
end

function Search:Item_OnEnter(btn)
	if BSYC.advUnitList then
		Tooltip:ResetLastLink()
	end

	if btn.data then
		SetupItemTooltip(btn, btn.data, btn.data.speciesID ~= nil)
	end
end

function Search:Item_OnLeave()
	if BSYC.advUnitList then
		Tooltip:ResetLastLink()
	end

	GameTooltip.isBSYCSearch = nil
	GameTooltip:Hide()

	if BattlePetTooltip then
		BattlePetTooltip.isBSYCSearch = nil
		BattlePetTooltip:Hide()
	end
end

function Search:SearchBox_OnEnterPressed(text)
	Search:DoSearch(text)
end

function Search:SearchBox_OnEscapePressed()
	-- Hide the search window when escape is pressed
	if Search.frame and Search.frame:IsShown() then
		Search.frame:Hide()
	end
end


function Search:SearchBox_OnTextChanged(userInput)
	-- Clear the list when the search box is emptied
	local frame = Search.frame
	if frame and frame.SearchBox then
		local text = frame.SearchBox:GetText()
		if text == "" or text == " " then
			Search:ClearList()
		end
	end
end
function Search:ItemDetails_OnEnter(btn)
	local item = btn:GetParent()

	GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
	GameTooltip:AddLine("|cFFe454fd"..L.Details.."|r")
	GameTooltip:AddLine("|cFFFFFFFF"..L.TooltipDetailsInfo.."|r")
	GameTooltip:AddLine(" ")

	if item and item.data then
		local entry = item.data.entry or item.data.parseLink or item.data.link
		if entry then
			GameTooltip:AddLine("|cFFCF9FFF"..entry.."|r")
		end
	end

	GameTooltip:Show()
end

function Search:ItemDetails_OnLeave()
	Search:Item_OnLeave()
end

function Search:PlusClick()
	Search.savedSearch:SetShown(not Search.savedSearch:IsShown())
end

------------------------------------------------------------
-- SAVED SEARCH
------------------------------------------------------------

function Search:SavedSearch_UpdateList()
	Search:SavedSearch_CreateList()
	Search:SavedSearch_RefreshList()
end

function Search:SavedSearch_CreateList()
	Search.savedSearch.items = {}

	for i = 1, #BSYC.db.savedsearch do
		table.insert(Search.savedSearch.items, {
			key = i,
			value = BSYC.db.savedsearch[i]
		})
	end
end

function Search:SavedSearch_RefreshList()
	local items = Search.savedSearch.items
	local buttons = HybridScrollFrame_GetButtons(Search.savedSearch.scrollFrame)
	local offset = HybridScrollFrame_GetOffset(Search.savedSearch.scrollFrame)

	if not buttons then return end

	for buttonIndex = 1, #buttons do
		local button = buttons[buttonIndex]
		UI:AttachListItemHandlers(button, Search, {
			onClick = "SavedSearch_Item_OnClick",
			onEnter = "SavedSearch_Item_OnEnter",
			onLeave = "SavedSearch_Item_OnLeave",
			detailsButton = "DeleteButton",
			onDetailsClick = "SavedSearch_Delete",
			onDetailsEnter = false,
			onDetailsLeave = false,
		})

		local itemIndex = buttonIndex + offset

		if itemIndex <= #items then
			local item = items[itemIndex]

			button:SetID(itemIndex)
			button.data = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
			button:SetWidth(Search.savedSearch.scrollFrame.scrollChild:GetWidth())

			button.Text:SetWordWrap(false)
			button.Text:SetPoint("LEFT", 8, 0)
			button.Text:SetPoint("RIGHT", button, -30, 0)
			button.Text:SetJustifyH("LEFT")
			button.Text:SetTextColor(1, 1, 1)
			button.Text:SetText(item.value)
			button.HeaderHighlight:SetAlpha(0)

			button:Show()
		else
			button:Hide()
		end
	end

	local buttonHeight = Search.savedSearch.scrollFrame.buttonHeight
	local totalHeight = #items * buttonHeight
	local shownHeight = #buttons * buttonHeight

	HybridScrollFrame_Update(Search.savedSearch.scrollFrame, totalHeight, shownHeight)
end

function Search:SavedSearch_AddItem()
	local frame, isSearchFilters = GetCurrentSearchFrame()
	local storeText = frame.SearchBox:GetText()

	if not storeText or #storeText < 1 then
		BSYC:Print(L.SavedSearch_Warn)
		return
	end

	table.insert(BSYC.db.savedsearch, storeText)
	Search:SavedSearch_UpdateList()
end

function Search:SavedSearch_Delete(btn)
	local item = btn:GetParent()
	table.remove(BSYC.db.savedsearch, item.data.key)
	Search:SavedSearch_UpdateList()
end

function Search:SavedSearch_Item_OnClick(btn)
	local frame = GetCurrentSearchFrame()

	frame.SearchBox.SearchInfo:Hide()
	frame.SearchBox:SetText(btn.data.value)

	local searchFilters = BSYC:GetModule("SearchFilters", true)
	-- Use rawget to bypass metatable when accessing .frame
	local filterFrame = searchFilters and rawget(searchFilters, "frame")
	if filterFrame and filterFrame:IsVisible() then
		searchFilters:DoSearch()
	else
		Search:DoSearch()
	end
end

local function splitByChunk(text, chunkSize)
	local s = {}
	for i = 1, #text, chunkSize do
		s[#s+1] = text:sub(i, i + chunkSize - 1)
	end
	return s
end

function Search:SavedSearch_Item_OnEnter(btn)
	GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
	GameTooltip:AddLine("|cFFFFFFFF"..L.SavedSearch.."|r")

	local list = splitByChunk(btn.data.value, 45)
	for i, v in ipairs(list) do
		GameTooltip:AddLine(v)
	end

	GameTooltip:Show()
end

function Search:SavedSearch_Item_OnLeave()
	GameTooltip:Hide()
end
