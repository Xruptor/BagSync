
local BSYC = select(2, ...) --grab the addon namespace
local Profiles = BSYC:NewModule("Profiles")

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync", true)
local AceGUI = LibStub("AceGUI-3.0")

function Profiles:OnEnable()

	--lets create our widgets
	local ProfilesFrame = AceGUI:Create("Window")
	local warning = AceGUI:Create("Label")
	local deleteButton = AceGUI:Create("Button")
	local confirmButton = AceGUI:Create("Button")
	local ddlist = AceGUI:Create("Dropdown")

	Profiles.frame = ProfilesFrame

	--add the controls first then edit them
	ProfilesFrame:AddChild(warning)
	ProfilesFrame:AddChild(ddlist)
	ProfilesFrame:AddChild(deleteButton)
	ProfilesFrame:AddChild(confirmButton)
	
	--set the defaults for the main frame
	ProfilesFrame:SetTitle("BagSync - "..L.Profiles)
	ProfilesFrame:SetHeight(200)
	ProfilesFrame:SetWidth(375)
	ProfilesFrame:EnableResize(false)

	--I wish Ace3 had better methods for modifying the alignment of widgets on a container....
	--list has to be in order for editing, warning, ddlist, deletebutton, confirmbutton, etc..
	warning:SetText(L.DeleteWarning)
	warning:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
	warning:ClearAllPoints()
	warning:SetPoint( "CENTER", ProfilesFrame.frame, "CENTER", 10, 55)
	
	ddlist:SetWidth(300)
	ddlist:ClearAllPoints()
	ddlist:SetPoint( "TOPLEFT", ProfilesFrame.frame, "TOPLEFT", 35, -70)
	
	deleteButton:ClearAllPoints()
	deleteButton:SetPoint("BOTTOMLEFT", ddlist.frame, "LEFT", 0, -50)
	
	confirmButton:ClearAllPoints()
	confirmButton:SetPoint("BOTTOMRIGHT", ddlist.frame, "RIGHT", 0, -50)
	
	deleteButton:SetText(L.Delete)
	deleteButton:SetCallback("OnClick", function()
		if not ddlist:GetValue() then BSYC:Print(L.ErrorUserNotFound) return end
		confirmButton:SetDisabled(false)
	end)

	confirmButton:SetText(L.Confirm)
	confirmButton:SetCallback("OnClick", function()
		if not ddlist:GetValue() then return end

		local yName, yRealm  = strsplit("^", ddlist:GetValue())
		
		--call me paranoid but I want to make sure we have something to work with before we even think of deleting... double checking everything
		if yName and string.len(yName) > 0 and yRealm and string.len(yRealm) > 0 then
			BSYC.db.global[yRealm][yName] = nil --remove it
			BSYC:FixDB() --remove all associated tables from the user
			BSYC:Print(L.Profiles.." "..L.Delete.." ["..yName.." - "..(BSYC.db.realmkey[yRealm] or yRealm).."]!")
			ddlist:SetValue(nil) --remove the currently selected player from dropdown
			ProfilesFrame:Hide()
		else
			BSYC:Print(L.ErrorUserNotFound)
		end
		
		confirmButton:SetDisabled(true)
	end)
	confirmButton:SetDisabled(true)

	deleteButton:SetWidth(100)
	confirmButton:SetWidth(100)
	
	--populate the dropdown
	hooksecurefunc(ProfilesFrame, "Show" ,function()
		local tmp = {}
		
		--add all the accounts, who cares if it's the current user
		for realm, rd in pairs(BSYC.db.global) do
			for k, v in pairs(rd) do
				local key = k.."^"..realm
				tmp[key] = k.." - "..(BSYC.db.realmkey[realm] or realm)
			end
		end
		
		table.sort(tmp, function(a,b) return (a < b) end)
		
		--set the list and move the dropdown a bit
		ddlist:SetList(tmp)
	end)
	
	ProfilesFrame:Hide()
end