--[[
	BagSyncLabel
	label.lua
		A custom widget for Label used for BagSync frames

		BagSync - All Rights Reserved - (c) 2006-2023
		License included with addon.
--]]

local Type, Version = "BagSyncLabel", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local max, select, pairs = math.max, select, pairs

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]

local function UpdateImageAnchor(self)
	if self.resizing then return end
	local frame = self.frame
	local width = frame.width or frame:GetWidth() or 0
	local image = self.image
	local label = self.label
	local height = self.customHeight or 0

	label:ClearAllPoints()
	image:ClearAllPoints()

	if self.imageshown then
        local imageHeight = image.height or 16
        local imageWidth = image.width or 16

		if (width - imageWidth) < 200 or (label:GetText() or "") == "" then
			-- image goes on top centered when less than 200 width for the text, or if there is no text
			image:SetPoint("TOP")
			label:SetPoint("TOP", image, "BOTTOM")
			label:SetPoint("LEFT")
			label:SetWidth(width)
			height = imageHeight + label:GetStringHeight()
		else
			-- image on the left
			image:SetPoint("TOPLEFT")
			if imageHeight > label:GetStringHeight() then
				label:SetPoint("LEFT", image, "RIGHT", 4, 0)
			else
				label:SetPoint("TOPLEFT", image, "TOPRIGHT", 4, 0)
			end
			label:SetWidth(width - imageWidth - 4)
			height = max(imageHeight, label:GetStringHeight())
		end
	else
		-- no image shown
		label:SetPoint("TOPLEFT")
		label:SetWidth(width)
		height = label:GetStringHeight()
	end

	-- avoid zero-height labels, since they can used as spacers
	if not height or height == 0 then
		height = 1
	end

	self.resizing = true
	if self.customHeight and self.customHeight > height then
		height = self.customHeight
	end
	frame.height = height
	frame:SetHeight(height)
	self.resizing = nil
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		-- set the flag to stop constant size updates
		self.resizing = true
		-- height is set dynamically by the text and image size
		self:SetWidth(200)
		self:SetText()
		self:SetImage(nil)
		self:SetImageSize(16, 16)
		self:SetColor()
		self:SetFontObject()
		self:SetJustifyH("LEFT")
		self:SetJustifyV("TOP")
		-- reset the flag
		self.customHeight = nil
		self.resizing = nil
		-- run the update explicitly
		UpdateImageAnchor(self)
	end,

	-- ["OnRelease"] = nil,

	["OnWidthSet"] = function(self, width)
		UpdateImageAnchor(self)
	end,

	["SetText"] = function(self, text)
		self.label:SetText(text)
		UpdateImageAnchor(self)
	end,

	["SetColor"] = function(self, r, g, b)
		if not (r and g and b) then
			r, g, b = 1, 1, 1
		end
		self.label:SetVertexColor(r, g, b)
	end,

	["SetImage"] = function(self, path, ...)
		local image = self.image
		image:SetTexture(path)

		if image:GetTexture() then
			self.imageshown = true
			local n = select("#", ...)
			if n == 4 or n == 8 then
				image:SetTexCoord(...)
			else
				image:SetTexCoord(0, 1, 0, 1)
			end
		else
			self.imageshown = nil
		end
		UpdateImageAnchor(self)
	end,

	["SetFont"] = function(self, font, height, flags)
		if not self.fontObject then
			self.fontObject = CreateFont("AceGUI30LabelFont" .. AceGUI:GetNextWidgetNum(Type))
		end
		self.fontObject:SetFont(font, height, flags)
		self:SetFontObject(self.fontObject)
	end,

	["SetFontObject"] = function(self, font)
		self.label:SetFontObject(font or GameFontHighlightSmall)
		UpdateImageAnchor(self)
	end,

	["SetImageSize"] = function(self, width, height)
		self.image:SetWidth(width)
		self.image:SetHeight(height)
        self.image.width = width
        self.image.height = height
		self.image:SetHeight(height)
		UpdateImageAnchor(self)
	end,

	["SetJustifyH"] = function(self, justifyH)
		self.label:SetJustifyH(justifyH)
	end,

	["SetJustifyV"] = function(self, justifyV)
		self.label:SetJustifyV(justifyV)
	end,

	["SetCustomHeight"] = function(self, height)
		self.customHeight = height
		UpdateImageAnchor(self)
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:Hide()

	local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	local image = frame:CreateTexture(nil, "BACKGROUND")

	-- create widget
	local widget = {
		label = label,
		image = image,
		frame = frame,
		type  = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
