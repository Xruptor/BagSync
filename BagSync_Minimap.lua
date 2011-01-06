--Minimap Button for BagSync
--So people can stop PESTERING me about a dang button, why can't they just use DataBroker sheesh

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

bgMinimapButton:SetScript('OnMouseUp', function(self, button)
	if button == 'LeftButton' and BagSync_SearchFrame then
		if BagSync_SearchFrame:IsVisible() then
			BagSync_SearchFrame:Hide()
		else
			BagSync_SearchFrame:Show()
		end
	elseif button == 'RightButton' and BagSync_TokensFrame then
		if BagSync_TokensFrame:IsVisible() then
			BagSync_TokensFrame:Hide()
		else
			BagSync_TokensFrame:Show()
		end
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
	GameTooltip:SetOwner(bgMinimapButton)
	GameTooltip:SetText('BagSync')
	GameTooltip:Show()
end)

bgMinimapButton:SetScript('OnLeave', function(self)
	GameTooltip:Hide()
end)

