local L = BAGSYNC_L
local currentPlayer = UnitName('player')
local currentRealm = GetRealmName()
local bgProfiles = CreateFrame("Frame","BagSync_ProfilesFrame", UIParent)

--lets do the dropdown menu of DOOM
local bgsProfilesDD = CreateFrame("Frame", "bgsProfilesDD")
bgsProfilesDD.displayMode = 'MENU'

local function addButton(level, text, isTitle, notCheckable, hasArrow, value, func)
	local info = UIDropDownMenu_CreateInfo()
	info.text = text
	info.isTitle = isTitle
	info.notCheckable = notCheckable
	info.hasArrow = hasArrow
	info.value = value
	info.func = func
	UIDropDownMenu_AddButton(info, level)
end
		
bgsProfilesDD.initialize = function(self, level)
	if not BagSync or not BagSyncDB then return end
	if not BagSyncDB[currentRealm] then return end
	
	local tmp = {}
	
	--freaking LUA table.sort is terrible, you can't sort non-numeric keys..
	for k, v in pairs(BagSyncDB[currentRealm]) do
		table.insert(tmp, k)
	end
	table.sort(tmp, function(a,b) return (a < b) end)

	if level == 1 then
		PlaySound('gsTitleOptionExit')

		for i=1, #tmp do
			addButton(level, tmp[i], nil, 1, nil, tmp[i], function(frame, ...)
				if BagSyncProfilesToonNameText then
					BagSyncProfilesToonNameText:SetText(tmp[i])
				end
			end)
		end
		
		addButton(level, "", nil, 1) --space ;)
		addButton(level, L["Close"], nil, 1)

	end

end

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

local warningLabel = bgProfiles:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
warningLabel:SetPoint("CENTER", bgProfiles, 0, 29)
warningLabel:SetText("|cFFDF2B2B"..L["Select a profile to delete.\nNOTE: This is irreversible!"].."|r")
bgProfiles.warningLabel = warningLabel

local buttonText = bgProfiles:CreateFontString("BagSyncProfilesToonNameText", nil, "GameFontNormal")
buttonText:SetText(L["Click Here"])
buttonText:SetPoint("CENTER")

bgProfiles.toonName = CreateFrame("Button", "BagSyncProfilesToonName", bgProfiles);
bgProfiles.toonName:SetPoint("CENTER", bgProfiles, 0, 0)
bgProfiles.toonName:SetHeight(21);
bgProfiles.toonName:SetWidth(266);
bgProfiles.toonName:SetFontString(buttonText)
bgProfiles.toonName:SetBackdrop({
	bgFile = "Interface\\Buttons\\WHITE8x8",
})
bgProfiles.toonName:SetBackdropColor(0,1,0,0.25)
bgProfiles.toonName:SetScript("OnClick", function() ToggleDropDownMenu(1, nil, bgsProfilesDD, 'cursor', 0, 0)  end)
bgProfiles.toonName.text = buttonText

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
	local name = BagSyncProfilesToonNameText:GetText()
	if name and BagSyncDB and BagSyncDB[currentRealm] and BagSyncDB[currentRealm][name] then
		BagSyncDB[currentRealm][name] = nil
		BagSyncOpt.delName = name
		BagSync:FixDB_Data()
		BagSync_ProfilesFrame:Hide()
		ReloadUI()
	else
		print(L["BagSync: Error user not found!"])
	end
	BagSync_ProfilesFrame.confirmButton:Disable()
end)

bgProfiles:SetScript("OnHide", function(self) bgsProfilesDD:Hide() end)

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

bgProfiles:Hide()