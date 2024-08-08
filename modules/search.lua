--[[
	search.lua
		A search frame for BagSync items

		BagSync - All Rights Reserved - (c) 2024
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Search = BSYC:NewModule("Search")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Search", ...) end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local ItemScout = LibStub("LibItemScout-1.0")

Search.cacheItems = {}

function Search:OnEnable()
    local searchFrame = _G.CreateFrame("Frame", nil, UIParent, "BagSyncSearchFrameTemplate")
	Mixin(searchFrame, Search) --implement new frame to our parent module Mixin, to have access to parent methods
	_G["BagSyncSearchFrame"] = searchFrame
    --Add to special frames so window can be closed when the escape key is pressed.
    tinsert(UISpecialFrames, "BagSyncSearchFrame")
    searchFrame.TitleText:SetText("BagSync - "..L.Search)
	searchFrame:SetWidth(400)
    searchFrame:SetHeight(500)
    searchFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    searchFrame:EnableMouse(true) --don't allow clickthrough
    searchFrame:SetMovable(true)
    searchFrame:SetResizable(false)
    searchFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	searchFrame:RegisterForDrag("LeftButton")
	searchFrame:SetClampedToScreen(true)
	searchFrame:SetScript("OnDragStart", searchFrame.StartMoving)
	searchFrame:SetScript("OnDragStop", searchFrame.StopMovingOrSizing)
	searchFrame:SetScript("OnShow", function() Search:OnShow() end)
	searchFrame:SetScript("OnHide", function() Search:OnHide() end)
	local closeBtn = CreateFrame("Button", nil, searchFrame, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", C_EditMode and -3 or 2, C_EditMode and -3 or 1) --check for classic servers to adjust for positioning using a check for the new EditMode
    searchFrame.closeBtn = closeBtn
    Search.frame = searchFrame

    Search.scrollFrame = _G.CreateFrame("ScrollFrame", nil, searchFrame, "HybridScrollFrameTemplate")
    Search.scrollFrame:SetWidth(357)
    Search.scrollFrame:SetPoint("TOPLEFT", searchFrame, "TOPLEFT", 13, -60)
    --set ScrollFrame height by altering the distance from the bottom of the frame
    Search.scrollFrame:SetPoint("BOTTOMLEFT", searchFrame, "BOTTOMLEFT", -25, 42)
    Search.scrollFrame.scrollBar = CreateFrame("Slider", "$parentscrollBar", Search.scrollFrame, "HybridScrollBarTemplate")
    Search.scrollFrame.scrollBar:SetPoint("TOPLEFT", Search.scrollFrame, "TOPRIGHT", 1, -16)
    Search.scrollFrame.scrollBar:SetPoint("BOTTOMLEFT", Search.scrollFrame, "BOTTOMRIGHT", 1, 12)
	--initiate the scrollFrame
    --the items we will work with
    Search.items = {}
	Search.scrollFrame.update = function() Search:RefreshList(); end
    HybridScrollFrame_SetDoNotHideScrollBar(Search.scrollFrame, true)
	HybridScrollFrame_CreateButtons(Search.scrollFrame, "BagSyncListItemTemplate")

	--total counter
	searchFrame.totalText = searchFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	searchFrame.totalText:SetText(L.TooltipTotal.." |cFFFFFFFF0|r")
	searchFrame.totalText:SetFont(STANDARD_TEXT_FONT, 12, "")
	searchFrame.totalText:SetTextColor(1, 165/255, 0)
	searchFrame.totalText:SetPoint("LEFT", searchFrame, "BOTTOMLEFT", 15, 20)
	searchFrame.totalText:SetJustifyH("LEFT")

	--Advanced Search button
	searchFrame.advSearchBtn = _G.CreateFrame("Button", nil, searchFrame, "UIPanelButtonTemplate")
	searchFrame.advSearchBtn:SetText(L.AdvancedSearch)
	searchFrame.advSearchBtn:SetHeight(20)
	searchFrame.advSearchBtn:SetWidth(searchFrame.advSearchBtn:GetTextWidth() + 30)
	searchFrame.advSearchBtn:SetPoint("RIGHT", searchFrame, "BOTTOMRIGHT", -10, 23)
	searchFrame.advSearchBtn:SetScript("OnClick", function() Search:ShowAdvanced() end)

	--Reset button
	searchFrame.resetButton = _G.CreateFrame("Button", nil, searchFrame, "UIPanelButtonTemplate")
	searchFrame.resetButton:SetText(L.Reset)
	searchFrame.resetButton:SetHeight(20)
	searchFrame.resetButton:SetWidth(searchFrame.resetButton:GetTextWidth() + 30)
	searchFrame.resetButton:SetPoint("RIGHT", searchFrame.advSearchBtn, "LEFT", 0, 0)
	searchFrame.resetButton:SetScript("OnClick", function() Search:Reset() end)

	--Warning Frame
	local warningFrame = _G.CreateFrame("Frame", nil, searchFrame, "BagSyncInfoFrameTemplate")
	warningFrame:Hide()
	warningFrame:SetBackdropColor(0, 0, 0, 0.75)
    warningFrame:EnableMouse(true) --don't allow clickthrough
    warningFrame:SetMovable(false)
	warningFrame:SetResizable(false)
    warningFrame:SetFrameStrata("HIGH")
	warningFrame:ClearAllPoints()
	warningFrame:SetPoint("BOTTOMLEFT", searchFrame, "BOTTOMRIGHT", 5, 0)
	warningFrame.TitleText:SetText(L.WarningHeader)
	warningFrame.TitleText:SetFont(STANDARD_TEXT_FONT, 14, "")
	warningFrame.TitleText:SetTextColor(1, 1, 1)
	warningFrame.infoText1 = warningFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	warningFrame.infoText1:SetText(L.WarningItemSearch)
	warningFrame.infoText1:SetFont(STANDARD_TEXT_FONT, 14, "")
	warningFrame.infoText1:SetTextColor(1, 165/255, 0) --orange, red is just too much sometimes
	warningFrame.infoText1:SetJustifyH("CENTER")
	warningFrame.infoText1:SetWidth(warningFrame:GetWidth() - 30)
	warningFrame.infoText1:SetPoint("LEFT", warningFrame, "TOPLEFT", 10, -100)
	warningFrame.infoText2 = warningFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	warningFrame.infoText2:SetText(L.ObsoleteWarning)
	warningFrame.infoText2:SetFont(STANDARD_TEXT_FONT, 14, "")
	warningFrame.infoText2:SetTextColor(50/255, 165/255, 0)
	warningFrame.infoText2:SetWidth(warningFrame:GetWidth() - 30)
	warningFrame.infoText2:SetPoint("LEFT", warningFrame.infoText1, "BOTTOMLEFT", 5, -70)
	warningFrame.infoText2:SetJustifyH("CENTER")
	Search.warningFrame = warningFrame

	--Help Frame
	local helpFrame = _G.CreateFrame("Frame", nil, searchFrame, "BagSyncInfoFrameTemplate")
	helpFrame:Hide()
	helpFrame:SetWidth(500)
	helpFrame:SetHeight(300)
	helpFrame:SetBackdropColor(0, 0, 0, 0.75)
    helpFrame:EnableMouse(true) --don't allow clickthrough
    helpFrame:SetMovable(false)
	helpFrame:SetResizable(false)
    helpFrame:SetFrameStrata("HIGH")
	helpFrame:ClearAllPoints()
	helpFrame:SetPoint("BOTTOMLEFT", searchFrame, "BOTTOMRIGHT", 5, 0)
	helpFrame.TitleText:SetText(L.SearchHelpHeader)
	helpFrame.TitleText:SetFont(STANDARD_TEXT_FONT, 14, "")
	helpFrame.TitleText:SetTextColor(1, 1, 1)
	helpFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, helpFrame, "UIPanelScrollFrameTemplate")
	helpFrame.ScrollFrame:SetPoint("TOPLEFT", helpFrame, "TOPLEFT", 8, -30)
	helpFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", helpFrame, "BOTTOMRIGHT", -30, 8)
	helpFrame.EditBox = _G.CreateFrame("EditBox", nil, helpFrame.ScrollFrame)
	helpFrame.EditBox:SetAllPoints()
	helpFrame.EditBox:SetFontObject(ChatFontNormal)
	helpFrame.EditBox:SetMultiLine(true)
	helpFrame.EditBox:SetAutoFocus(false)
	helpFrame.EditBox:SetMaxLetters(0)
	helpFrame.EditBox:SetCountInvisibleLetters(false)
	helpFrame.EditBox:SetText(L.SearchHelp)
	helpFrame.EditBox:SetWidth(465) --set the boundaries for word wrapping on the scrollbar, if smaller than the frame it will wrap it
	helpFrame.ScrollFrame:SetScrollChild(helpFrame.EditBox)
	--lets set it to disabled to prevent editing
	helpFrame.EditBox:ClearFocus()
	helpFrame.EditBox:EnableMouse(false)
	helpFrame.EditBox:SetTextColor(1, 1, 1) --set default to white
	helpFrame.ScrollFrame:EnableMouse(false)
	Search.helpFrame = helpFrame

	--Saved Search Frame
	local savedSearch = _G.CreateFrame("Frame", nil, searchFrame, "BagSyncInfoFrameTemplate")
	savedSearch:Hide()
	savedSearch:SetHeight(200)
	savedSearch:SetWidth(400)
	savedSearch:SetBackdropColor(0, 0, 0, 0.75)
    savedSearch:EnableMouse(true) --don't allow clickthrough
    savedSearch:SetMovable(false)
	savedSearch:SetResizable(false)
    savedSearch:SetFrameStrata("HIGH")
	savedSearch:ClearAllPoints()
	savedSearch:SetPoint("TOPLEFT", searchFrame, "TOPRIGHT", 5, 0)
	savedSearch.TitleText:SetText(L.SavedSearch)
	savedSearch.TitleText:SetFont(STANDARD_TEXT_FONT, 14, "")
	savedSearch.TitleText:SetTextColor(1, 1, 1)
	savedSearch:SetScript("OnShow", function() Search:SavedSearch_UpdateList() end)
	Search.savedSearch = savedSearch
    savedSearch.scrollFrame = _G.CreateFrame("ScrollFrame", nil, savedSearch, "HybridScrollFrameTemplate")
    savedSearch.scrollFrame:SetWidth(357)
    savedSearch.scrollFrame:SetPoint("TOPLEFT", savedSearch, "TOPLEFT", 13, -32)
    --set ScrollFrame height by altering the distance from the bottom of the frame
    savedSearch.scrollFrame:SetPoint("BOTTOMLEFT", savedSearch, "BOTTOMLEFT", -25, 36)
    savedSearch.scrollFrame.scrollBar = CreateFrame("Slider", "$parentscrollBar", savedSearch.scrollFrame, "HybridScrollBarTemplate")
    savedSearch.scrollFrame.scrollBar:SetPoint("TOPLEFT", savedSearch.scrollFrame, "TOPRIGHT", 1, -16)
    savedSearch.scrollFrame.scrollBar:SetPoint("BOTTOMLEFT", savedSearch.scrollFrame, "BOTTOMRIGHT", 1, 12)
	--initiate the scrollFrame
    --the items we will work with
    savedSearch.items = {}
	savedSearch.scrollFrame.update = function() Search:SavedSearch_RefreshList(); end
    HybridScrollFrame_SetDoNotHideScrollBar(savedSearch.scrollFrame, true)
	HybridScrollFrame_CreateButtons(savedSearch.scrollFrame, "BagSyncSavedListTemplate")
	--Add Search Button
	savedSearch.addSavedBtn = _G.CreateFrame("Button", nil, savedSearch, "UIPanelButtonTemplate")
	savedSearch.addSavedBtn:SetText(L.SavedSearch_Add)
	savedSearch.addSavedBtn:SetHeight(20)
	savedSearch.addSavedBtn:SetWidth(savedSearch.addSavedBtn:GetTextWidth() + 30)
	savedSearch.addSavedBtn:SetPoint("BOTTOM", savedSearch, "BOTTOM", 0, 5)
	savedSearch.addSavedBtn:SetScript("OnClick", function() Search:SavedSearch_AddItem() end)

	--Modules Button (credit to LibDBIcon-1.0.lua for initial button design)
	searchFrame.modulesButton = _G.CreateFrame("Button", nil, searchFrame)
	searchFrame.modulesButton:SetSize(31, 31)
	searchFrame.modulesButton:RegisterForClicks("anyUp")
	searchFrame.modulesButton:SetHighlightTexture(136477) --"Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
	searchFrame.modulesButton:SetPoint("TOPLEFT", searchFrame, "TOPLEFT", 0, 0)
	searchFrame.modulesButton:SetScript("OnClick", function() if BSYC.bgsMinimapDD then ToggleDropDownMenu(1, nil, BSYC.bgsMinimapDD, 'cursor', 0, 0) end end)

	local modulesButtonOverlay = searchFrame.modulesButton:CreateTexture(nil, "OVERLAY")
	local modulesButtonBG = searchFrame.modulesButton:CreateTexture(nil, "BACKGROUND")
	local modulesButtonIcon = searchFrame.modulesButton:CreateTexture(nil, "ARTWORK")

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

	searchFrame:Hide() --important
end

function Search:OnShow()
	BSYC:SetBSYC_FrameLevel(Search)
	Data:PopulateItemCache() --do a background caching of items
	BSYC.advUnitList = nil

	if not BSYC.options.alwaysShowAdvSearch then
		C_Timer.After(0.5, function()
			if BSYC.options.focusSearchEditBox then
				Search.frame.SearchBox:ClearFocus()
				Search.frame.SearchBox:SetFocus()
			end
		end)
	else
		Search:ShowAdvanced(true)
	end
    Search:RefreshList()
end

function Search:OnHide()
	Search.warningFrame:Hide()
	Search.helpFrame:Hide()
	BSYC.advUnitList = nil
	Search:ShowAdvanced(false)
end

function Search:ShowAdvanced(visible)
	if BSYC:GetModule("AdvancedSearch", true) then
		local frame = BSYC:GetModule("AdvancedSearch", true).frame
		if frame then
			if visible == nil then
				frame:SetShown(not frame:IsShown())
			elseif visible == true then
				frame:Show()
			else
				frame:Hide()
			end
		end
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

function Search:DoSearch(searchStr, advUnitList, advAllowList, isAdvancedSearch, warnCount)

	--only check for specifics when not using advanced search
	if not isAdvancedSearch then
		if not searchStr then searchStr = Search.frame.SearchBox:GetText() end
		if string.len(searchStr) <= 0 then return end
	end

	Search.items = {}
	local checkList = {}
	local warnTotal = 0
	local atUserLoc

	--make sure to always be using updated information, especially if processing items from Advanced Frame
	Tooltip:ResetLastLink()

	BSYC.advUnitList = advUnitList

	--items aren't counted into this array, it's just for allowing the search to pass through
	local allowList = {
		bag = true,
		bank = true,
		reagents = true,
		equip = true,
		mailbox = true,
		void = true,
		auction = true,
		warband = true,
	}

	--This is used when a player is requesting to view a custom list, such as @bank, @auction, @bag etc...
	if not isAdvancedSearch and string.len(searchStr) > 1 then
		atUserLoc = searchStr:match("@(.+)")
		--check it to verify it's a valid command
		if atUserLoc and (string.len(atUserLoc) < 1 or (atUserLoc ~= "guild" and not allowList[atUserLoc])) then atUserLoc = nil end
	end

	--overwrite the allowlist with the advance one if it isn't empty
	allowList = advAllowList or allowList
	Debug(BSYC_DL.INFO, "init:DoSearch", searchStr, atUserLoc, advUnitList, advAllowList, isAdvancedSearch, warnCount)

	local warbandObj = Data:GetWarbandBankObj()

	if not atUserLoc then
		for unitObj in Data:IterateUnits(false, advUnitList) do
			if not unitObj.isGuild then
				for k, v in pairs(allowList) do
					warnTotal = warnTotal + Search:CheckItems(searchStr, unitObj, k, checkList)
				end
			else
				--only do guild if we aren't using a custom adllowlist, otherwise it will always show up regardless of what custom field is selected
				--obviously guilds can't have stuff stored in AH, Mailbox, Void, etc...
				if not advAllowList then
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
			if playerObj.data.guild and not advAllowList then
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
			BSYC:StartTimer("SearchCacheChk", 0.5, Search, "DoSearch", searchStr, advUnitList, advAllowList, isAdvancedSearch, warnCount)
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
		button.parentHandler = Search

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
			if BSYC.GMF() == button then
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
	Search.items = {}
	Search:RefreshList()
end

function Search:ClearList()
	BSYC.advUnitList = nil
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
	if BSYC:GetModule("Details", true) then
		local item = btn:GetParent()
		if item and item.data then
			BSYC:GetModule("Details"):ShowItem(item.data.parseLink, item.data.entry)
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
		--reset the last cache link when using the advanced search to prevent improper listings from being cached
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
		--reset the last cache link when using the advanced search to prevent improper listings from being cached
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
		GameTooltip:AddLine("|cFFCF9FFF"..item.data.entry.."|r")
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
		button.parentHandler = Search

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

	if BSYC:GetModule("AdvancedSearch", true) and BSYC:GetModule("AdvancedSearch").frame:IsVisible() then
		frame = BSYC:GetModule("AdvancedSearch").frame
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
	local isAdvanced = false

	if BSYC:GetModule("AdvancedSearch", true) and BSYC:GetModule("AdvancedSearch").frame:IsVisible() then
		frame = BSYC:GetModule("AdvancedSearch").frame
		isAdvanced = true
	end

	frame.SearchBox.SearchInfo:Hide()
	frame.SearchBox:SetText(btn.data.value)

	if isAdvanced then
		BSYC:GetModule("AdvancedSearch"):DoSearch()
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
