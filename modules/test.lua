
local BSYC = select(2, ...) --grab the addon namespace
local Testing = BSYC:NewModule("Testing")

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync", true)
local AceGUI = LibStub("AceGUI-3.0")

function Testing:OnEnable()

	--lets create our widgets
	local TestingFrame = AceGUI:Create("Window")
	Testing.frame = TestingFrame

	TestingFrame:SetTitle("Testing")
	TestingFrame:SetHeight(500)
	TestingFrame:SetWidth(380)
	TestingFrame:EnableResize(false)
	
	local refreshbutton = AceGUI:Create("Button")
	refreshbutton:SetText(L.Refresh)
	refreshbutton:SetWidth(100)
	refreshbutton:SetHeight(20)
	refreshbutton:SetCallback("OnClick", function()
		self:DisplayList()
	end)
	TestingFrame:AddChild(refreshbutton)
	
	local scrollframe = AceGUI:Create("ScrollFrame");
	scrollframe:SetFullWidth(true)
	scrollframe:SetLayout("Flow")

	Testing.scrollframe = scrollframe
	TestingFrame:AddChild(scrollframe)

	TestingFrame:Hide()
end


function Testing:AddEntry(entry)

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

function Testing:DisplayList()
	
	self.scrollframe:ReleaseChildren() --clear out the scrollframe
	
	local searchTable = {}
	local count = 0
	
	--loop through our Testing
	for k, v in pairs(BSYC.db.profession[BSYC.currentRealm]) do
		if k == "test1" then
			local tName, tlevel, tValues = strsplit(",", v)
			local valuesList = {strsplit("|", tValues)}
			
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
				
				table.insert(searchTable, {name=craftName, recipeID=valuesList[idx]})
			end
			count = count + 1
		end
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
	
	--169080
	--GetSpellInfo(169080)
end