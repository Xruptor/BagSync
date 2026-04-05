--[[
	data.lua
		Handles all the data elements for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local ADDON_NAME, BSYC = ... --grab the addon namespace
local Data = BSYC:NewModule("Data")
local UI = BSYC:GetModule("UI")
local hasMark = BSYC.hasMark
local Unit = BSYC:GetModule("Unit")
local L = BSYC.L
local EMPTY = {}
local type = type
local tonumber = tonumber
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local strlower = strlower
local time = time
local GetTime = GetTime
local IsInGuild = IsInGuild
local UnitFactionGroup = UnitFactionGroup
local math_min = math.min
local math_max = math.max
local table_insert = table.insert
local string_sub = string.sub

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Data", ...) end
end

--these just reset individual items in the DB
local unitDBVersion = {
	auction = 1,
}

local function HexToRGBPerc(hex)
	if #hex >= 8 then
		hex = string_sub(hex, 3) --start from 3rd character
	end
	local rhex, ghex, bhex = string_sub(hex, 1, 2), string_sub(hex, 3, 4), string_sub(hex, 5, 6)
	return { r = tonumber(rhex, 16)/255, g = tonumber(ghex, 16)/255, b = tonumber(bhex, 16)/255 }
end

local optionsDefaults = {
	showTotal = true,
	enableUnitClass = true,
	enableAddonCompartment = true,
	enableFaction = true,
	tooltipOnlySearch = false,
	enableTooltips = true,
	enableExtTooltip = false,
	enableTooltipSeparator = true,
	enableCR = true,
	enableBNET = false,
	enableTooltipItemID = false,
	enableTooltipGreenCheck = true,
	enableRealmIDTags = true,
	enableRealmAstrickName = false,
	enableRealmShortName = false,
	enableLoginVersionInfo = true,
	enableFactionIcons = false,
	enableShowUniqueItemsTotals = true,
	enableRealmNames = true,
	showGuildInGoldTooltip = true,
	focusSearchEditBox = false,
	enableAccurateBattlePets = true,
	alwaysShowSearchFilters = false,
	tooltipSortMode = "realm_character",
	tooltipModifer = "NONE",
	singleCharLocations = false,
	useIconLocations = true,
	itemTotalsByClassColor = true,
	showRaceIcons = true,
	showGuildTabs = false,
	showWarbandTabs = false,
	showBankTabs = false,
	enableWhitelist = false,
	enableSourceExpansion = true,
	enableItemTypes = true,
	extTT_Font = "Friz Quadrata TT",
	extTT_FontSize = 12,
	extTT_FontOutline = "OUTLINE",
	extTT_FontMonochrome = false,
	extTT_Anchor = "BOTTOM",
	extTT_CustomAnchorEnabled = false,
	extTT_CustomAnchorLocation = "CENTER",
	extTT_CustomAnchorX = 0,
	extTT_CustomAnchorY = 0,
	enable_GSC_Display = false,
	enableCurrentRealmName = false,
	enableCurrentRealmShortName = false,
	enableCurrencyWindowTooltipData = true,
	showCurrentCharacterOnly = false,
	showEquipBagSlots = false,
	showBLCurrentCharacterOnly = false,
	sortCurrencyByExpansion = true,
	showBNETCRInfoWindow = true,
	sortShowCurrentPlayerOnTop = false,
	cacheThrottle = "slow",
}

local colorsDefaults = {
	first = HexToRGBPerc('FF80FF00'),
	second = HexToRGBPerc('FFFFFFFF'),
	total = HexToRGBPerc('FFF4A460'),
	guild = HexToRGBPerc('FF65B8C0'),
	warband = HexToRGBPerc('FFFF3C38'),
	debug = HexToRGBPerc('FF4DD827'),
	cr = HexToRGBPerc('FFFF7D0A'),
	bnet = HexToRGBPerc('FF3588FF'),
	itemid = HexToRGBPerc('FF52D386'),
	guildtabs = HexToRGBPerc('FF09DBE0'),
	warbandtabs = HexToRGBPerc('FF09DBE0'),
	banktabs = HexToRGBPerc('FF09DBE0'),
	expansion = HexToRGBPerc('FFCF9FFF'),
	itemtypes = HexToRGBPerc('ffcccf66'),
	currentrealm = HexToRGBPerc('ff4CBB17'),
	bagslots = HexToRGBPerc('ff44EE77'),
}

local trackingDefaults = {
	bag = true,
	bank = true,
	reagents = true,
	equip = true,
	mailbox = true,
	void = true,
	auction = true,
	guild = true,
	professions = true,
	currency = true,
	warband = true,
}

Data.__cache = {}
Data.__cache.items = {}
Data.__cache.tooltip = {}
Data.__cache.tooltipOrder = {}
Data.__cache.tooltipOrderHead = 1
Data.__cache.tooltipOrderTail = 0
Data.__cache.tooltipCount = 0
Data.__cache.ignore = {}
Data.__cache.pending = Data.__cache.pending or {}
Data.__cache.itemCacheRun = Data.__cache.itemCacheRun or nil
Data.__cache.throttleMode = Data.__cache.throttleMode or "background"
Data.__cache.backgroundThrottle = Data.__cache.backgroundThrottle or nil
Data.__cache.rampIndex = Data.__cache.rampIndex or 1

local ITEMCACHE_ALLOW_LIST = {
	bag = true,
	bank = true,
	reagents = true,
	equip = true,
	mailbox = true,
	void = true,
	auction = true,
	equipbags = true,
}

local ITEMCACHE_ALLOW_KEYS = {}
for key in pairs(ITEMCACHE_ALLOW_LIST) do
	table_insert(ITEMCACHE_ALLOW_KEYS, key)
end

-- Item cache throttle tiers (batch size / tick delay):
-- background: 8 per 0.30s (~27 items/sec) for login idle
-- medium: 30 per 0.15s (~200 items/sec) for search window open
-- full: 60 per 0.10s (~600 items/sec) for active searches
-- Optional ramp idea (every 90s, gentle steps to avoid FPS spikes):
-- 8 per 0.30s (~27/sec) -> 12 per 0.26s (~46/sec) -> 16 per 0.24s (~67/sec) -> 20 per 0.22s (~91/sec)
local ITEMCACHE_THROTTLE = {
	-- batch = items processed per tick
	-- tick = delay between ticks within a pass (seconds)
	-- pass = delay between passes (seconds)
	background = { batch = 8, tick = 0.30, pass = 0.60 },
	medium = { batch = 30, tick = 0.15, pass = 0.30 },
	full = { batch = 60, tick = 0.10, pass = 0.20 },
}

-- Background ramp (safe cap for FPS); advances every 90s while in background mode
local ITEMCACHE_RAMP_INTERVAL = 90
local ITEMCACHE_RAMP_STEPS = {
	{ batch = 8, tick = 0.30, pass = 0.60 }, -- ~27/sec
	{ batch = 12, tick = 0.26, pass = 0.52 }, -- ~46/sec
	{ batch = 16, tick = 0.24, pass = 0.48 }, -- ~67/sec
	{ batch = 20, tick = 0.22, pass = 0.44 }, -- ~91/sec (cap)
}

local CACHE_SPEED_MODES = {
	slow = "background",
	medium = "medium",
	fast = "full",
	disabled = "background",  --this is a fallback, not an actual mapping...
}

local function GetThrottleConfig(mode)
	if mode == "background" and Data.__cache.backgroundThrottle then
		return Data.__cache.backgroundThrottle
	end
	return ITEMCACHE_THROTTLE[mode] or ITEMCACHE_THROTTLE.background
end

local function GetCacheRemaining(run)
	if not run or not run.running then return 0 end
	local remaining = 0
	if run.queue then
		local curRemaining = #run.queue - (run.pos or 1) + 1
		if curRemaining < 0 then curRemaining = 0 end
		remaining = curRemaining + (#run.nextQueue or 0)
	end
	return remaining
end

local function GetOption(key, defaultValue)
	local options = BSYC.options
	if not options then return defaultValue end
	local value = options[key]
	return value == nil and defaultValue or value
end

----------------------
--   DB Functions   --
----------------------

function Data:OnEnable()
	Debug(BSYC_DL.INFO, "OnEnable")

	local API = BSYC.API
	local getMeta = API and API.GetAddOnMetadata
	local addonVersion = tostring((type(getMeta) == "function" and getMeta(ADDON_NAME, "Version")) or "0")

	--get player information from Unit
	local player = Unit:GetPlayerInfo(true)

	Debug(BSYC_DL.DEBUG, "UnitInfo-1", player.name, player.realm)
	Debug(BSYC_DL.DEBUG, "UnitInfo-2", player.class, player.race, player.gender, player.faction)
	Debug(BSYC_DL.DEBUG, "UnitInfo-3", player.guild, player.guildrealm)
	Debug(BSYC_DL.DEBUG, "RealmKey", player.realmKey)
	Debug(BSYC_DL.DEBUG, "RealmKey_RWS", player.rwsKey)
	Debug(BSYC_DL.DEBUG, "RealmKey_LC", player.lowerKey)

	--realm DB
	local realm = player.realm
	BagSyncDB[realm] = BagSyncDB[realm] or {}
	BSYC.db.realm = BagSyncDB[realm]

	--player DB
	local name = player.name
	BSYC.db.realm[name] = BSYC.db.realm[name] or {}

	local playerDB = BSYC.db.realm[name]
	BSYC.db.player = playerDB
	playerDB.currency = playerDB.currency or {}
	playerDB.professions = playerDB.professions or {}

	--options DB
	BSYC:SetDefaults(nil, optionsDefaults)

	--set tracking defaults
	BSYC:SetDefaults("tracking", trackingDefaults)
	BSYC.tracking = BSYC.options.tracking

	--setup the default colors
	BSYC:SetDefaults("colors", colorsDefaults)
	BSYC.colors = BSYC.options.colors

	--create any bagsync fonts
	BSYC:CreateFonts()

	local options = BSYC.options
	if options.addonversion ~= addonVersion then
		self:FixDB()
		options.addonversion = addonVersion
	end

	--player info
	playerDB.money = player.money
	playerDB.local_class_name = player.local_class_name
	playerDB.class = player.class
	playerDB.class_id = player.class_id
	playerDB.local_race_name = player.local_race_name
	playerDB.race = player.race
	playerDB.race_id = player.race_id
	playerDB.gender = player.gender
	playerDB.faction = player.faction
	playerDB.guid = player.guid
	playerDB.realmKey = player.realmKey
	playerDB.rwsKey = player.rwsKey

	--we cannot store guild as on login the guild name returns nil
	--https://wow.gamepedia.com/API_GetGuildInfo

	--if player isn't in a guild, then delete old guild data if found, sometimes this gets left behind for some reason
	if not IsInGuild() and (playerDB.guild or playerDB.guildrealm) then
		playerDB.guild = nil
		playerDB.guildrealm = nil
	end

	--load the slash commands
	self:LoadSlashCommand()

	--show the info window if enabled
	self:ShowInfoWindow()

	if options.enableLoginVersionInfo then
		BSYC:Print(string.format("[v|cFF20ff20%s|r] loaded:   /bgs, /bagsync", addonVersion))
	end
	if options.debug.enable then
		BSYC:Print(L.DebugWarning)
		C_Timer.After(6, function() BSYC:Print(L.DebugWarning) end)
	end
end

function Data:ShowInfoWindow()
	if not BSYC.options.showBNETCRInfoWindow then return end

	local infoWindow = self.__infoWindow
	if infoWindow then
		infoWindow:Show()
		return
	end

	infoWindow = UI:CreateInfoFrame(UIParent, {
		title = "BagSync",
		width = 500,
		height = 500,
		point = { "CENTER", UIParent, "CENTER", 0, 0 },
		backdropColor = { 0, 0, 0, 0.75 },
		frameStrata = "FULLSCREEN_DIALOG",
	})

	infoWindow.infoText1 = UI:CreateFontString(infoWindow, {
		template = "GameFontHighlightSmall",
		text = L.BagSyncInfoWindow.."\n"..L.DisplayBNET,
		font = { STANDARD_TEXT_FONT, 14, "" },
		textColor = { 1, 1, 1 },
		justifyH = "CENTER",
		width = infoWindow:GetWidth() - 30,
		point = { "CENTER", infoWindow, "CENTER", 0, 0 },
	})

	infoWindow.okBTN = UI:CreateButton(infoWindow, {
		template = "UIPanelButtonTemplate",
		text = OKAY,
		width = 100,
		height = 30,
		point = { "RIGHT", infoWindow, "BOTTOMRIGHT", -10, 23 },
		onClick = function()
			BSYC.options.showBNETCRInfoWindow = false
			infoWindow:Hide()
		end,
	})

	infoWindow.CloseButton:Hide()
	infoWindow:Show()
	self.__infoWindow = infoWindow
end

function Data:ResetColors()
	Debug(BSYC_DL.INFO, "ResetColors")
	local options = BSYC.options
	options.colors = nil
	BSYC:SetDefaults("colors", colorsDefaults)
	BSYC.colors = options.colors
end

function Data:FixDB()
	Debug(BSYC_DL.INFO, "FixDB")
	local options = BSYC.options
	local db = BagSyncDB

	--migrate legacy option name
	do
		local legacyKey = "alwaysShowAdvSearch"
		if options[legacyKey] ~= nil then
			options.alwaysShowSearchFilters = options[legacyKey]
			options[legacyKey] = nil
		end
	end

	-- ensure new ext tooltip anchor option is present
	do
		if options.extTT_Anchor == nil then
			options.extTT_Anchor = optionsDefaults.extTT_Anchor
		end
	end

	-- ensure custom ext tooltip anchor options are present
	do
		if options.extTT_CustomAnchorEnabled == nil then
			options.extTT_CustomAnchorEnabled = optionsDefaults.extTT_CustomAnchorEnabled
		end
		local validLocations = {
			TOPLEFT = true, TOPRIGHT = true, BOTTOMLEFT = true, BOTTOMRIGHT = true,
			CENTER = true, CENTER_TOP = true, CENTER_BOTTOM = true, ANCHOR = true
		}
		if not validLocations[options.extTT_CustomAnchorLocation] then
			options.extTT_CustomAnchorLocation = optionsDefaults.extTT_CustomAnchorLocation
		end
		if type(options.extTT_CustomAnchorX) ~= "number" then
			options.extTT_CustomAnchorX = optionsDefaults.extTT_CustomAnchorX
		end
		if type(options.extTT_CustomAnchorY) ~= "number" then
			options.extTT_CustomAnchorY = optionsDefaults.extTT_CustomAnchorY
		end
	end

	-- ensure addon compartment option is present
	do
		if options.enableAddonCompartment == nil then
			options.enableAddonCompartment = optionsDefaults.enableAddonCompartment
		end
	end

	-- ensure minimap db exists and prune flat options
	do
		local minimap = options.minimap
		if type(minimap) ~= "table" then
			minimap = {}
			options.minimap = minimap
		end
		if minimap.hide == nil then
			minimap.hide = false
		end
		if minimap.minimapPos == nil then
			minimap.minimapPos = 220
		end
		options.enableMinimap = nil
		options.minimapPos = nil
	end

	-- ensure cache throttle setting is present
	do
		local validSpeeds = { slow = true, medium = true, fast = true, disabled = true }
		if not validSpeeds[options.cacheThrottle] then
			options.cacheThrottle = optionsDefaults.cacheThrottle
		end
	end

	-- migrate + prune legacy sort toggles into the new sort mode option
	do
		local validModes = {
			realm_character = true,
			character = true,
			class_character = true,
			totals = true,
			custom = true,
		}

		local mode = options.tooltipSortMode
		if not validModes[mode] then
			if options.sortTooltipByTotals then
				mode = "totals"
			elseif options.sortByCustomOrder then
				mode = "custom"
			else
				mode = "realm_character"
			end
			options.tooltipSortMode = mode
		end

		-- legacy flags (no longer used post-config revamp)
		options.sortTooltipByTotals = nil
		options.sortByCustomOrder = nil
		options.showGuildCurrentCharacter = nil
	end

	local storeGuilds = {}
	local guildUnits = {}
	local storedUnitDBVersion = options.unitDBVersion
	if type(storedUnitDBVersion) ~= "table" then
		storedUnitDBVersion = {}
		options.unitDBVersion = storedUnitDBVersion
	end
	local needAuctionReset = storedUnitDBVersion.auction ~= unitDBVersion.auction

	-- gather active guilds, reset stale auction data, and snapshot guild units in a single pass
	for unitObj in self:IterateUnits(true) do
		if unitObj.isGuild then
			guildUnits[#guildUnits + 1] = unitObj
		else
			if unitObj.data.guild and unitObj.data.guildrealm then
				storeGuilds[unitObj.data.guild .. unitObj.data.guildrealm] = true
			end
			if needAuctionReset and unitObj.data.auction then
				unitObj.data.auction = nil
			end
		end
	end

	-- remove obsolete guilds
	for i = 1, #guildUnits do
		local unitObj = guildUnits[i]
		if not storeGuilds[unitObj.name .. unitObj.realm] and db[unitObj.realm] then
			db[unitObj.realm][unitObj.name] = nil
		end
	end

	--check for empty realm tables
	local removeList = {}
	for k, v in pairs(db) do
		--only do checks for realms not on options
		if not hasMark(k, "§") then
			if BSYC:GetHashTableLen(v) == 0 then
				--don't remove tables while iterating, that causes complications, do it afterwards
				table_insert(removeList, k)
			end
		end
	end
	for i=1, #removeList do
		if db[removeList[i]] then db[removeList[i]] = nil end
	end

	if needAuctionReset then
		BSYC:Print("|cFFffff00"..L.UnitDBAuctionReset.."|r")
	end

	--update db unit version information
	local updatedVersion = {}
	for key, value in pairs(unitDBVersion) do
		updatedVersion[key] = value
	end
	options.unitDBVersion = updatedVersion

	BSYC:Print("|cFFFF9900"..L.FixDBComplete.."|r")
end

function Data:LoadSlashCommand()
	Debug(BSYC_DL.INFO, "LoadSlashCommand")

	--load the keybinding locale information
	BINDING_HEADER_BAGSYNC = "BagSync"
	BINDING_NAME_BAGSYNCBLACKLIST = L.KeybindBlacklist
	BINDING_NAME_BAGSYNCWHITELIST = L.KeybindWhitelist
	BINDING_NAME_BAGSYNCCURRENCY = L.KeybindCurrency
	BINDING_NAME_BAGSYNCGOLD = L.KeybindGold
	BINDING_NAME_BAGSYNCPROFESSIONS = L.KeybindProfessions
	BINDING_NAME_BAGSYNCPROFILES = L.KeybindProfiles
	BINDING_NAME_BAGSYNCSEARCH = L.KeybindSearch

	local function ParseChatCommand(input)
		local raw = input or ""
		local cmd, args = raw:match("^%s*(%S*)%s*(.-)%s*$")
		return strlower(cmd or ""), args or "", raw
	end

	local function ShowModuleFrame(name)
		local module = BSYC:GetModule(name, true)
		if module and module.frame and module.frame.Show then
			module.frame:Show()
			return module
		end
	end

	local function ChatCommand(input)
		local cmd, _, raw = ParseChatCommand(input)

		if cmd ~= "" then
			local canCurrency = BSYC:CanDoCurrency() and BSYC.tracking.currency
			local canProfessions = BSYC:CanDoProfessions() and BSYC.tracking.professions

			if cmd == L.SlashSearch then
				ShowModuleFrame("Search")
				return true
			elseif cmd == L.SlashGold or cmd == L.SlashMoney then
				ShowModuleFrame("Gold")
				return true
			elseif cmd == L.SlashCurrency and canCurrency then
				ShowModuleFrame("Currency")
				return true
			elseif cmd == L.SlashProfiles then
				ShowModuleFrame("Profiles")
				return true
			elseif cmd == L.SlashProfessions and canProfessions then
				ShowModuleFrame("Professions")
				return true
			elseif cmd == L.SlashBlacklist then
				ShowModuleFrame("Blacklist")
				return true
			elseif cmd == L.SlashWhitelist then
				ShowModuleFrame("Whitelist")
				return true
			elseif cmd == L.SlashSortOrder then
				ShowModuleFrame("SortOrder")
				return true
			elseif cmd == L.SlashFixDB then
				self:FixDB()
				return true
			elseif cmd == L.SlashResetPOS then
				BSYC:ResetFramePositions()
				return true
			elseif cmd == L.SlashResetDB then
				StaticPopup_Show("BAGSYNC_RESETDATABASE")
				return true
			elseif cmd == L.SlashConfig then
				BSYC:OpenConfig()
				return true
			elseif cmd == L.SlashDebug then
				ShowModuleFrame("Debug")
				return true
			else
				--do an item search, use the full command to search
				local search = ShowModuleFrame("Search")
				if search and search.frame and search.frame.SearchBox then
					search.frame.SearchBox:SetText(raw)
					if search.frame.SearchBox.SearchInfo then
						search.frame.SearchBox.SearchInfo:Hide()
					end
					search:DoSearch()
				end
				return true
			end
		end

		BSYC:Print("/bgs "..L.SlashItemName.." - "..L.HelpSearchItemName)
		BSYC:Print("/bgs "..L.SlashSearch.." - "..L.HelpSearchWindow)
		BSYC:Print("/bgs "..L.SlashGold.." - "..L.HelpGoldTooltip)
		BSYC:Print("/bgs "..L.SlashProfiles.." - "..L.HelpProfilesWindow)
		if BSYC:CanDoProfessions() and BSYC.tracking.professions then
			BSYC:Print("/bgs "..L.SlashProfessions.." - "..L.HelpProfessionsWindow)
		end
		if BSYC:CanDoCurrency() and BSYC.tracking.currency then
			BSYC:Print("/bgs "..L.SlashCurrency.." - "..L.HelpCurrencyWindow)
		end
		BSYC:Print("/bgs "..L.SlashBlacklist.." - "..L.HelpBlacklistWindow)
		BSYC:Print("/bgs "..L.SlashWhitelist.." - "..L.HelpWhitelistWindow)
		BSYC:Print("/bgs "..L.SlashSortOrder.." - "..L.HelpSortOrder)
		BSYC:Print("/bgs "..L.SlashFixDB.." - "..L.HelpFixDB)
		BSYC:Print("/bgs "..L.SlashResetDB.." - "..L.HelpResetDB)
		BSYC:Print("/bgs "..L.SlashConfig.." - "..L.HelpConfigWindow)
		BSYC:Print("/bgs "..L.SlashDebug.." - "..L.HelpDebug)
		BSYC:Print("/bgs "..L.SlashResetPOS.." - "..L.HelpResetPOS)
	end

	--/bgs and /bagsync
	BSYC:RegisterChatCommand("bgs", ChatCommand)
	BSYC:RegisterChatCommand("bagsync", ChatCommand)

end

function Data:RemoveTooltipCacheLink(link)
	if not link then return end
	local cache = Data.__cache.tooltip
	if cache and cache[link] then
		cache[link] = nil
		Data.__cache.tooltipCount = math_max(0, (Data.__cache.tooltipCount or 0) - 1)
	end
end

function Data:ResetTooltipCache()
	local cache = Data.__cache
	cache.tooltip = {}
	cache.tooltipOrder = {}
	cache.tooltipOrderHead = 1
	cache.tooltipOrderTail = 0
	cache.tooltipCount = 0
end

function Data:EnforceTooltipCacheCap()
	local maxEntries = tonumber(BSYC and BSYC.TOOLTIP_CACHE_MAX) or 1000
	if maxEntries <= 0 then return end

	local cache = Data.__cache
	local tooltip = cache.tooltip
	if not tooltip then return end

	local order = cache.tooltipOrder or {}
	local head = cache.tooltipOrderHead or 1
	local tail = cache.tooltipOrderTail or 0
	local count = cache.tooltipCount or 0

	if count <= maxEntries then return end

	while count > maxEntries and head <= tail do
		local key = order[head]
		order[head] = nil
		head = head + 1

		if key and tooltip[key] then
			tooltip[key] = nil
			count = count - 1
		end
	end

	cache.tooltipOrderHead = head
	cache.tooltipCount = count

	-- compact queue if head has advanced far enough (avoid ever-growing arrays)
	if head > 256 and head > (tail / 2) then
		local new = {}
		local newTail = 0
		for i = head, tail do
			local key = order[i]
			if key then
				newTail = newTail + 1
				new[newTail] = key
			end
		end
		cache.tooltipOrder = new
		cache.tooltipOrderHead = 1
		cache.tooltipOrderTail = newTail
	end
end

function Data:SetTooltipCache(link, unitList, grandTotal)
	if not link then return end

	local cache = Data.__cache
	local tooltip = cache.tooltip
	if not tooltip then
		tooltip = {}
		cache.tooltip = tooltip
	end

	local entry = tooltip[link]
	local isNew = entry == nil
	if not entry then
		entry = {}
		tooltip[link] = entry
	end

	entry.unitList = unitList or {}
	entry.grandTotal = grandTotal or 0

	if isNew then
		cache.tooltipCount = (cache.tooltipCount or 0) + 1
		local order = cache.tooltipOrder
		if not order then
			order = {}
			cache.tooltipOrder = order
		end
		local tail = (cache.tooltipOrderTail or 0) + 1
		order[tail] = link
		cache.tooltipOrderTail = tail
		self:EnforceTooltipCacheCap()
	end
end

function Data:CacheLink(parseLink)
	--we want to store and aquire the cached data for the itemID by it's actual number and not a complex string
	if not parseLink then return nil end
	local shortID = tonumber(BSYC:GetShortItemID(parseLink))
	if not shortID then return nil end

	-- fast path
	local itemCache = Data.__cache.items
	local cached = itemCache[shortID]
	if cached then
		return cached
	end

	local speciesID = BSYC:FakeIDToSpeciesID(shortID)
	if speciesID then
		local C_PetJournal = C_PetJournal
		local petInfo = C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID
		if not petInfo then return nil end

		local itemObj = {
			itemQuality = 1,
			itemLink = shortID, --store the FakeID
			speciesID = speciesID,
			parseLink = parseLink,
		}

		--https://wowpedia.fandom.com/wiki/API_(C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID)
		itemObj.speciesName,
		itemObj.speciesIcon,
		itemObj.petType,
		itemObj.companionID,
		itemObj.tooltipSource,
		itemObj.isNotTradable,
		itemObj.isUnique,
		itemObj.ownedByBattleNet,
		itemObj.sourceText,
		itemObj.description,
		itemObj.isWildPet,
		itemObj.canBattle,
		itemObj.tradeSkill
		= petInfo(speciesID)

		--grab some additional information from the species
		local petAbility = C_PetJournal and C_PetJournal.GetPetAbilityList
		if petAbility then
			itemObj.ability1, itemObj.ability2, itemObj.ability3, itemObj.ability4, itemObj.ability5, itemObj.ability6 = petAbility(speciesID)
		end

		-- battle pets bypass itemID logic entirely
		itemObj.itemName = itemObj.speciesName
		-- no itemID for pets

		--lets store our fakeID
		itemCache[shortID] = itemObj
		return itemObj
	end

	--https://warcraft.wiki.gg/wiki/API_C_Item.GetItemInfo
	--Use the addon wrapper for C_Item/GetItemInfo compatibility.
	local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent
	local pending = Data.__cache.pending
	local cItem = C_Item

	-- retail: avoid spamming RequestLoadItemDataByID for the same item repeatedly
	if cItem and cItem.IsItemDataCachedByID and not cItem.IsItemDataCachedByID(shortID) then
		local lastReq = pending[shortID]
		if lastReq and (GetTime() - lastReq) < 1 then
			return nil
		end
	end

	local getItemInfo = BSYC.API and BSYC.API.GetItemInfo
	if not getItemInfo then return nil end
	itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent = getItemInfo(shortID)

	--if we are missing itemName and itemLink then request it (retail async cache)
	if not itemName or not itemLink then
		if cItem and cItem.RequestLoadItemDataByID then
			pending[shortID] = GetTime()
			cItem.RequestLoadItemDataByID(shortID)
		end
	end

	local itemObj = {
		itemName = itemName,
		itemLink = itemLink,
		itemQuality = itemQuality or 1,
		itemLevel = itemLevel,
		itemMinLevel = itemMinLevel,
		itemType = itemType,
		itemSubType = itemSubType,
		itemStackCount = itemStackCount,
		itemEquipLoc = itemEquipLoc,
		itemTexture = itemTexture,
		sellPrice = sellPrice,
		classID = classID,
		subclassID = subclassID,
		bindType = bindType,
		expacID = expacID,
		setID = setID,
		isCraftingReagent = isCraftingReagent,
	}

	--add to Cache if we have something to work with
	if itemObj.itemName and itemObj.itemLink then
		pending[shortID] = nil
		itemCache[shortID] = itemObj
		return itemObj
	end

	return nil
end

function Data:StopBackgroundRamp()
	BSYC:StopTimer("DataCacheRamp")
end

function Data:AdvanceBackgroundRamp()
	if Data:GetCacheThrottle() ~= "background" then return end

	local idx = Data.__cache.rampIndex or 1
	if idx < #ITEMCACHE_RAMP_STEPS then
		idx = idx + 1
		Data.__cache.rampIndex = idx
		Data.__cache.backgroundThrottle = ITEMCACHE_RAMP_STEPS[idx]
		Debug(BSYC_DL.SL2, "CacheThrottle-Ramp", "background", idx, "batch", Data.__cache.backgroundThrottle.batch, "tick", Data.__cache.backgroundThrottle.tick, "pass", Data.__cache.backgroundThrottle.pass)
		Debug(BSYC_DL.SL3, "CacheThrottle-Remaining", GetCacheRemaining(Data.__cache.itemCacheRun))
		Data:SetCacheThrottle("background")
		BSYC:StartTimer("DataCacheRamp", ITEMCACHE_RAMP_INTERVAL, Data, "AdvanceBackgroundRamp")
	end
end

function Data:StartBackgroundRamp()
	Data.__cache.rampIndex = 1
	Data.__cache.backgroundThrottle = ITEMCACHE_RAMP_STEPS[1]
	Debug(BSYC_DL.SL2, "CacheThrottle-Ramp", "background", Data.__cache.rampIndex, "batch", Data.__cache.backgroundThrottle.batch, "tick", Data.__cache.backgroundThrottle.tick, "pass", Data.__cache.backgroundThrottle.pass)
	Debug(BSYC_DL.SL3, "CacheThrottle-Remaining", GetCacheRemaining(Data.__cache.itemCacheRun))
	Data:SetCacheThrottle("background")
	BSYC:StartTimer("DataCacheRamp", ITEMCACHE_RAMP_INTERVAL, Data, "AdvanceBackgroundRamp")
end

function Data:GetCacheSpeedSetting()
	local speed = BSYC.options and BSYC.options.cacheThrottle
	local validSpeeds = { slow = true, medium = true, fast = true, disabled = true }
	return validSpeeds[speed] and speed or "slow"
end

function Data:IsCacheDisabled()
	return Data:GetCacheSpeedSetting() == "disabled"
end

function Data:GetCacheSpeedMode()
	local speed = Data:GetCacheSpeedSetting()
	return CACHE_SPEED_MODES[speed] or "background"
end

function Data:ApplyCacheSpeed()
	local speed = Data:GetCacheSpeedSetting()
	if speed == "disabled" then
		Data:StopBackgroundRamp()
		local run = Data.__cache.itemCacheRun
		if run and run.running then
			run.running = false
			Data.__cache.itemCacheRun = nil
		end
		Data.__cache.throttleMode = "background"
		return
	end

	if speed == "slow" then
		Data:StartBackgroundRamp()
		return
	end

	Data:StopBackgroundRamp()
	Data:SetCacheThrottle(Data:GetCacheSpeedMode())
end

function Data:GetCacheThrottleInfo()
	return {
		throttle = ITEMCACHE_THROTTLE,
		ramp = ITEMCACHE_RAMP_STEPS,
		rampInterval = ITEMCACHE_RAMP_INTERVAL,
	}
end

function Data:SetCacheThrottle(mode)
	local throttleMode = ITEMCACHE_THROTTLE[mode] and mode or "background"
	local cfg = GetThrottleConfig(throttleMode)
	local prevMode = Data.__cache.throttleMode
	local run = Data.__cache.itemCacheRun
	Data.__cache.throttleMode = throttleMode

	if prevMode ~= throttleMode then
		Debug(BSYC_DL.SL2, "CacheThrottle-Mode", prevMode, "->", throttleMode, "batch", cfg.batch, "tick", cfg.tick, "pass", cfg.pass)
		Debug(BSYC_DL.SL3, "CacheThrottle-Remaining", GetCacheRemaining(run))
	end

	if run and run.running then
		run.batchSize = cfg.batch
		run.tickDelay = cfg.tick
		run.passDelay = cfg.pass
		run.mode = Data.__cache.throttleMode
	end

	if throttleMode ~= "background" then
		Data:StopBackgroundRamp()
	end
end

function Data:GetCacheThrottle()
	return Data.__cache.throttleMode or "background"
end

function Data:GetItemCacheStatus()
	local run = Data.__cache.itemCacheRun
	if not run or not run.running then return false, 0, 0, Data:GetCacheThrottle() end

	local remaining = GetCacheRemaining(run)

	return true, remaining, (run.totalQueued or 0), (run.mode or Data:GetCacheThrottle())
end

local ITEMCACHE_MAX_PASSES = 20

function Data:PopulateItemCache(mode)
	if mode == "background" then
		if Data:IsCacheDisabled() then return end
		Data:ApplyCacheSpeed()
	elseif mode then
		Data:SetCacheThrottle(mode)
	end

	local cache = Data.__cache

	-- already running
	if cache.itemCacheRun and cache.itemCacheRun.running then return end
	local ignore = cache.ignore
	local itemCache = cache.items

	local seen = {}
	local queue = {}

	local function pushLink(link)
		if not link or ignore[link] or seen[link] then return end
		seen[link] = true

		local shortID = tonumber(BSYC:GetShortItemID(link))
		if shortID and not itemCache[shortID] then
			queue[#queue + 1] = link
		end
	end

	local function doItem(data)
		for i = 1, #data do
			local entry = data[i]
			if entry then
				local link = BSYC:Split(entry, true)
				pushLink(link)
			end
		end
	end

	local function CacheCheck(unitObj, target)
		local data = unitObj.data
		local bucket = data and data[target]
		if target == "bag" or target == "bank" or target == "reagents" then
			for _, bagData in pairs(bucket or EMPTY) do
				doItem(bagData)
			end
		elseif target == "auction" then
			doItem(bucket and bucket.bag or EMPTY)
		elseif target == "equipbags" then
			if bucket then
				doItem(bucket.bag or EMPTY)
				doItem(bucket.bank or EMPTY)
			end
		elseif target == "equip" or target == "void" or target == "mailbox" then
			doItem(bucket or EMPTY)
		end

		if target == "guild" then
			for _, tabData in pairs(data and data.tabs or EMPTY) do
				doItem(tabData)
			end
		end
	end

	for unitObj in Data:IterateUnits(true) do
		if not unitObj.isGuild then
			for i = 1, #ITEMCACHE_ALLOW_KEYS do
				CacheCheck(unitObj, ITEMCACHE_ALLOW_KEYS[i])
			end
		else
			CacheCheck(unitObj, "guild")
		end
	end

	if #queue < 1 then return end

	local throttle = GetThrottleConfig(Data:GetCacheThrottle())

	cache.itemCacheRun = {
		running = true,
		pass = 0,
		pos = 1,
		queue = queue,
		nextQueue = {},
		cachedThisPass = 0,
		totalThisPass = 0,
		totalQueued = #queue,
		noProgress = 0,
		lastRemaining = nil,
		batchSize = throttle.batch,
		tickDelay = throttle.tick,
		passDelay = throttle.pass,
		mode = Data:GetCacheThrottle(),
	}

	BSYC:StartTimer("DataDumpCache", cache.itemCacheRun.tickDelay, Data, "ProcessItemCacheRun")
end

function Data:ProcessItemCacheRun()
	local run = Data.__cache.itemCacheRun
	if not run or not run.running then return end

	local startPos = run.pos
	local batchSize = run.batchSize or 10
	local queue = run.queue
	local queueSize = #queue
	local endPos = math_min(queueSize, startPos + batchSize - 1)
	local ignore = Data.__cache.ignore
	local nextQueue = run.nextQueue
	local totalThisPass = run.totalThisPass
	local cachedThisPass = run.cachedThisPass

	for i = startPos, endPos do
		local link = queue[i]
		if link and not ignore[link] then
			totalThisPass = totalThisPass + 1
			local cacheObj = Data:CacheLink(link)
			if cacheObj then
				cachedThisPass = cachedThisPass + 1
			else
				nextQueue[#nextQueue + 1] = link
			end
		end
	end

	run.totalThisPass = totalThisPass
	run.cachedThisPass = cachedThisPass
	run.pos = endPos + 1

	-- still more work in this pass
	if run.pos <= queueSize then
		BSYC:StartTimer("DataDumpCache", run.tickDelay or 0.1, Data, "ProcessItemCacheRun")
		return
	end

	-- end of pass
	if #nextQueue < 1 then
		Debug(BSYC_DL.INFO, "PopulateItemCache-Done", run.totalThisPass, run.pass)
		run.running = false
		Data.__cache.itemCacheRun = nil
		return
	end

	-- progress / ignore heuristics (preserves existing behavior, but scoped per pass)
	local remaining = #nextQueue
	if run.lastRemaining ~= nil and run.lastRemaining == remaining and run.cachedThisPass == 0 then
		run.noProgress = run.noProgress + 1
	else
		run.noProgress = 0
	end
	run.lastRemaining = remaining

	if run.noProgress > 4 then
		for i = 1, #nextQueue do
			ignore[nextQueue[i]] = true
			Debug(BSYC_DL.WARN, "DataDumpCache-Ignore", nextQueue[i])
		end
		run.running = false
		Data.__cache.itemCacheRun = nil
		return
	end

	run.pass = run.pass + 1
	if run.pass >= ITEMCACHE_MAX_PASSES then
		Debug(BSYC_DL.INFO, "PopulateItemCache-Stop", remaining, run.pass)
		run.running = false
		Data.__cache.itemCacheRun = nil
		return
	end

	Debug(BSYC_DL.INFO, "PopulateItemCache", remaining, run.pass, run.cachedThisPass, run.totalThisPass)

	-- next pass
	run.queue = nextQueue
	run.nextQueue = {}
	run.pos = 1
	run.cachedThisPass = 0
	run.totalThisPass = 0

	BSYC:StartTimer("DataDumpCache", run.passDelay or 0.2, Data, "ProcessItemCacheRun")
end

function Data:CheckExpiredAuctions()
	Debug(BSYC_DL.INFO, "CheckExpiredAuctions", BSYC.tracking.auction)
	if not BSYC.tracking.auction then return end
	local now = time()

	for unitObj in self:IterateUnits(true) do
		if not unitObj.isGuild and unitObj.data.auction and unitObj.data.auction.count then
			local auction = unitObj.data.auction
			local bag = auction.bag or EMPTY
			local slotItems = {}
			local slotCount = 0

			for x = 1, auction.count do
				local entry = bag[x]
				if entry then
					local link, _, qOpts = BSYC:Split(entry)
					local timeleft = qOpts and qOpts.auction
					local expires = timeleft and tonumber(timeleft)

					--if the timeleft is greater than current time than keep it, it's not expired
					if link and expires and expires > now then
						slotCount = slotCount + 1
						slotItems[slotCount] = entry
					end
				end
			end

			auction.bag = slotItems
			auction.count = slotCount
		end
	end
end

function Data:CheckGuildDB()
	if not IsInGuild() then return end
	local unit = Unit:GetPlayerInfo(true)
	Debug(BSYC_DL.INFO, "CheckGuildDB", unit.name, unit.realm, unit.guild, unit.guildrealm, unit.realmKey)

	if not unit.guild or not unit.guildrealm then return end
	if not BagSyncDB[unit.guildrealm] then BagSyncDB[unit.guildrealm] = {} end
	if not BagSyncDB[unit.guildrealm][unit.guild] then BagSyncDB[unit.guildrealm][unit.guild] = {} end
	return BagSyncDB[unit.guildrealm][unit.guild]
end

function Data:CheckWarbandBankDB()
	if not BagSyncDB["warband§"] then BagSyncDB["warband§"] = {} end
	return BagSyncDB["warband§"]
end

function Data:GetPlayerObj(player)
	if not player then player = Unit:GetPlayerInfo(true) end
	local isConnectedRealm = Unit:CheckConnectedRealm(player.realm)
	Debug(BSYC_DL.TRACE, "GetPlayerObj", player.name, player.realm, isConnectedRealm)
	return {
		realm = player.realm,
		name = player.name,
		data = BSYC.db.player,
		isGuild = false,
		isConnectedRealm = isConnectedRealm,
		isXRGuild = false
	}
end

function Data:GetPlayerGuildObj(player)
	if not player then player = Unit:GetPlayerInfo(true) end
	if not player.guild then return end
	if not BSYC.tracking.guild then return end
	Debug(BSYC_DL.TRACE, "GetPlayerGuild", player.guild, BSYC.tracking.guild)

	local isConnectedRealm = Unit:CheckConnectedRealm(player.guildrealm)
	local isXRGuild = false

	local enableCR = GetOption("enableCR", optionsDefaults.enableCR)
	local enableBNET = GetOption("enableBNET", optionsDefaults.enableBNET)

	if not enableCR and not enableBNET then
		isXRGuild = not Unit:CompareRealms(player.guildrealm, player.realm) or false
	end

	if not BagSyncDB[player.guildrealm] then return end
	if not BagSyncDB[player.guildrealm][player.guild] then return end
	if BSYC.db.blacklist[player.guild..player.guildrealm] then return end

	return {
		realm = player.guildrealm,
		name = player.guild,
		data = BagSyncDB[player.guildrealm][player.guild],
		isGuild = true,
		isConnectedRealm = isConnectedRealm,
		isXRGuild = isXRGuild
	}
end

function Data:GetPlayerCurrencyObj(player, realm, GUID)
	if not player or not realm then return end
	if not BSYC.tracking.currency then return end
	Debug(BSYC_DL.TRACE, "GetPlayerCurrencyObj", player, realm)

	if BagSyncDB[realm] and BagSyncDB[realm][player] then
		return BagSyncDB[realm][player].currency
	end
	if GUID then
		--lets check for GUID
		for unitObj in self:IterateUnits(true) do
			--don't do guilds
			if not unitObj.isGuild then
				--check for GUID
				if unitObj.data.currency and unitObj.data.guid and unitObj.data.guid == GUID then
					return unitObj.data.currency
				end
			end
		end
	end
end

function Data:GetWarbandBankObj()
	if not BSYC.tracking.warband then return end
	if not BagSyncDB["warband§"] then return end
	Debug(BSYC_DL.TRACE, "GetWarbandBankObj")

	return {
		realm = L.Tooltip_warband,
		name = L.Tooltip_warband,
		data = BagSyncDB["warband§"],
		isWarbandBank = true,
	}
end

-- -------------------------------------------------------
-- IterateUnits helpers
-- -------------------------------------------------------

local function GetUnitFilterOptions()
	local options = BSYC.options
	local tracking = BSYC.tracking or (options and options.tracking) or {}
	return {
		enableBNET = GetOption("enableBNET", optionsDefaults.enableBNET),
		enableCR = GetOption("enableCR", optionsDefaults.enableCR),
		enableFaction = GetOption("enableFaction", optionsDefaults.enableFaction),
		trackingGuild = tracking.guild ~= false,
		blacklist = BSYC.db and BSYC.db.blacklist,
	}
end

local function ShouldIncludeRealm(realmKey, meta, dumpAll, filterList, opts)
	if hasMark(realmKey, "§") then
		return false
	end

	if dumpAll then return true end
	if filterList and filterList[realmKey] then return true end
	if meta.isCurrent then return true end
	if opts.enableBNET then return true end
	if opts.enableCR and meta.isConnected then return true end
	if meta.isXRGuild then return true end

	return false
end

local function ShouldIncludeUnit(realmKey, unitKey, unitData, meta, dumpAll, filterList, currentFaction, opts)
	local isGuild = hasMark(unitKey, "©")
	local hasSystemMark = hasMark(unitKey, "§")
	local hasAnyMark = isGuild or hasSystemMark

	if dumpAll then
		return true
	end
	if filterList then
		local realmFilter = filterList[realmKey]
		if realmFilter and type(realmFilter) == "table" and not realmFilter[unitKey] then
			return false
		end
		return true
	end

	local blacklist = opts.blacklist

	-- blacklist (guilds)
	if isGuild and blacklist and blacklist[unitKey .. realmKey] then
		return false
	end

	-- XR-guild realm: only show guild entries
	if meta.isXRGuild and not isGuild then
		return false
	end

	-- faction filtering (characters only)
	local enableFaction = opts.enableFaction
	if not isGuild and not hasAnyMark and not enableFaction then
		if currentFaction and unitData.faction and unitData.faction ~= currentFaction then
			return false
		end
	end

	-- guild toggle
	if isGuild and not opts.trackingGuild then
		return false
	end

	-- blacklist (characters only)
	if not isGuild and blacklist and blacklist[unitKey] then
		return false
	end


	return true
end

function Data:IterateUnits(dumpAll, filterList)
	local opts = GetUnitFilterOptions()
	local currentFaction
	if not opts.enableFaction then
		currentFaction = (BSYC.db and BSYC.db.player and BSYC.db.player.faction) or UnitFactionGroup("player")
	end
	local db = BagSyncDB
	local currentRealm = BSYC.realm
	local wantXRGuild = (not dumpAll and not filterList and opts.trackingGuild and not opts.enableCR and not opts.enableBNET)
	local player
	local playerGuildRealm
	local playerRealm

	if wantXRGuild then
		player = Unit:GetPlayerInfo(true)
		if player and player.guild and player.guildrealm and player.realm then
			playerGuildRealm = player.guildrealm
			playerRealm = player.realm
		else
			wantXRGuild = false
		end
	end

	-- snapshot realm keys (FixDB-safe)
	local realmKeys = {}
	for realmKey in pairs(db) do
		realmKeys[#realmKeys + 1] = realmKey
	end

	-- precompute realm metadata once
	local realmMeta = {}
	for _, realmKey in ipairs(realmKeys) do
		if not hasMark(realmKey, "§") then
			local isConnected = Unit:CheckConnectedRealm(realmKey)
			local isXRGuild = false
			if wantXRGuild and isConnected and playerGuildRealm and Unit:CompareRealms(realmKey, playerGuildRealm) then
				-- XR-guild passthrough: when CR/BNET are off, only the player's connected guild realm is allowed
				isXRGuild = not Unit:CompareRealms(realmKey, playerRealm)  --make sure the realm is NOT our players realm
			end
			realmMeta[realmKey] = {
				isConnected = isConnected,
				isCurrent   = (realmKey == currentRealm),
				isXRGuild   = isXRGuild,
			}
		end
	end

	local realmIndex = 0
	local unitKeys
	local unitIndex
	local realmKey
	local currentRealmData

	return function()
		while true do
			-- advance realm
			if not unitKeys then
				realmIndex = realmIndex + 1
				realmKey = realmKeys[realmIndex]
				if not realmKey then
					return
				end

				currentRealmData = db[realmKey]
				local meta = realmMeta[realmKey]

				if currentRealmData and meta and ShouldIncludeRealm(realmKey, meta, dumpAll, filterList, opts) then
					-- snapshot unit keys for this realm
					unitKeys = {}
					for unitKey in pairs(currentRealmData) do
						unitKeys[#unitKeys + 1] = unitKey
					end
					unitIndex = 0
				else
					unitKeys = nil
				end
			end

			-- advance unit
			if unitKeys then
				unitIndex = unitIndex + 1
				local unitKey = unitKeys[unitIndex]
				if unitKey then
					local unitData = currentRealmData[unitKey]
					local meta = realmMeta[realmKey]

					if unitData and ShouldIncludeUnit(realmKey, unitKey, unitData, meta, dumpAll, filterList, currentFaction, opts) then
						local isGuild = hasMark(unitKey, "©")
						local isXRGuild = meta.isXRGuild and isGuild

						return {
							realm = realmKey,
							name = unitKey,
							data = unitData,
							isGuild = isGuild,
							isConnectedRealm = meta.isConnected,
							isXRGuild = isXRGuild,
						}
					end
				else
					unitKeys = nil
				end
			end
		end
	end
end
