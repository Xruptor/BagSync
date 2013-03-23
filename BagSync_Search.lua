local L = BAGSYNC_L
local searchTable = {}
local rows, anchor = {}
local currentRealm = GetRealmName()
local GetItemInfo = _G['GetItemInfo']
local currentPlayer = UnitName('player')

local ItemSearch = LibStub('LibItemSearch-1.0')
local bgSearch = CreateFrame("Frame","BagSync_SearchFrame", UIParent)

--add class search
local tooltipScanner = _G['LibItemSearchTooltipScanner'] or CreateFrame('GameTooltip', 'LibItemSearchTooltipScanner', UIParent, 'GameTooltipTemplate')
local tooltipCache = setmetatable({}, {__index = function(t, k) local v = {} t[k] = v return v end})

ItemSearch:RegisterTypedSearch{
	id = 'classRestriction',
	tags = {'c', 'class'},
	
	canSearch = function(self, _, search)
		return search
	end,
	
	findItem = function(self, link, _, search)
		if link:find("battlepet") then return false end

		local itemID = link:match('item:(%d+)')
		if not itemID then
			return
		end
		
		local cachedResult = tooltipCache[search][itemID]
		if cachedResult ~= nil then
			return cachedResult
		end
	
		tooltipScanner:SetOwner(UIParent, 'ANCHOR_NONE')
		tooltipScanner:SetHyperlink(link)

		local result = false
		
		local pattern = string.gsub(ITEM_CLASSES_ALLOWED:lower(), "%%s", "(.+)")
		
		for i = 1, tooltipScanner:NumLines() do
			local text =  _G[tooltipScanner:GetName() .. 'TextLeft' .. i]:GetText():lower()
			textChk = string.find(text, pattern)

			if textChk and tostring(text):find(search) then
				result = true
			end
		end
		
		tooltipCache[search][itemID] = result
		return result
	end,
}

local function LoadSlider()

	local function OnEnter(self)
		if self.link then
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:SetHyperlink(self.link)
			GameTooltip:Show()
		end
	end
	local function OnLeave() GameTooltip:Hide() end

	local EDGEGAP, ROWHEIGHT, ROWGAP, GAP = 16, 20, 2, 4
	local FRAME_HEIGHT = bgSearch:GetHeight() - 60
	local SCROLL_TOP_POSITION = -90
	local totalRows = math.floor((FRAME_HEIGHT-22)/(ROWHEIGHT + ROWGAP))
	
	for i=1, totalRows do
		if not rows[i] then
			local row = CreateFrame("Button", "BagSyncSearchRow"..i, bgSearch)
			if not anchor then row:SetPoint("BOTTOMLEFT", bgSearch, "TOPLEFT", 0, SCROLL_TOP_POSITION)
			else row:SetPoint("TOP", anchor, "BOTTOM", 0, -ROWGAP) end
			row:SetPoint("LEFT", EDGEGAP, 0)
			row:SetPoint("RIGHT", -EDGEGAP*2-8, 0)
			row:SetHeight(ROWHEIGHT)
			row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
			anchor = row
			rows[i] = row

			local title = row:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
			title:SetPoint("LEFT")
			title:SetJustifyH("LEFT") 
			title:SetWidth(row:GetWidth())
			title:SetHeight(ROWHEIGHT)
			row.title = title

			row:SetScript("OnEnter", OnEnter)
			row:SetScript("OnLeave", OnLeave)
			row:SetScript("OnClick", function(self)
				if self.link then
					if HandleModifiedItemClick(self.link) then
						return
					end
					if IsModifiedClick("CHATLINK") then
						local editBox = ChatEdit_ChooseBoxForSend()
						if editBox then
							editBox:Insert(self.link)
							ChatFrame_OpenChat(editBox:GetText())
						end
					end
				end
			end)
		end
	end

	local offset = 0
	local RefreshSearch = function()
		if not BagSync_SearchFrame:IsVisible() then return end
		for i,row in ipairs(rows) do
			if (i + offset) <= #searchTable then
				if searchTable[i + offset] then
					if searchTable[i + offset].rarity then
						--local hex = (select(4, GetItemQualityColor(searchTable[i + offset].rarity)))
						local hex = (select(4, GetItemQualityColor(searchTable[i + offset].rarity)))
						row.title:SetText(format('|c%s%s|r', hex, searchTable[i + offset].name) or searchTable[i + offset].name)
					else
						row.title:SetText(searchTable[i + offset].name)
					end
					row.link = searchTable[i + offset].link
					row:Show()
				end
			else
				row.title:SetText(nil)
				row:Hide()
			end
		end
	end

	RefreshSearch()

	if not bgSearch.scrollbar then
		bgSearch.scrollbar = LibStub("tekKonfig-Scroll").new(bgSearch, nil, #rows/2)
		bgSearch.scrollbar:ClearAllPoints()
		bgSearch.scrollbar:SetPoint("TOP", rows[1], 0, -16)
		bgSearch.scrollbar:SetPoint("BOTTOM", rows[#rows], 0, 16)
		bgSearch.scrollbar:SetPoint("RIGHT", -16, 0)
	end
	
	if #searchTable > 0 then
		bgSearch.scrollbar:SetMinMaxValues(0, math.max(0, #searchTable - #rows))
		bgSearch.scrollbar:SetValue(0)
		bgSearch.scrollbar:Show()
	else
		bgSearch.scrollbar:Hide()
	end
	
	local f = bgSearch.scrollbar:GetScript("OnValueChanged")
		bgSearch.scrollbar:SetScript("OnValueChanged", function(self, value, ...)
		offset = math.floor(value)
		RefreshSearch()
		return f(self, value, ...)
	end)

	bgSearch:EnableMouseWheel()
	bgSearch:SetScript("OnMouseWheel", function(self, val)
		bgSearch.scrollbar:SetValue(bgSearch.scrollbar:GetValue() - val*#rows/2)
	end)
end

--do search routine
local function DoSearch()
	if not BagSync or not BagSyncDB then return end
	local searchStr = bgSearch.SEARCHBTN:GetText()

	searchStr = searchStr:lower()
	
	searchTable = {} --reset
	
	local tempList = {}
	local previousGuilds = {}
	local count = 0
	local playerSearch = false
	
	if strlen(searchStr) > 0 then
		
		local playerFaction = UnitFactionGroup("player")
		local allowList = {
			["bag"] = 0,
			["bank"] = 0,
			["equip"] = 0,
			["mailbox"] = 0,
			["void"] = 0,
			["auction"] = 0,
			["guild"] = 0,
		}
		
		if string.len(searchStr) > 1 and string.find(searchStr, "@") and allowList[string.sub(searchStr, 2)] ~= nil then playerSearch = true end
		
		--loop through our characters
		--k = player, v = stored data for player
		for k, v in pairs(BagSyncDB[currentRealm]) do

			local pFaction = v.faction or playerFaction --just in case ;) if we dont know the faction yet display it anyways
			
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
									local dblink, dbcount = strsplit(',', itemValue)
									if dblink then
										local dName, dItemLink, dRarity = GetItemInfo(dblink)
										if dName and dItemLink then
											--are we checking in our bank,void, etc?
											if playerSearch and string.sub(searchStr, 2) == q and string.sub(searchStr, 2) ~= "guild" and k == currentPlayer and not tempList[dblink] then
												table.insert(searchTable, { name=dName, link=dItemLink, rarity=dRarity } )
												tempList[dblink] = dName
												count = count + 1
											--we found a match
											elseif not playerSearch and not tempList[dblink] and ItemSearch:Find(dItemLink, searchStr) then
												table.insert(searchTable, { name=dName, link=dItemLink, rarity=dRarity } )
												tempList[dblink] = dName
												count = count + 1
											end
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
					if BagSyncGUILD_DB and guildN and BagSyncGUILD_DB[currentRealm][guildN] then
						--check to see if this guild has already been done through this run (so we don't do it multiple times)
						if not previousGuilds[guildN] then
							--we only really need to see this information once per guild
							for q, r in pairs(BagSyncGUILD_DB[currentRealm][guildN]) do
								local dblink, dbcount = strsplit(',', r)
								if dblink then
									local dName, dItemLink, dRarity = GetItemInfo(dblink)
									if dName then
										if playerSearch and string.sub(searchStr, 2) == q and string.sub(searchStr, 2) == "guild" and k == currentPlayer and not tempList[dblink] then
											table.insert(searchTable, { name=dName, link=dItemLink, rarity=dRarity } )
											tempList[dblink] = dName
											count = count + 1
										--we found a match
										elseif not playerSearch and not tempList[dblink] and ItemSearch:Find(dItemLink, searchStr) then
											table.insert(searchTable, { name=dName, link=dItemLink, rarity=dRarity } )
											tempList[dblink] = dName
											count = count + 1
										end
									end
								end
							end
							previousGuilds[guildN] = true
						end
					end
				end
				
			end
			
		end
		
		table.sort(searchTable, function(a,b) return (a.name < b.name) end)
	end
	
	bgSearch.totalC:SetText("|cFFFFFFFF"..L["Total:"].." "..count.."|r")
	
	LoadSlider()
end

local function escapeEditBox(self)
  self:SetAutoFocus(false)
end

local function enterEditBox(self)
	self:ClearFocus()
	--self:GetParent():DoSearch()
	DoSearch()
end

local function createEditBox(name, labeltext, obj, x, y)
  local editbox = CreateFrame("EditBox", name, obj, "InputBoxTemplate")
  editbox:SetAutoFocus(false)
  editbox:SetWidth(180)
  editbox:SetHeight(16)
  editbox:SetPoint("TOPLEFT", obj, "TOPLEFT", x or 0, y or 0)
  local label = editbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  label:SetPoint("BOTTOMLEFT", editbox, "TOPLEFT", -6, 4)
  label:SetText(labeltext)
  editbox:SetScript("OnEnterPressed", enterEditBox)
  editbox:HookScript("OnEscapePressed", escapeEditBox)
  return editbox
end

bgSearch:SetFrameStrata("HIGH")
bgSearch:SetToplevel(true)
bgSearch:EnableMouse(true)
bgSearch:SetMovable(true)
bgSearch:SetClampedToScreen(true)
bgSearch:SetWidth(380)
bgSearch:SetHeight(500)

bgSearch:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 32,
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
})

bgSearch:SetBackdropColor(0,0,0,1)
bgSearch:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

bgSearch.SEARCHBTN = createEditBox("$parentEdit1", (L["Search"]..":"), bgSearch, 60, -50)

local addonTitle = bgSearch:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
addonTitle:SetPoint("CENTER", bgSearch, "TOP", 0, -20)
addonTitle:SetText("|cFF99CC33BagSync|r |cFFFFFFFF("..L["Search"]..")|r")

local totalC = bgSearch:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
totalC:SetPoint("RIGHT", bgSearch.SEARCHBTN, 70, 0)
totalC:SetText("|cFFFFFFFF"..L["Total:"].." 0|r")
bgSearch.totalC = totalC
		
local closeButton = CreateFrame("Button", nil, bgSearch, "UIPanelCloseButton");
closeButton:SetPoint("TOPRIGHT", bgSearch, -15, -8);

bgSearch:SetScript("OnShow", function(self)
	LoadSlider()
	self.SEARCHBTN:SetFocus()
end)
bgSearch:SetScript("OnHide", function(self)
	searchTable = {}
	self.SEARCHBTN:SetText("")
	self.totalC:SetText("|cFFFFFFFF"..L["Total:"].." 0|r")
end)

bgSearch:SetScript("OnMouseDown", function(frame, button)
	if frame:IsMovable() then
		frame.isMoving = true
		frame:StartMoving()
	end
end)

bgSearch:SetScript("OnMouseUp", function(frame, button) 
	if( frame.isMoving ) then
		frame.isMoving = nil
		frame:StopMovingOrSizing()
	end
end)

function bgSearch:initSearch()
	DoSearch()
end

bgSearch:Hide()
