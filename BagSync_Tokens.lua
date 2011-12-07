local L = BAGSYNC_L
local tokensTable = {}
local tRows, tAnchor = {}
local currentPlayer = UnitName('player')
local currentRealm = GetRealmName()
local GetItemInfo = _G['GetItemInfo']
local SILVER = '|cffc7c7cf%s|r'
local MOSS = '|cFF80FF00%s|r'

local bgTokens = CreateFrame("Frame","BagSync_TokensFrame", UIParent)

local function LoadSlider()
	
	local function OnEnter(self)
		if self.name and self.tooltip then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(self.name)
			GameTooltip:AddLine(' ')
			for i=1, #self.tooltip do
				GameTooltip:AddDoubleLine(format(MOSS, self.tooltip[i].name), format(SILVER, self.tooltip[i].count))
			end
			GameTooltip:Show()
		end
	end
	
	local function OnLeave() GameTooltip:Hide() end

	local EDGEGAP, ROWHEIGHT, ROWGAP, GAP = 40, 20, 2, 4
	local FRAME_HEIGHT = bgTokens:GetHeight() - 50
	local SCROLL_TOP_POSITION = -80
	local totaltRows = math.floor((FRAME_HEIGHT-22)/(ROWHEIGHT + ROWGAP))
	
	for i=1, totaltRows do
		if not tRows[i] then
			local row = CreateFrame("Button", nil, bgTokens)
			if not tAnchor then row:SetPoint("BOTTOMLEFT", bgTokens, "TOPLEFT", 0, SCROLL_TOP_POSITION)
			else row:SetPoint("TOP", tAnchor, "BOTTOM", 0, -ROWGAP) end
			row:SetPoint("LEFT", EDGEGAP, 0)
			row:SetPoint("RIGHT", -EDGEGAP*1-8, 0)
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

			local icon = row:CreateTexture(nil,"OVERLAY")
			icon:SetPoint("LEFT", (ROWHEIGHT * -1) -3, 0)
			icon:SetWidth(ROWHEIGHT)
			icon:SetHeight(ROWHEIGHT)
			icon:SetTexture("Interface\\Icons\\Spell_Shadow_Shadowbolt")
			icon:Hide()
			row.icon = icon
	
			row:SetScript("OnEnter", OnEnter)
			row:SetScript("OnLeave", OnLeave)
		end
	end

	local offset = 0
	local RefreshTokens = function()
		if not BagSync_TokensFrame:IsVisible() then return end
		
		for i,row in ipairs(tRows) do
			if (i + offset) <= #tokensTable then
				if tokensTable[i + offset] then

					if tokensTable[i + offset].isHeader then
						row.title:SetText("|cFFFFFFFF"..tokensTable[i + offset].name.."|r")
					else
						row.title:SetText(tokensTable[i + offset].name)
					end
					
					--header texture and parameters
					if tokensTable[i + offset].isHeader then
						row:LockHighlight()
						row.title:SetJustifyH("CENTER") 
						row.tooltip = nil
					else
						row:UnlockHighlight()
						row.title:SetJustifyH("LEFT")
						row.name = row.title:GetText()
						row.tooltip = tokensTable[i + offset].tooltip
					end
					
					row.icon:SetTexture(tokensTable[i + offset].icon or nil)
					row.icon:Show()
					row:Show()
				end
			else
				row.icon:SetTexture(nil)
				row.icon:Hide()
				row:Hide()
			end
		end
	end

	RefreshTokens()

	if not bgTokens.scrollbar then
		bgTokens.scrollbar = LibStub("tekKonfig-Scroll").new(bgTokens, nil, #tRows/2)
		bgTokens.scrollbar:ClearAllPoints()
		bgTokens.scrollbar:SetPoint("TOP", tRows[1], 0, -16)
		bgTokens.scrollbar:SetPoint("BOTTOM", tRows[#tRows], 0, 16)
		bgTokens.scrollbar:SetPoint("RIGHT", -16, 0)
	end
	
	if #tokensTable > 0 then
		bgTokens.scrollbar:SetMinMaxValues(0, math.max(0, #tokensTable - #tRows))
		bgTokens.scrollbar:SetValue(0)
		bgTokens.scrollbar:Show()
	else
		bgTokens.scrollbar:Hide()
	end

	local f = bgTokens.scrollbar:GetScript("OnValueChanged")
	bgTokens.scrollbar:SetScript("OnValueChanged", function(self, value, ...)
		offset = math.floor(value)
		RefreshTokens()
		return f(self, value, ...)
	end)

	bgTokens:EnableMouseWheel()
	bgTokens:SetScript("OnMouseWheel", function(self, val)
		bgTokens.scrollbar:SetValue(bgTokens.scrollbar:GetValue() - val*#tRows/2)
	end)
end

local function DoTokens()
	if not BagSync or not BagSyncTOKEN_DB then return end
	if not BagSyncTOKEN_DB[currentRealm] then return end
	
	tokensTable = {} --reset
	local tmp = {}
	
	--loop through our characters
	-----------------------------------
	if BagSyncTOKEN_DB[currentRealm] then
		for k, v in pairs(BagSyncTOKEN_DB[currentRealm]) do

			tmp = {}
			--this will loop and store all characters whom have counts greater then zero, 
			--ignoring the icon and header table entry, then it sorts it by character name
			for q, r in pairs(v) do
				if q ~= "icon" and q ~= "header" and r > 0 then
					--only show counts that are greater then zero
					table.insert(tmp, { name=q, count=r} )
				end
			end
			table.sort(tmp, function(a,b) return (a.name < b.name) end)
			
			--now add it to master table to sort later
			table.insert(tokensTable, {name=k, icon=v.icon, header=v.header, tooltip=tmp})
		end
	end
	-----------------------------------
	
	--sort it
	table.sort(tokensTable, function(a,b)
		if a.header < b.header then
			return true;
		elseif a.header == b.header then
			return (a.name < b.name);
		end
	end)
	
	--add headers
	local lastHeader = ""
	tmp = {} --reset
	
	for i=1, #tokensTable do
		if tokensTable[i].header ~= lastHeader then
			lastHeader = tokensTable[i].header
			table.insert(tmp, { name=lastHeader, header=lastHeader, isHeader=true } )
			table.insert(tmp, tokensTable[i])
		else
			table.insert(tmp, tokensTable[i])
		end
	end
	tokensTable = tmp

	LoadSlider()
end

bgTokens:SetFrameStrata("HIGH")
bgTokens:SetToplevel(true)
bgTokens:EnableMouse(true)
bgTokens:SetMovable(true)
bgTokens:SetClampedToScreen(true)
bgTokens:SetWidth(380)
bgTokens:SetHeight(500)

bgTokens:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 32,
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
})

bgTokens:SetBackdropColor(0,0,0,1)
bgTokens:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

local addonTitle = bgTokens:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
addonTitle:SetPoint("CENTER", bgTokens, "TOP", 0, -20)
addonTitle:SetText("|cFF99CC33BagSync|r |cFFFFFFFF("..L["Tokens"]..")|r")

local closeButton = CreateFrame("Button", nil, bgTokens, "UIPanelCloseButton");
closeButton:SetPoint("TOPRIGHT", bgTokens, -15, -8);

bgTokens:SetScript("OnShow", function(self) DoTokens(); LoadSlider(); end)
bgTokens:SetScript("OnHide", function(self)
	tokensTable = {}
end)

bgTokens:SetScript("OnMouseDown", function(frame, button)
	if frame:IsMovable() then
		frame.isMoving = true
		frame:StartMoving()
	end
end)

bgTokens:SetScript("OnMouseUp", function(frame, button) 
	if( frame.isMoving ) then
		frame.isMoving = nil
		frame:StopMovingOrSizing()
	end
end)

bgTokens:Hide()