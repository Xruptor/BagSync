--[[
	sortOrder.lua
		A sortOrder editor frame for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local SortOrder = BSYC:NewModule("SortOrder")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "SortOrder", ...) end
end

local L = BSYC.L

function SortOrder:OnEnable()
	local sortorderFrame = BSYC:UI_CreateModuleFrame(SortOrder, {
		template = "BagSyncFrameTemplate",
		globalName = "BagSyncSortOrderFrame",
		title = "BagSync - "..L.SortOrder,
		height = 523,
		width = 440,
		point = { "CENTER", UIParent, "CENTER", 0, 0 },
		onShow = function() SortOrder:OnShow() end,
	})
	SortOrder.frame = sortorderFrame

	SortOrder.scrollFrame = BSYC:UI_CreateHybridScrollFrame(sortorderFrame, {
		width = 397,
		pointTopLeft = { "TOPLEFT", sortorderFrame, "TOPLEFT", 13, -29 },
		-- set ScrollFrame height by altering the distance from the bottom of the frame
		pointBottomLeft = { "BOTTOMLEFT", sortorderFrame, "BOTTOMLEFT", -25, 15 },
		buttonTemplate = "BagSyncListSortItemTemplate",
		update = function() SortOrder:RefreshList(); end,
	})
	--the items we will work with
	SortOrder.sortorderList = {}

	--Warning Frame
	local warningFrame = _G.CreateFrame("Frame", nil, sortorderFrame, "BagSyncInfoFrameTemplate")
	warningFrame:Hide()
	warningFrame:SetBackdropColor(0, 0, 0, 0.75)
    warningFrame:EnableMouse(true) --don't allow clickthrough
    warningFrame:SetMovable(false)
	warningFrame:SetResizable(false)
    warningFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	warningFrame:ClearAllPoints()
	warningFrame:SetPoint("TOPLEFT", sortorderFrame, "TOPRIGHT", 5, 0)
	warningFrame.TitleText:SetText(L.DisplaySortOrderHelp)
	warningFrame.TitleText:SetFont(STANDARD_TEXT_FONT, 14, "")
	warningFrame.TitleText:SetTextColor(1, 1, 1)
	warningFrame.infoText1 = warningFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	warningFrame.infoText1:SetText(L.DisplaySortOrderStatus)
	warningFrame.infoText1:SetFont(STANDARD_TEXT_FONT, 14, "")
	warningFrame.infoText1:SetTextColor(1, 165/255, 0) --orange, red is just too much sometimes
	warningFrame.infoText1:SetJustifyH("CENTER")
	warningFrame.infoText1:SetWidth(warningFrame:GetWidth() - 30)
	warningFrame.infoText1:SetPoint("LEFT", warningFrame, "TOPLEFT", 10, -40)
	warningFrame.infoText2 = warningFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	warningFrame.infoText2:SetText(L.CustomSortInfo.."\n\n"..L.CustomSortInfoWarn)
	warningFrame.infoText2:SetFont(STANDARD_TEXT_FONT, 14, "")
	warningFrame.infoText2:SetTextColor(50/255, 165/255, 0)
	warningFrame.infoText2:SetWidth(warningFrame:GetWidth() - 30)
	warningFrame.infoText2:SetPoint("LEFT", warningFrame.infoText1, "BOTTOMLEFT", 5, -100)
	warningFrame.infoText2:SetJustifyH("CENTER")
	SortOrder.warningFrame = warningFrame

	sortorderFrame:Hide()
end

function SortOrder:OnShow()
	BSYC:SetBSYC_FrameLevel(SortOrder)

	local isCustom = (BSYC.options.tooltipSortMode == "custom") or BSYC.options.sortByCustomOrder
	local getStatus = (isCustom and ("|cFF99CC33"..L.ON.."|r")) or ( "|cFFDF2B2B"..L.OFF.."|r")
	SortOrder.warningFrame.infoText1:SetText(L.DisplaySortOrderStatus:format(getStatus))
	SortOrder.warningFrame:Show()
	SortOrder:UpdateList()
end

function SortOrder:UpdateList()
	SortOrder:CreateList()
    SortOrder:RefreshList()

	--scroll to top when shown
	HybridScrollFrame_SetOffset(SortOrder.scrollFrame, 0)
	SortOrder.scrollFrame.scrollBar:SetValue(0)
end

function SortOrder:CreateList()
	SortOrder.sortorderList = {}
	local usrData = {}
	local SortIndex = 0

	for unitObj in Data:IterateUnits(true) do
		table.insert(usrData, {
			unitObj = unitObj,
			name = unitObj.name,
			realm = unitObj.realm,
			colorized = Tooltip:ColorizeUnit(unitObj, true)
		})
	end

	--add warband
	local warbandObj = Data:GetWarbandBankObj()
	if warbandObj then
		table.insert(usrData, {
			unitObj = warbandObj,
			name = warbandObj.name,
			realm = warbandObj.realm,
			colorized = Tooltip:ColorizeUnit(warbandObj, true)
		})
	end

	if #usrData > 0 then
		table.sort(usrData, function(a, b)
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
		for i=1, #usrData do
			--add SortIndex if missing
			if not usrData[i].unitObj.data.SortIndex then
				SortIndex = SortIndex + 1
				usrData[i].unitObj.data.SortIndex = SortIndex
			elseif usrData[i].unitObj.data.SortIndex > SortIndex then
				--this is for future entries that will always start at the bottom
				SortIndex = usrData[i].unitObj.data.SortIndex
			end
			if lastHeader ~= usrData[i].realm then
				--add header
				table.insert(SortOrder.sortorderList, {
					colorized = usrData[i].realm,
					isHeader = true,
				})
				lastHeader = usrData[i].realm
			end
			--add player
			table.insert(SortOrder.sortorderList, {
				unitObj = usrData[i].unitObj,
				name = usrData[i].name,
				realm = usrData[i].realm,
				colorized = usrData[i].colorized
			})
		end
	end
end

function SortOrder:RefreshList()
    local items = SortOrder.sortorderList
    local buttons = HybridScrollFrame_GetButtons(SortOrder.scrollFrame)
    local offset = HybridScrollFrame_GetOffset(SortOrder.scrollFrame)
	if not buttons then return end

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
		button.parentHandler = SortOrder

        local itemIndex = buttonIndex + offset

        if itemIndex <= #items then
            local item = items[itemIndex]

            button:SetID(itemIndex)
			button.data = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
			button.Text:SetTextColor(1, 1, 1)
            button:SetWidth(SortOrder.scrollFrame.scrollChild:GetWidth())

			if item.isHeader then
				button.Text:SetJustifyH("CENTER")
				--button.HeaderHighlight:SetVertexColor(0.8, 0.7, 0, 1)
				button.HeaderHighlight:SetAlpha(0.75)
				button.isHeader = true
				button.SortBox:SetText("")
				button.SortBox:Hide()
			else
				button.Text:SetJustifyH("LEFT")
				button.HeaderHighlight:SetAlpha(0)
				button.isHeader = nil
				button.SortBox:SetText(item.unitObj.data.SortIndex)
				button.SortBox:Show()
			end
			button.Text:SetText(item.colorized or "")

			--while we are updating the scrollframe, is the mouse currently over a button?
			--if so we need to force the OnEnter as the items will scroll up in data but the button remains the same position on our cursor
				if BSYC:IsMouseOver(button) then
					SortOrder:Item_OnLeave() --hide first
					SortOrder:Item_OnEnter(button)
				end

            button:Show()
        else
            button:Hide()
        end
    end

    local buttonHeight = SortOrder.scrollFrame.buttonHeight
    local totalHeight = #items * buttonHeight
    local shownHeight = #buttons * buttonHeight

    HybridScrollFrame_Update(SortOrder.scrollFrame, totalHeight, shownHeight)
end

function SortOrder:Item_OnEnter(btn)
	if btn.isHeader and btn.Highlight:IsVisible() then
		btn.Highlight:Hide()
	elseif not btn.isHeader and not btn.Highlight:IsVisible() then
		btn.Highlight:Show()
	end
    if not btn.isHeader then
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
		return
	end
	GameTooltip:Hide()
end

function SortOrder:Item_OnLeave()
	GameTooltip:Hide()
end

function SortOrder:SortBox_OnEnterPressed(text, editbox)
	local btn = editbox:GetParent()
	if not btn then return end

	local num = tonumber(text)
	--make sure it's a number we are working with
	if num then
		--set the new sortindex number
		btn.data.unitObj.data.SortIndex = num
		SortOrder:UpdateList()
		--reset tooltip cache since we have moved around the units to display
		Tooltip:ResetCache()
		Tooltip:ResetLastLink()
	else
		--reset to one already stored or 0
		if btn.data.unitObj.data.SortIndex then
			editbox:SetText(btn.data.unitObj.data.SortIndex)
		else
			editbox:SetText(0)
		end
	end
end
