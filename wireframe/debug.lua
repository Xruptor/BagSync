--[[
	debug.lua
		Provides some debugging information to assist in squashing bugs.

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...)
local UI = BSYC:GetModule("UI")
local L = BSYC.L
local Debug = BSYC:NewModule("Debug")

local xListLen = 500
local debugWidth = 880
local debugHeight = 465

local levels = {
	"DEBUG",
	"INFO",
	"TRACE",
	"WARN",
	"FINE",
	"SL1",
	"SL2",
	"SL3",
	"SL4",
	"SL5",
}

-- Color lookup table for debug levels (eliminates 40+ line if-elseif chain)
local levelColors = {
	[BSYC_DL.DEBUG] = "FF4DD827", -- fel green
	[BSYC_DL.INFO] = "FFffff00", -- yellow
	[BSYC_DL.TRACE] = "FF09DBE0", -- teal blue
	[BSYC_DL.WARN] = "FFFF3C38", -- rose red
	[BSYC_DL.FINE] = "FFe454fd", -- dark lavender
	[BSYC_DL.SL1] = "FFCF9FFF", -- light lavender
	[BSYC_DL.SL2] = "FFFFD580", -- light orange
	[BSYC_DL.SL3] = "FFd1d1d1", -- light gray
	[BSYC_DL.SL4] = "FF7FDBFF", -- light sky blue
	[BSYC_DL.SL5] = "FFC8F08F", -- light lime green
}

-- Cache C_AddOns API at module load (Retail 10.0+ vs Classic/Legacy compatibility)
local GetNumAddOns = (C_AddOns and C_AddOns.GetNumAddOns) or _G.GetNumAddOns
local GetAddOnInfo = (C_AddOns and C_AddOns.GetAddOnInfo) or _G.GetAddOnInfo
local IsAddOnLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded
local IsAddOnEnabled = (C_AddOns and C_AddOns.IsAddOnEnabled) or _G.IsAddOnEnabled

local function unescape(str)
	-- Removed redundant local reassignment - operate directly on str parameter
	str = string.gsub(str, "|T.-|t", "") -- textures
	str = string.gsub(str, "|H.-|h(.-)|h", "%1") -- links
	str = string.gsub(str, "{.-}", "") -- raid icons
	return str
end

-- Helper: Get level name from levels table
local function GetLevelName(level)
	return levels[level] or "UNKNOWN"
end

-- Helper: Get color hex code for level
local function GetLevelColor(level)
	return levelColors[level] or "778899" -- slate gray default
end

-- Helper: Check if a debug level is enabled in options
local function IsLevelEnabled(level)
	local levelName = levels[level]
	return levelName and BSYC.options.debug[levelName]
end

-- Helper: Count items in a category (bag, bank, reagents, etc.)
-- Dead code removed: Previously inline with duplicated #v or 0 patterns
local function CountItemsForCategory(k, v)
	if k == "bag" or k == "bank" or k == "reagents" then
		local total = 0
		for _, bagData in pairs(v or {}) do
			total = total + (#bagData or 0)
		end
		return total
	elseif k == "auction" then
		return (v.bag and #v.bag) or 0
	elseif k == "equipbags" then
		return ((v.bag and #v.bag) or 0) + ((v.bank and #v.bank) or 0)
	else
		return #v or 0
	end
end

-- Helper: Process a unit for dump totals
-- Dead code removed: Previously nested deeply in dumpTotals function
local function ProcessUnit(unitObj, totalItems, allowList)
	local count = 0
	for k, v in pairs(unitObj.data) do
		if allowList[k] and type(v) == "table" and k ~= "guild" then
			count = count + CountItemsForCategory(k, v)
		end
	end
	return totalItems + count
end

function Debug:OnEnable()
	local DebugFrame = UI:CreateModuleFrame(Debug, {
		template = "BagSyncFrameTemplate",
		title = "BagSync - "..L.Debug,
		width = debugWidth,
		height = debugHeight,
		point = { "CENTER", UIParent, "CENTER", 0, 150 },
		frameStrata = "BACKGROUND",
		onShow = function() Debug:OnShow() end,
		onHide = function() Debug:OnHide() end,
	})
	DebugFrame:Hide()
	DebugFrame.closeBtn:SetPoint("TOPRIGHT", C_EditMode and -3 or 2, C_EditMode and -3 or 1)
	Debug.frame = DebugFrame

	Debug.scrollFrame = UI:CreateHybridScrollFrame(DebugFrame, {
		width = debugWidth-44,
		pointTopLeft = { "TOPLEFT", DebugFrame, "TOPLEFT", 13, -30 },
		pointBottomLeft = { "BOTTOMLEFT", DebugFrame, "BOTTOMLEFT", -25, 15 },
		buttonTemplate = "BagSyncListSimpleItemTemplate",
		update = function() Debug:RefreshList() end,
		doNotHideScrollBar = true,
	})
	Debug.debugItems = {}

	--Options Frame
	Debug.optionsFrame = UI:CreateFrame(DebugFrame, {
		template = BackdropTemplateMixin and "BackdropTemplate" or nil,
	})
	local optionsFrame = Debug.optionsFrame
	local backdrop = {
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
		tile = true,
		tileSize = 16,
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	}

	optionsFrame:SetHeight(120)
	optionsFrame:SetWidth(debugWidth-3)
	optionsFrame:SetBackdrop(backdrop)
	optionsFrame:SetBackdropColor(0, 0, 0, 0.6)
	optionsFrame:SetPoint("TOPLEFT", DebugFrame, "BOTTOMLEFT", 2, 5)

	local enableDebugChk = UI:CreateCheckButton(optionsFrame, {
		text = L.DebugEnable,
		textColor = { 1, 1, 1 },
		point = { "TOPLEFT", optionsFrame, "TOPLEFT", 10, -5 },
		checked = BSYC.options.debug.enable,
		onClick = function(btn)
			BSYC.options.debug.enable = btn:GetChecked()
		end,
	})
	optionsFrame.enableDebugChk = enableDebugChk

	local disableCacheChk = UI:CreateCheckButton(optionsFrame, {
		text = L.DebugCache,
		textColor = { 1, 1, 1 },
		point = { "LEFT", (enableDebugChk.Text or enableDebugChk.text), "RIGHT", 15, 0 },
		checked = BSYC.options.debug.cache,
		onClick = function(btn)
			BSYC.options.debug.cache = btn:GetChecked()
		end,
	})
	optionsFrame.disableCacheChk = disableCacheChk

	local lastPoint
	optionsFrame.debugLevels = {}

	for k = 1, #levels do
		local tmpLevel = UI:CreateCheckButton(optionsFrame, {
			text = levels[k],
			textColor = { 1, 1, 1 },
			point = {
				(not lastPoint and "BOTTOMLEFT") or "LEFT",
				(not lastPoint and optionsFrame) or lastPoint,
				(not lastPoint and "BOTTOMLEFT") or "RIGHT",
				(not lastPoint and 10) or 15,
				(not lastPoint and 3) or 0,
			},
			checked = BSYC.options.debug[levels[k]],
			onClick = function(btn)
				BSYC.options.debug[btn.level] = btn:GetChecked()
			end,
		})
		tmpLevel.level = levels[k]
		local tmpText = tmpLevel.Text or tmpLevel.text
		lastPoint = tmpText
		table.insert(optionsFrame.debugLevels, tmpLevel)
	end

	--dump options
	local dumpOptions = UI:CreateButton(optionsFrame, {
		template = "UIPanelButtonTemplate",
		text = L.DebugDumpOptions,
		height = 30,
		autoWidth = true,
		point = { "TOPLEFT", optionsFrame, "TOPLEFT", 10, -43 },
		onClick = function()
			Debug:AddMessage(1, "init-DebugDumpOptions")
			for k, v in pairs(BSYC.options) do
				if type(v) ~= "table" then
					Debug:AddMessage(1, "DumpOptions", k, tostring(v))
				else
					for x, y in pairs(v) do
						if type(y) ~= "table" then
							Debug:AddMessage(1, "DumpOptions", k, tostring(x), tostring(y))
						elseif k == "colors" then
							-- Early return for nested table case (colors)
							Debug:AddMessage(1, "DumpOptions", k, tostring(x), y.r * 255, y.g * 255, y.b * 255)
						end
					end
				end
			end
		end,
	})
	optionsFrame.dumpOptions = dumpOptions

	--iterate units
	local iterateUnits = UI:CreateButton(optionsFrame, {
		template = "UIPanelButtonTemplate",
		text = L.DebugIterateUnits,
		height = 30,
		autoWidth = true,
		point = { "LEFT", dumpOptions, "RIGHT", 10, 0 },
		onClick = function()
			local player = BSYC:GetModule("Unit"):GetPlayerInfo(false, true)

			Debug:AddMessage(1, "IterateUnits", "UnitInfo-1", player.name, player.realm)
			Debug:AddMessage(1, "IterateUnits", "UnitInfo-2", player.class, player.race, player.gender, player.faction)
			Debug:AddMessage(1, "IterateUnits", "UnitInfo-3", player.guild, player.guildrealm)
			Debug:AddMessage(1, "IterateUnits", "RealmKey", player.realmKey)
			Debug:AddMessage(1, "IterateUnits", "RealmKey_RWS", player.rwsKey)
			Debug:AddMessage(1, "IterateUnits", "RealmKey_LC", player.lowerKey)

			for unitObj in BSYC:GetModule("Data"):IterateUnits() do
				if not unitObj.isGuild then
					Debug:AddMessage(1, "IterateUnits", "|cFFFFD580player|r",
						unitObj.name,
						unitObj.realm,
						unitObj.isConnectedRealm,
						unitObj.data.guild,
						unitObj.data.guildrealm
					)
					Debug:AddMessage(1, "IterateUnits", "|cFFe454fdPKey|r",
						unitObj.name,
						unitObj.data.realmKey, " | ",
						unitObj.data.rwsKey
					)
				else
					Debug:AddMessage(1, "IterateUnits", "|cFFFFD580guild|r",
						unitObj.name,
						unitObj.realm,
						unitObj.isConnectedRealm,
						unitObj.isXRGuild
					)
					Debug:AddMessage(1, "IterateUnits", "|cFFe454fdGKey|r",
						unitObj.name,
						unitObj.data.realmKey, " | ",
						unitObj.data.rwsKey
					)
				end
				Debug:AddMessage(1, " ") --extra space
			end
		end,
	})
	optionsFrame.iterateUnits = iterateUnits

	--dump totals
	local dumpTotals = UI:CreateButton(optionsFrame, {
		template = "UIPanelButtonTemplate",
		text = L.DebugDBTotals,
		height = 30,
		autoWidth = true,
		point = { "LEFT", iterateUnits, "RIGHT", 10, 0 },
		onClick = function()
			local totalUnits = 0
			local totalGuilds = 0
			local totalRealms = 0
			local biggestRealmName
			local biggestRealmCount = 0
			local totalItems = 0 -- Fixed typo: was 'toatlItems'

			local realmCount = 0
			local lastRealm

			local allowList = {
				bag = 0,
				bank = 0,
				reagents = 0,
				equip = 0,
				mailbox = 0,
				void = 0,
				auction = 0,
				guild = 0,
				equipbags = 0,
			}

			for unitObj in BSYC:GetModule("Data"):IterateUnits(true) do
				if not biggestRealmName then
					biggestRealmName = unitObj.realm
					lastRealm = unitObj.realm
					totalRealms = totalRealms + 1
				end

				--realm statistics
				if unitObj.realm == lastRealm then
					realmCount = realmCount + 1
				else
					if realmCount > biggestRealmCount then
						biggestRealmName = lastRealm
						biggestRealmCount = realmCount
					end
					lastRealm = unitObj.realm
					totalRealms = totalRealms + 1
					realmCount = 1
				end

				if not unitObj.isGuild then
					totalUnits = totalUnits + 1
					totalItems = ProcessUnit(unitObj, totalItems, allowList)
				else
					totalGuilds = totalGuilds + 1
					for _, tabData in pairs(unitObj.data.tabs or {}) do
						totalItems = totalItems + (#tabData or 0)
					end
				end
			end

			Debug:AddMessage(1, "DBTotals", "totalUnits", totalUnits)
			Debug:AddMessage(1, "DBTotals", "totalGuilds", totalGuilds)
			Debug:AddMessage(1, "DBTotals", "totalRealms", totalRealms)
			Debug:AddMessage(1, "DBTotals", "biggestRealmName", biggestRealmName)
			Debug:AddMessage(1, "DBTotals", "biggestRealmCount", biggestRealmCount)
			Debug:AddMessage(1, "DBTotals", "totalItems", totalItems) -- Fixed typo
		end,
	})
	optionsFrame.dumpTotals = dumpTotals

	--addon list
	local addonList = UI:CreateButton(optionsFrame, {
		template = "UIPanelButtonTemplate",
		text = L.DebugAddonList,
		height = 30,
		autoWidth = true,
		point = { "LEFT", dumpTotals, "RIGHT", 10, 0 },
		onClick = function()
			if type(GetNumAddOns) ~= "function" or type(GetAddOnInfo) ~= "function" then
				Debug:AddMessage(1, "AddonList", "GetAddOnInfo/GetNumAddOns unavailable")
				return
			end

			Debug:AddMessage(1, "AddonList", string.format("total=%s", tostring(GetNumAddOns())))

			for i = 1, GetNumAddOns() do
				local name, title, _, loadable, reason, security = GetAddOnInfo(i)
				local enabled = name and IsAddOnEnabled and IsAddOnEnabled(name)
				local loaded = name and IsAddOnLoaded and IsAddOnLoaded(name)
				local displayTitle = title or name

				local line = string.format(
					"%d: %s | %s | enabled=%s | loaded=%s | loadable=%s | reason=%s | security=%s",
					i,
					tostring(name),
					tostring(displayTitle),
					tostring(enabled),
					tostring(loaded),
					tostring(loadable),
					tostring(reason),
					tostring(security)
				)
				Debug:AddMessage(1, "AddonList", line)
			end
		end,
	})
	optionsFrame.addonList = addonList

	--export frame
	local exportFrame = UI:CreateInfoFrame(DebugFrame, {
		title = L.DebugExport,
		width = 850,
		height = 500,
		point = { "CENTER", UIParent, "CENTER", 0, 0 },
		backdropColor = { 0, 0, 0, 0.75 },
		frameStrata = "FULLSCREEN_DIALOG",
	})
	exportFrame:SetMovable(true)
	exportFrame:SetClampedToScreen(true)
	exportFrame:RegisterForDrag("LeftButton")
	exportFrame:SetScript("OnDragStart", function(frame)
		frame:StartMoving()
	end)
	exportFrame:SetScript("OnDragStop", function(frame)
		frame:StopMovingOrSizing()
	end)
	exportFrame.ScrollFrame = UI:CreateScrollFrame(exportFrame, {
		points = {
			{ "TOPLEFT", exportFrame, "TOPLEFT", 8, -30 },
			{ "BOTTOMRIGHT", exportFrame, "BOTTOMRIGHT", -30, 8 },
		},
	})
	exportFrame.EditBox = UI:CreateEditBox(exportFrame.ScrollFrame, {
		font = { "Fonts\\ARIALN.TTF", 14, "" },
		multiLine = true,
		autoFocus = false,
		maxLetters = 0,
		countInvisibleLetters = false,
	})
	exportFrame.EditBox:SetAllPoints()
	exportFrame.EditBox:SetWidth(815)
	exportFrame.ScrollFrame:SetScrollChild(exportFrame.EditBox)
	exportFrame.EditBox:ClearFocus()
	exportFrame.EditBox:EnableMouse(true)
	exportFrame.EditBox:SetTextColor(1, 1, 1)
	exportFrame.ScrollFrame:EnableMouse(false)
	DebugFrame.exportFrame = exportFrame

	--export button
	local exportBtn = UI:CreateButton(optionsFrame, {
		template = "UIPanelButtonTemplate",
		text = L.DebugExport,
		height = 20,
		autoWidth = true,
		point = { "TOPRIGHT", optionsFrame, "TOPRIGHT", -5, -5 },
		onClick = function()
			-- Replaced inefficient string concatenation with table.concat
			local lines = {}
			for i = 1, #Debug.debugItems do
				lines[i] = unescape(Debug.debugItems[i]).."|r"
			end
			exportFrame.EditBox:SetText(table.concat(lines, "\n"))
			exportFrame:Show()
		end,
	})
	optionsFrame.exportBtn = exportBtn

	--clear button
	local clearBtn = UI:CreateButton(optionsFrame, {
		template = "UIPanelButtonTemplate",
		text = L.Clear,
		height = 20,
		autoWidth = true,
		point = { "BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -5, 7 },
		onClick = function()
			Debug.debugItems = {}
			Debug:RefreshList()
		end,
	})
	optionsFrame.clearBtn = clearBtn

	if BSYC.options.debug.enable then
		DebugFrame:Show()
	end
end

function Debug:OnShow()
	Debug:RefreshList()
end

function Debug:OnHide()
	if BSYC.options.debug.enable then
		BSYC:Print(L.DebugWarning)
	end
end

function Debug:RefreshList()
	local buttons = HybridScrollFrame_GetButtons(Debug.scrollFrame)
	if not buttons then return end

	local offset = HybridScrollFrame_GetOffset(Debug.scrollFrame)

	-- Removed unnecessary local 'items' variable - use Debug.debugItems directly
	for buttonIndex = 1, #buttons do
		local button = buttons[buttonIndex]
		UI:AttachListItemHandlers(button, Debug)

		local itemIndex = buttonIndex + offset

		if itemIndex <= #Debug.debugItems then
			local item = Debug.debugItems[itemIndex]

			button:SetID(itemIndex)
			button.Text:SetFont("Fonts\\ARIALN.TTF", 14, "")
			button.Text:SetText(item or "")
			button.Text:SetTextColor(1, 1, 1)
			button:SetWidth(Debug.scrollFrame.scrollChild:GetWidth())
			button:Show()
		else
			button:Hide()
		end
	end

	local buttonHeight = Debug.scrollFrame.buttonHeight
	local totalHeight = #Debug.debugItems * buttonHeight
	local shownHeight = #buttons * buttonHeight

	HybridScrollFrame_Update(Debug.scrollFrame, totalHeight, shownHeight)
end

local function BuildDebugLine(level, sName, message)
	local color = GetLevelColor(level)
	local moduleName = string.format("|c"..color.."[%s]|r: ", sName)
	local core = moduleName..message
	local line = "|cff808080["..date("%X").."]|r|cff91aaff["..GetLevelName(level).."]:|r "..core
	return line, core
end

local function BuildSpamLine(level, sName, message)
	local color = "FFFFD580" -- light orange
	local moduleName = string.format("|c"..color.."[%s]|r: ", "Debug")
	local core = moduleName.."|cFFA86F00[SPAM Protect]|r"
	if sName or message then
		local info = ""
		if sName then
			info = tostring(sName)
		end
		if message and message ~= "" then
			if info ~= "" then
				info = info .. ": " .. message
			else
				info = tostring(message)
			end
		end
		if info ~= "" then
			core = core .. " -> " .. info
		end
	end
	local line = "|cff808080["..date("%X").."]|r|cff91aaff["..GetLevelName(level).."]:|r "..core
	return line
end

function Debug:AddMessage(level, sName, ...)
	if not BSYC.options or not BSYC.options.debug or not BSYC.options.debug.enable then
		return
	end

	-- Replaced 8 if statements with single lookup table check
	if not IsLevelEnabled(level) then
		return
	end

	-- Replaced deprecated string.join with table.concat (modern API)
	local message = table.concat({tostringall(...)}, ", ")
	local spamPreview
	if message ~= "" then
		local a, b = strsplit(",", message, 3)
		if a and b then
			spamPreview = a .. "," .. b
		else
			spamPreview = message
		end
	end
	local debugStr, core = BuildDebugLine(level, sName, message)

	local function IsSpamCore(c)
		return c and c:find("%[SPAM Protect%]")
	end

	-- Cache-based spam protection: suppress lines that appear in the last N messages.
	local spamCache = Debug.__spamCache or { list = {}, set = {} }
	Debug.__spamCache = spamCache

	if not IsSpamCore(core) then
		if spamCache.set[core] then
			if not Debug.__spamProtectActive then
				local spamLine = BuildSpamLine(level)
				if sName or spamPreview then
					spamLine = BuildSpamLine(level, sName, spamPreview)
				end
				if #Debug.debugItems > xListLen then
					table.remove(Debug.debugItems, 1)
				end
				table.insert(Debug.debugItems, spamLine)
				Debug:RefreshList()
				HybridScrollFrame_SetOffset(Debug.scrollFrame, Debug.scrollFrame.range)
				Debug.scrollFrame.scrollBar:SetValue(Debug.scrollFrame.range)
				Debug.__spamProtectActive = true
			end
			return
		end

		-- accept new line and update cache
		Debug.__spamProtectActive = nil
		local list = spamCache.list
		list[#list + 1] = core
		spamCache.set[core] = true
		if #list > 5 then
			local old = table.remove(list, 1)
			if old then spamCache.set[old] = nil end
		end
	end

	-- Remove oldest item if list exceeds limit
	if #Debug.debugItems > xListLen then
		table.remove(Debug.debugItems, 1)
	end

	table.insert(Debug.debugItems, debugStr)
	Debug:RefreshList()

	-- Scroll to bottom
	HybridScrollFrame_SetOffset(Debug.scrollFrame, Debug.scrollFrame.range)
	Debug.scrollFrame.scrollBar:SetValue(Debug.scrollFrame.range)
end
