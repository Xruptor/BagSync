local L = BAGSYNC_L
local craftsTable = {}
local tRows, tAnchor = {}
local currentPlayer = UnitName('player')
local currentRealm = GetRealmName()

local bgCrafts = CreateFrame("Frame","BagSync_CraftsFrame", UIParent)

local function LoadSlider()
	
	local function OnEnter(self)
		if self.canLink and self.owner then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(format('|cFF99CC33%s|r', self.owner))
			GameTooltip:AddLine(L["Left Click = Link to view tradeskill."])
			GameTooltip:AddLine(L["Right Click = Insert tradeskill link."])
			GameTooltip:Show()
		end
	end
	
	local function OnLeave() GameTooltip:Hide() end

	local EDGEGAP, ROWHEIGHT, ROWGAP, GAP = 16, 20, 2, 4
	local FRAME_HEIGHT = bgCrafts:GetHeight() - 50
	local SCROLL_TOP_POSITION = -80
	local totaltRows = math.floor((FRAME_HEIGHT-22)/(ROWHEIGHT + ROWGAP))
	
	for i=1, totaltRows do
		if not tRows[i] then
			local row = CreateFrame("Button", nil, bgCrafts)
			if not tAnchor then row:SetPoint("BOTTOMLEFT", bgCrafts, "TOPLEFT", 0, SCROLL_TOP_POSITION)
			else row:SetPoint("TOP", tAnchor, "BOTTOM", 0, -ROWGAP) end
			row:SetPoint("LEFT", EDGEGAP, 0)
			row:SetPoint("RIGHT", -EDGEGAP*2-8, 0)
			row:SetHeight(ROWHEIGHT)
			row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
			tAnchor = row
			tRows[i] = row

			local title = row:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
			title:SetPoint("LEFT")
			title:SetJustifyH("LEFT") 
			title:SetWidth(row:GetWidth())
			title:SetHeight(ROWHEIGHT)
			row.title = title

			row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			row:SetScript("OnEnter", OnEnter)
			row:SetScript("OnLeave", OnLeave)
			row:SetScript("OnClick", function (self, button, down)
				if self.link then
					if button == "LeftButton" then
						DEFAULT_CHAT_FRAME:AddMessage(format('%s|cFF99CC33%s|r ==> %s', L["Click to view profession: "], self.owner, self.link))
					else
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
	local RefreshCrafts = function()
		if not BagSync_CraftsFrame:IsVisible() then return end
		
		for i,row in ipairs(tRows) do
			if (i + offset) <= #craftsTable then
				if craftsTable[i + offset] then

					if craftsTable[i + offset].isHeader then
						row.title:SetText("|cFFFFFFFF"..craftsTable[i + offset].name.."|r")
					else
						if craftsTable[i + offset].isLink then
							row.title:SetText( format('|cFF99CC33%s|r |cFFFFFFFF(%s)|r', craftsTable[i + offset].name,  craftsTable[i + offset].level))
						else
							row.title:SetText( format('|cFF6699FF%s|r |cFFFFFFFF(%s)|r', craftsTable[i + offset].name,  craftsTable[i + offset].level))
						end
					end
					
					--header texture and parameters
					if craftsTable[i + offset].isHeader then
						row:LockHighlight()
						row.title:SetJustifyH("CENTER")
						row.canLink = nil
					else
						row:UnlockHighlight()
						row.title:SetJustifyH("LEFT")
						row.canLink = craftsTable[i + offset].isLink 
						row.link = craftsTable[i + offset].link 
						row.owner = craftsTable[i + offset].owner
					end

				end
			else
				row:Hide()
			end
		end
	end

	RefreshCrafts()

	if not bgCrafts.scrollbar then
		bgCrafts.scrollbar = LibStub("tekKonfig-Scroll").new(bgCrafts, nil, #tRows/2)
		bgCrafts.scrollbar:ClearAllPoints()
		bgCrafts.scrollbar:SetPoint("TOP", tRows[1], 0, -16)
		bgCrafts.scrollbar:SetPoint("BOTTOM", tRows[#tRows], 0, 16)
		bgCrafts.scrollbar:SetPoint("RIGHT", -16, 0)
	end
	
	if #craftsTable > 0 then
		bgCrafts.scrollbar:SetMinMaxValues(0, math.max(0, #craftsTable - #tRows))
		bgCrafts.scrollbar:SetValue(0)
		bgCrafts.scrollbar:Show()
	else
		bgCrafts.scrollbar:Hide()
	end

	local f = bgCrafts.scrollbar:GetScript("OnValueChanged")
	bgCrafts.scrollbar:SetScript("OnValueChanged", function(self, value, ...)
		offset = math.floor(value)
		RefreshCrafts()
		return f(self, value, ...)
	end)

	bgCrafts:EnableMouseWheel()
	bgCrafts:SetScript("OnMouseWheel", function(self, val)
		bgCrafts.scrollbar:SetValue(bgCrafts.scrollbar:GetValue() - val*#tRows/2)
	end)
end

local function DoCrafts()
	if not BagSync or not BagSyncCRAFT_DB then return end
	if not BagSyncCRAFT_DB[currentRealm] then return end
	
	craftsTable = {} --reset
	local tmp = {}
	
	--loop through our characters
	-----------------------------------
	if BagSyncCRAFT_DB[currentRealm] then
		for k, v in pairs(BagSyncCRAFT_DB[currentRealm]) do

			tmp = {}
			for q, r in pairs(v) do
				if type(r) == "string" then
					local trName, trSkillLevel = strsplit(',', r)
					if trName and trSkillLevel then
						table.insert(tmp, { name=trName, level=trSkillLevel, isLink=false, owner=k} )
					end
				elseif type(r) == "table" and r[1] and r[2] and r[3] then
					table.insert(tmp, { name=r[1], link=r[2], level=r[3], isLink=true, owner=k} )
				end
			end
			table.sort(tmp, function(a,b) return (a.name < b.name) end)
			
			--now add it to master table to sort later, only add if we have something to add
			if #tmp > 0 then
				table.insert(craftsTable, {header=k, info=tmp})
			end
		end
	end
	-----------------------------------
	
	--sort it
	table.sort(craftsTable, function(a,b)
		if a.header < b.header then
			return true;
		end
	end)
	
	--now that the header names are sorted lets add all headers and info to master table
	tmp = {} --reset
	
	for i=1, #craftsTable do
		--insert header
		table.insert(tmp, { name=craftsTable[i].header, isHeader=true } )
		--insert sub information :)
		for y=1, #craftsTable[i].info do
			table.insert(tmp, craftsTable[i].info[y])
		end
	end
	craftsTable = tmp

	LoadSlider()
end

bgCrafts:SetFrameStrata("HIGH")
bgCrafts:SetToplevel(true)
bgCrafts:EnableMouse(true)
bgCrafts:SetMovable(true)
bgCrafts:SetClampedToScreen(true)
bgCrafts:SetWidth(380)
bgCrafts:SetHeight(500)

bgCrafts:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 32,
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
})

bgCrafts:SetBackdropColor(0,0,0,1)
bgCrafts:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

local addonTitle = bgCrafts:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
addonTitle:SetPoint("CENTER", bgCrafts, "TOP", 0, -20)
addonTitle:SetText("|cFF99CC33BagSync|r |cFFFFFFFF("..L["Professions"]..")|r")

local closeButton = CreateFrame("Button", nil, bgCrafts, "UIPanelCloseButton");
closeButton:SetPoint("TOPRIGHT", bgCrafts, -15, -8);

bgCrafts:SetScript("OnShow", function(self) DoCrafts(); LoadSlider(); end)
bgCrafts:SetScript("OnHide", function(self)
	craftsTable = {}
end)

bgCrafts:SetScript("OnMouseDown", function(frame, button)
	if frame:IsMovable() then
		frame.isMoving = true
		frame:StartMoving()
	end
end)

bgCrafts:SetScript("OnMouseUp", function(frame, button) 
	if( frame.isMoving ) then
		frame.isMoving = nil
		frame:StopMovingOrSizing()
	end
end)

bgCrafts:Hide()