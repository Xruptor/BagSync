--[[
	tooltip.lua
		Tooltip module for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Tooltip = BSYC:NewModule("Tooltip")
local Unit = BSYC:GetModule("Unit")
local Data = BSYC:GetModule("Data")
local Scanner = BSYC:GetModule("Scanner")
local L = BSYC.L
local tinsert, tconcat, tsort = table.insert, table.concat, table.sort
local wipe = _G.wipe

--https://github.com/tomrus88/BlizzardInterfaceCode/blob/classic/Interface/GlueXML/CharacterCreate.lua
local RACE_ICON_TCOORDS = _G.RACE_ICON_TCOORDS or {
	["HUMAN_MALE"]		= {0, 0.25, 0, 0.25},
	["DWARF_MALE"]		= {0.25, 0.5, 0, 0.25},
	["GNOME_MALE"]		= {0.5, 0.75, 0, 0.25},
	["NIGHTELF_MALE"]	= {0.75, 1.0, 0, 0.25},
	["TAUREN_MALE"]		= {0, 0.25, 0.25, 0.5},
	["SCOURGE_MALE"]	= {0.25, 0.5, 0.25, 0.5},
	["TROLL_MALE"]		= {0.5, 0.75, 0.25, 0.5},
	["ORC_MALE"]		= {0.75, 1.0, 0.25, 0.5},
	["HUMAN_FEMALE"]	= {0, 0.25, 0.5, 0.75},
	["DWARF_FEMALE"]	= {0.25, 0.5, 0.5, 0.75},
	["GNOME_FEMALE"]	= {0.5, 0.75, 0.5, 0.75},
	["NIGHTELF_FEMALE"]	= {0.75, 1.0, 0.5, 0.75},
	["TAUREN_FEMALE"]	= {0, 0.25, 0.75, 1.0},
	["SCOURGE_FEMALE"]	= {0.25, 0.5, 0.75, 1.0},
	["TROLL_FEMALE"]	= {0.5, 0.75, 0.75, 1.0},
	["ORC_FEMALE"]		= {0.75, 1.0, 0.75, 1.0},
}

local PERM_IGNORE = {
	[6948] = "Hearthstone",
	[110560] = "Garrison Hearthstone",
	[140192] = "Dalaran Hearthstone",
	[128353] = "Admiral's Compass",
	[141605] = "Flight Master's Whistle",
}

--https://warcraft.wiki.gg/wiki/AtlasID
--raceicon-highmountain-male
--https://wago.tools/db2/UiTextureAtlasMember
--https://warcraft.wiki.gg/wiki/API_UnitRace
local FIXED_RACE_ATLAS = {
	["highmountaintauren"] = "highmountain",
	["lightforgeddraenei"] = "lightforged",
	["scourge"] = "undead",
	["zandalaritroll"] = "zandalari",
	["earthendwarf"] = "earthen",
}

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Tooltip", ...) end
end

local function CanAccessObject(obj)
    return issecure() or not obj:IsForbidden();
end

local function comma_value(n)
	if not n or not tonumber(n) then return "?" end
	return tostring(BreakUpLargeNumbers(tonumber(n)))
end

--https://wowwiki-archive.fandom.com/wiki/User_defined_functions
local function RGBPercToHex(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

local function GetTotalForItem(data, itemID, useUniqueTotals)
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

local function ConcatNumeric(tbl, delim)
	if not tbl or #tbl == 0 then return "" end
	local tmp = {}
	for i = 1, #tbl do
		tmp[i] = tostring(tbl[i])
	end
	return tconcat(tmp, delim or ",")
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

local function ShallowCopyArray(src)
	if not src or #src == 0 then return {} end
	local dst = {}
	for i = 1, #src do
		dst[i] = src[i]
	end
	return dst
end

function Tooltip:HexColor(color, str)
	if type(color) == "table" then
		return string.format("|cff%s%s|r", RGBPercToHex(color.r, color.g, color.b), tostring(str))
	end
	if string.len(color) == 8 then
		return string.format("|c%s%s|r", tostring(color), tostring(str))
	else
		return string.format("|cff%s%s|r", tostring(color), tostring(str))
	end
end

function Tooltip:GetItemTypeString(itemType, itemSubType, classID, subclassID)
	if not itemType or not itemSubType then return nil end

	local typeString = "?"
	typeString = itemType.." | "..itemSubType

	if classID then
		--https://wowpedia.fandom.com/wiki/ItemType
		if classID == Enum.ItemClass.Questitem then
			typeString = Tooltip:HexColor('ffccef66', itemType).." | "..itemSubType

		elseif classID == Enum.ItemClass.Profession then
			typeString = Tooltip:HexColor('FF51B9E9', itemType).." | "..itemSubType

		elseif classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon then
			typeString = Tooltip:HexColor('ff77ffff', itemType).." | "..itemSubType

		elseif classID == Enum.ItemClass.Consumable then
			typeString = Tooltip:HexColor('FF77F077', itemType).." | "..itemSubType

		elseif classID == Enum.ItemClass.Tradegoods then
			typeString = Tooltip:HexColor('FFFFD580', itemType).." | "..itemSubType

		elseif classID == Enum.ItemClass.Reagent then
			typeString = Tooltip:HexColor('ffff7777', itemType).." | "..itemSubType
		end
	end

	--name, isArmorType = GetItemSubClassInfo(classID, subClassID)
	--name = GetItemClassInfo(classID)

	return typeString
end

function Tooltip:GetSortIndex(unitObj)
	if unitObj then
		if BSYC.options.sortShowCurrentPlayerOnTop and unitObj.data == BSYC.db.player then
			return 1
		elseif not unitObj.isGuild and unitObj.realm == _G.GetRealmName() then
			return 2
		elseif unitObj.isGuild and unitObj.realm == _G.GetRealmName() then
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

function Tooltip:GetRaceIcon(race, gender, size, xOffset, yOffset, useHiRez)
	local raceString = ""
	local origRace = race
	local formatingString = useHiRez and "raceicon128-%s-%s" or "raceicon-%s-%s"

	if not race or not gender then return raceString end

	if BSYC.IsClassic then
		race = race:upper()
		local raceFile = "Interface/Glues/CharacterCreate/UI-CharacterCreate-Races"
		local coords = RACE_ICON_TCOORDS[race.."_"..(gender == 3 and "FEMALE" or "MALE")]
		if coords then
			local left, right, top, bottom = unpack(coords)
			raceString = CreateTextureMarkup(raceFile, 128, 128, size, size, left, right, top, bottom, xOffset, yOffset)
		end
	else
		race = race:lower()
		race = FIXED_RACE_ATLAS[race] or race

		formatingString = formatingString:format(race, gender == 3 and "female" or "male")

		raceString =  CreateAtlasMarkup(formatingString, size, size, xOffset, yOffset)
	end

	Debug(BSYC_DL.SL3, "GetRaceIcon", origRace, race, gender, size, xOffset, yOffset, useHiRez, raceString, formatingString)

	return raceString
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
	local classColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[unitObj.data.class] or RAID_CLASS_COLORS[unitObj.data.class]
	if bypass or ( doChk and classColor ) then
			return classColor
	end
	return altColor or BSYC.colors.first
end

function Tooltip:ColorizeUnit(unitObj, bypass, forceRealm, forceXRBNET, tagAtEnd)

	if not unitObj.data then return nil end

	local tmpTag = ""
	local realm = unitObj.realm
	local realmTag = ""
	--bypass: shows colorized names, checkmark, and faction icons but no CR or BNET tags
	--forceRealm: adds realm tags forcefully

	if not unitObj.isGuild and not unitObj.isWarbandBank then

		--first colorize by class color
		tmpTag = self:HexColor(self:GetClassColor(unitObj, 1, bypass), unitObj.name)

		--add green checkmark
		if unitObj.data == BSYC.db.player then
			if bypass or BSYC.options.enableTooltipGreenCheck then
				local ReadyCheck = [[|TInterface\RaidFrame\ReadyCheck-Ready:0|t]]
				tmpTag = ReadyCheck.." "..tmpTag
			end
		end

		--add race icons
		if bypass or BSYC.options.showRaceIcons then
			local raceIcon = self:GetRaceIcon(unitObj.data.race, unitObj.data.gender, 13, 0, 0)
			if raceIcon ~= "" then
				tmpTag = raceIcon.." "..tmpTag
			end
		end

	elseif unitObj.isWarbandBank then
		tmpTag = self:HexColor(BSYC.colors.warband, L.TooltipIcon_warband.." "..L.Tooltip_warband)
		bypass = true
	else
		--is guild
		tmpTag = self:HexColor(BSYC.colors.guild, select(2, Unit:GetUnitAddress(unitObj.name)) )
	end

	--add faction icons
	if not unitObj.isWarbandBank and (bypass or unitObj.isGuild or BSYC.options.enableFactionIcons) then
		local FactionIcon = ""

		if BSYC.IsRetail then
			FactionIcon = [[|TInterface\Icons\Achievement_worldevent_brewmaster:13:13|t]]
			if unitObj.data.faction == "Alliance" then
				FactionIcon = [[|TInterface\FriendsFrame\PlusManz-Alliance:13:13|t]]
			elseif unitObj.data.faction == "Horde" then
				FactionIcon = [[|TInterface\FriendsFrame\PlusManz-Horde:13:13|t]]
			end
		else
			FactionIcon = [[|TInterface\Icons\ability_seal:18|t]]
			if unitObj.data.faction == "Alliance" then
				FactionIcon = [[|TInterface\FriendsFrame\PlusManz-Alliance:13:13|t]]
			elseif unitObj.data.faction == "Horde" then
				FactionIcon = [[|TInterface\FriendsFrame\PlusManz-Horde:13:13|t]]
			end
		end

		tmpTag = FactionIcon.." "..tmpTag
	end

	----------------
	--If we Bypass none of the CR or BNET stuff will be shown
	----------------
	if bypass and (not forceRealm and not forceXRBNET) then
		Debug(BSYC_DL.INFO, "ColorizeUnit-Bypass", tmpTag)
		--since we Bypass don't show anything else just return what we got
		return tmpTag
	end
	----------------

	local addStr = ""

	if BSYC.options.enableRealmNames then
		realm = unitObj.realm
	elseif BSYC.options.enableRealmAstrickName then
		realm = "*"
	elseif BSYC.options.enableRealmShortName then
		realm = string.sub(unitObj.realm, 1, 5)
	elseif forceRealm then
		realm = unitObj.realm
	else
		realm = ""
	end

	if BSYC.options.enableCurrentRealmName and unitObj.realm == _G.GetRealmName() then
		realm = unitObj.realm
		if BSYC.options.enableCurrentRealmShortName then
			realm = string.sub(realm, 1, 5)
		end
		addStr = self:HexColor(BSYC.colors.currentrealm, "["..realm.."]")
	end

	local delimiter = (realm ~= "" and " ") or ""

	if not unitObj.isXRGuild then
		if (forceXRBNET or BSYC.options.enableBNET) and not unitObj.isConnectedRealm then
			realmTag = (BSYC.options.enableRealmIDTags and L.TooltipBNET_Tag..delimiter) or ""
			if realm ~= "" or realmTag ~= "" then
				addStr = self:HexColor(BSYC.colors.bnet, "["..realmTag..realm.."]")
			end
		end

		if (forceXRBNET or BSYC.options.enableCR) and unitObj.isConnectedRealm and unitObj.realm ~= _G.GetRealmName() then
			realmTag = (BSYC.options.enableRealmIDTags and L.TooltipCR_Tag..delimiter) or ""
			if realm ~= "" or realmTag ~= "" then
				addStr = self:HexColor(BSYC.colors.cr, "["..realmTag..realm.."]")
			end
		end
	else
		--if it's a connected realm guild the player belongs to, then show the CR tag.  This option only true if the CR and BNET options are off.
		realmTag = (BSYC.options.enableRealmIDTags and L.TooltipCR_Tag..delimiter) or ""
		realm = (string.len(realm) > 1 and realm) or "" --lets make sure we have more than just an asterick for the realm name otherwiose it would be [+] we want [+]
		addStr = self:HexColor(BSYC.colors.cr, "[+"..realmTag..realm.."]")
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
		Debug(BSYC_DL.INFO, "ColorizeUnit", tmpTag, unitObj.realm, unitObj.isConnectedRealm, unitObj.isXRGuild, _G.GetRealmName())
	end
	return tmpTag
end

function Tooltip:DoSort(tblData)

	local mode = BSYC.options.tooltipSortMode
	if not mode or mode == "" then
		mode = "realm_character"
	else
		local validModes = {
			realm_character = true,
			character = true,
			class_character = true,
			totals = true,
			custom = true,
		}
		if not validModes[mode] then
			mode = "realm_character"
		end
	end

	local function pinKey(entry)
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

	local function strKey(s)
		return tostring(s or ""):lower()
	end

	local function isCharacter(unitObj)
		return unitObj and not unitObj.isGuild and not unitObj.isWarbandBank
	end

	local function classKey(unitObj)
		if not unitObj or not unitObj.data or not unitObj.data.class then return "" end
		local token = unitObj.data.class
		local localized = _G.LOCALIZED_CLASS_NAMES_MALE and _G.LOCALIZED_CLASS_NAMES_MALE[token]
		return strKey(localized or token)
	end

	--sort the list by our chosen mode
	if mode == "totals" then
		table.sort(tblData, function(a, b)
			return a.count > b.count;
		end)
	elseif mode == "custom" then
		table.sort(tblData, function(a, b)
			local ap, bp = pinKey(a), pinKey(b)
			if ap ~= bp then return ap < bp end

			if a.unitObj.data.SortIndex and b.unitObj.data.SortIndex  then
				return  a.unitObj.data.SortIndex < b.unitObj.data.SortIndex;
			else
				if a.sortIndex == b.sortIndex then
					if a.unitObj.realm == b.unitObj.realm then
						return a.unitObj.name < b.unitObj.name;
					end
					return a.unitObj.realm < b.unitObj.realm;
				end
				return a.sortIndex < b.sortIndex;
			end
		end)
	elseif mode == "character" then
		table.sort(tblData, function(a, b)
			local ap, bp = pinKey(a), pinKey(b)
			if ap ~= bp then return ap < bp end

			local an, bn = strKey(a.unitObj and a.unitObj.name), strKey(b.unitObj and b.unitObj.name)
			if an == bn then
				return strKey(a.unitObj and a.unitObj.realm) < strKey(b.unitObj and b.unitObj.realm)
			end
			return an < bn
		end)
	elseif mode == "class_character" then
		table.sort(tblData, function(a, b)
			local ap, bp = pinKey(a), pinKey(b)
			if ap ~= bp then return ap < bp end

			local aChar, bChar = isCharacter(a.unitObj), isCharacter(b.unitObj)
			if aChar ~= bChar then return aChar end -- characters first

			if aChar and bChar then
				local ac, bc = classKey(a.unitObj), classKey(b.unitObj)
				if ac == bc then
					local an, bn = strKey(a.unitObj.name), strKey(b.unitObj.name)
					if an == bn then
						return strKey(a.unitObj.realm) < strKey(b.unitObj.realm)
					end
					return an < bn
				end
				return ac < bc
			end

			-- non-characters: keep prior stable ordering
			if a.sortIndex == b.sortIndex then
				if a.unitObj.realm == b.unitObj.realm then
					return a.unitObj.name < b.unitObj.name;
				end
				return a.unitObj.realm < b.unitObj.realm;
			end
			return a.sortIndex < b.sortIndex;
		end)
	else
		table.sort(tblData, function(a, b)
			if a.sortIndex == b.sortIndex then
				if a.unitObj.realm == b.unitObj.realm then
					return a.unitObj.name < b.unitObj.name;
				end
				return a.unitObj.realm < b.unitObj.realm;
			end
			return a.sortIndex < b.sortIndex;
		end)
	end

	return tblData
end

function Tooltip:GetEquipBags(target, unitObj, itemID, countList)
	if not target or not unitObj or not itemID then return 0 end
	if not unitObj.data.equipbags or not unitObj.data.equipbags[target] then return 0 end
	if target == "bank" and BSYC.IsBankTabsActive then return 0 end

	local useUniqueTotals = BSYC.options.enableShowUniqueItemsTotals

	local iCount = 0
	local tmpSlots = {}

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

function Tooltip:AddItems(unitObj, itemID, target, countList, isCurrentPlayer)
	local total = 0
	if not unitObj or not itemID or not target or not countList then return total end
	if not unitObj.data then return total end

	local useUniqueTotals = BSYC.options.enableShowUniqueItemsTotals

	if unitObj.data[target] and BSYC.tracking[target] then
		if target == "bag" or target == "bank" or target == "reagents" then
			for bagID, bagData in pairs(unitObj.data[target] or {}) do

				local bTotal = GetTotalForItem(bagData, itemID, useUniqueTotals)
				total = total + bTotal

				if target == "bank" and BSYC.IsBankTabsActive and BSYC.options.showBankTabs and bTotal > 0 then
					if not countList.btab then countList.btab = {} end
					table.insert(countList.btab, bagID - 5) --subtract 5 to get it to start from 1 since bank tabs start at 6
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
	if target == "guild" and BSYC.tracking.guild then
		for tabID, tabData in pairs(unitObj.data.tabs or {}) do
			local tabCount = GetTotalForItem(tabData, itemID, useUniqueTotals)
			if tabCount > 0 and BSYC.options.showGuildTabs then
				if not countList.gtab then countList.gtab = {} end
				table.insert(countList.gtab, tabID)
			end
			total = total + tabCount
		end
	end

	if target == "warband" and BSYC.tracking.warband then
		for tabID, tabData in pairs(unitObj.data.tabs or {}) do
			local tabCount = GetTotalForItem(tabData, itemID, useUniqueTotals)
			if tabCount > 0 and BSYC.options.showWarbandTabs then
				if not countList.wtab then countList.wtab = {} end
				table.insert(countList.wtab, tabID)
			end
			total = total + tabCount
		end
	end

	countList[target] = total

	return total
end

function Tooltip:GetCountString(colorType, dispType, srcType, srcCount, addStr)
	local desc = self:HexColor(colorType, L[dispType..srcType])
	local count = self:HexColor(BSYC.colors.second, comma_value(srcCount))
	local tmp = string.format("%s: %s", desc, count)..(addStr or "")
	return tmp
end

function Tooltip:UnitTotals(unitObj, countList, unitList, advUnitList)
	local total = 0
	local tallyCount = WipeTable(self.__scratchTallyCount or {})
	self.__scratchTallyCount = tallyCount
	local dispType = ""
	local colorType = self:GetClassColor(unitObj, 2)

	if BSYC.options.singleCharLocations then
		dispType = "TooltipSmall_"
	elseif BSYC.options.useIconLocations then
		dispType = "TooltipIcon_"
	else
		dispType = "Tooltip_"
	end

	if ((countList["bag"] or 0) > 0) then
		total = total + countList["bag"]
		tinsert(tallyCount, self:GetCountString(colorType, dispType, "bag", countList["bag"], BSYC.options.showEquipBagSlots and countList["bagslots"]))
	end
	if ((countList["bank"] or 0) > 0) then
		total = total + countList["bank"]

		local bTabStr = ""

		--check for warband tabs first
		if BSYC.IsBankTabsActive and BSYC.options.showBankTabs and countList["btab"] and #countList["btab"] > 0 then
			tsort(countList["btab"], function(a, b) return a < b end)
			bTabStr = ConcatNumeric(countList["btab"], ",")

			--check for bank tab
			if string.len(bTabStr) > 0 then
				bTabStr = self:HexColor(BSYC.colors.banktabs, " ["..L.TooltipTabs.." "..bTabStr.."]")
			end
		else
			bTabStr = (BSYC.options.showEquipBagSlots and countList["bankslots"]) or nil
		end

		tinsert(tallyCount, self:GetCountString(colorType, dispType, "bank", countList["bank"], bTabStr))
	end
	if ((countList["reagents"] or 0) > 0) then
		total = total + countList["reagents"]
		tinsert(tallyCount, self:GetCountString(colorType, dispType, "reagents", countList["reagents"]))
	end
	if ((countList["equip"] or 0) > 0) then
		total = total + countList["equip"]
		tinsert(tallyCount, self:GetCountString(colorType, dispType, "equip", countList["equip"]))
	end
	if ((countList["mailbox"] or 0) > 0) then
		total = total + countList["mailbox"]
		tinsert(tallyCount, self:GetCountString(colorType, dispType, "mailbox", countList["mailbox"]))
	end
	if ((countList["void"] or 0) > 0) then
		total = total + countList["void"]
		tinsert(tallyCount, self:GetCountString(colorType, dispType, "void", countList["void"]))
	end
	if ((countList["auction"] or 0) > 0) then
		total = total + countList["auction"]
		tinsert(tallyCount, self:GetCountString(colorType, dispType, "auction", countList["auction"]))
	end
	if ((countList["guild"] or 0) > 0) then
		total = total + countList["guild"]
		local gTabStr = ""

		--check for guild tabs first
		if BSYC.options.showGuildTabs and countList["gtab"] and #countList["gtab"] > 0 then
			tsort(countList["gtab"], function(a, b) return a < b end)
			gTabStr = ConcatNumeric(countList["gtab"], ",")

			--check for guild tab
			if string.len(gTabStr) > 0 then
				gTabStr = self:HexColor(BSYC.colors.guildtabs, " ["..L.TooltipTabs.." "..gTabStr.."]")
			end
		end

		tinsert(tallyCount, self:GetCountString(colorType, dispType, "guild", countList["guild"], gTabStr))
	end

	if ((countList["warband"] or 0) > 0) then
		total = total + countList["warband"]
		local wTabStr = ""

		--check for warband tabs first
		if BSYC.options.showWarbandTabs and countList["wtab"] and #countList["wtab"] > 0 then
			tsort(countList["wtab"], function(a, b) return a < b end)
			wTabStr = ConcatNumeric(countList["wtab"], ",")

			--check for warband tab
			if string.len(wTabStr) > 0 then
				wTabStr = self:HexColor(BSYC.colors.warbandtabs, " ["..L.TooltipTabs.." "..wTabStr.."]")
			end
		end

		tinsert(tallyCount, self:GetCountString(colorType, dispType, "warband", countList["warband"], wTabStr))
	end

	if total < 1 then return end
	local tallyString = ""

    if (#tallyCount > 0) then
		--if we only have one entry, then display that and no need to sort or concat
		if #tallyCount == 1 then
			tallyString = tallyCount[1]
		else
			table.sort(tallyCount)
			tallyString = self:HexColor(BSYC.colors.second, comma_value(total)).." ("..table.concat(tallyCount, L.TooltipDelimiter.." ")..")"
		end
    end
	if #tallyCount <= 0 or string.len(tallyString) < 1 then return end

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
	table.insert(unitList, unitData)

	Debug(BSYC_DL.SL2, "UnitTotals", unitObj.name, unitObj.realm, unitData.colorized, unitData.tallyString, total, sortIndex)
	return unitData
end

function Tooltip:EnsureExtTip()
	if Tooltip.extTip then return end
	local extTip = CreateFrame("GameTooltip", "BagSyncExtTip", UIParent, "GameTooltipTemplate")
	extTip:SetOwner(UIParent, "ANCHOR_NONE")
	extTip:SetClampedToScreen(true)
	extTip:SetFrameStrata("TOOLTIP")
	extTip:SetToplevel(true)
	Tooltip.extTip = extTip
end

function Tooltip:ApplyExtTipFont()
	if not Tooltip.extTip or not BSYC.__font then return end
	local fontPath, fontSize, fontFlags = BSYC.__font:GetFont()
	if not fontPath or not fontSize then return end

	local tip = Tooltip.extTip
	local name = tip:GetName()
	local numLines = tip:NumLines() or 0
	for i = 1, numLines do
		local left = _G[name .. "TextLeft" .. i]
		if left and left.SetFont then
			left:SetFont(fontPath, fontSize, fontFlags)
		end
		local right = _G[name .. "TextRight" .. i]
		if right and right.SetFont then
			right:SetFont(fontPath, fontSize, fontFlags)
		end
	end
end

function Tooltip:ExtTipCheck(source, isBattlePet)
	local opts = BSYC.options
	local shouldShow = (opts.enableExtTooltip or isBattlePet) and true or false

	self:EnsureExtTip()

	if not shouldShow then
		Tooltip.extTip:Hide()
		return false
	end

	Tooltip.extTip:ClearAllPoints()
	Tooltip.extTip:ClearLines()
	Tooltip.extTip:SetOwner(UIParent, "ANCHOR_NONE")

	return true
end

local function FrameAnchoredTo(frame, rel)
	if not frame or not rel then return false end
	if not frame.GetNumPoints or not frame.GetPoint then return false end
	for i = 1, frame:GetNumPoints() do
		local _, relativeTo = frame:GetPoint(i)
		if relativeTo == rel then
			return true
		end
	end
	return false
end

local function IsRelatedTooltipFrame(frame, owner)
	if not frame or not owner or frame == Tooltip.extTip then return false end
	if not CanAccessObject(frame) then return false end
	if not frame.IsVisible or not frame:IsVisible() then return false end

	if frame == owner then return true end
	if frame.GetOwner and frame:GetOwner() == owner then return true end
	if FrameAnchoredTo(frame, owner) then return true end

	return false
end

local function QuantizeCoord(v)
	if not v then return 0 end
	return math.floor(v * 10 + 0.5) -- tenth-pixel-ish granularity, avoids jitter
end

function Tooltip:GetBottomTooltipAnchor(owner)
	if not owner then return nil end

	local bestFrame = owner
	local bestPos = owner:GetBottom()

	local candidates = WipeTable(self.__scratchAnchorCandidates or {})
	self.__scratchAnchorCandidates = candidates

	local function consider(frame)
		if not frame or not frame.GetBottom then return end
		if not IsRelatedTooltipFrame(frame, owner) then return end
		local bottom = frame:GetBottom()
		if bottom and (not bestPos or bottom < bestPos) then
			bestPos = bottom
			bestFrame = frame
		end
	end

	-- Owner itself
	consider(owner)

	-- Blizzard comparison tooltips (common sources of "behind" issues)
	consider(_G.ShoppingTooltip1)
	consider(_G.ShoppingTooltip2)
	consider(_G.ShoppingTooltip3)
	consider(_G.ItemRefShoppingTooltip1)
	consider(_G.ItemRefShoppingTooltip2)
	consider(_G.ItemRefShoppingTooltip3)

	-- Retail: some tooltips keep a list of comparison tooltips
	if owner.shoppingTooltips then
		for _, tip in pairs(owner.shoppingTooltips) do
			consider(tip)
		end
	end
	if owner.comparisonTooltips then
		for _, tip in pairs(owner.comparisonTooltips) do
			consider(tip)
		end
	end

	-- Explicit known addon cases (cheap and predictable)
	local isAddOnLoaded = BSYC.API and BSYC.API.IsAddOnLoaded
	if isAddOnLoaded and isAddOnLoaded("TradeSkillMaster") then
		for i = 1, 20 do
			local t = _G["TSMExtraTip" .. i]
			if t and t.IsVisible and t:IsVisible() then
				consider(t)
			elseif not t then
				break
			end
		end
	end

	if LibStub and LibStub.libs and LibStub.libs["LibExtraTip-1"] then
		local t = LibStub("LibExtraTip-1"):GetExtraTip(owner)
		if t and t.IsVisible and t:IsVisible() then
			consider(t)
		end
	end

	if BPBID_BreedTooltip or BPBID_BreedTooltip2 then
		local t = BPBID_BreedTooltip or BPBID_BreedTooltip2
		if t and t.IsVisible and t:IsVisible() then
			consider(t)
		end
	end

	return bestFrame, bestPos
end

function Tooltip:GetBottomTooltipAnchorCached(owner)
	if not owner then return nil end

	-- Single-cache is enough: ExtTip shows for only one owner at a time.
	local cachedOwner = self.__extTipAnchorOwner
	local cachedSig = self.__extTipAnchorSig
	local cachedAnchor = self.__extTipAnchorFrame

	local sig = 5381

	local function sigAdd(n)
		sig = (sig * 33 + (n or 0)) % 2147483647
	end

	local function consider(frame, weight)
		if not frame or not frame.GetBottom then
			sigAdd(7 + (weight or 0))
			return nil
		end

		-- Visibility/relationship gates both anchoring and signature.
		if not IsRelatedTooltipFrame(frame, owner) then
			sigAdd(13 + (weight or 0))
			return nil
		end

		local bottom = frame:GetBottom()
		local q = QuantizeCoord(bottom)
		sigAdd((q * 31) + (weight or 0))

		return frame, bottom
	end

	-- Owner position affects where we anchor (TOP/BOTTOM and LEFT/RIGHT logic).
	local cx, cy = owner:GetCenter()
	sigAdd(QuantizeCoord(cx))
	sigAdd(QuantizeCoord(cy))

	-- Compute signature across the same candidate set used for anchoring.
	consider(owner, 1)
	consider(_G.ShoppingTooltip1, 2)
	consider(_G.ShoppingTooltip2, 3)
	consider(_G.ShoppingTooltip3, 4)
	consider(_G.ItemRefShoppingTooltip1, 5)
	consider(_G.ItemRefShoppingTooltip2, 6)
	consider(_G.ItemRefShoppingTooltip3, 7)

	if owner.shoppingTooltips then
		local w = 10
		for _, tip in pairs(owner.shoppingTooltips) do
			consider(tip, w)
			w = w + 1
		end
	end
	if owner.comparisonTooltips then
		local w = 40
		for _, tip in pairs(owner.comparisonTooltips) do
			consider(tip, w)
			w = w + 1
		end
	end

	local isAddOnLoaded = BSYC.API and BSYC.API.IsAddOnLoaded
	if isAddOnLoaded and isAddOnLoaded("TradeSkillMaster") then
		for i = 1, 20 do
			local t = _G["TSMExtraTip" .. i]
			if t and t.IsVisible and t:IsVisible() then
				consider(t, 100 + i)
			elseif not t then
				break
			end
		end
	end

	if LibStub and LibStub.libs and LibStub.libs["LibExtraTip-1"] then
		local t = LibStub("LibExtraTip-1"):GetExtraTip(owner)
		if t and t.IsVisible and t:IsVisible() then
			consider(t, 200)
		end
	end

	if BPBID_BreedTooltip or BPBID_BreedTooltip2 then
		local t = BPBID_BreedTooltip or BPBID_BreedTooltip2
		if t and t.IsVisible and t:IsVisible() then
			consider(t, 300)
		end
	end

	-- Cache hit: ensure the cached anchor still qualifies.
	if cachedOwner == owner and cachedSig == sig and cachedAnchor and IsRelatedTooltipFrame(cachedAnchor, owner) then
		return cachedAnchor
	end

	-- Cache miss: compute best anchor and store signature.
	local bestFrame = owner
	local bestPos = owner:GetBottom()

	local function pick(frame)
		if not frame or not frame.GetBottom then return end
		if not IsRelatedTooltipFrame(frame, owner) then return end
		local bottom = frame:GetBottom()
		if bottom and (not bestPos or bottom < bestPos) then
			bestPos = bottom
			bestFrame = frame
		end
	end

	pick(owner)
	pick(_G.ShoppingTooltip1)
	pick(_G.ShoppingTooltip2)
	pick(_G.ShoppingTooltip3)
	pick(_G.ItemRefShoppingTooltip1)
	pick(_G.ItemRefShoppingTooltip2)
	pick(_G.ItemRefShoppingTooltip3)

	if owner.shoppingTooltips then
		for _, tip in pairs(owner.shoppingTooltips) do
			pick(tip)
		end
	end
	if owner.comparisonTooltips then
		for _, tip in pairs(owner.comparisonTooltips) do
			pick(tip)
		end
	end

	local isAddOnLoaded = BSYC.API and BSYC.API.IsAddOnLoaded
	if isAddOnLoaded and isAddOnLoaded("TradeSkillMaster") then
		for i = 1, 20 do
			local t = _G["TSMExtraTip" .. i]
			if t and t.IsVisible and t:IsVisible() then
				pick(t)
			elseif not t then
				break
			end
		end
	end

	if LibStub and LibStub.libs and LibStub.libs["LibExtraTip-1"] then
		local t = LibStub("LibExtraTip-1"):GetExtraTip(owner)
		if t and t.IsVisible and t:IsVisible() then
			pick(t)
		end
	end

	if BPBID_BreedTooltip or BPBID_BreedTooltip2 then
		local t = BPBID_BreedTooltip or BPBID_BreedTooltip2
		if t and t.IsVisible and t:IsVisible() then
			pick(t)
		end
	end

	self.__extTipAnchorOwner = owner
	self.__extTipAnchorSig = sig
	self.__extTipAnchorFrame = bestFrame

	return bestFrame
end

function Tooltip:SetExtTipAnchor(owner, anchor, extTip)
	Debug(BSYC_DL.SL2, "SetExtTipAnchor", owner, anchor, extTip)

	anchor = anchor or owner
	local x, y = owner:GetCenter()
	if not x or not y then
		extTip:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT")
		return
	end

	local hhalf = (x > UIParent:GetWidth() * 2 / 3) and "LEFT" or (x < UIParent:GetWidth() / 3) and "RIGHT" or ""
	local vhalf = (y > UIParent:GetHeight() / 4) and "TOP" or "BOTTOM"

	extTip:SetPoint(vhalf .. hhalf, anchor, (vhalf == "TOP" and "BOTTOM" or "TOP") .. hhalf)
end

function Tooltip:UpdateExtTipAnchor()
	local frame, extTip = Tooltip.objTooltip, Tooltip.extTip
	if not frame or not extTip or not extTip:IsShown() then return end

	extTip:ClearAllPoints()
	local anchor = self:GetBottomTooltipAnchorCached(frame) or frame
	if anchor == extTip then anchor = frame end
	self:SetExtTipAnchor(frame, anchor, extTip)
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
	if BSYC.options.enableTooltips == false then return end
	if not CanAccessObject(objTooltip) then return end
	if Scanner.isScanningGuild then return end --don't tally while we are scanning the Guildbank

	local opts = BSYC.options
	local tracking = BSYC.tracking
	local GetItemCount = C_Item and C_Item.GetItemCount

	--check for modifier option only in windows that isn't BagSync search
	if not self:CheckModifier() and not objTooltip.isBSYCSearch then return end

	local showExtTip = Tooltip:ExtTipCheck(source, isBattlePet)
	local skipTally = false

	Tooltip.objTooltip = objTooltip

	--only show tooltips in search frame if the option is enabled
	if BSYC.options.tooltipOnlySearch and not objTooltip.isBSYCSearch then
		if Tooltip.extTip then Tooltip.extTip:Hide() end
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
		if Tooltip.extTip then Tooltip.extTip:Hide() end
		objTooltip:Show()
		Debug(BSYC_DL.WARN, "TallyUnits", "NoLink", origLink, source, isBattlePet)
		return
	end

	--if we already did the item, then display the previous information, use the unparsed link to verify
	if self.__lastLink and self.__lastLink == origLink then
		if self.__lastTally and #self.__lastTally > 0 then
			for i=1, #self.__lastTally do
				local color = self:GetClassColor(self.__lastTally[i].unitObj, 2, false, BSYC.colors.total)
				if showExtTip then
					Tooltip.extTip:AddDoubleLine(self.__lastTally[i].colorized, self.__lastTally[i].tallyString, color.r, color.g, color.b, color.r, color.g, color.b)
				else
					objTooltip:AddDoubleLine(self.__lastTally[i].colorized, self.__lastTally[i].tallyString, color.r, color.g, color.b, color.r, color.g, color.b)
				end
			end
			objTooltip:Show()
			if showExtTip then
				Tooltip:ApplyExtTipFont()
				Tooltip.extTip:Show()
				Tooltip:UpdateExtTipAnchor()
			end
		end
		objTooltip.__tooltipUpdated = true
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

	local useUniqueTotals = opts.enableShowUniqueItemsTotals

	--short the shortID and ignore all BonusID's and stats
	if useUniqueTotals then link = shortID end

	--store these in the addon itself not in the tooltip
	self.__lastTally = {}
	self.__lastLink = origLink

	local grandTotal = 0
	local unitList = {}
	local countList = WipeTable(self.__scratchCountList or {})
	self.__scratchCountList = countList
	local player = Unit:GetPlayerInfo()
	local guildObj = Data:GetPlayerGuildObj(player)
	local warbandObj = Data:GetWarbandBankObj()

	local allowList = BSYC.DEFAULT_ALLOW_LIST

	--the true option for GetModule is to set it to silent and not return an error if not found
	--only display advanced search results in the BagSync search window, but make sure to show tooltips regularly outside of that by checking isBSYCSearch
	local advUnitList = not skipTally and objTooltip.isBSYCSearch and BSYC.advUnitList
	local turnOffCache = (opts.debug.enable and opts.debug.cache and true) or false
	local advPlayerChk = false
	local advPlayerGuildChk = false
	local doCurrentPlayerOnly = opts.showCurrentCharacterOnly or (opts.showBLCurrentCharacterOnly and personalBlacklist)

	Debug(BSYC_DL.SL2, "TallyUnits", "|cFFe454fd[Item]|r", link, shortID, origLink, skipTally, advUnitList, turnOffCache, doCurrentPlayerOnly)

	--DB TOOLTIP COUNTS
	-------------------
	if advUnitList or not skipTally then

		--OTHER PLAYERS AND GUILDS
		-----------------
		--CACHE CHECK
		--NOTE: This cache check is ONLY for units (guild, players) that isn't related to the current player.  Since that data doesn't really change we can cache those lines
		--For the player however, we always want to grab the latest information.  So once it's grabbed we can do a small local cache for that using __lastTally
		--Advanced Searches should always be processed and not stored in the cache
		if turnOffCache or advUnitList or (not Data.__cache.tooltip[origLink] and not doCurrentPlayerOnly) then

			--allow advance search matches if found, no need to set to true as advUnitList will default to dumpAll if found
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
						for k in pairs(allowList) do
							unitTotal = unitTotal + self:AddItems(unitObj, link, k, countList)
						end
					elseif advUnitList then
						advPlayerChk = true
					end
				else
					--don't cache the players guild bank, lets get that in real time in case they put stuff in it
					if not guildObj or (unitObj.data ~= guildObj.data) then
						Debug(BSYC_DL.SL2, "TallyUnits", "[Guild]", unitObj.name, unitObj.realm)
						unitTotal = unitTotal + self:AddItems(unitObj, link, "guild", countList)
					elseif advUnitList then
						advPlayerGuildChk = true
					end
				end

				--only process the totals if we have something to work with
				if unitTotal > 0 then
					grandTotal = grandTotal + unitTotal
					--table variables gets passed as byRef
					self:UnitTotals(unitObj, countList, unitList, advUnitList)
				end
			end

				--do not cache if we are viewing an advanced search list, otherwise it won't display everything normally
				--finally, only cache if we have something to work with
				if not turnOffCache and not advUnitList then
					--store it in the cache (shallow copy to avoid deep-copying DB references)
					local cachedUnitList = (grandTotal > 0 and ShallowCopyArray(unitList)) or {}
					if Data and Data.SetTooltipCache then
						Data:SetTooltipCache(origLink, cachedUnitList, grandTotal)
					else
						Data.__cache.tooltip[origLink] = Data.__cache.tooltip[origLink] or {}
						Data.__cache.tooltip[origLink].unitList = cachedUnitList
						Data.__cache.tooltip[origLink].grandTotal = grandTotal
					end
				end
			elseif Data.__cache.tooltip[origLink] and not doCurrentPlayerOnly then
				--use cached results from previous DB searches; copy array so we can append current-player data safely
				unitList = ShallowCopyArray(Data.__cache.tooltip[origLink].unitList)
				grandTotal = Data.__cache.tooltip[origLink].grandTotal or 0
				Debug(BSYC_DL.INFO, "TallyUnits", "|cFF09DBE0CacheUsed|r", origLink)
			end

		Debug(BSYC_DL.SL2, "TallyUnits", "|cFF4DD827[AdvChk]|r", advUnitList, advPlayerChk, advPlayerGuildChk)

		--CURRENT PLAYER
		-----------------
		local carriedCount
		local bankTotalCount
		local reagentTotalCount
		local warbandTotalCount

		if not advUnitList or advPlayerChk then
			WipeTable(countList)
			local playerTotal = 0
			local playerObj = Data:GetPlayerObj(player)
			Debug(BSYC_DL.SL2, "TallyUnits", "|cFF4DD827[CurrentPlayer]|r", playerObj.name, playerObj.realm, link)

			--grab the equip count as we need that below for an accurate count on the bags, bank and reagents
			playerTotal = playerTotal + self:AddItems(playerObj, link, "equip", countList)
			--C_Item.GetItemCount does not work in the auction, void bank or mailbox, so grab it manually
			playerTotal = playerTotal + self:AddItems(playerObj, link, "auction", countList)
			playerTotal = playerTotal + self:AddItems(playerObj, link, "void", countList)
			playerTotal = playerTotal + self:AddItems(playerObj, link, "mailbox", countList)

			--C_Item.GetItemCount does not work on battlepet links either, grab bag, bank and reagents
			if isBattlePet then
				playerTotal = playerTotal + self:AddItems(playerObj, link, "bag", countList)
				playerTotal = playerTotal + self:AddItems(playerObj, link, "bank", countList)
				playerTotal = playerTotal + self:AddItems(playerObj, link, "reagents", countList)

			else
				local equipCount = countList["equip"] or 0
				local carryCount, bagCount, bankCount, regCount = 0, 0, 0, 0

				carriedCount = carriedCount or ((GetItemCount and GetItemCount(origLink)) or 0) --get the total amount the player is currently carrying (bags + equip)

				carryCount = carriedCount
				bagCount = carryCount - equipCount -- subtract the equipment count from the carry amount to get bag count

				if bagCount < 0 then bagCount = 0 end

				if IsReagentBankUnlocked and IsReagentBankUnlocked() then
					--C_Item.GetItemCount returns the bag count + reagent regardless of parameters.  So we have to subtract bag and reagents.  This does not include bank totals
					reagentTotalCount = reagentTotalCount or ((GetItemCount and GetItemCount(origLink, false, false, true, false)) or 0)

					regCount = reagentTotalCount
					regCount = regCount - carryCount
					if regCount < 0 then regCount = 0 end
				end

				--bankCount = C_Item.GetItemCount returns the bag + bank count regardless of parameters.  So we have to subtract the carry totals
				bankTotalCount = bankTotalCount or ((GetItemCount and GetItemCount(origLink, true, false, false, false)) or 0)

				bankCount = bankTotalCount
				bankCount = (bankCount - carryCount)
				if bankCount < 0 then bankCount = 0 end

				-- --now assign the values (check for disabled modules)
				if not tracking.bag then bagCount = 0 end
				if not tracking.bank then bankCount = 0 end
				if not tracking.reagents then regCount = 0 end

				if bagCount > 0 then
					self:GetEquipBags("bag", playerObj, link, countList)
				end
				if bankCount > 0 then
					self:GetEquipBags("bank", playerObj, link, countList)
				end

				if BSYC.IsBankTabsActive and opts.showBankTabs then
					--we do this so we can grab the btabs, even if we use a real time count from GetItemCount.
					self:AddItems(playerObj, link, "bank", countList)
				end

				countList.bag = bagCount
				countList.bank = bankCount
				countList.reagents = regCount
				playerTotal = playerTotal + (bagCount + bankCount + regCount)
			end

			if playerTotal > 0 then
				grandTotal = grandTotal + playerTotal
				--table variables gets passed as byRef
				self:UnitTotals(playerObj, countList, unitList, advUnitList)
			end
		end

		--CURRENT PLAYER GUILD
		--We do this separately so that the guild has it's own line in the unitList and not included inline with the player character
		--We also want to do this in real time and not cache, otherwise they may put stuff in their guild bank which will not be reflected in a cache
		-----------------
		if guildObj and (not advUnitList or advPlayerGuildChk) then
			Debug(BSYC_DL.SL2, "TallyUnits", "|cFF4DD827[CurrentPlayer-Guild]|r", player.guild, player.guildrealm)
			WipeTable(countList)
			local guildTotal = self:AddItems(guildObj, link, "guild", countList)
			if guildTotal > 0 then
				grandTotal = grandTotal + guildTotal
				--table variables gets passed as byRef
				self:UnitTotals(guildObj, countList, unitList, advUnitList)
			end
		end

		--Warband Bank can updated frequently, so we need to collect in real time and not cached
		if warbandObj and allowList.warband and not advUnitList then
			Debug(BSYC_DL.SL2, "TallyUnits", "|cFF4DD827[Warband]|r")
			WipeTable(countList)
			local warbandTotal = 0

			if isBattlePet then
				warbandTotal = warbandTotal + self:AddItems(warbandObj, link, "warband", countList)

			else
				if opts.showWarbandTabs then
					--we do this so we can grab the wtabs, even if we use a real time count from GetItemCount.
					self:AddItems(warbandObj, link, "warband", countList)
				end

				carriedCount = carriedCount or ((GetItemCount and GetItemCount(origLink)) or 0) --get the total amount the player is currently carrying (bags + equip)
				warbandTotalCount = warbandTotalCount or ((GetItemCount and GetItemCount(origLink, false, false, false, true)) or 0)

				local carryCount = carriedCount
				local warbandCount = warbandTotalCount
				warbandCount = warbandCount - carryCount

				if not tracking.warband then warbandCount = 0 end
				--overwride the countList if we are grabbing tabs
				countList.warband = warbandCount
				warbandTotal = warbandTotal + warbandCount
			end

			if warbandTotal > 0 then
				grandTotal = grandTotal + warbandTotal
				--table variables gets passed as byRef
				self:UnitTotals(warbandObj, countList, unitList, advUnitList)
			end
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
	local desc, value = '', ''
	local addSeparator = false

	--add [Total] if we have more than one unit to work with
	if not skipTally and opts.showTotal and grandTotal > 0 and #unitList > 1 then
		--add a separator after the character list
		tinsert(unitList, { colorized=" ", tallyString=" "} )

		desc = self:HexColor(BSYC.colors.total, L.TooltipTotal)
		value = self:HexColor(BSYC.colors.second, comma_value(grandTotal))
		tinsert(unitList, { colorized=desc, tallyString=value} )
	end

	--add ItemID
	if opts.enableTooltipItemID and shortID then
		desc = self:HexColor(BSYC.colors.itemid, L.TooltipItemID)
		value = self:HexColor(BSYC.colors.second, shortID)
		if isBattlePet then
			desc = string.format("|cFFCA9BF7%s|r ", L.TooltipFakeID)
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
				local xGetItemInfo = BSYC.API and BSYC.API.GetItemInfo
				expacID = xGetItemInfo and select(15, xGetItemInfo(shortID))
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
				local xGetItemInfo = BSYC.API and BSYC.API.GetItemInfo
				if xGetItemInfo then
					itemType, itemSubType, _, _, _, _, classID, subclassID = select(6, xGetItemInfo(shortID))
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
	for i=1, #unitList do
		local color = self:GetClassColor(unitList[i].unitObj, 2, false, BSYC.colors.total)
		if showExtTip then
			Tooltip.extTip:AddDoubleLine(unitList[i].colorized, unitList[i].tallyString, color.r, color.g, color.b, color.r, color.g, color.b)
		else
			objTooltip:AddDoubleLine(unitList[i].colorized, unitList[i].tallyString, color.r, color.g, color.b, color.r, color.g, color.b)
		end
	end

	--this is only a local cache for the current tooltip and will be reset on bag updates, it is not the same as Data.__cache.tooltip
	self.__lastTally = unitList

	objTooltip.__tooltipUpdated = true
	objTooltip:Show()

	if showExtTip then
		if #unitList > 0 then
			Tooltip:ApplyExtTipFont()
			Tooltip.extTip:Show()
			Tooltip:UpdateExtTipAnchor()
		else
			Tooltip.extTip:Hide()
		end
	end

	local WLChk = (opts.enableWhitelist and "WL-ON") or "WL-OFF"
	Debug(BSYC_DL.INFO, "|cFF52D386TallyUnits|r", link, shortID, source, isBattlePet, grandTotal, WLChk)
end

function Tooltip:CurrencyTooltip(objTooltip, currencyName, currencyIcon, currencyID, source)
	if not BSYC.tracking.currency then return end
	if BSYC.options.enableCurrencyWindowTooltipData == false and source ~= "bagsync_currency" then return end

	--check for modifier option
	if not self:CheckModifier() and source ~= "bagsync_currency" then return end

	currencyID = tonumber(currencyID) --make sure it's a number we are working with and not a string
	if not currencyID then return end

	local showExtTip = Tooltip:ExtTipCheck(source, false)

	--if we already did the currency, then display the previous information, use the unparsed link to verify
	if self.__lastCurrencyID and self.__lastCurrencyID == currencyID then
		if self.__lastCurrencyTally and #self.__lastCurrencyTally > 0 then
			Tooltip.objTooltip = objTooltip
			for i=1, #self.__lastCurrencyTally do
				if showExtTip then
					Tooltip.extTip:AddDoubleLine(self.__lastCurrencyTally[i][1], self.__lastCurrencyTally[i][2], 1, 1, 1, 1, 1, 1)
				else
					objTooltip:AddDoubleLine(self.__lastCurrencyTally[i][1], self.__lastCurrencyTally[i][2], 1, 1, 1, 1, 1, 1)
				end
			end
			objTooltip:Show()
			if showExtTip then
				Tooltip:ApplyExtTipFont()
				Tooltip.extTip:Show()
				Tooltip:UpdateExtTipAnchor()
			end
		end
		objTooltip.__tooltipUpdated = true
		return
	end

	Debug(BSYC_DL.INFO, "CurrencyTooltip", currencyName, currencyIcon, currencyID, source, BSYC.tracking.currency)

	Tooltip.objTooltip = objTooltip

	--loop through our characters
	local usrData = {}
	local grandTotal = 0

	self.__lastCurrencyID = currencyID
	self.__lastCurrencyTally = {}

	-- local permIgnore ={
	-- 	[2032] = "Trader's Tender", --shared across all characters
	-- }
	--if permIgnore[currencyID] then return end

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

				table.insert(usrData, {
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

	-- if currencyName then
	-- 	table.insert(displayList, {string.format("|cff%s%s|r", RGBPercToHex(64/255, 224/255, 208/255), tostring(currencyName)), " "})
	-- 	table.insert(displayList, {" ", " "})
	-- end

	for i=1, #usrData do
		if usrData[i].count then
			table.insert(displayList, {usrData[i].colorized, comma_value(usrData[i].count)})
		end
	end
	if #usrData <= 0 then
		table.insert(displayList, {NONE, " "})
	end

	--this is for trader tenders since they are account wide, only add them once
	-- if currencyID == 2032 then
	-- 	table.insert(displayList, {"|cffff7d0a["..L.DisplayTooltipAccountWide.."]|r", " "})
	-- end

	--add [Total]
	if BSYC.options.showTotal and grandTotal > 0 and #displayList > 1 then
		--add a separator
		table.insert(displayList, {" ", " "})
		local desc = self:HexColor(BSYC.colors.total, L.TooltipTotal)
		local value = self:HexColor(BSYC.colors.second, comma_value(grandTotal))
		table.insert(displayList, {desc, value})
	end

	if BSYC.options.enableTooltipItemID and currencyID then
		local desc = self:HexColor(BSYC.colors.itemid, L.TooltipCurrencyID)
		local value = self:HexColor(BSYC.colors.second, currencyID)
		table.insert(displayList, 1, {" ", " "})
		table.insert(displayList, 1,  {desc, value})
	end

	--finally display it
	for i=1, #displayList do
		if showExtTip then
			Tooltip.extTip:AddDoubleLine(displayList[i][1], displayList[i][2], 1, 1, 1, 1, 1, 1)
		else
			objTooltip:AddDoubleLine(displayList[i][1], displayList[i][2], 1, 1, 1, 1, 1, 1)
		end
	end

	self.__lastCurrencyTally = displayList

	objTooltip.__tooltipUpdated = true
	objTooltip:Show()
	if showExtTip then
		Tooltip:ApplyExtTipFont()
		Tooltip.extTip:Show()
		Tooltip.objTooltip = objTooltip
		Tooltip:UpdateExtTipAnchor()
	end
end

local arkAlreadyHooked = false

function Tooltip:HookTooltip(objTooltip)
	--if the tooltip doesn't exist, chances are it's the BattlePetTooltip and they are on Classic or WOTLK
	if not objTooltip then return end

	Debug(BSYC_DL.INFO, "HookTooltip", objTooltip)

	--MORE INFO (https://wowpedia.fandom.com/wiki/Category:API_namespaces/C_TooltipInfo)
	--https://wowpedia.fandom.com/wiki/Patch_10.0.2/API_changes#Tooltip_Changes
	--https://github.com/tomrus88/BlizzardInterfaceCode/blob/e4385aa29a69121b3a53850a8b2fcece9553892e/Interface/SharedXML/Tooltip/TooltipDataHandler.lua
	--https://wowpedia.fandom.com/wiki/Patch_10.0.2/API_changes

	objTooltip:HookScript("OnHide", function(self)
		self.__tooltipUpdated = false
		if Tooltip.extTip then Tooltip.extTip:Hide() end
		Tooltip.__extTipAnchorOwner = nil
		Tooltip.__extTipAnchorSig = nil
		Tooltip.__extTipAnchorFrame = nil
	end)
	--the battlepet tooltips don't use this, so check for it
	if objTooltip ~= BattlePetTooltip and objTooltip ~= FloatingBattlePetTooltip then
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
			if BattlePetTooltip and objTooltip == BattlePetTooltip then
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
			if FloatingBattlePetTooltip and objTooltip == FloatingBattlePetTooltip then
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

	if C_TooltipInfo then

		--Note: tooltip data type corresponds to the Enum.TooltipDataType types
		--i.e Enum.TooltipDataType.Unit it type 2
		--see https://github.com/tomrus88/BlizzardInterfaceCode/blob/de20049d4dc15eb268fb959148220acf0a23694c/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoSharedDocumentation.lua

		local function OnTooltipSetItem(tooltip, data)
			if (tooltip == GameTooltip or tooltip == EmbeddedItemTooltip or tooltip == ItemRefTooltip) then
				if tooltip.__tooltipUpdated then return end

				local link

					--data.guid is given to items that have additional bonus stats and such and basically do not return a simple itemID #
					if data.guid then
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
		end
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)

		local function OnTooltipSetCurrency(tooltip, data)
			if (tooltip == GameTooltip or tooltip == EmbeddedItemTooltip or tooltip == ItemRefTooltip) then
				if tooltip.__tooltipUpdated then return end

				local link = data.id or data.hyperlink
				local currencyID = BSYC:GetShortCurrencyID(link)

				if currencyID then
					--WOTLK still uses the old API functions, check for it
					local xGetCurrencyInfo = (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) or GetCurrencyInfo
					local currencyData = xGetCurrencyInfo(currencyID)
					if currencyData then
						Tooltip:CurrencyTooltip(tooltip, currencyData.name, currencyData.iconFileID, currencyID, "OnTooltipSetCurrency")
					end
				end
			end
		end
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Currency, OnTooltipSetCurrency)

	else

		if objTooltip ~= BattlePetTooltip and objTooltip ~= FloatingBattlePetTooltip then
			objTooltip:HookScript("OnTooltipSetItem", function(self)
				if self.__tooltipUpdated then return end
				local name, link = self:GetItem()
				if link then
					--sometimes the link is an empty link with the name being |h[]|h, its a bug with GetItem()
					--so lets check for that
					local linkName = string.match(link, "|h%[(.-)%]|h")
					if not linkName or string.len(linkName) < 1 then return nil end  -- we don't want to store or process it

					Tooltip:TallyUnits(self, link, "OnTooltipSetItem")
				end
			end)
		end

		if objTooltip.SetQuestLogItem then
			hooksecurefunc(objTooltip, "SetQuestLogItem", function(self, itemType, index)
				if self.__tooltipUpdated then return end
				local link = GetQuestLogItemLink(itemType, index)
				if link then
					Tooltip:TallyUnits(self, link, "SetQuestLogItem")
				end
			end)
		end
		if objTooltip.SetQuestItem then
			hooksecurefunc(objTooltip, "SetQuestItem", function(self, itemType, index)
				if self.__tooltipUpdated then return end
				local link = GetQuestItemLink(itemType, index)
				if link then
					Tooltip:TallyUnits(self, link, "SetQuestItem")
				end
			end)
		end

		--C_CurrencyInfo.GetCurrencyListInfo
		--https://www.townlong-yak.com/framexml/live/Blizzard_TokenUI/Blizzard_TokenUI.lua#383
		if objTooltip.SetCurrencyToken then
			hooksecurefunc(objTooltip, "SetCurrencyToken", function(self, currencyIndex)
				local link = C_CurrencyInfo.GetCurrencyListLink(currencyIndex)
				local xGetCurrencyInfo = (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) or GetCurrencyInfo
				if link then
					--local id = tonumber(string.match(link,"currency:(%d+)"))
					--local name = C_CurrencyInfo.GetCurrencyInfo(id).name


					--https://www.townlong-yak.com/framexml/55818/Blizzard_TokenUI/Blizzard_TokenUI.lua#307
					-- local currencyData = C_CurrencyInfo.GetCurrencyListInfo(currencyIndex);
					-- if currencyData then
					-- 	currencyData.currencyIndex = currencyIndex;
					-- 	tinsert(currencyList, currencyData);
					-- end

					local currencyID = BSYC:GetShortCurrencyID(link)

					if currencyID then
						--WOTLK still uses the old API functions, check for it
						local currencyData = xGetCurrencyInfo(currencyID)
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
				local _, _, count = GetCraftReagentInfo(index, reagent)
				--YOU NEED to do the above or it will return an empty link!
				local link = GetCraftReagentItemLink(index, reagent)
				if link then
					Tooltip:TallyUnits(self, link, "SetCraftItem")
				end
			end)
		end

	end

end

function Tooltip:OnEnable()
	Debug(BSYC_DL.INFO, "OnEnable")

	self:HookTooltip(GameTooltip)
	self:HookTooltip(ItemRefTooltip)
	self:HookTooltip(EmbeddedItemTooltip)
	self:HookTooltip(BattlePetTooltip)
	self:HookTooltip(FloatingBattlePetTooltip)
end
