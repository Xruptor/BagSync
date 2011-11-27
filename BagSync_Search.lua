local L = BAGSYNC_L
local searchTable = {}
local rows, anchor = {}
local currentRealm = GetRealmName()
local GetItemInfo = _G['GetItemInfo']

local ItemSearch = LibStub('LibItemSearch-1.0')

local bgSearch = CreateFrame("Frame","BagSync_SearchFrame", UIParent)

local function escapeEditBox(self)
  self:SetAutoFocus(false)
end

local function enterEditBox(self)
	self:ClearFocus()
	self:GetParent():DoSearch()
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
	self:LoadSlider()
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

function bgSearch:LoadSlider()

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
			local row = CreateFrame("Button", nil, bgSearch)
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
					if IsShiftKeyDown() then
						local editBox = ChatEdit_ChooseBoxForSend()
						if editBox then
							editBox:Insert(self.link)
							ChatFrame_OpenChat(editBox:GetText())
						end
					elseif IsControlKeyDown() then
						DressUpItemLink(self.link)
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
function bgSearch:DoSearch()
	if not BagSync or not BagSyncDB then return end
	local searchStr = bgSearch.SEARCHBTN:GetText()

	searchStr = searchStr:lower()
	
	searchTable = {} --reset
	
	local tempList = {}
	local previousGuilds = {}
	local count = 0
	
	if strlen(searchStr) > 0 then
		
		local playerFaction = UnitFactionGroup("player")

		--loop through our characters
		for k, v in pairs(BagSyncDB[currentRealm]) do
		
			local pFaction = v.faction or playerFaction --just in case ;) if we dont know the faction yet display it anyways
		
			--check if we should show both factions or not
			if BagSyncOpt.enableFaction or pFaction == playerFaction then

				--now count the stuff for the user
				for q, r in pairs(v) do
					--don't search gold, faction, or class info, just items
					if q ~= "gold" and q ~= "faction" and q ~= "class" then
						local dblink, dbcount = strsplit(',', r)
						if dblink then
							local dName, dItemLink, dRarity = GetItemInfo(dblink)
							if dName and dItemLink then
								--we found a match
								if not tempList[dblink] and ItemSearch:Find(dItemLink, searchStr) then
									table.insert(searchTable, { name=dName, link=dItemLink, rarity=dRarity } )
									tempList[dblink] = dName
									count = count + 1
								end
							end
						end
					end
				end
			
				--only search guild if the guild features are on
				if BagSyncOpt.enableGuild then
					local guildN = v.guild or nil
				
					--check the guild bank if the character is in a guild
					if BagSyncGUILD_DB and guildN and BagSyncGUILD_DB[currentRealm][guildN] then
						--check to see if this guild has already been done through this run (so we don't do it multiple times)
						if not previousGuilds[guildN] then
							for q, r in pairs(BagSyncGUILD_DB[currentRealm][guildN]) do
								local dblink, dbcount = strsplit(',', r)
								if dblink then
									local dName, dItemLink, dRarity = GetItemInfo(dblink)
									if dName then
										--we found a match
										if not tempList[dblink] and ItemSearch:Find(dItemLink, searchStr) then
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
	
	bgSearch:LoadSlider()
end

bgSearch:Hide()
