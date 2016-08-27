
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
	RecipesFrame:SetWidth(380)
	RecipesFrame:EnableResize(false)
	
	local information = AceGUI:Create("Label")
	information:SetText(L.ProfessionLeftClick)
	information:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
	information:SetColor(153/255,204/255,51/255)
	information:SetFullWidth(true)
	RecipesFrame:AddChild(information)
	
	Recipes.information = information
	
	local label = AceGUI:Create("InteractiveLabel")
	label:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
	label:SetFullWidth(true)
	label:SetText(" ") --add an empty space just to show the label
	
	--I know you aren't supposed to but I'm going to have to put it on the label object.  Only because when using userdata the texture sticks around even with release.
	--So I'm forced to have to add it to label and do a custom OnRelease to get rid of it for other addons.
	if not label.headerhighlight then
		label.headerhighlight = label.frame:CreateTexture(nil, "BACKGROUND") --userdata gets deleted when widget is recycled
		label.headerhighlight:SetAllPoints()
		label.headerhighlight:SetBlendMode("ADD")
		label.headerhighlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight") --userdata gets deleted when widget is recycled
		label.headerhighlight:Show()
	end
	--remove the highlight texture on widget release for other addons
	local oldOnRelease = label.OnRelease
	label.OnRelease = function(self)
		if self.headerhighlight then
			self.headerhighlight:SetTexture(nil)
			self.headerhighlight = nil
		end
		if oldOnRelease then
			oldOnRelease(self)
		end
	end
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

	local name, recipeID = entry.name, entry.recipeID
	
	local highlightColor = {1, 0, 0}
	local label = AceGUI:Create("InteractiveLabel")

	label:SetText(name)
	label:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
	label:SetFullWidth(true)
	label:SetColor( 1,1,1)
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
			label:SetColor(1,1,1)
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
		
		if recipe_info and recipe_info.name then
			craftName = recipe_info.name
		elseif GetSpellInfo(valuesList[idx]) then
			craftName = GetSpellInfo(valuesList[idx])
		else
			craftName = L.ProfessionsFailedRequest:format(valuesList[idx])
		end
		
		count = count + 1
		table.insert(searchTable, {name=craftName, recipeID=valuesList[idx]})
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