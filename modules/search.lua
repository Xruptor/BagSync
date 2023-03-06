--[[
	search.lua
		A search frame for BagSync items

		BagSync - All Rights Reserved - (c) 2006-2023
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Search = BSYC:NewModule("Search")
local Data = BSYC:GetModule("Data")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Search", ...) end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local ItemScout = LibStub("LibItemScout-1.0")

Search.cacheItems = {}
Search.warningAutoScan = 0

function Search:OnEnable()
    local searchFrame = _G.CreateFrame("Frame", nil, UIParent, "BagSyncFrameTemplate")
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
    searchFrame:SetScript("OnShow", function() Search:OnShow() end)
	searchFrame:SetScript("OnHide", function() Search:OnHide() end)
    Search.frame = searchFrame

    Search.scrollFrame = _G.CreateFrame("ScrollFrame", nil, searchFrame, "HybridScrollFrameTemplate")
    Search.scrollFrame:SetWidth(365)
    Search.scrollFrame:SetPoint("TOPLEFT", searchFrame, "TOPLEFT", 6, -60)
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
	searchFrame.advSearchBtn:SetPoint("RIGHT", searchFrame, "BOTTOMRIGHT", -10, 20)
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
    warningFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	warningFrame:ClearAllPoints()
	warningFrame:SetPoint("TOPLEFT", searchFrame, "TOPRIGHT", 5, 0)
	warningFrame.TitleText:SetText(L.WarningHeader)
	warningFrame.TitleText:SetFont(STANDARD_TEXT_FONT, 14, "")
	warningFrame.TitleText:SetTextColor(1, 1, 1)
	warningFrame.InfoText1:SetText(L.WarningItemSearch)
	warningFrame.InfoText1:SetFont(STANDARD_TEXT_FONT, 14, "")
	warningFrame.InfoText1:SetPoint("LEFT", warningFrame, "TOPLEFT", 5, -90)
	warningFrame.InfoText1:SetTextColor(1, 165/255, 0) --orange, red is just too much sometimes
	warningFrame.InfoText1:SetJustifyH("CENTER")
	warningFrame.InfoText1:SetWidth(warningFrame:GetWidth() - 15)
	warningFrame.InfoText2:SetText(L.ObsoleteWarning)
	warningFrame.InfoText2:SetFont(STANDARD_TEXT_FONT, 14, "")
	warningFrame.InfoText2:SetPoint("LEFT", warningFrame.InfoText1, "BOTTOMLEFT", 5, -40)
	warningFrame.InfoText2:SetTextColor(50/255, 165/255, 0) --orange, red is just too much sometimes
	warningFrame.InfoText2:SetJustifyH("CENTER")
	warningFrame.InfoText2:SetWidth(warningFrame:GetWidth() - 15)
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
    helpFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	helpFrame:ClearAllPoints()
	helpFrame:SetPoint("TOPLEFT", searchFrame, "TOPRIGHT", 5, 0)
	helpFrame.TitleText:SetText(L.SearchHelpHeader)
	helpFrame.TitleText:SetFont(STANDARD_TEXT_FONT, 14, "")
	helpFrame.TitleText:SetTextColor(1, 1, 1)
	helpFrame.InfoText1:Hide()
	helpFrame.InfoText2:Hide()
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

	searchFrame:Hide() --important
end

function Search:OnShow()
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

	HybridScrollFrame_CreateButtons(Search.scrollFrame, "BagSyncListItemTemplate")
    Search:RefreshList()
end

function Search:OnHide()
	Search.warningFrame:Hide()
	Search.helpFrame:Hide()
	Search.warningAutoScan = 0
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

function Search:CheckItem(searchStr, unitObj, target, checkList, onlyPlayer)
	local total = 0
	if not unitObj or not target then return total end
	searchStr = searchStr or ''

	local function parseItems(data)
		local iCount = 0
		for i=1, #data do
			if data[i] then
				local link, count, qOpts = BSYC:Split(data[i])
				if BSYC.options.enableShowUniqueItemsTotals then link = BSYC:GetShortItemID(link) end

				--we only really want to grab and search the item only once
				if link and not checkList[link] then
					--do cache grab
					local cacheObj = Data:CacheLink(data[i], link, qOpts)
					local entry = cacheObj.speciesName or cacheObj.itemLink --GetItemInfo does not support battlepet links, use speciesName instead
					local texture = cacheObj.speciesIcon or cacheObj.itemTexture
					local itemName = cacheObj.speciesName or cacheObj.itemName

					--we only really want to grab and search the item only once
					if entry then
						--perform item search
						local testMatch = ItemScout:Find(entry, searchStr, cacheObj)

						--for debugging purposes only
						if entry and (testMatch or onlyPlayer) then
							Debug(BSYC_DL.SL1, "FoundItem", searchStr, entry, unitObj.name, unitObj.realm)
						end

						checkList[link] = entry
						if testMatch or onlyPlayer then
							table.insert(Search.items, { name=itemName, link=cacheObj.itemLink, rarity=cacheObj.itemQuality, icon=texture, speciesID=qOpts.battlepet } )
						end
					else
						--add to warning count total if we haven't processed that item
						iCount = iCount + 1
					end
				end
			end
		end
		return iCount
	end

	if target == "bag" or target == "bank" or target == "reagents" then
		for bagID, bagData in pairs(unitObj.data[target] or {}) do
			total = total + parseItems(bagData)
		end

	elseif target == "auction" and BSYC.options.enableAuction then
		total = parseItems((unitObj.data[target] and unitObj.data[target].bag) or {})

	elseif target == "mailbox" and BSYC.options.enableMailbox then
		total = parseItems(unitObj.data[target] or {})

	elseif target == "equip" or target == "void" then
		total = parseItems(unitObj.data[target] or {})

	elseif target == "guild" and BSYC.options.enableGuild then
		for tabID, tabData in pairs(unitObj.tabs or (unitObj.data and unitObj.data.tabs) or {}) do
			local tabCount = parseItems(tabData)
			total = total + tabCount
		end
	end

	return total
end

function Search:DoSearch(searchStr, advUnitList, advAllowList)

	--only check for specifics when not using advanced search
	if not advUnitList then
		if not searchStr then searchStr = Search.frame.SearchBox:GetText() end
		if string.len(searchStr) <= 0 then return end
	end

	Search.items = {}
	local checkList = {}
	local countWarning = 0
	local atUserLoc

	Search.advUnitList = advUnitList

	--items aren't counted into this array, it's just for allowing the search to pass through
	local allowList = {
		bag = true,
		bank = true,
		reagents = true,
		equip = true,
		mailbox = true,
		void = true,
		auction = true,
	}

	--This is used when a player is requesting to view a custom list, such as @bank, @auction, @bag etc...
	if not advUnitList and string.len(searchStr) > 1 then
		atUserLoc = searchStr:match("@(.+)")
		--check it to verify it's a valid command
		if atUserLoc and string.len(atUserLoc) > 0 and (atUserLoc ~= "guild" and not allowList[atUserLoc]) then atUserLoc = nil end
	end

	--overwrite the allowlist with the advance one if it isn't empty
	allowList = advAllowList or allowList
	Debug(BSYC_DL.INFO, "init:DoSearch", searchStr, advUnitList, advAllowList)

	if not atUserLoc then
		for unitObj in Data:IterateUnits(false, advUnitList) do
			if not unitObj.isGuild then
				Debug(BSYC_DL.FINE, "Search-IterateUnits", "player", unitObj.name, unitObj.realm)
				for k, v in pairs(allowList) do
					Debug(BSYC_DL.FINE, k)
					countWarning = countWarning + Search:CheckItem(searchStr, unitObj, k, checkList)
				end
			else
				Debug(BSYC_DL.FINE, "Search-IterateUnits", "guild", unitObj.name, unitObj.realm)
				countWarning = countWarning + Search:CheckItem(searchStr, unitObj, "guild", checkList)
			end
		end
	else
		--player using an @location, so lets only search their database and not IterateUnits
		local playerObj = Data:GetCurrentPlayer()
		Debug(BSYC_DL.FINE, "Search-atUserLoc", "player", playerObj.name, playerObj.realm, atUserLoc)

		if atUserLoc ~= "guild" then
			Debug(BSYC_DL.FINE, atUserLoc)
			countWarning = countWarning + Search:CheckItem(searchStr, playerObj, atUserLoc, checkList, true)
		else
			if playerObj.data.guild then
				local guildObj = Data:GetGuild(playerObj.data)
				if guildObj then
					Debug(BSYC_DL.FINE, "guild")
					countWarning = countWarning + Search:CheckItem(searchStr, guildObj, atUserLoc, checkList, true)
				end
			end
		end
	end

	--show warning window if the server hasn't queried all the items yet
	if countWarning > 0 then
		Search.warningFrame.InfoText1:SetText(L.WarningItemSearch:format(countWarning))
		Search.warningFrame:Show()

		--lets not do TOO many refreshes
		if Search.warningAutoScan <= 5 then
			C_Timer.After(0.5, function()
				Search:DoSearch(searchStr, advUnitList, advAllowList)
			end)
			Search.warningAutoScan = Search.warningAutoScan + 1
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
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
            button.Text:SetText(item.name or "")
			button.Text:SetTextColor(r, g, b)
            button:SetWidth(Search.scrollFrame.scrollChild:GetWidth())
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
	Search.advUnitList = nil
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
end

function Search:Item_OnClick(btn)
end

function Search:Item_OnEnter(btn)
    if btn.data then
		if not btn.data.speciesID then
			GameTooltip:SetOwner(btn, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:SetHyperlink(btn.data.link)
			GameTooltip:Show()
		else
			--BattlePetToolTip_Show uses the previous GameTooltip owner positioning
			GameTooltip:SetOwner(btn, "ANCHOR_BOTTOMRIGHT")
			BattlePetToolTip_Show(tonumber(btn.data.speciesID), 0, 0, 0, 0, 0, nil)
		end
	end
end

function Search:Item_OnLeave(btn)
	GameTooltip:Hide()
    if btn.data then
		if btn.data.speciesID then
			BattlePetTooltip:Hide()
		end
	end
end

function Search:SearchBox_OnEnterPressed(text)
	Search:DoSearch(text)
end