--[[
	search.lua
		A search frame for BagSync items

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local UI = BSYC:GetModule("UI")
local Search = BSYC:NewModule("Search")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Search", ...) end
end

local L = BSYC.L
local ItemScout = LibStub("LibItemScout-1.0")

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
		-- set ScrollFrame height by altering the distance from the bottom of the frame
		pointBottomLeft = { "BOTTOMLEFT", searchFrame, "BOTTOMLEFT", -25, 42 },
		buttonTemplate = "BagSyncListItemTemplate",
		update = function() Search:RefreshList(); end,
	})
	--the items we will work with
	Search.items = {}

	-- Cache overlay (spinner + remaining count), centered over the item list
	local cacheOverlay = UI:CreateFrame(searchFrame, {
		frameStrata = "DIALOG",
		frameLevel = searchFrame:GetFrameLevel() + 20,
		enableMouse = true,
		points = {
			{ "TOPLEFT", Search.scrollFrame, "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", Search.scrollFrame, "BOTTOMRIGHT", 0, 0 },
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
	Search.cacheOverlay = cacheOverlay

	--total counter
	searchFrame.totalText = UI:CreateFontString(searchFrame, {
		template = "GameFontHighlightSmall",
		text = L.TooltipTotal.." |cFFFFFFFF0|r",
		font = { STANDARD_TEXT_FONT, 12, "" },
		textColor = { 1, 165/255, 0 },
		point = { "LEFT", searchFrame, "BOTTOMLEFT", 15, 20 },
		justifyH = "LEFT",
	})

	--Search Filters button
	searchFrame.searchFiltersBtn = UI:CreateButton(searchFrame, {
		template = "UIPanelButtonTemplate",
		text = L.SearchFilters,
		height = 20,
		autoWidth = true,
		point = { "RIGHT", searchFrame, "BOTTOMRIGHT", -10, 23 },
		onClick = function() Search:ShowSearchFilters() end,
	})

	--Reset button
	searchFrame.resetButton = UI:CreateButton(searchFrame, {
		template = "UIPanelButtonTemplate",
		text = L.Reset,
		height = 20,
		autoWidth = true,
		point = { "RIGHT", searchFrame.searchFiltersBtn, "LEFT", 0, 0 },
		onClick = function() Search:Reset() end,
	})

	--Warning Frame
	local warningFrame = UI:CreateInfoFrame(searchFrame, {
		title = L.WarningHeader,
		point = { "BOTTOMLEFT", searchFrame, "BOTTOMRIGHT", 5, 0 },
		backdropColor = { 0, 0, 0, 0.75 },
	})
	warningFrame.infoText1 = UI:CreateFontString(warningFrame, {
		template = "GameFontHighlightSmall",
		text = L.WarningItemSearch,
		font = { STANDARD_TEXT_FONT, 14, "" },
		textColor = { 1, 165/255, 0 }, --orange, red is just too much sometimes
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
	Search.warningFrame = warningFrame

	--Help Frame
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
		width = 465, --set the boundaries for word wrapping on the scrollbar, if smaller than the frame it will wrap it
	})
	helpFrame.EditBox:SetAllPoints()
	helpFrame.ScrollFrame:SetScrollChild(helpFrame.EditBox)
	--lets set it to disabled to prevent editing
	helpFrame.EditBox:ClearFocus()
	helpFrame.EditBox:EnableMouse(false)
	helpFrame.EditBox:SetTextColor(1, 1, 1) --set default to white
	helpFrame.ScrollFrame:EnableMouse(false)
	Search.helpFrame = helpFrame

	--Saved Search Frame
	local savedSearch = UI:CreateInfoFrame(searchFrame, {
		title = L.SavedSearch,
		width = 400,
		height = 200,
		point = { "TOPLEFT", searchFrame, "TOPRIGHT", 5, 0 },
		backdropColor = { 0, 0, 0, 0.75 },
	})
	savedSearch:SetScript("OnShow", function() Search:SavedSearch_UpdateList() end)
	Search.savedSearch = savedSearch
	savedSearch.scrollFrame = UI:CreateHybridScrollFrame(savedSearch, {
		width = 357,
		pointTopLeft = { "TOPLEFT", savedSearch, "TOPLEFT", 13, -32 },
		-- set ScrollFrame height by altering the distance from the bottom of the frame
		pointBottomLeft = { "BOTTOMLEFT", savedSearch, "BOTTOMLEFT", -25, 36 },
		buttonTemplate = "BagSyncSavedListTemplate",
		update = function() Search:SavedSearch_RefreshList(); end,
	})
	--the items we will work with
	savedSearch.items = {}
	--Add Search Button
	savedSearch.addSavedBtn = UI:CreateButton(savedSearch, {
		template = "UIPanelButtonTemplate",
		text = L.SavedSearch_Add,
		height = 20,
		autoWidth = true,
		point = { "BOTTOM", savedSearch, "BOTTOM", 0, 5 },
		onClick = function() Search:SavedSearch_AddItem() end,
	})

	--Modules Button (credit to LibDBIcon-1.0.lua for initial button design)
	searchFrame.modulesButton = UI:CreateButton(searchFrame, {
		size = { 31, 31 },
		registerForClicks = "anyUp",
		highlightTexture = 136477, --"Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
		point = { "TOPLEFT", searchFrame, "TOPLEFT", 0, 0 },
		onClick = function()
			if BSYC.OpenMinimapMenu then
				BSYC:OpenMinimapMenu("cursor")
			elseif BSYC.bgsMinimapDD then
				ToggleDropDownMenu(1, nil, BSYC.bgsMinimapDD, "cursor", 0, 0)
			end
		end,
	})

	local modulesButtonOverlay = UI:CreateTexture(searchFrame.modulesButton, { layer = "OVERLAY" })
	local modulesButtonBG = UI:CreateTexture(searchFrame.modulesButton, { layer = "BACKGROUND" })
	local modulesButtonIcon = UI:CreateTexture(searchFrame.modulesButton, { layer = "ARTWORK" })

	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		modulesButtonOverlay:SetSize(50, 50)
		modulesButtonOverlay:SetTexture(136430) --"Interface\\Minimap\\MiniMap-TrackingBorder"
		modulesButtonOverlay:SetPoint("TOPLEFT", searchFrame.modulesButton, "TOPLEFT", 0, 0)
		modulesButtonBG:SetSize(24, 24)
		modulesButtonBG:SetTexture(136467) --"Interface\\Minimap\\UI-Minimap-Background"
		modulesButtonBG:SetPoint("CENTER", searchFrame.modulesButton, "CENTER", 0, 1)
		modulesButtonIcon:SetSize(18, 18)
		modulesButtonIcon:SetTexture("Interface\\AddOns\\BagSync\\media\\icon")
		modulesButtonIcon:SetPoint("CENTER", searchFrame.modulesButton, "CENTER", 0, 1)
	else
		modulesButtonOverlay:SetSize(53, 53)
		modulesButtonOverlay:SetTexture(136430) --"Interface\\Minimap\\MiniMap-TrackingBorder"
		modulesButtonOverlay:SetPoint("TOPLEFT")
		modulesButtonBG:SetSize(20, 20)
		modulesButtonBG:SetTexture(136467) --"Interface\\Minimap\\UI-Minimap-Background"
		modulesButtonBG:SetPoint("TOPLEFT", 7, -5)
		modulesButtonIcon:SetSize(17, 17)
		modulesButtonIcon:SetTexture("Interface\\AddOns\\BagSync\\media\\icon")
		modulesButtonIcon:SetPoint("TOPLEFT", 7, -6)
	end

	local searchBox = searchFrame.SearchBox
	if searchBox then
		UI:SetupSearchBox(searchBox, Search)
	end

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

	searchFrame:Hide() --important
end

function Search:OnShow()
	BSYC:SetBSYC_FrameLevel(Search)
	if Data.IsCacheDisabled and Data:IsCacheDisabled() then
		Data:PopulateItemCache("full") --disabled: cache only while open, use full throttle
	else
		Data:PopulateItemCache("medium") --search window open: medium throttle
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
		Data:ApplyCacheSpeed() --return to user-selected background throttle
	else
		Data:SetCacheThrottle("background") --legacy fallback
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
	if not (searchFilters and searchFilters.frame) then return end

	local frame = searchFilters.frame
	if visible == nil then
		frame:SetShown(not frame:IsShown())
	elseif visible == true then
		frame:Show()
	else
		frame:Hide()
	end
end

function Search:CheckItems(searchStr, unitObj, target, checkList, atUserLoc)
	local total = 0
	if not unitObj or not target then return total end
	searchStr = searchStr or ''

	local function parseItems(data)
		local iCount = 0
		for i=1, #data do
			if data[i] then
				local link = BSYC:Split(data[i], true)
				if BSYC.options.enableShowUniqueItemsTotals and link then link = BSYC:GetShortItemID(link) end

				--we only really want to grab and search the item only once
				if link and not checkList[link] then
					--do cache grab
					local cacheObj = Data:CacheLink(link)
					if cacheObj then
						local entry = cacheObj.speciesName or cacheObj.itemLink --C_Item.GetItemInfo does not support battlepet links, use speciesName instead
						local texture = cacheObj.speciesIcon or cacheObj.itemTexture
						local itemName = cacheObj.speciesName or cacheObj.itemName
						local testMatch = ItemScout:Find(entry, searchStr, cacheObj)

						--for debugging purposes only
						if entry and (testMatch or atUserLoc) then
							Debug(BSYC_DL.SL1, "FoundItem", searchStr, entry, unitObj.name, unitObj.realm)
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
						--add to warning count total if we haven't processed that item
						iCount = iCount + 1
					end
				end
			end
		end
		return iCount
	end

	if unitObj.data[target] and BSYC.tracking[target] then
		if target == "bag" or target == "bank" or target == "reagents" then
			for bagID, bagData in pairs(unitObj.data[target] or {}) do
				total = total + parseItems(bagData)
			end
			--do equipbags
			if (target == "bag" or target == "bank") and unitObj.data.equipbags then
				total = total + parseItems(unitObj.data.equipbags[target] or {})
			end
		elseif target == "auction" then
			total = parseItems(unitObj.data[target].bag or {})

		elseif target == "equip" or target == "void" or target == "mailbox" then
			total = parseItems(unitObj.data[target] or {})
		end
	end
	if target == "guild" and BSYC.tracking.guild then
		for tabID, tabData in pairs(unitObj.data.tabs or {}) do
			total = total + parseItems(tabData)
		end
	end
	if target == "warband" and BSYC.tracking.warband then
		for tabID, tabData in pairs(unitObj.data.tabs or {}) do
			total = total + parseItems(tabData)
		end
	end

	return total
end

function Search:DoSearch(searchStr, advUnitList, advAllowList, isSearchFilters, warnCount)

	--only check for specifics when not using search filters
	if not isSearchFilters then
		if not searchStr then searchStr = Search.frame.SearchBox:GetText() end
		if string.len(searchStr) <= 0 then return end
	end

	-- active search: full throttle cache and show overlay
	Data:PopulateItemCache("full")
	Search:StartCacheOverlay()

	Search.items = {}
	local checkList = {}
	local warnTotal = 0
	local atUserLoc

	--make sure to always be using updated information, especially if processing items from Search Filters frame
	Tooltip:ResetLastLink()

	BSYC.advUnitList = advUnitList
	BSYC.advAllowList = advAllowList

	--items aren't counted into this array, it's just for allowing the search to pass through
	local allowList = BSYC.DEFAULT_ALLOW_LIST

	--This is used when a player is requesting to view a custom list, such as @bank, @auction, @bag etc...
	if not isSearchFilters and string.len(searchStr) > 1 then
		atUserLoc = searchStr:match("@(.+)")
		--check it to verify it's a valid command
		if atUserLoc and (string.len(atUserLoc) < 1 or (atUserLoc ~= "guild" and not allowList[atUserLoc])) then atUserLoc = nil end
	end

	--overwrite the allowlist with the advance one if it isn't empty
	allowList = advAllowList or allowList
	Debug(BSYC_DL.INFO, "init:DoSearch", searchStr, atUserLoc, advUnitList, advAllowList, isSearchFilters, warnCount)

	local warbandObj = Data:GetWarbandBankObj()

	if not atUserLoc then
		for unitObj in Data:IterateUnits(false, advUnitList) do
			if not unitObj.isGuild then
				for k in pairs(allowList) do
					if k ~= "guild" then
						warnTotal = warnTotal + Search:CheckItems(searchStr, unitObj, k, checkList)
					end
				end
			else
				--only do guild if filters allow it, otherwise it will always show up regardless of what custom field is selected
				--obviously guilds can't have stuff stored in AH, Mailbox, Void, etc...
				if not advAllowList or advAllowList.guild then
					warnTotal = warnTotal + Search:CheckItems(searchStr, unitObj, "guild", checkList)
				end
			end
		end
		if warbandObj and allowList.warband then
			warnTotal = warnTotal + Search:CheckItems(searchStr, warbandObj, "warband", checkList)
		end
	else
		--player using an @location, so lets only search their database and not IterateUnits
		local playerObj = Data:GetPlayerObj()

		if atUserLoc == "warband" and warbandObj then
			warnTotal = warnTotal + Search:CheckItems(searchStr, warbandObj, atUserLoc, checkList, true)
		elseif atUserLoc ~= "guild" then
			warnTotal = warnTotal + Search:CheckItems(searchStr, playerObj, atUserLoc, checkList, true)
		else
			--only do guild if we aren't using a custom adllowlist, otherwise it will always show up regardless of what custom field is selected
			if playerObj.data.guild and (not advAllowList or advAllowList.guild) then
				local guildObj = Data:GetPlayerGuildObj()
				if guildObj then
					warnTotal = warnTotal + Search:CheckItems(searchStr, guildObj, atUserLoc, checkList, true)
				end
			end
		end
	end

	--show warning window if the server hasn't queried all the items yet
	if warnTotal > 0 then
		Search.helpFrame:Hide()
		Search.warningFrame.infoText1:SetText(L.WarningItemSearch:format(warnTotal))
		Search.warningFrame:Show()

		--lets not do TOO many refreshes
		if not warnCount or warnCount <= 5 then
			warnCount = (warnCount or 0) + 1
			BSYC:StartTimer("SearchCacheChk", 0.5, Search, "DoSearch", searchStr, advUnitList, advAllowList, isSearchFilters, warnCount)
			return
		end
	else
		Search.warningFrame:Hide()
	end

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
			local r, g, b, hex = GetItemQualityColor(item.rarity or 1)

            button:SetID(itemIndex)
			button.data = item
            button.Icon:SetTexture(item.icon or nil)
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
            button.Text:SetText(item.name or "")
			button.Text:SetTextColor(r, g, b)
            button:SetWidth(Search.scrollFrame.scrollChild:GetWidth())

			--while we are updating the scrollframe, is the mouse currently over a button?
			--if so we need to force the OnEnter as the items will scroll up in data but the button remains the same position on our cursor
			if BSYC:IsMouseOver(button) then
				Search:Item_OnLeave() --hide first
				Search:Item_OnEnter(button)
			end

            button:Show()
        else
            button:Hide()
        end
    end

	Search.frame.totalText:SetText(L.TooltipTotal.." |cFFFFFFFF"..(#items or 0).."|r")

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
	btn:Hide()
	Search:Reset()
end

function Search:ItemDetails(btn)
	local details = BSYC:GetModule("Details", true)
	if details and details.ShowItem then
		local item = btn:GetParent()
		if item and item.data then
			details:ShowItem(item.data.parseLink, item.data.entry)
		end
	end
end

function Search:Item_OnClick(btn)
	if btn.data then
		if btn.data.speciesID then
			if IsModifiedClick("DRESSUP") then
				--https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/FrameXML/DressUpFrames.lua
				local _, _ ,_ , creatureID, _, _, _, _, _, _, _, displayID = C_PetJournal.GetPetInfoBySpeciesID(btn.data.speciesID)
				DressUpBattlePet(creatureID, displayID, btn.data.speciesID)
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
end

function Search:Item_OnEnter(btn)
	if BSYC.advUnitList then
		--reset the last cache link when using the search filters to prevent improper listings from being cached
		Tooltip:ResetLastLink()
	end
    if btn.data then
		if not btn.data.speciesID then
			GameTooltip.isBSYCSearch = true
			GameTooltip:SetOwner(btn, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:SetHyperlink("item:"..btn.data.parseLink)
			GameTooltip:Show()
		else
			--BattlePetToolTip_Show uses the previous GameTooltip owner positioning
			GameTooltip:SetOwner(btn, "ANCHOR_BOTTOMRIGHT")
			BattlePetTooltip.isBSYCSearch = true
			BattlePetToolTip_Show(tonumber(btn.data.speciesID), 0, 0, 0, 0, 0, nil)
		end
	end
end

function Search:Item_OnLeave()
	if BSYC.advUnitList then
		--reset the last cache link when using the search filters to prevent improper listings from being cached
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

-----------------------------
--- SAVED SEARCH
-----------------------------

function Search:SavedSearch_UpdateList()
	Search:SavedSearch_CreateList()
	Search:SavedSearch_RefreshList()
end

function Search:SavedSearch_CreateList()
	Search.savedSearch.items = {}

	--loop through our blacklist
	for i=1, #BSYC.db.savedsearch do
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
			--set the fontstring size by using multiple setpoints to make the dimensions
			button.Text:SetPoint("LEFT", 8, 0)
			button.Text:SetPoint("RIGHT", button, -30, 0)

			button.Text:SetJustifyH("LEFT")
			button.Text:SetTextColor(1, 1, 1)
			button.Text:SetText(item.value or "")
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
	local storeText = ""
	local frame = Search.frame

	local searchFilters = BSYC:GetModule("SearchFilters", true)
	if searchFilters and searchFilters.frame and searchFilters.frame:IsVisible() then
		frame = searchFilters.frame
	end
	storeText = frame.SearchBox:GetText()
	if not storeText or string.len(storeText) < 1 then
		BSYC:Print(L.SavedSearch_Warn)
		return
	end
	--store it and update the view list
	table.insert(BSYC.db.savedsearch, storeText)
	Search:SavedSearch_UpdateList()
end

function Search:SavedSearch_Delete(btn)
	local item = btn:GetParent()
	table.remove(BSYC.db.savedsearch, item.data.key)
	Search:SavedSearch_UpdateList()
end

function Search:SavedSearch_Item_OnClick(btn)
	local frame = Search.frame
	local isSearchFilters = false

	local searchFilters = BSYC:GetModule("SearchFilters", true)
	if searchFilters and searchFilters.frame and searchFilters.frame:IsVisible() then
		frame = searchFilters.frame
		isSearchFilters = true
	end

	frame.SearchBox.SearchInfo:Hide()
	frame.SearchBox:SetText(btn.data.value)

	if isSearchFilters then
		searchFilters:DoSearch()
	else
		Search:DoSearch()
	end
end

local function splitByChunk(text, chunkSize)
    local s = {}
    for i=1, #text, chunkSize do
        s[#s+1] = text:sub(i,i+chunkSize - 1)
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
