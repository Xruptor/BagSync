
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

	label.userdata.highlight = label.frame:CreateTexture(nil, "BACKGROUND") --userdata gets deleted when widget is recycled
	label.userdata.highlight:SetAllPoints()
	label.userdata.highlight:SetBlendMode("ADD")
	label.userdata.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight") --userdata gets deleted when widget is recycled
	label.userdata.highlight:Hide()
	
	label.userdata.color = {1, 1, 1}
	
	if isHeader then
		label:SetText(entry.player)
		label:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label:SetColor(unpack(label.userdata.color))
		label.userdata.highlight:Show()
		label.label:SetJustifyH("CENTER") --don't like doing this until they update Ace3GUI
		label.userdata.isHeader = isHeader
	else
		label:SetText(entry.name)
		label:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
		label:SetFullWidth(true)
		if entry.recipeIndex <= 2 then
			label.userdata.color = {153/255,204/255,51/255} --primary profession color it green
		else
			label.userdata.color = {102/255,153/255,1} --gathering profession color it blue
		end
		label.userdata.highlight:Hide()
		label:SetColor(unpack(label.userdata.color))
		label.label:SetJustifyH("LEFT")--don't like doing this until they update Ace3GUI
		label.userdata.isHeader = isHeader
	end

	label:SetCallback(
		"OnClick", 
		function (widget, sometable, button)
			if "LeftButton" == button then
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
			local tName, tLevel = strsplit(",", r)
			table.insert(tmp, { name=tName, level=tLevel, player=playerName, recipeIndex=q } )
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