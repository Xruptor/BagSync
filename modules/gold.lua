--[[
	gold.lua
		A frame displaying all database character gold totals for BagSync

		BagSync - All Rights Reserved - (c) 2006-2023
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Gold = BSYC:NewModule("Gold")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Gold", ...) end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

function Gold:OnEnable()
	local goldFrame = _G.CreateFrame("Frame", nil, UIParent, "BagSyncFrameTemplate")
	Mixin(goldFrame, Gold) --implement new frame to our parent module Mixin, to have access to parent methods
	_G["BagSyncGoldFrame"] = goldFrame
    --Add to special frames so window can be closed when the escape key is pressed.
    tinsert(UISpecialFrames, "BagSyncGoldFrame")
    goldFrame.TitleText:SetText("BagSync - "..L.Gold)
    goldFrame:SetHeight(500)
	goldFrame:SetWidth(440)
    goldFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    goldFrame:EnableMouse(true) --don't allow clickthrough
    goldFrame:SetMovable(true)
    goldFrame:SetResizable(false)
    goldFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    goldFrame:SetScript("OnShow", function() Gold:OnShow() end)
    Gold.frame = goldFrame

    Gold.scrollFrame = _G.CreateFrame("ScrollFrame", nil, goldFrame, "HybridScrollFrameTemplate")
    Gold.scrollFrame:SetWidth(405)
    Gold.scrollFrame:SetPoint("TOPLEFT", goldFrame, "TOPLEFT", 6, -22)
    --set ScrollFrame height by altering the distance from the bottom of the frame
    Gold.scrollFrame:SetPoint("BOTTOMLEFT", goldFrame, "BOTTOMLEFT", -25, 40)
    Gold.scrollFrame.scrollBar = CreateFrame("Slider", "$parentscrollBar", Gold.scrollFrame, "HybridScrollBarTemplate")
    Gold.scrollFrame.scrollBar:SetPoint("TOPLEFT", Gold.scrollFrame, "TOPRIGHT", 1, -16)
    Gold.scrollFrame.scrollBar:SetPoint("BOTTOMLEFT", Gold.scrollFrame, "BOTTOMRIGHT", 1, 12)
	--initiate the scrollFrame
    --the items we will work with
    Gold.goldList = {}
	Gold.scrollFrame.update = function() Gold:RefreshList(); end
    HybridScrollFrame_SetDoNotHideScrollBar(Gold.scrollFrame, true)
	HybridScrollFrame_CreateButtons(Gold.scrollFrame, "BagSyncListSimpleItemTemplate")

	--total counter
	goldFrame.totalText = goldFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	goldFrame.totalText:SetText("|cFFF4A460"..L.TooltipTotal.."|r  "..GetMoneyString(0, true))
	goldFrame.totalText:SetFont(STANDARD_TEXT_FONT, 12, "")
	goldFrame.totalText:SetTextColor(1, 165/255, 0)
	goldFrame.totalText:SetPoint("LEFT", goldFrame, "BOTTOMLEFT", 15, 20)
	goldFrame.totalText:SetJustifyH("LEFT")
	goldFrame.totalText:SetTextColor(1, 1, 1)

	goldFrame:Hide()
end

function Gold:OnShow()
	Gold:CreateList()
    Gold:RefreshList()

	--scroll to top when shown
	HybridScrollFrame_SetOffset(Gold.scrollFrame, 0)
	Gold.scrollFrame.scrollBar:SetValue(0)
end

function Gold:CreateList()
	Gold.goldList = {}
	local usrData = {}
	local total = 0

	for unitObj in Data:IterateUnits() do
		if unitObj.data.money and unitObj.data.money > 0 then
			if not unitObj.isGuild or (unitObj.isGuild and BSYC.options.showGuildInGoldTooltip) then
				table.insert(usrData, {
					unitObj = unitObj,
					colorized = Tooltip:ColorizeUnit(unitObj),
					sortIndex = Tooltip:GetSortIndex(unitObj),
					count = unitObj.data.money --we use count because of the DoSort() function
				})
			end
		end
	end

	if #usrData > 0 then
		usrData = Tooltip:DoSort(usrData)

		for i=1, #usrData do
			total = total + usrData[i].count
			table.insert(Gold.goldList, {
				unitObj = usrData[i].unitObj,
				colorized = usrData[i].colorized,
				sortIndex = usrData[i].sortIndex,
				count = usrData[i].count,
				moneyString = GetMoneyString(usrData[i].count, true)
			})
		end

		Gold.frame.totalText:SetText("|cFFF4A460"..L.TooltipTotal.."|r  "..GetMoneyString(total, true))
	end
end

function Gold:RefreshList()
    local items = Gold.goldList
    local buttons = HybridScrollFrame_GetButtons(Gold.scrollFrame)
    local offset = HybridScrollFrame_GetOffset(Gold.scrollFrame)
	if not buttons then return end

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
		button.parentHandler = Gold

        local itemIndex = buttonIndex + offset

        if itemIndex <= #items then
            local item = items[itemIndex]

            button:SetID(itemIndex)
			button.data = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
            button:SetWidth(Gold.scrollFrame.scrollChild:GetWidth())

			button.Text:SetJustifyH("LEFT")
			button.Text:SetTextColor(1, 1, 1)
			button.Text:SetText(item.colorized or "")
			button.Text:SetWordWrap(false)
			--set the fontstring size by using multiple setpoints to make the dimensions
			button.Text:SetPoint("LEFT", 8, 0)
			button.Text:SetPoint("RIGHT", button, -190, 0)

			button.Text2:SetJustifyH("RIGHT")
			button.Text2:SetTextColor(1, 1, 1)
			button.Text2:SetText(item.moneyString or "")
			button.HeaderHighlight:SetAlpha(0)

			if (itemIndex % 2 == 0) then
				--even
				button.Background:SetColorTexture(178/255, 190/255, 181/255, 0.10)
			else
				--odd
				button.Background:SetColorTexture(0, 0, 0, 0)
			end

			--while we are updating the scrollframe, is the mouse currently over a button?
			--if so we need to force the OnEnter as the items will scroll up in data but the button remains the same position on our cursor
			if GetMouseFocus() == button then
				Gold:Item_OnLeave() --hide first
				Gold:Item_OnEnter(button)
			end

            button:Show()
        else
            button:Hide()
        end
    end

    local buttonHeight = Gold.scrollFrame.buttonHeight
    local totalHeight = #items * buttonHeight
    local shownHeight = #buttons * buttonHeight

    HybridScrollFrame_Update(Gold.scrollFrame, totalHeight, shownHeight)
end

function Gold:Item_OnEnter(btn)
    if btn.data then
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		GameTooltip:AddLine(btn.data.colorized or "")
		GameTooltip:AddLine("|cFF3588FF"..(btn.data.unitObj.realm or "").."|r")
		GameTooltip:AddLine("|cFFFFFFFF"..(btn.data.moneyString or "").."|r")
		GameTooltip:Show()
		return
	end
	GameTooltip:Hide()
end

function Gold:Item_OnLeave()
	GameTooltip:Hide()
end