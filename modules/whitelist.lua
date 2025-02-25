--[[
	whitelist.lua
		A whitelist frame for BagSync items

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Whitelist = BSYC:NewModule("Whitelist")
local Tooltip = BSYC:GetModule("Tooltip")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Whitelist", ...) end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

function Whitelist:OnEnable()
	local whitelistFrame = _G.CreateFrame("Frame", nil, UIParent, "BagSyncFrameTemplate")
	Mixin(whitelistFrame, Whitelist) --implement new frame to our parent module Mixin, to have access to parent methods
	_G["BagSyncWhitelistFrame"] = whitelistFrame
    --Add to special frames so window can be closed when the escape key is pressed.
    tinsert(UISpecialFrames, "BagSyncWhitelistFrame")
    whitelistFrame.TitleText:SetText("BagSync - "..L.Whitelist)
    whitelistFrame:SetHeight(506) --irregular height to allow the scroll frame to fit the bottom most button
	whitelistFrame:SetWidth(380)
    whitelistFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    whitelistFrame:EnableMouse(true) --don't allow clickthrough
    whitelistFrame:SetMovable(true)
    whitelistFrame:SetResizable(false)
    whitelistFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	whitelistFrame:RegisterForDrag("LeftButton")
	whitelistFrame:SetClampedToScreen(true)
	whitelistFrame:SetScript("OnDragStart", whitelistFrame.StartMoving)
	whitelistFrame:SetScript("OnDragStop", whitelistFrame.StopMovingOrSizing)
	whitelistFrame:SetScript("OnShow", function() Whitelist:OnShow() end)
	local closeBtn = CreateFrame("Button", nil, whitelistFrame, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", C_EditMode and -3 or 2, C_EditMode and -3 or 1) --check for classic servers to adjust for positioning using a check for the new EditMode			
    whitelistFrame.closeBtn = closeBtn
    Whitelist.frame = whitelistFrame

	local itemIDBox = CreateFrame("EditBox", nil, whitelistFrame, "InputBoxTemplate")
	itemIDBox:SetSize(210, 20)
	itemIDBox:SetPoint("LEFT", whitelistFrame, "TOPLEFT", 20, -40)
	itemIDBox:SetAutoFocus(false)
	itemIDBox:SetText("")
	whitelistFrame.itemIDBox = itemIDBox

	--add itemID button
	whitelistFrame.addItemIDBtn = _G.CreateFrame("Button", nil, whitelistFrame, "UIPanelButtonTemplate")
	whitelistFrame.addItemIDBtn:SetText(L.AddItemID)
	whitelistFrame.addItemIDBtn:SetHeight(20)
	whitelistFrame.addItemIDBtn:SetWidth(whitelistFrame.addItemIDBtn:GetTextWidth() + 30)
	whitelistFrame.addItemIDBtn:SetPoint("LEFT", itemIDBox, "RIGHT", 5, 2)
	whitelistFrame.addItemIDBtn:SetScript("OnClick", function() Whitelist:AddItemID() end)

	whitelistFrame.infoText = whitelistFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	whitelistFrame.infoText:SetText(L.UseFakeID)
	whitelistFrame.infoText:SetFont(STANDARD_TEXT_FONT, 12, "")
	whitelistFrame.infoText:SetTextColor(1, 165/255, 0)
	whitelistFrame.infoText:SetPoint("LEFT", whitelistFrame, "TOPLEFT", 15, -60)
	whitelistFrame.infoText:SetJustifyH("LEFT")
	whitelistFrame.infoText:SetWidth(whitelistFrame:GetWidth() - 15)

    Whitelist.scrollFrame = _G.CreateFrame("ScrollFrame", nil, whitelistFrame, "HybridScrollFrameTemplate")
    Whitelist.scrollFrame:SetWidth(337)
    Whitelist.scrollFrame:SetPoint("TOPLEFT", whitelistFrame, "TOPLEFT", 13, -70)
    --set ScrollFrame height by altering the distance from the bottom of the frame
    Whitelist.scrollFrame:SetPoint("BOTTOMLEFT", whitelistFrame, "BOTTOMLEFT", -25, 15)
    Whitelist.scrollFrame.scrollBar = CreateFrame("Slider", "$parentscrollBar", Whitelist.scrollFrame, "HybridScrollBarTemplate")
    Whitelist.scrollFrame.scrollBar:SetPoint("TOPLEFT", Whitelist.scrollFrame, "TOPRIGHT", 1, -16)
    Whitelist.scrollFrame.scrollBar:SetPoint("BOTTOMLEFT", Whitelist.scrollFrame, "BOTTOMRIGHT", 1, 12)
	--initiate the scrollFrame
    --the items we will work with
    Whitelist.listItems = {}
	Whitelist.scrollFrame.update = function() Whitelist:RefreshList(); end
    HybridScrollFrame_SetDoNotHideScrollBar(Whitelist.scrollFrame, true)
	HybridScrollFrame_CreateButtons(Whitelist.scrollFrame, "BagSyncListSimpleItemTemplate")

	--Warning Frame
	local warningFrame = _G.CreateFrame("Frame", nil, whitelistFrame, "BagSyncInfoFrameTemplate")
	warningFrame:Hide()
	warningFrame:SetHeight(500)
	warningFrame:SetBackdropColor(0, 0, 0, 0.75)
    warningFrame:EnableMouse(true) --don't allow clickthrough
    warningFrame:SetMovable(false)
	warningFrame:SetResizable(false)
    warningFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	warningFrame:ClearAllPoints()
	warningFrame:SetPoint("TOPLEFT", whitelistFrame, "TOPRIGHT", 5, 0)
	warningFrame.TitleText:SetText(L.DisplayWhitelistHelp)
	warningFrame.TitleText:SetFont(STANDARD_TEXT_FONT, 14, "")
	warningFrame.TitleText:SetTextColor(1, 1, 1)
	warningFrame.infoText1 = warningFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	warningFrame.infoText1:SetText(L.DisplayWhitelistStatus)
	warningFrame.infoText1:SetFont(STANDARD_TEXT_FONT, 14, "")
	warningFrame.infoText1:SetTextColor(1, 165/255, 0) --orange, red is just too much sometimes
	warningFrame.infoText1:SetJustifyH("CENTER")
	warningFrame.infoText1:SetWidth(warningFrame:GetWidth() - 30)
	warningFrame.infoText1:SetPoint("LEFT", warningFrame, "TOPLEFT", 10, -40)
	warningFrame.infoText2 = warningFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	warningFrame.infoText2:SetText(L.DisplayWhitelistHelpInfo..L.DisplayWhitelistHelpInfo2)
	warningFrame.infoText2:SetFont(STANDARD_TEXT_FONT, 14, "")
	warningFrame.infoText2:SetTextColor(50/255, 165/255, 0)
	warningFrame.infoText2:SetWidth(warningFrame:GetWidth() - 30)
	warningFrame.infoText2:SetPoint("LEFT", warningFrame.infoText1, "BOTTOMLEFT", 5, -200)
	warningFrame.infoText2:SetJustifyH("CENTER")
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
			self.text:SetText(L.WhiteListRemove:format(self.data.value));
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
	Whitelist.listItems = {}
	local dataObj = {}

	--loop through our whitelist
	for k, v in pairs(BSYC.db.whitelist) do
		table.insert(dataObj, {
			key = k,
			value = v
		})
	end

	if #dataObj > 0 then
		table.sort(dataObj, function(a,b) return (a.value < b.value) end)
		for i=1, #dataObj do
			table.insert(Whitelist.listItems, {
				key = dataObj[i].key,
				value = dataObj[i].value
			})
		end
	end
end

function Whitelist:RefreshList()
    local items = Whitelist.listItems
    local buttons = HybridScrollFrame_GetButtons(Whitelist.scrollFrame)
    local offset = HybridScrollFrame_GetOffset(Whitelist.scrollFrame)
	if not buttons then return end

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
		button.parentHandler = Whitelist

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

			if BSYC.GMF() == button then
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

	if not itemid or string.len(editBox:GetText()) < 1 or not tonumber(itemid) then
		BSYC:Print(L.EnterItemID)
		editBox:SetText("")
		return
	end

	itemid = tonumber(itemid)

	if BSYC.db.whitelist[itemid] then
		BSYC:Print(L.ItemIDExistWhitelist:format(itemid))
		editBox:SetText("")
		return
	end
	if itemid >= BSYC.FakePetCode then
		local speciesID = BSYC:FakeIDToSpeciesID(itemid)
		if not speciesID then
			BSYC:Print(L.ItemIDNotValid:format(itemid))
			editBox:SetText("")
			return
		end
		local speciesName = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
		if not speciesName then
			BSYC:Print(L.ItemIDNotValid:format(itemid))
			editBox:SetText("")
			return
		end
		BSYC.db.whitelist[itemid] = "|cFFCF9FFF"..speciesName.."|r"
		BSYC:Print(L.ItemIDAdded:format(itemid), speciesName)
	else
		if not C_Item.GetItemInfo(itemid) then
			BSYC:Print(L.ItemIDNotValid:format(itemid))
			editBox:SetText("")
			return
		end

		local dName, dItemLink = C_Item.GetItemInfo(itemid)

		BSYC.db.whitelist[itemid] = dItemLink
		BSYC:Print(L.ItemIDAdded:format(itemid), dItemLink)
	end
	editBox:SetText("")

	Whitelist:UpdateList()
end

function Whitelist:AddGuild()
	if not Whitelist.selectedGuild then return end

	if BSYC.db.whitelist[Whitelist.selectedGuild.value] then
		BSYC:Print(L.GuildExist:format(Whitelist.selectedGuild.arg1))
		return
	end

	BSYC.db.whitelist[Whitelist.selectedGuild.value] = Whitelist.selectedGuild.arg1
	BSYC:Print(L.GuildAdded:format(Whitelist.selectedGuild.arg1))

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
			local speciesID = BSYC:FakeIDToSpeciesID(btn.data.key)
			if speciesID then
				BattlePetToolTip_Show(speciesID, 0, 0, 0, 0, 0, nil)
			end
		else
			GameTooltip:SetHyperlink("item:"..btn.data.key)
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