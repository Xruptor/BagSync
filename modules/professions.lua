
local BSYC = select(2, ...) --grab the addon namespace
local Professions = BSYC:NewModule("Professions")

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync", true)
local AceGUI = LibStub("AceGUI-3.0")

function Professions:OnEnable()

	--lets create our widgets
	local ProfessionsFrame = AceGUI:Create("Window")
	Professions.frame = ProfessionsFrame

	ProfessionsFrame:SetTitle("BagSync "..L.Professions)
	ProfessionsFrame:SetHeight(500)
	ProfessionsFrame:SetWidth(380)
	ProfessionsFrame:EnableResize(false)
	
	local information = AceGUI:Create("Label")
	information:SetText(L.ProfessionLeftClick)
	information:SetFont("Fonts\\FRIZQT__.TTF", 12, THICKOUTLINE)
	information:SetColor(1, 165/255, 0)
	information:SetFullWidth(true)
	ProfessionsFrame:AddChild(information)
	
	local scrollframe = AceGUI:Create("ScrollFrame");
	scrollframe:SetFullWidth(true)
	scrollframe:SetLayout("Flow")

	Professions.scrollframe = scrollframe
	ProfessionsFrame:AddChild(scrollframe)

	hooksecurefunc(ProfessionsFrame, "Show" ,function()
		self:DisplayList()
	end)
	
	ProfessionsFrame:Hide()
	
end

function Professions:AddEntry(entry, isHeader)

	local highlightColor = {1, 0, 0}
	local label = AceGUI:Create("InteractiveLabel")

	--I know you aren't supposed to but I'm going to have to put it on the label object.  Only because when using userdata the texture sticks around even with release.
	--So I'm forced to have to add it to label and do a custom OnRelease to get rid of it for other addons.
	if not label.headerhighlight then
		label.headerhighlight = label.frame:CreateTexture(nil, "BACKGROUND") --userdata gets deleted when widget is recycled
		label.headerhighlight:SetAllPoints()
		label.headerhighlight:SetBlendMode("ADD")
		label.headerhighlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight") --userdata gets deleted when widget is recycled
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

	label.userdata.color = {1, 1, 1}
	label.headerhighlight:Hide() --hide on default

	if isHeader then
		label:SetText(entry.player)
		label:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label:SetColor(unpack(label.userdata.color))
		label.label:SetJustifyH("CENTER") --don't like doing this until they update Ace3GUI
		label.userdata.isHeader = isHeader
		label.userdata.hasRecipes = false
		label.headerhighlight:Show()
	else
		local labelText = entry.name..format(" |cFFFFFFFF(%s)|r", entry.level)
		label:SetText(labelText)
		label:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
		label:SetFullWidth(true)
		if entry.recipes then
			label.userdata.color = {153/255,204/255,51/255} --primary profession color it green
		else
			label.userdata.color = {102/255,153/255,1} --gathering profession color it blue
		end
		label:SetColor(unpack(label.userdata.color))
		label.label:SetJustifyH("LEFT")--don't like doing this until they update Ace3GUI
		label.userdata.isHeader = isHeader
		label.userdata.hasRecipes = entry.recipes
	end

	label:SetCallback(
		"OnClick", 
		function (widget, sometable, button)
			if "LeftButton" == button and label.userdata.hasRecipes then
				print("left")
			end
		end)
	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			label:SetColor(unpack(highlightColor))

		end)
	label:SetCallback(
		"OnLeave",
		function (widget, sometable)
			label:SetColor(unpack(label.userdata.color))
		end)

	self.scrollframe:AddChild(label)
end

function Professions:DisplayList()

	local professionsTable = {}
	local tempList = {}
	local count = 0

	self.scrollframe:ReleaseChildren() --clear out the scrollframe
	
	local xDB = BSYC:FilterDB(1) --dbSelect 1
	
	--loop through our characters
	--k = player, v = stored data for player
	for k, v in pairs(xDB) do

		local tmp = {}
		local yName, yRealm  = strsplit("^", k)
		local playerName = BSYC:GetCharacterRealmInfo(yName, yRealm)

		for q, r in pairs(v) do
			local chkRecipes = false
			local tName, tLevel, tRecipeList = strsplit(",", r)
			if tRecipeList then chkRecipes = true end
			table.insert(tmp, { name=tName, level=tLevel, player=playerName, recipeIndex=q, recipes=chkRecipes } )
			count = count + 1
		end
		
		--add to master table
		table.insert(professionsTable, { player=playerName, info=tmp } )
	end
		
	--show or hide the scrolling frame depending on count
	if count > 0 then
		table.sort(professionsTable, function(a,b) return (a.player < b.player) end)
		for i=1, #professionsTable do
			self:AddEntry(professionsTable[i], true) --add header
			for z=1, #professionsTable[i].info do
				self:AddEntry(professionsTable[i].info[z], false)
			end
		end
		self.scrollframe.frame:Show()
	else
		self.scrollframe.frame:Hide()
	end
	
end