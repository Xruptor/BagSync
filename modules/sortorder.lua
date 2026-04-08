--[[
	sortorder.lua
		A sort order editor frame for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...) --grab the addon namespace
local UI = BSYC:GetModule("UI")
local SortOrder = BSYC:NewModule("SortOrder")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

-- Cache global API references to eliminate repeated _G lookups
local HybridScrollFrame_GetButtons = _G.HybridScrollFrame_GetButtons
local HybridScrollFrame_GetOffset = _G.HybridScrollFrame_GetOffset
local HybridScrollFrame_SetOffset = _G.HybridScrollFrame_SetOffset
local HybridScrollFrame_Update = _G.HybridScrollFrame_Update
local GameTooltip = _G.GameTooltip
local PLAYER = _G.PLAYER
local GUILD = _G.GUILD
local table_insert = _G.table.insert
local table_sort = _G.table.sort

local L = BSYC.L

-- Helper to normalize SortIndex to number or nil
local function NormalizeSortIndex(unitObj)
	if not unitObj or not unitObj.data then return end
	local v = unitObj.data.SortIndex
	if v == nil then return end
	local n = tonumber(v)
	if n then
		unitObj.data.SortIndex = n
	else
		unitObj.data.SortIndex = nil
	end
end

-- Helper to build unit data list for sorting
local function BuildUnitDataList()
	local usrData = {}

	for unitObj in Data:IterateUnits(true) do
		NormalizeSortIndex(unitObj)
		table_insert(usrData, {
			unitObj = unitObj,
			name = unitObj.name,
			realm = unitObj.realm,
			colorized = Tooltip:ColorizeUnit(unitObj, true)
		})
	end

	-- Add warband
	local warbandObj = Data:GetWarbandBankObj()
	if warbandObj then
		NormalizeSortIndex(warbandObj)
		table_insert(usrData, {
			unitObj = warbandObj,
			name = warbandObj.name,
			realm = warbandObj.realm,
			colorized = Tooltip:ColorizeUnit(warbandObj, true)
		})
	end

	return usrData
end

-- Sort comparison function
local function CompareUnitData(a, b)
	if a.unitObj.data.SortIndex and b.unitObj.data.SortIndex then
		return a.unitObj.data.SortIndex < b.unitObj.data.SortIndex
	end

	if a.unitObj.realm == b.unitObj.realm then
		return a.unitObj.name < b.unitObj.name
	end
	return a.unitObj.realm < b.unitObj.realm
end

-- Add missing SortIndex values to units
local function AddSortIndicesToUnits(usrData)
	local SortIndex = 0

	for i = 1, #usrData do
		if not usrData[i].unitObj.data.SortIndex then
			SortIndex = SortIndex + 1
			usrData[i].unitObj.data.SortIndex = SortIndex
		elseif usrData[i].unitObj.data.SortIndex > SortIndex then
			SortIndex = usrData[i].unitObj.data.SortIndex
		end
	end
end

-- Build the final sortorder list with headers
local function BuildSortOrderList(usrData)
	if #usrData == 0 then return {} end

	local sortorderList = {}
	local lastHeader = ""

	table_sort(usrData, CompareUnitData)
	AddSortIndicesToUnits(usrData)

	for i = 1, #usrData do
		-- Add header for each realm
		if lastHeader ~= usrData[i].realm then
			table_insert(sortorderList, {
				colorized = usrData[i].realm,
				isHeader = true,
			})
			lastHeader = usrData[i].realm
		end

		-- Add unit entry
		table_insert(sortorderList, {
			unitObj = usrData[i].unitObj,
			name = usrData[i].name,
			realm = usrData[i].realm,
			colorized = usrData[i].colorized
		})
	end

	return sortorderList
end

-- Helper to get sort status text
local function GetSortStatus()
	local isEnabled = (BSYC.options.tooltipSortMode == "custom")
	local statusColor = isEnabled and "|cFF99CC33" or "|cFFDF2B2B"
	local statusText = isEnabled and L.ON or L.OFF
	return statusColor .. statusText .. "|r"
end

-- Helper to setup SortBox handlers (only once per button)
local function SetupSortBoxHandlers(button)
	if button.SortBox.__bsycHandlers then return end

	button.SortBox.parentHandler = SortOrder
	button.SortBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	button.SortBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		UI:CallHandler(self, "SortBox_OnEnterPressed", self:GetText(), self)
	end)
	button.SortBox.__bsycHandlers = true
end

-- Helper to setup header button
local function SetupHeaderButton(button)
	button.Text:SetJustifyH("CENTER")
	button.HeaderHighlight:SetAlpha(0.75)
	button.isHeader = true
	button.SortBox:SetText("")
	button.SortBox:Hide()
end

-- Helper to setup unit button
local function SetupUnitButton(button, item)
	button.Text:SetJustifyH("LEFT")
	button.HeaderHighlight:SetAlpha(0)
	button.isHeader = nil
	button.SortBox:SetText(item.unitObj.data.SortIndex)
	button.SortBox:Show()
end

-- Helper to update button highlight state
local function UpdateButtonHighlight(button)
	if button.isHeader and button.Highlight:IsVisible() then
		button.Highlight:Hide()
	elseif not button.isHeader and not button.Highlight:IsVisible() then
		button.Highlight:Show()
	end
end

-- Helper to update tooltip for button under mouse
local function UpdateTooltipForButton(button)
	if BSYC:IsMouseOver(button) then
		SortOrder:Item_OnLeave()
		SortOrder:Item_OnEnter(button)
	end
end

function SortOrder:OnEnable()
	local sortorderFrame = UI:CreateModuleFrame(SortOrder, {
		template = "BagSyncFrameTemplate",
		globalName = "BagSyncSortOrderFrame",
		title = "BagSync - "..L.SortOrder,
		height = 523,
		width = 440,
		point = { "CENTER", UIParent, "CENTER", 0, 0 },
		onShow = function() SortOrder:OnShow() end,
	})
	SortOrder.frame = sortorderFrame

	SortOrder.scrollFrame = UI:CreateHybridScrollFrame(sortorderFrame, {
		width = 397,
		pointTopLeft = { "TOPLEFT", sortorderFrame, "TOPLEFT", 13, -29 },
		pointBottomLeft = { "BOTTOMLEFT", sortorderFrame, "BOTTOMLEFT", -25, 15 },
		buttonTemplate = "BagSyncListSortItemTemplate",
		update = function() SortOrder:RefreshList() end,
	})
	SortOrder.sortorderList = {}

	-- Warning Frame
	local warningFrame = UI:CreateInfoFrame(sortorderFrame, {
		title = L.DisplaySortOrderHelp,
		point = { "TOPLEFT", sortorderFrame, "TOPRIGHT", 5, 0 },
		backdropColor = { 0, 0, 0, 0.75 },
		frameStrata = "FULLSCREEN_DIALOG",
	})
	warningFrame.infoText1 = UI:CreateFontString(warningFrame, {
		template = "GameFontHighlightSmall",
		text = L.DisplaySortOrderStatus,
		font = { STANDARD_TEXT_FONT, 14, "" },
		textColor = { 1, 165/255, 0 },
		justifyH = "CENTER",
		width = warningFrame:GetWidth() - 30,
		point = { "LEFT", warningFrame, "TOPLEFT", 10, -40 },
	})
	warningFrame.infoText2 = UI:CreateFontString(warningFrame, {
		template = "GameFontHighlightSmall",
		text = L.CustomSortInfo.."\n\n"..L.CustomSortInfoWarn,
		font = { STANDARD_TEXT_FONT, 14, "" },
		textColor = { 50/255, 165/255, 0 },
		width = warningFrame:GetWidth() - 30,
		point = { "LEFT", warningFrame.infoText1, "BOTTOMLEFT", 5, -100 },
		justifyH = "CENTER",
	})
	SortOrder.warningFrame = warningFrame
	sortorderFrame:Hide()
end

function SortOrder:OnShow()
	BSYC:SetBSYC_FrameLevel(SortOrder)

	SortOrder.warningFrame.infoText1:SetText(L.DisplaySortOrderStatus:format(GetSortStatus()))
	SortOrder.warningFrame:Show()
	SortOrder:UpdateList()
end

function SortOrder:UpdateList()
	SortOrder:CreateList()
	SortOrder:RefreshList()

	-- Scroll to top when shown
	HybridScrollFrame_SetOffset(SortOrder.scrollFrame, 0)
	SortOrder.scrollFrame.scrollBar:SetValue(0)
end

function SortOrder:CreateList()
	local usrData = BuildUnitDataList()
	SortOrder.sortorderList = BuildSortOrderList(usrData)
end

function SortOrder:RefreshList()
	local items = SortOrder.sortorderList
	local buttons = HybridScrollFrame_GetButtons(SortOrder.scrollFrame)
	local offset = HybridScrollFrame_GetOffset(SortOrder.scrollFrame)

	if not buttons then return end
	local scrollFrame = SortOrder.scrollFrame

	for buttonIndex = 1, #buttons do
		local button = buttons[buttonIndex]
		UI:AttachListItemHandlers(button, SortOrder)
		SetupSortBoxHandlers(button)

		local itemIndex = buttonIndex + offset

		if itemIndex <= #items then
			local item = items[itemIndex]

			button:SetID(itemIndex)
			button.data = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
			button.Text:SetTextColor(1, 1, 1)
			button:SetWidth(scrollFrame.scrollChild:GetWidth())

			if item.isHeader then
				SetupHeaderButton(button)
			else
				SetupUnitButton(button, item)
			end
			button.Text:SetText(item.colorized or "")

			UpdateButtonHighlight(button)
			UpdateTooltipForButton(button)

			button:Show()
		else
			button:Hide()
		end
	end

	local buttonHeight = scrollFrame.buttonHeight
	local totalHeight = #items * buttonHeight
	local shownHeight = #buttons * buttonHeight

	HybridScrollFrame_Update(scrollFrame, totalHeight, shownHeight)
end

function SortOrder:Item_OnEnter(btn)
	if btn.isHeader then
		GameTooltip:Hide()
		return
	end

	if not btn.Highlight:IsVisible() then
		btn.Highlight:Show()
	end

	GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")

	if btn.data.unitObj.isWarbandBank then
		GameTooltip:AddLine(btn.data.colorized)
	elseif not btn.data.unitObj.isGuild then
		GameTooltip:AddLine("|cFFFFFFFF"..PLAYER..":|r  "..btn.data.colorized)
	else
		GameTooltip:AddLine("|cFFFFFFFF"..GUILD..":|r  "..btn.data.colorized)
		GameTooltip:AddLine("|cFFFFFFFF"..L.Realm.."|r  "..btn.data.realm)
		GameTooltip:AddLine("|cFFFFFFFF"..L.TooltipRealmKey.."|r "..(btn.data.unitObj.data.realmKey or "?"))
	end
	GameTooltip:Show()
end

function SortOrder:Item_OnLeave()
	GameTooltip:Hide()
end

function SortOrder:SortBox_OnEnterPressed(text, editbox)
	local btn = editbox:GetParent()
	if not btn then return end

	local num = tonumber(text)
	if num then
		btn.data.unitObj.data.SortIndex = num
		SortOrder:UpdateList()
		Tooltip:ResetCache()
		Tooltip:ResetLastLink()
	else
		-- Reset to stored value or 0
		local storedValue = btn.data.unitObj.data.SortIndex or 0
		editbox:SetText(storedValue)
	end
end
