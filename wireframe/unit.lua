--[[
	unit.lua
		Unit module for BagSync
		Special Thanks:  This module was inspired by LibItemCache-2.0.lua credit to jaliborc

		BagSync - All Rights Reserved - (c) 2024
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Unit = BSYC:NewModule("Unit", 'AceEvent-3.0')

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Unit", ...) end
end

local BROKEN_REALMS = {
	['Aggra(Português)'] = 'Aggra (Português)',
	['AzjolNerub'] = 'Azjol-Nerub',
	['Arakarahm'] = 'Arak-arahm',
	['Корольлич'] = 'Король-лич',
}

local Realms = _G.GetAutoCompleteRealms()
local Realms_RWS = {}
local Realms_LC = {} --lowercase

local RealmChk_CR = {}
local RealmChk_RWS = {}
local RealmChk_LC = {}

if C_PlayerInteractionManager then

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

	Unit:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(event, winArg)
		if winArg and showDebug[winArg] then
			Debug(BSYC_DL.DEBUG, "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", winArg)
		end
		if winArg == InteractType.MailInfo then
			Unit.atMailbox = true
			Unit:SendMessage('BAGSYNC_EVENT_MAILBOX', true)

		elseif winArg == InteractType.Banker then
			Unit.atBank = true
			Unit:SendMessage('BAGSYNC_EVENT_BANK', true)

		elseif winArg == InteractType.Auctioneer then
			Unit.atAuction = true
			Unit:SendMessage('BAGSYNC_EVENT_AUCTION', true)

		elseif winArg == InteractType.VoidStorageBanker then
			Unit.atVoidBank = true
			Unit:SendMessage('BAGSYNC_EVENT_VOIDBANK', true)

		elseif winArg == InteractType.GuildBanker then
			Unit.atGuildBank = true
			Unit:SendMessage('BAGSYNC_EVENT_GUILDBANK', true)

		elseif BSYC.isWarbandActive and winArg == InteractType.AccountBanker then
			--note: this interaction window only works with the Warband Bank Convergence
			Unit.atWarbandBank = true
			Unit:SendMessage('BAGSYNC_EVENT_WARBANDBANK', true)
		end
	end)

	--Introduced in Dragonflight (https://wowpedia.fandom.com/wiki/PLAYER_INTERACTION_MANAGER_FRAME_SHOW)
	Unit:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(event, winArg)
		if winArg and showDebug[winArg] then
			Debug(BSYC_DL.DEBUG, "PLAYER_INTERACTION_MANAGER_FRAME_HIDE", winArg)
		end
		if winArg == InteractType.MailInfo then
			Unit.atMailbox = false
			Unit:SendMessage('BAGSYNC_EVENT_MAILBOX')

		elseif winArg == InteractType.Banker then
			Unit.atBank = false
			Unit:SendMessage('BAGSYNC_EVENT_BANK')

		elseif winArg == InteractType.Auctioneer then
			Unit.atAuction = false
			Unit:SendMessage('BAGSYNC_EVENT_AUCTION')

		elseif winArg == InteractType.VoidStorageBanker then
			Unit.atVoidBank = false
			Unit:SendMessage('BAGSYNC_EVENT_VOIDBANK')

		elseif winArg == InteractType.GuildBanker then
			Unit.atGuildBank = false
			Unit:SendMessage('BAGSYNC_EVENT_GUILDBANK')

		elseif BSYC.isWarbandActive and winArg == InteractType.AccountBanker then
			--note: this interaction window only works with the Warband Bank Convergence
			Unit.atWarbandBank = false
			Unit:SendMessage('BAGSYNC_EVENT_WARBANDBANK')
		end
	end)
else

	Unit:RegisterEvent('MAIL_SHOW', function()
		Unit.atMailbox = true
		Unit:SendMessage('BAGSYNC_EVENT_MAILBOX', true)
	end)
	Unit:RegisterEvent('MAIL_CLOSED', function()
		Unit.atMailbox = false
		Unit:SendMessage('BAGSYNC_EVENT_MAILBOX')
	end)
	Unit:RegisterEvent('BANKFRAME_OPENED', function()
		Unit.atBank = true
		Unit:SendMessage('BAGSYNC_EVENT_BANK', true)
	end)
	Unit:RegisterEvent('BANKFRAME_CLOSED', function()
		Unit.atBank = false
		Unit:SendMessage('BAGSYNC_EVENT_BANK')
	end)
	Unit:RegisterEvent('AUCTION_HOUSE_SHOW', function()
		Unit.atAuction = true
		Unit:SendMessage('BAGSYNC_EVENT_AUCTION', true)
	end)
	Unit:RegisterEvent('AUCTION_HOUSE_CLOSED', function()
		Unit.atAuction = false
		Unit:SendMessage('BAGSYNC_EVENT_AUCTION')
	end)

	if CanUseVoidStorage then
		Unit:RegisterEvent('VOID_STORAGE_OPEN', function()
			Unit.atVoidBank = true
			Unit:SendMessage('BAGSYNC_EVENT_VOIDBANK', true)
		end)
		Unit:RegisterEvent('VOID_STORAGE_CLOSE', function()
			Unit.atVoidBank = false
			Unit:SendMessage('BAGSYNC_EVENT_VOIDBANK')
		end)
	end

	if CanGuildBankRepair then
		Unit:RegisterEvent('GUILDBANKFRAME_OPENED', function()
			Unit.atGuildBank = true
			Unit:SendMessage('BAGSYNC_EVENT_GUILDBANK', true)
		end)
		Unit:RegisterEvent('GUILDBANKFRAME_CLOSED', function()
			Unit.atGuildBank = false
			Unit:SendMessage('BAGSYNC_EVENT_GUILDBANK')
		end)
	end
end

--these are used to process auction house data when it's ready.  Second variable is true for ready
if C_AuctionHouse then
	Unit:RegisterEvent('AUCTION_HOUSE_THROTTLED_SYSTEM_READY', function()
		--if we created an auction, then query the player owned auctions but don't push event yet
		if Unit.auctionCreated then
			C_AuctionHouse.QueryOwnedAuctions({})
			Unit.auctionCreated = false
			return
		end
		Unit:SendMessage('BAGSYNC_EVENT_AUCTION', Unit.atAuction, true)
	end)
	--they sold something on auction house, so lets trigger an owned auctions update
	Unit:RegisterEvent('AUCTION_HOUSE_AUCTION_CREATED', function()
		Unit.auctionCreated = true
	end)
else
	Unit:RegisterEvent('AUCTION_OWNED_LIST_UPDATE', function()
		Unit:SendMessage('BAGSYNC_EVENT_AUCTION', Unit.atAuction, true)
	end)
end

function Unit:OnEnable()
	if not Unit.realmKey then Unit:DoRealmCollection("OnEnable") end
end

function Unit:DoRealmCollection(source)
	Debug(BSYC_DL.TRACE, "DoRealmCollection", source)

	Realms = _G.GetAutoCompleteRealms()

	if not Realms or #Realms == 0 then
		Realms = {_G.GetRealmName()}
	end

	for i, realm in ipairs(Realms) do
			realm = BROKEN_REALMS[realm] or realm

			realm = realm:gsub('(%l)(%u)', '%1 %2') -- names like Blade'sEdge to Blade's Edge
			local origRealm = realm
			Realms[i] = realm
			RealmChk_CR[realm] = true

			realm = realm:gsub('[%p%c%s]', '') -- remove all punctuation characters, all control characters, and all whitespace characters 
			Realms_RWS[i] = realm
			RealmChk_RWS[realm] = origRealm

			realm = string.lower(realm)
			Realms_LC[i] = realm
			RealmChk_LC[realm] = origRealm
	end

	--this is used to identify cross servers as a unique key.
	--for example guilds that are on cross servers with players from different servers in same guild
	table.sort(Realms, function(a,b) return (a < b) end) --sort them alphabetically
	Unit.realmKey = table.concat(Realms, ";") or "?" --concat them together

	table.sort(Realms_RWS, function(a,b) return (a < b) end) --sort them alphabetically
	Unit.rwsKey = table.concat(Realms_RWS, ";") or "?" --concat them together

	table.sort(Realms_LC, function(a,b) return (a < b) end) --sort them alphabetically
	Unit.lowerKey = table.concat(Realms_LC, ";") or "?" --concat them together

	Debug(BSYC_DL.TRACE, "DoRealmCollection-realmKey", Unit.realmKey)
	Debug(BSYC_DL.TRACE, "DoRealmCollection-rwsKey", Unit.rwsKey)
	Debug(BSYC_DL.TRACE, "DoRealmCollection-lowerKey", Unit.lowerKey)
end

function Unit:GetUnitAddress(unit)
	if not Unit.realmKey then Unit:DoRealmCollection("GetUnitAddress") end

	local REALM = _G.GetRealmName()
	local PLAYER = _G.UnitName("player")

	if not unit then
		return REALM, PLAYER
	end

	local name, realm = strmatch(unit, '^(.-) *%- *(.+)$')
	local guildName = strmatch(name or unit, '(.+)©')
	return realm or REALM, guildName or unit, guildName and true
end

function Unit:GetPlayerInfo(bypassDebug)
	if not Unit.realmKey then Unit:DoRealmCollection("GetPlayerInfo") end

	local REALM = _G.GetRealmName()
	local PLAYER = _G.UnitName("player")
	local FACTION = _G.UnitFactionGroup("player")
	local unit = {}
	local tmpGRealm = select(4, _G.GetGuildInfo("player"))

	unit.faction = FACTION
	unit.realm = REALM
	unit.name = PLAYER
	unit.money = (_G.GetMoney() or 0) - _G.GetCursorMoney() - _G.GetPlayerTradeMoney()
	unit.class = select(2, _G.UnitClass("player"))
	unit.race = select(2, _G.UnitRace("player"))
	unit.guid = _G.UnitGUID("player")
	unit.guild = _G.GetGuildInfo("player")
	if unit.guild then
		--we need to check for Normalized realm names that will cause issues since they are missing spaces and hyphens and won't match GetRealmName()
		unit.guildrealm = self:GetTrueRealmName(tmpGRealm or REALM)
	end
	unit.gender = _G.UnitSex("player")

	unit.guild = unit.guild and (unit.guild..'©')
	unit.realmKey = Unit.realmKey
	unit.rwsKey = Unit.rwsKey
	unit.lowerKey = Unit.lowerKey

	if not bypassDebug then
		Debug(BSYC_DL.TRACE, "GetPlayerInfo", PLAYER, REALM, FACTION, unit.class, unit.race, unit.guild, unit.guildrealm, tmpGRealm)
	end
	return unit
end

function Unit:isConnectedRealm(realm)
	if not realm then return false end
	if not Unit.realmKey then Unit:DoRealmCollection("isConnectedRealm") end

	realm = BROKEN_REALMS[realm] or realm
	realm = realm:gsub('(%l)(%u)', '%1 %2') -- names like Blade'sEdge to Blade's Edge

	if not RealmChk_CR[realm] then
		--check the stripped whitespace format Removed White Spaces or RWS
		realm = realm:gsub('[%p%c%s]', '') -- remove all punctuation characters, all control characters, and all whitespace characters 
		if not RealmChk_RWS[realm] then
			--check lowercase?
			realm = string.lower(realm)
			if not RealmChk_LC[realm] then
				return false
			end
		end
	end
	return true
end

function Unit:GetTrueRealmName(realm)
	if not realm then return "--UNKNOWN--" end
	if not Unit.realmKey then Unit:DoRealmCollection("GetTrueRealmName") end

	--for some reason they occasionally return the Normalized realm name instead of the true realm name. (see ticket #285)
	--in these situations the guild realms don't match because they may have a space or hyphen or something
	--we need to do checks for this to ensure we get the appropriate realm name

	if not RealmChk_CR[realm] then
		local origRealm = realm

		--it's not in our standard list of realms, so that is iffy we need to check for Normalized situations
		--if for some reason we STILL can't find the guild realm, then just store it as UNKNOWN to debug for the future

		--1) lets check for broken realms and incorrect spacing
		realm = BROKEN_REALMS[realm] or realm
		realm = realm:gsub('(%l)(%u)', '%1 %2') -- names like Blade'sEdge to Blade's Edge
		if RealmChk_CR[realm] then
			return realm
		end

		--2) lets do a quick RWS check
		realm = realm:gsub('[%p%c%s]', '') -- remove all punctuation characters, all control characters, and all whitespace characters 
		if RealmChk_RWS[realm] then
			return RealmChk_RWS[realm] --return original realm name
		end

		--3) lets check for lowercase
		realm = string.lower(realm)
		if RealmChk_LC[realm] then
			return RealmChk_LC[realm] --return original realm name
		end

		--4) they must have a guild on another server.  So return the unaltered origRealm
		return origRealm
	end

	return realm
end

function Unit:CompareRealms(sourceRealm, targetRealm)
	if not sourceRealm or not targetRealm then return false end
	if sourceRealm == targetRealm then return true end

	--before we do anything lets make everything lowercase
	sourceRealm = string.lower(sourceRealm)
	targetRealm = string.lower(targetRealm)
	if sourceRealm == targetRealm then return true end

	--now check broken realms
	sourceRealm = BROKEN_REALMS[sourceRealm] or sourceRealm
	sourceRealm = sourceRealm:gsub('(%l)(%u)', '%1 %2')
	targetRealm = BROKEN_REALMS[targetRealm] or targetRealm
	targetRealm = targetRealm:gsub('(%l)(%u)', '%1 %2')
	if sourceRealm == targetRealm then return true end

	--now lets do RWS checks
	sourceRealm = sourceRealm:gsub('[%p%c%s]', '')
	targetRealm = targetRealm:gsub('[%p%c%s]', '')
	if sourceRealm == targetRealm then return true end

	return false
end

function Unit:IsInBG()
	if GetNumBattlefieldScores and (GetNumBattlefieldScores() > 0) then
		return true
	end
	return false
end

function Unit:IsInArena()
	if not IsActiveBattlefieldArena then return false end
	local a, b = IsActiveBattlefieldArena()
	if not a then
		return false
	end
	return true
end

function Unit:InCombatLockdown()
	return self:IsInBG() or self:IsInArena() or InCombatLockdown() or UnitAffectingCombat("player") or (C_PetBattles and C_PetBattles.IsInBattle())
end
