local L = BAGSYNC_L
local currentPlayer = UnitName('player')
local currentRealm = GetRealmName()

local bgProfiles = CreateFrame("Frame","BagSync_ProfilesFrame", UIParent)
bgProfiles:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

bgProfiles:SetFrameStrata("HIGH")
bgProfiles:SetToplevel(true)
bgProfiles:EnableMouse(true)
bgProfiles:SetMovable(true)
bgProfiles:SetClampedToScreen(true)
bgProfiles:SetWidth(280)
bgProfiles:SetHeight(150)

bgProfiles:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 32,
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
})

bgProfiles:SetBackdropColor(0,0,0,1)
bgProfiles:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

local addonTitle = bgProfiles:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
addonTitle:SetPoint("CENTER", bgProfiles, "TOP", 0, -20)
addonTitle:SetText("|cFF99CC33BagSync|r |cFFFFFFFF("..L["Profiles"]..")|r")

local closeButton = CreateFrame("Button", nil, bgProfiles, "UIPanelCloseButton");
closeButton:SetPoint("TOPRIGHT", bgProfiles, -15, -8);

bgProfiles.deleteButton = CreateFrame("Button", nil, bgProfiles, "UIPanelButtonTemplate");
bgProfiles.deleteButton:SetPoint("BOTTOM", bgProfiles, "BOTTOM", -70, 20);
bgProfiles.deleteButton:SetHeight(21);
bgProfiles.deleteButton:SetWidth(100);
bgProfiles.deleteButton:SetText(L["Delete"]);
bgProfiles.deleteButton:SetScript("OnClick", function() BagSync_ProfilesFrame.confirmButton:Enable()  end)

bgProfiles.confirmButton = CreateFrame("Button", nil, bgProfiles, "UIPanelButtonTemplate");
bgProfiles.confirmButton:SetPoint("BOTTOM", bgProfiles, "BOTTOM", 70, 20);
bgProfiles.confirmButton:SetHeight(21);
bgProfiles.confirmButton:SetWidth(100);
bgProfiles.confirmButton:SetText(L["Confirm"]);
bgProfiles.confirmButton:Disable()

bgProfiles.confirmButton:SetScript("OnClick", function()
	local name = BagSync_ProfilesFrame.DDText:GetText()
	if name and BagSyncDB and BagSyncDB[currentRealm] and BagSyncDB[currentRealm][name] then
		BagSyncDB[currentRealm][name] = nil
		BagSyncOpt.delName = name
		BagSync:FixDB_Data()
		BagSync_ProfilesFrame:Hide()
		ReloadUI()
	else
		print("BagSync: Error user not found to delete!")
	end
	BagSync_ProfilesFrame.confirmButton:Disable()
end)


bgProfiles:SetScript("OnShow", function(self) self:LoadProfiles() end)
bgProfiles:SetScript("OnHide", function(self) GameTooltip:Hide() end)

bgProfiles:SetScript("OnMouseDown", function(frame, button)
	if frame:IsMovable() then
		frame.isMoving = true
		frame:StartMoving()
	end
end)

bgProfiles:SetScript("OnMouseUp", function(frame, button) 
	if( frame.isMoving ) then
		frame.isMoving = nil
		frame:StopMovingOrSizing()
	end
end)

function bgProfiles:LoadProfiles()
	if not BagSync or not BagSyncDB then return end
	if not BagSyncDB[currentRealm] then return end

	local profile_DD, profile_DD_text, profile_DD_container, profile_DD_label = LibStub("tekKonfig-Dropdown").new(bgProfiles, L["Profiles"], "CENTER", bgProfiles, "CENTER", -25, 0)
	
	profile_DD_container:SetHeight(28)
	profile_DD:SetWidth(180)
	profile_DD:ClearAllPoints()
	profile_DD:SetPoint("LEFT", profile_DD_label, "RIGHT", -8, -2)
	profile_DD_text:SetText(' ')
	profile_DD.tiptext = L["Select a profile to delete.\nNOTE: This is irreversible!"]

	bgProfiles.DDText = profile_DD_text
	
	local function OnClick(self)
		profile_DD_text:SetText(self.value)
		GameTooltip:Hide()
	end
	
	local tmp = {}
	local tmp2 = {}
	
	UIDropDownMenu_Initialize(profile_DD, function()
		local info = UIDropDownMenu_CreateInfo()
		
		info.func = OnClick

		for k, v in pairs(BagSyncDB[currentRealm]) do
			--show everyone but current player
			if k ~= currentPlayer and not tmp2[k] then
				table.insert(tmp, k)
				tmp2[k] = k
			end
		end
		table.sort(tmp, function(a,b) return (a < b) end)
		
		for i=1, #tmp do
			info.text = tmp[i]
			info.value = tmp[i]
			UIDropDownMenu_AddButton(info)
		end

	end)
	
end

bgProfiles:Hide()