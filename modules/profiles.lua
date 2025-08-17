--[[
	profiles.lua
		A profiles editor frame for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Profiles = BSYC:NewModule("Profiles")
local Data = BSYC:GetModule("Data")
local Unit = BSYC:GetModule("Unit")
local Tooltip = BSYC:GetModule("Tooltip")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Profiles", ...) end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

function Profiles:OnEnable()
	local profilesFrame = _G.CreateFrame("Frame", nil, UIParent, "BagSyncFrameTemplate")
	Mixin(profilesFrame, Profiles) --implement new frame to our parent module Mixin, to have access to parent methods
	_G["BagSyncProfilesFrame"] = profilesFrame
    --Add to special frames so window can be closed when the escape key is pressed.
    tinsert(UISpecialFrames, "BagSyncProfilesFrame")
    profilesFrame.TitleText:SetText("BagSync - "..L.Profiles)
    profilesFrame:SetHeight(506) --irregular height to allow the scroll frame to fit the bottom most button
	profilesFrame:SetWidth(440)
    profilesFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    profilesFrame:EnableMouse(true) --don't allow clickthrough
    profilesFrame:SetMovable(true)
    profilesFrame:SetResizable(false)
    profilesFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	profilesFrame:RegisterForDrag("LeftButton")
	profilesFrame:SetClampedToScreen(true)
	profilesFrame:SetScript("OnDragStart", profilesFrame.StartMoving)
	profilesFrame:SetScript("OnDragStop", profilesFrame.StopMovingOrSizing)
	profilesFrame:SetScript("OnShow", function() Profiles:OnShow() end)
	local closeBtn = CreateFrame("Button", nil, profilesFrame, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", C_EditMode and -3 or 2, C_EditMode and -3 or 1) --check for classic servers to adjust for positioning using a check for the new EditMode			
    profilesFrame.closeBtn = closeBtn
    Profiles.frame = profilesFrame

	profilesFrame.infoText = profilesFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	profilesFrame.infoText:SetText(L.DeleteWarning)
	profilesFrame.infoText:SetFont(STANDARD_TEXT_FONT, 12, "")
	profilesFrame.infoText:SetTextColor(1, 0, 0)
	profilesFrame.infoText:SetPoint("LEFT", profilesFrame, "TOPLEFT", 15, -35)
	profilesFrame.infoText:SetJustifyH("LEFT")
	profilesFrame.infoText:SetWidth(profilesFrame:GetWidth() - 15)

    Profiles.scrollFrame = _G.CreateFrame("ScrollFrame", nil, profilesFrame, "HybridScrollFrameTemplate")
    Profiles.scrollFrame:SetWidth(397)
    Profiles.scrollFrame:SetPoint("TOPLEFT", profilesFrame, "TOPLEFT", 13, -48)
    --set ScrollFrame height by altering the distance from the bottom of the frame
    Profiles.scrollFrame:SetPoint("BOTTOMLEFT", profilesFrame, "BOTTOMLEFT", -25, 15)
    Profiles.scrollFrame.scrollBar = CreateFrame("Slider", "$parentscrollBar", Profiles.scrollFrame, "HybridScrollBarTemplate")
    Profiles.scrollFrame.scrollBar:SetPoint("TOPLEFT", Profiles.scrollFrame, "TOPRIGHT", 1, -16)
    Profiles.scrollFrame.scrollBar:SetPoint("BOTTOMLEFT", Profiles.scrollFrame, "BOTTOMRIGHT", 1, 12)
	--initiate the scrollFrame
    --the items we will work with
    Profiles.profilesList = {}
	Profiles.scrollFrame.update = function() Profiles:RefreshList(); end
    HybridScrollFrame_SetDoNotHideScrollBar(Profiles.scrollFrame, true)
	HybridScrollFrame_CreateButtons(Profiles.scrollFrame, "BagSyncListSimpleItemTemplate")

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
			local tObj = self.text or self.Text
			tObj:SetText(L.ProfilesRemove:format(self.data.colorized, self.data.realm));
		end,
		OnAccept = function (self)
			Profiles:DeleteUnit(self.data)
		end,
		whileDead = 1,
	}

	profilesFrame:Hide()
end

function Profiles:OnShow()
	BSYC:SetBSYC_FrameLevel(Profiles)

	Profiles:UpdateList()
end

function Profiles:UpdateList()
	Profiles:CreateList()
    Profiles:RefreshList()

	--scroll to top when shown
	HybridScrollFrame_SetOffset(Profiles.scrollFrame, 0)
	Profiles.scrollFrame.scrollBar:SetValue(0)
end

function Profiles:CreateList()
	Profiles.profilesList = {}
	local usrData = {}

	for unitObj in Data:IterateUnits(true) do
		table.insert(usrData, {
			unitObj = unitObj,
			name = unitObj.name,
			realm = unitObj.realm,
			colorized = Tooltip:ColorizeUnit(unitObj, true)
		})
	end

	if #usrData > 0 then
		table.sort(usrData, function(a, b)
			if a.realm  == b.realm then
				return a.name < b.name;
			end
			return a.realm < b.realm;
		end)

		local lastHeader = ""
		for i=1, #usrData do
			if lastHeader ~= usrData[i].realm then
				--add header
				table.insert(Profiles.profilesList, {
					colorized = usrData[i].realm,
					isHeader = true,
				})
				lastHeader = usrData[i].realm
			end
			--add player
			table.insert(Profiles.profilesList, {
				unitObj = usrData[i].unitObj,
				name = usrData[i].name,
				realm = usrData[i].realm,
				colorized = usrData[i].colorized
			})
		end
	end
end

function Profiles:RefreshList()
    local items = Profiles.profilesList
    local buttons = HybridScrollFrame_GetButtons(Profiles.scrollFrame)
    local offset = HybridScrollFrame_GetOffset(Profiles.scrollFrame)
	if not buttons then return end

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
		button.parentHandler = Profiles

        local itemIndex = buttonIndex + offset

        if itemIndex <= #items then
            local item = items[itemIndex]

            button:SetID(itemIndex)
			button.data = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
			button.Text:SetTextColor(1, 1, 1)
            button:SetWidth(Profiles.scrollFrame.scrollChild:GetWidth())

			if item.isHeader then
				button.Text:SetJustifyH("CENTER")
				--button.HeaderHighlight:SetVertexColor(0.8, 0.7, 0, 1)
				button.HeaderHighlight:SetAlpha(0.75)
				button.isHeader = true
			else
				button.Text:SetJustifyH("LEFT")
				button.HeaderHighlight:SetAlpha(0)
				button.isHeader = nil
			end
			button.Text:SetText(item.colorized or "")

			--while we are updating the scrollframe, is the mouse currently over a button?
			--if so we need to force the OnEnter as the items will scroll up in data but the button remains the same position on our cursor
			if BSYC.GMF() == button then
				Profiles:Item_OnLeave() --hide first
				Profiles:Item_OnEnter(button)
			end

            button:Show()
        else
            button:Hide()
        end
    end

    local buttonHeight = Profiles.scrollFrame.buttonHeight
    local totalHeight = #items * buttonHeight
    local shownHeight = #buttons * buttonHeight

    HybridScrollFrame_Update(Profiles.scrollFrame, totalHeight, shownHeight)
end

function Profiles:DeleteUnit(entry)
	if not entry then BSYC:Print(L.ErrorUserNotFound) return end

	if not entry.unitObj.isGuild then
		if entry.unitObj.data == BSYC.db.player then
			--it's the current player so we have to do a reloadui
			BagSyncDB[entry.unitObj.realm][entry.unitObj.name] = nil
			Data:FixDB()
			ReloadUI()
			return
		else
			BSYC:Print(L.ProfileBeenRemoved:format(entry.colorized, entry.unitObj.realm))
			BagSyncDB[entry.unitObj.realm][entry.unitObj.name] = nil
		end
	else
		BSYC:Print(L.GuildRemoved:format(entry.colorized))
		BagSyncDB[entry.unitObj.realm][entry.unitObj.name] = nil
	end
	Data:FixDB()
	Profiles:UpdateList()
	--reset tooltip cache since we have removed some units
	Tooltip:ResetCache()
end

function Profiles:Item_OnEnter(btn)
	if btn.isHeader and btn.Highlight:IsVisible() then
		btn.Highlight:Hide()
	elseif not btn.isHeader and not btn.Highlight:IsVisible() then
		btn.Highlight:Show()
	end
    if not btn.isHeader then
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		if not btn.data.unitObj.isGuild then
			GameTooltip:AddLine("|cFFFFFFFF"..PLAYER..":|r  "..btn.data.colorized)
		else
			GameTooltip:AddLine("|cFFFFFFFF"..GUILD..":|r  "..btn.data.colorized)
			GameTooltip:AddLine("|cFFFFFFFF"..L.Realm.."|r  "..btn.data.realm)
			GameTooltip:AddLine("|cFFFFFFFF"..L.TooltipRealmKey.."|r "..(btn.data.unitObj.data.realmKey or "?"))
		end
		GameTooltip:Show()
		return
	end
	GameTooltip:Hide()
end

function Profiles:Item_OnLeave()
	GameTooltip:Hide()
end

function Profiles:Item_OnClick(btn)
	if not btn.isHeader then
		StaticPopup_Show("BAGSYNC_PROFILES_REMOVE", '', '', btn.data) --cannot pass nil as it's expected for SetFormattedText (Interface/FrameXML/StaticPopup.lua)
	end
end