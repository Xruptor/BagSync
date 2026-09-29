--[[
	professions.lua
		A professions frame for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...) --grab the addon namespace
local UI = BSYC:GetModule("UI")
local Professions = BSYC:NewModule("Professions")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

-- Cached global references
local HybridScrollFrame_GetButtons = _G.HybridScrollFrame_GetButtons
local HybridScrollFrame_GetOffset = _G.HybridScrollFrame_GetOffset
local HybridScrollFrame_SetOffset = _G.HybridScrollFrame_SetOffset
local HybridScrollFrame_Update = _G.HybridScrollFrame_Update
local GameTooltip = _G.GameTooltip
local PLAYER = _G.PLAYER
local STANDARD_TEXT_FONT = _G.STANDARD_TEXT_FONT
local strsplit = _G.strsplit
local strlower = _G.strlower
local string_match = _G.string.match
local table_insert = _G.table.insert
local table_sort = _G.table.sort
local format = _G.format
local GetItemInfo = BSYC.API.GetItemInfo

-- Cached module reference (Recipes is optional)
local Recipes

-- Cached localization
local L = BSYC.L

-- Constants
local BUTTON_HEIGHT = 22 -- fallback, must match BagSyncListSimpleItemTemplate y="22"

--------------
-- Helpers --
--------------

-- Create sort key to flatten nested comparison
local function CreateSortKey(entry)
	return string.format("%s_%09d_%s_%s",
		entry.skillData.name,
		entry.sortIndex,
		entry.unitObj.realm,
		entry.unitObj.name
	)
end

-- Build a profession entry with all needed data
local function BuildProfessionEntry(unitObj, skillID, skillData)
	local recipeCount = tonumber(skillData.recipeCount) or 0
	local categoryCount = tonumber(skillData.categoryCount) or 0
	local hasRecipes = (recipeCount > 0) or (categoryCount > 0)
	local colorized = Tooltip:ColorizeUnit(unitObj, true, false, true, true)

	return {
		skillID = skillID,
		skillData = skillData,
		unitObj = unitObj,
		colorized = colorized,
		sortIndex = Tooltip:GetSortIndex(unitObj),
		hasRecipes = hasRecipes
	}
end

-- Build sorted profession list with headers
local function BuildSortedList(usrData)
	local result = {}
	local lastHeader = ""

	for i = 1, #usrData do
		local entry = usrData[i]
		local professionName = entry.skillData.name

		-- Add header when profession changes
		if lastHeader ~= professionName then
			table.insert(result, {
				header = professionName,
				isHeader = true
			})
			lastHeader = professionName
		end

		-- Add unit entry
		table.insert(result, entry)
	end

	return result
end

-- Build profession level text for display
local function BuildProfessionLevelText(colorized, skillData)
	if not skillData.skillLineCurrentLevel or not skillData.skillLineMaxLevel then
		return colorized .. "   " .. L.PleaseRescan
	end
	return colorized .. format("   |cFFFFFFFF%s/%s|r", skillData.skillLineCurrentLevel, skillData.skillLineMaxLevel)
end

-- Setup header button appearance
local function SetupHeaderButton(button, item)
	button.Text:SetJustifyH("CENTER")
	button.Text:SetTextColor(1, 1, 1)
	button.Text:SetText(item.header or "")
	button.HeaderHighlight:SetAlpha(0.75)
	button.isHeader = true
end

-- Setup item button appearance
local function SetupItemButton(button, item)
	button.Text:SetJustifyH("LEFT")
	button.HeaderHighlight:SetAlpha(0)
	button.isHeader = nil

	-- Check if this is a recipe search result
	if item.recipeName then
		-- Recipe search result: show character and profession info
		button.Text:SetTextColor(0.25, 0.88, 0.82)
		button.Text:SetText(item.colorized .. " - " .. item.professionName .. " (" .. item.tierName .. ")")
	else
		-- Original profession list display
		button.Text:SetTextColor(0.25, 0.88, 0.82)

		--https://warcraft.wiki.gg/wiki/TradeSkillLineID
		--allow certain ones like fishing, skinning, etc.. to have levels shown

		local allowSkill = {
			[333] = true, --enchanting
			[356] = true, --fishing
			[182] = true, --herbalism
			[186] = true, --mining
			[393] = true, --skinning
			[794] = true, --archaeology
			[129] = true, --first aid
		}

		-- Display profession level info if no recipes
		if not item.hasRecipes or allowSkill[item.skillID] then
			button.Text:SetText(BuildProfessionLevelText(item.colorized, item.skillData))
		else
			button.Text:SetText(item.colorized)
		end
	end
end

--------------------
-- Main Functions --
--------------------

function Professions:OnEnable()
	local professionsFrame = UI:CreateModuleFrame(Professions, {
		template = "BagSyncFrameTemplate",
		globalName = "BagSyncProfessionsFrame",
		title = "BagSync - "..L.Professions,
		height = 506, --irregular height to allow the scroll frame to fit the bottom most button
		width = 380,
		point = { "CENTER", UIParent, "CENTER", 0, 0 },
		onShow = function() Professions:OnShow() end,
	})
	Professions.frame = professionsFrame

	professionsFrame.infoText = UI:CreateFontString(professionsFrame, {
		template = "GameFontHighlightSmall",
		text = L.ProfessionInformation,
		font = { STANDARD_TEXT_FONT, 12, "" },
		textColor = { 1, 165/255, 0 },
		point = { "LEFT", professionsFrame, "TOPLEFT", 15, -35 },
		justifyH = "LEFT",
		width = professionsFrame:GetWidth() - 15,
	})

	-- Add recipe search box
	professionsFrame.recipeSearchBox = UI:CreateEditBox(professionsFrame, {
		template = "InputBoxTemplate",
		size = { 200, 20 },
		point = { "TOPLEFT", professionsFrame, "TOPLEFT", 13, -48 },
		autoFocus = false,
	})
	
	-- Add search box placeholder text
	professionsFrame.searchPlaceholder = UI:CreateFontString(professionsFrame, {
		template = "GameFontDisable",
		text = L.RecipeSearchBoxPlaceholder or "Search recipes...",
		font = { STANDARD_TEXT_FONT, 11, "" },
		point = { "LEFT", professionsFrame.recipeSearchBox, "LEFT", 8, 0 },
		justifyH = "LEFT",
	})
	
	-- Hide/show placeholder when search box text changes
	professionsFrame.recipeSearchBox:SetScript("OnTextChanged", function(self)
		local text = self:GetText()
		if text and text ~= "" then
			professionsFrame.searchPlaceholder:Hide()
		else
			professionsFrame.searchPlaceholder:Show()
		end
	end)
	
	-- Search on Enter key press
	professionsFrame.recipeSearchBox:SetScript("OnEnterPressed", function(self)
		Professions:SearchAllRecipes()
		self:ClearFocus()
	end)

	-- Add recipe search button
	professionsFrame.recipeSearchBtn = UI:CreateButton(professionsFrame, {
		template = "UIPanelButtonTemplate",
		text = L.Search or "Search",
		width = 80,
		height = 20,
		point = { "LEFT", professionsFrame.recipeSearchBox, "RIGHT", 5, 0 },
		onClick = function() Professions:SearchAllRecipes() end,
	})

	-- Add clear search button
	professionsFrame.clearSearchBtn = UI:CreateButton(professionsFrame, {
		template = "UIPanelButtonTemplate",
		text = L.Reset or "Reset",
		width = 60,
		height = 20,
		point = { "LEFT", professionsFrame.recipeSearchBtn, "RIGHT", 5, 0 },
		onClick = function() Professions:ClearRecipeSearch() end,
	})

	Professions.scrollFrame = UI:CreateHybridScrollFrame(professionsFrame, {
		width = 337,
		pointTopLeft = { "TOPLEFT", professionsFrame, "TOPLEFT", 13, -75 },
		-- set ScrollFrame height by altering the distance from the bottom of the frame
		pointBottomLeft = { "BOTTOMLEFT", professionsFrame, "BOTTOMLEFT", -25, 15 },
		buttonTemplate = "BagSyncListSimpleItemTemplate",
		update = function() Professions:RefreshList(); end,
	})
	--the items we will work with
	Professions.professionList = {}

	professionsFrame:Hide()
end

function Professions:OnShow()
	BSYC:SetBSYC_FrameLevel(Professions)

	Professions:CreateList()
	Professions:RefreshList()

	--scroll to top when shown
	HybridScrollFrame_SetOffset(Professions.scrollFrame, 0)
	Professions.scrollFrame.scrollBar:SetValue(0)
end

function Professions:CreateList()
	local usrData = {}

	-- Collect profession data from all units
	for unitObj in Data:IterateUnits() do
		if not unitObj.isGuild and unitObj.data.professions then
			for skillID, skillData in pairs(unitObj.data.professions) do
				if skillData.name then
					table.insert(usrData, BuildProfessionEntry(unitObj, skillID, skillData))
				end
			end
		end
	end

	-- Sort by profession name, then sort index, then realm, then name
	if #usrData > 0 then
		table.sort(usrData, function(a, b)
			return CreateSortKey(a) < CreateSortKey(b)
		end)

		-- Build sorted list with headers
		Professions.professionList = BuildSortedList(usrData)
	else
		Professions.professionList = {}
	end
end

function Professions:RefreshList()
	local items = Professions.professionList
	local scrollFrame = Professions.scrollFrame
	local buttons = HybridScrollFrame_GetButtons(scrollFrame)
	local offset = HybridScrollFrame_GetOffset(scrollFrame)

	if not buttons then return end

	local fontCached = false

	for buttonIndex = 1, #buttons do
		local button = buttons[buttonIndex]
		UI:AttachListItemHandlers(button, Professions)

		local itemIndex = buttonIndex + offset

		if itemIndex <= #items then
			local item = items[itemIndex]

			button:SetID(itemIndex)
			button.data = item

			-- Only set font once (it's the same for all buttons)
			if not fontCached then
				button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
				fontCached = true
			end

			button:SetWidth(scrollFrame.scrollChild:GetWidth())

			-- Setup button based on type
			if item.isHeader then
				SetupHeaderButton(button, item)
			else
				SetupItemButton(button, item)
			end

			--while we are updating the scrollframe, is the mouse currently over a button?
			--if so we need to force the OnEnter as the items will scroll up in data but the button remains the same position on our cursor
			if BSYC:IsMouseOver(button) then
				Professions:Item_OnLeave() --hide first
				Professions:Item_OnEnter(button)
			end

			button:Show()
		else
			button:Hide()
		end
	end

	local buttonHeight = scrollFrame.buttonHeight or BUTTON_HEIGHT
	local totalHeight = #items * buttonHeight
	local shownHeight = #buttons * buttonHeight

	HybridScrollFrame_Update(scrollFrame, totalHeight, shownHeight)
end

function Professions:Item_OnEnter(btn)
	if btn.isHeader and btn.Highlight:IsVisible() then
		btn.Highlight:Hide()
	elseif not btn.isHeader and not btn.Highlight:IsVisible() then
		btn.Highlight:Show()
	end

	if not btn.isHeader then
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		
		-- Check if this is a recipe search result
		if btn.data.recipeName then
			-- Tooltip for recipe search result
			GameTooltip:AddLine("|cFFFFFFFF"..PLAYER..":|r  "..btn.data.colorized)
			GameTooltip:AddLine("|cFFFFFFFF"..L.Realm.."|r  "..btn.data.unitRealm)
			GameTooltip:AddLine("|cFFFFFFFF"..L.Professions..":|r  "..btn.data.professionName)
			GameTooltip:AddLine(" ")
			
			-- Show recipe info
			if btn.data.recipeID then
				local tooltipLink
				if btn.data.isClassic then
					if btn.data.linkType == "enchant" then
						tooltipLink = format("enchant:%d", btn.data.recipeID)
					else
						local _, itemLink = GetItemInfo(btn.data.recipeID)
						tooltipLink = itemLink
					end
				else
					-- Retail: use spell hyperlink
					tooltipLink = format("spell:%d", btn.data.recipeID)
				end
				
				if tooltipLink then
					GameTooltip:SetHyperlink(tooltipLink)
				else
					GameTooltip:AddLine(btn.data.recipeName or "")
				end
			end
		else
			-- Original profession list tooltip
			GameTooltip:AddLine("|cFFFFFFFF"..PLAYER..":|r  "..btn.data.colorized)
			GameTooltip:AddLine("|cFFFFFFFF"..L.Realm.."|r  "..btn.data.unitObj.realm)
			GameTooltip:AddLine("|cFFFFFFFF"..L.TooltipRealmKey.."|r "..(btn.data.unitObj.data.realmKey or "?"))
			GameTooltip:AddLine(" ")

			if btn.data.hasRecipes then
				GameTooltip:AddLine("|cFF4DD827"..L.ProfessionHasRecipes.."|r")
			else
				GameTooltip:AddLine("|cFFFF3C38"..L.ProfessionHasNoRecipes.."|r")
			end
		end
		GameTooltip:Show()
		return
	end
	GameTooltip:Hide()
end

function Professions:Item_OnLeave()
	GameTooltip:Hide()
end

function Professions:Item_OnClick(btn)
	if not btn.isHeader and btn.data.hasRecipes then
		Recipes = Recipes or BSYC:GetModule("Recipes", true)
		if Recipes and Recipes.ViewRecipes then
			Recipes:ViewRecipes(btn.data)
		end
	end
end

------------------------------------------------------------
-- RECIPE SEARCH
------------------------------------------------------------

function Professions:SearchAllRecipes()
	local searchText = self.frame.recipeSearchBox:GetText()
	if not searchText or searchText == "" then return end

	-- Clear the list
	Professions.professionList = {}

	local results = {}
	local getSpellInfo = BSYC.API and BSYC.API.GetSpellInfo
	local getRecipeInfo = BSYC.API and BSYC.API.GetRecipeInfo

	-- Iterate over all characters
	for unitObj in Data:IterateUnits() do
		if not unitObj.isGuild and unitObj.data.professions then
			-- Iterate over all professions for this character
			for skillID, skillData in pairs(unitObj.data.professions) do
				if skillData and skillData.categories then
					-- Iterate over all categories for this profession
					for tierID, category in pairs(skillData.categories) do
						if category.recipes and category.recipes ~= "" then
							-- Parse the recipe list
							local recipeList = {strsplit("|", category.recipes)}
							for _, recipeStr in ipairs(recipeList) do
								if recipeStr and recipeStr ~= "" then
									local recipeID, recipeName, iconTexture, linkType, isClassic

									-- Determine if this is Classic or Retail
									if skillData.isClassic then
										-- Classic format: "id:type"
										local numericID, typeStr = string_match(recipeStr, "^(%d+):(%w+)$")
										recipeID = numericID and tonumber(numericID) or tonumber(recipeStr)
										linkType = typeStr

										if linkType == "enchant" then
											-- Enchant uses spell ID
											if getSpellInfo then
												local sName, _, sIcon = getSpellInfo(recipeID)
												if sName then
													recipeName = sName
													iconTexture = sIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
												end
											end
										else
											-- Item ID
											local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(recipeID)
											if itemName then
												recipeName = itemName
												iconTexture = itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
											end
										end
										isClassic = true
									else
										-- Retail: recipeID is the spellID
										recipeID = tonumber(recipeStr)
										linkType = nil
										isClassic = false

										-- Try to get recipe info
										local recipe_info = getRecipeInfo and getRecipeInfo(recipeID)
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
									end

									-- If no name was retrieved, use a placeholder
									if not recipeName then
										recipeName = "Unknown Recipe ("..tostring(recipeID)..")"
									end

									-- Match search keyword (case-insensitive)
									local searchLower = strlower(searchText)
									if recipeName and strlower(recipeName):find(searchLower, 1, true) then
										table_insert(results, {
											recipeName = recipeName,
											recipeID = recipeID,
											recipeIcon = iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark",
											linkType = linkType,
											isClassic = isClassic,
											professionName = skillData.name,
											unitName = unitObj.name,
											unitRealm = unitObj.realm,
											colorized = Tooltip:ColorizeUnit(unitObj, true, false, true, true),
											tierName = category.name,
										})
									end
								end
							end
						end
					end
				end
			end
		end
	end

	-- Sort by recipe name
	if #results > 0 then
		table_sort(results, function(a, b)
			return a.recipeName < b.recipeName
		end)

		-- Convert to list format (add separator headers)
		local lastName = ""
		for i = 1, #results do
			local entry = results[i]

			-- Add recipe name as header (shown once per unique recipe)
			if lastName ~= entry.recipeName then
				table_insert(Professions.professionList, {
					header = entry.recipeName,
					isHeader = true,
				})
				lastName = entry.recipeName
			end

			-- Add character entry
			table_insert(Professions.professionList, {
				recipeName = entry.recipeName,
				recipeID = entry.recipeID,
				recipeIcon = entry.recipeIcon,
				linkType = entry.linkType,
				isClassic = entry.isClassic,
				professionName = entry.professionName,
				unitName = entry.unitName,
				unitRealm = entry.unitRealm,
				colorized = entry.colorized,
				tierName = entry.tierName,
				isHeader = false,
			})
		end
	end

	-- Update display
	Professions:RefreshList()

	-- Show result count
	local count = #results
	if count > 0 then
		self.frame.infoText:SetText(format(L.RecipeSearchResults or "Found %d recipes", count))
	else
		self.frame.infoText:SetText(L.RecipeSearchNoResults or "No recipes found")
	end
end

function Professions:ClearRecipeSearch()
	self.frame.recipeSearchBox:SetText("")
	self.frame.searchPlaceholder:Show()
	Professions.professionList = {}
	self.frame.infoText:SetText(L.ProfessionInformation)

	-- Reload the profession list
	Professions:CreateList()
	Professions:RefreshList()
end
