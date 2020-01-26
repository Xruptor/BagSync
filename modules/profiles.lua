--[[
	profiles.lua
		A profiles editor frame for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Profiles = BSYC:NewModule("Profiles")
local Data = BSYC:GetModule("Data")
local Unit = BSYC:GetModule("Unit")
local Tooltip = BSYC:GetModule("Tooltip")

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
local function Debug(...)
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", "Profiles")
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
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
	information:SetFont(STANDARD_TEXT_FONT, 12, THICKOUTLINE)
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
	
	StaticPopupDialogs["BAGSYNC_PROFILES_REMOVE"] = {
		text = L.ProfilesRemove,
		button1 = "Yes",
		button2 = "No",
		hasEditBox = false,
		timeout = 0,
		exclusive = 1,
		hideOnEscape = 1,
		OnShow = function (self)
			--entry.unitObj.realm
			POOPCRAP = self
			self.text:SetText(L.ProfilesRemove:format(self.data.colorized, self.data.unitObj.realm));
		end,
		OnAccept = function (self)
			Profiles:DeleteUnit(self.data)
		end,
		whileDead = 1,
	}
	
	ProfilesFrame:Hide()
	
end

function Profiles:DeleteUnit(entry)
	if not entry then BSYC:Print(L.ErrorUserNotFound) return end
	
	local player = Unit:GetUnitInfo()
	
	if not entry.unitObj.isGuild then
		if entry.unitObj.name == player.name and entry.unitObj.realm == player.realm then
			--it's the current player so we have to do a reloadui
			BagSyncDB[entry.unitObj.realm][entry.unitObj.name] = nil
			ReloadUI()
			return
		else
			BSYC:Print(L.ProfileBeenRemoved:format(entry.colorized, entry.unitObj.realm))
			BagSyncDB[entry.unitObj.realm][entry.unitObj.name] = nil
			self:DisplayList()
			return
		end
	else
		BSYC:Print(L.GuildRemoved:format(entry.colorized))
		BagSyncDB[entry.unitObj.realm][entry.unitObj.name] = nil
		self:DisplayList()
		return
	end
	
	BSYC:Print(L.ErrorUserNotFound)
end

function Profiles:AddEntry(entry, isHeader)

	local label = AceGUI:Create("BagSyncInteractiveLabel")

	label:SetHeaderHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	label:ToggleHeaderHighlight(false)
	label.entry = entry
	label:SetColor(1, 1, 1)
	
	if isHeader then
		label:SetText(entry.unitObj.realm)
		label:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label:ApplyJustifyH("CENTER")
		label:ToggleHeaderHighlight(true)
		label.userdata.isHeader = true
	else
		if entry.unitObj.isGuild then
			label:SetText(GUILD..":  "..entry.colorized)
		else
			label:SetText(entry.colorized)
		end
		label:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label:ApplyJustifyH("LEFT")
		label.userdata.isHeader = false
	end

	label:SetCallback(
		"OnClick", 
		function (widget, sometable, button)
			if "LeftButton" == button and not label.userdata.isHeader then
				StaticPopup_Show("BAGSYNC_PROFILES_REMOVE", '', '', entry) --cannot pass nil as it's expected for SetFormattedText (Interface/FrameXML/StaticPopup.lua)
			end
		end)
	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			if not label.userdata.isHeader then
				label:SetColor(1, 0, 0)
				GameTooltip:SetOwner(label.frame, "ANCHOR_BOTTOMRIGHT")
				
				if not label.entry.unitObj.isGuild then
					GameTooltip:AddLine(PLAYER..":  "..entry.colorized)
				else
					GameTooltip:AddLine(GUILD..":  "..entry.colorized)
					GameTooltip:AddLine(L.TooltipRealmKey.." "..entry.unitObj.data.realmKey)
				end
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

function Profiles:DisplayList()

	self.scrollframe:ReleaseChildren() --clear out the scrollframe
	
	local profilesTable = {}
	local tempList = {}
	
	for unitObj in Data:IterateUnits(true) do
		table.insert(profilesTable, { unitObj=unitObj, colorized=Tooltip:ColorizeUnit(unitObj, true) } )
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
