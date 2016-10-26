
local BSYC = select(2, ...) --grab the addon namespace
local Search = BSYC:NewModule("Search")

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync", true)
local AceGUI = LibStub("AceGUI-3.0")
local ItemSearch = LibStub('LibItemSearchGrid-1.0')

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
	warningframe:SetHeight(170)
	warningframe.frame:SetParent(SearchFrame.frame)
	warningframe:SetLayout("Flow")
	warningframe:EnableResize(false)

	local warninglabel = AceGUI:Create("Label")
	warninglabel:SetText(L.WarningItemSearch)
	warninglabel:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
	warninglabel:SetColor(1, 165/255, 0) --orange, red is just too much sometimes
	warninglabel:SetFullWidth(true)
	warningframe:AddChild(warninglabel)

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
	
	label:SetText(name)
	label:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
	label:SetFullWidth(true)
	label:SetColor( r, g, b)
	label:SetImage(texture)
	label:SetCallback(
		"OnClick", 
		function (widget, sometable, button)
			ChatEdit_InsertLink(link)
		end)
	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			label:SetColor(unpack(highlightColor))
			GameTooltip:SetOwner(label.frame, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:SetHyperlink(link)
			GameTooltip:Show()
		end)
	label:SetCallback(
		"OnLeave",
		function (widget, sometable)
			label:SetColor(r, g, b)
			GameTooltip:Hide()
		end)

	self.scrollframe:AddChild(label)
end

function Search:DoSearch(searchStr)
	local searchStr = searchStr or self.searchbar:GetText()
	searchStr = searchStr:lower() --always make sure everything is lowercase when doing searches

	local searchTable = {}
	local tempList = {}
	local previousGuilds = {}
	local previousGuildsXRList = {}
	local count = 0
	local playerSearch = false
	local countWarning = 0
	
	self.scrollframe:ReleaseChildren() --clear out the scrollframe
	
	if strlen(searchStr) > 0 then
		
		local allowList = {
			["bag"] = 0,
			["bank"] = 0,
			["equip"] = 0,
			["mailbox"] = 0,
			["void"] = 0,
			["auction"] = 0,
			["guild"] = 0,
			["reagentbank"] = 0,
		}
		
		if string.len(searchStr) > 1 and string.find(searchStr, "@") and allowList[string.sub(searchStr, 2)] ~= nil then playerSearch = true end
		
		local xDB = BSYC:FilterDB()
		
		--loop through our characters
		--k = player, v = stored data for player
		for k, v in pairs(xDB) do

			local pFaction = v.faction or BSYC.playerFaction --just in case ;) if we dont know the faction yet display it anyways
			local yName, yRealm  = strsplit("^", k)
			
			--check if we should show both factions or not
			if BSYC.options.enableFaction or pFaction == BSYC.playerFaction then

				--now count the stuff for the user
				--q = bag name, r = stored data for bag name
				for q, r in pairs(v) do
					--only loop through table items we want
					if allowList[q] and type(r) == "table" then
						--bagID = bag name bagID, bagInfo = data of specific bag with bagID
						for bagID, bagInfo in pairs(r) do
							--slotID = slotid for specific bagid, itemValue = data of specific slotid
							if type(bagInfo) == "table" then
								for slotID, itemValue in pairs(bagInfo) do
									local dblink, dbcount = strsplit(",", itemValue)
									if dblink then
										local dName, dItemLink, dRarity, _, _, _, _, _, _, dTexture = GetItemInfo("item:"..dblink)
										if dName then
											--are we checking in our bank,void, etc?
											if playerSearch and string.sub(searchStr, 2) == q and string.sub(searchStr, 2) ~= "guild" and yName == BSYC.currentPlayer and not tempList[dblink] then
												table.insert(searchTable, { name=dName, link=dItemLink, rarity=dRarity, texture=dTexture } )
												tempList[dblink] = dName
												count = count + 1
											--we found a match
											elseif not playerSearch and not tempList[dblink] and ItemSearch:Find(dItemLink, searchStr) then
												table.insert(searchTable, { name=dName, link=dItemLink, rarity=dRarity, texture=dTexture } )
												tempList[dblink] = dName
												count = count + 1
											end
										else
											countWarning = countWarning + 1
										end
									end
								end
							end
						end
					end
				end
				
				if BSYC.options.enableGuild then
					local guildN = v.guild or nil

					--check the guild bank if the character is in a guild
					if guildN and BSYC.db.guild[v.realm][guildN] then
						--check to see if this guild has already been done through this run (so we don't do it multiple times)
						--check for XR/B.Net support
						local gName = BSYC:GetRealmTags(guildN, v.realm, true)
					
						--check to make sure we didn't already add a guild from a connected-realm
						local trueRealmList = BSYC.db.realmkey[0][v.realm] --get the connected realms
						if trueRealmList then
							table.sort(trueRealmList, function(a,b) return (a < b) end) --sort them alphabetically
							trueRealmList = table.concat(trueRealmList, "|") --concat them together
						else
							trueRealmList = v.realm
						end
						trueRealmList = guildN.."-"..trueRealmList --add the guild name in front of concat realm list
					
						if not previousGuilds[gName] and not previousGuildsXRList[trueRealmList] then
							--we only really need to see this information once per guild
							for q, r in pairs(BSYC.db.guild[v.realm][guildN]) do
								local dblink, dbcount = strsplit(",", r)
								if dblink then
									local dName, dItemLink, dRarity, _, _, _, _, _, _, dTexture = GetItemInfo("item:"..dblink)
									if dName then
										if playerSearch and string.sub(searchStr, 2) == "guild" and BSYC.db.player.guild and guildN == BSYC.db.player.guild and not tempList[dblink] then
											table.insert(searchTable, { name=dName, link=dItemLink, rarity=dRarity, texture=dTexture } )
											tempList[dblink] = dName
											count = count + 1
										--we found a match
										elseif not playerSearch and not tempList[dblink] and ItemSearch:Find(dItemLink, searchStr) then
											table.insert(searchTable, { name=dName, link=dItemLink, rarity=dRarity, texture=dTexture } )
											tempList[dblink] = dName
											count = count + 1
										end
									else
										countWarning = countWarning + 1
									end
								end
							end
							previousGuilds[gName] = true
							previousGuildsXRList[trueRealmList] = true
						end
						
					end
				end
				
			end
			
		end
		
		--display the rows
		if count > 0 then
			table.sort(searchTable, function(a,b) return (a.name < b.name) end)
			for i=1, #searchTable do
				self:AddEntry(searchTable[i])
			end
		end
		
		--show warning window if the server hasn't queried all the items yet
		if countWarning > 0 then
			self.warninglabel:SetText(L.WarningItemSearch:format(countWarning))
			self.warningframe:Show()
		else
			self.warningframe:Hide()
		end

	end
	
	--show or hide the scrolling frame depending on count
	if strlen(searchStr) > 0 and count > 0 then
		self.scrollframe.frame:Show()
	else
		self.scrollframe.frame:Hide()
	end
	
end