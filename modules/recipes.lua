--[[
	recipes.lua
		A recipes frame for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Recipes = BSYC:NewModule("Recipes")
local Tooltip = BSYC:GetModule("Tooltip")

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
local function Debug(...)
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", "Recipes")
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
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
	information:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
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
	label:SetColor(1, 1, 1)
	label.entry = entry
	
	if isHeader then
		label:SetText(entry.tierData.name..format("   |cFF00FF00[ %s / %s ]|r", entry.tierData.skillLineCurrentLevel, entry.tierData.skillLineMaxLevel))
		label:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label:ApplyJustifyH("CENTER")
		label:ToggleHeaderHighlight(true)
		label.userdata.isHeader = true
	else
		label:SetText(entry.recipeName)
		label:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label:SetImage(entry.recipeIcon)
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
		if v.recipes then
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
						
						table.insert(tierTable, { tierID=k, tierData=v, tierIndex=v.orderIndex, recipeName=recipeName, recipeID=recipeList[idx], recipeIcon=iconTexture, isEmpty=false } )
					end
				end
				
			end
		else
			--we have no recipes but the tier is learned and is leveled.  So display it as a header
			table.insert(tierTable, { tierID=k, tierData=v, tierIndex=v.orderIndex, recipeName=v.name, isEmpty=true } )
		end
	end

	--now do the recipes per tier
	if table.getn(tierTable) > 0 then
		
		--sort the tiers
		table.sort(tierTable, function(a, b)
			if a.tierIndex  == b.tierIndex then
				return a.recipeName < b.recipeName;
			end
			return a.tierIndex < b.tierIndex;
		end)
		
		local lastHeader = ""
		for i = 1, #tierTable do
			if tierTable[i].isEmpty then
				--no recipes just display it as a header
				self:AddEntry(tierTable[i], true) --add header
				lastHeader = tierTable[i].tierData.name
			elseif lastHeader ~= tierTable[i].tierData.name then
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