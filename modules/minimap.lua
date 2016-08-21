--Minimap Button for BagSync
--So people can stop PESTERING me about a dang button, why can't they just use DataBroker sheesh

local L = BAGSYNC_L

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

--lets do the dropdown menu of DOOM
local bgsMinimapDD = CreateFrame("Frame", "bgsMinimapDD")
bgsMinimapDD.displayMode = 'MENU'

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
		PlaySound('gsTitleOptionExit')
		addButton(level, 'BagSync        ', 1, 1)
		addButton(level, L["Search"], nil, 1, nil, 'search', function(frame, ...)
			if BagSync_SearchFrame then BagSync_SearchFrame:Show() end
		end)
		addButton(level, L["Tokens"], nil, 1, nil, 'tokens', function(frame, ...)
			if BagSync_TokensFrame then BagSync_TokensFrame:Show() end
		end)
		addButton(level, L["Profiles"], nil, 1, nil, 'profiles', function(frame, ...)
			if BagSync_ProfilesFrame then BagSync_ProfilesFrame:Show() end
		end)
		addButton(level, L["Professions"], nil, 1, nil, 'professions', function(frame, ...)
			if BagSync_CraftsFrame then BagSync_CraftsFrame:Show() end
		end)
		addButton(level, L["Blacklist"], nil, 1, nil, 'blacklist', function(frame, ...)
			if BagSync_BlackListFrame then BagSync_BlackListFrame:Show() end
		end)
		addButton(level, L["Gold"], nil, 1, nil, 'gold', function(frame, ...)
			if BagSync then BagSync:ShowMoneyTooltip() end
		end)
		addButton(level, L["FixDB"], nil, 1, nil, 'fixdb', function(frame, ...)
			if BagSync then BagSync:FixDB_Data() end
		end)
		addButton(level, L["Config"], nil, 1, nil, 'config', function(frame, ...)
			InterfaceOptionsFrame_OpenToCategory("BagSync")
		end)
		addButton(level, "", nil, 1) --space ;)
		addButton(level, L["Close"], nil, 1)

	end

end
	
bgMinimapButton:SetScript('OnMouseUp', function(self, button)
	if button == 'LeftButton' and BagSync_SearchFrame then
		if BagSync_SearchFrame:IsVisible() then
			BagSync_SearchFrame:Hide()
		else
			BagSync_SearchFrame:Show()
		end
	elseif button == 'RightButton' and BagSync_TokensFrame then
		ToggleDropDownMenu(1, nil, bgsMinimapDD, 'cursor', 0, 0)
	end
end)

bgMinimapButton:SetScript('OnDragStart', function(self, button)
	if IsShiftKeyDown() then
		bgMinimapButton:SetScript('OnUpdate', function(self, elapsed)
			local x, y = Minimap:GetCenter()
			local cx, cy = GetCursorPosition()
			x, y = cx / self:GetEffectiveScale() - x, cy / self:GetEffectiveScale() - y
			if x > Minimap:GetWidth()/2+bgMinimapButton:GetWidth()/2 then x = Minimap:GetWidth()/2+bgMinimapButton:GetWidth()/2 end
			if x < Minimap:GetWidth()/2*-1-bgMinimapButton:GetWidth()/2 then x = Minimap:GetWidth()/2*-1-bgMinimapButton:GetWidth()/2 end
			if y > Minimap:GetHeight()/2+bgMinimapButton:GetHeight()/2 then y = Minimap:GetHeight()/2+bgMinimapButton:GetHeight()/2 end
			if y < Minimap:GetHeight()/2*-1-bgMinimapButton:GetHeight()/2 then y = Minimap:GetHeight()/2*-1-bgMinimapButton:GetHeight()/2 end
			bgMinimapButton:ClearAllPoints()
			bgMinimapButton:SetPoint('CENTER', x, y)
		end)
	end
end)

bgMinimapButton:SetScript('OnDragStop', function(self, button)
	bgMinimapButton:SetScript('OnUpdate', nil)
end)

bgMinimapButton:SetScript('OnEnter', function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:AddLine("BagSync")
	GameTooltip:AddLine(L["Left Click = Search Window"])
	GameTooltip:AddLine(L["Right Click = BagSync Menu"])
	GameTooltip:Show()
end)

bgMinimapButton:SetScript('OnLeave', function(self)
	GameTooltip:Hide()
end)

