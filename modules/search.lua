--[[
	search.lua
		A search frame for BagSync items

		BagSync - All Rights Reserved - (c) 2006-2023
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Search = BSYC:NewModule("Search", 'AceTimer-3.0')
local Unit = BSYC:GetModule("Unit")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Search", ...) end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local AceGUI = LibStub("AceGUI-3.0")
local ItemScout = LibStub("LibItemScout-1.0")

Search.cacheItems = {}
Search.warningAutoScan = 0

function Search:OnEnable()

	--lets create our widgets
	local SearchFrame = AceGUI:Create("Window")
	_G["BagSyncSearchFrame"] = SearchFrame
    --Add to special frames so window can be closed when the escape key is pressed.
    tinsert(UISpecialFrames, "BagSyncSearchFrame")
	Search.frame = SearchFrame
	Search.parentFrame = SearchFrame.frame

	SearchFrame:SetTitle("BagSync - "..L.Search)
	SearchFrame:SetHeight(500)
	SearchFrame:SetWidth(380)
	SearchFrame:EnableResize(false)

	local w = AceGUI:Create("SimpleGroup")
	w:SetLayout("Flow")
	w:SetFullWidth(true)
	SearchFrame:AddChild(w)

	local searchbar = AceGUI:Create("EditBox")
	searchbar:SetText()
	searchbar:SetWidth(255)
	searchbar:SetCallback("OnEnterPressed",function(widget)
		searchbar:ClearFocus()
		self:DoSearch(searchbar:GetText())
	end)

	Search.searchbar = searchbar
	w:AddChild(searchbar)

	local refreshbutton = AceGUI:Create("Button")
	refreshbutton:SetText(L.Refresh)
	refreshbutton:SetWidth(80)
	refreshbutton:SetHeight(20)
	refreshbutton:SetCallback("OnClick", function()
		searchbar:ClearFocus()
		local sbText = searchbar:GetText() or ''
		self:DoSearch((string.len(sbText) > 0 and sbText) or Search.searchStr)
	end)
	Search.refreshbutton = refreshbutton
	w:AddChild(refreshbutton)

	local helpButton = AceGUI:Create("Button")
	helpButton:SetText("?")
	helpButton:SetWidth(20)
	helpButton:SetHeight(20)
	helpButton:SetCallback("OnClick", function()
		if Search.helpframe:IsVisible() then
			Search.helpframe:Hide()
		else
			Search.helpframe:Show()
		end
	end)
	Search.helpButton = helpButton
	w:AddChild(helpButton)

	local scrollframe = AceGUI:Create("ScrollFrame")
	scrollframe:SetFullWidth(true)
	scrollframe:SetLayout("Flow")

	Search.scrollframe = scrollframe
	SearchFrame:AddChild(scrollframe)

	local totalCountLabel = AceGUI:Create("BagSyncLabel")

	totalCountLabel:SetText(L.TooltipTotal.." |cFFFFFFFF0|r")
	totalCountLabel:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	totalCountLabel:SetColor(1, 165/255, 0)
	totalCountLabel:SetFullWidth(true)

	totalCountLabel:ClearAllPoints()
	totalCountLabel.frame:SetParent(SearchFrame.frame)
	totalCountLabel:SetPoint("LEFT", SearchFrame.frame, "BOTTOMLEFT", 15, 25)
	totalCountLabel.frame:Show()
	Search.totalCountLabel = totalCountLabel

	SearchFrame:SetCallback("OnShow", function()
		if not BSYC.options.alwaysShowAdvSearch then
			self:ScheduleTimer(function()
				if BSYC.options.focusSearchEditBox then
					searchbar:ClearFocus()
					searchbar:SetFocus()
				end
			end, 0.5)
		else
			if self.advancedsearchframe then self.advancedsearchframe:Show() end
		end
	end)


	----------------------------------------------------------
	----------------------------------------------------------
	-------  SUMMARY FRAME

	local SummaryFrame = AceGUI:Create("Window")
	Search.summaryframe = SummaryFrame

	SummaryFrame:SetTitle("BagSync - "..L.Search)
	SummaryFrame:SetHeight(530)
	SummaryFrame:SetWidth(630)
	SummaryFrame.frame:SetParent(SearchFrame.frame)
	SummaryFrame.frame:SetFrameStrata("TOOLTIP")
	SummaryFrame:EnableResize(false)

	local sumFrameScroll = AceGUI:Create("ScrollFrame")
	sumFrameScroll:SetFullWidth(true)
	sumFrameScroll:SetHeight(450)
	sumFrameScroll:SetLayout("Flow")
	SummaryFrame.scrollframe = sumFrameScroll
	SummaryFrame:AddChild(sumFrameScroll)

	for i=1, 50 do
		local buttonGroup = AceGUI:Create("InlineGroup")
		buttonGroup:SetLayout("Flow")
		buttonGroup:SetFullWidth(true)
		buttonGroup:SetTitle("Poop-Famfrit")

		local label = AceGUI:Create("BagSyncInteractiveLabel")
		label.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		label.highlight:SetVertexColor(0,1,0,0.3)
		label:SetColor( 1, 1, 1)
		label:SetImage("Interface\\RaidFrame\\ReadyCheck-NotReady")
		label:SetImageSize(18, 18)
		label:SetWidth(380)
		label:SetText(("Bottomless Stonecrust Ore Satchel of the Monkey"):sub(1,45))
		label:ApplyJustifyH("LEFT")
		label:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
		label.label:SetWordWrap(false)
		buttonGroup:AddChild(label)

		local itemLoc = AceGUI:Create("BagSyncLabel")
		itemLoc:SetWidth(170)
		itemLoc.label:SetWordWrap(false)
		itemLoc:SetText(("Guild Banksdfsdfjsdfsdfsdfsd"):sub(1,20))
		itemLoc:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
		buttonGroup:AddChild(itemLoc)

		sumFrameScroll:AddChild(buttonGroup)
	end

	local sumCountLabel = AceGUI:Create("BagSyncLabel")
	sumCountLabel:SetText(L.TooltipTotal.." |cFFFFFFFF0|r")
	sumCountLabel:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	sumCountLabel:SetColor(1, 165/255, 0)
	sumCountLabel:SetFullWidth(true)

	sumCountLabel:ClearAllPoints()
	sumCountLabel.frame:SetParent(SummaryFrame.frame)
	sumCountLabel:SetPoint("LEFT", SummaryFrame.frame, "BOTTOMLEFT", 15, 25)
	sumCountLabel.frame:Show()
	SummaryFrame.sumCountLabel = sumCountLabel

	hooksecurefunc(SummaryFrame, "Show" ,function()
		--always show the warning frame on the right of the BagSync Search window
		SummaryFrame.frame:ClearAllPoints()
		SummaryFrame:SetPoint( "CENTER", UIParent, "CENTER", 0, 0)
	end)

	SummaryFrame:Hide()
	----------------------------------------------------------
	----------------------------------------------------------
	-------  WARNING FRAME

	local WarningFrame = AceGUI:Create("Window")
	WarningFrame:SetTitle(L.WarningHeader)
	WarningFrame:SetWidth(300)
	WarningFrame:SetHeight(280)
	WarningFrame.frame:SetParent(SearchFrame.frame)
	WarningFrame:SetLayout("Flow")
	WarningFrame:EnableResize(false)

	local warninglabel = AceGUI:Create("BagSyncLabel")
	warninglabel:SetText(L.WarningItemSearch)
	warninglabel:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
	warninglabel:SetColor(1, 165/255, 0) --orange, red is just too much sometimes
	warninglabel:SetFullWidth(true)
	WarningFrame:AddChild(warninglabel)

	local warninglabel2 = AceGUI:Create("BagSyncLabel")
	warninglabel2:SetText(L.ObsoleteWarning)
	warninglabel2:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
	warninglabel2:SetColor(50/255, 165/255, 0)
	warninglabel2:SetFullWidth(true)
	WarningFrame:AddChild(warninglabel2)

	Search.warningframe = WarningFrame
	Search.warninglabel = warninglabel

	hooksecurefunc(WarningFrame, "Show" ,function()
		--always show the warning frame on the right of the BagSync Search window
		WarningFrame.frame:ClearAllPoints()
		WarningFrame:SetPoint( "TOPLEFT", SearchFrame.frame, "TOPRIGHT", 0, 0)
	end)

	WarningFrame:Hide()

	----------------------------------------------------------
	----------------------------------------------------------
	-------  HELP FRAME

	local HelpFrame = AceGUI:Create("Window")
	HelpFrame:SetTitle(L.SearchHelpHeader)
	HelpFrame:SetWidth(500)
	HelpFrame:SetHeight(280)
	HelpFrame.frame:SetParent(SearchFrame.frame)
	HelpFrame:SetLayout("Flow")
	HelpFrame:EnableResize(false)

	local helpbox = AceGUI:Create("MultiLineEditBox")
	helpbox:SetWidth(470)
	helpbox:SetNumLines(15)
	helpbox:SetDisabled(true) --prevent editing
	helpbox.editBox:SetTextColor(1, 1, 1) --set default to white
	helpbox.button:Hide()
	helpbox.frame:SetClipsChildren(true)
	helpbox:SetLabel(L.ConfigSearch)
	helpbox:SetText(L.SearchHelp)
    helpbox:ClearFocus()
	HelpFrame:AddChild(helpbox)

	Search.helpframe = HelpFrame
	Search.helpbox = helpbox

	hooksecurefunc(HelpFrame, "Show" ,function()
		--always show the warning frame on the right of the BagSync Search window
		WarningFrame:Hide()
		HelpFrame.frame:ClearAllPoints()
		HelpFrame:SetPoint( "TOPLEFT", SearchFrame.frame, "TOPRIGHT", 0, 0)
	end)

	HelpFrame:Hide()

	----------------------------------------------------------
	----------------------------------------------------------
	-------  ADVANCED SEARCH

	--Button
	local spacer = AceGUI:Create("BagSyncLabel")
	spacer:SetFullWidth(true)
	spacer:SetText(" ")
	SearchFrame:AddChild(spacer)

	local advSearchBtn = AceGUI:Create("Button")
	advSearchBtn:SetText(L.AdvancedSearch)
	advSearchBtn:SetHeight(20)
	advSearchBtn:SetWidth(150)

	advSearchBtn:ClearAllPoints()
	advSearchBtn.frame:SetParent(SearchFrame.frame)
	advSearchBtn:SetPoint("CENTER", SearchFrame.frame, "BOTTOM", 105, 25)
	advSearchBtn.frame:Show()

	SearchFrame.advsearchbtn = advSearchBtn

	local searchResetBtn = AceGUI:Create("Button")
	searchResetBtn:SetText(L.Reset)
	searchResetBtn:SetHeight(20)
	searchResetBtn:SetAutoWidth(true)

	searchResetBtn:ClearAllPoints()
	searchResetBtn.frame:SetParent(SearchFrame.frame)
	searchResetBtn:SetPoint("RIGHT", advSearchBtn.frame, "LEFT", 0, 0)
	searchResetBtn.frame:Show()

	SearchFrame.searchResetBtn = searchResetBtn

	searchResetBtn:SetCallback("OnClick", function()
		Search:DoReset()
	end)
	--------------------

	local AdvancedSearchFrame = AceGUI:Create("Window")
	AdvancedSearchFrame:SetTitle(L.AdvancedSearch)
	AdvancedSearchFrame:SetHeight(550)
	AdvancedSearchFrame:SetWidth(380)
	AdvancedSearchFrame.frame:SetParent(SearchFrame.frame)
	AdvancedSearchFrame.frame:SetFrameStrata("DIALOG")
	AdvancedSearchFrame:EnableResize(false)

	Search.advancedsearchframe = AdvancedSearchFrame

	local advSearchInformation = AceGUI:Create("BagSyncLabel")
	advSearchInformation:SetText(L.AdvancedSearchInformation)
	advSearchInformation:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	advSearchInformation:SetColor(1, 165/255, 0)
	advSearchInformation:SetFullWidth(true)
	AdvancedSearchFrame:AddChild(advSearchInformation)

	local advSearchbar = AceGUI:Create("EditBox")
	advSearchbar:SetText()
	advSearchbar:SetWidth(255)
	advSearchbar:SetCallback("OnEnterPressed",function(widget)
		advSearchbar:ClearFocus()
		Search:DoAdvancedSearch()
	end)
	AdvancedSearchFrame.advsearchbar = advSearchbar
	AdvancedSearchFrame:AddChild(advSearchbar)

	hooksecurefunc(AdvancedSearchFrame, "Show" ,function()
		--always show the advanced search on the left of the BagSync Search window
		AdvancedSearchFrame.frame:ClearAllPoints()
		AdvancedSearchFrame:SetPoint( "TOPRIGHT", SearchFrame.frame, "TOPLEFT", 0, 0)
	end)

	advSearchBtn:SetCallback("OnClick", function()
		if AdvancedSearchFrame.frame:IsVisible() then
			AdvancedSearchFrame:Hide()
		else
			AdvancedSearchFrame:Show()
		end
	end)

	--player list
	local spacer = AceGUI:Create("BagSyncLabel")
    spacer:SetFullWidth(true)
	spacer:SetText(" ")
	AdvancedSearchFrame:AddChild(spacer)

	local pListInfo = AceGUI:Create("BagSyncLabel")
	pListInfo:SetText(L.Units)
	pListInfo:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	pListInfo:SetColor(0, 1, 0)
	pListInfo:SetFullWidth(true)
	AdvancedSearchFrame:AddChild(pListInfo)

	local advSelectAllBtn = AceGUI:Create("Button")
	advSelectAllBtn:SetText(L.SelectAll)
	advSelectAllBtn:SetHeight(16)
	advSelectAllBtn:SetAutoWidth(true)
	advSelectAllBtn:SetCallback("OnClick", function()
		Search:DisplayAdvSearchSelectAll()
	end)
	AdvancedSearchFrame.advSelectAllBtn = advSelectAllBtn

	advSelectAllBtn.frame:SetParent(AdvancedSearchFrame.frame)
	advSelectAllBtn:ClearAllPoints()
	advSelectAllBtn:SetPoint("RIGHT", pListInfo.frame, "RIGHT", -20, 5)
	advSelectAllBtn.frame:Show()

	local playerListScrollFrame = AceGUI:Create("ScrollFrame")
	playerListScrollFrame:SetFullWidth(true)
	playerListScrollFrame:SetLayout("Flow")
	playerListScrollFrame:SetHeight(240)

	AdvancedSearchFrame.playerlistscrollframe = playerListScrollFrame
	AdvancedSearchFrame:AddChild(playerListScrollFrame)

 	--location list (bank, bags, etc..)
	local spacer = AceGUI:Create("BagSyncLabel")
    spacer:SetFullWidth(true)
	spacer:SetText(" ")
	AdvancedSearchFrame:AddChild(spacer)

	local locListInfo = AceGUI:Create("BagSyncLabel")
	locListInfo:SetText(L.Locations)
	locListInfo:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	locListInfo:SetColor(0, 1, 0)
	locListInfo:SetFullWidth(true)
	AdvancedSearchFrame:AddChild(locListInfo)

	local advLocationInformation = AceGUI:Create("BagSyncLabel")
	advLocationInformation:SetText(L.AdvancedLocationInformation)
	advLocationInformation:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	advLocationInformation:SetColor(1, 165/255, 0)
	advLocationInformation:SetFullWidth(true)
	AdvancedSearchFrame:AddChild(advLocationInformation)

	local locationListScrollFrame = AceGUI:Create("ScrollFrame")
	locationListScrollFrame:SetFullWidth(true)
	locationListScrollFrame:SetLayout("Flow")
	locationListScrollFrame:SetHeight(140)

	AdvancedSearchFrame.locationlistscrollframe = locationListScrollFrame
	AdvancedSearchFrame:AddChild(locationListScrollFrame)

 	hooksecurefunc(AdvancedSearchFrame, "Show" ,function()
		self:DisplayAdvSearchLists()
	end)

	local spacer = AceGUI:Create("BagSyncLabel")
    spacer:SetFullWidth(true)
	spacer:SetText(" ")
	AdvancedSearchFrame:AddChild(spacer)

	local advDoSearchBtn = AceGUI:Create("Button")
	advDoSearchBtn:SetText(L.AdvSearchBtn)
	advDoSearchBtn:SetHeight(20)
	advDoSearchBtn:SetWidth(150)
	advDoSearchBtn:SetCallback("OnClick", function()
		Search:DoAdvancedSearch()
	end)
	AdvancedSearchFrame:AddChild(advDoSearchBtn)
	AdvancedSearchFrame.advdosearchbtn = advDoSearchBtn

	local advDoResetBtn = AceGUI:Create("Button")
	advDoResetBtn:SetText(L.Reset)
	advDoResetBtn:SetHeight(20)
	advDoResetBtn:SetWidth(150)
	advDoResetBtn:SetCallback("OnClick", function()
		--just refresh the list to empty it
		Search:DisplayAdvSearchLists()
	end)
	AdvancedSearchFrame:AddChild(advDoResetBtn)
	AdvancedSearchFrame.advdoresetbtn = advDoResetBtn

	advDoResetBtn:ClearAllPoints()
	advDoResetBtn:SetPoint("LEFT", advDoSearchBtn.frame, "LEFT", 210, 0)

	AdvancedSearchFrame:SetCallback("OnShow",function(widget)
		Search.searchbar.frame:Hide()
		Search.refreshbutton.frame:Hide()

		self:ScheduleTimer(function()
			if BSYC.options.focusSearchEditBox then
				advSearchbar:ClearFocus()
				advSearchbar:SetFocus()
			end
		end, 0.5)
	end)
	AdvancedSearchFrame:SetCallback("OnClose",function(widget)
		Search.searchbar.frame:Show()
		Search.refreshbutton.frame:Show()
	end)

	AdvancedSearchFrame:Hide()

	----------------------------------------------------------
	----------------------------------------------------------

	SearchFrame:SetCallback("OnClose",function(widget)
		WarningFrame:Hide()
		HelpFrame:Hide()
		AdvancedSearchFrame:Hide()
		Search.warningAutoScan = 0
	end)

	SearchFrame:Hide()
end

function Search:StartSearch(searchStr)
	self.frame:Show()

	if not BSYC.options.alwaysShowAdvSearch then
		self.searchbar:SetText(searchStr)
		self:DoSearch(searchStr)
	else
		self.advancedsearchframe.advsearchbar:SetText(searchStr)
	end
end

function Search:AddEntry(entry)

	local highlightColor = {1, 0, 0}
	local label = AceGUI:Create("BagSyncInteractiveLabel")

	local name, link, rarity, texture, isBattlePet = entry.name, entry.link, entry.rarity, entry.texture, entry.isBattlepet
	local r, g, b, hex = GetItemQualityColor(rarity)

	--if its a battlepet and we don't have access to BattlePetTooltip, then don't display it
	if isBattlePet and not BattlePetTooltip then return end
	label.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	label.highlight:SetVertexColor(0,1,0,0.3)
	label:SetColor( r, g, b)
	label:SetImage(texture)
	label:SetImageSize(18, 18)
	label:SetText(name)
	label:ApplyJustifyH("LEFT")
	label:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
	label:SetFullWidth(true)
	label:SetCallback("OnClick", function (widget, sometable, button)
		if IsControlKeyDown() then
			if not isBattlePet then
				ChatEdit_InsertLink(link)
			end
		elseif IsShiftKeyDown() then
			--do something
		end
	end)
	label:SetCallback("OnEnter", function (widget, sometable)
		label:SetColor(unpack(highlightColor))
		if not isBattlePet then
			GameTooltip:SetOwner(label.frame, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:SetHyperlink(link)
			GameTooltip:Show()
		else
			GameTooltip:SetOwner(label.frame, "ANCHOR_BOTTOMRIGHT")
			BattlePetToolTip_Show(tonumber(qOpts.battlepet), 0, 0, 0, 0, 0, nil)
		end
	end)
	label:SetCallback("OnLeave", function (widget, sometable)
		label:SetColor(r, g, b)
		GameTooltip:Hide()
		if not isBattlePet then
			GameTooltip:Hide()
		else
			BattlePetTooltip:Hide()
		end
	end)

	self.scrollframe:AddChild(label)
end

function Search:AdvancedSearchAddEntry(entry, isHeader, isUnit)

	local label = AceGUI:Create("BagSyncInteractiveLabel")

	label:SetHeaderHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")

	label:ToggleHeaderHighlight(false)
	label.entry = entry
	label:SetColor(1, 1, 1)

	if isHeader then
		label:SetText(entry.unitObj.realm)
		label:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
		label:SetFullWidth(true)
		label:ApplyJustifyH("CENTER")
		label:ToggleHeaderHighlight(true)
		label.userdata.isHeader = true
	else
		if entry.unitObj.isGuild then
			label:SetText(GUILD..":  "..entry.colorized)
		else
			label:SetText(entry.colorized)
		end
		label:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
		label:SetFullWidth(true)
		label:ApplyJustifyH("LEFT")
		label.userdata.isHeader = false

		label:SetImage("Interface\\RaidFrame\\ReadyCheck-NotReady")
		label.isSelected = false
	end

	label:SetCallback("OnClick", function (widget, sometable, button)
		if label.isSelected then
			label:SetImage("Interface\\RaidFrame\\ReadyCheck-NotReady")
			label.isSelected = false
		else
			label.isSelected = true
			label:SetImage("Interface\\RaidFrame\\ReadyCheck-Ready")
		end
	end)
	label:SetCallback("OnEnter", function (widget, sometable)
		if not label.userdata.isHeader then
			--override the single tooltip use of BagSync
			label.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
			label.highlight:SetVertexColor(0,1,0,0.3)
		end
	end)
	label:SetCallback("OnLeave", function (widget, sometable)
		--override the single tooltip use of BagSync
		label.highlight:SetTexture(nil)
	end)

	if isUnit then
		self.advancedsearchframe.playerlistscrollframe:AddChild(label)
	else
		self.advancedsearchframe.locationlistscrollframe:AddChild(label)
	end
end

function Search:DoReset()
	Search.searchStr = nil
	Search.advUnitList = nil
	self.advancedsearchframe.advsearchbar:SetText(nil)
	self.searchbar:SetText(nil)
	self.totalCountLabel:SetText(L.TooltipTotal.." |cFFFFFFFF0|r")
	self.scrollframe:ReleaseChildren()
	self.scrollframe.frame:Hide()
end

function Search:DisplayAdvSearchSelectAll()
	for i = 1, #self.advancedsearchframe.playerlistscrollframe.children do
		local label = self.advancedsearchframe.playerlistscrollframe.children[i] --grab the label
		if label and not label.userdata.isHeader then
			label.isSelected = true
			label:SetImage("Interface\\RaidFrame\\ReadyCheck-Ready")
		end
	end
end

function Search:DoAdvancedSearch()
	Debug(BSYC_DL.INFO, "init:DoAdvancedSearch", Search.searchStr, advUnitList, advAllowList)

	local advUnitList = {}
	local unitCount = 0

	--units
	for i = 1, #self.advancedsearchframe.playerlistscrollframe.children do
		local label = self.advancedsearchframe.playerlistscrollframe.children[i] --grab the label
		local unitObj = label.entry.unitObj

		--if it's not a headler and it's selected in the list
		if not label.userdata.isHeader and label.isSelected then
			--order of operations for filters -> realm -> name -> realmKey
			if not advUnitList[unitObj.realm] then advUnitList[unitObj.realm] = {} end
			advUnitList[unitObj.realm][unitObj.name] = {realmKey=unitObj.data.realmKey}
			unitCount = unitCount + 1
		end
	end
	if unitCount < 1 then advUnitList = nil end

	local advAllowList = {}
	local locCount = 0

	--locations
	for i = 1, #self.advancedsearchframe.locationlistscrollframe.children do
		local label = self.advancedsearchframe.locationlistscrollframe.children[i] --grab the label
		if label.isSelected then
			advAllowList[label.entry.unitObj.name] = true
			locCount = locCount + 1
		end
	end
	if locCount < 1 then advAllowList = nil end

	--global for tooltip checks
	Search.advUnitList = advUnitList

	--we are doing an advanced search
	local advsbText = self.advancedsearchframe.advsearchbar:GetText() or ''
	local searchStr = (string.len(advsbText) > 0 and advsbText) or Search.searchStr

	--send it off to the regular search
	self:DoSearch(searchStr, advUnitList, advAllowList)
end

function Search:CacheLink(dbEntry, parseLink, qOpts)
	local itemObj = {}
	if not Data.__cache.items[parseLink] then
		if qOpts.battlepet then
			itemObj.itemQuality = 1
			itemObj.itemLink = dbEntry --use the whole link, not just the FakeID, this is to grab qOpts in future uses

			--https://wowpedia.fandom.com/wiki/API_C_PetJournal.GetPetInfoBySpeciesID
			itemObj.speciesName,
			itemObj.speciesIcon,
			itemObj.petType,
			itemObj.companionID,
			itemObj.tooltipSource,
			itemObj.tooltipDescription,
			itemObj.isWild,
			itemObj.canBattle,
			itemObj.isTradeable,
			itemObj.isUnique,
			itemObj.obtainable,
			itemObj.creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(qOpts.battlepet)
		else
			--https://wowpedia.fandom.com/wiki/API_GetItemInfo
			itemObj.itemName,
			itemObj.itemLink,
			itemObj.itemQuality,
			itemObj.itemLevel,
			itemObj.itemMinLevel,
			itemObj.itemType,
			itemObj.itemSubType,
			itemObj.itemStackCount,
			itemObj.itemEquipLoc,
			itemObj.itemTexture,
			itemObj.sellPrice,
			itemObj.classID,
			itemObj.subclassID,
			itemObj.bindType,
			itemObj.expacID,
			itemObj.setID,
			itemObj.isCraftingReagent = GetItemInfo("item:"..parseLink)
		end
		--add to Cache if we have something to work with
		if itemObj.speciesName or itemObj.itemName then
			Data.__cache.items[parseLink] = itemObj
		end
	else
		itemObj = Data.__cache.items[parseLink]
	end
	return itemObj
end

function Search:CheckItem(searchStr, unitObj, target, searchList, checkList, onlyPlayer)
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
					local cacheObj = Search:CacheLink(data[i], link, qOpts)
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
							table.insert(searchList, { name=itemName, link=cacheObj.itemLink, rarity=cacheObj.itemQuality, texture=texture, isBattlePet=qOpts.battlepet } )
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

	local sbText = self.searchbar:GetText() or ''
	Search.advUnitList = advUnitList

	searchStr = searchStr or (string.len(sbText) > 0 and sbText) or Search.searchStr
	if not searchStr or string.len(searchStr) < 1 then return end

	self.searchbar:SetText(nil) --reset always, we only want to use searchStr
	searchStr = searchStr:lower() --always make sure everything is lowercase when doing searches
	Search.searchStr = searchStr --store globally for the refresh
	self.scrollframe:ReleaseChildren() --clear out the scrollframe

	local searchList = {}
	local checkList = {}
	local countWarning = 0
	local atUserLoc

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
					countWarning = countWarning + self:CheckItem(searchStr, unitObj, k, searchList, checkList)
				end
			else
				Debug(BSYC_DL.FINE, "Search-IterateUnits", "guild", unitObj.name, unitObj.realm)
				countWarning = countWarning + self:CheckItem(searchStr, unitObj, "guild", searchList, checkList)
			end
		end
	else
		--player using an @location, so lets only search their database and not IterateUnits
		local playerObj = Data:GetCurrentPlayer()
		Debug(BSYC_DL.FINE, "Search-atUserLoc", "player", playerObj.name, playerObj.realm, atUserLoc)

		if atUserLoc ~= "guild" then
			Debug(BSYC_DL.FINE, atUserLoc)
			countWarning = countWarning + self:CheckItem(searchStr, playerObj, atUserLoc, searchList, checkList, true)
		else
			if playerObj.data.guild then
				local guildObj = Data:GetGuild(playerObj.data)
				if guildObj then
					Debug(BSYC_DL.FINE, "guild")
					countWarning = countWarning + self:CheckItem(searchStr, guildObj, atUserLoc, searchList, checkList, true)
				end
			end
		end
	end

	--show warning window if the server hasn't queried all the items yet
	if countWarning > 0 then
		self.warninglabel:SetText(L.WarningItemSearch:format(countWarning))

		if not advUnitList then
			self.searchbar:SetText(searchStr) --set for the refresh button
		else
			self.advancedsearchframe.advsearchbar:SetText(searchStr) --set for the refresh button
		end

		self.warningframe:Show()

		--lets not do TOO many refreshes
		if Search.warningAutoScan <= 5 then
			C_Timer.After(0.5, function()
				self.searchbar:ClearFocus()
				local sbText = self.searchbar:GetText() or ''
				self:DoSearch((string.len(sbText) > 0 and sbText) or Search.searchStr)
			end)
			Search.warningAutoScan = Search.warningAutoScan + 1
		end

	else
		self.warningframe:Hide()
	end

	if #searchList > 0 then
		table.sort(searchList, function(a,b) return (a.name < b.name) end)
		for i=1, #searchList do
			self:AddEntry(searchList[i])
		end
		self.scrollframe.frame:Show()
		self.totalCountLabel:SetText(L.TooltipTotal.." |cFFFFFFFF"..tostring(#searchList).."|r")
	else
		self.totalCountLabel:SetText(L.TooltipTotal.." |cFFFFFFFF0|r")
		self.scrollframe.frame:Hide()
	end

end

function Search:DisplayAdvSearchLists()

	self.scrollframe:ReleaseChildren() --clear out the main search scroll frame
	self.advancedsearchframe.playerlistscrollframe:ReleaseChildren() --clear out the scrollframe
	self.advancedsearchframe.locationlistscrollframe:ReleaseChildren() --clear out the scrollframe

	local playerListTable = {}

	--show simple for ColorizeUnit
	for unitObj in Data:IterateUnits(true) do
		table.insert(playerListTable, { unitObj=unitObj, colorized=Tooltip:ColorizeUnit(unitObj, false, false, true) } )
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
				self:AdvancedSearchAddEntry(playerListTable[i], true, true) --add header
				self:AdvancedSearchAddEntry(playerListTable[i], false, true) --add entry
				lastHeader = playerListTable[i].unitObj.realm
			else
				self:AdvancedSearchAddEntry(playerListTable[i], false, true) --add entry
			end
		end
		self.advancedsearchframe.playerlistscrollframe.frame:Show()
	else
		self.advancedsearchframe.playerlistscrollframe.frame:Hide()
	end

	--locations
	local list = {
		[1] = { source="bag", 		desc=L.Tooltip_bag },
		[2] = { source="bank", 		desc=L.Tooltip_bank },
		[3] = { source="reagents", 	desc=L.Tooltip_reagents },
		[4] = { source="equip", 	desc=L.Tooltip_equip },
		[5] = { source="mailbox", 	desc=L.Tooltip_mailbox },
		[6] = { source="void", 		desc=L.Tooltip_void },
		[7] = { source="auction", 	desc=L.Tooltip_auction },
	}

	for i = 1, #list do

		--make sure to return not player
		local tmpLoc = {
			unitObj={name=list[i].source, isGuild=false, isConnectedRealm=false},
			colorized=Tooltip:HexColor(BSYC.options.colors.first, list[i].desc)
		}

		self:AdvancedSearchAddEntry(tmpLoc, false, false) --add entry

	end

	self.totalCountLabel:SetText(L.TooltipTotal.." |cFFFFFFFF0|r")

	self.advancedsearchframe.locationlistscrollframe.frame:Show()
end