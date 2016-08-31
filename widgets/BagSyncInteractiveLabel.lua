--[[-----------------------------------------------------------------------------
BagSyncInteractiveLabel Widget
-------------------------------------------------------------------------------]]
local Type, Version = "BagSyncInteractiveLabel", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local select, pairs = select, pairs

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: GameFontHighlightSmall

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	frame.obj:Fire("OnLeave")
end

local function Label_OnClick(frame, button)
	frame.obj:Fire("OnClick", button)
	AceGUI:ClearFocus()
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:LabelOnAcquire()
		self:ApplyJustifyH()
		self:ApplyJustifyV()
		self:SetHighlight()
		self:SetHeaderHighlight()
		self:SetHighlightTexCoord()
		self:SetHeaderHighlightTexCoord()
		self:ToggleHeaderHighlight()
		self:SetDisabled(false)
	end,

	["ApplyJustifyH"] = function(self,position)
		if position then
			self.label:SetJustifyH(position)
		else
			self.label:SetJustifyH("LEFT")
		end
	end,
	
	["ApplyJustifyV"] = function(self,position)
		if position then
			self.label:SetJustifyV(position)
		else
			self.label:SetJustifyV("TOP")
		end
	end,
	
	["SetDisabled"] = function(self,disabled)
		self.disabled = disabled
		if disabled then
			self.frame:EnableMouse(false)
			self.label:SetTextColor(0.5, 0.5, 0.5)
		else
			self.frame:EnableMouse(true)
			self.label:SetTextColor(1, 1, 1)
		end
	end,
	

	["SetHighlight"] = function(self, ...)
		self.highlight:SetTexture(...)
		self.headerhighlight:SetTexture(nil) --only one active highlight at a time
	end,

	["SetHighlightTexCoord"] = function(self, ...)
		local c = select("#", ...)
		if c == 4 or c == 8 then
			self.highlight:SetTexCoord(...)
		else
			self.highlight:SetTexCoord(0, 1, 0, 1)
		end
	end,
	
	["SetHeaderHighlight"] = function(self, ...)
		self.headerhighlight:SetTexture(...)
		self.highlight:SetTexture(nil) --only one active highlight at a time
	end,

	["SetHeaderHighlightTexCoord"] = function(self, ...)
		local c = select("#", ...)
		if c == 4 or c == 8 then
			self.headerhighlight:SetTexCoord(...)
		else
			self.headerhighlight:SetTexCoord(0, 1, 0, 1)
		end
	end,
	
	["ToggleHeaderHighlight"] = function(self,toggle)
		if toggle then
			self.headerhighlight:Show()
		else
			self.headerhighlight:Hide()
		end
	end,
	
	["SetDisabled"] = function(self,disabled)
		self.disabled = disabled
		if disabled then
			self.frame:EnableMouse(false)
			self.label:SetTextColor(0.5, 0.5, 0.5)
		else
			self.frame:EnableMouse(true)
			self.label:SetTextColor(1, 1, 1)
		end
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	-- create a Label type that we will hijack
	local label = AceGUI:Create("Label")

	local frame = label.frame
	frame:EnableMouse(true)
	frame:SetScript("OnEnter", Control_OnEnter)
	frame:SetScript("OnLeave", Control_OnLeave)
	frame:SetScript("OnMouseDown", Label_OnClick)

	local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetTexture(nil)
	highlight:SetAllPoints()
	highlight:SetBlendMode("ADD")

	local headerhighlight = frame:CreateTexture(nil, "BACKGROUND")
	headerhighlight:SetTexture(nil)
	headerhighlight:SetAllPoints()
	headerhighlight:SetBlendMode("ADD")
	headerhighlight:Hide()
	
	label.highlight = highlight
	label.headerhighlight = headerhighlight
	label.type = Type
	label.LabelOnAcquire = label.OnAcquire
	for method, func in pairs(methods) do
		label[method] = func
	end

	return label
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)

