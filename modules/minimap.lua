--[[
	minimap.lua
		A minimap button for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local Module = BSYC:NewModule("Minimap")

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
local function Debug(...)
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", "MiniMap")
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end
end

local bgMinimapButton = CreateFrame("Frame","BagSync_MinimapButton", Minimap)

bgMinimapButton:SetHeight(32)
bgMinimapButton:SetWidth(32)
bgMinimapButton:SetMovable(1)
bgMinimapButton:SetUserPlaced(1)
bgMinimapButton:EnableMouse(1)
bgMinimapButton:RegisterForDrag('LeftButton')
bgMinimapButton:SetFrameStrata('MEDIUM')
bgMinimapButton:SetPoint('CENTER', Minimap:GetWidth()/3*-0.9, Minimap:GetHeight()/2*-1);
bgMinimapButton:CreateTexture('bgMinimapButtonTexture', 'BACKGROUND')
bgMinimapButton:SetClampedToScreen(true)

bgMinimapButtonTexture:SetWidth(32)
bgMinimapButtonTexture:SetHeight(32)
bgMinimapButtonTexture:SetTexture('Interface\\AddOns\\BagSync\\media\\minimap.tga')
bgMinimapButtonTexture:SetPoint('CENTER')

Module.button = bgMinimapButton
Module.buttonTexture = bgMinimapButtonTexture

--lets do the dropdown menu of DOOM
local bgsMinimapDD = CreateFrame("Frame", "bgsMinimapDD")
bgsMinimapDD.displayMode = 'MENU'

Module.dropdown = bgsMinimapDD

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

bgsMinimapDD.initialize = function(self, level)

	if level == 1 then
		PlaySound(SOUNDKIT.GS_TITLE_OPTION_EXIT)
		addButton(level, 'BagSync        ', 1, 1)
		addButton(level, L.Search, nil, 1, nil, 'search', function(frame, ...)
			BSYC:GetModule("Search").frame:Show()
		end)
		addButton(level, L.Currency, nil, 1, nil, 'currency', function(frame, ...)
			BSYC:GetModule("Currency").frame:Show()
		end)
		addButton(level, L.Profiles, nil, 1, nil, 'profiles', function(frame, ...)
			BSYC:GetModule("Profiles").frame:Show()
		end)
		addButton(level, L.Professions, nil, 1, nil, 'professions', function(frame, ...)
			BSYC:GetModule("Professions").frame:Show()
		end)
		addButton(level, L.Blacklist, nil, 1, nil, 'blacklist', function(frame, ...)
			BSYC:GetModule("Blacklist").frame:Show()
		end)
		addButton(level, L.Gold, nil, 1, nil, 'gold', function(frame, ...)
			BSYC:GetModule("Tooltip"):MoneyTooltip()
		end)
		addButton(level, L.FixDB, nil, 1, nil, 'fixdb', function(frame, ...)
			BSYC:GetModule("Data"):CleanDB()
		end)
		addButton(level, L.Config, nil, 1, nil, 'config', function(frame, ...)
			InterfaceOptionsFrame:Show() --has to be here to load the about frame onLoad
			InterfaceOptionsFrame_OpenToCategory(BSYC.aboutPanel) --force the panel to show
		end)
		addButton(level, "", nil, 1) --space ;)
		addButton(level, L.Close, nil, 1)

	end

end
	
bgMinimapButton:SetScript('OnMouseUp', function(self, button)
	if button == 'LeftButton' then
		BSYC:GetModule("Search").frame:Show()
	elseif button == 'RightButton' then
		ToggleDropDownMenu(1, nil, bgsMinimapDD, 'cursor', 0, 0)
	end
end)

bgMinimapButton:SetScript('OnUpdate', function(self, elapsed)
	if self:IsDragging() then

		local minimap = self:GetParent()
		local radius = (minimap:GetWidth() + self:GetWidth()) / 2
		local width = self:GetWidth()
		local x,y = minimap:GetCenter()
		local sc = minimap:GetEffectiveScale()
		local mx, my = GetCursorPosition() --self:GetCenter()
		
		mx = mx / sc
		my = my / sc
		
		local dx, dy = mx - x , my - y
		local dist = (dx * dx + dy * dy) ^ 0.5

		local radmin = radius
		local radsnap = radius + width * 0.2
		local radpull = radius + width * 0.7
		local radfre = radius + width

		local radclamp
		if dist <= radsnap then self.snapped = true radclamp = radmin
		elseif dist < radpull and self.snapped then radclamp = radmin
		elseif dist < radfre and self.snapped then radclamp = radmin + (dist - radpull) / 2
		else self.snapped = false -- dobby is freeee
		end

		if radclamp then
			dx = dx / (dist / radclamp)
			dy = dy / (dist / radclamp)
		end

		self:ClearAllPoints()
		self:SetPoint("CENTER", self:GetParent(), "CENTER", dx, dy)
	end
end)

bgMinimapButton:SetScript('OnEnter', function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:AddLine("|cffff6600BagSync|r")
	GameTooltip:AddLine(L.LeftClickSearch)
	GameTooltip:AddLine(L.RightClickBagSyncMenu)
	GameTooltip:Show()
end)

bgMinimapButton:SetScript('OnLeave', function(self)
	GameTooltip:Hide()
end)

function Module:OnEnable()
	if BSYC.options.enableMinimap and not bgMinimapButton:IsVisible() then
		bgMinimapButton:Show()
	elseif not BSYC.options.enableMinimap and bgMinimapButton:IsVisible() then
		bgMinimapButton:Hide()
	end
end
