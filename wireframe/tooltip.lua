--[[
	tooltip.lua
		Tooltip module for BagSync

	BagSync - All Rights Reserved - (c) 2025
	License included with addon.

--]]

local BSYC = select(2, ...)
local Tooltip = BSYC:NewModule("Tooltip")
local Unit = BSYC:GetModule("Unit")
local Data = BSYC:GetModule("Data")
local Utility = BSYC:GetModule("Utility")
local ExtTip = BSYC:GetModule("ExtTip")
local Scanner = BSYC:GetModule("Scanner")
local L = BSYC.L

-- Cache globals at file scope for performance
local _G = _G
local type, tostring, tonumber, select = type, tostring, tonumber, select
local pairs = pairs
local str_format, str_len, str_lower, str_sub, str_match = string.format, string.len, string.lower, string.sub, string.match
local tinsert, tconcat, tsort = table.insert, table.concat, table.sort
local wipe = wipe
local BreakUpLargeNumbers = BreakUpLargeNumbers
local IsAltKeyDown, IsControlKeyDown, IsShiftKeyDown = IsAltKeyDown, IsControlKeyDown, IsShiftKeyDown
local CreateTextureMarkup = CreateTextureMarkup
local CreateAtlasMarkup = CreateAtlasMarkup
local hooksecurefunc = hooksecurefunc
local issecure = issecure
local GetRealmName = GetRealmName

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
	wipe(tbl)
	return tbl
end

local function ConcatNumeric(tbl, delim)
	if not tbl or #tbl == 0 then return "" end
	for i = 1, #tbl do
		NUMERIC_SCRATCH[i] = tostring(tbl[i])
	end
	local out = tconcat(NUMERIC_SCRATCH, delim or ",")
	wipe(NUMERIC_SCRATCH)
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
			if info.className then
				local c = info.className:upper()
				ClassIDLookup[c] = id
				ClassIDLookup[c:gsub("[^A-Z]", "")] = id
			end

			if info.classFile then
				local c = info.classFile:upper()
				ClassIDLookup[c] = id
				ClassIDLookup[c:gsub("[^A-Z]", "")] = id
			end
		end
	end
end

local function BuildAllowKeys(allowList, scratch)
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
	if not DEFAULT_ALLOW_KEYS then
		DEFAULT_ALLOW_KEYS = BuildAllowKeys(BSYC.DEFAULT_ALLOW_LIST)
	end
	return DEFAULT_ALLOW_KEYS
end

-- Tooltip signature option mapping (eliminates 48-line repetitive function)
local TOOLTIP_SIG_OPTIONS = {
	-- Count-affecting options
	enableShowUniqueItemsTotals = true,
	showCurrentCharacterOnly = true,
	showBLCurrentCharacterOnly = true,
	enableWhitelist = true,
	-- Display options
	showTotal = true,
	enableTooltipItemID = true,
	enableSourceExpansion = true,
	enableItemTypes = true,
	enableTooltipSeparator = true,
	singleCharLocations = true,
	useIconLocations = true,
	showEquipBagSlots = true,
	showBankTabs = true,
	showGuildTabs = true,
	showWarbandTabs = true,
	-- Name and class color options
	enableUnitClass = true,
	itemTotalsByClassColor = true,
	enableTooltipGreenCheck = true,
	showRaceIcons = true,
	enableFactionIcons = true,
	-- Realm/tag options
	enableRealmNames = true,
	enableRealmAstrickName = true,
	enableRealmShortName = true,
	enableCurrentRealmName = true,
	enableCurrentRealmShortName = true,
	enableRealmIDTags = true,
	enableBNET = true,
	enableCR = true,
}

local function BuildTooltipSignature(self, opts, allowSig, advUnitList, showExtTip, doCurrentPlayerOnly, skipTally)
	local parts = WipeTable(self.__scratchSigParts or {})
	self.__scratchSigParts = parts

	parts[#parts + 1] = allowSig or "default"
	parts[#parts + 1] = advUnitList and tostring(advUnitList) or ""
	parts[#parts + 1] = showExtTip and "1" or "0"
	parts[#parts + 1] = doCurrentPlayerOnly and "1" or "0"
	parts[#parts + 1] = skipTally and "1" or "0"

	-- Use TOOLTIP_SIG_OPTIONS mapping to eliminate 30+ lines of repetition
	for option in pairs(TOOLTIP_SIG_OPTIONS) do
		parts[#parts + 1] = opts[option] and "1" or "0"
	end

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
	if aChar ~= bChar then return aChar end

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
			if unitObj.data ~= BSYC.db.player then
				Debug(BSYC_DL.SL2, "TallyUnits", "[Unit]", unitObj.name, unitObj.realm)
				for i = 1, #allowKeys do
					unitTotal = unitTotal + self:AddItems(unitObj, link, allowKeys[i], countList)
				end
			elseif advUnitList then
				advPlayerChk = true
			end
		else
			if not guildObj or (unitObj.data ~= guildObj.data) then
				Debug(BSYC_DL.SL2, "TallyUnits", "[Guild]", unitObj.name, unitObj.realm)
				if allowGuild then
					unitTotal = unitTotal + self:AddItems(unitObj, link, "guild", countList)
				end
			elseif advUnitList then
				advPlayerGuildChk = true
			end
		end

		if unitTotal > 0 then
			total = total + unitTotal
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
	local opts = ctx.opts
	local tracking = ctx.tracking
	Debug(BSYC_DL.SL2, "TallyUnits", "|cFF4DD827[CurrentPlayer]|r", playerObj.name, playerObj.realm, ctx.link)

	local allowBag, allowBank, allowReagents, allowEquip, allowAuction, allowVoid, allowMailbox = ResolveAllowFlags(ctx.useFilters, ctx.allowList)
	local allowAnyBags = allowBag or allowBank or allowReagents

	local equipCount = 0
	if allowEquip or allowAnyBags then
		equipCount = self:AddItems(playerObj, ctx.link, "equip", ctx.countList)
		if allowEquip then
			playerTotal = playerTotal + equipCount
		else
			ctx.countList.equip = 0
		end
	end

	if allowAuction then playerTotal = playerTotal + self:AddItems(playerObj, ctx.link, "auction", ctx.countList) end
	if allowVoid then playerTotal = playerTotal + self:AddItems(playerObj, ctx.link, "void", ctx.countList) end
	if allowMailbox then playerTotal = playerTotal + self:AddItems(playerObj, ctx.link, "mailbox", ctx.countList) end

	if ctx.isBattlePet then
		if allowBag then playerTotal = playerTotal + self:AddItems(playerObj, ctx.link, "bag", ctx.countList) end
		if allowBank then playerTotal = playerTotal + self:AddItems(playerObj, ctx.link, "bank", ctx.countList) end
		if allowReagents then playerTotal = playerTotal + self:AddItems(playerObj, ctx.link, "reagents", ctx.countList) end
	else
		if allowAnyBags then
			local carryCount, bagCount, bankCount, regCount = 0, 0, 0, 0

			ctx.carriedCount = ctx.carriedCount or ((ctx.GetItemCount and ctx.GetItemCount(ctx.origLink)) or 0)

			carryCount = ctx.carriedCount
			bagCount = carryCount - equipCount

			if bagCount < 0 then bagCount = 0 end

			if ctx.IsReagentBankUnlocked and ctx.IsReagentBankUnlocked() then
				ctx.reagentTotalCount = ctx.reagentTotalCount or ((ctx.GetItemCount and ctx.GetItemCount(ctx.origLink, false, false, true, false)) or 0)

				regCount = ctx.reagentTotalCount
				regCount = regCount - carryCount
				if regCount < 0 then regCount = 0 end
			end

			ctx.bankTotalCount = ctx.bankTotalCount or ((ctx.GetItemCount and ctx.GetItemCount(ctx.origLink, true, false, false, false)) or 0)

			bankCount = ctx.bankTotalCount
			bankCount = (bankCount - carryCount)
			if bankCount < 0 then bankCount = 0 end

			if not tracking.bag then bagCount = 0 end
			if not tracking.bank then bankCount = 0 end
			if not tracking.reagents then regCount = 0 end

			if not allowBag then bagCount = 0 end
			if not allowBank then bankCount = 0 end
			if not allowReagents then regCount = 0 end

			if bagCount > 0 then
				self:GetEquipBags("bag", playerObj, ctx.link, ctx.countList)
			end
			if bankCount > 0 then
				self:GetEquipBags("bank", playerObj, ctx.link, ctx.countList)
			end

			if BSYC.IsBankTabsActive and opts.showBankTabs and allowBank then
				self:AddItems(playerObj, ctx.link, "bank", ctx.countList)
			end

			ctx.countList.bag = bagCount
			ctx.countList.bank = bankCount
			ctx.countList.reagents = regCount
			playerTotal = playerTotal + (bagCount + bankCount + regCount)
		end
	end

	if playerTotal > 0 then
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
		self:UnitTotals(ctx.guildObj, ctx.countList, ctx.unitList, ctx.advUnitList)
	end
	return guildTotal
end

local function AddWarband(self, ctx)
	if not ctx.warbandObj or not ctx.allowWarband then return 0 end

	Debug(BSYC_DL.SL2, "TallyUnits", "|cFF4DD827[Warband]|r")
	WipeTable(ctx.countList)
	local warbandTotal = 0
	local opts = ctx.opts
	local tracking = ctx.tracking

	if ctx.isBattlePet then
		warbandTotal = warbandTotal + self:AddItems(ctx.warbandObj, ctx.link, "warband", ctx.countList)
	else
		if opts.showWarbandTabs then
			self:AddItems(ctx.warbandObj, ctx.link, "warband", ctx.countList)
		end

		ctx.carriedCount = ctx.carriedCount or ((ctx.GetItemCount and ctx.GetItemCount(ctx.origLink)) or 0)
		ctx.warbandTotalCount = ctx.warbandTotalCount or ((ctx.GetItemCount and ctx.GetItemCount(ctx.origLink, false, false, false, true)) or 0)

		local carryCount = ctx.carriedCount
		local warbandCount = ctx.warbandTotalCount
		warbandCount = warbandCount - carryCount

		if not tracking.warband then warbandCount = 0 end
		ctx.countList.warband = warbandCount
		warbandTotal = warbandTotal + warbandCount
	end

	if warbandTotal > 0 then
		self:UnitTotals(ctx.warbandObj, ctx.countList, ctx.unitList, ctx.advUnitList)
	end

	return warbandTotal
end

function Tooltip:HexColor(color, str)
	if color == nil then
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
	if not objTooltip or not lineList or #lineList == 0 or type(objTooltip.AddDoubleLine) ~= "function" then return end
	for i = 1, #lineList do
		objTooltip:AddDoubleLine(lineList[i][1], lineList[i][2], 1, 1, 1, 1, 1, 1)
	end
end

function Tooltip:ShowExtTipWithUnitInline(objTooltip, extTip, unitList, addSeparator, isBattlePet)
	if not objTooltip or not extTip or not unitList or #unitList == 0 then return end

	ExtTip:ApplyFont()
	extTip:Show()

	local anchorResult = ExtTip:UpdateAnchor(objTooltip, isBattlePet)

	if not anchorResult then
		if type(objTooltip.AddDoubleLine) == "function" then
			if addSeparator then
				objTooltip:AddDoubleLine(" ", " ")
			end
			self:AddTooltipUnits(objTooltip, unitList, BSYC.colors.total)
			objTooltip:Show()
		end
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
	local itemClassEnum = _G.Enum and _G.Enum.ItemClass
	if classID and itemClassEnum then
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
		elseif unitObj.isWarbandBank then
			return 7
		elseif not unitObj.isGuild then
			return 6
		end
	end
	return 8
end

function Tooltip:GetIDFromRaceOrClass(unitObj, race, class)
	local rID, cID

	BuildRaceIDLookup()
	BuildClassIDLookup()

	if race then
		race = race:upper()
		local raceStrip = race:gsub("[^A-Z]", "")
		rID = RaceIDLookup[race] or RaceIDLookup[raceStrip]
		if rID and not unitObj.data.race_id then unitObj.data.race_id = rID end
	end

	if class then
		class = class:upper()
		local classStrip = class:gsub("[^A-Z]", "")
		cID = ClassIDLookup[class] or ClassIDLookup[classStrip]
		if cID and not unitObj.data.class_id then unitObj.data.class_id = cID end
	end

	return unitObj, rID, cID
end

-- Race icon atlas name fixes (Blizzard misnames some)
local FIXED_RACE_ATLAS = {
	["highmountaintauren"] = "highmountain",
	["lightforgeddraenei"] = "lightforged",
	["scourge"] = "undead",
	["zandalaritroll"] = "zandalari",
	["earthendwarf"] = "earthen",
	["harronir"] = "haranir",
	["kul_tiran"] = "kultiran",
	["visage"] = "dracthyrvisage",
	["maghar"] = "magharorc",
}

-- Racial fallback icons for allied races (indexed by race name, returns table with male/female icons)
local RACIAL_FALLBACK_ICONS = {
	["darkirondwarf"] = {male = "ability_racial_fireblood", female = "ability_racial_foregedinflames"},
	["goblin"] = "ability_racial_rocketjump",
	["nightborne"] = {male = "ability_racial_dispelillusions", female = "ability_racial_masquerade"},
	["voidelf"] = {male = "ability_racial_entropicembrace", female = "ability_racial_preturnaturalcalm"},
	["vulpera"] = "ability_racial_nosefortrouble",
	["lightforged"] = {male = "ability_racial_finalverdict", female = "achievement_alliedrace_lightforgeddraenei"},
	["highmountain"] = {male = "ability_racial_bullrush", female = "achievement_alliedrace_highmountaintauren"},
	["magharorc"] = {male = "achievement_character_orc_male_brn", female = "achievement_character_orc_female_brn"},
	["mechagnome"] = {male = "ability_racial_hyperorganiclightoriginator", female = "inv_plate_mechagnome_c_01helm"},
	["kultiran"] = {male = "achievement_boss_zuldazar_manceroy_mestrah", female = "ability_racial_childofthesea"},
	["zandalari"] = {male = "inv_zandalarimalehead", female = "inv_zandalarifemalehead"},
	["earthen"] = {male = "achievement_dungeon_ulduarraid_irondwarf_01", female = "ability_earthen_wideeyedwonder"},
	["haranir"] = {male = "inv12_haranir_character_creation_male", female = "inv12_haranir_character_creation_female"},
	["dracthyr"] = {male = "inv_dracthyrhead02", female = "inv_dracthyrhead01"},
	["pandaren"] = {male = "achievement_guild_classypanda", female = "achievement_character_pandaren_female"},
	["worgen"] = {male = "achievement_worganhead", female = "ability_racial_viciousness"},
	["dracthyrvisage"] = {male = "inv_dracthyrhead02", female = "inv_dracthyrhead01"},
	["visage"] = {male = "inv_dracthyrhead02", female = "inv_dracthyrhead01"},
}

local function GetRacialFallbackIcon(raceName, sex)
	local iconData = RACIAL_FALLBACK_ICONS[raceName]
	if type(iconData) == "table" then
		return (sex == 3) and iconData.female or iconData.male
	end
	return iconData
end

-- Base races with Achievement_Character icons
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
}

local function TryGetRaceIconAtlas(raceID, race, gender, size, xOffset, yOffset, useHiRez)
	local raceInfo = C_CreatureInfo.GetRaceInfo(raceID)
	if not raceInfo then return nil end

	local clientFile = raceInfo.clientFileString:gsub("%s+", ""):lower()
	local genderStr = (gender == 3) and "female" or "male"
	local fixedRace = FIXED_RACE_ATLAS[clientFile] or clientFile

	-- Try atlas format variations
	for _, prefix in ipairs({"raceicon128", "raceicon64", "raceicon"}) do
		local atlas = prefix.."-"..fixedRace.."-"..genderStr
		if C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
			local markup = CreateAtlasMarkup(atlas, size or 16, size or 16, xOffset or 0, yOffset or 0)
			Debug(BSYC_DL.SL3, "GetRaceIcon-success", raceID, race, genderStr, size, xOffset, yOffset, useHiRez, atlas, markup)
			return markup
		end
	end

	return nil
end

local function GetRaceIconFallback(raceID, race, gender, size, xOffset, yOffset)
	local raceInfo = C_CreatureInfo.GetRaceInfo(raceID)
	if not raceInfo then return nil end

	local clientFile = raceInfo.clientFileString:gsub("%s+", ""):lower()
	local genderCap = (gender == 3) and "Female" or "Male"
	local fixedRace = FIXED_RACE_ATLAS[clientFile] or clientFile

	-- Try racial ability fallback
	local fallbackIcon = GetRacialFallbackIcon(fixedRace, gender)
	if fallbackIcon then
		local icon = "Interface\\Icons\\" .. fallbackIcon
		return CreateTextureMarkup(icon, 64, 64, size or 16, size or 16, 0, 1, 0, 1, xOffset or 0, yOffset or 0)
	end

	-- Try Achievement_Character icon for base races
	if RACES_WITH_ACHIEVEMENT_ICONS[clientFile] then
		local icon = "Interface\\Icons\\Achievement_Character_" .. raceInfo.clientFileString .. "_" .. genderCap
		return CreateTextureMarkup(icon, 64, 64, size or 16, size or 16, 0, 1, 0, 1, xOffset or 0, yOffset or 0)
	end

	return nil
end

function Tooltip:GetRaceIcon(raceID, origRace, sex, size, xOffset, yOffset, useHiRez)
	-- Try atlas first (Retail)
	local atlasResult = TryGetRaceIconAtlas(raceID, origRace, sex, size, xOffset, yOffset, useHiRez)
	if atlasResult then return atlasResult end

	-- Fall back to texture markup
	local fallbackResult = GetRaceIconFallback(raceID, origRace, sex, size, xOffset, yOffset)
	if fallbackResult then
		Debug(BSYC_DL.SL3, "GetRaceIcon-fallback", raceID, origRace, sex, size, xOffset, yOffset, useHiRez, fallbackResult)
		return fallbackResult
	end

	-- Ultimate fallback
	Debug(BSYC_DL.SL3, "GetRaceIcon-questionmark", raceID, origRace, sex, size, xOffset, yOffset, useHiRez)
	return "|TInterface\\Icons\\INV_Misc_QuestionMark:16|t"
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

	local classColor = _G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[unitObj.data.class] or _G.RAID_CLASS_COLORS[unitObj.data.class]
	if bypass or (doChk and classColor) then
		return classColor
	end
	return altColor or BSYC.colors.first
end

-- Build realm tag for display
local function BuildRealmTag(realm, opts, currentRealm, isXRGuild, isConnectedRealm, unitRealm)
	local realmTag = ""
	local delimiter = (realm ~= "" and " ") or ""

	if not isXRGuild then
		if (opts.enableBNET) and not isConnectedRealm then
			realmTag = (opts.enableRealmIDTags and L.TooltipBNET_Tag..delimiter) or ""
			return realmTag, realm, BSYC.colors.bnet
		end

		-- use unitRealm (raw name) not realm (display value) to avoid same-realm chars being tagged [CR] when realm display is disabled
		if (opts.enableCR) and isConnectedRealm and unitRealm ~= currentRealm then
			realmTag = (opts.enableRealmIDTags and L.TooltipCR_Tag..delimiter) or ""
			return realmTag, realm, BSYC.colors.cr
		end
	else
		realmTag = (opts.enableRealmIDTags and L.TooltipCR_Tag..delimiter) or ""
		realm = (#realm > 1 and realm) or ""
		return "+"..realmTag, realm, BSYC.colors.cr
	end

	return realmTag, realm, nil
end

function Tooltip:ColorizeUnit(unitObj, bypass, forceRealm, forceXRBNET, tagAtEnd)
	if not unitObj or not unitObj.data then return nil end

	local opts = BSYC.options
	local colors = BSYC.colors
	local tmpTag = ""
	local realm = unitObj.realm
	local currentRealm = GetCurrentRealm()

	if not unitObj.isGuild and not unitObj.isWarbandBank then
		tmpTag = self:HexColor(self:GetClassColor(unitObj, 1, bypass), unitObj.name)

		if unitObj.data == BSYC.db.player then
			if bypass or opts.enableTooltipGreenCheck then
				local ReadyCheck = [[|TInterface\RaidFrame\ReadyCheck-Ready:0|t]]
				tmpTag = ReadyCheck.." "..tmpTag
			end
		end

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
		tmpTag = self:HexColor(colors.guild, select(2, Unit:GetUnitAddress(unitObj.name)))
	end

	if not unitObj.isWarbandBank and (bypass or unitObj.isGuild or opts.enableFactionIcons) then
		local factionIcon = FACTION_ICONS[unitObj.data.faction] or FACTION_ICONS.Neutral
		tmpTag = factionIcon.." "..tmpTag
	end

	if bypass and (not forceRealm and not forceXRBNET) then
		Debug(BSYC_DL.INFO, "ColorizeUnit-Bypass", tmpTag)
		return tmpTag
	end

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

	local addStr = ""

	if opts.enableCurrentRealmName and unitObj.realm == currentRealm then
		realm = unitObj.realm
		if opts.enableCurrentRealmShortName then
			realm = str_sub(realm, 1, 5)
		end
		addStr = self:HexColor(colors.currentrealm, "["..realm.."]")
	else
		local realmTag, realmValue, realmColor = BuildRealmTag(realm, opts, currentRealm, unitObj.isXRGuild, unitObj.isConnectedRealm, unitObj.realm)
		if realmTag ~= "" or realmValue ~= "" then
			addStr = self:HexColor(realmColor or colors.cr, "["..realmTag..realmValue.."]")
		end
	end

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
					tinsert(countList.btab, bagID - 5)
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

		if BSYC.IsBankTabsActive and opts.showBankTabs and countList["btab"] and #countList["btab"] > 0 then
			tsort(countList["btab"], function(a, b) return a < b end)
			bTabStr = ConcatNumeric(countList["btab"], ",")

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

		if opts.showGuildTabs and countList["gtab"] and #countList["gtab"] > 0 then
			tsort(countList["gtab"], function(a, b) return a < b end)
			gTabStr = ConcatNumeric(countList["gtab"], ",")

			if str_len(gTabStr) > 0 then
				gTabStr = self:HexColor(colors.guildtabs, " ["..L.TooltipTabs.." "..gTabStr.."]")
			end
		end

		tinsert(tallyCount, self:GetCountString(colorType, dispType, "guild", countList["guild"], gTabStr, countColor))
	end

	if ((countList["warband"] or 0) > 0) then
		total = total + countList["warband"]
		local wTabStr = ""

		if opts.showWarbandTabs and countList["wtab"] and #countList["wtab"] > 0 then
			tsort(countList["wtab"], function(a, b) return a < b end)
			wTabStr = ConcatNumeric(countList["wtab"], ",")

			if str_len(wTabStr) > 0 then
				wTabStr = self:HexColor(colors.warbandtabs, " ["..L.TooltipTabs.." "..wTabStr.."]")
			end
		end

		tinsert(tallyCount, self:GetCountString(colorType, dispType, "warband", countList["warband"], wTabStr, countColor))
	end

	if total < 1 then return end
	local tallyString = ""

	if (#tallyCount > 0) then
		if #tallyCount == 1 then
			tallyString = tallyCount[1]
		else
			tsort(tallyCount)
			tallyString = self:HexColor(countColor, comma_value(total)).." ("..tconcat(tallyCount, L.TooltipDelimiter.." ")..")"
		end
	end
	if #tallyCount <= 0 or str_len(tallyString) < 1 then return end

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

local function CheckBlacklistAndWhitelist(shortID, shortNum, opts, skipTally)
	local personalBlacklist = false
	local resultSkipTally = skipTally

	if shortNum and (PERM_IGNORE[shortNum] or BSYC.db.blacklist[shortNum]) then
		if BSYC.db.blacklist[shortNum] then
			resultSkipTally = not opts.showBLCurrentCharacterOnly
			personalBlacklist = true
		else
			resultSkipTally = true
		end
		Debug(BSYC_DL.SL3, "TallyUnits", "|cFFe454fd[Blacklist]|r", shortID, personalBlacklist, opts.showBLCurrentCharacterOnly)
	end

	if opts.enableWhitelist then
		if not shortNum or not BSYC.db.whitelist[shortNum] then
			resultSkipTally = true
			Debug(BSYC_DL.SL3, "TallyUnits", "|cFFe454fd[Whitelist]|r", shortID)
		end
	end

	return resultSkipTally, personalBlacklist
end

local function ProcessOtherUnits(self, ctx, allowKeys, grandTotal, advPlayerChk, advPlayerGuildChk)
	if ctx.advUnitList or not ctx.skipTally then
		local shouldScanOtherUnits = not ctx.doCurrentPlayerOnly and (ctx.turnOffCache or ctx.advUnitList or ctx.useFilters or not ctx.cacheEntry)
		if shouldScanOtherUnits then
			local otherTotal
			otherTotal, advPlayerChk, advPlayerGuildChk = ScanOtherUnits(self, ctx, allowKeys)
			grandTotal = grandTotal + otherTotal

			if not ctx.turnOffCache and not ctx.advUnitList and not ctx.useFilters then
				local cachedUnitList = (grandTotal > 0 and ShallowCopyArray(ctx.unitList)) or {}
				if Data and Data.SetTooltipCache then
					Data:SetTooltipCache(ctx.origLink, cachedUnitList, grandTotal)
				else
					Data.__cache.tooltip[ctx.origLink] = Data.__cache.tooltip[ctx.origLink] or {}
					Data.__cache.tooltip[ctx.origLink].unitList = cachedUnitList
					Data.__cache.tooltip[ctx.origLink].grandTotal = grandTotal
				end
			end
		elseif ctx.cacheEntry and not ctx.doCurrentPlayerOnly then
			ctx.unitList = ShallowCopyArray(ctx.cacheEntry.unitList)
			grandTotal = ctx.cacheEntry.grandTotal or 0
			Debug(BSYC_DL.INFO, "TallyUnits", "|cFF09DBE0CacheUsed|r", ctx.origLink)
		end
	end
	return grandTotal, advPlayerChk, advPlayerGuildChk, ctx.unitList
end

local function AddItemInfoLines(unitList, opts, shortID, isBattlePet, addSeparator)
	if not isBattlePet and not BSYC:IsBattlePetFakeID(shortID) then
		if BSYC.IsRetail and opts.enableSourceExpansion and shortID then
			local desc = Tooltip:HexColor(BSYC.colors.expansion, L.TooltipExpansion)
			local expacID
			if Data.__cache.items[shortID] then
				expacID = Data.__cache.items[shortID].expacID
			else
				local getItemInfo = BSYC.API and BSYC.API.GetItemInfo
				expacID = getItemInfo and select(15, getItemInfo(shortID))
			end
			local value = Tooltip:HexColor(BSYC.colors.second, (expacID and _G["EXPANSION_NAME"..expacID]) or "?")

			if not addSeparator then
				tinsert(unitList, 1, { colorized=" ", tallyString=" "} )
				addSeparator = true
			end
			tinsert(unitList, 1, { colorized=desc, tallyString=value} )
		end

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
				local desc = Tooltip:HexColor(BSYC.colors.itemtypes, L.TooltipItemType)
				local value = Tooltip:HexColor(BSYC.colors.second, typeString)

				if not addSeparator then
					tinsert(unitList, 1, { colorized=" ", tallyString=" "} )
					addSeparator = true
				end
				tinsert(unitList, 1, { colorized=desc, tallyString=value} )
			end
		end
	end
	return addSeparator
end

function Tooltip:TallyUnits(objTooltip, link, source, isBattlePet)
	local opts = BSYC.options
	if opts.enableTooltips == false then
		return
	end

	-- LAYER 1 SAFETY CHECK: Verify the owner tooltip itself is accessible before touching it.
	-- CanAccessObject() returns false if the tooltip frame is forbidden (secured) or if
	-- issecure() would be violated. If this fails we cannot write inline OR show extTip,
	-- so we bail out entirely — there is nothing safe to attach to.
	if not CanAccessObject(objTooltip) then
		return
	end

	if Scanner.isScanningGuild then
		return
	end

	local tracking = BSYC.tracking
	local GetItemCount = BSYC.API and BSYC.API.GetItemCount
	local IsReagentBankUnlocked = _G.IsReagentBankUnlocked

	if not self:CheckModifier() and not objTooltip.isBSYCSearch then
		return
	end

	Tooltip.objTooltip = objTooltip

	-- LAYER 2 SAFETY CHECK: Ask ExtTip whether it can safely show and position itself.
	-- ExtTip:Check() scans for a valid anchor frame using Utility:IsSecretFrame() on each
	-- candidate. If every candidate returns a secret value (Blizzard-protected), no safe
	-- anchor exists and Check() returns false. That result is captured here:
	--   showExtTip = true  → extTip is ready; BagSync data will be written to it.
	--   showExtTip = false → extTip cannot be positioned safely; BagSync data falls back
	--                        to inline output on objTooltip (the owner tooltip).
	-- extTip is nil when showExtTip is false so all downstream branches are safe.
	local showExtTip = ExtTip:Check(source, isBattlePet, objTooltip)
	local extTip = showExtTip and ExtTip:GetTip() or nil

	local skipTally = false

	if opts.tooltipOnlySearch and not objTooltip.isBSYCSearch then
		ExtTip:Hide()
		objTooltip:Show()
		return
	end

	local origLink = link
	link = BSYC:ParseItemLink(link)
	link = BSYC:Split(link, true)

	local shortID = BSYC:GetShortItemID(link)

	if isBattlePet then origLink = shortID end

	if not link or not shortID then
		ExtTip:Hide()
		objTooltip:Show()
		return
	end

	local shortNum = tonumber(shortID)
	local personalBlacklist
	skipTally, personalBlacklist = CheckBlacklistAndWhitelist(shortID, shortNum, opts, skipTally)

	if opts.enableShowUniqueItemsTotals then link = shortID end

	local grandTotal = 0
	local unitList = {}
	local countList = WipeTable(self.__scratchCountList or {})
	self.__scratchCountList = countList
	local player = Unit:GetPlayerInfo()
	local guildObj = Data:GetPlayerGuildObj(player)
	local warbandObj = Data:GetWarbandBankObj()

	local advUnitList = not skipTally and objTooltip.isBSYCSearch and BSYC.advUnitList
	local advAllowList = not skipTally and objTooltip.isBSYCSearch and BSYC.advAllowList
	local useFilters = advAllowList ~= nil
	local allowList = (useFilters and advAllowList) or BSYC.DEFAULT_ALLOW_LIST

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
		skipTally = skipTally,
		countList = countList,
		unitList = unitList,
		player = player,
		guildObj = guildObj,
		warbandObj = warbandObj,
	}

	self.__scratchAllowSig = self.__scratchAllowSig or {}
	local allowSig = useFilters and BuildAllowSignature(allowList, self.__scratchAllowSig) or "default"
	local tooltipSig = BuildTooltipSignature(self, opts, allowSig, advUnitList, showExtTip, doCurrentPlayerOnly, skipTally)

	-- Fast-path: same link + same signature means nothing changed; replay the cached result.
	-- The showExtTip flag is baked into tooltipSig, so a change from inline→extTip or vice
	-- versa correctly invalidates the cache and falls through to a full retally.
	if self.__lastLink and self.__lastLink == origLink and self.__lastSig == tooltipSig then
		if self.__lastTally and #self.__lastTally > 0 then
			-- Honour the same inline-vs-extTip decision that was made on the original pass.
			if showExtTip then
				self:AddTooltipUnits(extTip, self.__lastTally, BSYC.colors.total)
			else
				self:AddTooltipUnits(objTooltip, self.__lastTally, BSYC.colors.total)
			end
			objTooltip:Show()
			if showExtTip then
				-- ShowExtTipWithUnitInline positions extTip; if UpdateAnchor fails inside it
				-- the data is written inline to objTooltip as a final fallback (Layer 3).
				self:ShowExtTipWithUnitInline(objTooltip, extTip, self.__lastTally, opts.enableTooltipSeparator and #self.__lastTally > 0, isBattlePet)
			end
		end
		objTooltip.__tooltipUpdated = true
		Debug(BSYC_DL.SL3, "TallyUnits", "|cFFe454fd[Cache-Item]|r", link, origLink, shortID, isBattlePet, showExtTip)
		return
	end
	Debug(BSYC_DL.SL2, "TallyUnits", "|cFFe454fd[Item]|r", link, shortID, origLink, skipTally, advUnitList, turnOffCache, doCurrentPlayerOnly)

	local allowKeys
	if useFilters then
		allowKeys = BuildAllowKeys(allowList, self.__scratchAllowKeys)
		self.__scratchAllowKeys = allowKeys
	else
		allowKeys = GetDefaultAllowKeys()
	end

	--ProcessOtherUnits may replace ctx.unitList (cache reuse); VERY important to have unitList be updated by it as a return
	grandTotal, advPlayerChk, advPlayerGuildChk, unitList = ProcessOtherUnits(self, ctx, allowKeys, grandTotal, advPlayerChk, advPlayerGuildChk)

	Debug(BSYC_DL.SL2, "TallyUnits", "|cFF4DD827[AdvChk]|r", advUnitList, advPlayerChk, advPlayerGuildChk)

	if not advUnitList or advPlayerChk then
		local playerTotal = AddCurrentPlayer(self, ctx, advPlayerChk)
		if playerTotal > 0 then
			grandTotal = grandTotal + playerTotal
		end
	end

	local guildTotal = AddCurrentPlayerGuild(self, ctx, advPlayerGuildChk)
	if guildTotal > 0 then
		grandTotal = grandTotal + guildTotal
	end

	local warbandTotal = AddWarband(self, ctx)
	if warbandTotal > 0 then
		grandTotal = grandTotal + warbandTotal
	end

	if #unitList > 0 then
		unitList = self:DoSort(unitList)
	end

	if opts.showBLCurrentCharacterOnly and personalBlacklist then
		tinsert(unitList, 1, { colorized="|cffff7d0a["..L.Blacklist.."]|r", tallyString=" "} )
	end

	local desc, value = "", ""
	local addSeparator = false

	if not skipTally and opts.showTotal and grandTotal > 0 and #unitList > 1 then
		AddUnitSpacer(unitList)

		desc = self:HexColor(BSYC.colors.total, L.TooltipTotal)
		value = self:HexColor(BSYC.colors.second, comma_value(grandTotal))
		AddUnitLine(unitList, desc, value)
	end

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

	addSeparator = AddItemInfoLines(unitList, opts, shortID, isBattlePet, addSeparator)

	-- Separator is only prepended for inline output; extTip manages its own spacing.
	if not showExtTip and opts.enableTooltipSeparator and #unitList > 0 then
		tinsert(unitList, 1, { colorized=" ", tallyString=" "} )
	end

	-- Route BagSync data to the correct destination based on the Layer 2 result:
	--   showExtTip = true  → write to the separate extTip frame.
	--   showExtTip = false → write inline to objTooltip (owner tooltip).
	--                        This is the Layer 2 inline fallback for secret-value situations.
	if showExtTip then
		self:AddTooltipUnits(extTip, unitList, BSYC.colors.total)
	else
		self:AddTooltipUnits(objTooltip, unitList, BSYC.colors.total)
	end

	self.__lastTally = unitList
	self.__lastLink = origLink
	self.__lastSig = tooltipSig

	objTooltip.__tooltipUpdated = true
	objTooltip:Show()

	if showExtTip then
		if #unitList > 0 then
			-- ShowExtTipWithUnitInline makes extTip visible and calls UpdateAnchor to position it.
			-- If UpdateAnchor returns false (Layer 3 fallback), the data is also written inline
			-- to objTooltip so nothing is lost even if anchoring fails at this late stage.
			self:ShowExtTipWithUnitInline(objTooltip, extTip, unitList, opts.enableTooltipSeparator and #unitList > 0, isBattlePet)
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

	if not self:CheckModifier() and source ~= "bagsync_currency" then return end
	if not CanAccessObject(objTooltip) then return end

	currencyID = tonumber(currencyID)
	if not currencyID then return end

	Tooltip.objTooltip = objTooltip

	local showExtTip = ExtTip:Check(source, false, objTooltip)
	local extTip = showExtTip and ExtTip:GetTip() or nil

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

	local usrData = WipeTable(self.__scratchCurrencyData or {})
	self.__scratchCurrencyData = usrData
	local grandTotal = 0

	self.__lastCurrencyID = currencyID
	self.__lastCurrencyTally = {}

	local tenderCheck = currencyID == 2032 or false

	for unitObj in Data:IterateUnits() do
		if not unitObj.isGuild and unitObj.data.currency and unitObj.data.currency[currencyID] and unitObj.data.currency[currencyID].count > 0 then
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

	if opts.showTotal and grandTotal > 0 and #displayList > 1 then
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
		local getCurrencyInfo = BSYC.API and BSYC.API.GetCurrencyInfo
		local currencyData = getCurrencyInfo and getCurrencyInfo(currencyID)
		if currencyData then
			Tooltip:CurrencyTooltip(tooltip, currencyData.name, currencyData.iconFileID, currencyID, "OnTooltipSetCurrency")
		end
	end
end

local tooltipPostHooksRegistered = false
local tooltipUsingLegacyHooks = false

local function RegisterTooltipPostHooks()
	if tooltipUsingLegacyHooks then return false end
	if tooltipPostHooksRegistered then return true end
	local C_TooltipInfo = _G.C_TooltipInfo
	local TooltipDataProcessor = _G.TooltipDataProcessor
	local Enum = _G.Enum
	if not C_TooltipInfo or not TooltipDataProcessor or not Enum or not Enum.TooltipDataType then
		return false
	end

	tooltipPostHooksRegistered = true
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, HandleTooltipSetItem)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Currency, HandleTooltipSetCurrency)
	return true
end

local arkAlreadyHooked = false
local hookedTooltips = setmetatable({}, { __mode = "k" })

function Tooltip:HookTooltip(objTooltip)
	if not objTooltip then return end
	if hookedTooltips[objTooltip] then return end
	hookedTooltips[objTooltip] = true

	Debug(BSYC_DL.INFO, "HookTooltip", objTooltip)

	objTooltip:HookScript("OnHide", function(self)
		self.__tooltipUpdated = false
		-- Only hide/clear ExtTip when the current owner is hiding.
		if ExtTip.__currentOwner == self then
			ExtTip:OnTooltipHide()
		end
	end)

	local battlePetTooltip = _G.BattlePetTooltip
	local floatingBattlePetTooltip = _G.FloatingBattlePetTooltip
	local isBattlePet = (objTooltip == battlePetTooltip or objTooltip == floatingBattlePetTooltip)

	if not isBattlePet then
		objTooltip:HookScript("OnTooltipCleared", function(self)
			self.__tooltipUpdated = false
		end)
	else
		objTooltip:HookScript("OnShow", function(self)
			if self.__tooltipUpdated then return end
		end)

		if ArkInventory and ArkInventory.API and ArkInventory.API.CustomBattlePetTooltipReady then
			if not arkAlreadyHooked then
				hooksecurefunc(ArkInventory.API, "CustomBattlePetTooltipReady", function(tooltip, link)
					if link then
						Tooltip:TallyUnits(tooltip, link, "ArkInventory", true)
					end
				end)
				arkAlreadyHooked = true
			end
		else
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
		if RegisterTooltipPostHooks() then
			return
		end
		tooltipUsingLegacyHooks = true
	end

	if not isBattlePet then
		objTooltip:HookScript("OnTooltipSetItem", function(self)
			if self.__tooltipUpdated then return end
			local name, link = self:GetItem()
			if link then
				local linkName = str_match(link, "|h%[(.-)%]|h")
				if not linkName or str_len(linkName) < 1 then return nil end

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

	if objTooltip.SetCurrencyToken then
		hooksecurefunc(objTooltip, "SetCurrencyToken", function(self, currencyIndex)
			local getCurrencyListLink = BSYC.API and BSYC.API.GetCurrencyListLink
			local getCurrencyInfo = BSYC.API and BSYC.API.GetCurrencyInfo
			local link = getCurrencyListLink and getCurrencyListLink(currencyIndex)
			if link then
				local currencyID = BSYC:GetShortCurrencyID(link)

				if currencyID then
					local currencyData = getCurrencyInfo and getCurrencyInfo(currencyID)
					if currencyData and currencyData.name and currencyData.iconFileID then
						Tooltip:CurrencyTooltip(objTooltip, currencyData.name, currencyData.iconFileID, currencyID, "SetCurrencyToken")
					end
				end
			end
		end)
	end

	if objTooltip.SetCraftItem then
		hooksecurefunc(objTooltip, "SetCraftItem", function(self, index, reagent)
			if self.__tooltipUpdated then return end
			local _, _, count = _G.GetCraftReagentInfo(index, reagent)
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
