local L = LibStub("AceLocale-3.0"):GetLocale("BagSync", true)
local testTable = {}
local rows, anchor = {}
local currentRealm = select(2, UnitFullName("player"))
local GetItemInfo = _G["GetItemInfo"]
local currentPlayer = UnitName("player")

local AceGUI = LibStub("AceGUI-3.0")
local customSearch = LibStub('CustomSearch-1.0')
local ItemSearch = LibStub("LibItemSearch-1.2")

local frame = AceGUI:Create("Frame")

frame:SetTitle("Example Frame")
frame:SetStatusText("AceGUI-3.0 Example Container Frame")

local scrollframe = AceGUI:Create("ScrollFrame");
scrollframe:SetFullWidth(true)
scrollframe:SetLayout("List")

frame:AddChild(scrollframe)

--:ReleaseChildren()

--[[ local itemTexture = select(10, GetItemInfo(71354))
 
local myILabel

for i = 1, 50 do
	myILabel = AceGUI:Create("InteractiveLabel")
	--myILabel:SetText("20")
	myILabel:SetWidth(48)
	myILabel:SetHeight(48)
	myILabel:SetImage(itemTexture)
	myILabel:SetImageSize(48,48)
	myILabel:SetText("lala")
	scrollframe:AddChild(myILabel)
end ]]
		
		
local function addEntry(entry, counter)

	local color = {0.7, 0.7, 0.7}
	local highlightColor = {1, 0, 0}
	local label = AceGUI:Create("InteractiveLabel")

	local name, link, rarity = entry.name, entry.link, entry.rarity

	label:SetText(name)
	label:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
	label:SetFullWidth(true)
	label:SetColor(unpack(color))
	label:SetCallback(
		"OnClick", 
		function (widget, sometable, button)
			if "LeftButton" == button then
				print("left")
			elseif "RightButton" == button then
				print("right")
			end
		end)
	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			label:SetColor(unpack(highlightColor))
		end)
	label:SetCallback(
		"OnLeave",
		function (widget, sometable)
			label:SetColor(unpack(color))
		end)

	scrollframe:AddChild(label)
	
end

local function DoSearch()
	if not BagSync or not BagSyncDB then return end
	local searchStr = "red"
	
	searchStr = searchStr:lower()
	
	local tempList = {}
	local previousGuilds = {}
	local count = 0
	local playerSearch = false
	local countWarning = 0
	
	if strlen(searchStr) > 0 then
		
		scrollframe:ReleaseChildren() --clear out the scrollframe
		
		local playerFaction = UnitFactionGroup("player")
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
		
		local xDB = BagSync:getFilteredDB()
		
		--loop through our characters
		--k = player, v = stored data for player
		for k, v in pairs(xDB) do

			local pFaction = v.faction or playerFaction --just in case ;) if we dont know the faction yet display it anyways
			local yName, yRealm  = strsplit("^", k)
			
			--check if we should show both factions or not
			if BagSyncOpt.enableFaction or pFaction == playerFaction then

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
										local dName, dItemLink, dRarity = GetItemInfo(dblink)
										if dName then
											--are we checking in our bank,void, etc?
											if playerSearch and string.sub(searchStr, 2) == q and string.sub(searchStr, 2) ~= "guild" and yName == currentPlayer and not tempList[dblink] then
												addEntry({ name=dName, link=dItemLink, rarity=dRarity }, count)
												tempList[dblink] = dName
												count = count + 1
											--we found a match
											elseif not playerSearch and not tempList[dblink] and ItemSearch:Matches(dItemLink, searchStr) then
												addEntry({ name=dName, link=dItemLink, rarity=dRarity }, count)
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
				
				if BagSyncOpt.enableGuild then
					local guildN = v.guild or nil

					--check the guild bank if the character is in a guild
					if BagSyncGUILD_DB and guildN and BagSyncGUILD_DB[v.realm][guildN] then
						--check to see if this guild has already been done through this run (so we don't do it multiple times)
						--check for XR/B.Net support
						local gName = BagSync:getGuildRealmInfo(guildN, v.realm)
					
						if not previousGuilds[gName] then
							--we only really need to see this information once per guild
							for q, r in pairs(BagSyncGUILD_DB[v.realm][guildN]) do
								local dblink, dbcount = strsplit(",", r)
								if dblink then
									local dName, dItemLink, dRarity = GetItemInfo(dblink)
									if dName then
										if playerSearch and string.sub(searchStr, 2) == "guild" and GetGuildInfo("player") and guildN == GetGuildInfo("player") and not tempList[dblink] then
											addEntry({ name=dName, link=dItemLink, rarity=dRarity }, count)
											tempList[dblink] = dName
											count = count + 1
										--we found a match
										elseif not playerSearch and not tempList[dblink] and ItemSearch:Matches(dItemLink, searchStr) then
											addEntry({ name=dName, link=dItemLink, rarity=dRarity }, count)
											tempList[dblink] = dName
											count = count + 1
										end
									else
										countWarning = countWarning + 1
									end
								end
							end
							previousGuilds[gName] = true
						end
					end
				end
				
			end
			
		end
		print("countWarning: ".. countWarning)
		--table.sort(searchTable, function(a,b) return (a.name < b.name) end)
	end
	
end
	

local OKbutton = AceGUI:Create("Button")
OKbutton:SetText("Search")
OKbutton:SetCallback("OnClick", function()
      DoSearch()
   end
)
frame:AddChild(OKbutton)

--lets create the warning frame.

local warning = AceGUI:Create("Frame")
--f.statusbg:Hide() 
--f:SetWidth(400) f:SetHeight(320)

frame:Show()

--[[ scrollcontainer = AceGUI:Create("SimpleGroup") -- "InlineGroup" is also good
scrollcontainer:SetFullWidth(true)
scrollcontainer:SetFullHeight(true) -- probably?
scrollcontainer:SetLayout("Fill") -- important!

topContainer:AddChild(scrollcontainer)

scroll = AceGUI:Create("ScrollFrame")
scroll:SetLayout("Flow") -- probably?
scrollcontainer:AddChild(scroll) ]]

--[[ 		scrollframe = AceGUI:Create("ScrollFrame");
		scrollframe:SetLayout("Flow");
		scrollframe:SetFullHeight(true);
		scrollframe:SetWidth(80);

		LMMainFrame_Loot_BottomLeftCntr:AddChild(scrollframe);
		
		local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(71354);
	
		for i = 1, 5 do
			myILabel = AceGUI:Create("InteractiveLabel");
			--myILabel:SetText("20");
			myILabel:SetWidth(48);
			myILabel:SetHeight(48);
			myILabel:SetImage(itemTexture);
			myILabel:SetImageSize(48,48);
			scrollframe:AddChild(myILabel);
		end
 ]]

 