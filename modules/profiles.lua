--[[
	profiles.lua
		A profiles editor frame for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...) --grab the addon namespace
local UI = BSYC:GetModule("UI")
local Profiles = BSYC:NewModule("Profiles")
local Data = BSYC:GetModule("Data")
local Unit = BSYC:GetModule("Unit")
local Tooltip = BSYC:GetModule("Tooltip")

-- Cache global API references
local HybridScrollFrame_GetButtons = HybridScrollFrame_GetButtons
local HybridScrollFrame_GetOffset = HybridScrollFrame_GetOffset
local HybridScrollFrame_SetOffset = HybridScrollFrame_SetOffset
local HybridScrollFrame_Update = HybridScrollFrame_Update
local GameTooltip = GameTooltip
local StaticPopup_Show = StaticPopup_Show
local table_insert = table.insert
local table_sort = table.sort

-- Cache frequently accessed BSYC references
local L = BSYC.L

-- ============================================================================
-- Helper Functions
-- ============================================================================

local function BuildSortedProfileList()
	local profilesList = {}
	local usrData = {}

	for unitObj in Data:IterateUnits(true) do
		table_insert(usrData, {
			unitObj = unitObj,
			name = unitObj.name,
			realm = unitObj.realm,
			colorized = Tooltip:ColorizeUnit(unitObj, true)
		})
	end

	if #usrData == 0 then
		return profilesList
	end

	table_sort(usrData, function(a, b)
		if a.realm == b.realm then
			return a.name < b.name
		end
		return a.realm < b.realm
	end)

	local lastHeader = ""
	for i = 1, #usrData do
		if lastHeader ~= usrData[i].realm then
			table_insert(profilesList, {
				colorized = usrData[i].realm,
				isHeader = true,
			})
			lastHeader = usrData[i].realm
		end
		table_insert(profilesList, {
			unitObj = usrData[i].unitObj,
			name = usrData[i].name,
			realm = usrData[i].realm,
			colorized = usrData[i].colorized
		})
	end

	return profilesList
end

local function RemoveFromRealmDB(realmDB, unitObj)
	if not realmDB then return false end
	realmDB[unitObj.name] = nil
	return true
end

local function SetupButton(button, item, scrollFrame)
	button:SetID(item.index)
	button.data = item
	button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
	button.Text:SetTextColor(1, 1, 1)
	button:SetWidth(scrollFrame.scrollChild:GetWidth())

	if item.isHeader then
		button.Text:SetJustifyH("CENTER")
		button.HeaderHighlight:SetAlpha(0.75)
		button.isHeader = true
	else
		button.Text:SetJustifyH("LEFT")
		button.HeaderHighlight:SetAlpha(0)
		button.isHeader = nil
	end
	button.Text:SetText(item.colorized or "")
end

local function SetupProfileFrame(profilesFrame)
	profilesFrame.infoText = UI:CreateFontString(profilesFrame, {
		template = "GameFontHighlightSmall",
		text = L.DeleteWarning,
		font = { STANDARD_TEXT_FONT, 12, "" },
		textColor = { 1, 0, 0 },
		point = { "LEFT", profilesFrame, "TOPLEFT", 15, -35 },
		justifyH = "LEFT",
		width = profilesFrame:GetWidth() - 15,
	})

	Profiles.scrollFrame = UI:CreateHybridScrollFrame(profilesFrame, {
		width = 397,
		pointTopLeft = { "TOPLEFT", profilesFrame, "TOPLEFT", 13, -48 },
		pointBottomLeft = { "BOTTOMLEFT", profilesFrame, "BOTTOMLEFT", -25, 15 },
		buttonTemplate = "BagSyncListSimpleItemTemplate",
		update = function() Profiles:RefreshList() end,
	})

	Profiles.profilesList = {}

	StaticPopupDialogs["BAGSYNC_PROFILES_REMOVE"] = {
		text = L.ProfilesRemove,
		button1 = "Yes",
		button2 = "No",
		hasEditBox = false,
		timeout = 0,
		exclusive = 1,
		hideOnEscape = 1,
		OnShow = function(self)
			local textObj = self.Text
			textObj:SetText(L.ProfilesRemove:format(self.data.colorized, self.data.realm))
		end,
		OnAccept = function(self)
			Profiles:DeleteUnit(self.data)
		end,
		whileDead = 1,
	}
end

-- ============================================================================
-- Module Functions
-- ============================================================================

function Profiles:OnEnable()
	local profilesFrame = UI:CreateModuleFrame(Profiles, {
		template = "BagSyncFrameTemplate",
		globalName = "BagSyncProfilesFrame",
		title = "BagSync - "..L.Profiles,
		height = 506,
		width = 440,
		point = { "CENTER", UIParent, "CENTER", 0, 0 },
		onShow = function() Profiles:OnShow() end,
	})

	Profiles.frame = profilesFrame
	SetupProfileFrame(profilesFrame)
	profilesFrame:Hide()
end

function Profiles:OnShow()
	BSYC:SetBSYC_FrameLevel(Profiles)
	Profiles:UpdateList()
end

function Profiles:UpdateList()
	Profiles.profilesList = BuildSortedProfileList()
	Profiles:RefreshList()

	HybridScrollFrame_SetOffset(Profiles.scrollFrame, 0)
	Profiles.scrollFrame.scrollBar:SetValue(0)
end

function Profiles:RefreshList()
	local items = Profiles.profilesList
	local buttons = HybridScrollFrame_GetButtons(Profiles.scrollFrame)
	local offset = HybridScrollFrame_GetOffset(Profiles.scrollFrame)

	if not buttons then return end

	for buttonIndex = 1, #buttons do
		local button = buttons[buttonIndex]
		UI:AttachListItemHandlers(button, Profiles)

		local itemIndex = buttonIndex + offset

		if itemIndex <= #items then
			local item = items[itemIndex]
			item.index = itemIndex
			SetupButton(button, item, Profiles.scrollFrame)

			if BSYC:IsMouseOver(button) then
				Profiles:Item_OnLeave()
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
	if not entry then
		BSYC:Print(L.ErrorUserNotFound)
		return
	end

	local realmDB = BagSyncDB and BagSyncDB[entry.unitObj.realm]

	if not entry.unitObj.isGuild then
		if entry.unitObj.data == BSYC.db.player then
			if RemoveFromRealmDB(realmDB, entry.unitObj) then
				Data:FixDB()
			end
			ReloadUI()
			return
		else
			BSYC:Print(L.ProfileBeenRemoved:format(entry.colorized, entry.unitObj.realm))
			RemoveFromRealmDB(realmDB, entry.unitObj)
		end
	else
		BSYC:Print(L.GuildRemoved:format(entry.colorized))
		RemoveFromRealmDB(realmDB, entry.unitObj)
	end

	Data:FixDB()
	Profiles:UpdateList()
	Tooltip:ResetCache()
end

function Profiles:Item_OnEnter(btn)
	if btn.isHeader then
		if btn.Highlight:IsVisible() then
			btn.Highlight:Hide()
		end
		return
	end

	if not btn.Highlight:IsVisible() then
		btn.Highlight:Show()
	end

	GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
	if not btn.data.unitObj.isGuild then
		GameTooltip:AddLine("|cFFFFFFFF"..PLAYER..":|r  "..btn.data.colorized)
	else
		GameTooltip:AddLine("|cFFFFFFFF"..GUILD..":|r  "..btn.data.colorized)
		GameTooltip:AddLine("|cFFFFFFFF"..L.Realm.."|r  "..btn.data.realm)
		GameTooltip:AddLine("|cFFFFFFFF"..L.TooltipRealmKey.."|r "..(btn.data.unitObj.data.realmKey or "?"))
	end
	GameTooltip:Show()
end

function Profiles:Item_OnLeave()
	GameTooltip:Hide()
end

function Profiles:Item_OnClick(btn)
	if not btn.isHeader then
		StaticPopup_Show("BAGSYNC_PROFILES_REMOVE", '', '', btn.data)
	end
end
