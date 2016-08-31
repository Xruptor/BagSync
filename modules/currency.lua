
local BSYC = select(2, ...) --grab the addon namespace
local Currency = BSYC:NewModule("Currency")

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync", true)
local AceGUI = LibStub("AceGUI-3.0")

function Currency:OnEnable()

	--lets create our widgets
	local CurrencyFrame = AceGUI:Create("Window")
	Currency.frame = CurrencyFrame
	Currency.parentFrame = CurrencyFrame.frame

	CurrencyFrame:SetTitle("BagSync - "..L.Currency)
	CurrencyFrame:SetHeight(500)
	CurrencyFrame:SetWidth(380)
	CurrencyFrame:EnableResize(false)
	
	local information = AceGUI:Create("Label")
	information:SetText(L.ProfessionInformation)
	information:SetFont("Fonts\\FRIZQT__.TTF", 12, THICKOUTLINE)
	information:SetColor(1, 165/255, 0)
	information:SetFullWidth(true)
	CurrencyFrame:AddChild(information)
	
	local scrollframe = AceGUI:Create("ScrollFrame");
	scrollframe:SetFullWidth(true)
	scrollframe:SetLayout("Flow")

	Currency.scrollframe = scrollframe
	CurrencyFrame:AddChild(scrollframe)

	hooksecurefunc(CurrencyFrame, "Show" ,function()
		self:DisplayList()
	end)
	
	CurrencyFrame:Hide()
	
end

function Currency:AddEntry(entry, isHeader)

	local highlightColor = {1, 0, 0}
	local label = AceGUI:Create("BagSyncInteractiveLabel")

	label.userdata.color = {1, 1, 1}
	label:SetHeaderHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	label:ToggleHeaderHighlight(false)

	if isHeader then
		label:SetText(entry.player)
		label:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label:SetColor(unpack(label.userdata.color))
		label:ApplyJustifyH("CENTER")
		label.userdata.isHeader = true
		label.userdata.hasRecipes = false
		label:ToggleHeaderHighlight(true)
	else
		local labelText = entry.name..format(" |cFFFFFFFF(%s)|r", entry.level)
		label:SetText(labelText)
		label:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
		label:SetFullWidth(true)
		if entry.recipes then
			label.userdata.color = {153/255,204/255,51/255} --primary profession color it green
			label.userdata.hasRecipes = true
		else
			label.userdata.color = {102/255,153/255,1} --gathering profession color it blue
			label.userdata.hasRecipes = false
		end
		label:SetColor(unpack(label.userdata.color))
		label:ApplyJustifyH("LEFT")
		label.userdata.isHeader = false
	end

	label:SetCallback(
		"OnClick", 
		function (widget, sometable, button)
			if "LeftButton" == button and label.userdata.hasRecipes then
				BSYC:GetModule("Recipes"):ViewRecipes(entry.name, entry.level, entry.recipes)
			end
		end)
	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			label:SetColor(unpack(highlightColor))
			GameTooltip:SetOwner(label.frame, "ANCHOR_BOTTOMRIGHT")
			if label.userdata.hasRecipes then
				GameTooltip:AddLine(L.ProfessionHasRecipes)
			else
				GameTooltip:AddLine(L.ProfessionHasNoRecipes)
			end
			GameTooltip:Show()
		end)
	label:SetCallback(
		"OnLeave",
		function (widget, sometable)
			label:SetColor(unpack(label.userdata.color))
			GameTooltip:Hide()
		end)

	self.scrollframe:AddChild(label)
end

function Currency:DisplayList()

	local CurrencyTable = {}
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
			table.insert(tmp, { player=playerName, name=r.name, level=r.level, recipes=r.recipes } )
			count = count + 1
		end
		
		--add to master table
		table.insert(CurrencyTable, { player=playerName, info=tmp } )
	end
		
	--show or hide the scrolling frame depending on count
	if count > 0 then
		table.sort(CurrencyTable, function(a,b) return (a.player < b.player) end)
		for i=1, #CurrencyTable do
			self:AddEntry(CurrencyTable[i], true) --add header
			for z=1, #CurrencyTable[i].info do
				self:AddEntry(CurrencyTable[i].info[z], false)
			end
		end
		self.scrollframe.frame:Show()
	else
		self.scrollframe.frame:Hide()
	end
	
end