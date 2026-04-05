--[[
	gold.lua
		A frame displaying all database character gold totals for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...) --grab the addon namespace
local UI = BSYC:GetModule("UI")
local Gold = BSYC:NewModule("Gold")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

-- Cache global references for performance
local HybridScrollFrame_GetButtons = HybridScrollFrame_GetButtons
local HybridScrollFrame_GetOffset = HybridScrollFrame_GetOffset
local HybridScrollFrame_SetOffset = HybridScrollFrame_SetOffset
local HybridScrollFrame_Update = HybridScrollFrame_Update
local GameTooltip = GameTooltip
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT
local floor = math.floor
local mod = math.fmod or math.mod or function(a, b) return a % b end
local t_unpack = table.unpack or unpack

-- Currency constants
local COPPER_PER_SILVER = _G.COPPER_PER_SILVER or 100
local SILVER_PER_GOLD = _G.SILVER_PER_GOLD or 100
local GOLD_AMOUNT_TEXTURE = _G.GOLD_AMOUNT_TEXTURE
local GOLD_AMOUNT_TEXTURE_STRING = _G.GOLD_AMOUNT_TEXTURE_STRING
local SILVER_AMOUNT_TEXTURE = _G.SILVER_AMOUNT_TEXTURE
local COPPER_AMOUNT_TEXTURE = _G.COPPER_AMOUNT_TEXTURE
local FormatLargeNumber = _G.FormatLargeNumber or _G.AbbreviateNumbers

local L = BSYC.L

function Gold:OnEnable()
	local goldFrame = UI:CreateModuleFrame(Gold, {
		template = "BagSyncFrameTemplate",
		globalName = "BagSyncGoldFrame",
		title = "BagSync - "..L.Gold,
		height = 506,
		width = 440,
		point = { "CENTER", UIParent, "CENTER", 0, 0 },
		onShow = function() Gold:OnShow() end,
	})
	Gold.frame = goldFrame

	Gold.scrollFrame = UI:CreateHybridScrollFrame(goldFrame, {
		width = 397,
		pointTopLeft = { "TOPLEFT", goldFrame, "TOPLEFT", 13, -29 },
		-- set ScrollFrame height by altering the distance from the bottom of the frame
		pointBottomLeft = { "BOTTOMLEFT", goldFrame, "BOTTOMLEFT", -25, 37 },
		buttonTemplate = "BagSyncListSimpleItemTemplate",
		update = function() Gold:RefreshList() end,
	})
	--the items we will work with
	Gold.goldList = {}

	--total counter
	goldFrame.totalText = UI:CreateFontString(goldFrame, {
		template = "GameFontHighlightSmall",
		text = "|cFFF4A460"..L.TooltipTotal.."|r  "..GetMoneyString(0, true),
		font = { STANDARD_TEXT_FONT, 12, "" },
		textColor = { 1, 165/255, 0 },
		point = { "LEFT", goldFrame, "BOTTOMLEFT", 15, 20 },
		justifyH = "LEFT",
	})
	goldFrame.totalText:SetTextColor(1, 1, 1)

	goldFrame:Hide()
end

function Gold:OnShow()
	BSYC:SetBSYC_FrameLevel(Gold)

	Gold:CreateList()
	Gold:RefreshList()

	--scroll to top when shown
	HybridScrollFrame_SetOffset(Gold.scrollFrame, 0)
	Gold.scrollFrame.scrollBar:SetValue(0)
end

--this is a modified version of GetMoneyString from FormattingUtil.lua found in the Blizzard code
--I wanted something that only displayed the gold if found, otherwise display the rest

-- Helper to build individual currency texture strings
local function BuildCurrencyTextures(gold, silver, copper, separateThousands)
	local goldString = separateThousands
		and GOLD_AMOUNT_TEXTURE_STRING:format(FormatLargeNumber(gold), 0, 0)
		or GOLD_AMOUNT_TEXTURE:format(gold, 0, 0)
	local silverString = SILVER_AMOUNT_TEXTURE:format(silver, 0, 0)
	local copperString = COPPER_AMOUNT_TEXTURE:format(copper, 0, 0)
	return goldString, silverString, copperString
end

local function CustomMoneyString(money, separateThousands, showAll)
	local gold = floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD))
	local silver = floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = mod(money, COPPER_PER_SILVER)

	-- Early return: only gold and not showing all currencies
	if gold > 0 and not showAll then
		return (separateThousands
			and GOLD_AMOUNT_TEXTURE_STRING:format(FormatLargeNumber(gold), 0, 0)
			or GOLD_AMOUNT_TEXTURE:format(gold, 0, 0))
	end

	local goldString, silverString, copperString = BuildCurrencyTextures(gold, silver, copper, separateThousands)
	local parts = {}

	if gold > 0 then
		table.insert(parts, goldString)
	end
	if silver > 0 then
		table.insert(parts, silverString)
	end
	if copper > 0 or #parts == 0 then
		table.insert(parts, copperString)
	end

	return table.concat(parts, " ")
end

-- Helper to build a gold list entry
local function BuildGoldEntry(unitObj, colorizeArgs)
	return {
		unitObj = unitObj,
		colorized = Tooltip:ColorizeUnit(unitObj, true, false, t_unpack(colorizeArgs)),
		sortIndex = Tooltip:GetSortIndex(unitObj),
		count = unitObj.data.money
	}
end

function Gold:CreateList()
	local goldList = {}
	local total = 0

	for unitObj in Data:IterateUnits() do
		if unitObj.data.money and unitObj.data.money > 0 then
			if not unitObj.isGuild or (unitObj.isGuild and BSYC.tracking.guild and BSYC.options.showGuildInGoldTooltip) then
				goldList[#goldList + 1] = BuildGoldEntry(unitObj, {true, true})
			end
		end
	end

	--add warband
	local warbandObj = Data:GetWarbandBankObj()
	if warbandObj then
		goldList[#goldList + 1] = BuildGoldEntry(warbandObj, {false, false})
	end

	if #goldList > 0 then
		goldList = Tooltip:DoSort(goldList)

		for i = 1, #goldList do
			local entry = goldList[i]
			total = total + entry.count
			entry.moneyString = CustomMoneyString(entry.count, true, BSYC.options.enable_GSC_Display)
		end

		Gold.frame.totalText:SetText("|cFFF4A460"..L.TooltipTotal.."|r  "..GetMoneyString(total, true))
	end

	Gold.goldList = goldList
end

-- Helper to setup button appearance for an item
local function SetupButton(button, item, itemIndex, scrollFrameWidth)
	button:SetID(itemIndex)
	button.data = item
	button:SetWidth(scrollFrameWidth)

	-- Setup Text (character name)
	button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
	button.Text:SetJustifyH("LEFT")
	button.Text:SetTextColor(1, 1, 1)
	button.Text:SetText(item.colorized or "")
	button.Text:SetWordWrap(false)
	button.Text:SetPoint("LEFT", 8, 0)
	button.Text:SetPoint("RIGHT", button, -150, 0)

	-- Setup Text2 (money amount)
	button.Text2:SetJustifyH("RIGHT")
	button.Text2:SetTextColor(1, 1, 1)
	button.Text2:SetText(item.moneyString or "")

	button.HeaderHighlight:SetAlpha(0)

	-- Alternating row colors
	if itemIndex % 2 == 0 then
		button.Background:SetColorTexture(178/255, 190/255, 181/255, 0.10)
	else
		button.Background:SetColorTexture(0, 0, 0, 0)
	end
end

function Gold:RefreshList()
	local items = Gold.goldList
	local buttons = HybridScrollFrame_GetButtons(Gold.scrollFrame)
	local offset = HybridScrollFrame_GetOffset(Gold.scrollFrame)
	if not buttons then return end

	for buttonIndex = 1, #buttons do
		local button = buttons[buttonIndex]
		UI:AttachListItemHandlers(button, Gold)

		local itemIndex = buttonIndex + offset

		if itemIndex <= #items then
			local item = items[itemIndex]
			SetupButton(button, item, itemIndex, Gold.scrollFrame.scrollChild:GetWidth())

			--while we are updating the scrollframe, is the mouse currently over a button?
			--if so we need to force the OnEnter as the items will scroll up in data but the button remains the same position on our cursor
			if BSYC:IsMouseOver(button) then
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
	if not btn.data then
		GameTooltip:Hide()
		return
	end

	GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
	GameTooltip:AddLine(btn.data.colorized or "")
	if not btn.data.unitObj.isWarbandBank then
		GameTooltip:AddLine("|cFFF4A460"..(btn.data.unitObj.realm or "").."|r")
	end
	GameTooltip:AddLine("|cFFFFFFFF"..CustomMoneyString(btn.data.count or 0, true, true).."|r")
	GameTooltip:Show()
end

function Gold:Item_OnLeave()
	GameTooltip:Hide()
end
