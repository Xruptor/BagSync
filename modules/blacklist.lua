--[[
	blacklist.lua
		A blacklist frame for BagSync items

		BagSync - All Rights Reserved - (c) 2024
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Blacklist = BSYC:NewModule("Blacklist")
local Data = BSYC:GetModule("Data")
local Unit = BSYC:GetModule("Unit")
local Tooltip = BSYC:GetModule("Tooltip")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Blacklist", ...) end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

function Blacklist:OnEnable()
	local blacklistFrame = _G.CreateFrame("Frame", nil, UIParent, "BagSyncFrameTemplate")
	Mixin(blacklistFrame, Blacklist) --implement new frame to our parent module Mixin, to have access to parent methods
	_G["BagSyncBlacklistFrame"] = blacklistFrame
    --Add to special frames so window can be closed when the escape key is pressed.
    tinsert(UISpecialFrames, "BagSyncBlacklistFrame")
    blacklistFrame.TitleText:SetText("BagSync - "..L.Blacklist)
    blacklistFrame:SetHeight(506) --irregular height to allow the scroll frame to fit the bottom most button
	blacklistFrame:SetWidth(380)
    blacklistFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    blacklistFrame:EnableMouse(true) --don't allow clickthrough
    blacklistFrame:SetMovable(true)
    blacklistFrame:SetResizable(false)
    blacklistFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	blacklistFrame:RegisterForDrag("LeftButton")
	blacklistFrame:SetClampedToScreen(true)
	blacklistFrame:SetScript("OnDragStart", blacklistFrame.StartMoving)
	blacklistFrame:SetScript("OnDragStop", blacklistFrame.StopMovingOrSizing)
	local closeBtn = CreateFrame("Button", nil, blacklistFrame, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", C_EditMode and -3 or 2, C_EditMode and -3 or 1) --check for classic servers to adjust for positioning using a check for the new EditMode
	blacklistFrame.closeBtn = closeBtn
    blacklistFrame:SetScript("OnShow", function() Blacklist:OnShow() end)
    Blacklist.frame = blacklistFrame

	--guild dropdown
	local guildDD = CreateFrame("Frame", nil, blacklistFrame, "UIDropDownMenuTemplate")
	guildDD:SetPoint("LEFT", blacklistFrame, "TOPLEFT", 0, -40)
	UIDropDownMenu_SetWidth(guildDD, 200)
	UIDropDownMenu_SetText(guildDD, L.Tooltip_guild)
	blacklistFrame.guildDD = guildDD

	--add guild button
	blacklistFrame.addGuildBtn = _G.CreateFrame("Button", nil, blacklistFrame, "UIPanelButtonTemplate")
	blacklistFrame.addGuildBtn:SetText(L.AddGuild)
	blacklistFrame.addGuildBtn:SetHeight(20)
	blacklistFrame.addGuildBtn:SetWidth(blacklistFrame.addGuildBtn:GetTextWidth() + 30)
	blacklistFrame.addGuildBtn:SetPoint("LEFT", guildDD, "RIGHT", -10, 2)
	blacklistFrame.addGuildBtn:SetScript("OnClick", function() Blacklist:AddGuild() end)

	local itemIDBox = CreateFrame("EditBox", nil, blacklistFrame, "InputBoxTemplate")
	itemIDBox:SetSize(210, 20)
	itemIDBox:SetPoint("LEFT", blacklistFrame, "TOPLEFT", 20, -70)
	itemIDBox:SetAutoFocus(false)
	itemIDBox:SetText("")
	blacklistFrame.itemIDBox = itemIDBox

	--add itemID button
	blacklistFrame.addItemIDBtn = _G.CreateFrame("Button", nil, blacklistFrame, "UIPanelButtonTemplate")
	blacklistFrame.addItemIDBtn:SetText(L.AddItemID)
	blacklistFrame.addItemIDBtn:SetHeight(20)
	blacklistFrame.addItemIDBtn:SetWidth(blacklistFrame.addItemIDBtn:GetTextWidth() + 30)
	blacklistFrame.addItemIDBtn:SetPoint("LEFT", itemIDBox, "RIGHT", 5, 2)
	blacklistFrame.addItemIDBtn:SetScript("OnClick", function() Blacklist:AddItemID() end)

	blacklistFrame.infoText = blacklistFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	blacklistFrame.infoText:SetText(L.UseFakeID)
	blacklistFrame.infoText:SetFont(STANDARD_TEXT_FONT, 12, "")
	blacklistFrame.infoText:SetTextColor(1, 165/255, 0)
	blacklistFrame.infoText:SetPoint("LEFT", blacklistFrame, "TOPLEFT", 15, -90)
	blacklistFrame.infoText:SetJustifyH("LEFT")
	blacklistFrame.infoText:SetWidth(blacklistFrame:GetWidth() - 15)

    Blacklist.scrollFrame = _G.CreateFrame("ScrollFrame", nil, blacklistFrame, "HybridScrollFrameTemplate")
    Blacklist.scrollFrame:SetWidth(337)
    Blacklist.scrollFrame:SetPoint("TOPLEFT", blacklistFrame, "TOPLEFT", 13, -100)
    --set ScrollFrame height by altering the distance from the bottom of the frame
    Blacklist.scrollFrame:SetPoint("BOTTOMLEFT", blacklistFrame, "BOTTOMLEFT", -25, 15)
    Blacklist.scrollFrame.scrollBar = CreateFrame("Slider", "$parentscrollBar", Blacklist.scrollFrame, "HybridScrollBarTemplate")
    Blacklist.scrollFrame.scrollBar:SetPoint("TOPLEFT", Blacklist.scrollFrame, "TOPRIGHT", 1, -16)
    Blacklist.scrollFrame.scrollBar:SetPoint("BOTTOMLEFT", Blacklist.scrollFrame, "BOTTOMRIGHT", 1, 12)
	--initiate the scrollFrame
    --the items we will work with
    Blacklist.listItems = {}
	Blacklist.scrollFrame.update = function() Blacklist:RefreshList(); end
    HybridScrollFrame_SetDoNotHideScrollBar(Blacklist.scrollFrame, true)
	HybridScrollFrame_CreateButtons(Blacklist.scrollFrame, "BagSyncListSimpleItemTemplate")

	StaticPopupDialogs["BAGSYNC_BLACKLIST_REMOVE"] = {
		text = L.BlackListRemove,
		button1 = "Yes",
		button2 = "No",
		hasEditBox = false,
		timeout = 0,
		exclusive = 1,
		hideOnEscape = 1,
		OnShow = function (self)
			self.text:SetText(L.BlackListRemove:format(self.data.value));
		end,
		OnAccept = function (self)
			Blacklist:RemoveData(self.data)
		end,
		whileDead = 1,
	}

	blacklistFrame:Hide()
end

function Blacklist:OnShow()
	BSYC:SetBSYC_FrameLevel(Blacklist)
	Blacklist:UpdateList()
end

function Blacklist:UpdateList()
	Blacklist.frame.itemIDBox:ClearFocus()
	Blacklist:CreateList()
    Blacklist:RefreshList()

	--scroll to top when shown
	HybridScrollFrame_SetOffset(Blacklist.scrollFrame, 0)
	Blacklist.scrollFrame.scrollBar:SetValue(0)
end

function Blacklist:CreateList()
	Blacklist.listItems = {}
	Blacklist.selectedGuild = nil

	--do the dropdown first
	local tmp = {}
	for unitObj in Data:IterateUnits() do
		if unitObj.isGuild then
			local guildName = select(2, Unit:GetUnitAddress(unitObj.name))
			local key = unitObj.name..unitObj.realm --note key is different then displayed name
			tmp[key] = guildName.." - "..unitObj.realm
		end
	end
	table.sort(tmp, function(a,b) return (a < b) end)

	UIDropDownMenu_Initialize(Blacklist.frame.guildDD, function(self)
		local info = UIDropDownMenu_CreateInfo()
		for k, v in pairs(tmp) do
			info.text, info.value, info.arg1 = v, k, v
			info.notCheckable = true
			info.func = function(data)
				self.Text:SetText(data.arg1)
				Blacklist.selectedGuild = data
			end
			UIDropDownMenu_AddButton(info)
		end
	end)

	local dataObj = {}

	--loop through our blacklist
	for k, v in pairs(BSYC.db.blacklist) do
		table.insert(dataObj, {
			key = k,
			value = v
		})
	end

	if #dataObj > 0 then
		table.sort(dataObj, function(a,b) return (a.value < b.value) end)
		for i=1, #dataObj do
			table.insert(Blacklist.listItems, {
				key = dataObj[i].key,
				value = dataObj[i].value
			})
		end
	end
end

function Blacklist:RefreshList()
    local items = Blacklist.listItems
    local buttons = HybridScrollFrame_GetButtons(Blacklist.scrollFrame)
    local offset = HybridScrollFrame_GetOffset(Blacklist.scrollFrame)
	if not buttons then return end

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
		button.parentHandler = Blacklist

        local itemIndex = buttonIndex + offset

        if itemIndex <= #items then
            local item = items[itemIndex]

            button:SetID(itemIndex)
			button.data = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
            button:SetWidth(Blacklist.scrollFrame.scrollChild:GetWidth())

			button.Text:SetJustifyH("LEFT")
			if not tonumber(item.key) then
				--is guild
				button.Text:SetTextColor(101/255, 184/255, 	192/255)
			else
				button.Text:SetTextColor(1, 1, 1)
			end
			button.Text:SetText(item.value or "")
			button.HeaderHighlight:SetAlpha(0)

			if BSYC.GMF() == button then
				Blacklist:Item_OnLeave() --hide first
				Blacklist:Item_OnEnter(button)
			end

            button:Show()
        else
            button:Hide()
        end
    end

    local buttonHeight = Blacklist.scrollFrame.buttonHeight
    local totalHeight = #items * buttonHeight
    local shownHeight = #buttons * buttonHeight

    HybridScrollFrame_Update(Blacklist.scrollFrame, totalHeight, shownHeight)
end

function Blacklist:AddItemID()
	local editBox = Blacklist.frame.itemIDBox

	editBox:ClearFocus()
	local itemid = editBox:GetText()

	if not itemid or string.len(editBox:GetText()) < 1 or not tonumber(itemid) then
		BSYC:Print(L.EnterItemID)
		editBox:SetText("")
		return
	end

	itemid = tonumber(itemid)

	if BSYC.db.blacklist[itemid] then
		BSYC:Print(L.ItemIDExistBlacklist:format(itemid))
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
		BSYC.db.blacklist[itemid] = "|cFFCF9FFF"..speciesName.."|r"
		BSYC:Print(L.ItemIDAdded:format(itemid), speciesName)
	else
		if not C_Item.GetItemInfo(itemid) then
			BSYC:Print(L.ItemIDNotValid:format(itemid))
			editBox:SetText("")
			return
		end

		local dName, dItemLink = C_Item.GetItemInfo(itemid)

		BSYC.db.blacklist[itemid] = dItemLink
		BSYC:Print(L.ItemIDAdded:format(itemid), dItemLink)
	end
	editBox:SetText("")

	Blacklist:UpdateList()
end

function Blacklist:AddGuild()
	if not Blacklist.selectedGuild then return end

	if BSYC.db.blacklist[Blacklist.selectedGuild.value] then
		BSYC:Print(L.GuildExist:format(Blacklist.selectedGuild.arg1))
		return
	end

	BSYC.db.blacklist[Blacklist.selectedGuild.value] = Blacklist.selectedGuild.arg1
	BSYC:Print(L.GuildAdded:format(Blacklist.selectedGuild.arg1))

	Blacklist:UpdateList()
end

function Blacklist:RemoveData(entry)
	if BSYC.db.blacklist[entry.key] then
		if type(entry.key) == "number" then
			BSYC:Print(L.ItemIDRemoved:format(entry.value))
		else
			BSYC:Print(L.GuildRemoved:format(entry.value))
		end
		BSYC.db.blacklist[entry.key] = nil
		Blacklist:UpdateList()
		--reset tooltip cache since we have blacklisted some items or guilds
		Tooltip:ResetCache()
	else
		BSYC:Print(L.BlackListErrorRemove)
	end
end

function Blacklist:Item_OnEnter(btn)
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

function Blacklist:Item_OnLeave()
	GameTooltip:Hide()
	if BattlePetTooltip then BattlePetTooltip:Hide() end
end

function Blacklist:Item_OnClick(btn)
	StaticPopup_Show("BAGSYNC_BLACKLIST_REMOVE", '', '', btn.data) --cannot pass nil as it's expected for SetFormattedText (Interface/FrameXML/StaticPopup.lua)
end
