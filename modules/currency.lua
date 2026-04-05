--[[
	currency.lua
		A currency frame for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...) --grab the addon namespace
local UI = BSYC:GetModule("UI")
local Currency = BSYC:NewModule("Currency")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local L = BSYC.L

-- Cache global references
local HybridScrollFrame_GetButtons = HybridScrollFrame_GetButtons
local HybridScrollFrame_GetOffset = HybridScrollFrame_GetOffset
local HybridScrollFrame_SetOffset = HybridScrollFrame_SetOffset
local HybridScrollFrame_Update = HybridScrollFrame_Update
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT
local GameTooltip = GameTooltip
local GetNumExpansions = GetNumExpansions
local table_insert = table.insert
local strlower = string.lower

function Currency:OnEnable()
	local currencyFrame = UI:CreateModuleFrame(Currency, {
		template = "BagSyncFrameTemplate",
		globalName = "BagSyncCurrencyFrame",
		title = "BagSync - "..L.Currency,
		height = 506,
		width = 380,
		point = { "CENTER", UIParent, "CENTER", 0, 0 },
		onShow = function() Currency:OnShow() end,
	})
	Currency.frame = currencyFrame

	Currency.scrollFrame = UI:CreateHybridScrollFrame(currencyFrame, {
		width = 337,
		pointTopLeft = { "TOPLEFT", currencyFrame, "TOPLEFT", 13, -30 },
		pointBottomLeft = { "BOTTOMLEFT", currencyFrame, "BOTTOMLEFT", -25, 15 },
		buttonTemplate = "BagSyncListItemTemplate",
		update = function() Currency:RefreshList() end,
	})
	Currency.currencies = {}

	currencyFrame:Hide()
end

function Currency:OnShow()
	BSYC:SetBSYC_FrameLevel(Currency)

	Currency:CreateList()
	Currency:RefreshList()

	HybridScrollFrame_SetOffset(Currency.scrollFrame, 0)
	Currency.scrollFrame.scrollBar:SetValue(0)
end

function Currency:DoSortFilters(expName)
	if not expName then return end

	expName = expName:gsub('(%l)(%u)', '%1 %2')
	expName = expName:gsub('[%p%c%s]', '')
	expName = strlower(expName)

	-- Use localized filters - no type check needed as we only run this loop if L.CurrencySortFilters exists
	if L.CurrencySortFilters then
		for e = 1, #L.CurrencySortFilters do
			expName = expName:gsub("^"..L.CurrencySortFilters[e], "")
		end
	end

	return expName
end

-- Build an index of expansion names to their numeric IDs for sorting
function Currency:BuildExpansionIndex()
	local expansionList = {}

	for i = 0, GetNumExpansions() do
		local eTmp = _G['EXPANSION_NAME'..i]
		eTmp = self:DoSortFilters(eTmp)

		if eTmp then
			expansionList[eTmp] = i
		end
	end

	return expansionList
end

-- Create a currency entry table for sorting
function Currency:CreateCurrencyEntry(k, v, expansionList, sortByExpansion)
	local header = v.header or L.Currency
	local sortHeader = self:DoSortFilters(header)
	local sortIndex = sortHeader and sortByExpansion and expansionList[sortHeader] or -100

	return {
		header = header,
		name = v.name,
		icon = v.icon,
		currencyID = k,
		sortIndex = sortIndex
	}
end

-- Build the sorted list of currencies with headers
function Currency:BuildSortedCurrencyList(usrData)
	if #usrData == 0 then return end

	table.sort(usrData, function(a, b)
		if a.sortIndex == b.sortIndex then
			if a.header == b.header then
				return a.name < b.name
			end
			return a.header < b.header
		end
		return a.sortIndex > b.sortIndex
	end)

	local lastHeader = ""
	for i = 1, #usrData do
		if lastHeader ~= usrData[i].header then
			table_insert(Currency.currencies, {
				header = usrData[i].header,
				isHeader = true
			})
			lastHeader = usrData[i].header
		end
		table_insert(Currency.currencies, {
			header = usrData[i].header,
			name = usrData[i].name,
			icon = usrData[i].icon,
			currencyID = usrData[i].currencyID
		})
	end
end

function Currency:CreateList()
	Currency.currencies = {}
	local usrData = {}
	local tempList = {}
	local expansionList = self:BuildExpansionIndex()
	local sortByExpansion = BSYC.options.sortCurrencyByExpansion

	for unitObj in Data:IterateUnits() do
		if not unitObj.isGuild and unitObj.data.currency then
			for k, v in pairs(unitObj.data.currency) do
				-- Skip currencies with zero or negative counts
				if v.count and v.count > 0 then
					if not tempList[k] then
						table_insert(usrData, self:CreateCurrencyEntry(k, v, expansionList, sortByExpansion))
						tempList[k] = true
					end
				end
			end
		end
	end

	self:BuildSortedCurrencyList(usrData)
end

-- Setup button for header items
function Currency:SetupButtonForHeader(button, item)
	button.Icon:SetTexture(nil)
	button.Icon:Hide()
	button.Text:SetJustifyH("CENTER")
	button.Text:SetTextColor(1, 1, 1)
	button.Text:SetText(item.header or "")
	button.HeaderHighlight:SetAlpha(0.75)
	button.isHeader = true
end

-- Setup button for currency items
function Currency:SetupButtonForCurrency(button, item)
	button.Icon:SetTexture(item.icon)
	button.Icon:Show()
	button.Text:SetJustifyH("LEFT")
	button.Text:SetTextColor(0.25, 0.88, 0.82)
	button.Text:SetText(item.name or "")
	button.HeaderHighlight:SetAlpha(0)
	button.isHeader = nil
end

function Currency:RefreshList()
	local items = Currency.currencies
	local buttons = HybridScrollFrame_GetButtons(Currency.scrollFrame)
	local offset = HybridScrollFrame_GetOffset(Currency.scrollFrame)

	if not buttons then return end

	for buttonIndex = 1, #buttons do
		local button = buttons[buttonIndex]
		UI:AttachListItemHandlers(button, Currency)

		local itemIndex = buttonIndex + offset

		if itemIndex <= #items then
			local item = items[itemIndex]

			button:SetID(itemIndex)
			button.data = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
			button:SetWidth(Currency.scrollFrame.scrollChild:GetWidth())
			button.DetailsButton:Hide()

			if item.isHeader then
				self:SetupButtonForHeader(button, item)
			else
				self:SetupButtonForCurrency(button, item)
			end

			-- Force tooltip refresh if mouse is over button during scroll
			if BSYC:IsMouseOver(button) then
				Currency:Item_OnLeave()
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
