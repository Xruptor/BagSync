--[[
	sortOrder.lua
		A sortOrder editor frame for BagSync

		BagSync - All Rights Reserved - (c) 2006-2023
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local SortOrder = BSYC:NewModule("SortOrder")
local Data = BSYC:GetModule("Data")
local Unit = BSYC:GetModule("Unit")
local Tooltip = BSYC:GetModule("Tooltip")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "SortOrder", ...) end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local AceGUI = LibStub("AceGUI-3.0")

function SortOrder:OnEnable()

	--lets create our widgets
	local SortOrderFrame = AceGUI:Create("Window")
	_G["BagSyncSortOrderFrame"] = SortOrderFrame
    --Add to special frames so window can be closed when the escape key is pressed.
    tinsert(UISpecialFrames, "BagSyncSortOrderFrame")
	SortOrder.frame = SortOrderFrame
	SortOrder.parentFrame = SortOrderFrame.frame

	SortOrderFrame:SetTitle("BagSync - "..L.SortOrder)
	SortOrderFrame:SetHeight(500)
	SortOrderFrame:SetWidth(380)
	SortOrderFrame:EnableResize(false)

	local information = AceGUI:Create("BagSyncLabel")
	information:SetText(L.CustomSortInfo)
	information:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	information:SetColor(1, 165/255, 0)
	information:SetFullWidth(true)
	SortOrderFrame:AddChild(information)

	local information2 = AceGUI:Create("BagSyncLabel")
	information2:SetText(L.CustomSortInfoWarn)
	information2:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	information2:SetColor(1, 165/255, 0)
	information2:SetFullWidth(true)
	SortOrderFrame:AddChild(information2)

	local scrollframe = AceGUI:Create("ScrollFrame");
	scrollframe:SetFullWidth(true)
	scrollframe:SetLayout("Flow")

	SortOrder.scrollframe = scrollframe
	SortOrderFrame:AddChild(scrollframe)

	hooksecurefunc(SortOrderFrame, "Show" ,function()
		self:DisplayList()
	end)

	local refreshbutton = AceGUI:Create("Button")
	refreshbutton:SetText(L.Refresh)
	refreshbutton:SetWidth(100)
	refreshbutton:SetHeight(20)
	refreshbutton:SetCallback("OnClick", function()
		self:DisplayList()
	end)
	SortOrderFrame:AddChild(refreshbutton)

	SortOrderFrame:Hide()
end

function SortOrder:AddEntry(entry, isHeader)

	local label = AceGUI:Create("BagSyncInteractiveLabel")

	label:SetHeaderHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	label:ToggleHeaderHighlight(false)
	label.entry = entry
	label:SetColor(1, 1, 1)

	if isHeader then
		label:SetText(entry.unitObj.realm)
		label:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
		label:SetFullWidth(true)
		label:ApplyJustifyH("CENTER")
		label:ToggleHeaderHighlight(true)
		label.userdata.isHeader = true
		label:ToggleEditBox(false)
		label.editbox:SetText("")
	else
		if entry.unitObj.isGuild then
			label:SetText(GUILD..":  "..entry.colorized)
		else
			label:SetText(entry.colorized)
		end
		label:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
		label:SetFullWidth(true)
		label:ApplyJustifyH("LEFT")
		label.userdata.isHeader = false

		label:ToggleEditBox(true)
		label:SetCustomHeight(32)
		label:SetEditBoxHeight(25)
		label:SetEditBoxWidth(65)
		label.editbox:SetText(entry.unitObj.data.SortIndex)
	end

	label:SetCallback(
		"OnEnterPressed",
		function (widget, event, value)
			local indexNum = tonumber(value)

			--make sure it's a number we are working with
			if indexNum then
				--set the new sortindex number
				entry.unitObj.data.SortIndex = indexNum
			else
				--reset to one already stored or 0
				if entry.unitObj.data.SortIndex then
					label.editbox:SetText(entry.unitObj.data.SortIndex)
				else
					label.editbox:SetText(0)
				end
			end
		end)

	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			if not label.userdata.isHeader then
				label:SetColor(1, 0, 0)
				--override the single tooltip use of BagSync
				label.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
				label.highlight:SetVertexColor(0,1,0,0.3)

				GameTooltip:SetOwner(label.frame, "ANCHOR_BOTTOMRIGHT")

				if not label.entry.unitObj.isGuild then
					GameTooltip:AddLine(PLAYER..":  "..entry.colorized)
				else
					GameTooltip:AddLine(GUILD..":  "..entry.colorized)
					GameTooltip:AddLine(L.Realm.."  "..entry.unitObj.realm)
					GameTooltip:AddLine(L.TooltipRealmKey.." "..entry.unitObj.data.realmKey)
				end
				GameTooltip:Show()
			end
		end)
	label:SetCallback(
		"OnLeave",
		function (widget, sometable)
			label:SetColor(1, 1, 1)
			--override the single tooltip use of BagSync
			label.highlight:SetTexture(nil)
			GameTooltip:Hide()
		end)

	self.scrollframe:AddChild(label)
end

function SortOrder:DisplayList()

	self.scrollframe:ReleaseChildren() --clear out the scrollframe

	local sortOrderTable = {}
	local SortIndex = 0

	for unitObj in Data:IterateUnits(true) do
		table.insert(sortOrderTable, { unitObj=unitObj, colorized=Tooltip:ColorizeUnit(unitObj, true) } )
	end

	if #sortOrderTable > 0 then

		table.sort(sortOrderTable, function(a, b)
			if a.unitObj.data.SortIndex and b.unitObj.data.SortIndex  then
				return  a.unitObj.data.SortIndex < b.unitObj.data.SortIndex;
			else
				if a.unitObj.realm  == b.unitObj.realm then
					return a.unitObj.name < b.unitObj.name;
				end
				return a.unitObj.realm < b.unitObj.realm;
			end
		end)

		local lastHeader = ""

		for i=1, #sortOrderTable do
			local unitObj = sortOrderTable[i].unitObj
			--add SortIndex if missing
			if not unitObj.data.SortIndex then
				SortIndex = SortIndex + 1
				unitObj.data.SortIndex = SortIndex
			else
				--this is for future entries that will always start at the bottom
				if unitObj.data.SortIndex > SortIndex then
					SortIndex = unitObj.data.SortIndex
				end
			end
			if lastHeader ~= unitObj.realm then
				self:AddEntry(sortOrderTable[i], true) --add header
				self:AddEntry(sortOrderTable[i], false) --add entry
				lastHeader = unitObj.realm
			else
				self:AddEntry(sortOrderTable[i], false) --add entry
			end
		end
		self.scrollframe.frame:Show()
	else
		self.scrollframe.frame:Hide()
	end

end
