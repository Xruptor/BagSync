--[[
	data.lua
		Handles all the data elements for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Data = BSYC:NewModule("Data")
local Unit = BSYC:GetModule("Unit")
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Data", ...) end
end

--increment forceDBReset to reset the ENTIRE db forcefully
local forceDBReset = 2
--these just reset individual items in the DB
local unitDBVersion = {
	auction = 1,
}

StaticPopupDialogs["BAGSYNC_RESETDATABASE"] = {
	text = L.ResetDBInfo,
	button1 = L.Yes,
	button2 = L.No,
	OnAccept = function()
		BagSyncDB = { ["forceDBReset§"] = forceDBReset }
		ReloadUI()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

----------------------
--   DB Functions   --
----------------------

function Data:OnEnable()
	Debug(2, "OnEnable")
	local ver = GetAddOnMetadata("BagSync","Version") or 0

	--get player information from Unit
	local player = Unit:GetUnitInfo()

	Debug(1, "UnitInfo-1", player.name, player.realm)
	Debug(1, "UnitInfo-2", player.class, player.race, player.gender, player.faction)
	Debug(1, "UnitInfo-3", player.guild, player.guildrealm)
	Debug(1, "RealmKey", Unit:GetRealmKey())
	Debug(1, "RealmKey_RWS", Unit:GetRealmKey_RWS())

	--main DB call
	BSYC.db = BSYC.db or {}

	--realm DB
	BagSyncDB[player.realm] = BagSyncDB[player.realm] or {}
	BSYC.db.realm = BagSyncDB[player.realm]

	--player DB
	BSYC.db.realm[player.name] = BSYC.db.realm[player.name] or {}
	BSYC.db.player = BSYC.db.realm[player.name]
	BSYC.db.player.currency = BSYC.db.player.currency or {}
	BSYC.db.player.professions = BSYC.db.player.professions or {}

	--blacklist DB
	BSYC.db.blacklist = BagSyncDB["blacklist§"]

	--options DB
	if BSYC.options.showTotal == nil then BSYC.options.showTotal = true end
	if BSYC.options.enableGuild == nil then BSYC.options.enableGuild = true end
	if BSYC.options.enableMailbox == nil then BSYC.options.enableMailbox = true end
	if BSYC.options.enableUnitClass == nil then BSYC.options.enableUnitClass = true end
	if BSYC.options.enableMinimap == nil then BSYC.options.enableMinimap = true end
	if BSYC.options.enableFaction == nil then BSYC.options.enableFaction = true end
	if BSYC.options.enableAuction == nil then BSYC.options.enableAuction = true end
	if BSYC.options.tooltipOnlySearch == nil then BSYC.options.tooltipOnlySearch = false end
	if BSYC.options.enableTooltips == nil then BSYC.options.enableTooltips = true end
	if BSYC.options.enableExtTooltip == nil then BSYC.options.enableExtTooltip = false end
	if BSYC.options.enableTooltipSeperator == nil then BSYC.options.enableTooltipSeperator = true end
	if BSYC.options.enableCrossRealmsItems == nil then BSYC.options.enableCrossRealmsItems = true end
	if BSYC.options.enableBNetAccountItems == nil then BSYC.options.enableBNetAccountItems = false end
	if BSYC.options.enableTooltipItemID == nil then BSYC.options.enableTooltipItemID = false end
	if BSYC.options.enableSourceDebugInfo == nil then BSYC.options.enableSourceDebugInfo = false end
	if BSYC.options.enableTooltipGreenCheck == nil then BSYC.options.enableTooltipGreenCheck = true end
	if BSYC.options.enableRealmIDTags == nil then BSYC.options.enableRealmIDTags = true end
	if BSYC.options.enableRealmAstrickName == nil then BSYC.options.enableRealmAstrickName = false end
	if BSYC.options.enableRealmShortName == nil then BSYC.options.enableRealmShortName = false end
	if BSYC.options.enableLoginVersionInfo == nil then BSYC.options.enableLoginVersionInfo = true end
	if BSYC.options.enableFactionIcons == nil then BSYC.options.enableFactionIcons = false end
	if BSYC.options.enableShowUniqueItemsTotals == nil then BSYC.options.enableShowUniqueItemsTotals = true end
	if BSYC.options.enableXR_BNETRealmNames == nil then BSYC.options.enableXR_BNETRealmNames = true end
	if BSYC.options.showGuildInGoldTooltip == nil then BSYC.options.showGuildInGoldTooltip = true end
	if BSYC.options.showGuildCurrentCharacter == nil then BSYC.options.showGuildCurrentCharacter = false end
	if BSYC.options.showGuildBankScanAlert == nil then BSYC.options.showGuildBankScanAlert = true end
	if BSYC.options.focusSearchEditBox == nil then BSYC.options.focusSearchEditBox = false end
	if BSYC.options.enableAccurateBattlePets == nil then BSYC.options.enableAccurateBattlePets = true end
	if BSYC.options.alwaysShowAdvSearch == nil then BSYC.options.alwaysShowAdvSearch = false end
	if BSYC.options.sortTooltipByTotals == nil then BSYC.options.sortTooltipByTotals = false end
	if BSYC.options.sortByCustomOrder == nil then BSYC.options.sortByCustomOrder = false end
	if BSYC.options.tooltipModifer == nil then BSYC.options.tooltipModifer = "NONE" end

	--setup the default colors
	if BSYC.options.colors == nil then BSYC.options.colors = {} end
	if BSYC.options.colors.first == nil then BSYC.options.colors.first = { r = 128/255, g = 1, b = 0 }  end
	if BSYC.options.colors.second == nil then BSYC.options.colors.second = { r = 1, g = 1, b = 1 }  end
	if BSYC.options.colors.total == nil then BSYC.options.colors.total = { r = 244/255, g = 164/255, b = 96/255 }  end
	if BSYC.options.colors.guild == nil then BSYC.options.colors.guild = { r = 101/255, g = 184/255, b = 192/255 }  end --very grayish light blue
	if BSYC.options.colors.debug == nil then BSYC.options.colors.debug = { r = 77/255, g = 216/255, b = 39/255 }  end --fel green
	if BSYC.options.colors.cross == nil then BSYC.options.colors.cross = { r = 1, g = 125/255, b = 10/255 }  end
	if BSYC.options.colors.bnet == nil then BSYC.options.colors.bnet = { r = 53/255, g = 136/255, b = 1 }  end
	if BSYC.options.colors.itemid == nil then BSYC.options.colors.itemid = { r = 82/255, g = 211/255, b = 134/255 }  end

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
	--we cannot store guild as on login the guild name returns nil
	--https://wow.gamepedia.com/API_GetGuildInfo

	--if player isn't in a guild, then delete old guild data if found, sometimes this gets left behind for some reason
	if not IsInGuild() and (BSYC.db.player.guild or BSYC.db.player.guildrealm) then
		BSYC.db.player.guild = nil
		BSYC.db.player.guildrealm = nil
	end

	--load the slash commands
	self:LoadSlashCommand()

	if BSYC.options.enableLoginVersionInfo then
		BSYC:Print("[v|cFF20ff20"..ver.."|r] /bgs, /bagsync")
	end
	if BSYC.options.debug.enable then
		BSYC:Print(L.DebugWarning)
		C_Timer.After(6, function() BSYC:Print(L.DebugWarning) end)
	end
end

function Data:DebugDumpOptions()
	Debug(1, "init-DebugDumpOptions")
	for k, v in pairs(BSYC.options) do
		if type(v) ~= "table" then
			Debug(1, k, tostring(v))
		else
			for x, y in pairs(v) do
				if type(y) ~= "table" then
					Debug(1, k, tostring(x), tostring(y))
				else
					if k == "colors" then
						Debug(1, k, tostring(x), y.r * 255, y.g * 255, y.b * 255)
					end
					--Debug(1, k, tostring(x), BSYC:serializeTable(y))
				end
			end
		end
	end
end

function Data:ResetColors()
	Debug(2, "ResetColors")

	if BSYC.options.colors == nil then BSYC.options.colors = {} end
	BSYC.options.colors.first = { r = 128/255, g = 1, b = 0 }
	BSYC.options.colors.second = { r = 1, g = 1, b = 1 }
	BSYC.options.colors.total = { r = 244/255, g = 164/255, b = 96/255 }
	BSYC.options.colors.guild = { r = 101/255, g = 184/255, b = 192/255 } --very grayish light blue
	BSYC.options.colors.debug = { r = 77/255, g = 216/255, b = 39/255 } --fel green
	BSYC.options.colors.cross = { r = 1, g = 125/255, b = 10/255 }
	BSYC.options.colors.bnet = { r = 53/255, g = 136/255, b = 1 }
	BSYC.options.colors.itemid = { r = 82/255, g = 211/255, b = 134/255 }
end

function Data:CleanDB()
	Debug(2, "CleanDB")

	--check for empty table table to prevent loops
	if next(BagSyncDB) == nil then
		BagSyncDB["forceDBReset§"] = forceDBReset
		BSYC:Print("|cFFFF9900"..L.DatabaseReset.."|r")
		return
	elseif not BagSyncDB["forceDBReset§"] or BagSyncDB["forceDBReset§"] < forceDBReset then
		BagSyncDB = { ["forceDBReset§"] = forceDBReset }
		BSYC:Print("|cFFFF9900"..L.DatabaseReset.."|r")
		return
	end
end

function Data:FixDB()
	Debug(2, "FixDB")

    local storeGuilds = {}

	if not BSYC.options.unitDBVersion then BSYC.options.unitDBVersion = {} end

	for unitObj in self:IterateUnits(true) do
		--store only user guild names
		if not unitObj.isGuild then
			if unitObj.data.guild and unitObj.data.guildrealm then
				storeGuilds[unitObj.data.guild..unitObj.data.guildrealm] = true
			end
		end
	end

	--cleanup guilds
	for realm, rd in pairs(BagSyncDB) do
		--ignore options
		if not string.match(realm, '§*') then
			--iterate through realm data
			for k, v in pairs(rd) do
				local isGuild = (k:find('©*') and true) or false
				if isGuild then
					if not storeGuilds[k..realm] then
						--remove obsolete guild
						BagSyncDB[realm][k] = nil
					end
				else
					--users lets do a individual db cleanup if necessary
					if BSYC.options.unitDBVersion.auction ~= unitDBVersion.auction and v.auction then
						v.auction = nil
					end
				end
			end
		end
	end

	if BSYC.options.unitDBVersion.auction ~= unitDBVersion.auction then
		BSYC:Print("|cFFffff00"..L.UnitDBAuctionReset.."|r")
	end

	--update db unit version information
	BSYC.options.unitDBVersion = unitDBVersion

	BSYC:Print("|cFFFF9900"..L.FixDBComplete.."|r")
end

function Data:LoadSlashCommand()
	Debug(2, "LoadSlashCommand")

	--load the keybinding locale information
	BINDING_HEADER_BAGSYNC = "BagSync"
	BINDING_NAME_BAGSYNCBLACKLIST = L.KeybindBlacklist
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
				BSYC:GetModule("Search"):StartSearch()
				return true
			elseif cmd == L.SlashGold or cmd == L.SlashMoney then
				BSYC:GetModule("Tooltip"):MoneyTooltip()
				return true
			elseif cmd == L.SlashCurrency and BSYC.IsRetail then
				BSYC:GetModule("Currency").frame:Show()
				return true
			elseif cmd == L.SlashProfiles then
				BSYC:GetModule("Profiles").frame:Show()
				return true
			elseif cmd == L.SlashProfessions and BSYC.IsRetail then
				BSYC:GetModule("Professions").frame:Show()
				return true
			elseif cmd == L.SlashBlacklist then
				BSYC:GetModule("Blacklist").frame:Show()
				return true
			elseif cmd == L.SlashFixDB then
				self:FixDB()
				return true
			elseif cmd == L.SlashResetDB then
				StaticPopup_Show("BAGSYNC_RESETDATABASE")
				return true
			elseif cmd == L.SlashConfig then
				if not BSYC.IsRetail then
					--only do this for Expansions less than Retail
					InterfaceOptionsFrame:Show() --has to be here to load the about frame onLoad
				else
					if InCombatLockdown() or GameMenuFrame:IsShown() or InterfaceOptionsFrame then
						return false
					end
				end
				InterfaceOptionsFrame_OpenToCategory(BSYC.aboutPanel) --force the panel to show
				return true
			elseif cmd == L.SlashDebug then
				BSYC:GetModule("Debug").frame:Show()
				return true
			else
				--do an item search, use the full command to search
				BSYC:GetModule("Search"):StartSearch(input)
				return true
			end

		end

		BSYC:Print("/bgs "..L.SlashItemName.." - "..L.HelpSearchItemName)
		BSYC:Print("/bgs "..L.SlashSearch.." - "..L.HelpSearchWindow)
		BSYC:Print("/bgs "..L.SlashGold.." - "..L.HelpGoldTooltip)
		BSYC:Print("/bgs "..L.SlashProfiles.." - "..L.HelpProfilesWindow)
		if BSYC.IsRetail then
			BSYC:Print("/bgs "..L.SlashProfessions.." - "..L.HelpProfessionsWindow)
			BSYC:Print("/bgs "..L.SlashCurrency.." - "..L.HelpCurrencyWindow)
		end
		BSYC:Print("/bgs "..L.SlashBlacklist.." - "..L.HelpBlacklistWindow)
		BSYC:Print("/bgs "..L.SlashFixDB.." - "..L.HelpFixDB)
		BSYC:Print("/bgs "..L.SlashResetDB.." - "..L.HelpResetDB)
		BSYC:Print("/bgs "..L.SlashConfig.." - "..L.HelpConfigWindow)
		BSYC:Print("/bgs "..L.SlashDebug.." - "..L.HelpDebug)
	end

	--/bgs and /bagsync
	BSYC:RegisterChatCommand("bgs", ChatCommand)
	BSYC:RegisterChatCommand("bagsync", ChatCommand)

end

function Data:CheckExpiredAuctions()
	Debug(2, "CheckExpiredAuctions")

	for unitObj in self:IterateUnits(true) do
		if not unitObj.isGuild and unitObj.data.auction and unitObj.data.auction.count then

			local slotItems = {}

			for x = 1, unitObj.data.auction.count do
				if unitObj.data.auction.bag[x] then

					local timeleft
					local link, count, identifier, optOne, optTwo = strsplit(";", unitObj.data.auction.bag[x])

					identifier = tonumber(identifier)

					if identifier and identifier == 1 then
						--it's a regular auction item
						timeleft = optOne
					else
						--it's a battlepet with identifier of 2
						timeleft = optTwo
					end

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

function Data:GetGuild()
	if not IsInGuild() then return end
	Debug(2, "GetGuild")

	local player = Unit:GetUnitInfo()
	if not player.guild or not player.guildrealm then return end

	if not BagSyncDB[player.guildrealm] then BagSyncDB[player.guildrealm] = {} end
	if not BagSyncDB[player.guildrealm][player.guild] then BagSyncDB[player.guildrealm][player.guild] = {} end
	return BagSyncDB[player.guildrealm][player.guild]
end

function Data:IterateUnits(dumpAll, filterList)
	Debug(2, "IterateUnits", dumpAll, filterList)

	local player = Unit:GetUnitInfo()
	local argKey, argValue = next(BagSyncDB)
	local k, v

	return function()
		while argKey do

			if argKey and string.match(argKey, '§*') then
				argKey, argValue = next(BagSyncDB, argKey)

			elseif argKey then
				local isConnectedRealm = (Unit:isConnectedRealm(argKey) and true) or false

				--check to see if a user joined a guild on a connected realm and doesn't have the XR or BNET options on
				--if they have guilds enabled, then we should show it anyways, regardless of the XR and BNET options
				--NOTE: This should ONLY be done if the guild realm is NOT the player realm.  If it's the same realms for both then it would be processed anyways.
				local isXRGuild = false
				if BSYC.options.enableGuild and player.guild and not BSYC.options.enableCrossRealmsItems and not BSYC.options.enableBNetAccountItems then
					isXRGuild = (player.guildrealm and argKey == player.guildrealm and argKey ~= player.realm) or false
				end

				local passChk = false
				if dumpAll or filterList then
					if dumpAll or (filterList and filterList[argKey]) then passChk = true end
				else
					if argKey == player.realm or isXRGuild then passChk = true end
					if isConnectedRealm and BSYC.options.enableCrossRealmsItems then passChk = true end
					if BSYC.options.enableBNetAccountItem then passChk = true end
				end

				if passChk then

					--pull entries from characters until k is empty, then pull next realm entry
					k, v = next(argValue, k)

					if k then

						local skipReturn = false
						local isGuild = (k:find('©*') and true) or false

						--return everything regardless of user settings
						if dumpAll or filterList then

							skipReturn = false

							if filterList then
								if filterList[argKey][k] then
									skipReturn = false
								else
									skipReturn = true
								end
							end

							if not skipReturn then
								return {realm=argKey, name=k, data=v, isGuild=isGuild, isConnectedRealm=isConnectedRealm, isXRGuild=isXRGuild}
							end

						elseif v.faction and (v.faction == BSYC.db.player.faction or BSYC.options.enableFaction) then

							skipReturn = false

							--check for guilds and if we have them merged or not
							if BSYC.options.enableGuild and isGuild then

								--check for guilds only on current character if enabled and on their current realm
								if (isXRGuild or BSYC.options.showGuildCurrentCharacter) and player.guild and player.guildrealm then
									--if we have the same guild realm and same guild name, then let it pass, otherwise skip it
									if argKey == player.guildrealm and k == player.guild then
										skipReturn = false
									else
										skipReturn = true
									end
								end

								--check for the guild blacklist
								if BSYC.db.blacklist[k..argKey] then skipReturn = true end

							elseif not BSYC.options.enableGuild and isGuild then
								skipReturn = true

							elseif isXRGuild then
								--if this is enabled, then we only want guilds, skip all users
								skipReturn = true
							end

							if not skipReturn then
								return {realm=argKey, name=k, data=v, isGuild=isGuild, isConnectedRealm=isConnectedRealm, isXRGuild=isXRGuild}
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
