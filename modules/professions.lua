--[[
	professions.lua
		A professions frame for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Professions = BSYC:NewModule("Professions")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Professions", ...) end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local AceGUI = LibStub("AceGUI-3.0")

function Professions:OnEnable()

	--lets create our widgets
	local ProfessionsFrame = AceGUI:Create("Window")
	_G["BagSyncProfessionsFrame"] = ProfessionsFrame
    --Add to special frames so window can be closed when the escape key is pressed.
    tinsert(UISpecialFrames, "BagSyncProfessionsFrame")
	Professions.frame = ProfessionsFrame
	Professions.parentFrame = ProfessionsFrame.frame

	ProfessionsFrame:SetTitle("BagSync - "..L.Professions)
	ProfessionsFrame:SetHeight(500)
	ProfessionsFrame:SetWidth(380)
	ProfessionsFrame:EnableResize(false)

	local information = AceGUI:Create("BagSyncLabel")
	information:SetText(L.ProfessionInformation)
	information:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
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

	local label = AceGUI:Create("BagSyncInteractiveLabel")

	label:SetHeaderHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	label:ToggleHeaderHighlight(false)
	label.entry = entry
	label:SetColor(1, 1, 1)

	if isHeader then
		label:SetText(entry.skillData.name)
		label:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
		label:SetFullWidth(true)
		label:ApplyJustifyH("CENTER")
		label.userdata.hasRecipes = false
		label:ToggleHeaderHighlight(true)
		label.userdata.isHeader = true
	else
		label:SetText(entry.colorized)
		label:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
		label:SetFullWidth(true)
		if entry.hasRecipes then
			label.userdata.hasRecipes = true
		else
			label:SetText(entry.colorized..format("   |cFFFFFFFF%s/%s|r", entry.skillData.skillLineCurrentLevel or 0, entry.skillData.skillLineMaxLevel or 0))
			label.userdata.hasRecipes = false
		end
		label:ApplyJustifyH("LEFT")
		label.userdata.isHeader = false
	end

	label:SetCallback(
		"OnClick",
		function (widget, sometable, button)
			if "LeftButton" == button and label.userdata.hasRecipes then
				BSYC:GetModule("Recipes"):ViewRecipes(label.entry)
			end
		end)
	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			if not label.userdata.isHeader then
				label:SetColor(1, 0, 0)
				--override the single tooltip use of BagSync
				label.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
				label.highlight:SetVertexColor(0,1,0,0.3)

				GameTooltip:SetOwner(label.frame, "ANCHOR_BOTTOMRIGHT")

				if not label.userdata.isHeader then
					if label.userdata.hasRecipes then
						GameTooltip:AddLine(label.entry.colorized..": "..L.ProfessionHasRecipes)
					else
						GameTooltip:AddLine(label.entry.colorized..": "..L.ProfessionHasNoRecipes)
					end
					GameTooltip:Show()
				end
			end
		end)
	label:SetCallback(
		"OnLeave",
		function (widget, sometable)
			label:SetColor(1, 1, 1)
			--override the single tooltip use of BagSync
			label.highlight:SetTexture(nil)
			GameTooltip:Hide()
		end)

	self.scrollframe:AddChild(label)
end

function Professions:DisplayList()

	self.scrollframe:ReleaseChildren() --clear out the scrollframe

	local professionsTable = {}
	local tempList = {}

	for unitObj in Data:IterateUnits() do
		if not unitObj.isGuild and unitObj.data.professions then
			for skillID, skillData in pairs(unitObj.data.professions) do
				if skillData.name then
					local hasRecipes = false
					if (skillData.recipeCount and skillData.recipeCount > 0) or (skillData.categoryCount and skillData.categoryCount > 0) then
						hasRecipes = true
					end
					table.insert(professionsTable, { skillID=skillID, skillData=skillData, unitObj=unitObj, colorized=Tooltip:ColorizeUnit(unitObj), sortIndex=Tooltip:GetSortIndex(unitObj), hasRecipes=hasRecipes } )
				end
			end
		end
	end

	if #professionsTable > 0 then

		table.sort(professionsTable, function(a, b)
			if a.skillData.name == b.skillData.name then
				if a.sortIndex  == b.sortIndex then
					if a.unitObj.realm == b.unitObj.realm then
						return a.unitObj.name < b.unitObj.name;
					end
					return a.unitObj.realm < b.unitObj.realm;
				end
				return a.sortIndex < b.sortIndex;
			end
			return a.skillData.name < b.skillData.name;
		end)

		local lastHeader = ""
		for i=1, #professionsTable do
			if lastHeader ~= professionsTable[i].skillData.name then
				self:AddEntry(professionsTable[i], true) --add header
				self:AddEntry(professionsTable[i], false) --add entry
				lastHeader = professionsTable[i].skillData.name
			else
				self:AddEntry(professionsTable[i], false) --add entry
			end
		end
		self.scrollframe.frame:Show()
	else
		self.scrollframe.frame:Hide()
	end

end