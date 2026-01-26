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

local function makeInfo(opt)
	return { arg = opt and opt.arg }
end

local function getOptValue(opt, parent, info)
	local getter = opt and opt.get or parent and parent.get
	if type(getter) ~= "function" then return nil end
	return getter(info)
end

local function setOptValue(opt, parent, info, ...)
	local setter = opt and opt.set or parent and parent.set
	if type(setter) ~= "function" then return end
	return setter(info, ...)
end

local function isDisabled(opt)
	if type(opt.disabled) == "function" then
		return not not opt.disabled()
	end
	return not not opt.disabled
end

local function isHidden(opt)
	if type(opt.hidden) == "function" then
		return not not opt.hidden()
	end
	return not not opt.hidden
end

local function sortedArgs(args)
	local out = {}
	for key, opt in pairs(args or {}) do
		if type(opt) == "table" and not isHidden(opt) then
			table.insert(out, { key = key, opt = opt })
		end
	end
	table.sort(out, function(a, b)
		local ao = tonumber(a.opt.order) or 999999
		local bo = tonumber(b.opt.order) or 999999
		if ao == bo then return tostring(a.key) < tostring(b.key) end
		return ao < bo
	end)
	return out
end

local function resolveText(v)
	if type(v) == "function" then
		local ok, res = pcall(v)
		if ok then return res end
		return ""
	end
	return v
end

local function createTitle(parent, text, y)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
	fs:SetJustifyH("LEFT")
	fs:SetText(text or "")
	return fs, y - (fs:GetStringHeight() + 8)
end

local function createDescription(parent, text, y)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
	fs:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
	fs:SetJustifyH("LEFT")
	fs:SetText(text or "")
	return fs, y - (fs:GetStringHeight() + 10)
end

local function createCheckbox(parent, label, y)
	local cb = CreateFrame("CheckButton", uiName("Check"), parent, "InterfaceOptionsCheckButtonTemplate")
	cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
	local textRegion = cb.Text or _G[cb:GetName() .. "Text"]
	if textRegion then
		textRegion:SetText(label or "")
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

local function createDropdown(parent, label, y)
	local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
	title:SetJustifyH("LEFT")
	title:SetText(label or "")

	local dd = CreateFrame("Frame", uiName("DropDown"), parent, "UIDropDownMenuTemplate")
	dd:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -16, -2)
	return dd, title, y - 56
end

local function getSelectEntries(values, sorting)
	local entries = {}
	if type(values) ~= "table" then return entries end

	if type(sorting) == "table" and #sorting > 0 then
		for _, key in ipairs(sorting) do
			if values[key] ~= nil then
				table.insert(entries, { key = key, label = values[key] })
			end
		end
		return entries
	end

	if values[1] ~= nil then
		for i = 1, #values do
			table.insert(entries, { key = i, label = values[i] })
		end
		return entries
	end

	for key, label in pairs(values) do
		table.insert(entries, { key = key, label = label })
	end
	table.sort(entries, function(a, b) return tostring(a.label) < tostring(b.label) end)
	return entries
end

local function applyFontPreview(dropdownFrame, fontPath)
	if not dropdownFrame or type(fontPath) ~= "string" or fontPath == "" then return end
	local text = _G[dropdownFrame:GetName() .. "Text"] or dropdownFrame.Text
	if text and text.SetFont then
		local size = select(2, text:GetFont()) or 12
		text:SetFont(fontPath, size, "")
	end
end

local function renderOptions(parent, group, widgets, y)
	for _, item in ipairs(sortedArgs(group.args)) do
		local opt = item.opt
		local optType = opt.type
		local optLabel = resolveText(opt.name) or ""

		if optType == "group" then
			if opt.guiInline then
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
				createTitle(box, resolveText(opt.name) or "", -10)
				y = y - 24

				local inner = CreateFrame("Frame", nil, box)
				inner:SetPoint("TOPLEFT", box, "TOPLEFT", 0, -28)
				inner:SetPoint("RIGHT", box, "RIGHT", 0, 0)
				local innerY = -6
				innerY = renderOptions(inner, opt, widgets, innerY)
				box:SetHeight(math.max(40, -innerY + 14))
				y = y - box:GetHeight() - 10
			else
				_, y = createTitle(parent, resolveText(opt.name) or "", y)
				y = renderOptions(parent, opt, widgets, y)
			end

		elseif optType == "description" then
			_, y = createDescription(parent, resolveText(opt.name) or "", y)

		elseif optType == "toggle" then
			local cb
			cb, y = createCheckbox(parent, optLabel, y)
			local info = makeInfo(opt)
			cb:SetScript("OnClick", function(self)
				setOptValue(opt, group, info, self:GetChecked() and true or false)
				for _, w in ipairs(widgets) do w.refresh() end
			end)
			table.insert(widgets, {
				refresh = function()
					cb:SetChecked(not not getOptValue(opt, group, info))
					cb:SetEnabled(not isDisabled(opt))
				end
			})

		elseif optType == "select" then
			local dd, _, ny = createDropdown(parent, optLabel, y)
			y = ny
			local info = makeInfo(opt)
			local values = resolveText(opt.values) or opt.values or {}
			local entries = getSelectEntries(values, opt.sorting or opt.ordering)

			UIDropDownMenu_Initialize(dd, function(self, level)
				local selected = getOptValue(opt, group, info)
				for _, entry in ipairs(entries) do
					local v = entry.key
					local text = tostring(entry.label)
					local b = UIDropDownMenu_CreateInfo()
					b.text = text
					b.value = v
					b.func = function()
						setOptValue(opt, group, info, v)
						UIDropDownMenu_SetSelectedValue(dd, v)
						for _, w in ipairs(widgets) do w.refresh() end
					end
					b.checked = (selected == v)
					UIDropDownMenu_AddButton(b, level)
				end
			end)

			table.insert(widgets, {
				refresh = function()
					local selected = getOptValue(opt, group, info)
					UIDropDownMenu_SetSelectedValue(dd, selected)

					local label
					for _, entry in ipairs(entries) do
						if entry.key == selected then
							label = tostring(entry.label)
							break
						end
					end
					UIDropDownMenu_SetText(dd, label or "")
					UIDropDownMenu_DisableDropDown(dd)
					if not isDisabled(opt) then
						UIDropDownMenu_EnableDropDown(dd)
					end

					if (opt.itemControl == "FONT-DDL" or opt.itemControl == "DDI-Font")
						and label
						and type(BSYC.GetFontPath) == "function"
					then
						applyFontPreview(dd, BSYC:GetFontPath(label))
					end
				end
			})

		elseif optType == "range" then
			local slider
			slider, y = createSlider(parent, optLabel, y)
			local info = makeInfo(opt)
			local minVal = tonumber(opt.min) or 0
			local maxVal = tonumber(opt.max) or 100
			local step = tonumber(opt.step) or 1
			slider:SetMinMaxValues(minVal, maxVal)
			slider:SetValueStep(step)
			if slider.SetObeyStepOnDrag then
				slider:SetObeyStepOnDrag(true)
			end
			slider:SetScript("OnValueChanged", function(self, value)
				value = tonumber(value) or minVal
				setOptValue(opt, group, info, value)
			end)
			table.insert(widgets, {
				refresh = function()
					local v = tonumber(getOptValue(opt, group, info)) or minVal
					slider:SetValue(v)
					slider:SetEnabled(not isDisabled(opt))
				end
			})

		elseif optType == "execute" then
			local btn
			btn, y = createButton(parent, optLabel, y)
			btn:SetScript("OnClick", function()
				if type(opt.func) == "function" then
					opt.func()
				end
				for _, w in ipairs(widgets) do w.refresh() end
			end)
			table.insert(widgets, { refresh = function() btn:SetEnabled(not isDisabled(opt)) end })

		elseif optType == "color" then
			local btn
			btn, y = createButton(parent, optLabel, y)
			local info = makeInfo(opt)
			btn:SetScript("OnClick", function()
				local r, g, b = getOptValue(opt, group, info)
				r, g, b = tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1

				local function applyColor()
					local cr, cg, cb = ColorPickerFrame:GetColorRGB()
					setOptValue(opt, group, info, cr, cg, cb)
					for _, w in ipairs(widgets) do w.refresh() end
				end

				ColorPickerFrame.hasOpacity = false
				ColorPickerFrame.previousValues = { r, g, b }
				ColorPickerFrame.func = applyColor
				ColorPickerFrame.cancelFunc = function()
					local prev = ColorPickerFrame.previousValues
					if prev then
						setOptValue(opt, group, info, prev[1], prev[2], prev[3])
					end
					for _, w in ipairs(widgets) do w.refresh() end
				end
				ColorPickerFrame:SetColorRGB(r, g, b)
				ColorPickerFrame:Show()
			end)
			table.insert(widgets, { refresh = function() btn:SetEnabled(not isDisabled(opt)) end })
		elseif optType == "keybinding" then
			local btn
			btn, y = createButton(parent, optLabel, y)
			local info = makeInfo(opt)

			local listening = false
			local function stopListening()
				listening = false
				btn:SetScript("OnKeyDown", nil)
			end

			local function currentBinding()
				local v = getOptValue(opt, group, info)
				if v == nil or v == "" then return "" end
				return tostring(v)
			end

			btn:EnableKeyboard(true)
			btn:SetScript("OnClick", function()
				if isDisabled(opt) then return end
				listening = not listening
				if not listening then
					stopListening()
					for _, w in ipairs(widgets) do w.refresh() end
					return
				end
				btn:SetScript("OnKeyDown", function(_, key)
					if key == "ESCAPE" then
						setOptValue(opt, group, info, "")
						stopListening()
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
					setOptValue(opt, group, info, combo)
					stopListening()
					for _, w in ipairs(widgets) do w.refresh() end
				end)
			end)

			table.insert(widgets, {
				refresh = function()
					btn:SetEnabled(not isDisabled(opt))
					local v = currentBinding()
					if v ~= "" then
						btn:SetText(("%s: %s"):format(optLabel, v))
					else
						btn:SetText(("%s: %s"):format(optLabel, BSYC.L.None or "None"))
					end
				end
			})
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
		if optionsTable.name then
			_, y = createTitle(content, resolveText(optionsTable.name) or "", y)
		end
		y = renderOptions(content, optionsTable, panel._widgets, y)
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
