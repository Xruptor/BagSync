--[[
	wrapper.lua
		Internal lightweight framework that replaces Ace3 usage while keeping BagSync's
		module/event/message/console/locale/config behavior stable across Classic → Retail.
--]]

local addonName, BSYC = ...
BSYC = BSYC or {}
_G[addonName] = BSYC

-- ---------------------------------------------------------------------------
-- Locale (AceLocale replacement)
-- ---------------------------------------------------------------------------

BSYC._locales = BSYC._locales or {
	current = (type(_G.GetLocale) == "function" and _G.GetLocale()) or "enUS",
	default = nil,
	locales = {},
}

function BSYC:NewLocale(locale, isDefault)
	if type(locale) ~= "string" or locale == "" then return nil end
	local store = BSYC._locales

	if isDefault then
		store.default = store.default or {}
		return store.default
	end

	if locale ~= store.current then
		return nil
	end

	store.locales[locale] = store.locales[locale] or {}
	return store.locales[locale]
end

function BSYC:GetLocale()
	local store = BSYC._locales
	local L = store.locales[store.current] or store.default or {}
	if store.default and L ~= store.default then
		return setmetatable(L, { __index = store.default })
	end
	return L
end

BSYC.L = BSYC.L or setmetatable({}, {
	__index = function(_, key)
		return (BSYC:GetLocale() or {})[key]
	end,
})

-- ---------------------------------------------------------------------------
-- Console (AceConsole replacement)
-- ---------------------------------------------------------------------------

BSYC._chatCommands = BSYC._chatCommands or {}

function BSYC:Print(...)
	local msg = string.join(" ", tostringall(...))
	if _G.DEFAULT_CHAT_FRAME and _G.DEFAULT_CHAT_FRAME.AddMessage then
		_G.DEFAULT_CHAT_FRAME:AddMessage(msg)
	else
		print(msg)
	end
end

function BSYC:Printf(fmt, ...)
	BSYC:Print(string.format(fmt, ...))
end

local function normalizeCommand(command)
	command = tostring(command or ""):lower():gsub("^/", "")
	return command
end

function BSYC:RegisterChatCommand(command, func)
	command = normalizeCommand(command)
	if command == "" then return end

	local handler
	if type(func) == "string" then
		handler = function(msg) return BSYC[func](BSYC, msg) end
	elseif type(func) == "function" then
		handler = function(msg) return func(msg) end
	else
		return
	end

	local slashName = "BAGSYNC_" .. command:upper()
	_G.SlashCmdList[slashName] = handler
	_G["SLASH_" .. slashName .. "1"] = "/" .. command
	BSYC._chatCommands[command] = slashName
end

function BSYC:UnregisterChatCommand(command)
	command = normalizeCommand(command)
	local slashName = BSYC._chatCommands[command]
	if not slashName then return end
	_G.SlashCmdList[slashName] = nil
	_G["SLASH_" .. slashName .. "1"] = nil
	BSYC._chatCommands[command] = nil
end

-- ---------------------------------------------------------------------------
-- Modules (AceAddon replacement)
-- ---------------------------------------------------------------------------

BSYC._modulesByName = BSYC._modulesByName or {}
BSYC._modulesByOrder = BSYC._modulesByOrder or {}

function BSYC:NewModule(name, ...)
	if type(name) ~= "string" or name == "" then return nil end
	if BSYC._modulesByName[name] then
		return BSYC._modulesByName[name]
	end

	local module = { name = name }
	BSYC._modulesByName[name] = module
	table.insert(BSYC._modulesByOrder, module)

	module.RegisterEvent = function(self, ...) return BSYC.RegisterEvent(self, ...) end
	module.UnregisterEvent = function(self, ...) return BSYC.UnregisterEvent(self, ...) end
	module.UnregisterAllEvents = function(self) return BSYC.UnregisterAllEvents(self) end
	module.RegisterMessage = function(self, ...) return BSYC.RegisterMessage(self, ...) end
	module.UnregisterMessage = function(self, ...) return BSYC.UnregisterMessage(self, ...) end
	module.UnregisterAllMessages = function(self) return BSYC.UnregisterAllMessages(self) end
	module.SendMessage = function(self, ...) return BSYC.SendMessage(self, ...) end

	return module
end

function BSYC:GetModule(name, silent)
	local m = BSYC._modulesByName[name]
	if m then return m end
	if silent then return nil end
	error(("BagSync: module '%s' not found"):format(tostring(name)), 2)
end

function BSYC:IterateModules()
	return ipairs(BSYC._modulesByOrder)
end

-- ---------------------------------------------------------------------------
-- Events + messages (AceEvent replacement)
-- ---------------------------------------------------------------------------

local eventFrame = _G.CreateFrame("Frame")
BSYC._eventFrame = eventFrame

BSYC._eventHandlers = BSYC._eventHandlers or {}     -- event -> { [obj]=fn }
BSYC._messageHandlers = BSYC._messageHandlers or {} -- msg -> { [obj]=fn }

local function makeHandler(obj, method, arg)
	if type(method) == "function" then
		if arg ~= nil then
			return function(eventName, ...) return method(arg, eventName, ...) end
		end
		return function(eventName, ...) return method(eventName, ...) end
	end

	method = method or ""
	if type(method) ~= "string" or method == "" then
		return nil
	end

	if arg ~= nil then
		return function(eventName, ...) return obj[method](obj, arg, eventName, ...) end
	end
	return function(eventName, ...) return obj[method](obj, eventName, ...) end
end

function BSYC:RegisterEvent(eventName, method, arg)
	local obj = self
	if type(eventName) ~= "string" or eventName == "" then return end
	method = method or eventName
	local handler = makeHandler(obj, method, arg)
	if not handler then return end

	BSYC._eventHandlers[eventName] = BSYC._eventHandlers[eventName] or {}
	BSYC._eventHandlers[eventName][obj] = handler
	pcall(eventFrame.RegisterEvent, eventFrame, eventName)
end

function BSYC:UnregisterEvent(eventName)
	local obj = self
	if type(eventName) ~= "string" or eventName == "" then return end
	local handlers = BSYC._eventHandlers[eventName]
	if not handlers then return end
	handlers[obj] = nil
	if not next(handlers) then
		BSYC._eventHandlers[eventName] = nil
		pcall(eventFrame.UnregisterEvent, eventFrame, eventName)
	end
end

function BSYC:UnregisterAllEvents()
	local obj = self
	for eventName, handlers in pairs(BSYC._eventHandlers) do
		if handlers[obj] then
			handlers[obj] = nil
			if not next(handlers) then
				BSYC._eventHandlers[eventName] = nil
				pcall(eventFrame.UnregisterEvent, eventFrame, eventName)
			end
		end
	end
end

function BSYC:RegisterMessage(messageName, method, arg)
	local obj = self
	if type(messageName) ~= "string" or messageName == "" then return end
	method = method or messageName
	local handler = makeHandler(obj, method, arg)
	if not handler then return end

	BSYC._messageHandlers[messageName] = BSYC._messageHandlers[messageName] or {}
	BSYC._messageHandlers[messageName][obj] = handler
end

function BSYC:UnregisterMessage(messageName)
	local obj = self
	if type(messageName) ~= "string" or messageName == "" then return end
	local handlers = BSYC._messageHandlers[messageName]
	if not handlers then return end
	handlers[obj] = nil
	if not next(handlers) then
		BSYC._messageHandlers[messageName] = nil
	end
end

function BSYC:UnregisterAllMessages()
	local obj = self
	for messageName, handlers in pairs(BSYC._messageHandlers) do
		if handlers[obj] then
			handlers[obj] = nil
			if not next(handlers) then
				BSYC._messageHandlers[messageName] = nil
			end
		end
	end
end

function BSYC:SendMessage(messageName, ...)
	local handlers = BSYC._messageHandlers[messageName]
	if not handlers then return end
	for _, handler in pairs(handlers) do
		pcall(handler, messageName, ...)
	end
end

eventFrame:SetScript("OnEvent", function(_, eventName, ...)
	local handlers = BSYC._eventHandlers[eventName]
	if not handlers then return end
	for _, handler in pairs(handlers) do
		pcall(handler, eventName, ...)
	end
end)

-- ---------------------------------------------------------------------------
-- Config UI renderer (AceConfig replacement)
-- ---------------------------------------------------------------------------

BSYC.Config = BSYC.Config or { _tables = {} }

function BSYC.Config:RegisterOptionsTable(appName, optionsTable)
	if type(appName) ~= "string" or appName == "" then return end
	if type(optionsTable) ~= "table" then return end
	BSYC.Config._tables[appName] = optionsTable
end

BSYC.ConfigDialog = BSYC.ConfigDialog or { _settingsCategories = {} }

local uiNameCounter = 0
local function uiName(kind)
	uiNameCounter = uiNameCounter + 1
	return ("%s_%s_%d"):format(addonName, tostring(kind or "UI"), uiNameCounter)
end

local function resolveText(v, ctx)
	if type(v) == "function" then
		local ok, res = pcall(v, ctx)
		if ok then return res end
		return ""
	end
	return v
end

local function evalBool(value, ctx)
	if type(value) == "function" then
		local ok, res = pcall(value, ctx)
		if ok then return not not res end
		return false
	end
	return not not value
end

local function attachTooltip(frame, title, body)
	title = title or ""
	body = body or ""
	if not frame or (title == "" and body == "") then return end
	if type(frame.HookScript) ~= "function" then return end

	frame:HookScript("OnEnter", function(self)
		if not _G.GameTooltip then return end
		_G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if title ~= "" then
			_G.GameTooltip:AddLine(title, 1, 1, 1)
		end
		if body ~= "" then
			_G.GameTooltip:AddLine(body, 0.9, 0.9, 0.9, true)
		end
		_G.GameTooltip:Show()
	end)
	frame:HookScript("OnLeave", function()
		if _G.GameTooltip then _G.GameTooltip:Hide() end
	end)
end

local function applyTitleColor(fs, color)
	if not fs or not color then return end
	local r, g, b
	if type(color) == "table" then
		r = color.r or color[1]
		g = color.g or color[2]
		b = color.b or color[3]
	end
	if r and g and b then
		fs:SetTextColor(r, g, b)
	end
end

local function createTitle(parent, text, y, color)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
	fs:SetJustifyH("LEFT")
	fs:SetText(text or "")
	applyTitleColor(fs, color)
	return fs, y - (fs:GetStringHeight() + 8)
end

local function getContentWidth(parent)
	if not parent or type(parent.GetWidth) ~= "function" then
		return 560
	end
	local w = parent:GetWidth() or 0
	if not w or w <= 1 then
		local p = parent:GetParent()
		if p and type(p.GetWidth) == "function" then
			w = p:GetWidth() or 0
		end
	end
	if w and w > 1 then
		return math.max(100, w - 32)
	end
	return 560
end

local function createDescription(parent, text, y, fontTemplate)
	local fs = parent:CreateFontString(nil, "ARTWORK", fontTemplate or "GameFontHighlight")
	fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
	fs:SetJustifyH("LEFT")
	fs:SetJustifyV("TOP")
	local width = getContentWidth(parent)
	if width and width > 0 then
		fs:SetWidth(width)
	else
		fs:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
	end
	if fs.SetWordWrap then fs:SetWordWrap(true) end
	if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(true) end
	fs:SetText(text or "")
	return fs, y - (fs:GetStringHeight() + 10)
end

local function createCheckbox(parent, label, y)
	local cb = CreateFrame("CheckButton", uiName("Check"), parent, "InterfaceOptionsCheckButtonTemplate")
	cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
	local textRegion = cb.Text or _G[cb:GetName() .. "Text"]
	if textRegion then
		textRegion:SetText(label or "")
		local font, size, flags = textRegion:GetFont()
		if font and size then
			textRegion:SetFont(font, size + 1, flags)
		end
	end
	return cb, y - 26
end

local function createButton(parent, label, y)
	local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
	btn:SetHeight(22)
	btn:SetText(label or "")
	btn:SetWidth(math.max(140, btn:GetTextWidth() + 30))
	return btn, y - 28
end

local function createKeybind(parent, label, y)
	local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
	title:SetJustifyH("LEFT")
	title:SetText(label or "")

	local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	btn:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -4)
	btn:SetPoint("RIGHT", parent, "RIGHT", -28, 0)
	btn:SetHeight(20)
	btn:SetText("")
	return btn, title, y - (title:GetStringHeight() + 30)
end

local function createColorRow(parent, label, y)
	local row = CreateFrame("Button", nil, parent)
	row:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
	row:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
	row:SetHeight(20)
	row:EnableMouse(true)

	local swatch = row:CreateTexture(nil, "ARTWORK")
	swatch:SetSize(14, 14)
	swatch:SetPoint("LEFT", row, "LEFT", 0, 0)
	swatch:SetColorTexture(1, 1, 1, 1)

	local border = row:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
	border:SetSize(18, 18)
	border:SetPoint("CENTER", swatch, "CENTER", 0, 0)
	border:SetTexCoord(0.2, 0.8, 0.2, 0.8)

	local highlight = row:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetColorTexture(1, 1, 1, 0.08)
	highlight:SetPoint("TOPLEFT", row, "TOPLEFT", -2, 2)
	highlight:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 2, -2)

	local text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	text:SetPoint("LEFT", swatch, "RIGHT", 6, 0)
	text:SetJustifyH("LEFT")
	text:SetText(label or "")
	return row, swatch, text, y - 22
end

local function createSlider(parent, label, y)
	local slider = CreateFrame("Slider", uiName("Slider"), parent, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
	slider:SetPoint("RIGHT", parent, "RIGHT", -46, 0)
	local textRegion = slider.Text or _G[slider:GetName() .. "Text"]
	if textRegion then
		textRegion:SetText(label or "")
	end
	return slider, y - 48
end

local DROPDOWN_TOP_PADDING = 6
local DROPDOWN_WIDTH_PADDING = 40
local DROPDOWN_MIN_WIDTH = 140

local function createDropdown(parent, label, y)
	local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y - DROPDOWN_TOP_PADDING)
	title:SetJustifyH("LEFT")
	title:SetText(label or "")

	local dd = CreateFrame("Frame", uiName("DropDown"), parent, "UIDropDownMenuTemplate")
	dd:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -16, -2)
	return dd, title, y - (56 + DROPDOWN_TOP_PADDING)
end

local function getDropdownText(dd)
	if not dd or not dd.GetName then return nil end
	return _G[dd:GetName() .. "Text"] or dd.Text
end

local function getMeasureFontString(dd, text)
	if not dd then return nil end
	local measure = dd._bsycMeasureText
	if not measure then
		measure = dd:CreateFontString(nil, "ARTWORK")
		measure:Hide()
		dd._bsycMeasureText = measure
	end
	if text and text.GetFontObject and text:GetFontObject() then
		measure:SetFontObject(text:GetFontObject())
	elseif text and text.GetFont then
		local font, size, flags = text:GetFont()
		if font then
			measure:SetFont(font, size, flags)
		end
	end
	return measure
end

local function applyDropdownSizing(dd, entries, parent, force)
	if not dd or type(entries) ~= "table" or #entries == 0 then return end
	if dd._bsycWidth and not force then
		if UIDropDownMenu_SetWidth then
			UIDropDownMenu_SetWidth(dd, dd._bsycWidth)
		else
			dd:SetWidth(dd._bsycWidth)
		end
		return
	end

	if not dd._bsycDefaultWidth then
		local curWidth = dd.GetWidth and dd:GetWidth() or 0
		if curWidth and curWidth > 0 then
			dd._bsycDefaultWidth = curWidth
		end
	end

	local text = getDropdownText(dd)
	local measure = getMeasureFontString(dd, text)
	if not measure or not measure.SetText then return end

	local maxWidth = 0
	for i = 1, #entries do
		local label = tostring(entries[i].label or "")
		measure:SetText(label)
		local w = measure:GetStringWidth() or 0
		if w > maxWidth then
			maxWidth = w
		end
	end
	if maxWidth <= 0 then return end

	local width = math.floor(maxWidth + DROPDOWN_WIDTH_PADDING + 0.5)
	local minWidth = dd._bsycDefaultWidth or DROPDOWN_MIN_WIDTH
	if width < minWidth then width = minWidth end
	local maxAllowed = getContentWidth(parent)
	if maxAllowed and maxAllowed > 0 then
		maxAllowed = maxAllowed + 16
		if width > maxAllowed then width = maxAllowed end
	end

	dd._bsycWidth = width
	if UIDropDownMenu_SetWidth then
		UIDropDownMenu_SetWidth(dd, width)
	else
		dd:SetWidth(width)
	end
end

local function updateSliderText(slider, label, value, minVal, maxVal, showValue)
	local textRegion = slider.Text or _G[slider:GetName() .. "Text"]
	if textRegion then
		if showValue and label and label ~= "" then
			textRegion:SetText(("%s: %s"):format(label, tostring(value)))
		else
			textRegion:SetText(label or "")
		end
	end
	local low = slider.Low or _G[slider:GetName() .. "Low"]
	if low then low:SetText(tostring(minVal)) end
	local high = slider.High or _G[slider:GetName() .. "High"]
	if high then high:SetText(tostring(maxVal)) end
end

local function applyFontPreview(dropdownFrame, fontPath)
	if not dropdownFrame or type(fontPath) ~= "string" or fontPath == "" then return end
	local text = _G[dropdownFrame:GetName() .. "Text"] or dropdownFrame.Text
	if text and text.SetFont then
		local size = select(2, text:GetFont()) or 12
		text:SetFont(fontPath, size, "")
	end
end

local function applyDirty(dirty)
	if not dirty then return end

	local flags = {}
	if type(dirty) == "string" then
		flags[dirty] = true
	elseif type(dirty) == "table" then
		for i = 1, #dirty do
			flags[dirty[i]] = true
		end
	end

	if flags.fonts and type(BSYC.CreateFonts) == "function" then
		pcall(BSYC.CreateFonts, BSYC)
	end

	if flags.tooltips and BSYC.GetModule then
		local tooltip = BSYC:GetModule("Tooltip", true)
		if tooltip and tooltip.ResetCache then pcall(tooltip.ResetCache, tooltip) end
		if tooltip and tooltip.ResetLastLink then pcall(tooltip.ResetLastLink, tooltip) end
	end

	if flags.minimap and BSYC.GetModule then
		local minimap = BSYC:GetModule("Minimap", true)
		if minimap and minimap.UpdateVisibility then pcall(minimap.UpdateVisibility, minimap) end
	end

	if flags.bindings and _G.SaveBindings and _G.GetCurrentBindingSet then
		pcall(_G.SaveBindings, _G.GetCurrentBindingSet())
	end
end

local function compileBinding(item)
	if not item or type(item) ~= "table" then return nil end

	if type(item.get) == "function" or type(item.set) == "function" then
		local getter = item.get
		local setter = item.set
		return {
			get = getter and function()
				local ok, a, b, c, d = pcall(getter)
				if ok then return a, b, c, d end
				return nil
			end or nil,
			set = setter and function(...)
				pcall(setter, ...)
			end or nil,
		}
	end

	local bind = item.bind
	if type(bind) ~= "table" then return nil end

	local kind = bind[1]
	if kind == "opt" then
		local key = bind[2]
		return {
			get = function()
				local v = BSYC.options and BSYC.options[key]
				if v == nil then return item.default end
				return v
			end,
			set = function(v)
				BSYC.options = BSYC.options or {}
				BSYC.options[key] = v
			end,
		}
	elseif kind == "tracking" then
		local key = bind[2]
		return {
			get = function()
				local t = BSYC.tracking or (BSYC.options and BSYC.options.tracking)
				local v = t and t[key]
				if v == nil then return item.default end
				return v
			end,
			set = function(v)
				BSYC.options = BSYC.options or {}
				BSYC.options.tracking = BSYC.options.tracking or {}
				BSYC.options.tracking[key] = v
				if BSYC.tracking then
					BSYC.tracking[key] = v
				end
			end,
		}
	elseif kind == "color" then
		local key = bind[2]
		return {
			get = function()
				local c = (BSYC.colors and BSYC.colors[key])
					or (BSYC.options and BSYC.options.colors and BSYC.options.colors[key])
				if c then
					return tonumber(c.r) or 1, tonumber(c.g) or 1, tonumber(c.b) or 1
				end
				return 1, 1, 1
			end,
			set = function(r, g, b)
				r, g, b = tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1
				BSYC.options = BSYC.options or {}
				BSYC.options.colors = BSYC.options.colors or {}
				BSYC.options.colors[key] = BSYC.options.colors[key] or {}
				BSYC.options.colors[key].r = r
				BSYC.options.colors[key].g = g
				BSYC.options.colors[key].b = b
				if BSYC.colors then
					BSYC.colors[key] = BSYC.options.colors[key]
				end
			end,
		}
	elseif kind == "keybind" then
		local command = bind[2]
		return {
			get = function()
				if not _G.GetBindingKey then return "" end
				local k1 = _G.GetBindingKey(command)
				return k1 or ""
			end,
			set = function(key)
				if not (_G.GetBindingKey and _G.SetBinding) then return end
				local b1, b2 = _G.GetBindingKey(command)
				if b1 then _G.SetBinding(b1) end
				if b2 then _G.SetBinding(b2) end
				if key and key ~= "" then
					_G.SetBinding(key, command)
				end
			end,
		}
	elseif kind == "minimapEnable" then
		return {
			get = function()
				local opts = BSYC.options
				if not opts then return true end
				if opts.enableMinimap == false then return false end
				if opts.minimap and opts.minimap.hide then return false end
				return true
			end,
			set = function(enabled)
				enabled = enabled and true or false
				BSYC.options = BSYC.options or {}
				BSYC.options.enableMinimap = enabled
				BSYC.options.minimap = BSYC.options.minimap or {}
				BSYC.options.minimap.hide = not enabled
			end,
		}
	end

	return nil
end

local function getSelectEntries(values)
	values = resolveText(values)
	if type(values) ~= "table" then return {}, {} end

	local entries = {}
	local labels = {}

	if values[1] ~= nil then
		-- Array values: { "a", "b" } OR { {value,label}, ... }
		for i = 1, #values do
			local v = values[i]
			if type(v) == "table" then
				local value = v.value ~= nil and v.value or v[1]
				local label = v.label ~= nil and v.label or v[2]
				if value ~= nil then
					label = tostring(label ~= nil and label or value)
					entries[#entries + 1] = { value = value, label = label }
					labels[value] = label
				end
			else
				local value = v
				local label = tostring(v)
				entries[#entries + 1] = { value = value, label = label }
				labels[value] = label
			end
		end
		return entries, labels
	end

	for value, label in pairs(values) do
		label = tostring(label ~= nil and label or value)
		entries[#entries + 1] = { value = value, label = label }
	end
	table.sort(entries, function(a, b) return a.label:lower() < b.label:lower() end)
	for i = 1, #entries do
		labels[entries[i].value] = entries[i].label
	end

	return entries, labels
end

local function renderItems(parent, items, widgets, y)
	for i = 1, #(items or {}) do
		local item = items[i]
		if type(item) == "table" and not evalBool(item.hidden) then
			local itemType = item.type

			if itemType == "group" then
				local title = resolveText(item.title or item.name) or ""
				if item.inline then
					local box = CreateFrame("Frame", nil, parent, _G.BackdropTemplateMixin and "BackdropTemplate" or nil)
					if box.SetBackdrop then
						box:SetBackdrop({
							bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
							edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
							tile = true,
							tileSize = 16,
							edgeSize = 14,
							insets = { left = 3, right = 3, top = 3, bottom = 3 },
						})
						box:SetBackdropColor(0, 0, 0, 0.25)
					end
					box:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
					box:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
					local _, innerTop = createTitle(box, title, -8, item.titleColor)

					local inner = CreateFrame("Frame", nil, box)
					inner:SetPoint("TOPLEFT", box, "TOPLEFT", 0, innerTop)
					inner:SetPoint("RIGHT", box, "RIGHT", 0, 0)
					local innerY = -6
					innerY = renderItems(inner, item.items, widgets, innerY)
					local topOffset = -innerTop
					local contentHeight = -innerY + 6
					box:SetHeight(math.max(40, topOffset + contentHeight + 10))
					y = y - box:GetHeight() - 10
				else
					_, y = createTitle(parent, title, y, item.titleColor)
					y = renderItems(parent, item.items, widgets, y)
				end

			elseif itemType == "text" then
				local text = resolveText(item.text or item.name) or ""
				_, y = createDescription(parent, text, y, item.font)

			elseif itemType == "toggle" then
				local label = resolveText(item.label or item.name) or ""
				local cb
				cb, y = createCheckbox(parent, label, y)
				attachTooltip(cb, label, resolveText(item.desc) or "")

				local binding = compileBinding(item)
				cb:SetScript("OnClick", function(self)
					if binding and binding.set then
						binding.set(self:GetChecked() and true or false)
					end
					applyDirty(item.dirty)
					for _, w in ipairs(widgets) do w.refresh() end
				end)

				table.insert(widgets, {
					refresh = function()
						local v = binding and binding.get and binding.get()
						cb:SetChecked(not not v)
						cb:SetEnabled(not evalBool(item.disabled))
					end
				})

			elseif itemType == "select" then
				local label = resolveText(item.label or item.name) or ""
				local dd, _, ny = createDropdown(parent, label, y)
				y = ny
				local ddButton = dd and _G[dd:GetName() .. "Button"]
				attachTooltip(ddButton or dd, label, resolveText(item.desc) or "")

				local binding = compileBinding(item)
				local entries, labelByValue = getSelectEntries(item.values)

				UIDropDownMenu_Initialize(dd, function(_, level)
					local selected = binding and binding.get and binding.get()
					for j = 1, #entries do
						local entry = entries[j]
						local b = UIDropDownMenu_CreateInfo()
						b.text = tostring(entry.label)
						b.value = entry.value
						b.func = function()
							if binding and binding.set then
								binding.set(entry.value)
							end
							UIDropDownMenu_SetSelectedValue(dd, entry.value)
							applyDirty(item.dirty)
							for _, w in ipairs(widgets) do w.refresh() end
						end
						b.checked = (selected == entry.value)
						UIDropDownMenu_AddButton(b, level)
					end
				end)
				applyDropdownSizing(dd, entries, parent, false)

				table.insert(widgets, {
					refresh = function()
						local selected = binding and binding.get and binding.get()
						UIDropDownMenu_SetSelectedValue(dd, selected)
						local t = labelByValue[selected] or ""
						UIDropDownMenu_SetText(dd, t)
						UIDropDownMenu_DisableDropDown(dd)
						if not evalBool(item.disabled) then
							UIDropDownMenu_EnableDropDown(dd)
						end
						if item.control == "font" and type(BSYC.GetFontPath) == "function" then
							applyFontPreview(dd, BSYC:GetFontPath(t ~= "" and t or tostring(selected or "")))
						end
						applyDropdownSizing(dd, entries, parent, item.control == "font")
					end
				})

			elseif itemType == "range" then
				local label = resolveText(item.label or item.name) or ""
				local slider
				slider, y = createSlider(parent, label, y)
				attachTooltip(slider, label, resolveText(item.desc) or "")

				local binding = compileBinding(item)
				local minVal = tonumber(item.min) or 0
				local maxVal = tonumber(item.max) or 100
				local step = tonumber(item.step) or 1

				slider:SetMinMaxValues(minVal, maxVal)
				slider:SetValueStep(step)
				if slider.SetObeyStepOnDrag then
					slider:SetObeyStepOnDrag(true)
				end
				updateSliderText(slider, label, minVal, minVal, maxVal, item.showValue)

				slider._bsycUpdating = false
				slider._bsycDragging = false
				slider:HookScript("OnMouseDown", function(self) self._bsycDragging = true end)
				slider:HookScript("OnMouseUp", function(self)
					self._bsycDragging = false
					applyDirty(item.dirty)
					for _, w in ipairs(widgets) do w.refresh() end
				end)

				slider:SetScript("OnValueChanged", function(self, value)
					if self._bsycUpdating then return end
					value = tonumber(value) or minVal
					if step and step > 0 then
						value = math.floor((value / step) + 0.5) * step
					end
					if value < minVal then value = minVal end
					if value > maxVal then value = maxVal end
					updateSliderText(self, label, value, minVal, maxVal, item.showValue)
					if binding and binding.set then binding.set(value) end
					if not self._bsycDragging then
						applyDirty(item.dirty)
						for _, w in ipairs(widgets) do w.refresh() end
					end
				end)

				table.insert(widgets, {
					refresh = function()
						local v = binding and binding.get and tonumber(binding.get()) or item.default
						v = tonumber(v) or minVal
						local orig = v
						if v < minVal then v = minVal end
						if v > maxVal then v = maxVal end
						if binding and binding.set and v ~= orig then
							binding.set(v)
						end
						slider._bsycUpdating = true
						slider:SetValue(v)
						slider._bsycUpdating = false
						updateSliderText(slider, label, v, minVal, maxVal, item.showValue)
						slider:SetEnabled(not evalBool(item.disabled))
					end
				})

			elseif itemType == "button" then
				local label = resolveText(item.label or item.name) or ""
				local btn
				btn, y = createButton(parent, label, y)
				attachTooltip(btn, label, resolveText(item.desc) or "")

				btn:SetScript("OnClick", function()
					if type(item.onClick) == "function" then
						pcall(item.onClick)
					end
					applyDirty(item.dirty)
					for _, w in ipairs(widgets) do w.refresh() end
				end)
				table.insert(widgets, { refresh = function() btn:SetEnabled(not evalBool(item.disabled)) end })

			elseif itemType == "color" then
				local label = resolveText(item.label or item.name) or ""
				local row, swatch, text
				row, swatch, text, y = createColorRow(parent, label, y)
				attachTooltip(row, label, resolveText(item.desc) or "")

				local binding = compileBinding(item)
				row:SetScript("OnClick", function()
					local r, g, b = 1, 1, 1
					if binding and binding.get then
						r, g, b = binding.get()
					end
					r, g, b = tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1

					local function applyColor()
						local cr, cg, cb = _G.ColorPickerFrame:GetColorRGB()
						if binding and binding.set then
							binding.set(cr, cg, cb)
						end
						applyDirty(item.dirty)
						for _, w in ipairs(widgets) do w.refresh() end
					end

					local picker = _G.ColorPickerFrame
					if picker.SetupColorPickerAndShow then
						local function cancelFunc(previous)
							local pr, pg, pb = r, g, b
							if type(previous) == "table" then
								pr = previous.r or previous[1] or pr
								pg = previous.g or previous[2] or pg
								pb = previous.b or previous[3] or pb
							end
							if binding and binding.set then
								binding.set(pr, pg, pb)
							end
							applyDirty(item.dirty)
							for _, w in ipairs(widgets) do w.refresh() end
						end

						picker:SetupColorPickerAndShow({
							r = r, g = g, b = b,
							hasOpacity = false,
							opacity = 1,
							swatchFunc = applyColor,
							cancelFunc = cancelFunc,
						})
					else
						--fall back to classic
						picker.hasOpacity = false
						picker.previousValues = { r, g, b }
						picker.func = applyColor
						picker.cancelFunc = function()
							local prev = picker.previousValues
							if prev and binding and binding.set then
								binding.set(prev[1], prev[2], prev[3])
							end
							applyDirty(item.dirty)
							for _, w in ipairs(widgets) do w.refresh() end
						end
						if picker.SetColorRGB then
							picker:SetColorRGB(r, g, b)
						elseif picker.Content and picker.Content.ColorPicker and picker.Content.ColorPicker.SetColorRGB then
							picker.Content.ColorPicker:SetColorRGB(r, g, b)
						end
						picker:Show()
					end
				end)
				table.insert(widgets, {
					refresh = function()
						local disabled = evalBool(item.disabled)
						row:SetEnabled(not disabled)
						if text then
							if disabled then
								text:SetTextColor(0.5, 0.5, 0.5)
							else
								text:SetTextColor(1, 0.82, 0)
							end
						end
						if swatch and binding and binding.get then
							local r, g, b = binding.get()
							r, g, b = tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1
							swatch:SetColorTexture(r, g, b, 1)
							if swatch.SetDesaturated then
								swatch:SetDesaturated(disabled)
							end
						end
					end
				})

			elseif itemType == "keybind" then
				local label = resolveText(item.label or item.name) or ""
				local btn
				btn, _, y = createKeybind(parent, label, y)
				attachTooltip(btn, label, resolveText(item.desc) or "")

				local binding = compileBinding(item)
				local listening = false

				local function stopListening()
					listening = false
					btn:SetScript("OnKeyDown", nil)
				end

				local function currentBinding()
					local v = binding and binding.get and binding.get()
					if v == nil or v == "" then return "" end
					return tostring(v)
				end

				btn:EnableKeyboard(true)
				btn:SetScript("OnClick", function()
					if evalBool(item.disabled) then return end
					listening = not listening
					if not listening then
						stopListening()
						for _, w in ipairs(widgets) do w.refresh() end
						return
					end
					btn:SetScript("OnKeyDown", function(_, key)
						if key == "ESCAPE" then
							if binding and binding.set then binding.set("") end
							stopListening()
							applyDirty(item.dirty)
							for _, w in ipairs(widgets) do w.refresh() end
							return
						end
						if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then
							return
						end
						local combo = key
						if IsShiftKeyDown() then combo = "SHIFT-" .. combo end
						if IsControlKeyDown() then combo = "CTRL-" .. combo end
						if IsAltKeyDown() then combo = "ALT-" .. combo end
						if binding and binding.set then binding.set(combo) end
						stopListening()
						applyDirty(item.dirty)
						for _, w in ipairs(widgets) do w.refresh() end
					end)
				end)

				table.insert(widgets, {
					refresh = function()
						btn:SetEnabled(not evalBool(item.disabled))
						local v = currentBinding()
						if v ~= "" then
							btn:SetText(v)
						else
							btn:SetText(_G.NOT_BOUND or BSYC.L.None or "None")
						end
					end
				})
			end
		end
	end
	return y
end

local function registerPanel(panel, name, parentName)
	panel.name = name
	panel.parent = parentName

	if _G.Settings and type(_G.Settings) == "table" and _G.Settings.RegisterAddOnCategory then
		local parentCategory = parentName and BSYC.ConfigDialog._settingsCategories[parentName] or nil
		local category
		if parentCategory and _G.Settings.RegisterCanvasLayoutSubcategory then
			category = _G.Settings.RegisterCanvasLayoutSubcategory(parentCategory, panel, name)
		else
			category = _G.Settings.RegisterCanvasLayoutCategory(panel, name)
		end
		_G.Settings.RegisterAddOnCategory(category)
		BSYC.ConfigDialog._settingsCategories[name] = category
		return
	end

	if _G.InterfaceOptions_AddCategory then
		_G.InterfaceOptions_AddCategory(panel)
	end
end

function BSYC.ConfigDialog:AddToBlizOptions(appName, name, parentName)
	local optionsTable = BSYC.Config._tables[appName]
	if type(optionsTable) ~= "table" then
		error(("BagSync: options table '%s' not registered"):format(tostring(appName)), 2)
	end

	local panel = CreateFrame("Frame", nil, UIParent)
	panel:Hide()

	local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 0, 0)
	scroll:SetPoint("BOTTOMRIGHT", -28, 0)

	local content = CreateFrame("Frame", nil, scroll)
	content:SetPoint("TOPLEFT", 0, 0)
	content:SetPoint("RIGHT", 0, 0)
	scroll:SetScrollChild(content)

	panel._widgets = {}
	panel._built = false

	local function syncContentWidth()
		local w = scroll.GetWidth and scroll:GetWidth() or 0
		if not w or w <= 1 then
			w = panel.GetWidth and (panel:GetWidth() - 32) or 0
		end
		if w and w > 1 then
			content:SetWidth(w)
		end
	end

	scroll:HookScript("OnSizeChanged", function()
		syncContentWidth()
	end)

	panel:SetScript("OnShow", function()
		syncContentWidth()
		if panel._built then
			for _, w in ipairs(panel._widgets) do w.refresh() end
			return
		end
		panel._built = true

		local y = -12
		local title = resolveText(optionsTable.title or optionsTable.name) or ""
		if title ~= "" then
			_, y = createTitle(content, title, y, optionsTable.titleColor)
		end
		local desc = resolveText(optionsTable.description or optionsTable.desc) or ""
		if desc ~= "" then
			_, y = createDescription(content, desc, y)
		end
		y = renderItems(content, optionsTable.items, panel._widgets, y)
		content:SetHeight(math.max(1, -y + 20))
		for _, w in ipairs(panel._widgets) do w.refresh() end
	end)

	registerPanel(panel, name, parentName)
	return panel
end

-- ---------------------------------------------------------------------------
-- Addon lifecycle: core on ADDON_LOADED; modules on PLAYER_LOGIN
-- ---------------------------------------------------------------------------

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

local coreEnabled = false
local modulesEnabled = false

eventFrame:HookScript("OnEvent", function(_, eventName, arg1)
	if eventName == "ADDON_LOADED" then
		if arg1 ~= addonName or coreEnabled then return end
		coreEnabled = true
		if type(BSYC.OnEnable) == "function" then
			pcall(BSYC.OnEnable, BSYC)
		end
		return
	end

	if eventName == "PLAYER_LOGIN" then
		if modulesEnabled then return end
		modulesEnabled = true

		if not coreEnabled and type(BSYC.OnEnable) == "function" then
			coreEnabled = true
			pcall(BSYC.OnEnable, BSYC)
		end

		for _, module in BSYC:IterateModules() do
			if type(module.OnEnable) == "function" then
				pcall(module.OnEnable, module)
			end
		end
	end
end)
