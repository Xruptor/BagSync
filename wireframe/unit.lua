--[[
	unit.lua
		Unit module for BagSync
		Special Thanks:  This module was inspired by LibItemCache-2.0.lua credit to jaliborc

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...) --grab the addon namespace
local Unit = BSYC:NewModule("Unit")

local wipe = _G.wipe
local ipairs = _G.ipairs
local strmatch = _G.strmatch
local strlower = _G.string.lower
local strgsub = _G.string.gsub
local tconcat = _G.table.concat
local tsort = _G.table.sort

local GetAutoCompleteRealms = _G.GetAutoCompleteRealms
local GetRealmName = _G.GetRealmName
local UnitName = _G.UnitName
local UnitFactionGroup = _G.UnitFactionGroup
local UnitClass = _G.UnitClass
local UnitRace = _G.UnitRace
local UnitGUID = _G.UnitGUID
local UnitSex = _G.UnitSex
local GetGuildInfo = _G.GetGuildInfo
local GetMoney = _G.GetMoney
local GetCursorMoney = _G.GetCursorMoney
local GetPlayerTradeMoney = _G.GetPlayerTradeMoney
local GetNumBattlefieldScores = _G.GetNumBattlefieldScores
local IsActiveBattlefieldArena = _G.IsActiveBattlefieldArena
local InCombatLockdown = _G.InCombatLockdown
local UnitAffectingCombat = _G.UnitAffectingCombat
local C_PetBattles = _G.C_PetBattles

local C_PlayerInteractionManager = _G.C_PlayerInteractionManager
local C_AuctionHouse = _G.C_AuctionHouse
local CanUseVoidStorage = _G.CanUseVoidStorage
local GetVoidItemInfo = _G.GetVoidItemInfo
local CanGuildBankRepair = _G.CanGuildBankRepair
local Enum = _G.Enum

local function Debug(level, ...)
	if BSYC.DEBUG then BSYC.DEBUG(level, "Unit", ...) end
end

local BROKEN_REALMS = {
	['Aggra(Português)'] = 'Aggra (Português)',
	['AzjolNerub'] = 'Azjol-Nerub',
	['Arakarahm'] = 'Arak-arahm',
	['Корольлич'] = 'Король-лич',
}

local GUILD_MARK = "©"
local REALM_SPLIT_PATTERN = '^(.-) *%- *(.+)$'
local REALM_SPACE_PATTERN = '(%l)(%u)'
local REALM_STRIP_PATTERN = '[%p%c%s]'

-- Realm cache tables. Naming convention:
--   COR = Corrected Realm (ApplyBrokenSpacing applied — proper spacing/hyphens restored)
--   RWS = Remove White Space (punctuation, control chars, and whitespace stripped)
--   LC  = Lowercase (strlower of the RWS form)
--
-- Realms_* arrays hold the transformed realm at each stage (indexed, for key generation).
-- RealmChk_* lookup maps store: transformed_form → corrected_form (COR), used by
-- CheckConnectedRealm and GetTrueRealmName to resolve normalized/misspelled realm names.
local Realms
local Realms_RWS = {}
local Realms_LC = {}
local RealmChk_COR = {}
local RealmChk_RWS = {}
local RealmChk_LC = {}

local function ApplyBrokenSpacing(realm)
	if not realm then return realm end
	realm = BROKEN_REALMS[realm] or realm
	return strgsub(realm, REALM_SPACE_PATTERN, '%1 %2')
end

local function StripRealm(realm)
	if not realm then return realm end
	return strgsub(realm, REALM_STRIP_PATTERN, '')
end

local function NormalizeRealmForCompare(realm)
	realm = ApplyBrokenSpacing(realm)
	realm = StripRealm(realm)
	return realm and strlower(realm) or realm
end

-- Helper to normalize a realm name and return all three forms (COR, RWS, LC)
-- Used to avoid redundant transformations in CheckConnectedRealm and GetTrueRealmName
local function NormalizeRealmSingle(realm)
	if not realm then return nil, nil, nil end
	local cor = ApplyBrokenSpacing(realm)
	local rws = StripRealm(cor)
	local lc = strlower(rws)
	return cor, rws, lc
end

local function GetPlayerMoney()
	local money = GetMoney and GetMoney() or 0
	local cursorMoney = GetCursorMoney and GetCursorMoney() or 0
	local tradeMoney = GetPlayerTradeMoney and GetPlayerTradeMoney() or 0
	return money - cursorMoney - tradeMoney
end

local function SetLocationState(flagKey, message, isOpen)
	Unit[flagKey] = isOpen and true or false
	if isOpen then
		Unit:SendMessage(message, true)
	else
		Unit:SendMessage(message)
	end
end

if C_PlayerInteractionManager and Enum and Enum.PlayerInteractionType then
	local InteractType = Enum.PlayerInteractionType

	-- Lookup table mapping interaction types to their state flags and messages
	-- Replaces 6 duplicate if-blocks with O(1) lookup
	local INTERACT_TYPE_MAP = {
		[InteractType.MailInfo] = { flag = "atMailbox", msg = "BAGSYNC_EVENT_MAILBOX" },
		[InteractType.Banker] = { flag = "atBank", msg = "BAGSYNC_EVENT_BANK" },
		[InteractType.Auctioneer] = { flag = "atAuction", msg = "BAGSYNC_EVENT_AUCTION" },
		[InteractType.VoidStorageBanker] = { flag = "atVoidBank", msg = "BAGSYNC_EVENT_VOIDBANK" },
		[InteractType.GuildBanker] = { flag = "atGuildBank", msg = "BAGSYNC_EVENT_GUILDBANK" },
	}
	if BSYC.isWarbandActive then
		INTERACT_TYPE_MAP[InteractType.AccountBanker] = { flag = "atWarbandBank", msg = "BAGSYNC_EVENT_WARBANDBANK" }
	end

	local function HandleInteraction(eventName, winArg, isShow)
		local interactInfo = INTERACT_TYPE_MAP[winArg]
		if interactInfo then
			Debug(BSYC_DL.DEBUG, eventName, winArg)
			SetLocationState(interactInfo.flag, interactInfo.msg, isShow)
		end
	end

	function Unit:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(_, winArg)
		HandleInteraction("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", winArg, true)
	end

	function Unit:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(_, winArg)
		HandleInteraction("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", winArg, false)
	end

	Unit:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
	Unit:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
else
	-- Legacy event mapping avoids per-event closures and keeps state logic centralized.
	local LEGACY_EVENT_MAP = {
		MAIL_SHOW = { flag = "atMailbox", msg = "BAGSYNC_EVENT_MAILBOX", open = true },
		MAIL_CLOSED = { flag = "atMailbox", msg = "BAGSYNC_EVENT_MAILBOX", open = false },
		BANKFRAME_OPENED = { flag = "atBank", msg = "BAGSYNC_EVENT_BANK", open = true },
		BANKFRAME_CLOSED = { flag = "atBank", msg = "BAGSYNC_EVENT_BANK", open = false },
		AUCTION_HOUSE_SHOW = { flag = "atAuction", msg = "BAGSYNC_EVENT_AUCTION", open = true },
		AUCTION_HOUSE_CLOSED = { flag = "atAuction", msg = "BAGSYNC_EVENT_AUCTION", open = false },
	}

	function Unit:LEGACY_INTERACTION_EVENT(event)
		local info = LEGACY_EVENT_MAP[event]
		if not info then return end
		SetLocationState(info.flag, info.msg, info.open)
	end

	Unit:RegisterEvent("MAIL_SHOW", "LEGACY_INTERACTION_EVENT")
	Unit:RegisterEvent("MAIL_CLOSED", "LEGACY_INTERACTION_EVENT")
	Unit:RegisterEvent("BANKFRAME_OPENED", "LEGACY_INTERACTION_EVENT")
	Unit:RegisterEvent("BANKFRAME_CLOSED", "LEGACY_INTERACTION_EVENT")
	Unit:RegisterEvent("AUCTION_HOUSE_SHOW", "LEGACY_INTERACTION_EVENT")
	Unit:RegisterEvent("AUCTION_HOUSE_CLOSED", "LEGACY_INTERACTION_EVENT")

	if CanUseVoidStorage and GetVoidItemInfo then
		function Unit:VOID_STORAGE_OPEN()
			SetLocationState("atVoidBank", "BAGSYNC_EVENT_VOIDBANK", true)
		end

		function Unit:VOID_STORAGE_CLOSE()
			SetLocationState("atVoidBank", "BAGSYNC_EVENT_VOIDBANK", false)
		end

		Unit:RegisterEvent("VOID_STORAGE_OPEN")
		Unit:RegisterEvent("VOID_STORAGE_CLOSE")
	end

	if CanGuildBankRepair then
		function Unit:GUILDBANKFRAME_OPENED()
			SetLocationState("atGuildBank", "BAGSYNC_EVENT_GUILDBANK", true)
		end

		function Unit:GUILDBANKFRAME_CLOSED()
			SetLocationState("atGuildBank", "BAGSYNC_EVENT_GUILDBANK", false)
		end

		Unit:RegisterEvent("GUILDBANKFRAME_OPENED")
		Unit:RegisterEvent("GUILDBANKFRAME_CLOSED")
	end
end

-- Auction house data processing handlers
if C_AuctionHouse then
	function Unit:AUCTION_HOUSE_THROTTLED_SYSTEM_READY()
		--if we created an auction, then query the player owned auctions but don't push event yet
		if self.auctionCreated then
			if C_AuctionHouse.QueryOwnedAuctions then
				C_AuctionHouse.QueryOwnedAuctions({})
			end
			self.auctionCreated = false
			return
		end
		self:SendMessage('BAGSYNC_EVENT_AUCTION', self.atAuction, true)
	end

	function Unit:AUCTION_HOUSE_AUCTION_CREATED()
		self.auctionCreated = true
	end

	Unit:RegisterEvent('AUCTION_HOUSE_THROTTLED_SYSTEM_READY')
	Unit:RegisterEvent('AUCTION_HOUSE_AUCTION_CREATED')
else
	function Unit:AUCTION_OWNED_LIST_UPDATE()
		self:SendMessage('BAGSYNC_EVENT_AUCTION', self.atAuction, true)
	end

	Unit:RegisterEvent('AUCTION_OWNED_LIST_UPDATE')
end

function Unit:OnEnable()
	if not Unit.realmKey then Unit:DoRealmCollection("OnEnable") end
end

function Unit:DoRealmCollection(source)
	Debug(BSYC_DL.TRACE, "DoRealmCollection", source)

	Realms = GetAutoCompleteRealms and GetAutoCompleteRealms() or nil
	if not Realms or #Realms == 0 then
		Realms = { GetRealmName() }
	end

	-- Clear realm caches to avoid stale entries on refresh
	-- Dead code removed: wipe is always available in WoW Lua, no nil check needed
	wipe(Realms_RWS)
	wipe(Realms_LC)
	wipe(RealmChk_COR)
	wipe(RealmChk_RWS)
	wipe(RealmChk_LC)

	for i, realm in ipairs(Realms) do
		-- Cache all transformations to avoid redundant ApplyBrokenSpacing/StripRealm calls
		local cor = ApplyBrokenSpacing(realm)
		local rws = StripRealm(cor)
		local lc = strlower(rws)

		Realms[i] = cor
		RealmChk_COR[cor] = true

		Realms_RWS[i] = rws
		RealmChk_RWS[rws] = cor

		Realms_LC[i] = lc
		RealmChk_LC[lc] = cor
	end

	--this is used to identify cross servers as a unique key.
	--for example guilds that are on cross servers with players from different servers in same guild
	tsort(Realms)
	Unit.realmKey = (#Realms > 0 and tconcat(Realms, ";")) or "?"

	tsort(Realms_RWS)
	Unit.rwsKey = (#Realms_RWS > 0 and tconcat(Realms_RWS, ";")) or "?"

	tsort(Realms_LC)
	Unit.lowerKey = (#Realms_LC > 0 and tconcat(Realms_LC, ";")) or "?"

	Debug(BSYC_DL.TRACE, "DoRealmCollection-realmKey", Unit.realmKey)
	Debug(BSYC_DL.TRACE, "DoRealmCollection-rwsKey", Unit.rwsKey)
	Debug(BSYC_DL.TRACE, "DoRealmCollection-lowerKey", Unit.lowerKey)
end

function Unit:GetUnitAddress(unit)
	if not Unit.realmKey then Unit:DoRealmCollection("GetUnitAddress") end

	local realmName = GetRealmName()
	local playerName = UnitName("player")

	if not unit then
		return realmName, playerName
	end

	local name, realm = strmatch(unit, REALM_SPLIT_PATTERN)
	local value = name or unit
	local guildName

	-- Removed redundant type check - string.find works on strings, and value is always a string here
	local pos = value:find(GUILD_MARK, 1, true)
	if pos and pos > 1 then
		guildName = value:sub(1, pos - 1)
	end

	return realm or realmName, guildName or unit, guildName and true
end

function Unit:GetPlayerInfo(bypassDebug)
	if not Unit.realmKey then Unit:DoRealmCollection("GetPlayerInfo") end

	local realmName = GetRealmName()
	local playerName = UnitName("player")
	local faction = UnitFactionGroup("player")
	local guildName, _, _, guildRealm = GetGuildInfo("player")

	local unit = {}
	unit.faction = faction
	unit.realm = realmName
	unit.name = playerName
	unit.money = GetPlayerMoney()
	unit.local_class_name, unit.class, unit.class_id = UnitClass("player")
	unit.local_race_name, unit.race, unit.race_id = UnitRace("player")
	unit.guid = UnitGUID("player")
	unit.guild = guildName
	if unit.guild then
		--we need to check for Normalized realm names that will cause issues since they are missing spaces and hyphens and won't match GetRealmName()
		unit.guildrealm = self:GetTrueRealmName(guildRealm or realmName)
	end
	unit.gender = UnitSex("player")

	unit.guild = unit.guild and (unit.guild .. GUILD_MARK)
	unit.realmKey = Unit.realmKey
	unit.rwsKey = Unit.rwsKey
	unit.lowerKey = Unit.lowerKey

	if not bypassDebug then
		Debug(BSYC_DL.TRACE, "GetPlayerInfo", playerName, realmName, faction, unit.class, unit.race, unit.guild, unit.guildrealm, guildRealm)
	end
	return unit
end

function Unit:CheckConnectedRealm(realm)
	if not realm then return false end
	if not Unit.realmKey then Unit:DoRealmCollection("CheckConnectedRealm") end

	-- Use NormalizeRealmSingle to get all forms at once, then check in order of specificity
	local cor, rws, lc = NormalizeRealmSingle(realm)

	if RealmChk_COR[cor] then return true end
	if RealmChk_RWS[rws] then return true end
	if RealmChk_LC[lc] then return true end

	return false
end

function Unit:GetTrueRealmName(realm)
	if not realm then return "--UNKNOWN--" end
	if not Unit.realmKey then Unit:DoRealmCollection("GetTrueRealmName") end

	--for some reason they occasionally return the Normalized realm name instead of the true realm name. (see ticket #285)
	--in these situations the guild realms don't match because they may have a space or hyphen or something
	--we need to do checks for this to ensure we get the appropriate realm name

	local cor, rws, lc = NormalizeRealmSingle(realm)

	-- Check in order: corrected realname, stripped, lowercase
	-- Early returns avoid unnecessary checks
	if RealmChk_COR[cor] then
		return cor
	end

	if RealmChk_RWS[rws] then
		return RealmChk_RWS[rws]
	end

	if RealmChk_LC[lc] then
		return RealmChk_LC[lc]
	end

	-- they must have a guild on another server. So return the unaltered realm
	return realm
end

function Unit:CompareRealms(sourceRealm, targetRealm)
	if not sourceRealm or not targetRealm then return false end
	if sourceRealm == targetRealm then return true end

	-- Cache lowercase results to avoid redundant strlower calls
	local sourceLC = strlower(sourceRealm)
	local targetLC = strlower(targetRealm)

	if sourceLC == targetLC then return true end

	-- NormalizeRealmForCompare will call strlower again, but we've already cached the result above
	-- This is fine - the function does more than just lowercase
	return NormalizeRealmForCompare(sourceRealm) == NormalizeRealmForCompare(targetRealm)
end

function Unit:IsInBG()
	return GetNumBattlefieldScores and (GetNumBattlefieldScores() > 0) or false
end

function Unit:IsInArena()
	if not IsActiveBattlefieldArena then return false end
	return IsActiveBattlefieldArena() and true or false
end

function Unit:InCombatLockdown()
	return self:IsInBG()
		or self:IsInArena()
		or (InCombatLockdown and InCombatLockdown())
		or (UnitAffectingCombat and UnitAffectingCombat("player"))
		or (C_PetBattles and C_PetBattles.IsInBattle and C_PetBattles.IsInBattle())
end
