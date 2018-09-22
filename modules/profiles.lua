--[[
	profiles.lua
		A profiles editor frame for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Profiles = BSYC:NewModule("Profiles")
local Data = BSYC:GetModule("Data")
local Unit = BSYC:GetModule("Unit")
local Tooltip = BSYC:GetModule("Tooltip")

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync", true)
local AceGUI = LibStub("AceGUI-3.0")

function Profiles:OnEnable()

	--lets create our widgets
	local ProfilesFrame = AceGUI:Create("Window")
	Profiles.frame = ProfilesFrame
	Profiles.parentFrame = ProfilesFrame.frame

	ProfilesFrame:SetTitle("BagSync - "..L.Profiles)
	ProfilesFrame:SetHeight(500)
	ProfilesFrame:SetWidth(380)
	ProfilesFrame:EnableResize(false)
	
	local information = AceGUI:Create("Label")
	information:SetText(L.DeleteWarning)
	information:SetFont(L.GetFontType, 12, THICKOUTLINE)
	information:SetColor(1, 165/255, 0)
	information:SetFullWidth(true)
	ProfilesFrame:AddChild(information)
	
	local scrollframe = AceGUI:Create("ScrollFrame");
	scrollframe:SetFullWidth(true)
	scrollframe:SetLayout("Flow")

	Profiles.scrollframe = scrollframe
	ProfilesFrame:AddChild(scrollframe)

	hooksecurefunc(ProfilesFrame, "Show" ,function()
		self:DisplayList()
	end)
	
	ProfilesFrame:Hide()
	
end

function Profiles:AddEntry(entry, isHeader)

	local label = AceGUI:Create("BagSyncInteractiveLabel")

	label:SetHeaderHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	label:ToggleHeaderHighlight(false)
	label.entry = entry
	
	if isHeader then
		label:SetText(entry.unitObj.realm)
		label:SetFont(L.GetFontType, 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label:SetColor(1, 1, 1)
		label:ApplyJustifyH("CENTER")
		label:ToggleHeaderHighlight(true)
		label.userdata.isHeader = true
	else
		label:SetText(entry.colorized)
		label:SetFont(L.GetFontType, 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label:ApplyJustifyH("LEFT")
		label.userdata.isHeader = false
	end

	label:SetCallback(
		"OnClick", 
		function (widget, sometable, button)
			if "LeftButton" == button and label.userdata.hasRecipes then
				--do something
			end
		end)
	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			if not label.userdata.isHeader then
				--label:SetColor(1, 0, 0)
			end
		end)
	label:SetCallback(
		"OnLeave",
		function (widget, sometable)
			--label:SetColor(1, 1, 1)
			--GameTooltip:Hide()
		end)

	self.scrollframe:AddChild(label)
end

function Profiles:DisplayList()

	self.scrollframe:ReleaseChildren() --clear out the scrollframe
	
	local profilesTable = {}
	local tempList = {}
	
	for unitObj in Data:IterateUnits(true) do
		if not unitObj.isGuild then
			table.insert(profilesTable, { unitObj=unitObj, colorized=Tooltip:ColorizeUnit(unitObj, true) } )
		end
	end

	if table.getn(profilesTable) > 0 then
	
		table.sort(profilesTable, function(a, b)
			if a.unitObj.realm  == b.unitObj.realm then
				return a.unitObj.name < b.unitObj.name;
			end
			return a.unitObj.realm < b.unitObj.realm;
		end)
	
		local lastHeader = ""
		for i=1, #profilesTable do
			if lastHeader ~= profilesTable[i].unitObj.realm then
				self:AddEntry(profilesTable[i], true) --add header
				self:AddEntry(profilesTable[i], false) --add entry
				lastHeader = profilesTable[i].unitObj.realm
			else
				self:AddEntry(profilesTable[i], false) --add entry
			end
		end
		self.scrollframe.frame:Show()
	else
		self.scrollframe.frame:Hide()
	end

end

-- L.Profiles
-- L.DeleteWarning
-- L.Delete
-- L.ErrorUserNotFound
-- L.Confirm
