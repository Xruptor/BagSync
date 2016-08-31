
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
	information:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
	information:SetColor(153/255,204/255,51/255)
	information:SetFullWidth(true)
	information:ApplyJustifyH("CENTER")
	RecipesFrame:AddChild(information)
	
	Recipes.information = information
	
	local label = AceGUI:Create("BagSyncInteractiveLabel")
	label:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
	label:SetFullWidth(true)
	label:SetText(" ") --add an empty space just to show the label
	label:SetHeaderHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	label:ToggleHeaderHighlight(true)
	RecipesFrame:AddChild(label)
	
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

function Recipes:AddEntry(entry)

	local name, recipeID, icon = entry.name, entry.recipeID, entry.icon
	
	local highlightColor = {1, 0, 0}
	local color = {1, 1, 1}
	local label = AceGUI:Create("InteractiveLabel")

	label:SetText(name)
	label:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
	label:SetFullWidth(true)
	label:SetColor(unpack(color))
	label:SetImage(icon)
	label:SetCallback(
		"OnClick", 
		function (widget, sometable, button)
			ChatEdit_InsertLink(GetSpellLink(recipeID))
		end)
	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			label:SetColor(unpack(highlightColor))
			GameTooltip:SetOwner(label.frame, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:SetSpellByID(recipeID)
			GameTooltip:Show()
		end)
	label:SetCallback(
		"OnLeave",
		function (widget, sometable)
			label:SetColor(unpack(color))
			GameTooltip:Hide()
		end)

	self.scrollframe:AddChild(label)
end

function Recipes:ViewRecipes(tradeName, tradeLevel, tradeRecipes)
	self.information:SetText(tradeName..format(" |cFFFFFFFF(%s)|r", tradeLevel))
	self:DisplayList(tradeRecipes)
	self.frame:Show()
end

function Recipes:DisplayList(tradeRecipes)
	
	self.scrollframe:ReleaseChildren() --clear out the scrollframe
	
	local searchTable = {}
	local count = 0
	
	--loop through our Recipes
	local valuesList = {strsplit("|", tradeRecipes)}
	
	for idx = 1, #valuesList do
	
		local recipe_info = _G.C_TradeSkillUI.GetRecipeInfo(valuesList[idx])
		local craftName = valuesList[idx]
		local iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
	
		local gName, gRank, gIcon = GetSpellInfo(valuesList[idx])
		
		if recipe_info and recipe_info.name then
			craftName = recipe_info.name
			iconTexture = recipe_info.icon
		elseif gName then
			craftName = gName
			iconTexture = gIcon
		else
			craftName = L.ProfessionsFailedRequest:format(valuesList[idx])
		end
		
		count = count + 1
		table.insert(searchTable, {name=craftName, recipeID=valuesList[idx], icon=iconTexture})
	end

	--show or hide the scrolling frame depending on count
	if count > 0 then
		table.sort(searchTable, function(a,b) return (a.name < b.name) end)
		for i=1, #searchTable do
			self:AddEntry(searchTable[i])
		end
		self.scrollframe.frame:Show()
	else
		self.scrollframe.frame:Hide()
	end
	
end