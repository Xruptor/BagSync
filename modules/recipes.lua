--[[
	recipes.lua
		A recipes frame for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...)
local UI = BSYC:GetModule("UI")
local Recipes = BSYC:NewModule("Recipes")
local Tooltip = BSYC:GetModule("Tooltip")
local Professions = BSYC:GetModule("Professions")

local L = BSYC.L

-- Cache global references for performance
local HybridScrollFrame_GetButtons = _G.HybridScrollFrame_GetButtons
local HybridScrollFrame_GetOffset = _G.HybridScrollFrame_GetOffset
local HybridScrollFrame_SetOffset = _G.HybridScrollFrame_SetOffset
local HybridScrollFrame_Update = _G.HybridScrollFrame_Update
local GameTooltip = _G.GameTooltip
local format = _G.format
local select = _G.select
local GetItemInfo = _G.GetItemInfo
local GetSpellLink = _G.GetSpellLink
local GetSpellInfo = _G.GetSpellInfo
local table_insert = _G.table.insert
local table_sort = _G.table.sort
local string_match = _G.string.match
local strsplit = _G.strsplit

-----------------------
-- Helper Functions --
-----------------------

-- Get recipe link for chat linking (handles both Classic and Retail)
local function GetRecipeLink(recipeID, isClassic, linkType)
	local numID = tonumber(recipeID)
	if not numID then return nil end

	if isClassic then
		if linkType == "enchant" then
			return format("enchant:%d", numID)
		elseif linkType == "item" then
			return select(2, _G.GetItemInfo(numID))
		else
			-- Legacy format: try item first, fall back to enchant
			local itemLink = select(2, _G.GetItemInfo(numID))
			if itemLink then
				return itemLink
			end
			return format("enchant:%d", numID)
		end
	else
		-- Retail: recipeID is a spell ID
		local spellLinkFn = (BSYC.API and BSYC.API.GetSpellLink) or (C_Spell and C_Spell.GetSpellLink) or _G.GetSpellLink
		if spellLinkFn then
			local link = spellLinkFn(numID)
			if link then
				return link
			end
		end
		-- Fallback: build a proper hyperlink if spell data is available
		local spellInfoFn = (BSYC.API and BSYC.API.GetSpellInfo) or (C_Spell and C_Spell.GetSpellInfo) or _G.GetSpellInfo
		if spellInfoFn then
			local spellName = spellInfoFn(numID)
			if spellName then
				return format("|cffffffff|Hspell:%d|h[%s]|h|r", numID, spellName)
			end
		end
		return nil
	end
end

-- Get recipe link for tooltip display (handles both Classic and Retail)
local function GetRecipeTooltipLink(recipeID, isClassic, linkType)
	local numID = tonumber(recipeID)
	if not numID then return nil end

	if isClassic then
		if linkType == "enchant" then
			return format("enchant:%d", numID)
		elseif linkType == "item" then
			local _, itemLink = GetItemInfo(numID)
			return itemLink
		else
			-- Legacy format: try item first, fall back to enchant
			local _, itemLink = GetItemInfo(numID)
			if itemLink then
				return itemLink
			end
			return format("enchant:%d", numID)
		end
	else
		-- Retail: use spell hyperlink
		return format("spell:%d", numID)
	end
end

-- Parse Classic recipe data to get display name and icon
local function ParseClassicRecipeInfo(recipeStr, getSpellInfo)
	local numericID, typeStr = string_match(recipeStr, "^(%d+):(%w+)$")
	local recipeID = numericID and tonumber(numericID) or tonumber(recipeStr)
	local linkType = typeStr
	local iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
	local recipeName

	if linkType == "enchant" then
		-- Enchanting uses spell IDs
		if getSpellInfo then
			local sName, _, sIcon = getSpellInfo(recipeID)
			if sName then
				recipeName = sName
				iconTexture = sIcon or iconTexture
			end
		end
	else
		-- Item-based profession
		local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(recipeID)
		if itemName then
			recipeName = itemName
			iconTexture = itemIcon or iconTexture
		end
	end

	return recipeID, recipeName, iconTexture, linkType
end

-- Parse Retail recipe data to get display name and icon
local function ParseRetailRecipeInfo(recipeStr, getSpellInfo, getRecipeInfo)
	local recipeID = tonumber(recipeStr)
	local iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
	local recipeName

	local recipe_info = getRecipeInfo and getRecipeInfo(recipeID) or nil
	local gName, _, gIcon
	if getSpellInfo then
		gName, _, gIcon = getSpellInfo(recipeID)
	end

	if recipe_info and recipe_info.name then
		recipeName = recipe_info.name
		iconTexture = recipe_info.icon
	elseif gName then
		recipeName = gName
		iconTexture = gIcon
	end

	return recipeID, recipeName, iconTexture
end

-- Get recipe display info with fallback
local function GetRecipeDisplayInfo(recipeID, recipeName)
	if recipeName then
		return recipeName
	end
	return "Unknown Item ("..tostring(recipeID)..")"
end

-- Build a tier header entry
local function BuildTierHeader(tierData)
	return {
		header = tierData.name,
		skillLineCurrentLevel = tierData.skillLineCurrentLevel,
		skillLineMaxLevel = tierData.skillLineMaxLevel,
		isHeader = true
	}
end

-- Build a recipe data entry
local function AddRecipeDataEntry(recipesList, recipeData)
	table_insert(recipesList, {
		tierID = recipeData.tierID,
		tierData = recipeData.tierData,
		tierIndex = recipeData.tierIndex,
		recipeName = recipeData.recipeName,
		recipeID = recipeData.recipeID,
		recipeIcon = recipeData.recipeIcon,
		linkType = recipeData.linkType,
		isClassic = recipeData.isClassic
	})
end

-- Process a single recipe category
local function ProcessRecipeCategory(category, tierID, isClassicData, getSpellInfo, getRecipeInfo, recipeData)
	if not category.recipes or category.recipes == "" then
		-- No recipes but tier is learned - add as header-only entry
		table_insert(recipeData, {
			tierID = tierID,
			tierData = category,
			tierIndex = category.orderIndex,
			recipeName = category.name,
		})
		return
	end

	local recipeList = {strsplit("|", category.recipes)}

	if #recipeList == 0 then return end

	for idx = 1, #recipeList do
		local recipeStr = recipeList[idx]
		if recipeStr and recipeStr ~= "" then

			local recipeID, recipeName, iconTexture, linkType

			if isClassicData then
				recipeID, recipeName, iconTexture, linkType = ParseClassicRecipeInfo(recipeStr, getSpellInfo)
			else
				recipeID, recipeName, iconTexture = ParseRetailRecipeInfo(recipeStr, getSpellInfo, getRecipeInfo)
			end

			recipeName = GetRecipeDisplayInfo(recipeID, recipeName)

			table_insert(recipeData, {
				tierID = tierID,
				tierData = category,
				tierIndex = category.orderIndex,
				recipeName = recipeName,
				recipeID = recipeID,
				recipeIcon = iconTexture,
				linkType = linkType,
				hasRecipes = true,
				isClassic = isClassicData
			})
		end
	end
end

-----------------------
-- Module Functions --
-----------------------

function Recipes:OnEnable()
	local recipesFrame = UI:CreateModuleFrame(Recipes, {
		template = "BagSyncFrameTemplate",
		globalName = "BagSyncRecipesFrame",
		title = "BagSync - "..L.Recipes,
		height = 500,
		width = 570,
		point = { "TOPLEFT", Professions.frame, "TOPRIGHT", 10, 0 },
		onShow = function() Recipes:OnShow() end,
	})
	Recipes.frame = recipesFrame

	recipesFrame.infoText = UI:CreateFontString(recipesFrame, {
		template = "GameFontHighlightSmall",
		text = L.ProfessionInformation,
		font = { STANDARD_TEXT_FONT, 12, "" },
		textColor = { 1, 165/255, 0 },
		point = { "LEFT", recipesFrame, "TOPLEFT", 15, -35 },
		justifyH = "CENTER",
		width = recipesFrame:GetWidth() - 15,
	})

	Recipes.scrollFrame = UI:CreateHybridScrollFrame(recipesFrame, {
		width = 527,
		pointTopLeft = { "TOPLEFT", recipesFrame, "TOPLEFT", 13, -48 },
		pointBottomLeft = { "BOTTOMLEFT", recipesFrame, "BOTTOMLEFT", -25, 15 },
		buttonTemplate = "BagSyncListItemTemplate",
		update = function() Recipes:RefreshList(); end,
	})

	Recipes.recipesList = {}
	recipesFrame:Hide()
end

function Recipes:OnShow()
	BSYC:SetBSYC_FrameLevel(Recipes)
end

function Recipes:ViewRecipes(data)
	if not data then return end
	Recipes.frame:Show()
	Recipes:CreateList(data)
	Recipes:RefreshList()

	HybridScrollFrame_SetOffset(Recipes.scrollFrame, 0)
	Recipes.scrollFrame.scrollBar:SetValue(0)
end

function Recipes:CreateList(data)
	if not data or not data.skillData or not data.skillData.categories then return end

	Recipes.recipesList = {}
	Recipes.frame.infoText:SetText(data.colorized.." | "..data.skillData.name)

	local getSpellInfo = BSYC.API and BSYC.API.GetSpellInfo
	local getRecipeInfo = BSYC.API and BSYC.API.GetRecipeInfo
	local isClassicData = data.skillData.isClassic
	local recipeData = {}

	for tierID, category in pairs(data.skillData.categories) do
		ProcessRecipeCategory(category, tierID, isClassicData, getSpellInfo, getRecipeInfo, recipeData)
	end

	if #recipeData == 0 then return end

	-- Sort by tier index, then by recipe name
	table_sort(recipeData, function(a, b)
		if a.tierIndex == b.tierIndex then
			return a.recipeName < b.recipeName
		end
		return a.tierIndex < b.tierIndex
	end)

	local lastHeader = ""
	for i = 1, #recipeData do
		local entry = recipeData[i]

		if not entry.hasRecipes or lastHeader ~= entry.tierData.name then
			table_insert(Recipes.recipesList, BuildTierHeader(entry.tierData))
			lastHeader = entry.tierData.name
		end

		if entry.hasRecipes then
			AddRecipeDataEntry(Recipes.recipesList, entry)
		end
	end
end

-- Helper to setup button for header display
local function SetupHeaderButton(button, item)
	button.Icon:SetTexture(nil)
	button.Icon:Hide()
	button.Text:SetJustifyH("CENTER")
	button.Text:SetTextColor(1, 1, 1)
	button.Text:SetText(item.header..format("   |cFF52D386[ %s / %s ]|r", item.skillLineCurrentLevel or 0, item.skillLineMaxLevel or 0))
	button.HeaderHighlight:SetAlpha(0.75)
	button.isHeader = true
end

-- Helper to setup button for recipe display
local function SetupRecipeButton(button, item)
	button.Icon:SetTexture(item.recipeIcon or nil)
	button.Icon:Show()
	button.Text:SetJustifyH("LEFT")
	button.Text:SetTextColor(0.25, 0.88, 0.82)
	button.Text:SetText(item.recipeName or "")
	button.HeaderHighlight:SetAlpha(0)
	button.isHeader = nil
end

function Recipes:RefreshList()
	local items = Recipes.recipesList
	local buttons = HybridScrollFrame_GetButtons(Recipes.scrollFrame)
	local offset = HybridScrollFrame_GetOffset(Recipes.scrollFrame)

	if not buttons then return end

	for buttonIndex = 1, #buttons do
		local button = buttons[buttonIndex]
		UI:AttachListItemHandlers(button, Recipes)

		local itemIndex = buttonIndex + offset

		if itemIndex <= #items then
			local item = items[itemIndex]
			button:SetID(itemIndex)
			button.data = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
			button:SetWidth(Recipes.scrollFrame.scrollChild:GetWidth())
			button.DetailsButton:Hide()

			if item.isHeader then
				SetupHeaderButton(button, item)
			else
				SetupRecipeButton(button, item)
			end

			if BSYC:IsMouseOver(button) then
				Recipes:Item_OnLeave()
				Recipes:Item_OnEnter(button)
			end

			button:Show()
		else
			button:Hide()
		end
	end

	local buttonHeight = Recipes.scrollFrame.buttonHeight
	local totalHeight = #items * buttonHeight
	local shownHeight = #buttons * buttonHeight

	HybridScrollFrame_Update(Recipes.scrollFrame, totalHeight, shownHeight)
end

function Recipes:Item_OnEnter(btn)
	if btn.isHeader and btn.Highlight:IsVisible() then
		btn.Highlight:Hide()
	elseif not btn.isHeader and not btn.Highlight:IsVisible() then
		btn.Highlight:Show()
	end

	if btn.isHeader then
		GameTooltip:Hide()
		return
	end

	GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")

	local tooltipLink = GetRecipeTooltipLink(btn.data.recipeID, btn.data.isClassic, btn.data.linkType)
	if tooltipLink then
		GameTooltip:SetHyperlink(tooltipLink)
	else
		GameTooltip:AddLine(btn.data.recipeName or "")
	end

	GameTooltip:Show()
end

function Recipes:Item_OnLeave()
	GameTooltip:Hide()
end

function Recipes:Item_OnClick(btn)
	if btn.isHeader or not IsModifiedClick("CHATLINK") then return end

	local link = GetRecipeLink(btn.data.recipeID, btn.data.isClassic, btn.data.linkType)
	if link then
		ChatEdit_InsertLink(link)
	end
end
