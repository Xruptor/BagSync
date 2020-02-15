--[[
	search.lua
		A search frame for BagSync items
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Search = BSYC:NewModule("Search")
local Unit = BSYC:GetModule("Unit")
local Data = BSYC:GetModule("Data")

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

	local warningframe = AceGUI:Create("Window")
	warningframe:SetTitle(L.WarningHeader)
	warningframe:SetWidth(300)
	warningframe:SetHeight(280)
	warningframe.frame:SetParent(SearchFrame.frame)
	warningframe:SetLayout("Flow")
	warningframe:EnableResize(false)

	local warninglabel = AceGUI:Create("Label")
	warninglabel:SetText(L.WarningItemSearch)
	warninglabel:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
	warninglabel:SetColor(1, 165/255, 0) --orange, red is just too much sometimes
	warninglabel:SetFullWidth(true)
	warningframe:AddChild(warninglabel)

	local warninglabel2 = AceGUI:Create("Label")
	warninglabel2:SetText(L.ObsoleteWarning)
	warninglabel2:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
	warninglabel2:SetColor(50/255, 165/255, 0)
	warninglabel2:SetFullWidth(true)
	warningframe:AddChild(warninglabel2)
	
	Search.warningframe = warningframe
	Search.warninglabel = warninglabel
	
	hooksecurefunc(warningframe, "Show" ,function()
		--always show the warning frame on the right of the BagSync window
		warningframe.frame:ClearAllPoints()
		warningframe:SetPoint( "TOPLEFT", SearchFrame.frame, "TOPRIGHT", 0, 0)
	end)
	
	--hide the warning window if they close the search window
	SearchFrame:SetCallback("OnClose",function(widget)
		warningframe:Hide()
	end)
	
	warningframe:Hide()
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

local function checkData(data, searchStr, searchTable, tempList, countWarning, playerSearch)
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
					if playerSearch or testMatch then
						tempList[link] = dName
						table.insert(searchTable, { name=dName, link=dItemLink, rarity=dRarity, texture=dTexture } )
					end					
				else
					countWarning = countWarning + 1
				end
			end
		end
	end
	return countWarning
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
	local playerSearch
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
	
	if string.len(searchStr) > 1 and string.find(searchStr, "@") and allowList[string.sub(searchStr, 2)] ~= nil then playerSearch = string.sub(searchStr, 2) end
	
	for unitObj in Data:IterateUnits() do
	
		if not unitObj.isGuild then
			for k, v in pairs(unitObj.data) do
				if allowList[k] and type(v) == "table" then
					--bags, bank, reagents are stored in individual bags
					if k == "bag" or k == "bank" or k == "reagents" then
						for bagID, bagData in pairs(v) do
							if not playerSearch or playerSearch == k and unitObj.name == player.name and unitObj.realm == player.realm then
								countWarning = checkData(bagData, searchStr, searchTable, tempList, countWarning, playerSearch)
							end
						end
					else
						local passChk = true
						if k == "auction" and not BSYC.options.enableAuction then passChk = false end
						if k == "mailbox" and not BSYC.options.enableMailbox then passChk = false end
						
						if passChk then
							if not playerSearch or playerSearch == k and unitObj.name == player.name and unitObj.realm == player.realm then
								countWarning = checkData(k == "auction" and v.bag or v, searchStr, searchTable, tempList, countWarning, playerSearch)
							end
						end
					end
				end
			end
		else
			if not playerSearch or playerSearch == "guild" and unitObj.name == player.guild and unitObj.data.realmKey == player.realmKey then
				countWarning = checkData(unitObj.data.bag, searchStr, searchTable, tempList, countWarning, playerSearch)
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