--[[
	details.lua
		A window that provides a detailed summary of items for BagSync

		BagSync - All Rights Reserved - (c) 2024
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Details = BSYC:NewModule("Details")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Details", ...) end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

local function comma_value(n)
	if not n or not tonumber(n) then return "?" end
	return tostring(BreakUpLargeNumbers(tonumber(n)))
end

function Details:OnEnable()
	local detailsFrame = _G.CreateFrame("Frame", nil, UIParent, "BagSyncFrameTemplate")
	Mixin(detailsFrame, Details) --implement new frame to our parent module Mixin, to have access to parent methods
	_G["BagSyncDetailsFrame"] = detailsFrame
    --Add to special frames so window can be closed when the escape key is pressed.
    tinsert(UISpecialFrames, "BagSyncDetailsFrame")
    detailsFrame.TitleText:SetText("BagSync - "..L.Details)
    detailsFrame:SetHeight(606)
	detailsFrame:SetWidth(600)
    detailsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    detailsFrame:EnableMouse(true) --don't allow clickthrough
    detailsFrame:SetMovable(true)
    detailsFrame:SetResizable(false)
    detailsFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	detailsFrame:RegisterForDrag("LeftButton")
	detailsFrame:SetClampedToScreen(true)
	detailsFrame:SetScript("OnDragStart", detailsFrame.StartMoving)
	detailsFrame:SetScript("OnDragStop", detailsFrame.StopMovingOrSizing)
	detailsFrame:SetScript("OnShow", function() Details:OnShow() end)
	local closeBtn = CreateFrame("Button", nil, detailsFrame, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", C_EditMode and -3 or 2, C_EditMode and -3 or 1) --check for classic servers to adjust for positioning using a check for the new EditMode			
    detailsFrame.closeBtn = closeBtn
	Details.frame = detailsFrame

	detailsFrame.infoText = detailsFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	detailsFrame.infoText:SetText(L.Details)
	detailsFrame.infoText:SetFont(STANDARD_TEXT_FONT, 12, "")
	detailsFrame.infoText:SetTextColor(1, 165/255, 0)
	detailsFrame.infoText:SetPoint("LEFT", detailsFrame, "TOPLEFT", 15, -35)
	detailsFrame.infoText:SetJustifyH("LEFT")
	detailsFrame.infoText:SetWidth(detailsFrame:GetWidth() - 15)

    Details.scrollFrame = _G.CreateFrame("ScrollFrame", nil, detailsFrame, "HybridScrollFrameTemplate")
    Details.scrollFrame:SetWidth(557)
    Details.scrollFrame:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 13, -45)
    --set ScrollFrame height by altering the distance from the bottom of the frame
    Details.scrollFrame:SetPoint("BOTTOMLEFT", detailsFrame, "BOTTOMLEFT", -25, 15)
    Details.scrollFrame.scrollBar = CreateFrame("Slider", "$parentscrollBar", Details.scrollFrame, "HybridScrollBarTemplate")
    Details.scrollFrame.scrollBar:SetPoint("TOPLEFT", Details.scrollFrame, "TOPRIGHT", 1, -16)
    Details.scrollFrame.scrollBar:SetPoint("BOTTOMLEFT", Details.scrollFrame, "BOTTOMRIGHT", 1, 12)
	--initiate the scrollFrame
    --the items we will work with
    Details.items = {}
	Details.scrollFrame.update = function() Details:RefreshList(); end
    HybridScrollFrame_SetDoNotHideScrollBar(Details.scrollFrame, true)
	HybridScrollFrame_CreateButtons(Details.scrollFrame, "BagSyncListSimpleItemTemplate")

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

function Details:CheckItems(usrData, unitObj, target, itemID, colorized)
	if not unitObj or not target then return end

	local function parseItems(data, tab, equipped)
		local iCount = 0
		for i=1, #data do
			if data[i] then
				local link, count, qOpts = BSYC:Split(data[i])
				if BSYC.options.enableShowUniqueItemsTotals and link then link = BSYC:GetShortItemID(link) end
				if link then
					if link == itemID then
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
		return iCount
	end

	if unitObj.data[target] and BSYC.tracking[target] then
		if target == "bag" or target == "bank" or target == "reagents" then
			for bagID, bagData in pairs(unitObj.data[target] or {}) do
				parseItems(bagData, bagID)
			end
			--do equipbags
			if (target == "bag" or target == "bank") and unitObj.data.equipbags then
				parseItems(unitObj.data.equipbags[target] or {}, nil, true)
			end
		elseif target == "auction" then
			parseItems((unitObj.data[target] and unitObj.data[target].bag) or {})

		elseif target == "equip" or target == "void" or target == "mailbox" then
			parseItems(unitObj.data[target] or {})
		end
	end
	if target == "guild" and BSYC.tracking.guild then
		for tabID, tabData in pairs(unitObj.data.tabs or {}) do
			parseItems(tabData, tabID)
		end
	end
	if target == "warband" and BSYC.tracking.warband then
		for tabID, tabData in pairs(unitObj.data.tabs or {}) do
			parseItems(tabData, tabID)
		end
	end
end

function Details:CreateList(itemID)
	Details.items = {}

	local usrData = {}
	local allowList = {
		bag = true,
		bank = true,
		reagents = true,
		equip = true,
		mailbox = true,
		void = true,
		auction = true,
		warband = true,
	}
	if BSYC.options.enableShowUniqueItemsTotals then itemID = BSYC:GetShortItemID(itemID) end

	for unitObj in Data:IterateUnits(true) do
		local colorized = Tooltip:ColorizeUnit(unitObj, true) --if we did this in CheckItems() it would be spammy and call it WAY too much
		if not unitObj.isGuild then
			for k, v in pairs(allowList) do
				Details:CheckItems(usrData, unitObj, k, itemID, colorized)
			end
		else
			Details:CheckItems(usrData, unitObj, "guild", itemID, colorized)
		end
	end

	local warbandObj = Data:GetWarbandBankObj()
	if warbandObj and allowList.warband then
		local colorized = Tooltip:HexColor(BSYC.colors.warband, L.TooltipIcon_warband.." "..L.Tooltip_warband)
		Details:CheckItems(usrData, warbandObj, "warband", itemID, colorized)
	end

	if #usrData > 0 then

		--sort order
		--Realm -> Player -> target type -> tab (if exists) -> slot/index

		table.sort(usrData, function(a, b)
			if a.realm  == b.realm then
				if a.name  == b.name then
					if a.target  == b.target then
						if a.tab and b.tab then
							if a.tab == b.tab then
								return a.slot < b.slot;
							end
							return a.tab < b.tab;
						else
							return a.slot < b.slot;
						end
					end
					return a.target < b.target;
				end
				return a.name < b.name;
			end
			return a.realm < b.realm;
		end)

		local lastHeader = ""
		for i=1, #usrData do
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

function Details:RefreshList()
    local items = Details.items
    local buttons = HybridScrollFrame_GetButtons(Details.scrollFrame)
    local offset = HybridScrollFrame_GetOffset(Details.scrollFrame)
	if not buttons then return end

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
		button.parentHandler = Details

        local itemIndex = buttonIndex + offset

        if itemIndex <= #items then
            local item = items[itemIndex]

            button:SetID(itemIndex)
			button.data = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
            button:SetWidth(Details.scrollFrame.scrollChild:GetWidth())

			if item.isHeader then
				button.Text:SetJustifyH("CENTER")
				button.Text:SetTextColor(1, 1, 1)
				button.Text:SetText(item.realm or "")
				--button.HeaderHighlight:SetVertexColor(0.8, 0.7, 0, 1)
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

				local info = ""
				local dispType = ""

				if BSYC.options.singleCharLocations then
					dispType = "TooltipSmall_"
				elseif BSYC.options.useIconLocations then
					dispType = "TooltipIcon_"
				else
					dispType = "Tooltip_"
				end

				local colorType = Tooltip:GetClassColor(item.unitObj, 2)
				info = Tooltip:HexColor(BSYC.colors.second, comma_value(item.count))
				info = info.." ("..Tooltip:HexColor(colorType, L[dispType..item.target]).." "

				if item.tab then
					if item.target ~= "guild" and item.target ~= "warband"  then
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
					local r, g, b, hex = GetItemQualityColor(breedQuality)
					--local qStr = _G["ITEM_QUALITY"..breedQuality.."_DESC"]
					--qStr = "|c"..hex.."["..qStr.."]|r"

					if tonumber(level) and tonumber(level) > 0 then
						info = info.." |c"..hex..LEVEL..":|r "..level
					end
				end

				button.Text2:SetText(info)
			end

			--while we are updating the scrollframe, is the mouse currently over a button?
			--if so we need to force the OnEnter as the items will scroll up in data but the button remains the same position on our cursor
			if BSYC.GMF() == button then
				Details:Item_OnLeave() --hide first
				Details:Item_OnEnter(button)
			end

            button:Show()
        else
            button:Hide()
        end
    end

    local buttonHeight = Details.scrollFrame.buttonHeight
    local totalHeight = #items * buttonHeight
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