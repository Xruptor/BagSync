--[[
	BagSyncInteractiveLabel
	interactivelabel.lua
		A custom widget for InteractiveLabel used for BagSync frames

		BagSync - All Rights Reserved - (c) 2006-2023
		License included with addon.
--]]

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

local function EditBox_OnEscapePressed(frame)
	frame:ClearFocus()
end

local function EditBox_OnEnterPressed(frame)
	local self = frame.obj
	local value = frame:GetText()
	local cancel = frame.obj:Fire("OnEnterPressed", value)
	if not cancel then
		PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
	end
	frame:ClearFocus()
end

local function EditBox_OnEnter(frame)
	frame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
end

local function EditBox_OnLeave(frame)
	frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
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
		self:SetEditBoxHeight()
		self:SetEditBoxWidth()
		self:ToggleEditBox()
	end,

	["GetText"] = function(self)
		return self.label:GetText()
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

	["ToggleEditBox"] = function(self,toggle)
		if toggle then
			self.editbox:Show()
		else
			self.editbox:Hide()
		end
	end,

	["SetEditBoxHeight"] = function(self,height)
		if height then
			self.editbox:SetHeight(height)
		else
			self.editbox:SetHeight(14)
		end
	end,

	["SetEditBoxWidth"] = function(self,width)
		if width then
			self.editbox:SetWidth(width)
		else
			self.editbox:SetWidth(70)
		end
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

local ManualBackdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
	tile = true, edgeSize = 1, tileSize = 5,
}

local editBoxBackdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
	tile = true,
	tileSize = 16,
	edgeSize = 12,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local function Constructor()
	-- create a Label type that we will hijack
	local label = AceGUI:Create("BagSyncLabel")

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

	local editbox = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
	editbox:SetAutoFocus(false)
	editbox:SetFontObject(GameFontHighlight)
	editbox:SetPoint("RIGHT", frame, "RIGHT")
	editbox:SetHeight(14)
	editbox:SetWidth(70)
	editbox:SetJustifyH("CENTER")
	editbox:EnableMouse(true)
	editbox:SetBackdrop(editBoxBackdrop)
	editbox:SetBackdropColor(0, 0, 0, 0.5)
	editbox:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
	editbox:SetScript("OnEnter", EditBox_OnEnter)
	editbox:SetScript("OnLeave", EditBox_OnLeave)
	editbox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
	editbox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)
	editbox.obj = label
	editbox:Hide()

	label.editbox = editbox
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

