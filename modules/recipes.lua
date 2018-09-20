--[[
	recipes.lua
		A recipes frame for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Recipes = BSYC:NewModule("Recipes")

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync", true)
local AceGUI = LibStub("AceGUI-3.0")

function Recipes:OnEnable()

	--lets create our widgets
	local RecipesFrame = AceGUI:Create("Window")
	Recipes.frame = RecipesFrame

	RecipesFrame:SetTitle("BagSync - "..L.Recipes)
	RecipesFrame:SetHeight(500)
	RecipesFrame:SetWidth(570)
	RecipesFrame:EnableResize(false)
	
	local information = AceGUI:Create("BagSyncInteractiveLabel")
	information:SetFont(L.GetFontType, 14, THICKOUTLINE)
	information:SetColor(153/255,204/255,51/255)
	information:SetFullWidth(true)
	information:ApplyJustifyH("CENTER")
	RecipesFrame:AddChild(information)
	
	Recipes.information = information
	
	local scrollframe = AceGUI:Create("ScrollFrame");
	scrollframe:SetFullWidth(true)
	scrollframe:SetLayout("Flow")

	Recipes.scrollframe = scrollframe
	RecipesFrame:AddChild(scrollframe)

	hooksecurefunc(RecipesFrame, "Show" ,function()
		--always show the recipes frame on the right of the Professions window
		RecipesFrame:SetPoint( "TOPLEFT", BSYC:GetModule("Professions").parentFrame, "TOPRIGHT", 0, 0)
	end)
	
	RecipesFrame:Hide()
end

function Recipes:AddEntry(entry, isHeader)

	local label = AceGUI:Create("BagSyncInteractiveLabel")

	label:SetHeaderHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	label:ToggleHeaderHighlight(false)

	if isHeader then
		label:SetText(entry.tierData.name..format("   |cFF20ff20[%s/%s]|r", entry.tierData.skillLineCurrentLevel, entry.tierData.skillLineMaxLevel))
		label:SetFont(L.GetFontType, 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label:SetColor(1, 1, 1)
		label:ApplyJustifyH("CENTER")
		label.userdata.isHeader = true
		label:ToggleHeaderHighlight(true)
		label.entry = entry
	else
		label:SetText(entry.recipeName)
		label:SetFont(L.GetFontType, 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label:SetColor(1, 1, 1)
		label:SetImage(entry.recipeIcon)
		label.entry = entry
		label.userdata.isHeader = false
	end

	label:SetCallback(
		"OnClick", 
		function (widget, sometable, button)
			if not label.userdata.isHeader then
				ChatEdit_InsertLink(GetSpellLink(label.entry.recipeID))
			end
		end)
	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			if not label.userdata.isHeader then
				label:SetColor(1, 0, 0)
				GameTooltip:SetOwner(label.frame, "ANCHOR_BOTTOMRIGHT")
				GameTooltip:SetSpellByID(label.entry.recipeID)
				GameTooltip:Show()
			end
		end)
	label:SetCallback(
		"OnLeave",
		function (widget, sometable)
			label:SetColor(1, 1, 1)
			GameTooltip:Hide()
		end)

	self.scrollframe:AddChild(label)
end

function Recipes:ViewRecipes(data)
	self.information:SetText(data.colorized.." | "..data.skillData.name)
	self:DisplayList(data)
	self.frame:Show()
end

function Recipes:DisplayList(data)
	if not data then return end
	if not data.skillData.categories then return end
	
	self.scrollframe:ReleaseChildren() --clear out the scrollframe
	
	local tierTable = {}
	
	for k, v in pairs(data.skillData.categories) do
		local recipeList = {strsplit("|", v.recipes)}
		
		if table.getn(recipeList) > 0 then
		
			for idx = 1, #recipeList do
				if recipeList[idx] and string.len(recipeList[idx]) > 0 then
					local recipe_info = _G.C_TradeSkillUI.GetRecipeInfo(recipeList[idx])
					local recipeName = recipeList[idx]
					local iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
				
					local gName, gRank, gIcon = GetSpellInfo(recipeList[idx])
					
					if recipe_info and recipe_info.name then
						recipeName = recipe_info.name
						iconTexture = recipe_info.icon
					elseif gName then
						recipeName = gName
						iconTexture = gIcon
					else
						recipeName = L.ProfessionsFailedRequest:format(recipeList[idx])
					end
					
					table.insert(tierTable, { tierID=k, tierData=v, tierIndex=v.orderIndex, recipeName=recipeName, recipeID=recipeList[idx], recipeIcon=iconTexture } )
				end
			end
		
		end
	end

	--sort the tiers
	table.sort(tierTable, function(a, b)
		if a.tierIndex  == b.tierIndex then
			return a.recipeName < b.recipeName;
		end
		return a.tierIndex < b.tierIndex;
	end)
	
	--now do the recipes per tier
	if table.getn(tierTable) > 0 then
		local lastHeader = ""
		for i = 1, #tierTable do
			if lastHeader ~= tierTable[i].tierData.name then
				self:AddEntry(tierTable[i], true) --add header
				self:AddEntry(tierTable[i], false) --add entry
				lastHeader = tierTable[i].tierData.name
			else
				self:AddEntry(tierTable[i], false) --add entry
			end
		end
		self.scrollframe.frame:Show()
	else
		self.scrollframe.frame:Hide()
	end

end