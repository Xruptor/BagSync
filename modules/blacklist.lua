--[[
	blacklist.lua
		A blacklist frame for BagSync items

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...) --grab the addon namespace
local UI = BSYC:GetModule("UI")
local Blacklist = BSYC:NewModule("Blacklist")
local Data = BSYC:GetModule("Data")
local Unit = BSYC:GetModule("Unit")
local Tooltip = BSYC:GetModule("Tooltip")

local L = BSYC.L

-- Cache global API references
local GameTooltip = _G.GameTooltip
local BattlePetTooltip = _G.BattlePetTooltip
local HybridScrollFrame_GetButtons = _G.HybridScrollFrame_GetButtons
local HybridScrollFrame_GetOffset = _G.HybridScrollFrame_GetOffset
local HybridScrollFrame_SetOffset = _G.HybridScrollFrame_SetOffset
local HybridScrollFrame_Update = _G.HybridScrollFrame_Update
local UIDropDownMenu_Initialize = _G.UIDropDownMenu_Initialize
local UIDropDownMenu_CreateInfo = _G.UIDropDownMenu_CreateInfo
local UIDropDownMenu_AddButton = _G.UIDropDownMenu_AddButton
local C_PetJournal = _G.C_PetJournal
local BattlePetToolTip_Show = _G.BattlePetToolTip_Show
local StaticPopupDialogs = _G.StaticPopupDialogs
local StaticPopup_Show = _G.StaticPopup_Show

-- Cache frequently accessed constants
local FakePetCode = BSYC.FakePetCode

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Reset tooltip cache (consolidated from 3 duplicate blocks)
local function ResetTooltipCache()
	Tooltip:ResetCache()
	Tooltip:ResetLastLink()
end

-- Determine if entry is an item (number) or guild (string)
local function GetEntryType(key)
	return type(key) == "number"
end

-- Format removal message based on entry type
local function FormatRemovalMessage(entry)
	if GetEntryType(entry.key) then
		return L.ItemIDRemoved:format(entry.value)
	else
		return L.GuildRemoved:format(entry.value)
	end
end

-- Build list of guilds for dropdown
local function BuildGuildListForDropdown()
	local guildList = {}

	for unitObj in Data:IterateUnits() do
		if unitObj.isGuild then
			local guildName = select(2, Unit:GetUnitAddress(unitObj.name))
			-- note: key is different than displayed name
			local key = unitObj.name..unitObj.realm
			guildList[#guildList + 1] = {
				key = key,
				display = guildName.." - "..unitObj.realm
			}
		end
	end

	table.sort(guildList, function(a, b)
		return (a.display or "") < (b.display or "")
	end)

	return guildList
end

-- Initialize guild dropdown with sorted list
local function InitializeGuildDropdown(guildList)
	UIDropDownMenu_Initialize(Blacklist.frame.guildDD, function(dropdown)
		local info = UIDropDownMenu_CreateInfo()
		for i = 1, #guildList do
			local entry = guildList[i]
			info.text = entry.display
			info.value = entry.key
			info.arg1 = entry.display
			info.notCheckable = true
			info.func = function(data)
				dropdown.Text:SetText(data.arg1)
				Blacklist.selectedGuild = data
			end
			UIDropDownMenu_AddButton(info)
		end
	end)
end

-- Display success message for added item
local function DisplayItemAddedMessage(itemid, displayName)
	BSYC:Print(L.ItemIDAdded:format(itemid), displayName)
end

-- Validate and add a pet (battle pet) to blacklist
local function ValidateAndAddPetItem(itemid, speciesID, db)
	local petJournal = C_PetJournal or _G.C_PetJournal
	local speciesName = petJournal and petJournal.GetPetInfoBySpeciesID and petJournal.GetPetInfoBySpeciesID(speciesID)
	if not speciesName then
		BSYC:Print(L.ItemIDNotValid:format(itemid))
		return false
	end

	db[itemid] = "|cFFCF9FFF"..speciesName.."|r"
	DisplayItemAddedMessage(itemid, speciesName)
	return true
end

-- Validate and add a standard item to blacklist
local function ValidateAndAddStandardItem(itemid, getItemInfo, db)
	local _, dItemLink = getItemInfo(itemid)

	if not dItemLink then
		BSYC:Print(L.ItemIDNotValid:format(itemid))
		return false
	end

	db[itemid] = dItemLink
	DisplayItemAddedMessage(itemid, dItemLink)
	return true
end

-- Validate guild is not already blacklisted
local function ValidateGuildNotBlacklisted(guildValue)
	if BSYC.db.blacklist[guildValue] then
		BSYC:Print(L.GuildExist:format(Blacklist.selectedGuild.arg1))
		return false
	end
	return true
end

-- ============================================================================
-- Module Functions
-- ============================================================================

function Blacklist:OnEnable()
	local blacklistFrame = UI:CreateModuleFrame(Blacklist, {
		template = "BagSyncFrameTemplate",
		globalName = "BagSyncBlacklistFrame",
		title = "BagSync - "..L.Blacklist,
		height = 506, -- irregular height to allow scroll frame to fit bottom button
		width = 380,
		point = { "CENTER", UIParent, "CENTER", 0, 0 },
		onShow = function() Blacklist:OnShow() end,
	})
	Blacklist.frame = blacklistFrame

	-- guild dropdown
	local guildDD = UI:CreateDropdown(blacklistFrame, {
		point = { "LEFT", blacklistFrame, "TOPLEFT", 0, -40 },
		width = 200,
		text = L.Tooltip_guild,
	})
	blacklistFrame.guildDD = guildDD

	-- add guild button
	blacklistFrame.addGuildBtn = UI:CreateButton(blacklistFrame, {
		template = "UIPanelButtonTemplate",
		text = L.AddGuild,
		height = 20,
		autoWidth = true,
		point = { "LEFT", guildDD, "RIGHT", -10, 2 },
		onClick = function() Blacklist:AddGuild() end,
	})

	local itemIDBox = UI:CreateEditBox(blacklistFrame, {
		template = "InputBoxTemplate",
		size = { 210, 20 },
		point = { "LEFT", blacklistFrame, "TOPLEFT", 20, -70 },
		autoFocus = false,
		text = "",
	})
	blacklistFrame.itemIDBox = itemIDBox

	-- add itemID button
	blacklistFrame.addItemIDBtn = UI:CreateButton(blacklistFrame, {
		template = "UIPanelButtonTemplate",
		text = L.AddItemID,
		height = 20,
		autoWidth = true,
		point = { "LEFT", itemIDBox, "RIGHT", 5, 2 },
		onClick = function() Blacklist:AddItemID() end,
	})

	blacklistFrame.infoText = UI:CreateFontString(blacklistFrame, {
		template = "GameFontHighlightSmall",
		text = L.UseFakeID,
		font = { STANDARD_TEXT_FONT, 12, "" },
		textColor = { 1, 165/255, 0 },
		point = { "LEFT", blacklistFrame, "TOPLEFT", 15, -90 },
		justifyH = "LEFT",
		width = blacklistFrame:GetWidth() - 15,
	})

	Blacklist.scrollFrame = UI:CreateHybridScrollFrame(blacklistFrame, {
		width = 337,
		pointTopLeft = { "TOPLEFT", blacklistFrame, "TOPLEFT", 13, -100 },
		-- set ScrollFrame height by altering distance from bottom of frame
		pointBottomLeft = { "BOTTOMLEFT", blacklistFrame, "BOTTOMLEFT", -25, 15 },
		buttonTemplate = "BagSyncListSimpleItemTemplate",
		update = function() Blacklist:RefreshList() end,
	})
	-- the items we will work with
	Blacklist.listItems = {}

	StaticPopupDialogs["BAGSYNC_BLACKLIST_REMOVE"] = {
		text = L.BlackListRemove,
		button1 = "Yes",
		button2 = "No",
		hasEditBox = false,
		timeout = 0,
		exclusive = 1,
		hideOnEscape = 1,
		OnShow = function(dialog)
			local tObj = dialog.text or dialog.Text
			tObj:SetText(L.BlackListRemove:format(dialog.data.value))
		end,
		OnAccept = function(dialog)
			Blacklist:RemoveData(dialog.data)
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

	-- scroll to top when shown
	HybridScrollFrame_SetOffset(Blacklist.scrollFrame, 0)
	Blacklist.scrollFrame.scrollBar:SetValue(0)
end

function Blacklist:CreateList()
	local listItems = {}
	Blacklist.selectedGuild = nil

	-- do the dropdown first
	local guildList = BuildGuildListForDropdown()
	InitializeGuildDropdown(guildList)

	-- loop through blacklist
	for k, v in pairs(BSYC.db.blacklist) do
		listItems[#listItems + 1] = {
			key = k,
			value = v
		}
	end

	if #listItems > 0 then
		table.sort(listItems, function(a, b)
			return (a.value or "") < (b.value or "")
		end)
	end

	Blacklist.listItems = listItems
end

function Blacklist:RefreshList()
	local items = Blacklist.listItems
	local buttons = HybridScrollFrame_GetButtons(Blacklist.scrollFrame)
	local offset = HybridScrollFrame_GetOffset(Blacklist.scrollFrame)

	if not buttons then return end

	for buttonIndex = 1, #buttons do
		local button = buttons[buttonIndex]
		UI:AttachListItemHandlers(button, Blacklist)

		local itemIndex = buttonIndex + offset

		if itemIndex <= #items then
			local item = items[itemIndex]
			local isItem = GetEntryType(item.key)

			button:SetID(itemIndex)
			button.data = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
			button:SetWidth(Blacklist.scrollFrame.scrollChild:GetWidth())

			button.Text:SetJustifyH("LEFT")
			if not isItem then
				-- is guild
				button.Text:SetTextColor(101/255, 184/255, 192/255)
			else
				button.Text:SetTextColor(1, 1, 1)
			end
			button.Text:SetText(item.value or "")
			button.HeaderHighlight:SetAlpha(0)

			if BSYC:IsMouseOver(button) then
				Blacklist:Item_OnLeave() -- hide first
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
	local db = BSYC.db.blacklist

	editBox:ClearFocus()
	local text = editBox:GetText()

	if not text or #text < 1 then
		BSYC:Print(L.EnterItemID)
		editBox:SetText("")
		return
	end

	local itemid = tonumber(text)
	if not itemid then
		BSYC:Print(L.EnterItemID)
		editBox:SetText("")
		return
	end

	if db[itemid] then
		BSYC:Print(L.ItemIDExistBlacklist:format(itemid))
		editBox:SetText("")
		return
	end

	-- handle pet items vs standard items
	if itemid >= FakePetCode then
		local speciesID = BSYC:FakeIDToSpeciesID(itemid)
		if not speciesID then
			BSYC:Print(L.ItemIDNotValid:format(itemid))
			editBox:SetText("")
			return
		end

		if not ValidateAndAddPetItem(itemid, speciesID, db) then
			editBox:SetText("")
			return
		end
	else
		local getItemInfo = BSYC.API.GetItemInfo
		if not (getItemInfo and getItemInfo(itemid)) then
			BSYC:Print(L.ItemIDNotValid:format(itemid))
			editBox:SetText("")
			return
		end

		if not ValidateAndAddStandardItem(itemid, getItemInfo, db) then
			editBox:SetText("")
			return
		end
	end

	editBox:SetText("")
	ResetTooltipCache()
	Blacklist:UpdateList()
end

function Blacklist:AddGuild()
	if not Blacklist.selectedGuild then return end

	if not ValidateGuildNotBlacklisted(Blacklist.selectedGuild.value) then
		return
	end

	BSYC.db.blacklist[Blacklist.selectedGuild.value] = Blacklist.selectedGuild.arg1
	BSYC:Print(L.GuildAdded:format(Blacklist.selectedGuild.arg1))
	ResetTooltipCache()
	Blacklist:UpdateList()
end

function Blacklist:RemoveData(entry)
	if BSYC.db.blacklist[entry.key] then
		BSYC:Print(FormatRemovalMessage(entry))
		BSYC.db.blacklist[entry.key] = nil
		Blacklist:UpdateList()
		ResetTooltipCache()
	else
		BSYC:Print(L.BlackListErrorRemove)
	end
end

function Blacklist:Item_OnEnter(btn)
	GameTooltip:SetOwner(btn, "ANCHOR_BOTTOMRIGHT")

	if GetEntryType(btn.data.key) then
		if btn.data.key >= FakePetCode then
			local speciesID = BSYC:FakeIDToSpeciesID(btn.data.key)
			if speciesID then
				if BattlePetToolTip_Show then
					BattlePetToolTip_Show(speciesID, 0, 0, 0, 0, 0, nil)
				end
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
	if BattlePetTooltip then
		BattlePetTooltip:Hide()
	end
end

function Blacklist:Item_OnClick(btn)
	StaticPopup_Show("BAGSYNC_BLACKLIST_REMOVE", '', '', btn.data)
end
