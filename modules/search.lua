--[[
	search.lua
		A search frame for BagSync items
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Search = BSYC:NewModule("Search")
local Unit = BSYC:GetModule("Unit")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
local function Debug(...)
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", "Search")
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local AceGUI = LibStub("AceGUI-3.0")
local itemScanner = LibStub('LibItemSearch-1.2')

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
	w:AddChild(refreshbutton)

	local scrollframe = AceGUI:Create("ScrollFrame");
	scrollframe:SetFullWidth(true)
	scrollframe:SetLayout("Flow")

	Search.scrollframe = scrollframe
	SearchFrame:AddChild(scrollframe)

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

	local warninglabel = AceGUI:Create("Label")
	warninglabel:SetText(L.WarningItemSearch)
	warninglabel:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
	warninglabel:SetColor(1, 165/255, 0) --orange, red is just too much sometimes
	warninglabel:SetFullWidth(true)
	WarningFrame:AddChild(warninglabel)

	local warninglabel2 = AceGUI:Create("Label")
	warninglabel2:SetText(L.ObsoleteWarning)
	warninglabel2:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
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
	local spacer = AceGUI:Create("Label")
    spacer:SetFullWidth(true)
	spacer:SetText(" ")
	SearchFrame:AddChild(spacer)

	local advSearchBtn = AceGUI:Create("Button")
	advSearchBtn:SetText(L.AdvancedSearch)
	advSearchBtn:SetHeight(20)
	
	SearchFrame:AddChild(advSearchBtn)
	advSearchBtn:ClearAllPoints()
	advSearchBtn:SetPoint("CENTER", SearchFrame.frame, "BOTTOM", 0, 25)
	
	--------------------
	
	local AdvancedSearchFrame = AceGUI:Create("Window")
	AdvancedSearchFrame:SetTitle(L.AdvancedSearch)
	AdvancedSearchFrame:SetHeight(530)
	AdvancedSearchFrame:SetWidth(380)
	AdvancedSearchFrame.frame:SetParent(SearchFrame.frame)
	AdvancedSearchFrame:EnableResize(false)
	
	Search.advancedsearchframe = AdvancedSearchFrame
	
	local advSearchInformation = AceGUI:Create("Label")
	advSearchInformation:SetText(L.AdvancedSearchInformation)
	advSearchInformation:SetFont(STANDARD_TEXT_FONT, 12, THICKOUTLINE)
	advSearchInformation:SetColor(1, 165/255, 0)
	advSearchInformation:SetFullWidth(true)
	AdvancedSearchFrame:AddChild(advSearchInformation)
	
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
		AdvancedSearchFrame:Show()
	end)
	
	--player list
	local spacer = AceGUI:Create("Label")
    spacer:SetFullWidth(true)
	spacer:SetText(" ")
	AdvancedSearchFrame:AddChild(spacer)
	
	local pListInfo = AceGUI:Create("Label")
	pListInfo:SetText(L.Units)
	pListInfo:SetFont(STANDARD_TEXT_FONT, 12, THICKOUTLINE)
	pListInfo:SetColor(0, 1, 0)
	pListInfo:SetFullWidth(true)
	AdvancedSearchFrame:AddChild(pListInfo)
	
	local playerListScrollFrame = AceGUI:Create("ScrollFrame");
	playerListScrollFrame:SetFullWidth(true)
	playerListScrollFrame:SetLayout("Flow")
	playerListScrollFrame:SetHeight(240)

	AdvancedSearchFrame.playerlistscrollframe = playerListScrollFrame
	AdvancedSearchFrame:AddChild(playerListScrollFrame)

 	--location list (bank, bags, etc..)
	local spacer = AceGUI:Create("Label")
    spacer:SetFullWidth(true)
	spacer:SetText(" ")
	AdvancedSearchFrame:AddChild(spacer)
	
	local locListInfo = AceGUI:Create("Label")
	locListInfo:SetText(L.Locations)
	locListInfo:SetFont(STANDARD_TEXT_FONT, 12, THICKOUTLINE)
	locListInfo:SetColor(0, 1, 0)
	locListInfo:SetFullWidth(true)
	AdvancedSearchFrame:AddChild(locListInfo)
	
	local locationListScrollFrame = AceGUI:Create("ScrollFrame");
	locationListScrollFrame:SetFullWidth(true)
	locationListScrollFrame:SetLayout("Flow")
	locationListScrollFrame:SetHeight(150)

	AdvancedSearchFrame.locationlistscrollframe = locationListScrollFrame
	AdvancedSearchFrame:AddChild(locationListScrollFrame)

 	hooksecurefunc(AdvancedSearchFrame, "Show" ,function()
		self:DisplayAdvSearchLists()
	end)
  
	local spacer = AceGUI:Create("Label")
    spacer:SetFullWidth(true)
	spacer:SetText(" ")
	AdvancedSearchFrame:AddChild(spacer)
	
	local spacer = AceGUI:Create("Label")
    spacer:SetFullWidth(true)
	spacer:SetText(" ")
	AdvancedSearchFrame:AddChild(spacer)
	
	local advDoSearchBtn = AceGUI:Create("Button")
	advDoSearchBtn:SetText(L.Search)
	advDoSearchBtn:SetHeight(20)
	advDoSearchBtn:SetWidth(150)
	advDoSearchBtn:SetCallback("OnClick", function()
		Search:DoAdvancedSearch()
	end)
	AdvancedSearchFrame:AddChild(advDoSearchBtn)
	
	local advDoResetBtn = AceGUI:Create("Button")
	advDoResetBtn:SetText(L.Reset)
	advDoResetBtn:SetHeight(20)
	advDoResetBtn:SetWidth(150)
	advDoResetBtn:SetCallback("OnClick", function()
		--just refresh the list to empty it
		Search:DisplayAdvSearchLists()
	end)
	AdvancedSearchFrame:AddChild(advDoResetBtn)
	
	advDoResetBtn:ClearAllPoints()
	advDoResetBtn:SetPoint("LEFT", advDoSearchBtn.frame, "LEFT", 210, 0)
	
	AdvancedSearchFrame:Hide()
	
	----------------------------------------------------------
	----------------------------------------------------------
	
	SearchFrame:Hide()
end

function Search:StartSearch(searchStr)
	self.frame:Show()
	self.searchbar:SetText(searchStr)
	self:DoSearch(searchStr)
end

function Search:AddEntry(entry)

	local highlightColor = {1, 0, 0}
	local label = AceGUI:Create("InteractiveLabel")

	local name, link, rarity, texture = entry.name, entry.link, entry.rarity, entry.texture
	local r, g, b, hex = GetItemQualityColor(rarity)
	local isBattlePet = false
	
	local _, _, identifier, optOne = strsplit(";", link)
	if identifier and tonumber(identifier) == 2 and optOne then
		isBattlePet = true
	end
	
	--if we aren't retail then just don't add the item to the list if we have a battle pet
	if isBattlePet and not BSYC.IsRetail then return end
	
	label.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	label.highlight:SetVertexColor(0,1,0,0.3)
				
	label:SetText(name)
	label:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
	label:SetFullWidth(true)
	label:SetColor( r, g, b)
	label:SetImage(texture)
	label:SetImageSize(18, 18)
	label:SetCallback(
		"OnClick", 
		function (widget, sometable, button)
			if not isBattlePet then
				ChatEdit_InsertLink(link)
			else
				FloatingBattlePet_Toggle(tonumber(optOne), 0, 0, 0, 0, 0, nil, nil)
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
				BattlePetToolTip_Show(tonumber(optOne), 0, 0, 0, 0, 0, nil)
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
		label:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
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
		label:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
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

local function checkData(data, searchStr, searchTable, tempList, countWarning, viewCustomList)
	for i=1, table.getn(data) do
		if data[i] then
			local link, count, identifier, optOne = strsplit(";", data[i])
			
			if link then
				local dName, dItemLink, dRarity, dTexture
				local testMatch = false
				
				--if identifier is 2 then it's a battlepet, optOne would be speciesID
				if identifier and tonumber(identifier) == 2 and optOne then
					dName, dTexture = C_PetJournal.GetPetInfoBySpeciesID(optOne)
					dRarity = 1
					dItemLink = data[i]
					testMatch = LibStub('CustomSearch-1.0'):Find(searchStr, dName)
				else
					dName, dItemLink, dRarity, _, _, _, _, _, _, dTexture = GetItemInfo("item:"..link)
					testMatch = itemScanner:Matches(dItemLink, searchStr)
				end
				
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

function Search:DoAdvancedSearch()
	
	--units
	for i = 1, #self.advancedsearchframe.playerlistscrollframe.children do
		local label = self.advancedsearchframe.playerlistscrollframe.children[i] --grab the label
		
		if not label.userdata.isHeader then
		
			if not label.entry.unitObj.isGuild then
				--print(label.entry.colorized)
			end
			
		end
	end
	
	--locations
	for i = 1, #self.advancedsearchframe.locationlistscrollframe.children do
		local label = self.advancedsearchframe.locationlistscrollframe.children[i] --grab the label
		print(label.entry.colorized)
	end
			
end

function Search:DoSearch(searchStr)
	if not searchStr then return end
	local searchStr = searchStr or self.searchbar:GetText()
	searchStr = searchStr:lower() --always make sure everything is lowercase when doing searches
	if string.len(searchStr) < 1 then return end
	
	self.searchbar:SetText(nil) --reset to make searching faster
	
	self.scrollframe:ReleaseChildren() --clear out the scrollframe
	
	local searchTable = {}
	local tempList = {}
	local countWarning = 0
	local viewCustomList
	local player = Unit:GetUnitInfo()

	local allowList = {
		["bag"] = 0,
		["bank"] = 0,
		["reagents"] = 0,
		["equip"] = 0,
		["mailbox"] = 0,
		["void"] = 0,
		["auction"] = 0,
		["guild"] = 0,
	}
	
	--This is used when a player is requesting to view a custom list, such as @bank, @auction, @bag etc...
	if string.len(searchStr) > 1 and string.find(searchStr, "@") and allowList[string.sub(searchStr, 2)] ~= nil then viewCustomList = string.sub(searchStr, 2) end
	
	for unitObj in Data:IterateUnits() do
	
		if not unitObj.isGuild then
			for k, v in pairs(unitObj.data) do
				if allowList[k] and type(v) == "table" then
					--bags, bank, reagents are stored in individual bags
					if k == "bag" or k == "bank" or k == "reagents" then
						for bagID, bagData in pairs(v) do
							if not viewCustomList or viewCustomList == k and unitObj.name == player.name and unitObj.realm == player.realm then
								countWarning = checkData(bagData, searchStr, searchTable, tempList, countWarning, viewCustomList)
							end
						end
					else
						local passChk = true
						if k == "auction" and not BSYC.options.enableAuction then passChk = false end
						if k == "mailbox" and not BSYC.options.enableMailbox then passChk = false end
						
						if passChk then
							if not viewCustomList or viewCustomList == k and unitObj.name == player.name and unitObj.realm == player.realm then
								countWarning = checkData(k == "auction" and v.bag or v, searchStr, searchTable, tempList, countWarning, viewCustomList)
							end
						end
					end
				end
			end
		else
			if not viewCustomList or viewCustomList == "guild" and unitObj.name == player.guild and unitObj.data.realmKey == player.realmKey then
				countWarning = checkData(unitObj.data.bag, searchStr, searchTable, tempList, countWarning, viewCustomList)
			end
		end

	end

	--show warning window if the server hasn't queried all the items yet
	if countWarning > 0 then
		self.warninglabel:SetText(L.WarningItemSearch:format(countWarning))
		self.searchbar:SetText(searchStr) --set for the refresh button
		self.warningframe:Show()
	else
		self.warningframe:Hide()
	end
		
	if table.getn(searchTable) > 0 then
		table.sort(searchTable, function(a,b) return (a.name < b.name) end)
		for i=1, #searchTable do
			self:AddEntry(searchTable[i])
		end
		self.scrollframe.frame:Show()
	else
		self.scrollframe.frame:Hide()
	end
		
end

function Search:DisplayAdvSearchLists()

	self.advancedsearchframe.playerlistscrollframe:ReleaseChildren() --clear out the scrollframe
	self.advancedsearchframe.locationlistscrollframe:ReleaseChildren() --clear out the scrollframe

	local playerListTable = {}
	local tempList = {}
	
	--show simple for ColorizeUnit
	for unitObj in Data:IterateUnits(true) do
		table.insert(playerListTable, { unitObj=unitObj, colorized=Tooltip:ColorizeUnit(unitObj, false, false, true) } )
	end
	
	--units
	if table.getn(playerListTable) > 0 then
	
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
		[1] = { source="bag", 		desc=L.TooltipBag },
		[2] = { source="bank", 		desc=L.TooltipBank },
		[3] = { source="reagents", 	desc=L.TooltipReagent },
		[4] = { source="equip", 	desc=L.TooltipEquip },
		[5] = { source="guild", 	desc=L.TooltipGuild },
		[6] = { source="mailbox", 	desc=L.TooltipMail },
		[7] = { source="void", 		desc=L.TooltipVoid },
		[8] = { source="auction", 	desc=L.TooltipAuction },
	}
	
	for i = 1, #list do
		
		local stripColon = strsub(list[i].desc, 0, string.len(list[i].desc) - 1) --remove colon at end
		
		--make sure to return not player
		local tmpLoc = {
			unitObj={name=list[i].source, isGuild=false, isConnectedRealm=false},
			colorized=Tooltip:HexColor(BSYC.options.colors.first, stripColon)
		}
		
		self:AdvancedSearchAddEntry(tmpLoc, false, false) --add entry

	end
	self.advancedsearchframe.locationlistscrollframe.frame:Show()
	

end