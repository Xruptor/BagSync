--[[
	search.lua
		A search frame for BagSync items
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
local itemScanner = LibStub("ItemSearch-1.3")
local customSearch = LibStub("CustomSearch-1.0")

function Search:OnEnable()

	--lets create our widgets
	local SearchFrame = AceGUI:Create("Window")
	_G["BagSyncSearchFrame"] = SearchFrame
    --Add to special frames so window can be closed when the escape key is pressed.
    tinsert(UISpecialFrames, "BagSyncSearchFrame")
	Search.frame = SearchFrame

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
	refreshbutton:SetWidth(100)
	refreshbutton:SetHeight(20)
	refreshbutton:SetCallback("OnClick", function()
		searchbar:ClearFocus()
		self:DoSearch(searchbar:GetText())
	end)
	Search.refreshbutton = refreshbutton
	w:AddChild(refreshbutton)

	local scrollframe = AceGUI:Create("ScrollFrame");
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
	totalCountLabel:SetPoint("CENTER", SearchFrame.frame, "BOTTOM", -75, 25)
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

	--hide the warning window if they close the search window
	SearchFrame:SetCallback("OnClose",function(widget)
		WarningFrame:Hide()
	end)

	WarningFrame:Hide()

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

	--hide the advanced search if they close the search window
	SearchFrame:SetCallback("OnClose",function(widget)
		AdvancedSearchFrame:Hide()
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

	local playerListScrollFrame = AceGUI:Create("ScrollFrame");
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

	local locationListScrollFrame = AceGUI:Create("ScrollFrame");
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

	local name, link, rarity, texture = entry.name, entry.link, entry.rarity, entry.texture
	local r, g, b, hex = GetItemQualityColor(rarity)
	local isBattlePet = false

	local _, _, qOpts = BSYC:Split(link)
	if qOpts and qOpts.battlepet then isBattlePet = true end

	--if its a battlepet and we don't have access to BattlePetTooltip, then don't display it
	if isBattlePet and not BattlePetTooltip then return end
	label.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	label.highlight:SetVertexColor(0,1,0,0.3)
	label:SetColor( r, g, b)
	label:SetImage(texture)
	label:SetImageSize(18, 18)
	label:SetFullWidth(true)
	label:SetText(name)
	label:ApplyJustifyH("LEFT")
	label:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
	label:SetFullWidth(true)
	label:SetCallback(
		"OnClick",
		function (widget, sometable, button)
			if not isBattlePet then
				ChatEdit_InsertLink(link)
			else
				FloatingBattlePet_Toggle(tonumber(qOpts.battlepet), 0, 0, 0, 0, 0, nil, nil)
			end
		end)
	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
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
	label:SetCallback(
		"OnLeave",
		function (widget, sometable)
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

	label:SetCallback(
		"OnClick",
		function (widget, sometable, button)
			if label.isSelected then
				label:SetImage("Interface\\RaidFrame\\ReadyCheck-NotReady")
				label.isSelected = false
			else
				label.isSelected = true
				label:SetImage("Interface\\RaidFrame\\ReadyCheck-Ready")
			end
		end)
	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			if not label.userdata.isHeader then
				--override the single tooltip use of BagSync
				label.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
				label.highlight:SetVertexColor(0,1,0,0.3)
			end
		end)
	label:SetCallback(
		"OnLeave",
		function (widget, sometable)
			--override the single tooltip use of BagSync
			label.highlight:SetTexture(nil)
		end)

	if isUnit then
		self.advancedsearchframe.playerlistscrollframe:AddChild(label)
	else
		self.advancedsearchframe.locationlistscrollframe:AddChild(label)
	end
end

local function checkData(data, searchStr, searchTable, tempList, countWarning, viewCustomList, unitObj)

	for i=1, #data do
		if data[i] then
			local link, count, qOpts = BSYC:Split(data[i])

			if link then
				local dName, dItemLink, dRarity, dTexture
				local testMatch = false

				--qOpts.battlepet would be speciesID
				if qOpts and qOpts.battlepet then
					dName, dTexture = C_PetJournal.GetPetInfoBySpeciesID(qOpts.battlepet)
					dRarity = 1
					dItemLink = data[i]
					testMatch = customSearch:Find(searchStr or '', dName) --searchStr cannot be nil
				else
					dName, dItemLink, dRarity, _, _, _, _, _, _, dTexture = GetItemInfo("item:"..link)
					testMatch = itemScanner:Matches(dItemLink, searchStr)
				end

				--for debugging purposes only
				if dName and (viewCustomList or testMatch) then
					Debug(6, "FoundItem", searchStr, dName, unitObj.name, unitObj.realm)
				end

				--we only really want to grab the item once in our list, no need to add it multiple times per character
				if dName and not tempList[link] then
					if viewCustomList or testMatch then
						tempList[link] = dName
						table.insert(searchTable, { name=dName, link=dItemLink, rarity=dRarity, texture=dTexture } )
					end
				elseif not tempList[link] then
					--only show a warning if we haven't already processed that item
					countWarning = countWarning + 1
				end
			end
		end
	end
	return countWarning
end

function Search:DoReset()
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
	Debug(2, "init:DoAdvancedSearch", searchStr, advUnitList, advAllowList)

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
			advAllowList[label.entry.unitObj.name] = true --get the source name
			locCount = locCount + 1
		end
	end
	if locCount < 1 then advAllowList = nil end

	--global for tooltip checks
	self.advUnitList = advUnitList

	--send it off to the regular search
	self:DoSearch(nil, advUnitList, advAllowList)
end

function Search:DoSearch(searchStr, advUnitList, advAllowList)

	--only do if we aren't doing an advanced search
	if not advUnitList then
		Search.advUnitList = nil -- we aren't doing an advanced search so lets reset this
		if not searchStr then return end
		if string.len(searchStr) < 1 then return end
		searchStr = searchStr or self.searchbar:GetText()
	else
		searchStr = searchStr or self.advancedsearchframe.advsearchbar:GetText()
		self.advancedsearchframe.advsearchbar:SetText(nil) --reset always, we only want to use searchStr
	end

	self.searchbar:SetText(nil) --reset always, we only want to use searchStr
	searchStr = searchStr:lower() --always make sure everything is lowercase when doing searches
	self.scrollframe:ReleaseChildren() --clear out the scrollframe

	local searchTable = {}
	local tempList = {}
	local countWarning = 0
	local viewCustomList
	local player = Unit:GetUnitInfo()

	--items aren't counted into this array, it's just for allowing the search to pass through
	local allowList = {
		["bag"] = true,
		["bank"] = true,
		["reagents"] = true,
		["equip"] = true,
		["mailbox"] = true,
		["void"] = true,
		["auction"] = true,
	}

	--This is used when a player is requesting to view a custom list, such as @bank, @auction, @bag etc...
	--only do if we aren't using an advance search
	if not advUnitList and string.len(searchStr) > 1 and string.find(searchStr, "@") and allowList[string.sub(searchStr, 2)] ~= nil then
		viewCustomList = string.sub(searchStr, 2)
	end

	--overwrite the allowlist with the advance one if it isn't empty
	allowList = advAllowList or allowList

	Debug(2, "init:DoSearch", searchStr, advUnitList, advAllowList)

	--advUnitList will force dumpAll to be true if necessary for advanced search, no need to set it to true
	for unitObj in Data:IterateUnits(false, advUnitList) do

		if not unitObj.isGuild then
			Debug(5, "Search-IterateUnits", "player", unitObj.name, player.realm)
			for k, v in pairs(unitObj.data) do
				if allowList[k] and type(v) == "table" then
					Debug(5, k)
					--bags, bank, reagents are stored in individual bags
					if k == "bag" or k == "bank" or k == "reagents" then
						for bagID, bagData in pairs(v) do
							if not viewCustomList or (viewCustomList == k and unitObj.name == player.name and unitObj.realm == player.realm) then
								countWarning = checkData(bagData, searchStr, searchTable, tempList, countWarning, viewCustomList, unitObj)
							end
						end
					else
						local passChk = true
						if k == "auction" and not BSYC.options.enableAuction then passChk = false end
						if k == "mailbox" and not BSYC.options.enableMailbox then passChk = false end

						if passChk then
							if not viewCustomList or (viewCustomList == k and unitObj.name == player.name and unitObj.realm == player.realm) then
								countWarning = checkData(k == "auction" and v.bag or v, searchStr, searchTable, tempList, countWarning, viewCustomList, unitObj)
							end
						end
					end
				end
			end
		else
			Debug(5, "Search-IterateUnits", "guild", unitObj.name, player.realm, unitObj.data.realmKey)
			if not advUnitList then
				if not viewCustomList or (viewCustomList == "guild" and unitObj.name == player.guild and unitObj.realm == player.guildrealm) then
					countWarning = checkData(unitObj.data.bag, searchStr, searchTable, tempList, countWarning, viewCustomList, unitObj)
				end
			else
				countWarning = checkData(unitObj.data.bag, searchStr, searchTable, tempList, countWarning, viewCustomList, unitObj)
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
	else
		self.warningframe:Hide()
	end

	if #searchTable > 0 then
		table.sort(searchTable, function(a,b) return (a.name < b.name) end)
		for i=1, #searchTable do
			self:AddEntry(searchTable[i])
		end
		self.scrollframe.frame:Show()
		self.totalCountLabel:SetText(L.TooltipTotal.." |cFFFFFFFF"..tostring(#searchTable).."|r")
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
	local tempList = {}

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