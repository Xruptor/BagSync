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
