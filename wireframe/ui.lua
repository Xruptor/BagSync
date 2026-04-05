--[[
	ui.lua
		UI helpers (backbone only; preserves existing layout/behavior)

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local _G = _G
local CreateFrame = _G.CreateFrame
local pairs = pairs
local unpack = unpack
local tinsert = tinsert
local C_EditMode = C_EditMode

local BSYC = select(2, ...)
local UI = BSYC:NewModule("UI")

-- ============================================================================
-- Shared Helpers
-- ============================================================================

-- Apply multiple anchor points to a frame/texture from opts.points
local function ApplyPoints(self, points)
	for i = 1, #points do
		self:SetPoint(unpack(points[i]))
	end
end

-- Apply scripts to a frame from opts.scripts table
local function ApplyScripts(self, scripts)
	for event, fn in pairs(scripts) do
		self:SetScript(event, fn)
	end
end

-- Set font from opts table, handling both table and string formats
local function SetFontFromOpts(self, opts)
	if opts.fontObject then
		self:SetFontObject(opts.fontObject)
	elseif opts.font then
		if type(opts.font) == "table" then
			self:SetFont(unpack(opts.font))
		else
			self:SetFont(opts.font, opts.fontSize or 12, opts.fontFlags or "")
		end
	end
end

-- ============================================================================
-- Public API
-- ============================================================================

function UI:FindHandler(widget)
	if not widget then return nil end
	if widget.parentHandler then return widget.parentHandler end

	local p = widget
	while p do
		if p.parentHandler then
			widget.parentHandler = p.parentHandler
			return p.parentHandler
		end
		p = p:GetParent()
	end
end

function UI:CallHandler(widget, method, ...)
	local handler = self:FindHandler(widget)
	local fn = handler and handler[method]
	if type(fn) == "function" then
		return fn(handler, ...)
	end
end

-- NOTE: Reduced closure creation from 7 to 4 by sharing the base handler script
function UI:AttachListItemHandlers(button, handler, opts)
	if not button or button.__bsycHandlers then return end

	opts = opts or {}
	local onClick = opts.onClick or "Item_OnClick"
	local onEnter = opts.onEnter or "Item_OnEnter"
	local onLeave = opts.onLeave or "Item_OnLeave"

	button.parentHandler = handler

	-- Shared handler dispatcher to reduce closure count
	local function MakeHandler(method)
		return function(self)
			UI:CallHandler(self, method, self)
		end
	end

	button:SetScript("OnClick", MakeHandler(onClick))
	button:SetScript("OnEnter", MakeHandler(onEnter))
	button:SetScript("OnLeave", MakeHandler(onLeave))

	local details = opts.detailsButton and button[opts.detailsButton]
	if details then
		local onDetailsClick = opts.onDetailsClick or "ItemDetails"
		local onDetailsEnter = opts.onDetailsEnter or "ItemDetails_OnEnter"
		local onDetailsLeave = opts.onDetailsLeave or "ItemDetails_OnLeave"

		details.parentHandler = handler
		details:SetScript("OnClick", MakeHandler(onDetailsClick))

		if onDetailsEnter ~= false then
			details:SetScript("OnEnter", function(self)
				local parent = self:GetParent()
				if parent.DetailsHighlight then
					parent.DetailsHighlight:SetAlpha(0.75)
				end
				UI:CallHandler(self, onDetailsEnter, self)
			end)
		end

		if onDetailsLeave ~= false then
			details:SetScript("OnLeave", function(self)
				local parent = self:GetParent()
				if parent.DetailsHighlight then
					parent.DetailsHighlight:SetAlpha(0)
				end
				UI:CallHandler(self, onDetailsLeave, self)
			end)
		end
	end

	button.__bsycHandlers = true
end

function UI:CreateModuleFrame(module, opts)
	opts = opts or {}

	local parent = opts.parent or UIParent
	local template = opts.template or "BagSyncFrameTemplate"

	local frame = CreateFrame("Frame", nil, parent, template)
	if module then
		Mixin(frame, module)
	end

	if opts.globalName then
		_G[opts.globalName] = frame
		tinsert(UISpecialFrames, opts.globalName)
	end

	if frame.TitleText and opts.title then
		frame.TitleText:SetText(opts.title)
	end

	if opts.width then frame:SetWidth(opts.width) end
	if opts.height then frame:SetHeight(opts.height) end
	if opts.point then frame:SetPoint(unpack(opts.point)) end

	frame:EnableMouse(opts.enableMouse ~= false)
	frame:SetMovable(opts.movable ~= false)
	frame:SetResizable(false)
	frame:SetFrameStrata(opts.frameStrata or "FULLSCREEN_DIALOG")
	frame:RegisterForDrag(opts.dragButton or "LeftButton")
	frame:SetClampedToScreen(true)
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	if opts.onShow then frame:SetScript("OnShow", opts.onShow) end
	if opts.onHide then frame:SetScript("OnHide", opts.onHide) end

	if opts.createCloseButton ~= false then
		local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
		local offset = C_EditMode and -3 or 2
		local offsetV = C_EditMode and -3 or 1
		closeBtn:SetPoint("TOPRIGHT", offset, offsetV)
		frame.closeBtn = closeBtn
	end

	return frame
end

function UI:CreateHybridScrollFrame(parent, opts)
	if not parent then return nil end
	opts = opts or {}
	local scroll = CreateFrame("ScrollFrame", nil, parent, "HybridScrollFrameTemplate")

	if opts.width then
		scroll:SetWidth(opts.width)
	end
	if opts.pointTopLeft then
		scroll:SetPoint(unpack(opts.pointTopLeft))
	end
	if opts.pointBottomLeft then
		scroll:SetPoint(unpack(opts.pointBottomLeft))
	end

	scroll.scrollBar = CreateFrame("Slider", "$parentscrollBar", scroll, "HybridScrollBarTemplate")
	scroll.scrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 1, -16)
	scroll.scrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 1, 12)

	if opts.update then
		scroll.update = opts.update
	end

	HybridScrollFrame_SetDoNotHideScrollBar(scroll, opts.doNotHideScrollBar ~= false)
	if opts.buttonTemplate then
		HybridScrollFrame_CreateButtons(scroll, opts.buttonTemplate)
	end

	return scroll
end

function UI:CreateFrame(parent, opts)
	if not parent then return nil end
	opts = opts or {}
	local frameType = opts.frameType or "Frame"
	local frame = CreateFrame(frameType, opts.globalName, parent, opts.template)

	if opts.width then frame:SetWidth(opts.width) end
	if opts.height then frame:SetHeight(opts.height) end
	if opts.size then frame:SetSize(opts.size[1], opts.size[2]) end
	if opts.point then frame:SetPoint(unpack(opts.point)) end
	if opts.points then
		ApplyPoints(frame, opts.points)
	end
	if opts.frameStrata then frame:SetFrameStrata(opts.frameStrata) end
	if opts.frameLevel then frame:SetFrameLevel(opts.frameLevel) end
	if opts.enableMouse ~= nil then frame:EnableMouse(opts.enableMouse) end
	if opts.scripts then
		ApplyScripts(frame, opts.scripts)
	end

	return frame
end

function UI:CreateScrollFrame(parent, opts)
	if not parent then return nil end
	opts = opts or {}

	local scroll = CreateFrame("ScrollFrame", opts.globalName, parent, opts.template or "UIPanelScrollFrameTemplate")

	if opts.width then scroll:SetWidth(opts.width) end
	if opts.height then scroll:SetHeight(opts.height) end
	if opts.point then scroll:SetPoint(unpack(opts.point)) end
	if opts.points then
		ApplyPoints(scroll, opts.points)
	end
	if opts.scrollChild then
		scroll:SetScrollChild(opts.scrollChild)
	end
	if opts.enableMouse ~= nil then
		scroll:EnableMouse(opts.enableMouse)
	end

	return scroll
end

function UI:CreateSlider(parent, opts)
	if not parent then return nil end
	opts = opts or {}

	local slider = CreateFrame("Slider", opts.globalName, parent, opts.template)

	if opts.width then slider:SetWidth(opts.width) end
	if opts.height then slider:SetHeight(opts.height) end
	if opts.point then slider:SetPoint(unpack(opts.point)) end
	if opts.points then
		ApplyPoints(slider, opts.points)
	end
	if opts.minValue ~= nil and opts.maxValue ~= nil then
		slider:SetMinMaxValues(opts.minValue, opts.maxValue)
	end
	if opts.value ~= nil then slider:SetValue(opts.value) end
	if opts.valueStep ~= nil then slider:SetValueStep(opts.valueStep) end
	if opts.obeyStepOnDrag ~= nil and slider.SetObeyStepOnDrag then
		slider:SetObeyStepOnDrag(opts.obeyStepOnDrag)
	end
	if opts.scripts then
		ApplyScripts(slider, opts.scripts)
	end

	return slider
end

function UI:CreateStatusBar(parent, opts)
	if not parent then return nil end
	opts = opts or {}

	local bar = CreateFrame("StatusBar", opts.globalName, parent, opts.template)

	if opts.width then bar:SetWidth(opts.width) end
	if opts.height then bar:SetHeight(opts.height) end
	if opts.point then bar:SetPoint(unpack(opts.point)) end
	if opts.points then
		ApplyPoints(bar, opts.points)
	end
	if opts.minValue ~= nil and opts.maxValue ~= nil then
		bar:SetMinMaxValues(opts.minValue, opts.maxValue)
	end
	if opts.value ~= nil then bar:SetValue(opts.value) end
	if opts.statusBarTexture then bar:SetStatusBarTexture(opts.statusBarTexture) end
	if opts.color then bar:SetStatusBarColor(unpack(opts.color)) end

	return bar
end

function UI:CreateTexture(parent, opts)
	if not parent then return nil end
	opts = opts or {}

	local texture = parent:CreateTexture(opts.globalName, opts.layer, opts.template, opts.subLevel)

	if opts.size then texture:SetSize(opts.size[1], opts.size[2]) end
	if opts.width then texture:SetWidth(opts.width) end
	if opts.height then texture:SetHeight(opts.height) end
	if opts.point then texture:SetPoint(unpack(opts.point)) end
	if opts.points then
		ApplyPoints(texture, opts.points)
	end
	if opts.texture then texture:SetTexture(opts.texture) end
	if opts.color then texture:SetColorTexture(unpack(opts.color)) end
	if opts.texCoord then texture:SetTexCoord(unpack(opts.texCoord)) end
	if opts.alpha ~= nil then texture:SetAlpha(opts.alpha) end
	if opts.blendMode then texture:SetBlendMode(opts.blendMode) end
	if opts.allPoints then texture:SetAllPoints(opts.allPoints) end

	return texture
end

function UI:CreateCheckButton(parent, opts)
	if not parent then return nil end
	opts = opts or {}

	local check = CreateFrame("CheckButton", opts.globalName, parent, opts.template or "UICheckButtonTemplate")

	if opts.point then check:SetPoint(unpack(opts.point)) end
	if opts.points then
		ApplyPoints(check, opts.points)
	end
	if opts.checked ~= nil then check:SetChecked(opts.checked) end

	local label = check.Text or check.text
	if label then
		if opts.text then label:SetText(opts.text) end
		if opts.textColor then label:SetTextColor(unpack(opts.textColor)) end
	end

	if opts.onClick then check:SetScript("OnClick", opts.onClick) end
	if opts.scripts then
		ApplyScripts(check, opts.scripts)
	end

	return check
end

function UI:CreateInfoFrame(parent, opts)
	opts = opts or {}

	local frame = CreateFrame("Frame", opts.globalName, parent, opts.template or "BagSyncInfoFrameTemplate")
	if opts.hide ~= false then frame:Hide() end

	if opts.width then frame:SetWidth(opts.width) end
	if opts.height then frame:SetHeight(opts.height) end
	if opts.backdropColor then frame:SetBackdropColor(unpack(opts.backdropColor)) end

	frame:EnableMouse(opts.enableMouse ~= false)
	frame:SetMovable(false)
	frame:SetResizable(false)
	frame:SetFrameStrata(opts.frameStrata or opts.strata or "HIGH")
	frame:ClearAllPoints()
	if opts.point then frame:SetPoint(unpack(opts.point)) end

	if frame.TitleText and opts.title then
		frame.TitleText:SetText(opts.title)
		if opts.titleFont then
			if type(opts.titleFont) == "table" then
				frame.TitleText:SetFont(unpack(opts.titleFont))
			else
				frame.TitleText:SetFont(opts.titleFont, opts.titleFontSize or 14, opts.titleFontFlags or "")
			end
		else
			frame.TitleText:SetFont(STANDARD_TEXT_FONT, 14, "")
		end
		if opts.titleColor then
			frame.TitleText:SetTextColor(unpack(opts.titleColor))
		else
			frame.TitleText:SetTextColor(1, 1, 1)
		end
	end

	if frame.CloseButton and opts.closeOnClick ~= false then
		frame.CloseButton:SetScript("OnClick", function(self) self:GetParent():Hide() end)
	end

	return frame
end

function UI:CreateEditBox(parent, opts)
	if not parent then return nil end
	opts = opts or {}

	local editBox = CreateFrame("EditBox", opts.globalName, parent, opts.template)

	if opts.size then
		editBox:SetSize(opts.size[1], opts.size[2])
	else
		if opts.width then editBox:SetWidth(opts.width) end
		if opts.height then editBox:SetHeight(opts.height) end
	end
	if opts.point then editBox:SetPoint(unpack(opts.point)) end
	if opts.points then
		ApplyPoints(editBox, opts.points)
	end
	if opts.autoFocus ~= nil then editBox:SetAutoFocus(opts.autoFocus) end
	if opts.multiLine ~= nil then editBox:SetMultiLine(opts.multiLine) end
	if opts.maxLetters ~= nil then editBox:SetMaxLetters(opts.maxLetters) end
	if opts.countInvisibleLetters ~= nil then editBox:SetCountInvisibleLetters(opts.countInvisibleLetters) end
	if opts.text then editBox:SetText(opts.text) end
	SetFontFromOpts(editBox, opts)
	if opts.scripts then
		ApplyScripts(editBox, opts.scripts)
	end

	return editBox
end

function UI:CreateDropdown(parent, opts)
	if not parent then return nil end
	opts = opts or {}

	local dd = CreateFrame("Frame", opts.globalName, parent, opts.template or "UIDropDownMenuTemplate")

	if opts.point then dd:SetPoint(unpack(opts.point)) end
	if opts.points then
		ApplyPoints(dd, opts.points)
	end
	if opts.width and UIDropDownMenu_SetWidth then
		UIDropDownMenu_SetWidth(dd, opts.width)
	end
	if opts.text and UIDropDownMenu_SetText then
		UIDropDownMenu_SetText(dd, opts.text)
	end

	return dd
end

function UI:CreateFontString(parent, opts)
	if not parent then return nil end
	opts = opts or {}

	local layer = opts.layer or "BACKGROUND"
	local fs = parent:CreateFontString(opts.globalName, layer, opts.template)

	if opts.text then fs:SetText(opts.text) end
	if opts.fontObject then
		fs:SetFontObject(opts.fontObject)
	else
		SetFontFromOpts(fs, opts)
	end
	if opts.textColor then fs:SetTextColor(unpack(opts.textColor)) end
	if opts.justifyH then fs:SetJustifyH(opts.justifyH) end
	if opts.justifyV then fs:SetJustifyV(opts.justifyV) end
	if opts.width then fs:SetWidth(opts.width) end
	if opts.height then fs:SetHeight(opts.height) end
	if opts.point then fs:SetPoint(unpack(opts.point)) end
	if opts.points then
		ApplyPoints(fs, opts.points)
	end

	return fs
end

function UI:CreateButton(parent, opts)
	if not parent then return nil end
	opts = opts or {}

	local btn = CreateFrame("Button", opts.globalName, parent, opts.template)

	if opts.text then btn:SetText(opts.text) end
	if opts.width then btn:SetWidth(opts.width) end
	if opts.height then btn:SetHeight(opts.height) end
	if opts.size then btn:SetSize(opts.size[1], opts.size[2]) end
	if opts.autoWidth then
		local padding = opts.autoWidthPadding or 30
		btn:SetWidth((btn:GetTextWidth() or 0) + padding)
	end
	if opts.point then btn:SetPoint(unpack(opts.point)) end
	if opts.points then
		ApplyPoints(btn, opts.points)
	end
	if opts.frameStrata then btn:SetFrameStrata(opts.frameStrata) end
	if opts.frameLevel then btn:SetFrameLevel(opts.frameLevel) end
	if opts.highlightTexture then btn:SetHighlightTexture(opts.highlightTexture) end

	if opts.registerForClicks then
		btn:RegisterForClicks(type(opts.registerForClicks) == "table" and unpack(opts.registerForClicks) or opts.registerForClicks)
	end
	if opts.registerForDrag then
		btn:RegisterForDrag(type(opts.registerForDrag) == "table" and unpack(opts.registerForDrag) or opts.registerForDrag)
	end
	if opts.scripts then
		ApplyScripts(btn, opts.scripts)
	end
	if opts.onClick then btn:SetScript("OnClick", opts.onClick) end
	if opts.onEnter then btn:SetScript("OnEnter", opts.onEnter) end
	if opts.onLeave then btn:SetScript("OnLeave", opts.onLeave) end

	return btn
end

function UI:SetupSearchBox(searchBox, handler)
	if not searchBox then return end

	searchBox.parentHandler = handler
	if searchBox.ClearButton then
		searchBox.ClearButton.parentHandler = handler
		searchBox.ClearButton:SetScript("OnEnter", function(self)
			self.Texture:SetAlpha(1.0)
		end)
		searchBox.ClearButton:SetScript("OnLeave", function(self)
			self.Texture:SetAlpha(0.5)
		end)
		searchBox.ClearButton:SetScript("OnMouseDown", function(self)
			self.Texture:SetPoint("TOPLEFT", -1, -2)
		end)
		searchBox.ClearButton:SetScript("OnMouseUp", function(self)
			self.Texture:SetPoint("TOPLEFT", 0, 0)
		end)
		searchBox.ClearButton:SetScript("OnShow", function(self)
			self.Texture:SetPoint("TOPLEFT", 0, 0)
		end)
		searchBox.ClearButton:SetScript("OnClick", function(self)
			UI:CallHandler(self, "SearchBox_ResetSearch", self)
		end)
	end
	searchBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		UI:CallHandler(self, "SearchBox_OnEscapePressed")
	end)
	searchBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		UI:CallHandler(self, "SearchBox_OnEnterPressed", self:GetText())
	end)
	searchBox:SetScript("OnEditFocusLost", function(self)
		self.SearchIcon:SetVertexColor(0.6, 0.6, 0.6)
		self.SearchInfo:SetShown(self:GetText():len() == 0)
		self.ClearButton:SetShown(self:GetText():len() > 0)
	end)
	searchBox:SetScript("OnEditFocusGained", function(self)
		self.SearchIcon:SetVertexColor(1.0, 1.0, 1.0)
		self.ClearButton:Show()
		self.SearchInfo:Hide()
	end)
	searchBox:SetScript("OnTextChanged", function(self, userInput)
		UI:CallHandler(self, "SearchBox_OnTextChanged", userInput)
	end)
end
