--[[
	data.lua
		Handles all the data elements for BagSync

		BagSync - All Rights Reserved - (c) 2024
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Data = BSYC:NewModule("Data")
local Unit = BSYC:GetModule("Unit")
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

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
	tooltipModifer = "NONE",
	singleCharLocations = false,
	useIconLocations = true,
	itemTotalsByClassColor = true,
	showRaceIcons = true,
	showGuildTabs = false,
	showWarbandTabs = false,
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

local ignoreChk, ignoreTotal = 0, 0

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
		C_Timer.After(6, function() BSYC:Print(L.DebugWarning) end)
	end
end

function Data:ShowInfoWindow()
	if not BSYC.options.showBNETCRInfoWindow then return end

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
		if not string.match(k, '§*') then
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
				if Settings then
					Settings.OpenToCategory("BagSync")
				elseif InterfaceOptionsFrame_OpenToCategory then

					if not BSYC.IsRetail then
						--only do this for Expansions less than Retail
						InterfaceOptionsFrame:Show() --has to be here to load the about frame onLoad
					else
						if InCombatLockdown() or GameMenuFrame:IsShown() or InterfaceOptionsFrame then
							return false
						end
					end

					InterfaceOptionsFrame_OpenToCategory(BSYC.aboutPanel)
				end
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

	local itemObj = {}
	local speciesID = BSYC:FakeIDToSpeciesID(shortID)

	if not Data.__cache.items[shortID] then
		if speciesID then
			itemObj.itemQuality = 1
			itemObj.itemLink = shortID --store the FakeID
			itemObj.speciesID = speciesID
			itemObj.parseLink = origLink

			--https://wowpedia.fandom.com/wiki/API_C_PetJournal.GetPetInfoBySpeciesID
			itemObj.speciesName,
			itemObj.speciesIcon,
			itemObj.petType,
			itemObj.companionID,
			itemObj.tooltipSource,
			itemObj.tooltipDescription,
			itemObj.isWild,
			itemObj.canBattle,
			itemObj.isTradeable,
			itemObj.isUnique,
			itemObj.obtainable,
			itemObj.creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
		else
			if C_Item.IsItemDataCachedByID(shortID) then
				itemObj.parseLink = origLink

				--https://wowpedia.fandom.com/wiki/API_C_Item.GetItemInfo
				itemObj.itemName,
				itemObj.itemLink,
				itemObj.itemQuality,
				itemObj.itemLevel,
				itemObj.itemMinLevel,
				itemObj.itemType,
				itemObj.itemSubType,
				itemObj.itemStackCount,
				itemObj.itemEquipLoc,
				itemObj.itemTexture,
				itemObj.sellPrice,
				itemObj.classID,
				itemObj.subclassID,
				itemObj.bindType,
				itemObj.expacID,
				itemObj.setID,
				itemObj.isCraftingReagent = C_Item.GetItemInfo(shortID)
			else
				C_Item.RequestLoadItemDataByID(shortID)
			end
		end
		--add to Cache if we have something to work with
		if itemObj.speciesName or (itemObj.itemName and itemObj.itemLink) then
			Data.__cache.items[shortID] = itemObj
			return itemObj
		end
	else
		return Data.__cache.items[shortID]
	end
	return nil
end

function Data:PopulateItemCache(errorList, errorCount)
	if errorList and errorCount then
		Debug(BSYC_DL.INFO, "PopulateItemCache", #errorList, errorCount)
	end
	local allowList = {
		bag = true,
		bank = true,
		reagents = true,
		equip = true,
		mailbox = true,
		void = true,
		auction = true,
		equipbags = true,
	}
	local tmpList = {}
	local tmpError = {}

	local function doItem(data)
		for i=1, #data do
			if data[i] then
				local link = BSYC:Split(data[i], true)
				if link and not tmpList[link] and not Data.__cache.ignore[link] then
					local cacheObj = Data:CacheLink(link)
					if cacheObj then
						tmpList[link] = true --lets not check the same item twice in same pass
					else
						table.insert(tmpError, link)
						tmpList[link] = true --lets not check the same item twice in same pass
					end
				end
			end
		end
	end

	local function CacheCheck(unitObj, target)
		if unitObj.data[target] then
			if target == "bag" or target == "bank" or target == "reagents" then
				for bagID, bagData in pairs(unitObj.data[target] or {}) do
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
			for tabID, tabData in pairs(unitObj.data.tabs or {}) do
				doItem(tabData)
			end
		end
	end

	--do initial grab before we do a timed loop
	if not errorList then
		ignoreChk, ignoreTotal = 0, 0 --reset our ignore counts

		for unitObj in Data:IterateUnits(true) do
			if not unitObj.isGuild then
				for k, v in pairs(allowList) do
					CacheCheck(unitObj, k)
				end
			else
				CacheCheck(unitObj, "guild")
			end
		end
		--only loop again if we have anything to work with
		if #tmpError > 0 then
			BSYC:StartTimer("DataDumpCache-0", 0.3, Data, "PopulateItemCache", tmpError, 0)
		end
		return
	end

	--we don't want to do these checks more than 20 times, otherwise endless loop
	if #errorList > 0 and errorCount < 20 then
		errorCount = errorCount + 1

		--iterate backwards since we are using table.remove
		for i=#errorList, 1, -1 do
			local errObj = Data:CacheLink(errorList[i])
			if errObj then
				--remove it since we have a cached item
				table.remove(errorList, i)
			end
		end

		if #errorList > 0 then
			--check our ignore list in case we repeatedly process invalid or broken itemIDs
			if ignoreChk ~= #errorList then
				ignoreChk = #errorList
				ignoreTotal = 0
			else
				ignoreTotal = ignoreTotal + 1
			end

			--if we have ignored the same list of items on more than 5 separate occasions then it's probably invalid, add them to ignore
			if ignoreTotal > 4 then
				for i=1, #errorList do
					Data.__cache.ignore[errorList[i]] = errorList[i]
					Debug(BSYC_DL.WARN, "DataDumpCache-Ignore", errorList[i])
				end
				errorList = {}
				errorCount = -1
			end

			--loop again if we still have something
			BSYC:StartTimer("DataDumpCache-"..errorCount, 0.3, Data, "PopulateItemCache", errorList, errorCount)
		end
	end
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
	local isConnectedRealm = Unit:isConnectedRealm(player.realm)
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

	local isConnectedRealm = Unit:isConnectedRealm(player.guildrealm)
	local isXRGuild = false
	if not BSYC.options.enableCR and not BSYC.options.enableBNET then
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

function Data:IterateUnits(dumpAll, filterList)
	Debug(BSYC_DL.INFO, "IterateUnits", dumpAll, filterList)

	local player = Unit:GetPlayerInfo(true)
	local argKey, argValue = next(BagSyncDB)
	local k, v

	return function()
		while argKey do

			if argKey and string.match(argKey, '§*') then
				argKey, argValue = next(BagSyncDB, argKey)

			elseif argKey then
				local isConnectedRealm = Unit:isConnectedRealm(argKey)

				--check to see if a user joined a guild on a connected realm and doesn't have the CR or BNET options on
				--if they have guilds enabled, then we should show it anyways, regardless of the CR and BNET options
				--NOTE: This should ONLY be done if the guild realm is NOT the player realm.  If it's the same realms for both then it would be processed anyways.
				local isXRGuild = false
				if BSYC.tracking.guild and player.guild and not BSYC.options.enableCR and not BSYC.options.enableBNET then
					if player.guildrealm and Unit:CompareRealms(argKey, player.guildrealm) then
						isXRGuild = not Unit:CompareRealms(argKey, player.realm) or false
					end
				end

				local passChk = false
				if dumpAll or filterList then
					if dumpAll or (filterList and filterList[argKey]) then passChk = true end
				else
					if argKey == player.realm or isXRGuild then passChk = true end
					if isConnectedRealm and BSYC.options.enableCR then passChk = true end
					if BSYC.options.enableBNET then passChk = true end
				end

				if passChk then

					--pull entries from characters until k is empty, then pull next realm entry
					k, v = next(argValue, k)

					if k then

						local skipReturn = false
						local isGuild = (k:find('©*') and true) or false

						--return everything regardless of user settings
						if dumpAll or filterList then

							if filterList and not filterList[argKey][k] then
								skipReturn = true
							end

							if not skipReturn then
								return {
									realm = argKey,
									name = k,
									data = v,
									isGuild = isGuild,
									isConnectedRealm = isConnectedRealm,
									isXRGuild = isXRGuild
								}
							end

						elseif v.faction and (v.faction == BSYC.db.player.faction or BSYC.options.enableFaction) then

							--check for guilds and if we have them merged or not
							if BSYC.tracking.guild and isGuild then

								--check for guilds only on current character if enabled and on their current realm
								if (isXRGuild or BSYC.options.showGuildCurrentCharacter) and player.guild and player.guildrealm then
									--if we have the same guild realm and same guild name, then let it pass, otherwise skip it
									if Unit:CompareRealms(argKey, player.guildrealm) and k == player.guild then
										skipReturn = false
									else
										skipReturn = true
									end
								end

								--check for the guild blacklist
								if BSYC.db.blacklist[k..argKey] then skipReturn = true end

							elseif not BSYC.tracking.guild and isGuild then
								skipReturn = true

							elseif isXRGuild then
								--if this is enabled, then we only want guilds, skip all users
								skipReturn = true
							end

							if not skipReturn then
								return {
									realm = argKey,
									name = k,
									data = v,
									isGuild = isGuild,
									isConnectedRealm = isConnectedRealm,
									isXRGuild = isXRGuild
								}
							end

						end

					else
						--we have looped through all the characters and next k entry is empty, pull next entry from realms
						argKey, argValue = next(BagSyncDB, argKey)
					end

				else
					--realm doesn't match our criteria, pull next entry from realms
					argKey, argValue = next(BagSyncDB, argKey)
				end

			end
		end
	end

end
