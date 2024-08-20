--[[
	recipes.lua
		A recipes frame for BagSync

		BagSync - All Rights Reserved - (c) 2024
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Recipes = BSYC:NewModule("Recipes")
local Tooltip = BSYC:GetModule("Tooltip")
local Professions = BSYC:GetModule("Professions")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Recipes", ...) end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

function Recipes:OnEnable()
	local recipesFrame = _G.CreateFrame("Frame", nil, UIParent, "BagSyncFrameTemplate")
	Mixin(recipesFrame, Recipes) --implement new frame to our parent module Mixin, to have access to parent methods
	_G["BagSyncRecipesFrame"] = recipesFrame
    --Add to special frames so window can be closed when the escape key is pressed.
    tinsert(UISpecialFrames, "BagSyncRecipesFrame")
    recipesFrame.TitleText:SetText("BagSync - "..L.Recipes)
    recipesFrame:SetHeight(500)
	recipesFrame:SetWidth(570)
    recipesFrame:SetPoint("TOPLEFT", Professions.frame, "TOPRIGHT", 10, 0)
    recipesFrame:EnableMouse(true) --don't allow clickthrough
    recipesFrame:SetMovable(true)
    recipesFrame:SetResizable(false)
    recipesFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	recipesFrame:RegisterForDrag("LeftButton")
	recipesFrame:SetClampedToScreen(true)
	recipesFrame:SetScript("OnDragStart", recipesFrame.StartMoving)
	recipesFrame:SetScript("OnDragStop", recipesFrame.StopMovingOrSizing)
	recipesFrame:SetScript("OnShow", function() Recipes:OnShow() end)
	local closeBtn = CreateFrame("Button", nil, recipesFrame, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", C_EditMode and -3 or 2, C_EditMode and -3 or 1) --check for classic servers to adjust for positioning using a check for the new EditMode			
    recipesFrame.closeBtn = closeBtn
	Recipes.frame = recipesFrame

	recipesFrame.infoText = recipesFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	recipesFrame.infoText:SetText(L.ProfessionInformation)
	recipesFrame.infoText:SetFont(STANDARD_TEXT_FONT, 12, "")
	recipesFrame.infoText:SetTextColor(1, 165/255, 0)
	recipesFrame.infoText:SetPoint("LEFT", recipesFrame, "TOPLEFT", 15, -35)
	recipesFrame.infoText:SetJustifyH("CENTER")
	recipesFrame.infoText:SetWidth(recipesFrame:GetWidth() - 15)

    Recipes.scrollFrame = _G.CreateFrame("ScrollFrame", nil, recipesFrame, "HybridScrollFrameTemplate")
    Recipes.scrollFrame:SetWidth(527)
    Recipes.scrollFrame:SetPoint("TOPLEFT", recipesFrame, "TOPLEFT", 13, -48)
    --set ScrollFrame height by altering the distance from the bottom of the frame
    Recipes.scrollFrame:SetPoint("BOTTOMLEFT", recipesFrame, "BOTTOMLEFT", -25, 15)
    Recipes.scrollFrame.scrollBar = CreateFrame("Slider", "$parentscrollBar", Recipes.scrollFrame, "HybridScrollBarTemplate")
    Recipes.scrollFrame.scrollBar:SetPoint("TOPLEFT", Recipes.scrollFrame, "TOPRIGHT", 1, -16)
    Recipes.scrollFrame.scrollBar:SetPoint("BOTTOMLEFT", Recipes.scrollFrame, "BOTTOMRIGHT", 1, 12)
	--initiate the scrollFrame
    --the items we will work with
    Recipes.recipesList = {}
	Recipes.scrollFrame.update = function() Recipes:RefreshList(); end
    HybridScrollFrame_SetDoNotHideScrollBar(Recipes.scrollFrame, true)
	HybridScrollFrame_CreateButtons(Recipes.scrollFrame, "BagSyncListItemTemplate")

	recipesFrame:Hide()
end

function Recipes:OnShow()
	BSYC:SetBSYC_FrameLevel(Recipes)
end

function Recipes:ViewRecipes(data)
	Recipes.frame:Show()
	Recipes:CreateList(data)
    Recipes:RefreshList()

	--scroll to top when shown
	HybridScrollFrame_SetOffset(Recipes.scrollFrame, 0)
	Recipes.scrollFrame.scrollBar:SetValue(0)
end


function Recipes:CreateList(data)
	if not data then return end
	if not data.skillData.categories then return end

	Recipes.recipesList = {}
	Recipes.frame.infoText:SetText(data.colorized.." | "..data.skillData.name)

	local xGetSpellInfo = C_Spell and C_Spell.GetSpellInfo or GetSpellInfo
	local recipeData = {}

	for k, v in pairs(data.skillData.categories) do
		if v.recipes then
			local recipeList = {strsplit("|", v.recipes)}

			if #recipeList > 0 then
				for idx = 1, #recipeList do
					if recipeList[idx] and string.len(recipeList[idx]) > 0 then
						local recipe_info = _G.C_TradeSkillUI.GetRecipeInfo(recipeList[idx])
						local recipeName = recipeList[idx]
						local iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark"

						local gName, _, gIcon = xGetSpellInfo(recipeList[idx])

						if recipe_info and recipe_info.name then
							recipeName = recipe_info.name
							iconTexture = recipe_info.icon
						elseif gName then
							recipeName = gName
							iconTexture = gIcon
						else
							recipeName = L.RecipesFailedRequest:format(recipeList[idx])
						end

						table.insert(recipeData, {
							tierID = k,
							tierData = v,
							tierIndex = v.orderIndex,
							recipeName = recipeName,
							recipeID = recipeList[idx],
							recipeIcon = iconTexture,
							hasRecipes = true
						})
					end
				end
			end
		else
			--we have no recipes but the tier is learned and is leveled.  So display it as a header (don't pass hasRecipes)
			table.insert(recipeData, {
				tierID = k,
				tierData = v,
				tierIndex = v.orderIndex,
				recipeName = v.name,
			})
		end
	end

	if #recipeData > 0 then
		table.sort(recipeData, function(a, b)
			if a.tierIndex  == b.tierIndex then
				return a.recipeName < b.recipeName;
			end
			return a.tierIndex < b.tierIndex;
		end)

		local lastHeader = ""
		for i=1, #recipeData do
			if not recipeData[i].hasRecipes or lastHeader ~= recipeData[i].tierData.name then
				--add header
				table.insert(Recipes.recipesList, {
					header = recipeData[i].tierData.name,
					skillLineCurrentLevel = recipeData[i].tierData.skillLineCurrentLevel,
					skillLineMaxLevel = recipeData[i].tierData.skillLineMaxLevel,
					isHeader = true
				})
				lastHeader = recipeData[i].tierData.name
			end
			if recipeData[i].hasRecipes then
				--only add recipe data if we have recipes to work with
				table.insert(Recipes.recipesList, {
					tierID = recipeData[i].tierID,
					tierData = recipeData[i].tierData,
					tierIndex = recipeData[i].tierIndex,
					recipeName = recipeData[i].recipeName,
					recipeID = recipeData[i].recipeID,
					recipeIcon = recipeData[i].recipeIcon
				})
			end
		end
	end
end

function Recipes:RefreshList()
    local items = Recipes.recipesList
    local buttons = HybridScrollFrame_GetButtons(Recipes.scrollFrame)
    local offset = HybridScrollFrame_GetOffset(Recipes.scrollFrame)
	if not buttons then return end

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
		button.parentHandler = Recipes

        local itemIndex = buttonIndex + offset

        if itemIndex <= #items then
            local item = items[itemIndex]

            button:SetID(itemIndex)
			button.data = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
            button:SetWidth(Recipes.scrollFrame.scrollChild:GetWidth())
			button.DetailsButton:Hide()

			if item.isHeader then
				button.Icon:SetTexture(nil)
				button.Icon:Hide()
				button.Text:SetJustifyH("CENTER")
				button.Text:SetTextColor(1, 1, 1)
				button.Text:SetText(item.header..format("   |cFF52D386[ %s / %s ]|r", item.skillLineCurrentLevel or 0, item.skillLineMaxLevel or 0))
				--button.HeaderHighlight:SetVertexColor(0.8, 0.7, 0, 1)
				button.HeaderHighlight:SetAlpha(0.75)
				button.isHeader = true
			else
				button.Icon:SetTexture(item.recipeIcon or nil)
				button.Icon:Show()
				button.Text:SetJustifyH("LEFT")
				button.Text:SetTextColor(0.25, 0.88, 0.82)
				button.Text:SetText(item.recipeName or "")
				button.HeaderHighlight:SetAlpha(0)
				button.isHeader = nil
			end

			--while we are updating the scrollframe, is the mouse currently over a button?
			--if so we need to force the OnEnter as the items will scroll up in data but the button remains the same position on our cursor
			if BSYC.GMF() == button then
				Recipes:Item_OnLeave() --hide first
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
    if not btn.isHeader then
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		GameTooltip:SetSpellByID(btn.data.recipeID)
		GameTooltip:Show()
		return
	end
	GameTooltip:Hide()
end

function Recipes:Item_OnLeave()
	GameTooltip:Hide()
end

function Recipes:Item_OnClick(btn)
	if not btn.isHeader and IsModifiedClick("CHATLINK") then
		ChatEdit_InsertLink(GetSpellLink(btn.data.recipeID))
	end
end
