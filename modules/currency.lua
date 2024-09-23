--[[
	currency.lua
		A currency frame for BagSync

		BagSync - All Rights Reserved - (c) 2024
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Currency = BSYC:NewModule("Currency")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Currency", ...) end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

function Currency:OnEnable()
	local currencyFrame = _G.CreateFrame("Frame", nil, UIParent, "BagSyncFrameTemplate")
	Mixin(currencyFrame, Currency) --implement new frame to our parent module Mixin, to have access to parent methods
	_G["BagSyncCurrencyFrame"] = currencyFrame
    --Add to special frames so window can be closed when the escape key is pressed.
    tinsert(UISpecialFrames, "BagSyncCurrencyFrame")
    currencyFrame.TitleText:SetText("BagSync - "..L.Currency)
    currencyFrame:SetHeight(506) --irregular height to allow the scroll frame to fit the bottom most button
	currencyFrame:SetWidth(380)
    currencyFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    currencyFrame:EnableMouse(true) --don't allow clickthrough
    currencyFrame:SetMovable(true)
    currencyFrame:SetResizable(false)
    currencyFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	currencyFrame:RegisterForDrag("LeftButton")
	currencyFrame:SetClampedToScreen(true)
	currencyFrame:SetScript("OnDragStart", currencyFrame.StartMoving)
	currencyFrame:SetScript("OnDragStop", currencyFrame.StopMovingOrSizing)
	currencyFrame:SetScript("OnShow", function() Currency:OnShow() end)
	local closeBtn = CreateFrame("Button", nil, currencyFrame, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", C_EditMode and -3 or 2, C_EditMode and -3 or 1) --check for classic servers to adjust for positioning using a check for the new EditMode		
    currencyFrame.closeBtn = closeBtn
    Currency.frame = currencyFrame

    Currency.scrollFrame = _G.CreateFrame("ScrollFrame", nil, currencyFrame, "HybridScrollFrameTemplate")
    Currency.scrollFrame:SetWidth(337)
    Currency.scrollFrame:SetPoint("TOPLEFT", currencyFrame, "TOPLEFT", 13, -30)
    --set ScrollFrame height by altering the distance from the bottom of the frame
    Currency.scrollFrame:SetPoint("BOTTOMLEFT", currencyFrame, "BOTTOMLEFT", -25, 15)
    Currency.scrollFrame.scrollBar = CreateFrame("Slider", "$parentscrollBar", Currency.scrollFrame, "HybridScrollBarTemplate")
    Currency.scrollFrame.scrollBar:SetPoint("TOPLEFT", Currency.scrollFrame, "TOPRIGHT", 1, -16)
    Currency.scrollFrame.scrollBar:SetPoint("BOTTOMLEFT", Currency.scrollFrame, "BOTTOMRIGHT", 1, 12)
	--initiate the scrollFrame
    --the items we will work with
    Currency.currencies = {}
	Currency.scrollFrame.update = function() Currency:RefreshList(); end
    HybridScrollFrame_SetDoNotHideScrollBar(Currency.scrollFrame, true)
	HybridScrollFrame_CreateButtons(Currency.scrollFrame, "BagSyncListItemTemplate")

	currencyFrame:Hide()
end

function Currency:OnShow()
	BSYC:SetBSYC_FrameLevel(Currency)

	Currency:CreateList()
    Currency:RefreshList()

	--scroll to top when shown
	HybridScrollFrame_SetOffset(Currency.scrollFrame, 0)
	Currency.scrollFrame.scrollBar:SetValue(0)
end

function Currency:DoSortFilters(expName)
	if not expName then return end

	expName = expName:gsub('(%l)(%u)', '%1 %2')
	expName = expName:gsub('[%p%c%s]', '') -- remove all punctuation characters, all control characters, and all whitespace characters 
	expName = string.lower(expName)

	--now do our localized filters
	if L.CurrencySortFilters and type(L.CurrencySortFilters) == "table" then
		for e=1, #L.CurrencySortFilters do
			expName = expName:gsub("^"..L.CurrencySortFilters[e], "")
		end
	end

	return expName
end

function Currency:CreateList()
	Currency.currencies = {}
	local usrData = {}
	local tempList = {}
	local expansionList = {}

	--lets get an expansion list so we can sort the top part by expansion release
	for i=0, GetNumExpansions() do
		local eTmp = _G['EXPANSION_NAME'..i]
		eTmp = self:DoSortFilters(eTmp)

		if eTmp then
			expansionList[eTmp] = i
		end
	end

	for unitObj in Data:IterateUnits() do
		if not unitObj.isGuild and unitObj.data.currency then
			for k, v in pairs(unitObj.data.currency) do
				local header = v.header or L.Currency

				--only do the entry once per currencyID
				if not tempList[k]  then
					local sortHeader = self:DoSortFilters(header)

					table.insert(usrData, {
						header = header,
						name = v.name,
						icon = v.icon,
						currencyID = k,
						sortIndex = sortHeader and BSYC.options.sortCurrencyByExpansion and expansionList[sortHeader] or -100  --we use -100 as a filler for anything that isn't an expansion to be below lowest possible expansion
					})
					tempList[k] = true
				end
			end
		end
	end

	if #usrData > 0 then

		table.sort(usrData, function(a, b)
			if a.sortIndex == b.sortIndex then
				if a.header == b.header then
					return a.name < b.name;
				end
				return a.header < b.header;
			end
			return a.sortIndex > b.sortIndex;
		end)

		local lastHeader = ""
		for i=1, #usrData do
			if lastHeader ~= usrData[i].header then
				--add header
				table.insert(Currency.currencies, {
					header = usrData[i].header,
					isHeader = true
				})
				lastHeader = usrData[i].header
			end
			--add currency
			table.insert(Currency.currencies, {
				header = usrData[i].header,
				name = usrData[i].name,
				icon = usrData[i].icon,
				currencyID = usrData[i].currencyID
			})
		end
	end
end

function Currency:RefreshList()
    local items = Currency.currencies
    local buttons = HybridScrollFrame_GetButtons(Currency.scrollFrame)
    local offset = HybridScrollFrame_GetOffset(Currency.scrollFrame)
	if not buttons then return end

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
		button.parentHandler = Currency

        local itemIndex = buttonIndex + offset

        if itemIndex <= #items then
            local item = items[itemIndex]

            button:SetID(itemIndex)
			button.data = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
            button:SetWidth(Currency.scrollFrame.scrollChild:GetWidth())
			button.DetailsButton:Hide()

			if item.isHeader then
				button.Icon:SetTexture(nil)
				button.Icon:Hide()
				button.Text:SetJustifyH("CENTER")
				button.Text:SetTextColor(1, 1, 1)
				button.Text:SetText(item.header or "")
				--button.HeaderHighlight:SetVertexColor(0.8, 0.7, 0, 1)
				button.HeaderHighlight:SetAlpha(0.75)
				button.isHeader = true
			else
				button.Icon:SetTexture(item.icon or nil)
				button.Icon:Show()
				button.Text:SetJustifyH("LEFT")
				button.Text:SetTextColor(0.25, 0.88, 0.82)
				button.Text:SetText(item.name or "")
				button.HeaderHighlight:SetAlpha(0)
				button.isHeader = nil
			end

			--while we are updating the scrollframe, is the mouse currently over a button?
			--if so we need to force the OnEnter as the items will scroll up in data but the button remains the same position on our cursor
			if BSYC.GMF() == button then
				Currency:Item_OnLeave() --hide first
				Currency:Item_OnEnter(button)
			end

            button:Show()
        else
            button:Hide()
        end
    end

    local buttonHeight = Currency.scrollFrame.buttonHeight
    local totalHeight = #items * buttonHeight
    local shownHeight = #buttons * buttonHeight

    HybridScrollFrame_Update(Currency.scrollFrame, totalHeight, shownHeight)
end

function Currency:Item_OnEnter(btn)
	if btn.isHeader and btn.Highlight:IsVisible() then
		btn.Highlight:Hide()
	elseif not btn.isHeader and not btn.Highlight:IsVisible() then
		btn.Highlight:Show()
	end
    if not btn.isHeader then
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		Tooltip:CurrencyTooltip(GameTooltip, btn.data.name, btn.data.icon, btn.data.currencyID, "bagsync_currency")
		return
	end
	GameTooltip:Hide()
end

function Currency:Item_OnLeave()
	GameTooltip:Hide()
end