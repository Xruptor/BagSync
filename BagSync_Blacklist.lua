local L = BAGSYNC_L
local blacklistTable = {}
local tRows, tAnchor = {}
local currentPlayer = UnitName('player')
local currentRealm = GetRealmName()
local storedBarCount = 0
local prevClickedBar

local bgBlackList = CreateFrame("Frame","BagSync_BlackListFrame", UIParent)

--itemid popup
StaticPopupDialogs["BAGSYNC_BLACKLIST"] = {
	text = L["Please enter an itemid. (Use Wowhead.com)"],
	button1 = "Yes",
	button2 = "No",
	hasEditBox = true,
    hasWideEditBox = true,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
	OnAccept = function (self, data, data2)
		local text = self.editBox:GetText()
		if BagSync_BlackListFrame then
			BagSync_BlackListFrame:processAdd(text)
		end
	end,
	whileDead = 1,
	maxLetters = 255,
}

local function LoadSlider()
	
	local EDGEGAP, ROWHEIGHT, ROWGAP, GAP = 16, 20, 2, 4
	local FRAME_HEIGHT = bgBlackList:GetHeight() - 90
	local SCROLL_TOP_POSITION = -80
	local totaltRows = math.floor((FRAME_HEIGHT-22)/(ROWHEIGHT + ROWGAP))
	
	for i=1, totaltRows do
		if not tRows[i] then
			local row = CreateFrame("Button", nil, bgBlackList)
			if not tAnchor then row:SetPoint("BOTTOMLEFT", bgBlackList, "TOPLEFT", 0, SCROLL_TOP_POSITION)
			else row:SetPoint("TOP", tAnchor, "BOTTOM", 0, -ROWGAP) end
			row:SetPoint("LEFT", EDGEGAP, 0)
			row:SetPoint("RIGHT", -EDGEGAP*2-8, 0)
			row:SetHeight(ROWHEIGHT)
			row:EnableMouse(true)
			row:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8x8",
			})
			row:SetBackdropColor(0,0,0,0)
			tAnchor = row
			tRows[i] = row

			local title = row:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
			title:SetPoint("LEFT")
			title:SetJustifyH("LEFT") 
			title:SetWidth(row:GetWidth())
			title:SetHeight(ROWHEIGHT)
			row.title = title

			row:SetScript("OnClick", function (self, button, down)
				if prevClickedBar then
					prevClickedBar:SetBackdropColor(0,0,0,0)
				end
				prevClickedBar = self
				self:SetBackdropColor(0,1,0,0.25)
			end)
		end
	end

	local offset = 0
	local RefreshBlackList = function()
		if not BagSync_BlackListFrame:IsVisible() then return end
		for i,row in ipairs(tRows) do
			if (i + offset) <= #blacklistTable then
				if blacklistTable[i + offset] then
					row.title:SetText(blacklistTable[i + offset])
					row:Show()
				end
			else
				row:Hide()
			end
		end
	end

	RefreshBlackList()

	if not bgBlackList.scrollbar then
		bgBlackList.scrollbar = LibStub("tekKonfig-Scroll").new(bgBlackList, nil, #tRows/2)
		bgBlackList.scrollbar:ClearAllPoints()
		bgBlackList.scrollbar:SetPoint("TOP", tRows[1], 0, -16)
		bgBlackList.scrollbar:SetPoint("BOTTOM", tRows[#tRows], 0, 16)
		bgBlackList.scrollbar:SetPoint("RIGHT", -16, 0)
	end
	
	if #blacklistTable > 0 then
		bgBlackList.scrollbar:SetMinMaxValues(0, math.max(0, #blacklistTable - #tRows))
		bgBlackList.scrollbar:SetValue(0)
		bgBlackList.scrollbar:Show()
	else
		bgBlackList.scrollbar:Hide()
	end

	local f = bgBlackList.scrollbar:GetScript("OnValueChanged")
	bgBlackList.scrollbar:SetScript("OnValueChanged", function(self, value, ...)
		offset = math.floor(value)
		RefreshBlackList()
		return f(self, value, ...)
	end)

	bgBlackList:EnableMouseWheel()
	bgBlackList:SetScript("OnMouseWheel", function(self, val)
		bgBlackList.scrollbar:SetValue(bgBlackList.scrollbar:GetValue() - val*#tRows/2)
	end)
end

local function DoBlackList()
	if not BagSync or not BagSyncBLACKLIST_DB then return end
	if not BagSyncBLACKLIST_DB[currentRealm] then return end
	
	blacklistTable = {} --reset
	local tmp = {}
	
	--loop through our blacklist
	-----------------------------------
	if BagSyncBLACKLIST_DB[currentRealm] then
		for k, v in pairs(BagSyncBLACKLIST_DB[currentRealm]) do
			table.insert(blacklistTable, k)
		end
	end
	-----------------------------------

	--sort it
	table.sort(blacklistTable)

	LoadSlider()
end

bgBlackList:SetFrameStrata("HIGH")
bgBlackList:SetToplevel(true)
bgBlackList:EnableMouse(true)
bgBlackList:SetMovable(true)
bgBlackList:SetClampedToScreen(true)
bgBlackList:SetWidth(380)
bgBlackList:SetHeight(490)

bgBlackList:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 32,
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
})

bgBlackList:SetBackdropColor(0,0,0,1)
bgBlackList:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

local addonTitle = bgBlackList:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
addonTitle:SetPoint("CENTER", bgBlackList, "TOP", 0, -20)
addonTitle:SetText("|cFF99CC33BagSync|r |cFFFFFFFF("..L["Blacklist"]..")|r")

local closeButton = CreateFrame("Button", nil, bgBlackList, "UIPanelCloseButton");
closeButton:SetPoint("TOPRIGHT", bgBlackList, -15, -8);

--Add ItemID
local addItemButton = CreateFrame("Button", nil, bgBlackList, "UIPanelButtonTemplate")
addItemButton:SetWidth(130)
addItemButton:SetHeight(25)
addItemButton:SetPoint("BOTTOMLEFT", bgBlackList, "BOTTOMLEFT", 20, 15)
addItemButton:SetText(L["Add ItemID"])
addItemButton:SetScript("OnClick", function() StaticPopup_Show("BAGSYNC_BLACKLIST") end)

--Remove ItemID
local removeItemButton = CreateFrame("Button", nil, bgBlackList, "UIPanelButtonTemplate")
removeItemButton:SetWidth(130)
removeItemButton:SetHeight(25)
removeItemButton:SetPoint("BOTTOMRIGHT", bgBlackList, "BOTTOMRIGHT", -20, 15)
removeItemButton:SetText(L["Remove ItemID"])
removeItemButton:SetScript("OnClick", function()
	if not BagSync or not BagSyncBLACKLIST_DB then return end
	if not BagSyncBLACKLIST_DB[currentRealm] then return end
	if not prevClickedBar or not prevClickedBar.title or not prevClickedBar.title:GetText() then return end
	if not tonumber(prevClickedBar.title:GetText()) then return end
	BagSyncBLACKLIST_DB[currentRealm][tonumber(prevClickedBar.title:GetText())] = nil
	DoBlackList()
end)

bgBlackList:SetScript("OnShow", function(self) DoBlackList(); LoadSlider(); end)
bgBlackList:SetScript("OnHide", function(self)
	blacklistTable = {}
end)

bgBlackList:SetScript("OnMouseDown", function(frame, button)
	if frame:IsMovable() then
		frame.isMoving = true
		frame:StartMoving()
	end
end)

bgBlackList:SetScript("OnMouseUp", function(frame, button) 
	if( frame.isMoving ) then
		frame.isMoving = nil
		frame:StopMovingOrSizing()
	end
end)

function bgBlackList:processAdd(itemid)
	if not BagSync or not BagSyncBLACKLIST_DB then return end
	if not BagSyncBLACKLIST_DB[currentRealm] then return end
	if not tonumber(itemid) then return end
	BagSyncBLACKLIST_DB[currentRealm][tonumber(itemid)] = true
	DoBlackList()
end

bgBlackList:Hide()
