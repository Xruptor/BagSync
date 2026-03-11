--[[
	tooltip.lua
		Tooltip module for BagSync

	BagSync - All Rights Reserved - (c) 2025
	License included with addon.

	Changes (2026-02-08):
	- Consolidated tooltip line rendering and ExtTip fallback handling to remove duplication in hot paths.
	- Reduced churn by reusing scratch tables, hoisting sort-mode validation, and avoiding per-call closures where practical.
	- Added defensive nil guards for tooltip access, colors, and enum tables to prevent rare tooltip errors without changing normal output.
	- Refactored TallyUnits DB-scan flow into helpers, precomputing allowed keys and clarifying cache/scan decisions.
	- Guarded __lastLink fast-path with a signature to prevent stale display when filters/options change.
	- Reused static allow-key lists for default (no-filter) scans and prebuilt sort comparators.
	- Prevented potential double-tally by suppressing post-call hooks if legacy hooks are already in use.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Tooltip = BSYC:NewModule("Tooltip")
local Unit = BSYC:GetModule("Unit")
local Data = BSYC:GetModule("Data")
local Utility = BSYC:GetModule("Utility")
local ExtTip = BSYC:GetModule("ExtTip")
local Scanner = BSYC:GetModule("Scanner")
local L = BSYC.L

local _G = _G
local type, tostring, tonumber, select = type, tostring, tonumber, select
local pairs = pairs
local str_format, str_len, str_lower, str_sub, str_match = string.format, string.len, string.lower, string.sub, string.match
local tinsert, tconcat, tsort = table.insert, table.concat, table.sort
local wipe = _G.wipe
local BreakUpLargeNumbers = _G.BreakUpLargeNumbers
local IsAltKeyDown, IsControlKeyDown, IsShiftKeyDown = _G.IsAltKeyDown, _G.IsControlKeyDown, _G.IsShiftKeyDown
local CreateTextureMarkup = _G.CreateTextureMarkup
local CreateAtlasMarkup = _G.CreateAtlasMarkup
local hooksecurefunc = _G.hooksecurefunc
local issecure = _G.issecure
local GetRealmName = _G.GetRealmName

local CURRENT_REALM = type(GetRealmName) == "function" and GetRealmName() or nil

local function GetCurrentRealm()
	if not CURRENT_REALM and type(GetRealmName) == "function" then
		CURRENT_REALM = GetRealmName()
	end
	return CURRENT_REALM or ""
end

local PERM_IGNORE = {
	[6948] = "Hearthstone",
	[110560] = "Garrison Hearthstone",
	[140192] = "Dalaran Hearthstone",
	[128353] = "Admiral's Compass",
	[141605] = "Flight Master's Whistle",
}

local SORT_MODES = {
	realm_character = true,
	character = true,
	class_character = true,
	totals = true,
	custom = true,
}

local FACTION_ICONS = BSYC.IsRetail and {
	Alliance = [[|TInterface\FriendsFrame\PlusManz-Alliance:16:16|t]],
	Horde = [[|TInterface\FriendsFrame\PlusManz-Horde:16:16|t]],
	Neutral = [[|TInterface\Icons\Achievement_worldevent_brewmaster:16:16|t]],
} or {
	Alliance = [[|TInterface\FriendsFrame\PlusManz-Alliance:16:16|t]],
	Horde = [[|TInterface\FriendsFrame\PlusManz-Horde:16:16|t]],
	Neutral = [[|TInterface\Icons\ability_seal:18|t]],
}

local NUMERIC_SCRATCH = {}

local RaceIDLookup = {}
local ClassIDLookup = {}

local function Debug(level, ...)
	if BSYC.DEBUG then BSYC.DEBUG(level, "Tooltip", ...) end
end

local function CanAccessObject(obj)
	if not obj then return false end
	if type(obj.IsForbidden) ~= "function" then return true end
	if type(issecure) ~= "function" then
		return not obj:IsForbidden()
	end
	return issecure() or not obj:IsForbidden()
end

local function comma_value(n)
	if not n or not tonumber(n) then return "?" end
	if BreakUpLargeNumbers then
		return tostring(BreakUpLargeNumbers(tonumber(n)))
	end
	return tostring(n)
end

--https://wowwiki-archive.fandom.com/wiki/User_defined_functions
local function RGBPercToHex(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	return str_format("%02x%02x%02x", r*255, g*255, b*255)
end

local function GetTotalForItem(data, itemID, useUniqueTotals)
	if not data or #data == 0 then return 0 end

	local total = 0
	for i = 1, #data do
		local entry = data[i]
		if entry then
			local link, count = BSYC:Split(entry, true)
			if useUniqueTotals then link = BSYC:GetShortItemID(link) end

			if link and link == itemID then
				total = total + (count or 1)
			end
		end
	end

	return total
end

local function WipeTable(tbl)
	if not tbl then return {} end
	if wipe then
		wipe(tbl)
	else
		for k in pairs(tbl) do
			tbl[k] = nil
		end
	end
	return tbl
end

local function ConcatNumeric(tbl, delim)
	if not tbl or #tbl == 0 then return "" end
	for i = 1, #tbl do
		NUMERIC_SCRATCH[i] = tostring(tbl[i])
	end
	local out = tconcat(NUMERIC_SCRATCH, delim or ",")
	WipeTable(NUMERIC_SCRATCH)
	return out
end

local function ShallowCopyArray(src)
	if not src or #src == 0 then return {} end
	local dst = {}
	for i = 1, #src do
		dst[i] = src[i]
	end
	return dst
end

local function AddUnitSpacer(list)
	tinsert(list, { colorized = " ", tallyString = " " })
end

local function AddUnitLine(list, left, right)
	tinsert(list, { colorized = left, tallyString = right })
end

local function AddTextSpacer(list)
	tinsert(list, { " ", " " })
end

local function AddTextLine(list, left, right)
	tinsert(list, { left, right })
end

local function SortStrKey(s)
	return str_lower(tostring(s or ""))
end

local function SortPinKey(entry)
	if BSYC.options.sortShowCurrentPlayerOnTop
		and entry
		and entry.unitObj
		and BSYC.db
		and entry.unitObj.data == BSYC.db.player
	then
		return 0
	end
	return 1
end

local function SortIsCharacter(unitObj)
	return unitObj and not unitObj.isGuild and not unitObj.isWarbandBank
end

local function SortClassKey(unitObj)
	if not unitObj or not unitObj.data or not unitObj.data.class then return "" end
	local token = unitObj.data.class
	local localized = _G.LOCALIZED_CLASS_NAMES_MALE and _G.LOCALIZED_CLASS_NAMES_MALE[token]
	return SortStrKey(localized or token)
end

local function BuildRaceIDLookup()
    if next(RaceIDLookup) then return end

    for id = 1, 300 do
        local info = C_CreatureInfo.GetRaceInfo(id)
        if info then
            if info.raceName then
                local r = info.raceName:upper()
                RaceIDLookup[r] = id
                RaceIDLookup[r:gsub("[^A-Z]", "")] = id
            end

            if info.clientFileString then
                local r = info.clientFileString:upper()
                RaceIDLookup[r] = id
                RaceIDLookup[r:gsub("[^A-Z]", "")] = id
            end
        end
    end
end

local function BuildClassIDLookup()
    if next(ClassIDLookup) then return end

    for id = 1, 30 do
        local info = C_CreatureInfo.GetClassInfo(id)
        if info then
            -- localized class name
            if info.className then
                local c = info.className:upper()
                ClassIDLookup[c] = id
                ClassIDLookup[c:gsub("[^A-Z]", "")] = id
            end

            -- file token (WARRIOR, DEATHKNIGHT, etc)
            if info.classFile then
                local c = info.classFile:upper()
                ClassIDLookup[c] = id
                ClassIDLookup[c:gsub("[^A-Z]", "")] = id
            end
        end
    end
end

local function BuildAllowKeys(allowList, scratch)
	-- Preserve legacy behavior: include all keys (values are treated as set membership).
	scratch = WipeTable(scratch or {})
	for k in pairs(allowList) do
		if k ~= "guild" and k ~= "warband" then
			scratch[#scratch + 1] = k
		end
	end
	return scratch
end

local function BuildAllowSignature(allowList, scratch)
	if not allowList then return "" end
	scratch = WipeTable(scratch or {})
	for k in pairs(allowList) do
		scratch[#scratch + 1] = k
	end
	tsort(scratch)
	return tconcat(scratch, ",")
end

local DEFAULT_ALLOW_KEYS
local function GetDefaultAllowKeys()
	-- static list derived from BSYC.DEFAULT_ALLOW_LIST (non-guild/warband keys)
	if not DEFAULT_ALLOW_KEYS then
		DEFAULT_ALLOW_KEYS = BuildAllowKeys(BSYC.DEFAULT_ALLOW_LIST)
	end
	return DEFAULT_ALLOW_KEYS
end

local function BuildTooltipSignature(self, opts, allowSig, advUnitList, showExtTip, doCurrentPlayerOnly, skipTally)
	local parts = WipeTable(self.__scratchSigParts or {})
	self.__scratchSigParts = parts

	parts[#parts + 1] = allowSig or "default"
	parts[#parts + 1] = advUnitList and tostring(advUnitList) or ""
	parts[#parts + 1] = showExtTip and "1" or "0"
	parts[#parts + 1] = doCurrentPlayerOnly and "1" or "0"
	parts[#parts + 1] = skipTally and "1" or "0"

	-- count-affecting options
	parts[#parts + 1] = opts.enableShowUniqueItemsTotals and "1" or "0"
	parts[#parts + 1] = opts.showCurrentCharacterOnly and "1" or "0"
	parts[#parts + 1] = opts.showBLCurrentCharacterOnly and "1" or "0"
	parts[#parts + 1] = opts.enableWhitelist and "1" or "0"

	-- display options (unit lines + extras)
	parts[#parts + 1] = opts.showTotal and "1" or "0"
	parts[#parts + 1] = opts.enableTooltipItemID and "1" or "0"
	parts[#parts + 1] = opts.enableSourceExpansion and "1" or "0"
	parts[#parts + 1] = opts.enableItemTypes and "1" or "0"
	parts[#parts + 1] = opts.enableTooltipSeparator and "1" or "0"
	parts[#parts + 1] = opts.singleCharLocations and "1" or "0"
	parts[#parts + 1] = opts.useIconLocations and "1" or "0"
	parts[#parts + 1] = opts.showEquipBagSlots and "1" or "0"
	parts[#parts + 1] = opts.showBankTabs and "1" or "0"
	parts[#parts + 1] = opts.showGuildTabs and "1" or "0"
	parts[#parts + 1] = opts.showWarbandTabs and "1" or "0"

	-- name and class color options
	parts[#parts + 1] = opts.enableUnitClass and "1" or "0"
	parts[#parts + 1] = opts.itemTotalsByClassColor and "1" or "0"
	parts[#parts + 1] = opts.enableTooltipGreenCheck and "1" or "0"
	parts[#parts + 1] = opts.showRaceIcons and "1" or "0"
	parts[#parts + 1] = opts.enableFactionIcons and "1" or "0"

	-- realm/tag options
	parts[#parts + 1] = opts.enableRealmNames and "1" or "0"
	parts[#parts + 1] = opts.enableRealmAstrickName and "1" or "0"
	parts[#parts + 1] = opts.enableRealmShortName and "1" or "0"
	parts[#parts + 1] = opts.enableCurrentRealmName and "1" or "0"
	parts[#parts + 1] = opts.enableCurrentRealmShortName and "1" or "0"
	parts[#parts + 1] = opts.enableRealmIDTags and "1" or "0"
	parts[#parts + 1] = opts.enableBNET and "1" or "0"
	parts[#parts + 1] = opts.enableCR and "1" or "0"

	return tconcat(parts, "|")
end

local function SortTotals(a, b)
	return a.count > b.count
end

local function SortCustom(a, b)
	local ap, bp = SortPinKey(a), SortPinKey(b)
	if ap ~= bp then return ap < bp end

	local aSort = a.unitObj and a.unitObj.data and a.unitObj.data.SortIndex
	local bSort = b.unitObj and b.unitObj.data and b.unitObj.data.SortIndex
	if aSort and bSort then
		return aSort < bSort
	end

	if a.sortIndex == b.sortIndex then
		if a.unitObj.realm == b.unitObj.realm then
			return a.unitObj.name < b.unitObj.name
		end
		return a.unitObj.realm < b.unitObj.realm
	end
	return a.sortIndex < b.sortIndex
end

local function SortCharacter(a, b)
	local ap, bp = SortPinKey(a), SortPinKey(b)
	if ap ~= bp then return ap < bp end

	local an, bn = SortStrKey(a.unitObj and a.unitObj.name), SortStrKey(b.unitObj and b.unitObj.name)
	if an == bn then
		return SortStrKey(a.unitObj and a.unitObj.realm) < SortStrKey(b.unitObj and b.unitObj.realm)
	end
	return an < bn
end

local function SortClassCharacter(a, b)
	local ap, bp = SortPinKey(a), SortPinKey(b)
	if ap ~= bp then return ap < bp end

	local aChar, bChar = SortIsCharacter(a.unitObj), SortIsCharacter(b.unitObj)
	if aChar ~= bChar then return aChar end -- characters first

	if aChar and bChar then
		local ac, bc = SortClassKey(a.unitObj), SortClassKey(b.unitObj)
		if ac == bc then
			local an, bn = SortStrKey(a.unitObj.name), SortStrKey(b.unitObj.name)
			if an == bn then
				return SortStrKey(a.unitObj.realm) < SortStrKey(b.unitObj.realm)
			end
			return an < bn
		end
		return ac < bc
	end

	-- non-characters: keep prior stable ordering
	if a.sortIndex == b.sortIndex then
		if a.unitObj.realm == b.unitObj.realm then
			return a.unitObj.name < b.unitObj.name
		end
		return a.unitObj.realm < b.unitObj.realm
	end
	return a.sortIndex < b.sortIndex
end

local function SortRealmCharacter(a, b)
	if a.sortIndex == b.sortIndex then
		if a.unitObj.realm == b.unitObj.realm then
			return a.unitObj.name < b.unitObj.name
		end
		return a.unitObj.realm < b.unitObj.realm
	end
	return a.sortIndex < b.sortIndex
end

local SORTERS = {
	totals = SortTotals,
	custom = SortCustom,
	character = SortCharacter,
	class_character = SortClassCharacter,
	realm_character = SortRealmCharacter,
}

local function ResolveAllowFlags(useFilters, allowList)
	if not useFilters then
		return true, true, true, true, true, true, true
	end
	return allowList.bag, allowList.bank, allowList.reagents, allowList.equip, allowList.auction, allowList.void, allowList.mailbox
end

local function ScanOtherUnits(self, ctx, allowKeys)
	local total = 0
	local advPlayerChk = false
	local advPlayerGuildChk = false
	local advUnitList = ctx.advUnitList
	local allowGuild = ctx.allowGuild
	local guildObj = ctx.guildObj
	local link = ctx.link
	local unitList = ctx.unitList
	local countList = ctx.countList

	for unitObj in Data:IterateUnits(false, advUnitList) do

		WipeTable(countList)
		local unitTotal = 0

		if not unitObj.isGuild then
			--Due to crafting items being used in reagents bank, or turning in quests with items in the bank, etc..
			--The cached item info for the current player would obviously be out of date until they returned to the bank to scan again.
			--In order to combat this, lets just get the realtime count for the currently logged in player every single time.
			--This is why we check for player name and realm below, we don't want to do anything in regards to the current player when the Database.
			if unitObj.data ~= BSYC.db.player then
				Debug(BSYC_DL.SL2, "TallyUnits", "[Unit]", unitObj.name, unitObj.realm)
				for i = 1, #allowKeys do
					unitTotal = unitTotal + self:AddItems(unitObj, link, allowKeys[i], countList)
				end
			elseif advUnitList then
				advPlayerChk = true
			end
		else
			--don't cache the players guild bank, lets get that in real time in case they put stuff in it
			if not guildObj or (unitObj.data ~= guildObj.data) then
				Debug(BSYC_DL.SL2, "TallyUnits", "[Guild]", unitObj.name, unitObj.realm)
				if allowGuild then
					unitTotal = unitTotal + self:AddItems(unitObj, link, "guild", countList)
				end
			elseif advUnitList then
				advPlayerGuildChk = true
			end
		end

		--only process the totals if we have something to work with
		if unitTotal > 0 then
			total = total + unitTotal
			--table variables gets passed as byRef
			self:UnitTotals(unitObj, countList, unitList, advUnitList)
		end
	end

	return total, advPlayerChk, advPlayerGuildChk
end

local function AddCurrentPlayer(self, ctx, advPlayerChk)
	if ctx.advUnitList and not advPlayerChk then return 0 end

	WipeTable(ctx.countList)
	local playerTotal = 0
	local playerObj = Data:GetPlayerObj(ctx.player)
	Debug(BSYC_DL.SL2, "TallyUnits", "|cFF4DD827[CurrentPlayer]|r", playerObj.name, playerObj.realm, ctx.link)

	local allowBag, allowBank, allowReagents, allowEquip, allowAuction, allowVoid, allowMailbox = ResolveAllowFlags(ctx.useFilters, ctx.allowList)
	local allowAnyBags = allowBag or allowBank or allowReagents

	local equipCount = 0
	if allowEquip or allowAnyBags then
		--grab the equip count as we need that below for an accurate count on the bags, bank and reagents
		equipCount = self:AddItems(playerObj, ctx.link, "equip", ctx.countList)
		if allowEquip then
			playerTotal = playerTotal + equipCount
		else
			ctx.countList.equip = 0
		end
	end

	--C_Item.GetItemCount does not work in the auction, void bank or mailbox, so grab it manually
	if allowAuction then playerTotal = playerTotal + self:AddItems(playerObj, ctx.link, "auction", ctx.countList) end
	if allowVoid then playerTotal = playerTotal + self:AddItems(playerObj, ctx.link, "void", ctx.countList) end
	if allowMailbox then playerTotal = playerTotal + self:AddItems(playerObj, ctx.link, "mailbox", ctx.countList) end

	--C_Item.GetItemCount does not work on battlepet links either, grab bag, bank and reagents
	if ctx.isBattlePet then
		if allowBag then playerTotal = playerTotal + self:AddItems(playerObj, ctx.link, "bag", ctx.countList) end
		if allowBank then playerTotal = playerTotal + self:AddItems(playerObj, ctx.link, "bank", ctx.countList) end
		if allowReagents then playerTotal = playerTotal + self:AddItems(playerObj, ctx.link, "reagents", ctx.countList) end
	else
		if allowAnyBags then
			local carryCount, bagCount, bankCount, regCount = 0, 0, 0, 0

			ctx.carriedCount = ctx.carriedCount or ((ctx.GetItemCount and ctx.GetItemCount(ctx.origLink)) or 0) --get the total amount the player is currently carrying (bags + equip)

			carryCount = ctx.carriedCount
			bagCount = carryCount - equipCount -- subtract the equipment count from the carry amount to get bag count

			if bagCount < 0 then bagCount = 0 end

			if ctx.IsReagentBankUnlocked and ctx.IsReagentBankUnlocked() then
				--C_Item.GetItemCount returns the bag count + reagent regardless of parameters.  So we have to subtract bag and reagents.  This does not include bank totals
				ctx.reagentTotalCount = ctx.reagentTotalCount or ((ctx.GetItemCount and ctx.GetItemCount(ctx.origLink, false, false, true, false)) or 0)

				regCount = ctx.reagentTotalCount
				regCount = regCount - carryCount
				if regCount < 0 then regCount = 0 end
			end

			--bankCount = C_Item.GetItemCount returns the bag + bank count regardless of parameters.  So we have to subtract the carry totals
			ctx.bankTotalCount = ctx.bankTotalCount or ((ctx.GetItemCount and ctx.GetItemCount(ctx.origLink, true, false, false, false)) or 0)

			bankCount = ctx.bankTotalCount
			bankCount = (bankCount - carryCount)
			if bankCount < 0 then bankCount = 0 end

			--now assign the values (check for disabled modules)
			if not ctx.tracking.bag then bagCount = 0 end
			if not ctx.tracking.bank then bankCount = 0 end
			if not ctx.tracking.reagents then regCount = 0 end

			if not allowBag then bagCount = 0 end
			if not allowBank then bankCount = 0 end
			if not allowReagents then regCount = 0 end

			if bagCount > 0 then
				self:GetEquipBags("bag", playerObj, ctx.link, ctx.countList)
			end
			if bankCount > 0 then
				self:GetEquipBags("bank", playerObj, ctx.link, ctx.countList)
			end

			if BSYC.IsBankTabsActive and ctx.opts.showBankTabs and allowBank then
				--we do this so we can grab the btabs, even if we use a real time count from GetItemCount.
				self:AddItems(playerObj, ctx.link, "bank", ctx.countList)
			end

			ctx.countList.bag = bagCount
			ctx.countList.bank = bankCount
			ctx.countList.reagents = regCount
			playerTotal = playerTotal + (bagCount + bankCount + regCount)
		end
	end

	if playerTotal > 0 then
		--table variables gets passed as byRef
		self:UnitTotals(playerObj, ctx.countList, ctx.unitList, ctx.advUnitList)
	end

	return playerTotal
end

local function AddCurrentPlayerGuild(self, ctx, advPlayerGuildChk)
	if not ctx.allowGuild or not ctx.guildObj then return 0 end
	if ctx.advUnitList and not advPlayerGuildChk then return 0 end

	Debug(BSYC_DL.SL2, "TallyUnits", "|cFF4DD827[CurrentPlayer-Guild]|r", ctx.player.guild, ctx.player.guildrealm)
	WipeTable(ctx.countList)
	local guildTotal = self:AddItems(ctx.guildObj, ctx.link, "guild", ctx.countList)
	if guildTotal > 0 then
		--table variables gets passed as byRef
		self:UnitTotals(ctx.guildObj, ctx.countList, ctx.unitList, ctx.advUnitList)
	end
	return guildTotal
end

local function AddWarband(self, ctx)
	if not ctx.warbandObj or not ctx.allowWarband then return 0 end

	Debug(BSYC_DL.SL2, "TallyUnits", "|cFF4DD827[Warband]|r")
	WipeTable(ctx.countList)
	local warbandTotal = 0

	if ctx.isBattlePet then
		warbandTotal = warbandTotal + self:AddItems(ctx.warbandObj, ctx.link, "warband", ctx.countList)
	else
		if ctx.opts.showWarbandTabs then
			--we do this so we can grab the wtabs, even if we use a real time count from GetItemCount.
			self:AddItems(ctx.warbandObj, ctx.link, "warband", ctx.countList)
		end

		ctx.carriedCount = ctx.carriedCount or ((ctx.GetItemCount and ctx.GetItemCount(ctx.origLink)) or 0) --get the total amount the player is currently carrying (bags + equip)
		ctx.warbandTotalCount = ctx.warbandTotalCount or ((ctx.GetItemCount and ctx.GetItemCount(ctx.origLink, false, false, false, true)) or 0)

		local carryCount = ctx.carriedCount
		local warbandCount = ctx.warbandTotalCount
		warbandCount = warbandCount - carryCount

		if not ctx.tracking.warband then warbandCount = 0 end
		--overwride the countList if we are grabbing tabs
		ctx.countList.warband = warbandCount
		warbandTotal = warbandTotal + warbandCount
	end

	if warbandTotal > 0 then
		--table variables gets passed as byRef
		self:UnitTotals(ctx.warbandObj, ctx.countList, ctx.unitList, ctx.advUnitList)
	end

	return warbandTotal
end

function Tooltip:HexColor(color, str)
	if color == nil then
		-- defensive: avoid nil color errors on edge cases
		return tostring(str)
	end
	if type(color) == "table" then
		return str_format("|cff%s%s|r", RGBPercToHex(color.r, color.g, color.b), tostring(str))
	end
	if type(color) ~= "string" then
		return tostring(str)
	end
	if #color == 8 then
		return str_format("|c%s%s|r", tostring(color), tostring(str))
	end
	return str_format("|cff%s%s|r", tostring(color), tostring(str))
end

function Tooltip:AddTooltipUnits(objTooltip, unitList, altColor)
	-- consolidated rendering; this replaces repeated line loops in multiple paths
	if not objTooltip or not unitList or #unitList == 0 or type(objTooltip.AddDoubleLine) ~= "function" then return end
	for i = 1, #unitList do
		local entry = unitList[i]
		if entry then
			local color
			if entry.unitObj then
				color = self:GetClassColor(entry.unitObj, 2, false, altColor)
			else
				color = altColor or BSYC.colors.first
			end
			objTooltip:AddDoubleLine(entry.colorized, entry.tallyString, color.r, color.g, color.b, color.r, color.g, color.b)
		end
	end
end

function Tooltip:AddTextLines(objTooltip, lineList)
	-- consolidated rendering for simple text lists (currency, etc.)
	if not objTooltip or not lineList or #lineList == 0 or type(objTooltip.AddDoubleLine) ~= "function" then return end
	for i = 1, #lineList do
		objTooltip:AddDoubleLine(lineList[i][1], lineList[i][2], 1, 1, 1, 1, 1, 1)
	end
end

function Tooltip:ShowExtTipWithUnitInline(objTooltip, extTip, unitList, addSeparator)
	if not objTooltip or not extTip or not unitList or #unitList == 0 or type(objTooltip.AddDoubleLine) ~= "function" then return end
	ExtTip:ApplyFont()
	extTip:Show()
	if not ExtTip:UpdateAnchor(objTooltip) then
		if addSeparator then
			objTooltip:AddDoubleLine(" ", " ")
		end
		self:AddTooltipUnits(objTooltip, unitList, BSYC.colors.total)
		objTooltip:Show()
	end
end

function Tooltip:ShowExtTipWithTextInline(objTooltip, extTip, lineList)
	if not objTooltip or not extTip or not lineList or #lineList == 0 or type(objTooltip.AddDoubleLine) ~= "function" then return end
	ExtTip:ApplyFont()
	extTip:Show()
	if not ExtTip:UpdateAnchor(objTooltip) then
		self:AddTextLines(objTooltip, lineList)
		objTooltip:Show()
	end
end

function Tooltip:GetItemTypeString(itemType, itemSubType, classID, subclassID)
	if not itemType or not itemSubType then return nil end

	local typeString = itemType.." | "..itemSubType
	-- Defensive: Enum.ItemClass can be nil on Classic; skip colorization if absent.
	local itemClassEnum = _G.Enum and _G.Enum.ItemClass
	if classID and itemClassEnum then
		--https://wowpedia.fandom.com/wiki/ItemType
		if classID == itemClassEnum.Questitem then
			typeString = Tooltip:HexColor("ffccef66", itemType).." | "..itemSubType
		elseif classID == itemClassEnum.Profession then
			typeString = Tooltip:HexColor("FF51B9E9", itemType).." | "..itemSubType
		elseif classID == itemClassEnum.Armor or classID == itemClassEnum.Weapon then
			typeString = Tooltip:HexColor("ff77ffff", itemType).." | "..itemSubType
		elseif classID == itemClassEnum.Consumable then
			typeString = Tooltip:HexColor("FF77F077", itemType).." | "..itemSubType
		elseif classID == itemClassEnum.Tradegoods then
			typeString = Tooltip:HexColor("FFFFD580", itemType).." | "..itemSubType
		elseif classID == itemClassEnum.Reagent then
			typeString = Tooltip:HexColor("ffff7777", itemType).." | "..itemSubType
		end
	end

	return typeString
end

function Tooltip:GetSortIndex(unitObj)
	if unitObj then
		local currentRealm = GetCurrentRealm()
		if BSYC.options.sortShowCurrentPlayerOnTop and unitObj.data == BSYC.db.player then
			return 1
		elseif not unitObj.isGuild and unitObj.realm == currentRealm then
			return 2
		elseif unitObj.isGuild and unitObj.realm == currentRealm then
			return 3
		elseif not unitObj.isGuild and unitObj.isConnectedRealm then
			return 4
		elseif unitObj.isGuild and unitObj.isConnectedRealm then
			return 5
		elseif not unitObj.isGuild then
			return 6
		elseif unitObj.isWarbandBank then
			--sort warband banks just above other server guilds
			return 7
		end
	end
	--other server guilds should be sorted last
	return 8
end

function Tooltip:GetIDFromRaceOrClass(unitObj, race, class)
	local rID, cID

	--build the tables if we don't have them arleady
	BuildRaceIDLookup()
	BuildClassIDLookup()

    -- Race lookup
    if race then
        race = race:upper()
		local raceStrip = race:gsub("[^A-Z]", "")
		rID = RaceIDLookup[race] or RaceIDLookup[raceStrip]
		if rID and not unitObj.data.race_id then unitObj.data.race_id = rID end
    end

    -- Class lookup
    if class then
        class = class:upper()
		local classStrip = class:gsub("[^A-Z]", "")
		cID = ClassIDLookup[class] or ClassIDLookup[classStrip]
		if cID and not unitObj.data.class_id then unitObj.data.class_id = cID end
    end

    return unitObj, rID, cID
end

--[[
    CreateTextureMarkup(filename, width, height, displayWidth, displayHeight, left, right, top, bottom, xOffset, yOffset)
      For Classic era with explicit texture coordinates
      Used in old BagSync code but not in current implementation

    CreateAtlasMarkup(atlas, displayWidth, displayHeight, xOffset, yOffset)
      For Retail atlas system with automatic formatting
      This is what old BagSync code used successfully

    Why CreateAtlasMarkup works:
    - MANUAL ATTEMPT FAILED: Tried to construct |T...|t strings from atlas info using C_Texture.GetAtlasInfo
    - Result: Black boxes displayed in tooltips (texture not rendering)
    - SUCCESS: CreateAtlasMarkup generates proper tooltip texture markup that renders correctly
    - The function handles internal conversion between atlas system and tooltip texture format

    Atlas System References:
    - https://warcraft.wiki.gg/wiki/AtlasID - Atlas system documentation
    - https://www.townlong-yak.com/framexml/go/CreateAtlasMarkup
]]
function Tooltip:GetRaceIcon(raceID, origRace, sex, size, xOffset, yOffset, useHiRez)
    local raceInfo = C_CreatureInfo.GetRaceInfo(raceID)
    if not raceInfo then
        return "|TInterface\\Icons\\INV_Misc_QuestionMark:16|t"
    end

    local race = raceInfo.clientFileString
    race = race:gsub("%s+", "")
    race = race:lower()

    local gender = (sex == 3) and "female" or "male"
    size = size or 16

    -- Blizzard incorrectly names some raceicon texture files, fix these
    --https://wago.tools/db2/UiTextureAtlasMember?filter%5BCommittedName%5D=raceicon
    local FIXED_RACE_ATLAS = {
        ["highmountaintauren"] = "highmountain",
        ["lightforgeddraenei"] = "lightforged",
        ["scourge"] = "undead",
        ["zandalaritroll"] = "zandalari",
        ["earthendwarf"] = "earthen",
		["harronir"] = "haranir",                -- Fallback for haranir, mispelling?
    }

    -- Atlas format variations to try for fallback security
    local atlasFormats = {
        {prefix = "raceicon128", suffix = ""},      -- High resolution
        {prefix = "raceicon64", suffix = ""},       -- Medium resolution
        {prefix = "raceicon", suffix = ""},          -- Low resolution
    }

    -- -- Get the correct race name (use fixed name if Blizzard named it wrong)
    local fixedRace = FIXED_RACE_ATLAS[race] or race

    -- Try all atlas format variations with the fixed race name using Blizzard's CreateAtlasMarkup
    for _, format in ipairs(atlasFormats) do
        local atlas = format.prefix.."-"..fixedRace.."-"..gender..format.suffix
        local info = C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)

        if info then
            -- Use Blizzard's CreateAtlasMarkup function for proper tooltip texture
            local raceMarkup = CreateAtlasMarkup(atlas, size, size, xOffset or 0, yOffset or 0)
            Debug(BSYC_DL.SL3, "GetRaceIcon-success", raceID, origRace, gender, size, xOffset, yOffset, useHiRez, atlas, raceMarkup)
            return raceMarkup
        end
    end

    -- Ultimate fallback for Classic: Achievement_Character icons
    -- Use CreateTextureMarkup for consistency with atlas approach
    -- https://www.townlong-yak.com/framexml/latest/Blizzard_SharedXMLBase/TextureUtil.lua#226

    -- Racial fallback icons for races that don't have Achievement_Character icons
    -- Based on Total RP 3's approach: https://github.com/Total-RP/Total-RP-3/blob/c5d90a4ca40eb4eef300d633ddf522e77cfc84a5/totalRP3/Resources/InterfaceIcons.lua#L86
    local RACIAL_FALLBACK_ICONS = {
        -- Allied races and races without Achievement_Character icons use racial abilities
        ["darkirondwarf"] = (sex == 3) and "ability_racial_foregedinflames"  or "ability_racial_fireblood",
        ["goblin"] = "ability_racial_rocketjump",
        ["nightborne"] = (sex == 3) and "ability_racial_masquerade" or "ability_racial_dispelillusions",
        ["voidelf"] = (sex == 3) and "ability_racial_preturnaturalcalm" or "ability_racial_entropicembrace",
        ["vulpera"] = "ability_racial_nosefortrouble",
        ["lightforgeddraenei"] = (sex == 3) and "achievement_alliedrace_lightforgeddraenei" or "ability_racial_finalverdict",
        ["highmountaintauren"] = (sex == 3) and "achievement_alliedrace_highmountaintauren" or "ability_racial_bullrush",
        ["magharorc"] = (sex == 3) and "achievement_character_orc_female_brn" or "achievement_character_orc_male_brn",
        ["mechagnome"] = (sex == 3) and "inv_plate_mechagnome_c_01helm" or "ability_racial_hyperorganiclightoriginator",
        ["kul_tiran"] = (sex == 3) and "ability_racial_childofthesea" or "achievement_boss_zuldazar_manceroy_mestrah",
        ["zandalaritroll"] = (sex == 3) and "inv_zandalarifemalehead" or "inv_zandalarimalehead",-- Use head icon fallback
        ["earthen"] = (sex == 3) and "ability_earthen_wideeyedwonder" or "achievement_dungeon_ulduarraid_irondwarf_01",
        ["harronir"] = (sex == 3) and "inv12_haranir_character_creation_female" or "inv12_haranir_character_creation_male",
        ["dracthyr"] = (sex == 3) and "inv_dracthyrhead01" or "inv_dracthyrhead02",
		["pandaren"] = (sex == 3) and "achievement_character_pandaren_female" or "achievement_guild_classypanda",
		["worgen"] = (sex == 3) and "ability_racial_viciousness" or "achievement_worganhead",
    }

    -- Races that DO have Achievement_Character icons (base/vanilla races)
	local RACES_WITH_ACHIEVEMENT_ICONS = {
		human = true,
		dwarf = true,
		nightElf = true,
		gnome = true,
		draenei = true,
		orc = true,
		undead = true,
		tauren = true,
		troll = true,
		bloodElf = true,
		-- Allied races don't have Achievement_Character icons
	}

    -- Use racial fallback icon if available, otherwise try Achievement_Character if race has it
    local fallbackIcon = RACIAL_FALLBACK_ICONS[race]
    local genderCap = (sex == 3) and "Female" or "Male"

    if fallbackIcon then
        -- Use racial ability icon as fallback
        local icon = "Interface\\Icons\\" .. fallbackIcon
        local tFile = CreateTextureMarkup(icon, 64, 64, size, size, 0, 1, 0, 1, xOffset or 0, yOffset or 0)

        Debug(BSYC_DL.SL3, "GetRaceIcon-racial-fallback", raceID, origRace, gender, size, xOffset, yOffset, useHiRez, icon, tFile)
        return tFile
	end

	local icon = "Interface\\Icons\\INV_Misc_QuestionMark"

	-- Only try Achievement_Character for races that actually have them
	if RACES_WITH_ACHIEVEMENT_ICONS[race] then
		icon = "Interface\\Icons\\Achievement_Character_" ..raceInfo.clientFileString.."_"..genderCap
	end

	local tFile = CreateTextureMarkup(icon, 64, 64, size, size, 0, 1, 0, 1, xOffset or 0, yOffset or 0)
	Debug(BSYC_DL.SL3, "GetRaceIcon-achievement-fallback", raceID, origRace, gender, size, xOffset, yOffset, useHiRez, icon, tFile)
	return tFile
end

function Tooltip:GetClassColor(unitObj, switch, bypass, altColor)
	if not unitObj then return altColor or BSYC.colors.first end
	if not unitObj.data or not unitObj.data.class then return altColor or BSYC.colors.first end

	local doChk = false
	if switch == 1 then
		doChk = BSYC.options.enableUnitClass
	elseif switch == 2 then
		doChk = BSYC.options.itemTotalsByClassColor
	end

	--adds support for depricated ClassColors / WeWantBlueShamans   Ticket #331
	local classColor = _G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[unitObj.data.class] or _G.RAID_CLASS_COLORS[unitObj.data.class]
	if bypass or (doChk and classColor) then
		return classColor
	end
	return altColor or BSYC.colors.first
end

function Tooltip:ColorizeUnit(unitObj, bypass, forceRealm, forceXRBNET, tagAtEnd)
	if not unitObj or not unitObj.data then return nil end

	local opts = BSYC.options
	local colors = BSYC.colors
	local tmpTag = ""
	local realm = unitObj.realm
	local realmTag = ""
	local currentRealm = GetCurrentRealm()

	--bypass: shows colorized names, checkmark, and faction icons but no CR or BNET tags
	--forceRealm: adds realm tags forcefully

	if not unitObj.isGuild and not unitObj.isWarbandBank then
		--first colorize by class color
		tmpTag = self:HexColor(self:GetClassColor(unitObj, 1, bypass), unitObj.name)

		--add green checkmark
		if unitObj.data == BSYC.db.player then
			if bypass or opts.enableTooltipGreenCheck then
				local ReadyCheck = [[|TInterface\RaidFrame\ReadyCheck-Ready:0|t]]
				tmpTag = ReadyCheck.." "..tmpTag
			end
		end

		--add race icons
		if bypass or opts.showRaceIcons then
			local raceID = unitObj.data.race_id or select(2, self:GetIDFromRaceOrClass(unitObj, unitObj.data.race, unitObj.data.class))
			local raceIcon = self:GetRaceIcon(raceID, unitObj.data.race, unitObj.data.gender, 16, 0, 0)
			if raceIcon ~= "" then
				tmpTag = raceIcon.." "..tmpTag
			end
		end

	elseif unitObj.isWarbandBank then
		tmpTag = self:HexColor(colors.warband, L.TooltipIcon_warband.." "..L.Tooltip_warband)
		bypass = true
	else
		--is guild
		tmpTag = self:HexColor(colors.guild, select(2, Unit:GetUnitAddress(unitObj.name)) )
	end

	--add faction icons
	if not unitObj.isWarbandBank and (bypass or unitObj.isGuild or opts.enableFactionIcons) then
		local factionIcon = FACTION_ICONS[unitObj.data.faction] or FACTION_ICONS.Neutral
		tmpTag = factionIcon.." "..tmpTag
	end

	--If we Bypass none of the CR or BNET stuff will be shown
	if bypass and (not forceRealm and not forceXRBNET) then
		Debug(BSYC_DL.INFO, "ColorizeUnit-Bypass", tmpTag)
		--since we Bypass don't show anything else just return what we got
		return tmpTag
	end

	local addStr = ""

	if opts.enableRealmNames then
		realm = unitObj.realm
	elseif opts.enableRealmAstrickName then
		realm = "*"
	elseif opts.enableRealmShortName then
		realm = str_sub(unitObj.realm, 1, 5)
	elseif forceRealm then
		realm = unitObj.realm
	else
		realm = ""
	end

	if opts.enableCurrentRealmName and unitObj.realm == currentRealm then
		realm = unitObj.realm
		if opts.enableCurrentRealmShortName then
			realm = str_sub(realm, 1, 5)
		end
		addStr = self:HexColor(colors.currentrealm, "["..realm.."]")
	end

	local delimiter = (realm ~= "" and " ") or ""

	if not unitObj.isXRGuild then
		if (forceXRBNET or opts.enableBNET) and not unitObj.isConnectedRealm then
			realmTag = (opts.enableRealmIDTags and L.TooltipBNET_Tag..delimiter) or ""
			if realm ~= "" or realmTag ~= "" then
				addStr = self:HexColor(colors.bnet, "["..realmTag..realm.."]")
			end
		end

		if (forceXRBNET or opts.enableCR) and unitObj.isConnectedRealm and unitObj.realm ~= currentRealm then
			realmTag = (opts.enableRealmIDTags and L.TooltipCR_Tag..delimiter) or ""
			if realm ~= "" or realmTag ~= "" then
				addStr = self:HexColor(colors.cr, "["..realmTag..realm.."]")
			end
		end
	else
		--if it's a connected realm guild the player belongs to, then show the CR tag.  This option only true if the CR and BNET options are off.
		realmTag = (opts.enableRealmIDTags and L.TooltipCR_Tag..delimiter) or ""
		realm = (#realm > 1 and realm) or "" --lets make sure we have more than just an asterick for the realm name otherwiose it would be [+] we want [+]
		addStr = self:HexColor(colors.cr, "[+"..realmTag..realm.."]")
	end

	--add the tags if we have anything to work with
	if addStr ~= "" then
		if tagAtEnd then
			tmpTag = tmpTag.." "..addStr
		else
			tmpTag = addStr.." "..tmpTag
		end
	end

	if not bypass then
		Debug(BSYC_DL.INFO, "ColorizeUnit", tmpTag, unitObj.realm, unitObj.isConnectedRealm, unitObj.isXRGuild, currentRealm)
	end
	return tmpTag
end

function Tooltip:DoSort(tblData)
	local mode = BSYC.options.tooltipSortMode
	if not SORT_MODES[mode] then
		-- avoid per-call table allocations; SORT_MODES is file-scope
		mode = "realm_character"
	end
	local sorter = SORTERS[mode] or SORTERS.realm_character
	tsort(tblData, sorter)

	return tblData
end

function Tooltip:GetEquipBags(target, unitObj, itemID, countList)
	if not target or not unitObj or not itemID then return 0 end
	if not unitObj.data.equipbags or not unitObj.data.equipbags[target] then return 0 end
	if target == "bank" and BSYC.IsBankTabsActive then return 0 end

	local useUniqueTotals = BSYC.options.enableShowUniqueItemsTotals

	local iCount = 0
	local tmpSlots = WipeTable(self.__scratchSlots or {})
	self.__scratchSlots = tmpSlots

	for i=1, #unitObj.data.equipbags[target] do
		local link, count, qOpts = BSYC:Split(unitObj.data.equipbags[target][i], false)
		if useUniqueTotals then link = BSYC:GetShortItemID(link) end
		if link then
			if link == itemID and qOpts and qOpts.bagslot then
				tinsert(tmpSlots, tostring(qOpts.bagslot))
				iCount = iCount + (count or 1)
			end
		end
	end

	if iCount > 0 then
		countList[target.."slots"] = self:HexColor(BSYC.colors.bagslots, " <"..tconcat(tmpSlots, ",")..">")
	elseif countList[target.."slots"] then
		countList[target.."slots"] = nil
	end

	return iCount
end

function Tooltip:AddItems(unitObj, itemID, target, countList)
	local total = 0
	if not unitObj or not itemID or not target or not countList then return total end
	if not unitObj.data then return total end

	local tracking = BSYC.tracking
	local useUniqueTotals = BSYC.options.enableShowUniqueItemsTotals

	if unitObj.data[target] and tracking[target] then
		if target == "bag" or target == "bank" or target == "reagents" then
			for bagID, bagData in pairs(unitObj.data[target] or {}) do
				local bTotal = GetTotalForItem(bagData, itemID, useUniqueTotals)
				total = total + bTotal

				if target == "bank" and BSYC.IsBankTabsActive and BSYC.options.showBankTabs and bTotal > 0 then
					if not countList.btab then countList.btab = {} end
					tinsert(countList.btab, bagID - 5) --subtract 5 to get it to start from 1 since bank tabs start at 6
				end
			end

			if target == "bag" or target == "bank" then
				total = total + self:GetEquipBags(target, unitObj, itemID, countList)
			end
		elseif target == "auction" then
			total = GetTotalForItem(unitObj.data[target].bag or {}, itemID, useUniqueTotals)
		elseif target == "equip" or target == "void" or target == "mailbox" then
			total = GetTotalForItem(unitObj.data[target] or {}, itemID, useUniqueTotals)
		end
	end
	if target == "guild" and tracking.guild then
		for tabID, tabData in pairs(unitObj.data.tabs or {}) do
			local tabCount = GetTotalForItem(tabData, itemID, useUniqueTotals)
			if tabCount > 0 and BSYC.options.showGuildTabs then
				if not countList.gtab then countList.gtab = {} end
				tinsert(countList.gtab, tabID)
			end
			total = total + tabCount
		end
	end

	if target == "warband" and tracking.warband then
		for tabID, tabData in pairs(unitObj.data.tabs or {}) do
			local tabCount = GetTotalForItem(tabData, itemID, useUniqueTotals)
			if tabCount > 0 and BSYC.options.showWarbandTabs then
				if not countList.wtab then countList.wtab = {} end
				tinsert(countList.wtab, tabID)
			end
			total = total + tabCount
		end
	end

	countList[target] = total

	return total
end

function Tooltip:GetCountString(colorType, dispType, srcType, srcCount, addStr, countColor)
	local desc = self:HexColor(colorType, L[dispType..srcType])
	local count = self:HexColor(countColor or BSYC.colors.second, comma_value(srcCount))
	local tmp = str_format("%s: %s", desc, count)..(addStr or "")
	return tmp
end

function Tooltip:UnitTotals(unitObj, countList, unitList, advUnitList)
	local total = 0
	local tallyCount = WipeTable(self.__scratchTallyCount or {})
	self.__scratchTallyCount = tallyCount
	local dispType = ""
	local opts = BSYC.options
	local colors = BSYC.colors
	local colorType = self:GetClassColor(unitObj, 2)
	local countColor = (opts.itemTotalsByClassColor and colorType) or colors.second

	if opts.singleCharLocations then
		dispType = "TooltipSmall_"
	elseif opts.useIconLocations then
		dispType = "TooltipIcon_"
	else
		dispType = "Tooltip_"
	end

	if ((countList["bag"] or 0) > 0) then
		total = total + countList["bag"]
		tinsert(tallyCount, self:GetCountString(colorType, dispType, "bag", countList["bag"], opts.showEquipBagSlots and countList["bagslots"], countColor))
	end
	if ((countList["bank"] or 0) > 0) then
		total = total + countList["bank"]

		local bTabStr = ""

		--check for warband tabs first
		if BSYC.IsBankTabsActive and opts.showBankTabs and countList["btab"] and #countList["btab"] > 0 then
			tsort(countList["btab"], function(a, b) return a < b end)
			bTabStr = ConcatNumeric(countList["btab"], ",")

			--check for bank tab
			if str_len(bTabStr) > 0 then
				bTabStr = self:HexColor(colors.banktabs, " ["..L.TooltipTabs.." "..bTabStr.."]")
			end
		else
			bTabStr = (opts.showEquipBagSlots and countList["bankslots"]) or nil
		end

		tinsert(tallyCount, self:GetCountString(colorType, dispType, "bank", countList["bank"], bTabStr, countColor))
	end
	if ((countList["reagents"] or 0) > 0) then
		total = total + countList["reagents"]
		tinsert(tallyCount, self:GetCountString(colorType, dispType, "reagents", countList["reagents"], nil, countColor))
	end
	if ((countList["equip"] or 0) > 0) then
		total = total + countList["equip"]
		tinsert(tallyCount, self:GetCountString(colorType, dispType, "equip", countList["equip"], nil, countColor))
	end
	if ((countList["mailbox"] or 0) > 0) then
		total = total + countList["mailbox"]
		tinsert(tallyCount, self:GetCountString(colorType, dispType, "mailbox", countList["mailbox"], nil, countColor))
	end
	if ((countList["void"] or 0) > 0) then
		total = total + countList["void"]
		tinsert(tallyCount, self:GetCountString(colorType, dispType, "void", countList["void"], nil, countColor))
	end
	if ((countList["auction"] or 0) > 0) then
		total = total + countList["auction"]
		tinsert(tallyCount, self:GetCountString(colorType, dispType, "auction", countList["auction"], nil, countColor))
	end
	if ((countList["guild"] or 0) > 0) then
		total = total + countList["guild"]
		local gTabStr = ""

		--check for guild tabs first
		if opts.showGuildTabs and countList["gtab"] and #countList["gtab"] > 0 then
			tsort(countList["gtab"], function(a, b) return a < b end)
			gTabStr = ConcatNumeric(countList["gtab"], ",")

			--check for guild tab
			if str_len(gTabStr) > 0 then
				gTabStr = self:HexColor(colors.guildtabs, " ["..L.TooltipTabs.." "..gTabStr.."]")
			end
		end

		tinsert(tallyCount, self:GetCountString(colorType, dispType, "guild", countList["guild"], gTabStr, countColor))
	end

	if ((countList["warband"] or 0) > 0) then
		total = total + countList["warband"]
		local wTabStr = ""

		--check for warband tabs first
		if opts.showWarbandTabs and countList["wtab"] and #countList["wtab"] > 0 then
			tsort(countList["wtab"], function(a, b) return a < b end)
			wTabStr = ConcatNumeric(countList["wtab"], ",")

			--check for warband tab
			if str_len(wTabStr) > 0 then
				wTabStr = self:HexColor(colors.warbandtabs, " ["..L.TooltipTabs.." "..wTabStr.."]")
			end
		end

		tinsert(tallyCount, self:GetCountString(colorType, dispType, "warband", countList["warband"], wTabStr, countColor))
	end

	if total < 1 then return end
	local tallyString = ""

	if (#tallyCount > 0) then
		--if we only have one entry, then display that and no need to sort or concat
		if #tallyCount == 1 then
			tallyString = tallyCount[1]
		else
			tsort(tallyCount)
			tallyString = self:HexColor(countColor, comma_value(total)).." ("..tconcat(tallyCount, L.TooltipDelimiter.." ")..")"
		end
	end
	if #tallyCount <= 0 or str_len(tallyString) < 1 then return end

	--add to list
	local doAdv = (advUnitList and true) or false
	local sortIndex = self:GetSortIndex(unitObj)
	local unitData = {
		unitObj=unitObj,
		colorized=self:ColorizeUnit(unitObj, false, false, doAdv),
		tallyString=tallyString,
		sortIndex=sortIndex,
		count=total
	}
	tinsert(unitList, unitData)

	Debug(BSYC_DL.SL2, "UnitTotals", unitObj.name, unitObj.realm, unitData.colorized, unitData.tallyString, total, sortIndex)
	return unitData
end

function Tooltip:ResetCache()
	if Data and Data.ResetTooltipCache then
		Data:ResetTooltipCache()
	elseif Data.__cache and Data.__cache.tooltip then
		Data.__cache.tooltip = {}
	end
end

function Tooltip:ResetLastLink()
	self.__lastLink = nil
	self.__lastSig = nil
	self.__lastCurrencyID = nil
end

function Tooltip:CheckModifier()
	if BSYC.options.tooltipModifer then
		local modKey = BSYC.options.tooltipModifer
		if modKey == "ALT" and not IsAltKeyDown() then
			return false
		elseif modKey == "CTRL" and not IsControlKeyDown() then
			return false
		elseif modKey == "SHIFT" and not IsShiftKeyDown() then
			return false
		end
	end
	return true
end

function Tooltip:TallyUnits(objTooltip, link, source, isBattlePet)
	local opts = BSYC.options
	if opts.enableTooltips == false then return end
	if not CanAccessObject(objTooltip) then return end
	if Scanner.isScanningGuild then return end --don't tally while we are scanning the Guildbank

	local tracking = BSYC.tracking
	local GetItemCount = BSYC.API and BSYC.API.GetItemCount
	local IsReagentBankUnlocked = _G.IsReagentBankUnlocked

	--check for modifier option only in windows that isn't BagSync search
	if not self:CheckModifier() and not objTooltip.isBSYCSearch then return end

	-- Legacy: keep objTooltip assignment for potential external consumers (internal code no longer uses it).
	Tooltip.objTooltip = objTooltip

	local showExtTip = ExtTip:Check(source, isBattlePet, objTooltip)
	local extTip = showExtTip and ExtTip:GetTip() or nil
	local skipTally = false

	--only show tooltips in search frame if the option is enabled
	if opts.tooltipOnlySearch and not objTooltip.isBSYCSearch then
		ExtTip:Hide()
		objTooltip:Show()
		return
	end

	local origLink = link --store the original unparsed link
	--remember when no count is provided to ParseItemLink, only the itemID is returned.  Integer or a string if it has bonusID
	link = BSYC:ParseItemLink(link)
	link = BSYC:Split(link, true) --if we are parsing a database entry, return only the itemID portion

	--we do this because the itemID portion can be something like 190368::::::::::::5:8115:7946:6652:7579:1491::::::
	local shortID = BSYC:GetShortItemID(link)

	--we want to make sure the origLink for BattlePets is always the fakeID for parsing through cache below
	if isBattlePet then origLink = shortID end

	--make sure we have something to work with
	if not link or not shortID then
		ExtTip:Hide()
		objTooltip:Show()
		Debug(BSYC_DL.WARN, "TallyUnits", "NoLink", origLink, source, isBattlePet)
		return
	end

	--check blacklist
	local personalBlacklist = false
	local shortNum = tonumber(shortID)

	if shortNum and (PERM_IGNORE[shortNum] or BSYC.db.blacklist[shortNum]) then
		if BSYC.db.blacklist[shortNum] then
			--don't use this on perm ignores only personal blacklist
			skipTally = not opts.showBLCurrentCharacterOnly
			personalBlacklist = true
		else
			skipTally = true
		end
		Debug(BSYC_DL.SL3, "TallyUnits", "|cFFe454fd[Blacklist]|r", link, shortID, personalBlacklist, opts.showBLCurrentCharacterOnly)
	end
	--check whitelist (blocks all items except those found in whitelist)
	if opts.enableWhitelist then
		if not shortNum or not BSYC.db.whitelist[shortNum] then
			skipTally = true
			Debug(BSYC_DL.SL3, "TallyUnits", "|cFFe454fd[Whitelist]|r", link, shortID)
		end
	end

	--short the shortID and ignore all BonusID's and stats
	if opts.enableShowUniqueItemsTotals then link = shortID end

	local grandTotal = 0
	local unitList = {}
	local countList = WipeTable(self.__scratchCountList or {})
	self.__scratchCountList = countList
	local player = Unit:GetPlayerInfo()
	local guildObj = Data:GetPlayerGuildObj(player)
	local warbandObj = Data:GetWarbandBankObj()

	--only display search filters results in the BagSync search window, but make sure to show tooltips regularly outside of that by checking isBSYCSearch
	local advUnitList = not skipTally and objTooltip.isBSYCSearch and BSYC.advUnitList
	local advAllowList = not skipTally and objTooltip.isBSYCSearch and BSYC.advAllowList
	local useFilters = advAllowList ~= nil
	local allowList = (useFilters and advAllowList) or BSYC.DEFAULT_ALLOW_LIST

	-- inline allow-list checks avoid allocating a per-call closure
	local allowGuild = not useFilters or allowList.guild
	local allowWarband = not useFilters or allowList.warband
	local turnOffCache = opts.debug and opts.debug.enable and opts.debug.cache or false
	local doCurrentPlayerOnly = opts.showCurrentCharacterOnly or (opts.showBLCurrentCharacterOnly and personalBlacklist)
	local cacheTooltip = Data.__cache and Data.__cache.tooltip
	local cacheEntry = cacheTooltip and cacheTooltip[origLink]
	local advPlayerChk = false
	local advPlayerGuildChk = false
	local ctx = {
		opts = opts,
		tracking = tracking,
		GetItemCount = GetItemCount,
		IsReagentBankUnlocked = IsReagentBankUnlocked,
		link = link,
		origLink = origLink,
		shortID = shortID,
		isBattlePet = isBattlePet,
		advUnitList = advUnitList,
		advAllowList = advAllowList,
		useFilters = useFilters,
		allowList = allowList,
		allowGuild = allowGuild,
		allowWarband = allowWarband,
		turnOffCache = turnOffCache,
		doCurrentPlayerOnly = doCurrentPlayerOnly,
		cacheEntry = cacheEntry,
		countList = countList,
		unitList = unitList,
		player = player,
		guildObj = guildObj,
		warbandObj = warbandObj,
	}

	self.__scratchAllowSig = self.__scratchAllowSig or {}
	local allowSig = useFilters and BuildAllowSignature(allowList, self.__scratchAllowSig) or "default"
	local tooltipSig = BuildTooltipSignature(self, opts, allowSig, advUnitList, showExtTip, doCurrentPlayerOnly, skipTally)

	--check if we already did the item, then display the previous information, use the unparsed link to verify
	--reuse last tooltip only when link and signature match (prevents stale output when options/filters change)
	if self.__lastLink and self.__lastLink == origLink and self.__lastSig == tooltipSig then
		if self.__lastTally and #self.__lastTally > 0 then
			if showExtTip then
				self:AddTooltipUnits(extTip, self.__lastTally, BSYC.colors.total)
			else
				self:AddTooltipUnits(objTooltip, self.__lastTally, BSYC.colors.total)
			end
			objTooltip:Show()
			if showExtTip then
				self:ShowExtTipWithUnitInline(objTooltip, extTip, self.__lastTally, opts.enableTooltipSeparator and #self.__lastTally > 0)
			end
		end
		objTooltip.__tooltipUpdated = true
		return
	end

	Debug(BSYC_DL.SL2, "TallyUnits", "|cFFe454fd[Item]|r", link, shortID, origLink, skipTally, advUnitList, turnOffCache, doCurrentPlayerOnly)

	--DB TOOLTIP COUNTS
	-------------------
	if advUnitList or not skipTally then

		--OTHER PLAYERS AND GUILDS
		-----------------
		--CACHE CHECK
		--NOTE: This cache check is ONLY for units (guild, players) that isn't related to the current player.  Since that data doesn't really change we can cache those lines
		--For the player however, we always want to grab the latest information.  So once it's grabbed we can do a small local cache for that using __lastTally
		--Search Filters should always be processed and not stored in the cache
		local shouldScanOtherUnits = not doCurrentPlayerOnly and (turnOffCache or advUnitList or useFilters or not cacheEntry)
		if shouldScanOtherUnits then

			local allowKeys
			if useFilters then
				allowKeys = BuildAllowKeys(allowList, self.__scratchAllowKeys)
				self.__scratchAllowKeys = allowKeys
			else
				allowKeys = GetDefaultAllowKeys()
			end

			local otherTotal
			otherTotal, advPlayerChk, advPlayerGuildChk = ScanOtherUnits(self, ctx, allowKeys)
			grandTotal = grandTotal + otherTotal

			--do not cache if we are viewing a search filters list, otherwise it won't display everything normally
			--finally, only cache if we have something to work with
			if not turnOffCache and not advUnitList and not useFilters then
				--store it in the cache (shallow copy to avoid deep-copying DB references)
				local cachedUnitList = (grandTotal > 0 and ShallowCopyArray(unitList)) or {}
				if Data and Data.SetTooltipCache then
					--This will add it to our tooltip cache, it will check to see if the tooltip cache is reached, if so it removes the top most entry to insert the new one
					--this is done at EnforceTooltipCacheCap()
					Data:SetTooltipCache(origLink, cachedUnitList, grandTotal)
				else
					--NOTE:  This is a fallback ONLY if Data module doesn't load and there is a failure to get SetTooltipCache()
					Data.__cache.tooltip[origLink] = Data.__cache.tooltip[origLink] or {}
					Data.__cache.tooltip[origLink].unitList = cachedUnitList
					Data.__cache.tooltip[origLink].grandTotal = grandTotal
				end
			end
		elseif cacheEntry and not doCurrentPlayerOnly then
			--use cached results from previous DB searches; copy array so we can append current-player data safely
			unitList = ShallowCopyArray(cacheEntry.unitList)
			ctx.unitList = unitList
			grandTotal = cacheEntry.grandTotal or 0
			Debug(BSYC_DL.INFO, "TallyUnits", "|cFF09DBE0CacheUsed|r", origLink)
		end

		Debug(BSYC_DL.SL2, "TallyUnits", "|cFF4DD827[AdvChk]|r", advUnitList, advPlayerChk, advPlayerGuildChk)

		--CURRENT PLAYER
		-----------------
		if not advUnitList or advPlayerChk then
			local playerTotal = AddCurrentPlayer(self, ctx, advPlayerChk)
			if playerTotal > 0 then
				grandTotal = grandTotal + playerTotal
			end
		end

		--CURRENT PLAYER GUILD
		--We do this separately so that the guild has it's own line in the unitList and not included inline with the player character
		--We also want to do this in real time and not cache, otherwise they may put stuff in their guild bank which will not be reflected in a cache
		-----------------
		local guildTotal = AddCurrentPlayerGuild(self, ctx, advPlayerGuildChk)
		if guildTotal > 0 then
			grandTotal = grandTotal + guildTotal
		end

		--Warband Bank can updated frequently, so we need to collect in real time and not cached
		local warbandTotal = AddWarband(self, ctx)
		if warbandTotal > 0 then
			grandTotal = grandTotal + warbandTotal
		end

		--only sort items if we have something to work with
		if #unitList > 0 then
			unitList = self:DoSort(unitList)
		end
	end

	--check for blacklist (showBLCurrentCharacterOnly)
	if opts.showBLCurrentCharacterOnly and personalBlacklist then
		tinsert(unitList, 1, { colorized="|cffff7d0a["..L.Blacklist.."]|r", tallyString=" "} )
	end

	--EXTRA OPTIONAL DISPLAYS
	-------------------------
	local desc, value = "", ""
	local addSeparator = false

	--add [Total] if we have more than one unit to work with
	if not skipTally and opts.showTotal and grandTotal > 0 and #unitList > 1 then
		--add a separator after the character list
		AddUnitSpacer(unitList)

		desc = self:HexColor(BSYC.colors.total, L.TooltipTotal)
		value = self:HexColor(BSYC.colors.second, comma_value(grandTotal))
		AddUnitLine(unitList, desc, value)
	end

	--add ItemID
	if opts.enableTooltipItemID and shortID then
		desc = self:HexColor(BSYC.colors.itemid, L.TooltipItemID)
		value = self:HexColor(BSYC.colors.second, shortID)
		if isBattlePet then
			desc = str_format("|cFFCA9BF7%s|r ", L.TooltipFakeID)
		end
		if not addSeparator then
			tinsert(unitList, 1, { colorized=" ", tallyString=" "} )
			addSeparator = true
		end
		tinsert(unitList, 1, { colorized=desc, tallyString=value} )
	end

	--don't do expansion or itemtype information for battlepets
	if not isBattlePet and not BSYC:IsBattlePetFakeID(shortID) then
		--add expansion
		if BSYC.IsRetail and opts.enableSourceExpansion and shortID then
			desc = self:HexColor(BSYC.colors.expansion, L.TooltipExpansion)
			local expacID
			if Data.__cache.items[shortID] then
				expacID = Data.__cache.items[shortID].expacID
			else
				local getItemInfo = BSYC.API and BSYC.API.GetItemInfo
				expacID = getItemInfo and select(15, getItemInfo(shortID))
			end
			value = self:HexColor(BSYC.colors.second, (expacID and _G["EXPANSION_NAME"..expacID]) or "?")

			if not addSeparator then
				tinsert(unitList, 1, { colorized=" ", tallyString=" "} )
				addSeparator = true
			end
			tinsert(unitList, 1, { colorized=desc, tallyString=value} )
		end
		--add item types
		if opts.enableItemTypes and shortID then
			local itemType, itemSubType, _, _, _, _, classID, subclassID
			if Data.__cache.items[shortID] then
				itemType = Data.__cache.items[shortID].itemType
				itemSubType = Data.__cache.items[shortID].itemSubType
				classID = Data.__cache.items[shortID].classID
				subclassID = Data.__cache.items[shortID].subclassID
			else
				local getItemInfo = BSYC.API and BSYC.API.GetItemInfo
				if getItemInfo then
					itemType, itemSubType, _, _, _, _, classID, subclassID = select(6, getItemInfo(shortID))
				end
			end
			local typeString = Tooltip:GetItemTypeString(itemType, itemSubType, classID, subclassID)

			if typeString then
				desc = self:HexColor(BSYC.colors.itemtypes, L.TooltipItemType)
				value = self:HexColor(BSYC.colors.second, typeString)

				if not addSeparator then
					tinsert(unitList, 1, { colorized=" ", tallyString=" "} )
					addSeparator = true
				end
				tinsert(unitList, 1, { colorized=desc, tallyString=value} )
			end
		end
	end

	--add separator if enabled and only if we have something to work with
	if not showExtTip and opts.enableTooltipSeparator and #unitList > 0 then
		tinsert(unitList, 1, { colorized=" ", tallyString=" "} )
	end

	--finally display it
	if showExtTip then
		self:AddTooltipUnits(extTip, unitList, BSYC.colors.total)
	else
		self:AddTooltipUnits(objTooltip, unitList, BSYC.colors.total)
	end

	--this is only a local cache for the current tooltip and will be reset on bag updates, it is not the same as Data.__cache.tooltip
	self.__lastTally = unitList
	self.__lastLink = origLink
	self.__lastSig = tooltipSig

	objTooltip.__tooltipUpdated = true
	objTooltip:Show()

	if showExtTip then
		if #unitList > 0 then
			self:ShowExtTipWithUnitInline(objTooltip, extTip, unitList, opts.enableTooltipSeparator and #unitList > 0)
		else
			ExtTip:Hide()
		end
	end

	local WLChk = (opts.enableWhitelist and "WL-ON") or "WL-OFF"
	Debug(BSYC_DL.INFO, "|cFF52D386TallyUnits|r", link, shortID, source, isBattlePet, grandTotal, WLChk)
end

function Tooltip:CurrencyTooltip(objTooltip, currencyName, currencyIcon, currencyID, source)
	local opts = BSYC.options
	if not BSYC.tracking.currency then return end
	if opts.enableCurrencyWindowTooltipData == false and source ~= "bagsync_currency" then return end

	--check for modifier option
	if not self:CheckModifier() and source ~= "bagsync_currency" then return end
	if not CanAccessObject(objTooltip) then return end

	currencyID = tonumber(currencyID) --make sure it's a number we are working with and not a string
	if not currencyID then return end

	-- Legacy: keep objTooltip assignment for potential external consumers (internal code no longer uses it).
	Tooltip.objTooltip = objTooltip

	local showExtTip = ExtTip:Check(source, false, objTooltip)
	local extTip = showExtTip and ExtTip:GetTip() or nil

	--if we already did the currency, then display the previous information, use the unparsed link to verify
	if self.__lastCurrencyID and self.__lastCurrencyID == currencyID then
		if self.__lastCurrencyTally and #self.__lastCurrencyTally > 0 then
			if showExtTip then
				self:AddTextLines(extTip, self.__lastCurrencyTally)
			else
				self:AddTextLines(objTooltip, self.__lastCurrencyTally)
			end
			objTooltip:Show()
			if showExtTip then
				self:ShowExtTipWithTextInline(objTooltip, extTip, self.__lastCurrencyTally)
			end
		end
		objTooltip.__tooltipUpdated = true
		return
	end

	Debug(BSYC_DL.INFO, "CurrencyTooltip", currencyName, currencyIcon, currencyID, source, BSYC.tracking.currency)

	--loop through our characters
	local usrData = WipeTable(self.__scratchCurrencyData or {})
	self.__scratchCurrencyData = usrData
	local grandTotal = 0

	self.__lastCurrencyID = currencyID
	self.__lastCurrencyTally = {}

	local tenderCheck = currencyID == 2032 or false

	for unitObj in Data:IterateUnits() do
		if not unitObj.isGuild and unitObj.data.currency and unitObj.data.currency[currencyID] and unitObj.data.currency[currencyID].count > 0 then
			--check for "Trader's Tender" which is currencyID 2032.  Only display it once for the current player.
			--that currency is account-wide.
			local doTender = (tenderCheck and unitObj.data == BSYC.db.player) or false

			if not tenderCheck or doTender then
				local colorized = self:ColorizeUnit(unitObj)
				local sortIndex = self:GetSortIndex(unitObj)
				local count = unitObj.data.currency[currencyID].count
				grandTotal = grandTotal + count

				if doTender then
					local warbandObj = Data:GetWarbandBankObj()
					if warbandObj then
						colorized = Tooltip:ColorizeUnit(warbandObj, true, false, false, false)
						sortIndex = Tooltip:GetSortIndex(warbandObj)
						count = L.TooltipIcon_warband.." "..count
					end
				end

				tinsert(usrData, {
					unitObj = unitObj,
					colorized = colorized,
					sortIndex = sortIndex,
					count = count
				})
			end
		end
	end

	--sort
	usrData = self:DoSort(usrData)

	local displayList = {}

	for i=1, #usrData do
		if usrData[i].count then
			AddTextLine(displayList, usrData[i].colorized, comma_value(usrData[i].count))
		end
	end
	if #usrData <= 0 then
		AddTextLine(displayList, NONE, " ")
	end

	--add [Total]
	if opts.showTotal and grandTotal > 0 and #displayList > 1 then
		--add a separator
		AddTextSpacer(displayList)
		local desc = self:HexColor(BSYC.colors.total, L.TooltipTotal)
		local value = self:HexColor(BSYC.colors.second, comma_value(grandTotal))
		AddTextLine(displayList, desc, value)
	end

	if opts.enableTooltipItemID and currencyID then
		local desc = self:HexColor(BSYC.colors.itemid, L.TooltipCurrencyID)
		local value = self:HexColor(BSYC.colors.second, currencyID)
		tinsert(displayList, 1, { " ", " " })
		tinsert(displayList, 1, { desc, value })
	end

	--finally display it
	if showExtTip then
		self:AddTextLines(extTip, displayList)
	else
		self:AddTextLines(objTooltip, displayList)
	end

	self.__lastCurrencyTally = displayList

	objTooltip.__tooltipUpdated = true
	objTooltip:Show()
	if showExtTip then
		self:ShowExtTipWithTextInline(objTooltip, extTip, displayList)
	end
end

local function IsPrimaryTooltip(tooltip)
	return tooltip == _G.GameTooltip or tooltip == _G.EmbeddedItemTooltip or tooltip == _G.ItemRefTooltip
end

local function HandleTooltipSetItem(tooltip, data)
	if not Utility:IsSafeTable(data) then return end
	if not IsPrimaryTooltip(tooltip) then return end
	if tooltip.__tooltipUpdated then return end

	local link
	if data.guid then
		local C_Item = _G.C_Item
		if C_Item and C_Item.GetItemLinkByGUID then
			link = C_Item.GetItemLinkByGUID(data.guid)
		end
	elseif data.hyperlink then
		link = data.hyperlink

		local shortID = tonumber(BSYC:GetShortItemID(link))
		if data.id and shortID and data.id ~= shortID then
			--if the data.id doesn't match the shortID it's probably a pattern, schematic, etc..
			--This is because the hyperlink is overwritten during the args process.
			--Pattern hyperlinks are usally args3 but get overwritten when they get to args7 that has the hyperlink of the item being crafted.
			--Instead the pattern/recipe/schematic is returned in the data.id, because that is the only thing not overwritten
			link = data.id
		end
	end

	if link then
		Tooltip:TallyUnits(tooltip, link, "OnTooltipSetItem")
	end
end

local function HandleTooltipSetCurrency(tooltip, data)
	if not Utility:IsSafeTable(data) then return end
	if not IsPrimaryTooltip(tooltip) then return end
	if tooltip.__tooltipUpdated then return end

	local link = data.id or data.hyperlink
	local currencyID = BSYC:GetShortCurrencyID(link)
	if currencyID then
		--WOTLK still uses the old API functions, check for it
		local getCurrencyInfo = BSYC.API and BSYC.API.GetCurrencyInfo
		local currencyData = getCurrencyInfo and getCurrencyInfo(currencyID)
		if currencyData and not Utility:IsSafeTable(currencyData) then
			currencyData = nil
		end
		if currencyData then
			Tooltip:CurrencyTooltip(tooltip, currencyData.name, currencyData.iconFileID, currencyID, "OnTooltipSetCurrency")
		end
	end
end

-- Global hook flags:
-- tooltipPostHooksRegistered: post-call hooks are global and only need registration once.
-- tooltipUsingLegacyHooks: we failed to register post-call hooks and must use legacy HookScript path.
local tooltipPostHooksRegistered = false
local tooltipUsingLegacyHooks = false

local function RegisterTooltipPostHooks()
	-- If we've already fallen back, don't try to register post-hooks again.
	if tooltipUsingLegacyHooks then return false end
	-- Post-call hooks are global (not per-tooltip), so only register once.
	if tooltipPostHooksRegistered then return true end
	local C_TooltipInfo = _G.C_TooltipInfo
	local TooltipDataProcessor = _G.TooltipDataProcessor
	local Enum = _G.Enum
	if not C_TooltipInfo or not TooltipDataProcessor or not Enum or not Enum.TooltipDataType then
		return false
	end

	-- Global post-call hooks: TooltipDataProcessor will call these for any tooltip.
	tooltipPostHooksRegistered = true
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, HandleTooltipSetItem)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Currency, HandleTooltipSetCurrency)
	return true
end

local arkAlreadyHooked = false
local hookedTooltips = setmetatable({}, { __mode = "k" })

function Tooltip:HookTooltip(objTooltip)
	--if the tooltip doesn't exist, chances are it's the BattlePetTooltip and they are on Classic or WOTLK
	if not objTooltip then return end
	if hookedTooltips[objTooltip] then return end -- avoid double-hooking if called twice
	hookedTooltips[objTooltip] = true

	Debug(BSYC_DL.INFO, "HookTooltip", objTooltip)

	--MORE INFO (https://wowpedia.fandom.com/wiki/Category:API_namespaces/C_TooltipInfo)
	--https://wowpedia.fandom.com/wiki/Patch_10.0.2/API_changes#Tooltip_Changes
	--https://github.com/tomrus88/BlizzardInterfaceCode/blob/e4385aa29a69121b3a53850a8b2fcece9553892e/Interface/SharedXML/Tooltip/TooltipDataHandler.lua
	--https://wowpedia.fandom.com/wiki/Patch_10.0.2/API_changes

	objTooltip:HookScript("OnHide", function(self)
		self.__tooltipUpdated = false
		ExtTip:OnTooltipHide()
	end)

	local battlePetTooltip = _G.BattlePetTooltip
	local floatingBattlePetTooltip = _G.FloatingBattlePetTooltip
	local isBattlePet = (objTooltip == battlePetTooltip or objTooltip == floatingBattlePetTooltip)

	--the battlepet tooltips don't use this, so check for it
	if not isBattlePet then
		objTooltip:HookScript("OnTooltipCleared", function(self)
			--this gets called repeatedly on some occasions. Do not reset Tooltip cache here at all
			self.__tooltipUpdated = false
		end)
	else
		--this is required for the battlepet tooltips, otherwise it will flood the tooltip with data
		objTooltip:HookScript("OnShow", function(self)
			if self.__tooltipUpdated then return end
		end)

		--add support for ArkInventory (Fixes #231)
		if ArkInventory and ArkInventory.API and ArkInventory.API.CustomBattlePetTooltipReady then
			if not arkAlreadyHooked then
				hooksecurefunc(ArkInventory.API, "CustomBattlePetTooltipReady", function(tooltip, link)
					if tooltip.__tooltipUpdated then return end
					if link then
						Tooltip:TallyUnits(tooltip, link, "ArkInventory", true)
					end
				end)
				arkAlreadyHooked = true
			end
		else
			--BattlePetToolTip_Show
			if battlePetTooltip and objTooltip == battlePetTooltip then
				hooksecurefunc("BattlePetToolTip_Show", function(speciesID, level, breedQuality, maxHealth, power, speed, name)
					if objTooltip.__tooltipUpdated then return end
					if speciesID then
						local fakeID = BSYC:CreateFakeID(nil, nil, speciesID, level, breedQuality, maxHealth, power, speed, name)
						if fakeID then
							Tooltip:TallyUnits(objTooltip, fakeID, "BattlePetToolTip_Show", true)
						end
					end
				end)
			end
			--FloatingBattlePet_Show
			if floatingBattlePetTooltip and objTooltip == floatingBattlePetTooltip then
				hooksecurefunc("FloatingBattlePet_Show", function(speciesID, level, breedQuality, maxHealth, power, speed, name)
					if objTooltip.__tooltipUpdated then return end
					if speciesID then
						local fakeID = BSYC:CreateFakeID(nil, nil, speciesID, level, breedQuality, maxHealth, power, speed, name)
						if fakeID then
							Tooltip:TallyUnits(objTooltip, fakeID, "FloatingBattlePet_Show", true)
						end
					end
				end)
			end
		end
	end

	if _G.C_TooltipInfo then
		-- If available, use the global post-call hooks (covers all tooltips without per-tooltip scripts).
		if RegisterTooltipPostHooks() then
			return
		end
		-- If post-hooks can't be registered, switch to legacy HookScript for this tooltip
		-- and mark legacy mode so we don't retry post-hook registration later.
		tooltipUsingLegacyHooks = true
	end

	-- Legacy (pre-C_TooltipInfo) hooks
	if not isBattlePet then
		objTooltip:HookScript("OnTooltipSetItem", function(self)
			if self.__tooltipUpdated then return end
			local name, link = self:GetItem()
			if link then
				--sometimes the link is an empty link with the name being |h[]|h, its a bug with GetItem()
				--so lets check for that
				local linkName = str_match(link, "|h%[(.-)%]|h")
				if not linkName or str_len(linkName) < 1 then return nil end -- we don't want to store or process it

				Tooltip:TallyUnits(self, link, "OnTooltipSetItem")
			end
		end)
	end

	if objTooltip.SetQuestLogItem then
		hooksecurefunc(objTooltip, "SetQuestLogItem", function(self, itemType, index)
			if self.__tooltipUpdated then return end
			local link = _G.GetQuestLogItemLink(itemType, index)
			if link then
				Tooltip:TallyUnits(self, link, "SetQuestLogItem")
			end
		end)
	end
	if objTooltip.SetQuestItem then
		hooksecurefunc(objTooltip, "SetQuestItem", function(self, itemType, index)
			if self.__tooltipUpdated then return end
			local link = _G.GetQuestItemLink(itemType, index)
			if link then
				Tooltip:TallyUnits(self, link, "SetQuestItem")
			end
		end)
	end

	--C_CurrencyInfo.GetCurrencyListInfo
	--https://www.townlong-yak.com/framexml/live/Blizzard_TokenUI/Blizzard_TokenUI.lua#383
	if objTooltip.SetCurrencyToken then
		hooksecurefunc(objTooltip, "SetCurrencyToken", function(self, currencyIndex)
			local getCurrencyListLink = BSYC.API and BSYC.API.GetCurrencyListLink
			local getCurrencyInfo = BSYC.API and BSYC.API.GetCurrencyInfo
			local link = getCurrencyListLink and getCurrencyListLink(currencyIndex)
			if link then
				local currencyID = BSYC:GetShortCurrencyID(link)

				if currencyID then
					--WOTLK still uses the old API functions, check for it
					local currencyData = getCurrencyInfo and getCurrencyInfo(currencyID)
					if currencyData and currencyData.name and currencyData.iconFileID then
						Tooltip:CurrencyTooltip(objTooltip, currencyData.name, currencyData.iconFileID, currencyID, "SetCurrencyToken")
					end
				end
			end
		end)
	end

	--only parse CraftFrame when it's not the RETAIL but Classic and TBC, because this was changed to TradeSkillUI on retail
	if objTooltip.SetCraftItem then
		hooksecurefunc(objTooltip, "SetCraftItem", function(self, index, reagent)
			if self.__tooltipUpdated then return end
			local _, _, count = _G.GetCraftReagentInfo(index, reagent)
			--YOU NEED to do the above or it will return an empty link!
			local link = _G.GetCraftReagentItemLink(index, reagent)
			if link then
				Tooltip:TallyUnits(self, link, "SetCraftItem")
			end
		end)
	end
end

function Tooltip:OnEnable()
	Debug(BSYC_DL.INFO, "OnEnable")

	self:HookTooltip(_G.GameTooltip)
	self:HookTooltip(_G.ItemRefTooltip)
	self:HookTooltip(_G.EmbeddedItemTooltip)
	self:HookTooltip(_G.BattlePetTooltip)
	self:HookTooltip(_G.FloatingBattlePetTooltip)
end
