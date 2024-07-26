--[[
	professions.lua
		A professions frame for BagSync

		BagSync - All Rights Reserved - (c) 2024
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Professions = BSYC:NewModule("Professions")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Professions", ...) end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

function Professions:OnEnable()
	local professionsFrame = _G.CreateFrame("Frame", nil, UIParent, "BagSyncFrameTemplate")
	Mixin(professionsFrame, Professions) --implement new frame to our parent module Mixin, to have access to parent methods
	_G["BagSyncProfessionsFrame"] = professionsFrame
    --Add to special frames so window can be closed when the escape key is pressed.
    tinsert(UISpecialFrames, "BagSyncProfessionsFrame")
    professionsFrame.TitleText:SetText("BagSync - "..L.Professions)
    professionsFrame:SetHeight(506) --irregular height to allow the scroll frame to fit the bottom most button
	professionsFrame:SetWidth(380)
    professionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    professionsFrame:EnableMouse(true) --don't allow clickthrough
    professionsFrame:SetMovable(true)
    professionsFrame:SetResizable(false)
    professionsFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	professionsFrame:RegisterForDrag("LeftButton")
	professionsFrame:SetClampedToScreen(true)
	professionsFrame:SetScript("OnDragStart", professionsFrame.StartMoving)
	professionsFrame:SetScript("OnDragStop", professionsFrame.StopMovingOrSizing)
	professionsFrame:SetScript("OnShow", function() Professions:OnShow() end)
	local closeBtn = CreateFrame("Button", nil, professionsFrame, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", C_EditMode and -3 or 2, C_EditMode and -3 or 1) --check for classic servers to adjust for positioning using a check for the new EditMode		
    professionsFrame.closeBtn = closeBtn
    Professions.frame = professionsFrame

	professionsFrame.infoText = professionsFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	professionsFrame.infoText:SetText(L.ProfessionInformation)
	professionsFrame.infoText:SetFont(STANDARD_TEXT_FONT, 12, "")
	professionsFrame.infoText:SetTextColor(1, 165/255, 0)
	professionsFrame.infoText:SetPoint("LEFT", professionsFrame, "TOPLEFT", 15, -35)
	professionsFrame.infoText:SetJustifyH("LEFT")
	professionsFrame.infoText:SetWidth(professionsFrame:GetWidth() - 15)

    Professions.scrollFrame = _G.CreateFrame("ScrollFrame", nil, professionsFrame, "HybridScrollFrameTemplate")
    Professions.scrollFrame:SetWidth(337)
    Professions.scrollFrame:SetPoint("TOPLEFT", professionsFrame, "TOPLEFT", 13, -48)
    --set ScrollFrame height by altering the distance from the bottom of the frame
    Professions.scrollFrame:SetPoint("BOTTOMLEFT", professionsFrame, "BOTTOMLEFT", -25, 15)
    Professions.scrollFrame.scrollBar = CreateFrame("Slider", "$parentscrollBar", Professions.scrollFrame, "HybridScrollBarTemplate")
    Professions.scrollFrame.scrollBar:SetPoint("TOPLEFT", Professions.scrollFrame, "TOPRIGHT", 1, -16)
    Professions.scrollFrame.scrollBar:SetPoint("BOTTOMLEFT", Professions.scrollFrame, "BOTTOMRIGHT", 1, 12)
	--initiate the scrollFrame
    --the items we will work with
    Professions.professionList = {}
	Professions.scrollFrame.update = function() Professions:RefreshList(); end
    HybridScrollFrame_SetDoNotHideScrollBar(Professions.scrollFrame, true)
	HybridScrollFrame_CreateButtons(Professions.scrollFrame, "BagSyncListSimpleItemTemplate")

	professionsFrame:Hide()
end

function Professions:OnShow()
	BSYC:SetBSYC_FrameLevel(Professions)

	Professions:CreateList()
    Professions:RefreshList()

	--scroll to top when shown
	HybridScrollFrame_SetOffset(Professions.scrollFrame, 0)
	Professions.scrollFrame.scrollBar:SetValue(0)
end

function Professions:CreateList()
	Professions.professionList = {}
	local usrData = {}

	for unitObj in Data:IterateUnits() do
		if not unitObj.isGuild and unitObj.data.professions then
			local colorized = Tooltip:ColorizeUnit(unitObj, true, false, true, true)

			for skillID, skillData in pairs(unitObj.data.professions) do
				if skillData.name then
					local hasRecipes = false
					if (skillData.recipeCount and skillData.recipeCount > 0) or (skillData.categoryCount and skillData.categoryCount > 0) then
						hasRecipes = true
					end
					table.insert(usrData, {
						skillID = skillID,
						skillData = skillData,
						unitObj = unitObj,
						colorized = colorized,
						sortIndex = Tooltip:GetSortIndex(unitObj),
						hasRecipes = hasRecipes
					})
				end
			end
		end
	end

	if #usrData > 0 then
		table.sort(usrData, function(a, b)
			if a.skillData.name == b.skillData.name then
				if a.sortIndex  == b.sortIndex then
					if a.unitObj.realm == b.unitObj.realm then
						return a.unitObj.name < b.unitObj.name;
					end
					return a.unitObj.realm < b.unitObj.realm;
				end
				return a.sortIndex < b.sortIndex;
			end
			return a.skillData.name < b.skillData.name;
		end)

		local lastHeader = ""
		for i=1, #usrData do
			if lastHeader ~= usrData[i].skillData.name then
				--add header
				table.insert(Professions.professionList, {
					header = usrData[i].skillData.name,
					isHeader = true
				})
				lastHeader = usrData[i].skillData.name
			end
			--add unit
			table.insert(Professions.professionList, {
				skillID = usrData[i].skillID,
				skillData = usrData[i].skillData,
				unitObj = usrData[i].unitObj,
				colorized = usrData[i].colorized,
				sortIndex = usrData[i].sortIndex,
				hasRecipes = usrData[i].hasRecipes
			})
		end
	end
end

function Professions:RefreshList()
    local items = Professions.professionList
    local buttons = HybridScrollFrame_GetButtons(Professions.scrollFrame)
    local offset = HybridScrollFrame_GetOffset(Professions.scrollFrame)
	if not buttons then return end

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
		button.parentHandler = Professions

        local itemIndex = buttonIndex + offset

        if itemIndex <= #items then
            local item = items[itemIndex]

            button:SetID(itemIndex)
			button.data = item
			button.Text:SetFont(STANDARD_TEXT_FONT, 14, "")
            button:SetWidth(Professions.scrollFrame.scrollChild:GetWidth())

			if item.isHeader then
				button.Text:SetJustifyH("CENTER")
				button.Text:SetTextColor(1, 1, 1)
				button.Text:SetText(item.header or "")
				--button.HeaderHighlight:SetVertexColor(0.8, 0.7, 0, 1)
				button.HeaderHighlight:SetAlpha(0.75)
				button.isHeader = true
			else
				button.Text:SetJustifyH("LEFT")
				button.Text:SetTextColor(0.25, 0.88, 0.82)
				button.Text:SetText(item.colorized or "")
				button.HeaderHighlight:SetAlpha(0)
				button.isHeader = nil

				--check for possible rescans and display baseline profession levels
				if not item.hasRecipes then
					if not item.skillData.skillLineCurrentLevel or not item.skillData.skillLineMaxLevel then
						button.Text:SetText(item.colorized.."   "..L.PleaseRescan)
					else
						button.Text:SetText(item.colorized..format("   |cFFFFFFFF%s/%s|r", item.skillData.skillLineCurrentLevel or 0, item.skillData.skillLineMaxLevel or 0))
					end
				end
			end

			--while we are updating the scrollframe, is the mouse currently over a button?
			--if so we need to force the OnEnter as the items will scroll up in data but the button remains the same position on our cursor
			if BSYC.GMF() == button then
				Professions:Item_OnLeave() --hide first
				Professions:Item_OnEnter(button)
			end

            button:Show()
        else
            button:Hide()
        end
    end

    local buttonHeight = Professions.scrollFrame.buttonHeight
    local totalHeight = #items * buttonHeight
    local shownHeight = #buttons * buttonHeight

    HybridScrollFrame_Update(Professions.scrollFrame, totalHeight, shownHeight)
end

function Professions:Item_OnEnter(btn)
	if btn.isHeader and btn.Highlight:IsVisible() then
		btn.Highlight:Hide()
	elseif not btn.isHeader and not btn.Highlight:IsVisible() then
		btn.Highlight:Show()
	end
    if not btn.isHeader then
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		GameTooltip:AddLine("|cFFFFFFFF"..PLAYER..":|r  "..btn.data.colorized)
		GameTooltip:AddLine("|cFFFFFFFF"..L.Realm.."|r  "..btn.data.unitObj.realm)
		GameTooltip:AddLine("|cFFFFFFFF"..L.TooltipRealmKey.."|r "..(btn.data.unitObj.data.realmKey or "?"))
		GameTooltip:AddLine(" ")

		if btn.data.hasRecipes then
			GameTooltip:AddLine("|cFF4DD827"..L.ProfessionHasRecipes.."|r")
		else
			GameTooltip:AddLine("|cFFFF3C38"..L.ProfessionHasNoRecipes.."|r")
		end
		GameTooltip:Show()
		return
	end
	GameTooltip:Hide()
end

function Professions:Item_OnLeave()
	GameTooltip:Hide()
end

function Professions:Item_OnClick(btn)
	if not btn.isHeader and btn.data.hasRecipes then
		BSYC:GetModule("Recipes"):ViewRecipes(btn.data)
	end
end
