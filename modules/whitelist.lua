--[[
	whitelist.lua
		A whitelist frame for BagSync items

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...) --grab the addon namespace
local UI = BSYC:GetModule("UI")
local Whitelist = BSYC:NewModule("Whitelist")
local Tooltip = BSYC:GetModule("Tooltip")

-- Cache global references
local GameTooltip = _G.GameTooltip
local BattlePetTooltip = _G.BattlePetTooltip
local HybridScrollFrame_GetButtons = _G.HybridScrollFrame_GetButtons
local HybridScrollFrame_GetOffset = _G.HybridScrollFrame_GetOffset
local HybridScrollFrame_SetOffset = _G.HybridScrollFrame_SetOffset
local HybridScrollFrame_Update = _G.HybridScrollFrame_Update
local C_PetJournal = _G.C_PetJournal
local StaticPopup_Show = _G.StaticPopup_Show
local BattlePetToolTip_Show = _G.BattlePetToolTip_Show

local L = BSYC.L

-------------------- Helper Functions --------------------

-- Clear editbox text and reset it (eliminates 6 duplicate blocks)
local function ClearAndResetEditBox(editBox)
	editBox:ClearFocus()
	editBox:SetText("")
end

-- Validate pet item and get species info
local function ValidatePetItem(itemid)
	local speciesID = BSYC:FakeIDToSpeciesID(itemid)
	if not speciesID then
		return nil
	end

	local speciesName = C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID(speciesID)
	if not speciesName then
		return nil
	end

	return speciesID, speciesName
end

-- Get display name for pet item
local function GetPetItemName(itemid)
	local _, speciesName = ValidatePetItem(itemid)
	if not speciesName then
		return nil
	end
	return "|cFFCF9FFF"..speciesName.."|r"
end

-- Validate standard item
local function ValidateStandardItem(itemid)
	local getItemInfo = BSYC.API.GetItemInfo
	if not (getItemInfo and getItemInfo(itemid)) then
		return nil
	end
	return true
end

-- Get display name for standard item
local function GetStandardItemName(itemid)
	local getItemInfo = BSYC.API.GetItemInfo
	if not (getItemInfo and getItemInfo(itemid)) then
		return nil
	end

	local _, itemLink = getItemInfo(itemid)
	return itemLink
end

-- Show pet tooltip
local function ShowPetTooltip(itemid)
	local speciesID = BSYC:FakeIDToSpeciesID(itemid)
	if speciesID then
		BattlePetToolTip_Show(speciesID, 0, 0, 0, 0, 0, nil)
	end
end

-- Show standard item tooltip
local function ShowStandardItemTooltip(itemid)
	GameTooltip:SetHyperlink("item:"..itemid)
end

-------------------- Module Functions --------------------

function Whitelist:OnEnable()
	local whitelistFrame = UI:CreateModuleFrame(Whitelist, {
		template = "BagSyncFrameTemplate",
		globalName = "BagSyncWhitelistFrame",
		title = "BagSync - "..L.Whitelist,
		height = 506, --irregular height to allow the scroll frame to fit the bottom most button
		width = 380,
		point = { "CENTER", UIParent, "CENTER", 0, 0 },
		onShow = function() Whitelist:OnShow() end,
	})
	Whitelist.frame = whitelistFrame

	local itemIDBox = UI:CreateEditBox(whitelistFrame, {
		template = "InputBoxTemplate",
		size = { 210, 20 },
		point = { "LEFT", whitelistFrame, "TOPLEFT", 20, -40 },
		autoFocus = false,
		text = "",
	})
	whitelistFrame.itemIDBox = itemIDBox

	--add itemID button
	whitelistFrame.addItemIDBtn = UI:CreateButton(whitelistFrame, {
		template = "UIPanelButtonTemplate",
		text = L.AddItemID,
		height = 20,
		autoWidth = true,
		point = { "LEFT", itemIDBox, "RIGHT", 5, 2 },
		onClick = function() Whitelist:AddItemID() end,
	})

	whitelistFrame.infoText = UI:CreateFontString(whitelistFrame, {
		template = "GameFontHighlightSmall",
		text = L.UseFakeID,
		font = { STANDARD_TEXT_FONT, 12, "" },
		textColor = { 1, 165/255, 0 },
		point = { "LEFT", whitelistFrame, "TOPLEFT", 15, -60 },
		justifyH = "LEFT",
		width = whitelistFrame:GetWidth() - 15,
	})

	Whitelist.scrollFrame = UI:CreateHybridScrollFrame(whitelistFrame, {
		width = 337,
		pointTopLeft = { "TOPLEFT", whitelistFrame, "TOPLEFT", 13, -70 },
		-- set ScrollFrame height by altering the distance from the bottom of the frame
		pointBottomLeft = { "BOTTOMLEFT", whitelistFrame, "BOTTOMLEFT", -25, 15 },
		buttonTemplate = "BagSyncListSimpleItemTemplate",
		update = function() Whitelist:RefreshList(); end,
	})
	--the items we will work with
	Whitelist.listItems = {}

	--Warning Frame
	local warningFrame = UI:CreateInfoFrame(whitelistFrame, {
		title = L.DisplayWhitelistHelp,
		height = 500,
		point = { "TOPLEFT", whitelistFrame, "TOPRIGHT", 5, 0 },
		backdropColor = { 0, 0, 0, 0.75 },
		frameStrata = "FULLSCREEN_DIALOG",
	})
	warningFrame.infoText1 = UI:CreateFontString(warningFrame, {
		template = "GameFontHighlightSmall",
		text = L.DisplayWhitelistStatus,
		font = { STANDARD_TEXT_FONT, 14, "" },
		textColor = { 1, 165/255, 0 }, --orange, red is just too much sometimes
		justifyH = "CENTER",
		width = warningFrame:GetWidth() - 30,
		point = { "LEFT", warningFrame, "TOPLEFT", 10, -40 },
	})
	warningFrame.infoText2 = UI:CreateFontString(warningFrame, {
		template = "GameFontHighlightSmall",
		text = L.DisplayWhitelistHelpInfo..L.DisplayWhitelistHelpInfo2,
		font = { STANDARD_TEXT_FONT, 14, "" },
		textColor = { 50/255, 165/255, 0 },
		width = warningFrame:GetWidth() - 30,
		point = { "LEFT", warningFrame.infoText1, "BOTTOMLEFT", 5, -200 },
		justifyH = "CENTER",
	})
	Whitelist.warningFrame = warningFrame
	StaticPopupDialogs["BAGSYNC_WHITELIST_REMOVE"] = {
		text = L.WhiteListRemove,
		button1 = "Yes",
		button2 = "No",
		hasEditBox = false,
		timeout = 0,
		exclusive = 1,
		hideOnEscape = 1,
		OnShow = function (self)
			local tObj = self.text or self.Text
			tObj:SetText(L.WhiteListRemove:format(self.data.value));
		end,
		OnAccept = function (self)
			Whitelist:RemoveData(self.data)
		end,
		whileDead = 1,
	}

	whitelistFrame:Hide()
end

function Whitelist:OnShow()
	BSYC:SetBSYC_FrameLevel(Whitelist)

	local getStatus = (BSYC.options.enableWhitelist and ("|cFF99CC33"..L.ON.."|r")) or ( "|cFFDF2B2B"..L.OFF.."|r")
	Whitelist.warningFrame.infoText1:SetText(L.DisplayWhitelistStatus:format(getStatus))
	Whitelist.warningFrame:Show()
	Whitelist:UpdateList()
end

function Whitelist:UpdateList()
	Whitelist.frame.itemIDBox:ClearFocus()
	Whitelist:CreateList()
	Whitelist:RefreshList()

	--scroll to top when shown
	HybridScrollFrame_SetOffset(Whitelist.scrollFrame, 0)
	Whitelist.scrollFrame.scrollBar:SetValue(0)
end

function Whitelist:CreateList()
	local listItems = {}

	--loop through our whitelist
	for k, v in pairs(BSYC.db.whitelist) do
		listItems[#listItems + 1] = {
			key = k,
			value = v
		}
	end

	if #listItems > 0 then
		table.sort(listItems, function(a, b) return (a.value or "") < (b.value or "") end)
	end

	Whitelist.listItems = listItems
end

function Whitelist:RefreshList()
	local items = Whitelist.listItems
	local buttons = HybridScrollFrame_GetButtons(Whitelist.scrollFrame)
	local offset = HybridScrollFrame_GetOffset(Whitelist.scrollFrame)
	if not buttons then return end

	for buttonIndex = 1, #buttons do
		local button = buttons[buttonIndex]
		UI:AttachListItemHandlers(button, Whitelist)

		local itemIndex = buttonIndex + offset

		if itemIndex <= #items then
			local item = items[itemIndex]

			button:SetID(itemIndex)
			button.data = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
			button:SetWidth(Whitelist.scrollFrame.scrollChild:GetWidth())

			button.Text:SetJustifyH("LEFT")
			button.Text:SetTextColor(1, 1, 1)
			button.Text:SetText(item.value or "")
			button.HeaderHighlight:SetAlpha(0)

			if BSYC:IsMouseOver(button) then
				Whitelist:Item_OnLeave() --hide first
				Whitelist:Item_OnEnter(button)
			end

			button:Show()
		else
			button:Hide()
		end
	end

	local buttonHeight = Whitelist.scrollFrame.buttonHeight
	local totalHeight = #items * buttonHeight
	local shownHeight = #buttons * buttonHeight

	HybridScrollFrame_Update(Whitelist.scrollFrame, totalHeight, shownHeight)
end

function Whitelist:AddItemID()
	local editBox = Whitelist.frame.itemIDBox
	editBox:ClearFocus()
	local itemid = editBox:GetText()

	-- Validate input
	if not itemid or #itemid < 1 then
		BSYC:Print(L.EnterItemID)
		ClearAndResetEditBox(editBox)
		return
	end

	itemid = tonumber(itemid)
	if not itemid then
		BSYC:Print(L.EnterItemID)
		ClearAndResetEditBox(editBox)
		return
	end

	-- Check if already exists
	if BSYC.db.whitelist[itemid] then
		BSYC:Print(L.ItemIDExistWhitelist:format(itemid))
		ClearAndResetEditBox(editBox)
		return
	end

	-- Handle pet items (FakePetCode and above)
	if itemid >= BSYC.FakePetCode then
		local _, speciesName = ValidatePetItem(itemid)
		if not speciesName then
			BSYC:Print(L.ItemIDNotValid:format(itemid))
			ClearAndResetEditBox(editBox)
			return
		end

		BSYC.db.whitelist[itemid] = GetPetItemName(itemid)
		BSYC:Print(L.ItemIDAdded:format(itemid), speciesName)
	else
		-- Handle standard items
		if not ValidateStandardItem(itemid) then
			BSYC:Print(L.ItemIDNotValid:format(itemid))
			ClearAndResetEditBox(editBox)
			return
		end

		local itemName = GetStandardItemName(itemid)
		BSYC.db.whitelist[itemid] = itemName
		BSYC:Print(L.ItemIDAdded:format(itemid), itemName)
	end

	ClearAndResetEditBox(editBox)
	Whitelist:UpdateList()
end

function Whitelist:RemoveData(entry)
	if BSYC.db.whitelist[entry.key] then
		BSYC:Print(L.ItemIDRemoved:format(entry.value))
		BSYC.db.whitelist[entry.key] = nil
		Whitelist:UpdateList()
		--reset tooltip cache since we have whitelisted some items or guilds
		Tooltip:ResetCache()
	else
		BSYC:Print(L.WhiteListErrorRemove)
	end
end

function Whitelist:Item_OnEnter(btn)
	GameTooltip:SetOwner(btn, "ANCHOR_BOTTOMRIGHT")

	if type(btn.data.key) == "number" then
		if tonumber(btn.data.key) >= BSYC.FakePetCode then
			ShowPetTooltip(btn.data.key)
		else
			ShowStandardItemTooltip(btn.data.key)
		end
	else
		GameTooltip:AddLine(btn.data.value)
		GameTooltip:AddLine(L.TooltipRealmKey.." "..btn.data.key)
	end
	GameTooltip:Show()
end

function Whitelist:Item_OnLeave()
	GameTooltip:Hide()
	if BattlePetTooltip then BattlePetTooltip:Hide() end
end

function Whitelist:Item_OnClick(btn)
	StaticPopup_Show("BAGSYNC_WHITELIST_REMOVE", '', '', btn.data) --cannot pass nil as it's expected for SetFormattedText (Interface/FrameXML/StaticPopup.lua)
end
