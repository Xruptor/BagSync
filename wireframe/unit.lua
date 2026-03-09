--[[
	unit.lua
		Unit module for BagSync
		Special Thanks:  This module was inspired by LibItemCache-2.0.lua credit to jaliborc

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.
--]]

-- Changes made:
-- - Replaced inline event closures with named handlers to ensure proper registration and reduce duplication.
-- - Centralized interaction state updates and auction callbacks for clarity and safer re-entrancy.
-- - Reset realm caches on collection to avoid stale realm key data, plus localized hot globals.

local BSYC = select(2, ...) --grab the addon namespace
local Unit = BSYC:NewModule("Unit")

local Debug = BSYC.DEBUG
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

local function DebugLog(level, ...)
	if Debug then Debug(level, "Unit", ...) end
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

local Realms
local Realms_RWS = {}
local Realms_LC = {}
local RealmChk_CR = {}
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
	--honestly lets ignore all the other gossip and frames that trigger and focus on the ones we want
	local showDebug = {
		[InteractType.MailInfo] = true,
		[InteractType.Banker] = true,
		[InteractType.Auctioneer] = true,
		[InteractType.VoidStorageBanker] = true,
		[InteractType.GuildBanker] = true,
	}
	if BSYC.isWarbandActive then
		showDebug[InteractType.AccountBanker] = true
	end

	local function HandleInteraction(eventName, winArg, isShow)
		if winArg and showDebug[winArg] then
			DebugLog(BSYC_DL.DEBUG, eventName, winArg)
		end

		if winArg == InteractType.MailInfo then
			SetLocationState("atMailbox", "BAGSYNC_EVENT_MAILBOX", isShow)
			return
		end
		if winArg == InteractType.Banker then
			SetLocationState("atBank", "BAGSYNC_EVENT_BANK", isShow)
			return
		end
		if winArg == InteractType.Auctioneer then
			SetLocationState("atAuction", "BAGSYNC_EVENT_AUCTION", isShow)
			return
		end
		if winArg == InteractType.VoidStorageBanker then
			SetLocationState("atVoidBank", "BAGSYNC_EVENT_VOIDBANK", isShow)
			return
		end
		if winArg == InteractType.GuildBanker then
			SetLocationState("atGuildBank", "BAGSYNC_EVENT_GUILDBANK", isShow)
			return
		end
		if BSYC.isWarbandActive and winArg == InteractType.AccountBanker then
			--note: this interaction window only works with the Warband Bank Convergence
			SetLocationState("atWarbandBank", "BAGSYNC_EVENT_WARBANDBANK", isShow)
			return
		end
	end

	function Unit:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(_, winArg)
		HandleInteraction("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", winArg, true)
	end

	--Introduced in Dragonflight (https://wowpedia.fandom.com/wiki/PLAYER_INTERACTION_MANAGER_FRAME_SHOW)
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

--these are used to process auction house data when it's ready.  Second variable is true for ready
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

	--they sold something on auction house, so lets trigger an owned auctions update
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
	DebugLog(BSYC_DL.TRACE, "DoRealmCollection", source)

	Realms = GetAutoCompleteRealms and GetAutoCompleteRealms() or nil
	if not Realms or #Realms == 0 then
		Realms = { GetRealmName() }
	end

	-- Clear realm caches to avoid stale entries on refresh.
	if wipe then
		wipe(Realms_RWS)
		wipe(Realms_LC)
		wipe(RealmChk_CR)
		wipe(RealmChk_RWS)
		wipe(RealmChk_LC)
	else
		Realms_RWS = {}
		Realms_LC = {}
		RealmChk_CR = {}
		RealmChk_RWS = {}
		RealmChk_LC = {}
	end

	for i, realm in ipairs(Realms) do
		realm = ApplyBrokenSpacing(realm)
		local origRealm = realm

		Realms[i] = realm
		RealmChk_CR[realm] = true

		realm = StripRealm(realm)
		Realms_RWS[i] = realm
		RealmChk_RWS[realm] = origRealm

		realm = strlower(realm)
		Realms_LC[i] = realm
		RealmChk_LC[realm] = origRealm
	end

	--this is used to identify cross servers as a unique key.
	--for example guilds that are on cross servers with players from different servers in same guild
	tsort(Realms)
	Unit.realmKey = (#Realms > 0 and tconcat(Realms, ";")) or "?"

	tsort(Realms_RWS)
	Unit.rwsKey = (#Realms_RWS > 0 and tconcat(Realms_RWS, ";")) or "?"

	tsort(Realms_LC)
	Unit.lowerKey = (#Realms_LC > 0 and tconcat(Realms_LC, ";")) or "?"

	DebugLog(BSYC_DL.TRACE, "DoRealmCollection-realmKey", Unit.realmKey)
	DebugLog(BSYC_DL.TRACE, "DoRealmCollection-rwsKey", Unit.rwsKey)
	DebugLog(BSYC_DL.TRACE, "DoRealmCollection-lowerKey", Unit.lowerKey)
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

	if type(value) == "string" then
		local pos = value:find(GUILD_MARK, 1, true)
		if pos and pos > 1 then
			guildName = value:sub(1, pos - 1)
		end
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
	unit.local_class_name, unit.class, unit.class_id  = UnitClass("player")
	unit.local_race_name, unit.race, unit.race_id  = UnitRace("player")
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
		DebugLog(BSYC_DL.TRACE, "GetPlayerInfo", playerName, realmName, faction, unit.class, unit.race, unit.guild, unit.guildrealm, guildRealm)
	end
	return unit
end

function Unit:CheckConnectedRealm(realm)
	if not realm then return false end
	if not Unit.realmKey then Unit:DoRealmCollection("CheckConnectedRealm") end

	realm = ApplyBrokenSpacing(realm)
	if RealmChk_CR[realm] then return true end

	realm = StripRealm(realm)
	if RealmChk_RWS[realm] then return true end

	realm = strlower(realm)
	if RealmChk_LC[realm] then return true end

	return false
end

function Unit:GetTrueRealmName(realm)
	if not realm then return "--UNKNOWN--" end
	if not Unit.realmKey then Unit:DoRealmCollection("GetTrueRealmName") end

	--for some reason they occasionally return the Normalized realm name instead of the true realm name. (see ticket #285)
	--in these situations the guild realms don't match because they may have a space or hyphen or something
	--we need to do checks for this to ensure we get the appropriate realm name

	if RealmChk_CR[realm] then
		return realm
	end

	local origRealm = realm

	--1) lets check for broken realms and incorrect spacing
	realm = ApplyBrokenSpacing(realm)
	if RealmChk_CR[realm] then
		return realm
	end

	--2) lets do a quick RWS check
	realm = StripRealm(realm)
	if RealmChk_RWS[realm] then
		return RealmChk_RWS[realm] --return original realm name
	end

	--3) lets check for lowercase
	realm = strlower(realm)
	if RealmChk_LC[realm] then
		return RealmChk_LC[realm] --return original realm name
	end

	--4) they must have a guild on another server.  So return the unaltered origRealm
	return origRealm
end

function Unit:CompareRealms(sourceRealm, targetRealm)
	if not sourceRealm or not targetRealm then return false end
	if sourceRealm == targetRealm then return true end

	--before we do anything lets make everything lowercase
	if strlower(sourceRealm) == strlower(targetRealm) then return true end

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
