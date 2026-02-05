--[[
	ui.lua
		UI helpers (backbone only; preserves existing layout/behavior)
--]]

local BSYC = select(2, ...)
local UI = BSYC:NewModule("UI")

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

function UI:AttachListItemHandlers(button, handler, opts)
	if not button or button.__bsycHandlers then return end

	opts = opts or {}
	local onClick = opts.onClick or "Item_OnClick"
	local onEnter = opts.onEnter or "Item_OnEnter"
	local onLeave = opts.onLeave or "Item_OnLeave"

	button.parentHandler = handler
	button:SetScript("OnClick", function(self)
		UI:CallHandler(self, onClick, self)
	end)
	button:SetScript("OnEnter", function(self)
		UI:CallHandler(self, onEnter, self)
	end)
	button:SetScript("OnLeave", function(self)
		UI:CallHandler(self, onLeave, self)
	end)

	local details = opts.detailsButton and button[opts.detailsButton]
	if details then
		local onDetailsClick = opts.onDetailsClick or "ItemDetails"
		local onDetailsEnter = opts.onDetailsEnter or "ItemDetails_OnEnter"
		local onDetailsLeave = opts.onDetailsLeave or "ItemDetails_OnLeave"
		details.parentHandler = handler
		details:SetScript("OnClick", function(self)
			UI:CallHandler(self, onDetailsClick, self)
		end)
		if onDetailsEnter ~= false then
			details:SetScript("OnEnter", function(self)
				if self:GetParent().DetailsHighlight then
					self:GetParent().DetailsHighlight:SetAlpha(0.75)
				end
				UI:CallHandler(self, onDetailsEnter, self)
			end)
		end
		if onDetailsLeave ~= false then
			details:SetScript("OnLeave", function(self)
				if self:GetParent().DetailsHighlight then
					self:GetParent().DetailsHighlight:SetAlpha(0)
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

	local frame = _G.CreateFrame("Frame", nil, parent, template)
	if module then
		Mixin(frame, module)
	end

	if opts.globalName then
		_G[opts.globalName] = frame
		-- Add to special frames so window can be closed when the escape key is pressed.
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
		closeBtn:SetPoint("TOPRIGHT", C_EditMode and -3 or 2, C_EditMode and -3 or 1)
		frame.closeBtn = closeBtn
	end

	return frame
end

function UI:CreateHybridScrollFrame(parent, opts)
	opts = opts or {}
	local scroll = _G.CreateFrame("ScrollFrame", nil, parent, "HybridScrollFrameTemplate")

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
	opts = opts or {}
	local frameType = opts.frameType or "Frame"
	local frame = _G.CreateFrame(frameType, opts.globalName, parent, opts.template)

	if opts.width then frame:SetWidth(opts.width) end
	if opts.height then frame:SetHeight(opts.height) end
	if opts.size then frame:SetSize(opts.size[1], opts.size[2]) end
	if opts.point then frame:SetPoint(unpack(opts.point)) end
	if opts.points then
		for i = 1, #opts.points do
			frame:SetPoint(unpack(opts.points[i]))
		end
	end
	if opts.frameStrata then frame:SetFrameStrata(opts.frameStrata) end
	if opts.frameLevel then frame:SetFrameLevel(opts.frameLevel) end
	if opts.enableMouse ~= nil then frame:EnableMouse(opts.enableMouse) end
	if opts.scripts then
		for event, fn in pairs(opts.scripts) do
			frame:SetScript(event, fn)
		end
	end

	return frame
end

function UI:CreateScrollFrame(parent, opts)
	opts = opts or {}
	if not parent then return nil end

	local scroll = _G.CreateFrame("ScrollFrame", opts.globalName, parent, opts.template or "UIPanelScrollFrameTemplate")

	if opts.width then scroll:SetWidth(opts.width) end
	if opts.height then scroll:SetHeight(opts.height) end
	if opts.point then scroll:SetPoint(unpack(opts.point)) end
	if opts.points then
		for i = 1, #opts.points do
			scroll:SetPoint(unpack(opts.points[i]))
		end
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
	opts = opts or {}
	if not parent then return nil end

	local slider = _G.CreateFrame("Slider", opts.globalName, parent, opts.template)

	if opts.width then slider:SetWidth(opts.width) end
	if opts.height then slider:SetHeight(opts.height) end
	if opts.point then slider:SetPoint(unpack(opts.point)) end
	if opts.points then
		for i = 1, #opts.points do
			slider:SetPoint(unpack(opts.points[i]))
		end
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
		for event, fn in pairs(opts.scripts) do
			slider:SetScript(event, fn)
		end
	end

	return slider
end

function UI:CreateStatusBar(parent, opts)
	opts = opts or {}
	if not parent then return nil end

	local bar = _G.CreateFrame("StatusBar", opts.globalName, parent, opts.template)

	if opts.width then bar:SetWidth(opts.width) end
	if opts.height then bar:SetHeight(opts.height) end
	if opts.point then bar:SetPoint(unpack(opts.point)) end
	if opts.points then
		for i = 1, #opts.points do
			bar:SetPoint(unpack(opts.points[i]))
		end
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
	opts = opts or {}
	if not parent then return nil end

	local texture = parent:CreateTexture(opts.globalName, opts.layer, opts.template, opts.subLevel)

	if opts.size then texture:SetSize(opts.size[1], opts.size[2]) end
	if opts.width then texture:SetWidth(opts.width) end
	if opts.height then texture:SetHeight(opts.height) end
	if opts.point then texture:SetPoint(unpack(opts.point)) end
	if opts.points then
		for i = 1, #opts.points do
			texture:SetPoint(unpack(opts.points[i]))
		end
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
	opts = opts or {}
	if not parent then return nil end

	local check = _G.CreateFrame("CheckButton", opts.globalName, parent, opts.template or "UICheckButtonTemplate")

	if opts.point then check:SetPoint(unpack(opts.point)) end
	if opts.points then
		for i = 1, #opts.points do
			check:SetPoint(unpack(opts.points[i]))
		end
	end
	if opts.checked ~= nil then check:SetChecked(opts.checked) end

	local label = check.Text or check.text
	if label then
		if opts.text then label:SetText(opts.text) end
		if opts.textColor then label:SetTextColor(unpack(opts.textColor)) end
	end

	if opts.onClick then check:SetScript("OnClick", opts.onClick) end
	if opts.scripts then
		for event, fn in pairs(opts.scripts) do
			check:SetScript(event, fn)
		end
	end

	return check
end

function UI:CreateInfoFrame(parent, opts)
	opts = opts or {}

	local frame = _G.CreateFrame("Frame", opts.globalName, parent, opts.template or "BagSyncInfoFrameTemplate")
	if opts.hide ~= false then frame:Hide() end

	if opts.width then frame:SetWidth(opts.width) end
	if opts.height then frame:SetHeight(opts.height) end
	if opts.backdropColor then frame:SetBackdropColor(unpack(opts.backdropColor)) end

	frame:EnableMouse(opts.enableMouse ~= false) --don't allow clickthrough by default
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
	opts = opts or {}
	if not parent then return nil end

	local editBox = _G.CreateFrame("EditBox", opts.globalName, parent, opts.template)

	if opts.size then
		editBox:SetSize(opts.size[1], opts.size[2])
	else
		if opts.width then editBox:SetWidth(opts.width) end
		if opts.height then editBox:SetHeight(opts.height) end
	end
	if opts.point then editBox:SetPoint(unpack(opts.point)) end
	if opts.points then
		for i = 1, #opts.points do
			editBox:SetPoint(unpack(opts.points[i]))
		end
	end
	if opts.autoFocus ~= nil then editBox:SetAutoFocus(opts.autoFocus) end
	if opts.multiLine ~= nil then editBox:SetMultiLine(opts.multiLine) end
	if opts.maxLetters ~= nil then editBox:SetMaxLetters(opts.maxLetters) end
	if opts.countInvisibleLetters ~= nil then editBox:SetCountInvisibleLetters(opts.countInvisibleLetters) end
	if opts.text then editBox:SetText(opts.text) end
	if opts.fontObject then editBox:SetFontObject(opts.fontObject) end
	if opts.font then
		if type(opts.font) == "table" then
			editBox:SetFont(unpack(opts.font))
		elseif opts.fontSize then
			editBox:SetFont(opts.font, opts.fontSize, opts.fontFlags or "")
		else
			editBox:SetFont(opts.font, opts.fontSize or 12, opts.fontFlags or "")
		end
	end
	if opts.scripts then
		for event, fn in pairs(opts.scripts) do
			editBox:SetScript(event, fn)
		end
	end

	return editBox
end

function UI:CreateDropdown(parent, opts)
	opts = opts or {}
	if not parent then return nil end

	local dd = _G.CreateFrame("Frame", opts.globalName, parent, opts.template or "UIDropDownMenuTemplate")

	if opts.point then dd:SetPoint(unpack(opts.point)) end
	if opts.points then
		for i = 1, #opts.points do
			dd:SetPoint(unpack(opts.points[i]))
		end
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
	opts = opts or {}
	if not parent then return nil end

	local layer = opts.layer or "BACKGROUND"
	local fs = parent:CreateFontString(opts.globalName, layer, opts.template)

	if opts.text then fs:SetText(opts.text) end
	if opts.fontObject then fs:SetFontObject(opts.fontObject) end
	if opts.font then
		if type(opts.font) == "table" then
			fs:SetFont(unpack(opts.font))
		elseif opts.fontSize then
			fs:SetFont(opts.font, opts.fontSize, opts.fontFlags or "")
		else
			fs:SetFont(opts.font, opts.fontSize or 12, opts.fontFlags or "")
		end
	end
	if opts.textColor then fs:SetTextColor(unpack(opts.textColor)) end
	if opts.justifyH then fs:SetJustifyH(opts.justifyH) end
	if opts.justifyV then fs:SetJustifyV(opts.justifyV) end
	if opts.width then fs:SetWidth(opts.width) end
	if opts.height then fs:SetHeight(opts.height) end
	if opts.point then fs:SetPoint(unpack(opts.point)) end
	if opts.points then
		for i = 1, #opts.points do
			fs:SetPoint(unpack(opts.points[i]))
		end
	end

	return fs
end

function UI:CreateButton(parent, opts)
	opts = opts or {}
	if not parent then return nil end

	local btn = _G.CreateFrame("Button", opts.globalName, parent, opts.template)

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
		for i = 1, #opts.points do
			btn:SetPoint(unpack(opts.points[i]))
		end
	end
	if opts.frameStrata then btn:SetFrameStrata(opts.frameStrata) end
	if opts.frameLevel then btn:SetFrameLevel(opts.frameLevel) end
	if opts.highlightTexture then btn:SetHighlightTexture(opts.highlightTexture) end

	if opts.registerForClicks then
		if type(opts.registerForClicks) == "table" then
			btn:RegisterForClicks(unpack(opts.registerForClicks))
		else
			btn:RegisterForClicks(opts.registerForClicks)
		end
	end
	if opts.registerForDrag then
		if type(opts.registerForDrag) == "table" then
			btn:RegisterForDrag(unpack(opts.registerForDrag))
		else
			btn:RegisterForDrag(opts.registerForDrag)
		end
	end
	if opts.scripts then
		for event, fn in pairs(opts.scripts) do
			btn:SetScript(event, fn)
		end
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
		UI:CallHandler(self, "SearchBox_OnEscapePressed", self:GetText())
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
