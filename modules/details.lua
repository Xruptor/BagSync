--[[
	details.lua
		A window that provides a detailed summary of items for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...) --grab the addon namespace
local UI = BSYC:GetModule("UI")
local Details = BSYC:NewModule("Details")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local L = BSYC.L

-- Cache global references
local HybridScrollFrame_GetButtons = HybridScrollFrame_GetButtons
local HybridScrollFrame_GetOffset = HybridScrollFrame_GetOffset
local HybridScrollFrame_SetOffset = HybridScrollFrame_SetOffset
local HybridScrollFrame_Update = HybridScrollFrame_Update
local GameTooltip = GameTooltip
local BattlePetTooltip = BattlePetTooltip
local BattlePetToolTip_Show = BattlePetToolTip_Show
local BreakUpLargeNumbers = BreakUpLargeNumbers
local strsplit = strsplit
local GetItemQualityColor = GetItemQualityColor
local LEVEL = LEVEL
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT

-- Display type lookup table (eliminates if-chain)
local DISPLAY_TYPE_MAP = {
	singleCharLocations = "TooltipSmall_",
	useIconLocations = "TooltipIcon_",
	default = "Tooltip_",
}

-- Helper to get display type prefix
local function GetDisplayType(options)
	if options.singleCharLocations then
		return DISPLAY_TYPE_MAP.singleCharLocations
	elseif options.useIconLocations then
		return DISPLAY_TYPE_MAP.useIconLocations
	end
	return DISPLAY_TYPE_MAP.default
end

-- Optimized comma value function (removed redundant tonumber)
local function comma_value(n)
	if not n or not tonumber(n) then return "?" end
	return tostring(BreakUpLargeNumbers(n))
end

-- Module-level parseItems function (not recreated on each call)
local function parseItems(data, tab, equipped, usrData, unitObj, target, itemID, colorized, options)
	for i = 1, #data do
		if data[i] then
			local link, count, qOpts = BSYC:Split(data[i])
			if options.enableShowUniqueItemsTotals and link then
				link = BSYC:GetShortItemID(link)
			end
			if link and link == itemID then
				table.insert(usrData, {
					unitObj = unitObj,
					name = unitObj.name,
					realm = unitObj.realm,
					colorized = colorized,
					tab = tab,
					slot = (equipped and "E") or i,
					target = target,
					link = link,
					count = count or 1,
					qOpts = qOpts,
					speciesID = BSYC:FakeIDToSpeciesID(link),
				})
			end
		end
	end
end

-- Helper to process tabular data (guild/warband) - eliminates duplication
local function ProcessTabularData(unitObj, usrData, target, itemID, colorized, options)
	for tabID, tabData in pairs(unitObj.data.tabs or {}) do
		parseItems(tabData, tabID, false, usrData, unitObj, target, itemID, colorized, options)
	end
end

function Details:OnEnable()
	local detailsFrame = UI:CreateModuleFrame(Details, {
		template = "BagSyncFrameTemplate",
		globalName = "BagSyncDetailsFrame",
		title = "BagSync - "..L.Details,
		height = 606,
		width = 600,
		point = { "CENTER", UIParent, "CENTER", 0, 0 },
		onShow = function() Details:OnShow() end,
	})
	Details.frame = detailsFrame

	detailsFrame.infoText = UI:CreateFontString(detailsFrame, {
		template = "GameFontHighlightSmall",
		text = L.Details,
		font = { STANDARD_TEXT_FONT, 12, "" },
		textColor = { 1, 165/255, 0 },
		point = { "LEFT", detailsFrame, "TOPLEFT", 15, -35 },
		justifyH = "LEFT",
		width = detailsFrame:GetWidth() - 15,
	})

	Details.scrollFrame = UI:CreateHybridScrollFrame(detailsFrame, {
		width = 557,
		pointTopLeft = { "TOPLEFT", detailsFrame, "TOPLEFT", 13, -45 },
		-- set ScrollFrame height by altering the distance from the bottom of the frame
		pointBottomLeft = { "BOTTOMLEFT", detailsFrame, "BOTTOMLEFT", -25, 15 },
		buttonTemplate = "BagSyncListSimpleItemTemplate",
		update = function() Details:RefreshList() end,
	})
	--the items we will work with
	Details.items = {}

	detailsFrame:Hide()
end

function Details:OnShow()
	BSYC:SetBSYC_FrameLevel(Details)
end

function Details:ShowItem(itemID, text)
	if not itemID then return end
	Details.frame:Show()
	Details.frame.infoText:SetText("|cFFe454fd"..L.Details..":|r "..text)

	Details:CreateList(itemID)
	Details:RefreshList()

	--scroll to top when shown
	HybridScrollFrame_SetOffset(Details.scrollFrame, 0)
	Details.scrollFrame.scrollBar:SetValue(0)
end

function Details:CheckItems(usrData, unitObj, target, itemID, colorized, tracking, options)
	if not unitObj or not target then return end

	if unitObj.data[target] and tracking[target] then
		if target == "bag" or target == "bank" or target == "reagents" then
			for bagID, bagData in pairs(unitObj.data[target] or {}) do
				parseItems(bagData, bagID, false, usrData, unitObj, target, itemID, colorized, options)
			end
			--do equipbags
			if (target == "bag" or target == "bank") and unitObj.data.equipbags then
				parseItems(unitObj.data.equipbags[target] or {}, nil, true, usrData, unitObj, target, itemID, colorized, options)
			end
		elseif target == "auction" then
			parseItems((unitObj.data[target] and unitObj.data[target].bag) or {}, nil, false, usrData, unitObj, target, itemID, colorized, options)
		elseif target == "equip" or target == "void" or target == "mailbox" then
			parseItems(unitObj.data[target] or {}, nil, false, usrData, unitObj, target, itemID, colorized, options)
		end
	end

	if target == "guild" and tracking.guild then
		ProcessTabularData(unitObj, usrData, "guild", itemID, colorized, options)
	end
	if target == "warband" and tracking.warband then
		ProcessTabularData(unitObj, usrData, "warband", itemID, colorized, options)
	end
end

-- Sort key helper for cleaner comparison
local function CreateSortKey(entry)
	return string.format("%s\0%s\0%s\0%s\0%s",
		entry.realm or "",
		entry.name or "",
		entry.target or "",
		tostring(entry.tab or ""),
		entry.slot or ""
	)
end

function Details:CreateList(itemID)
	Details.items = {}

	local usrData = {}
	local options = BSYC.options or {}
	local tracking = BSYC.tracking or {}
	local colors = BSYC.colors or {}
	local allowList = BSYC.DEFAULT_ALLOW_LIST
	if options.enableShowUniqueItemsTotals then
		itemID = BSYC:GetShortItemID(itemID)
	end

	for unitObj in Data:IterateUnits(true) do
		local colorized = Tooltip:ColorizeUnit(unitObj, true)
		if not unitObj.isGuild then
			for k, _ in pairs(allowList) do
				Details:CheckItems(usrData, unitObj, k, itemID, colorized, tracking, options)
			end
		else
			Details:CheckItems(usrData, unitObj, "guild", itemID, colorized, tracking, options)
		end
	end

	local warbandObj = Data:GetWarbandBankObj()
	if warbandObj and allowList.warband then
		local colorized = Tooltip:HexColor(colors.warband, L.TooltipIcon_warband.." "..L.Tooltip_warband)
		Details:CheckItems(usrData, warbandObj, "warband", itemID, colorized, tracking, options)
	end

	if #usrData > 0 then
		--sort order: Realm -> Player -> target type -> tab (if exists) -> slot/index
		table.sort(usrData, function(a, b)
			local keyA = CreateSortKey(a)
			local keyB = CreateSortKey(b)
			return keyA < keyB
		end)

		local lastHeader = ""
		for i = 1, #usrData do
			if lastHeader ~= usrData[i].realm then
				--add header
				table.insert(Details.items, {
					realm = usrData[i].realm,
					isHeader = true,
				})
				lastHeader = usrData[i].realm
			end
			--add units
			table.insert(Details.items, {
				unitObj = usrData[i].unitObj,
				name = usrData[i].name,
				realm = usrData[i].realm,
				colorized = usrData[i].colorized,
				tab = usrData[i].tab,
				slot = usrData[i].slot,
				target = usrData[i].target,
				link = usrData[i].link,
				count = usrData[i].count,
				qOpts = usrData[i].qOpts,
				speciesID = usrData[i].speciesID,
			})
		end
	end
end

-- Helper to build item info text
local function BuildItemInfoText(item, options, colors)
	local info = ""
	local dispType = GetDisplayType(options)

	local colorType = Tooltip:GetClassColor(item.unitObj, 2)
	info = Tooltip:HexColor(colors.second, comma_value(item.count))
	info = info.." ("..Tooltip:HexColor(colorType, L[dispType..item.target]).." "

	if item.tab then
		if item.target ~= "guild" and item.target ~= "warband" then
			info = info..Tooltip:HexColor(colorType, L.DetailsBagID).." "..item.tab.." "
		else
			info = info..Tooltip:HexColor(colorType, L.DetailsTab).." "..item.tab.." "
		end
	end
	info = info..Tooltip:HexColor(colorType, L.DetailsSlot).." "..item.slot..")"

	--check for battlepet
	if item.speciesID and item.qOpts and item.qOpts.petdata then
		local _, level, breedQuality = strsplit(":", item.qOpts.petdata)
		breedQuality = tonumber(breedQuality) or 0
		local _, _, _, hex = GetItemQualityColor(breedQuality)

		if tonumber(level) and tonumber(level) > 0 then
			info = info.." |c"..hex..LEVEL..":|r "..level
		end
	end

	return info
end

function Details:RefreshList()
	local buttons = HybridScrollFrame_GetButtons(Details.scrollFrame)
	local offset = HybridScrollFrame_GetOffset(Details.scrollFrame)
	local options = BSYC.options or {}
	local colors = BSYC.colors or {}
	if not buttons then return end

	for buttonIndex = 1, #buttons do
		local button = buttons[buttonIndex]
		UI:AttachListItemHandlers(button, Details)

		local itemIndex = buttonIndex + offset

		if itemIndex <= #Details.items then
			local item = Details.items[itemIndex]

			button:SetID(itemIndex)
			button.data = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
			button:SetWidth(Details.scrollFrame.scrollChild:GetWidth())

			-- Early return for header path
			if item.isHeader then
				button.Text:SetJustifyH("CENTER")
				button.Text:SetTextColor(1, 1, 1)
				button.Text:SetText(item.realm or "")
				button.HeaderHighlight:SetAlpha(0.75)
				button.isHeader = true
				button.Text2:SetJustifyH("RIGHT")
				button.Text2:SetTextColor(1, 1, 1)
				button.Text2:SetText("")
			else
				button.Text:SetJustifyH("LEFT")
				button.Text:SetTextColor(0.25, 0.88, 0.82)
				button.Text:SetText(item.colorized or "")
				button.HeaderHighlight:SetAlpha(0)
				button.isHeader = nil

				button.Text2:SetJustifyH("RIGHT")
				button.Text2:SetTextColor(1, 1, 1)
				button.Text2:SetText(BuildItemInfoText(item, options, colors))
			end

			--while we are updating the scrollframe, is the mouse currently over a button?
			--if so we need to force the OnEnter as the items will scroll up in data but the button remains the same position on our cursor
			if BSYC:IsMouseOver(button) then
				Details:Item_OnLeave()
				Details:Item_OnEnter(button)
			end

			button:Show()
		else
			button:Hide()
		end
	end

	local buttonHeight = Details.scrollFrame.buttonHeight
	local totalHeight = #Details.items * buttonHeight
	local shownHeight = #buttons * buttonHeight

	HybridScrollFrame_Update(Details.scrollFrame, totalHeight, shownHeight)
end

function Details:Item_OnEnter(btn)
	if btn.isHeader and btn.Highlight:IsVisible() then
		btn.Highlight:Hide()
	elseif not btn.isHeader and not btn.Highlight:IsVisible() then
		btn.Highlight:Show()
	end
	if not btn.isHeader and btn.data.speciesID and btn.data.qOpts and btn.data.qOpts.petdata then
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		local speciesID, level, breedQuality, maxHealth, power, speed = strsplit(":", btn.data.qOpts.petdata)
		if tonumber(speciesID) and tonumber(level) and tonumber(level) > 0 then
			BattlePetToolTip_Show(tonumber(speciesID), tonumber(level), tonumber(breedQuality), tonumber(maxHealth), tonumber(power), tonumber(speed), nil)
		end
		return
	end
	if BattlePetTooltip then BattlePetTooltip:Hide() end
end

function Details:Item_OnLeave()
	if BattlePetTooltip then BattlePetTooltip:Hide() end
end
