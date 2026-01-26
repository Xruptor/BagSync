--[[
	data.lua
		Handles all the data elements for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Data = BSYC:NewModule("Data")
local hasMark = BSYC.hasMark
local Unit = BSYC:GetModule("Unit")
local L = BSYC.L

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Data", ...) end
end

--these just reset individual items in the DB
local unitDBVersion = {
	auction = 1,
}

local function HexToRGBPerc(hex)
	if string.len(hex) >= 8 then
		hex = hex:sub(3) --start from 3rd character
	end
	local rhex, ghex, bhex = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6)
	return { r = tonumber(rhex, 16)/255, g = tonumber(ghex, 16)/255, b = tonumber(bhex, 16)/255 }
end

local optionsDefaults = {
	showTotal = true,
	enableUnitClass = true,
	enableMinimap = true,
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
	showGuildCurrentCharacter = false,
	focusSearchEditBox = false,
	enableAccurateBattlePets = true,
	alwaysShowAdvSearch = false,
	sortTooltipByTotals = false,
	sortByCustomOrder = false,
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
Data.__cache.ignore = {}
Data.__cache.pending = Data.__cache.pending or {}
Data.__cache.itemCacheRun = Data.__cache.itemCacheRun or nil

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

----------------------
--   DB Functions   --
----------------------

function Data:OnEnable()
	Debug(BSYC_DL.INFO, "OnEnable")
	local ver = C_AddOns.GetAddOnMetadata("BagSync","Version") or 0

	--get player information from Unit
	local player = Unit:GetPlayerInfo(true)

	Debug(BSYC_DL.DEBUG, "UnitInfo-1", player.name, player.realm)
	Debug(BSYC_DL.DEBUG, "UnitInfo-2", player.class, player.race, player.gender, player.faction)
	Debug(BSYC_DL.DEBUG, "UnitInfo-3", player.guild, player.guildrealm)
	Debug(BSYC_DL.DEBUG, "RealmKey", player.realmKey)
	Debug(BSYC_DL.DEBUG, "RealmKey_RWS", player.rwsKey)
	Debug(BSYC_DL.DEBUG, "RealmKey_LC", player.lowerKey)

	--realm DB
	BagSyncDB[player.realm] = BagSyncDB[player.realm] or {}
	BSYC.db.realm = BagSyncDB[player.realm]

	--player DB
	BSYC.db.realm[player.name] = BSYC.db.realm[player.name] or {}
	BSYC.db.player = BSYC.db.realm[player.name]
	BSYC.db.player.currency = BSYC.db.player.currency or {}
	BSYC.db.player.professions = BSYC.db.player.professions or {}

	--options DB
	BSYC:SetDefaults(nil, optionsDefaults)

	-- migrate legacy sort toggles into the new sort mode option
	if not BSYC.options.tooltipSortMode or BSYC.options.tooltipSortMode == "realm_character" then
		if BSYC.options.sortTooltipByTotals then
			BSYC.options.tooltipSortMode = "totals"
		elseif BSYC.options.sortByCustomOrder then
			BSYC.options.tooltipSortMode = "custom"
		else
			BSYC.options.tooltipSortMode = "realm_character"
		end
	end

	--set tracking defaults
	BSYC:SetDefaults("tracking", trackingDefaults)
	BSYC.tracking = BSYC.options.tracking

	--setup the default colors
	BSYC:SetDefaults("colors", colorsDefaults)
	BSYC.colors = BSYC.options.colors

	--create any bagsync fonts
	BSYC:CreateFonts()

	--do DB cleanup check by version number
	if not BSYC.options.addonversion or BSYC.options.addonversion ~= ver then
		self:FixDB()
		BSYC.options.addonversion = ver
	end

	--player info
	BSYC.db.player.money = player.money
	BSYC.db.player.class = player.class
	BSYC.db.player.race = player.race
	BSYC.db.player.gender = player.gender
	BSYC.db.player.faction = player.faction
	BSYC.db.player.guid = player.guid
	BSYC.db.player.realmKey = player.realmKey
	BSYC.db.player.rwsKey = player.rwsKey

	--we cannot store guild as on login the guild name returns nil
	--https://wow.gamepedia.com/API_GetGuildInfo

	--if player isn't in a guild, then delete old guild data if found, sometimes this gets left behind for some reason
	if not IsInGuild() and (BSYC.db.player.guild or BSYC.db.player.guildrealm) then
		BSYC.db.player.guild = nil
		BSYC.db.player.guildrealm = nil
	end

	--load the slash commands
	self:LoadSlashCommand()

	--show the info window if enabled
	self:ShowInfoWindow()

	if BSYC.options.enableLoginVersionInfo then
		BSYC:Print("[v|cFF20ff20"..ver.."|r] /bgs, /bagsync")
	end
	if BSYC.options.debug.enable then
		BSYC:Print(L.DebugWarning)
		if C_Timer and C_Timer.After then
			C_Timer.After(6, function() BSYC:Print(L.DebugWarning) end)
		end
	end
end

function Data:ShowInfoWindow()
	if BSYC.options.showBNETCRInfoWindow == false then return end

	local bgsInfoWindow = _G.CreateFrame("Frame", nil, UIParent, "BagSyncInfoFrameTemplate")
	bgsInfoWindow:SetHeight(500)
	bgsInfoWindow:SetWidth(500)
	bgsInfoWindow:SetBackdropColor(0, 0, 0, 0.75)
	bgsInfoWindow:EnableMouse(true) --don't allow clickthrough
	bgsInfoWindow:SetMovable(false)
	bgsInfoWindow:SetResizable(false)
	bgsInfoWindow:SetFrameStrata("FULLSCREEN_DIALOG")
	bgsInfoWindow:ClearAllPoints()
	bgsInfoWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	bgsInfoWindow.TitleText:SetText("BagSync")
	bgsInfoWindow.TitleText:SetFont(STANDARD_TEXT_FONT, 14, "")
	bgsInfoWindow.TitleText:SetTextColor(1, 1, 1)
	bgsInfoWindow.infoText1 = bgsInfoWindow:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	bgsInfoWindow.infoText1:SetText(L.BagSyncInfoWindow.."\n"..L.DisplayBNET)
	bgsInfoWindow.infoText1:SetFont(STANDARD_TEXT_FONT, 14, "")
	bgsInfoWindow.infoText1:SetTextColor(1, 1, 1)
	bgsInfoWindow.infoText1:SetJustifyH("CENTER")
	bgsInfoWindow.infoText1:SetWidth(bgsInfoWindow:GetWidth() - 30)
	bgsInfoWindow.infoText1:SetPoint("CENTER", bgsInfoWindow, "CENTER", 0, 0)
	bgsInfoWindow.okBTN = _G.CreateFrame("Button", nil, bgsInfoWindow, "UIPanelButtonTemplate")
	bgsInfoWindow.okBTN:SetText(OKAY)
	bgsInfoWindow.okBTN:SetWidth(100)
	bgsInfoWindow.okBTN:SetHeight(30)
	bgsInfoWindow.okBTN:SetPoint("RIGHT", bgsInfoWindow, "BOTTOMRIGHT", -10, 23)
	bgsInfoWindow.okBTN:SetScript("OnClick", function() BSYC.options.showBNETCRInfoWindow = false; bgsInfoWindow:Hide()  end)

	bgsInfoWindow.CloseButton:Hide()
	bgsInfoWindow:Show()
end

function Data:ResetColors()
	Debug(BSYC_DL.INFO, "ResetColors")
	BSYC.colors = nil
	BSYC:SetDefaults("colors", colorsDefaults)
	BSYC.colors = BSYC.options.colors
end

function Data:FixDB()
	Debug(BSYC_DL.INFO, "FixDB")

    local storeGuilds = {}
	if not BSYC.options.unitDBVersion then BSYC.options.unitDBVersion = {} end

	--first grab all active guilds
	for unitObj in self:IterateUnits(true) do
		if not unitObj.isGuild then
			--store only user guild names
			if unitObj.data.guild and unitObj.data.guildrealm then
				storeGuilds[unitObj.data.guild..unitObj.data.guildrealm] = true
			end
		end
	end

	--now do the cleanup and remove old obsolete guilds
	for unitObj in self:IterateUnits(true) do
		if not unitObj.isGuild then
			--users lets do a individual db cleanup if necessary
			if BSYC.options.unitDBVersion.auction ~= unitDBVersion.auction and unitObj.data.auction then
				unitObj.data.auction = nil
			end
		else
			if not storeGuilds[unitObj.name..unitObj.realm] then
				--remove obsolete guild
				BagSyncDB[unitObj.realm][unitObj.name] = nil
			end
		end
	end

	--check for empty realm tables
	local removeList = {}
	for k, v in pairs(BagSyncDB) do
		--only do checks for realms not on options
		if not hasMark(k, "§") then
			if BSYC:GetHashTableLen(v) == 0 then
				--don't remove tables while iterating, that causes complications, do it afterwards
				table.insert(removeList, k)
			end
		end
	end
	for i=1, #removeList do
		if BagSyncDB[removeList[i]] then BagSyncDB[removeList[i]] = nil end
	end

	if BSYC.options.unitDBVersion.auction ~= unitDBVersion.auction then
		BSYC:Print("|cFFffff00"..L.UnitDBAuctionReset.."|r")
	end

	--update db unit version information
	BSYC.options.unitDBVersion = unitDBVersion

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

	local function ChatCommand(input)

		local parts = { (" "):split(input) }
		local cmd, args = strlower(parts[1] or ""), table.concat(parts, " ", 2)

		if string.len(cmd) > 0 then

			if cmd == L.SlashSearch then
				BSYC:GetModule("Search").frame:Show()
				return true
			elseif cmd == L.SlashGold or cmd == L.SlashMoney then
				BSYC:GetModule("Gold").frame:Show()
				return true
			elseif cmd == L.SlashCurrency and BSYC:CanDoCurrency() and BSYC.tracking.currency then
				BSYC:GetModule("Currency").frame:Show()
				return true
			elseif cmd == L.SlashProfiles then
				BSYC:GetModule("Profiles").frame:Show()
				return true
			elseif cmd == L.SlashProfessions and BSYC:CanDoProfessions() and BSYC.tracking.professions then
				BSYC:GetModule("Professions").frame:Show()
				return true
			elseif cmd == L.SlashBlacklist then
				BSYC:GetModule("Blacklist").frame:Show()
				return true
			elseif cmd == L.SlashWhitelist then
				BSYC:GetModule("Whitelist").frame:Show()
				return true
			elseif cmd == L.SlashSortOrder then
				BSYC:GetModule("SortOrder").frame:Show()
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
				BSYC:GetModule("Debug").frame:Show()
				return true
			else
				--do an item search, use the full command to search
				BSYC:GetModule("Search").frame:Show()
				BSYC:GetModule("Search").frame.SearchBox:SetText(input)
				BSYC:GetModule("Search").frame.SearchBox.SearchInfo:Hide()
				BSYC:GetModule("Search"):DoSearch()
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
	if Data.__cache.tooltip[link] then
		Data.__cache.tooltip[link] = nil
	end
end

function Data:CacheLink(parseLink)
	--we want to store and aquire the cached data for the itemID by it's actual number and not a complex string
	if not parseLink then return nil end
	local origLink = parseLink

	local shortID = tonumber(BSYC:GetShortItemID(parseLink))
	if not shortID then return nil end

	-- fast path
	if Data.__cache.items[shortID] then
		return Data.__cache.items[shortID]
	end

	local itemObj = {}
	local speciesID = BSYC:FakeIDToSpeciesID(shortID)

	if not Data.__cache.items[shortID] then
		if speciesID then
			itemObj.itemQuality = 1
			itemObj.itemLink = shortID --store the FakeID
			itemObj.speciesID = speciesID
			itemObj.parseLink = origLink

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
			= (C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID)(speciesID)

			--grab some additional information from the species
			if C_PetJournal and C_PetJournal.GetPetAbilityList then
				itemObj.ability1, itemObj.ability2, itemObj.ability3, itemObj.ability4, itemObj.ability5, itemObj.ability6 = C_PetJournal.GetPetAbilityList(speciesID)
			end

			-- battle pets bypass itemID logic entirely
			itemObj.itemName = itemObj.speciesName
			-- no itemID for pets

			--lets store our fakeID
			Data.__cache.items[shortID] = itemObj
			return itemObj
		else

			--https://wowpedia.fandom.com/wiki/API_C_Item.GetItemInfo
			--NOTE: C_Item.GetItemInfo doesn't exist on classic, so fallback
			local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent

			-- retail: avoid spamming RequestLoadItemDataByID for the same item repeatedly
			if C_Item and C_Item.IsItemDataCachedByID and not C_Item.IsItemDataCachedByID(shortID) then
				local lastReq = Data.__cache.pending[shortID]
				if lastReq and (GetTime() - lastReq) < 1 then
					return nil
				end
			end

			if C_Item and C_Item.GetItemInfo then
				itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent = C_Item.GetItemInfo(shortID)
			else
				itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID = GetItemInfo(shortID)
			end

			--if we are missing itemName and itemLink then request it (retail async cache)
			if not itemName or not itemLink then
				if C_Item and C_Item.RequestLoadItemDataByID then
					Data.__cache.pending[shortID] = GetTime()
					C_Item.RequestLoadItemDataByID(shortID)
				end
			end

			itemObj.itemName = itemName
			itemObj.itemLink = itemLink
			itemObj.itemQuality = itemQuality or 1
			itemObj.itemLevel = itemLevel
			itemObj.itemMinLevel = itemMinLevel
			itemObj.itemType = itemType
			itemObj.itemSubType = itemSubType
			itemObj.itemStackCount = itemStackCount
			itemObj.itemEquipLoc = itemEquipLoc
			itemObj.itemTexture = itemTexture
			itemObj.sellPrice = sellPrice
			itemObj.classID = classID
			itemObj.subclassID = subclassID
			itemObj.bindType = bindType
			itemObj.expacID = expacID
			itemObj.setID = setID
			itemObj.isCraftingReagent = isCraftingReagent

			--add to Cache if we have something to work with
			if itemObj.itemName and itemObj.itemLink then
				Data.__cache.pending[shortID] = nil
				Data.__cache.items[shortID] = itemObj
				return itemObj
			end
		end
	else
		return Data.__cache.items[shortID]
	end
	return nil
end

local ITEMCACHE_BATCH_SIZE = 200
local ITEMCACHE_MAX_PASSES = 20

function Data:PopulateItemCache()
	-- already running
	if Data.__cache.itemCacheRun and Data.__cache.itemCacheRun.running then return end

	local seen = {}
	local queue = {}

	local function pushLink(link)
		if not link or Data.__cache.ignore[link] or seen[link] then return end
		seen[link] = true

		local shortID = tonumber(BSYC:GetShortItemID(link))
		if shortID and not Data.__cache.items[shortID] then
			queue[#queue + 1] = link
		end
	end

	local function doItem(data)
		for i = 1, #data do
			if data[i] then
				local link = BSYC:Split(data[i], true)
				pushLink(link)
			end
		end
	end

	local function CacheCheck(unitObj, target)
		if unitObj.data[target] then
			if target == "bag" or target == "bank" or target == "reagents" then
				for _, bagData in pairs(unitObj.data[target] or {}) do
					doItem(bagData)
				end
			elseif target == "auction" then
				doItem(unitObj.data[target].bag or {})
			elseif target == "equipbags" then
				doItem(unitObj.data[target].bag or {})
				doItem(unitObj.data[target].bank or {})
			elseif target == "equip" or target == "void" or target == "mailbox" then
				doItem(unitObj.data[target] or {})
			end
		end

		if target == "guild" then
			for _, tabData in pairs(unitObj.data.tabs or {}) do
				doItem(tabData)
			end
		end
	end

	for unitObj in Data:IterateUnits(true) do
		if not unitObj.isGuild then
			for k in pairs(ITEMCACHE_ALLOW_LIST) do
				CacheCheck(unitObj, k)
			end
		else
			CacheCheck(unitObj, "guild")
		end
	end

	if #queue < 1 then return end

	Data.__cache.itemCacheRun = {
		running = true,
		pass = 0,
		pos = 1,
		queue = queue,
		nextQueue = {},
		cachedThisPass = 0,
		totalThisPass = 0,
		noProgress = 0,
		lastRemaining = nil,
	}

	BSYC:StartTimer("DataDumpCache", 0.1, Data, "ProcessItemCacheRun")
end

function Data:ProcessItemCacheRun()
	local run = Data.__cache.itemCacheRun
	if not run or not run.running then return end

	local startPos = run.pos
	local endPos = math.min(#run.queue, startPos + ITEMCACHE_BATCH_SIZE - 1)

	for i = startPos, endPos do
		local link = run.queue[i]
		if link and not Data.__cache.ignore[link] then
			run.totalThisPass = run.totalThisPass + 1
			local cacheObj = Data:CacheLink(link)
			if cacheObj then
				run.cachedThisPass = run.cachedThisPass + 1
			else
				run.nextQueue[#run.nextQueue + 1] = link
			end
		end
	end

	run.pos = endPos + 1

	-- still more work in this pass
	if run.pos <= #run.queue then
		BSYC:StartTimer("DataDumpCache", 0.05, Data, "ProcessItemCacheRun")
		return
	end

	-- end of pass
	if #run.nextQueue < 1 then
		Debug(BSYC_DL.INFO, "PopulateItemCache-Done", run.totalThisPass, run.pass)
		run.running = false
		Data.__cache.itemCacheRun = nil
		return
	end

	-- progress / ignore heuristics (preserves existing behavior, but scoped per pass)
	local remaining = #run.nextQueue
	if run.lastRemaining ~= nil and run.lastRemaining == remaining and run.cachedThisPass == 0 then
		run.noProgress = run.noProgress + 1
	else
		run.noProgress = 0
	end
	run.lastRemaining = remaining

	if run.noProgress > 4 then
		for i = 1, #run.nextQueue do
			Data.__cache.ignore[run.nextQueue[i]] = run.nextQueue[i]
			Debug(BSYC_DL.WARN, "DataDumpCache-Ignore", run.nextQueue[i])
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
	run.queue = run.nextQueue
	run.nextQueue = {}
	run.pos = 1
	run.cachedThisPass = 0
	run.totalThisPass = 0

	BSYC:StartTimer("DataDumpCache", 0.3, Data, "ProcessItemCacheRun")
end

function Data:CheckExpiredAuctions()
	Debug(BSYC_DL.INFO, "CheckExpiredAuctions", BSYC.tracking.auction)
	if not BSYC.tracking.auction then return end

	for unitObj in self:IterateUnits(true) do
		if not unitObj.isGuild and unitObj.data.auction and unitObj.data.auction.count then

			local slotItems = {}

			for x = 1, unitObj.data.auction.count do
				if unitObj.data.auction.bag[x] then

					local timeleft
					local link, count, qOpts = BSYC:Split(unitObj.data.auction.bag[x])

					timeleft = qOpts.auction or nil

					--if the timeleft is greater than current time than keep it, it's not expired
					if link and timeleft and tonumber(timeleft) then
						if tonumber(timeleft) > time() then
							table.insert(slotItems, unitObj.data.auction.bag[x])
						end
					end

				end
			end

			unitObj.data.auction.bag = slotItems
			unitObj.data.auction.count = #slotItems or 0
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

	local enableCR = BSYC.options and BSYC.options.enableCR
	if enableCR == nil then enableCR = optionsDefaults.enableCR end

	local enableBNET = BSYC.options and BSYC.options.enableBNET
	if enableBNET == nil then enableBNET = optionsDefaults.enableBNET end

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

local function GetOption(key, defaultValue)
	if not BSYC.options then return defaultValue end
	local value = BSYC.options[key]
	if value == nil then return defaultValue end
	return value
end

local function ShouldIncludeRealm(realmKey, meta, dumpAll, filterList)
	if hasMark(realmKey, "§") then
		return false
	end

	if dumpAll then return true end
	if filterList and filterList[realmKey] then return true end

	if meta.isCurrent then return true end

	local enableBNET = GetOption("enableBNET", optionsDefaults.enableBNET)
	local enableCR = GetOption("enableCR", optionsDefaults.enableCR)

	if enableBNET then
		-- allow all realms, but preserve legacy equivalence safety
		if meta.isConnected then
			return true
		end

		-- legacy fallback: string-equivalent realms
		if Unit:CompareRealms(realmKey, BSYC.realm) then
			return true
		end

		return true -- still allow, but flags below will differ
	end
	if enableCR and meta.isConnected then return true end

	-- XR-guild passthrough
	if not enableCR and meta.isConnected then
		return true
	end

	return false
end

local function ShouldIncludeUnit(realmKey, unitKey, unitData, meta, dumpAll, filterList, currentFaction)
	local isGuild = hasMark(unitKey, "©")
	local hasAnyMark = hasMark(unitKey, "©") or hasMark(unitKey, "§")

	if dumpAll or filterList then
		local realmFilter = filterList and filterList[realmKey]
		if realmFilter and type(realmFilter) == "table" and not realmFilter[unitKey] then
			return false
		end
		return true
	end

	local enableCR = GetOption("enableCR", optionsDefaults.enableCR)

	-- XR realm suppression
	if not enableCR and meta.isConnected then
		return isGuild
	end

	-- faction filtering (characters only)
	local enableFaction = GetOption("enableFaction", optionsDefaults.enableFaction)
	if not isGuild and not hasAnyMark and not enableFaction then
		if currentFaction and unitData.faction and unitData.faction ~= currentFaction then
			return false
		end
	end

	-- guild toggle
	if isGuild and BSYC.tracking and BSYC.tracking.guild == false then
		return false
	end

	-- blacklist (characters only)
	if not isGuild and BSYC.db and BSYC.db.blacklist and BSYC.db.blacklist[unitKey] then
		return false
	end


	return true
end

function Data:IterateUnits(dumpAll, filterList)
	local currentFaction = (BSYC.db and BSYC.db.player and BSYC.db.player.faction) or _G.UnitFactionGroup("player")

	-- snapshot realm keys (FixDB-safe)
	local realmKeys = {}
	for realmKey in pairs(BagSyncDB) do
		realmKeys[#realmKeys + 1] = realmKey
	end

	-- precompute realm metadata once
	local realmMeta = {}
	for _, realmKey in ipairs(realmKeys) do
		if not hasMark(realmKey, "§") then
			realmMeta[realmKey] = {
				isConnected = Unit:CheckConnectedRealm(realmKey),
				isCurrent   = (realmKey == BSYC.realm),
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

				currentRealmData = BagSyncDB[realmKey]
				local meta = realmMeta[realmKey]

				if currentRealmData and meta and ShouldIncludeRealm(realmKey, meta, dumpAll, filterList) then
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

					if unitData and ShouldIncludeUnit(realmKey, unitKey, unitData, meta, dumpAll, filterList, currentFaction) then
						local isGuild = hasMark(unitKey, "©")
						local enableCR = GetOption("enableCR", optionsDefaults.enableCR)
						local isXRGuild = (not enableCR and meta.isConnected and isGuild)

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
