--[[
	tooltip.lua
		Tooltip module for BagSync

		BagSync - All Rights Reserved - (c) 2024
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Tooltip = BSYC:NewModule("Tooltip")
local Unit = BSYC:GetModule("Unit")
local Data = BSYC:GetModule("Data")
local Scanner = BSYC:GetModule("Scanner")
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local LibQTip = LibStub("LibQTip-1.0")

--https://github.com/tomrus88/BlizzardInterfaceCode/blob/classic/Interface/GlueXML/CharacterCreate.lua
RACE_ICON_TCOORDS = {
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
local FIXED_RACE_ATLAS = {
	["highmountaintauren"] = "highmountain",
	["lightforgeddraenei"] = "lightforged",
	["scourge"] = "undead",
	["zandalaritroll"] = "zandalari",
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
		if not unitObj.isGuild and unitObj.realm == _G.GetRealmName() then
			return 1
		elseif unitObj.isGuild and unitObj.realm == _G.GetRealmName() then
			return 2
		elseif not unitObj.isGuild and unitObj.isConnectedRealm then
			return 3
		elseif unitObj.isGuild and unitObj.isConnectedRealm then
			return 4
		elseif not unitObj.isGuild then
			return 5
		elseif unitObj.isWarbandBank then
			--sort warband banks just above other server guilds
			return 6
		end
	end
	--other server guilds should be sorted last
	return 7
end

function Tooltip:GetRaceIcon(race, gender, size, xOffset, yOffset, useHiRez)
	local raceString = ""
	if not race or not gender then return raceString end

	if BSYC.IsClassic then
		race = race:upper()
		local raceFile = "Interface/Glues/CharacterCreate/UI-CharacterCreate-Races"
		local coords = RACE_ICON_TCOORDS[race.."_"..(gender == 3 and "FEMALE" or "MALE")]
		local left, right, top, bottom = unpack(coords)

		raceString = CreateTextureMarkup(raceFile, 128, 128, size, size, left, right, top, bottom, xOffset, yOffset)
	else
		race = race:lower()
		race = FIXED_RACE_ATLAS[race] or race

		local formatingString = useHiRez and "raceicon128-%s-%s" or "raceicon-%s-%s"
		formatingString = formatingString:format(race, gender == 3 and "female" or "male")

		raceString =  CreateAtlasMarkup(formatingString, size, size, xOffset, yOffset)
	end

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

	--sort the list by our sortIndex then by realm and finally by name
	if BSYC.options.sortTooltipByTotals then
		table.sort(tblData, function(a, b)
			return a.count > b.count;
		end)
	elseif BSYC.options.sortByCustomOrder then
		table.sort(tblData, function(a, b)
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
	if not unitObj.data.equipbags or not unitObj.data.equipbags[target] then return 0 end

	local iCount = 0
	local tmpSlots = ""

	for i=1, #unitObj.data.equipbags[target] do
		local link, count, qOpts = BSYC:Split(unitObj.data.equipbags[target][i], false)
		if BSYC.options.enableShowUniqueItemsTotals then link = BSYC:GetShortItemID(link) end
		if link then
			if link == itemID and qOpts and qOpts.bagslot then
				tmpSlots = tmpSlots..","..qOpts.bagslot
				iCount = iCount + (count or 1)
			end
		end
	end

	if iCount > 0 then
		tmpSlots = string.sub(tmpSlots, 2)  -- remove comma
		countList[target.."slots"] = self:HexColor(BSYC.colors.bagslots, " <"..tmpSlots..">")
	elseif countList[target.."slots"] then
		countList[target.."slots"] = nil
	end

	return iCount
end

function Tooltip:AddItems(unitObj, itemID, target, countList, isCurrentPlayer)
	local total = 0
	if not unitObj or not itemID or not target or not countList then return total end
	if not unitObj.data then return total end

	local function getTotal(data, target)
		local iCount = 0
		for i=1, #data do
			if data[i] then
				local link, count = BSYC:Split(data[i], true)
				if BSYC.options.enableShowUniqueItemsTotals then link = BSYC:GetShortItemID(link) end
				if link then
					if link == itemID then
						iCount = iCount + (count or 1)
					end
				end
			end
		end
		return iCount
	end

	if unitObj.data[target] and BSYC.tracking[target] then
		if target == "bag" or target == "bank" or target == "reagents" then
			for bagID, bagData in pairs(unitObj.data[target] or {}) do
				total = total + getTotal(bagData, target)
			end
			if target == "bag" or target == "bank" then
				total = total + self:GetEquipBags(target, unitObj, itemID, countList)
			end
		elseif target == "auction" then
			total = getTotal(unitObj.data[target].bag or {}, target)

		elseif target == "equip" or target == "void" or target == "mailbox" then
			total = getTotal(unitObj.data[target] or {}, target)
		end
	end
	if target == "guild" and BSYC.tracking.guild then
		countList.gtab = {}
		for tabID, tabData in pairs(unitObj.data.tabs or {}) do
			local tabCount = getTotal(tabData, target)
			if tabCount > 0 then
				countList.gtab[tabID] = tabCount
			end
			total = total + tabCount
		end
	end

	if target == "warband" and BSYC.tracking.warband then
		countList.wtab = {}
		for tabID, tabData in pairs(unitObj.data.tabs or {}) do
			local tabCount = getTotal(tabData, target)
			if tabCount > 0 then
				countList.wtab[tabID] = tabCount
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
	local tallyCount = {}
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
		table.insert(tallyCount, self:GetCountString(colorType, dispType, "bag", countList["bag"], BSYC.options.showEquipBagSlots and countList["bagslots"]))
	end
	if ((countList["bank"] or 0) > 0) then
		total = total + countList["bank"]
		table.insert(tallyCount, self:GetCountString(colorType, dispType, "bank", countList["bank"], BSYC.options.showEquipBagSlots and countList["bankslots"]))
	end
	if ((countList["reagents"] or 0) > 0) then
		total = total + countList["reagents"]
		table.insert(tallyCount, self:GetCountString(colorType, dispType, "reagents", countList["reagents"]))
	end
	if ((countList["equip"] or 0) > 0) then
		total = total + countList["equip"]
		table.insert(tallyCount, self:GetCountString(colorType, dispType, "equip", countList["equip"]))
	end
	if ((countList["mailbox"] or 0) > 0) then
		total = total + countList["mailbox"]
		table.insert(tallyCount, self:GetCountString(colorType, dispType, "mailbox", countList["mailbox"]))
	end
	if ((countList["void"] or 0) > 0) then
		total = total + countList["void"]
		table.insert(tallyCount, self:GetCountString(colorType, dispType, "void", countList["void"]))
	end
	if ((countList["auction"] or 0) > 0) then
		total = total + countList["auction"]
		table.insert(tallyCount, self:GetCountString(colorType, dispType, "auction", countList["auction"]))
	end
	if ((countList["guild"] or 0) > 0) then
		total = total + countList["guild"]
		local gTabStr = ""

		--check for guild tabs first
		if BSYC.options.showGuildTabs then
			table.sort(countList["gtab"], function(a, b) return a < b end)

			for k, v in pairs(countList["gtab"]) do
				gTabStr = gTabStr..","..tostring(k)
			end
			gTabStr = string.sub(gTabStr, 2)  -- remove comma

			--check for guild tab
			if string.len(gTabStr) > 0 then
				gTabStr = self:HexColor(BSYC.colors.guildtabs, " ["..L.TooltipGuildTabs.." "..gTabStr.."]")
			end
		end

		table.insert(tallyCount, self:GetCountString(colorType, dispType, "guild", countList["guild"], gTabStr))
	end

	if ((countList["warband"] or 0) > 0) then
		total = total + countList["warband"]
		local wTabStr = ""

		--check for warband tabs first
		if BSYC.options.showWarbandTabs then
			table.sort(countList["wtab"], function(a, b) return a < b end)

			for k, v in pairs(countList["wtab"]) do
				wTabStr = wTabStr..","..tostring(k)
			end
			wTabStr = string.sub(wTabStr, 2)  -- remove comma

			--check for warband tab
			if string.len(wTabStr) > 0 then
				wTabStr = self:HexColor(BSYC.colors.warbandtabs, " ["..L.TooltipGuildTabs.." "..wTabStr.."]")
			end
		end

		table.insert(tallyCount, self:GetCountString(colorType, dispType, "warband", countList["warband"], wTabStr))
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
	local unitData = {
		unitObj=unitObj,
		colorized=self:ColorizeUnit(unitObj, false, false, doAdv),
		tallyString=tallyString,
		sortIndex=self:GetSortIndex(unitObj),
		count=total
	}
	table.insert(unitList, unitData)

	Debug(BSYC_DL.SL2, "UnitTotals", unitObj.name, unitObj.realm, unitData.colorized, unitData.tallyString, total)
	return unitData
end

function Tooltip:QTipCheck(source, isBattlePet)
	local showQTip = false

	--create the extra tooltip (qTip) only if it doesn't already exist
	if BSYC.options.enableExtTooltip or isBattlePet then
		local doQTip = true
		--only show the external tooltip if we have the option enabled, otherwise show it inside the tooltip if isBattlePet
		if source == "ArkInventory" and not BSYC.options.enableExtTooltip then doQTip = false end
		if doQTip then
			if not Tooltip.qTip then
				Tooltip.qTip = LibQTip:Acquire("BagSyncQTip", 3, "LEFT", "CENTER", "RIGHT")
				Tooltip.qTip:SetClampedToScreen(true)

				Tooltip.qTip:SetScript("OnShow", function()
					Tooltip:GetBottomChild()
				end)
			end
			if BSYC.__font and BSYC.__fontFlags then
				Tooltip.qTip:SetFont(BSYC.__font)
			end
			Tooltip.qTip:Clear()
			showQTip = true
		end
	end
	--release it if we aren't using the qTip
	if Tooltip.qTip and not showQTip then
		LibQTip:Release(Tooltip.qTip)
		Tooltip.qTip = nil
	end

	return showQTip
end

function Tooltip:GetBottomChild()
	Debug(BSYC_DL.TRACE, "GetBottomChild", Tooltip.objTooltip, Tooltip.qTip)

	local frame, qTip = Tooltip.objTooltip, Tooltip.qTip
	if not qTip then return end

	local cache = {}

	qTip:ClearAllPoints()

	local function getMinLoc(top, bottom)
		if top and bottom then
			if top < bottom then
				return "top", top
			else
				return "bottom", bottom
			end
		elseif top then
			return "top", top
		elseif bottom then
			return "bottom", bottom
		end
	end

	--first do TradeSkillMaster
	if C_AddOns.IsAddOnLoaded("TradeSkillMaster") then
        for i=1, 20 do
            local t = _G["TSMExtraTip" .. i]
            if t and t:IsVisible() then
				local loc, pos = getMinLoc(t:GetTop(), t:GetBottom())
				table.insert(cache, {name="TradeSkillMaster", frame=t, loc=loc, pos=pos})
			elseif not t then
				break
            end
        end
    end

	--check for LibExtraTip (Auctioneer, Oribos Exchange Addon, etc...)
	if LibStub and LibStub.libs and LibStub.libs["LibExtraTip-1"] then
		local t = LibStub("LibExtraTip-1"):GetExtraTip(frame)
		if t and t:IsVisible() then
			local loc, pos = getMinLoc(t:GetTop(), t:GetBottom())
			table.insert(cache, {name="LibExtraTip-1", frame=t, loc=loc, pos=pos})
		end
	end

	--check for BattlePetBreedID addon (Fixes #231)
	if BPBID_BreedTooltip or BPBID_BreedTooltip2 then
		local t = BPBID_BreedTooltip or BPBID_BreedTooltip2
		if t and t:IsVisible() then
			local loc, pos = getMinLoc(t:GetTop(), t:GetBottom())
			table.insert(cache, {name="BattlePetBreedID", frame=t, loc=loc, pos=pos})
		end
	end

	--find closest to edge (closer to 0)
	local lastLoc
	local lastPos
	local lastAnchor
	local lastName

	for i=1, #cache do
		local data = cache[i]
		if data and data.frame and data.loc and data.pos then
			if not lastPos then lastPos = data.pos end
			if not lastLoc then lastLoc = data.loc end
			if not lastAnchor then lastAnchor = data.frame end
			if not lastName then lastName = data.name end

			if data.pos <  lastPos then
				lastPos = data.pos
				lastLoc = data.loc
				lastAnchor = data.frame
				lastName = data.name
			end
		end
	end

	if lastAnchor and lastLoc and lastPos then
		Debug(BSYC_DL.SL3, "GetBottomChild", lastAnchor, lastLoc, lastPos, lastName)
		if lastLoc == "top" then
			qTip:SetPoint("BOTTOM", lastAnchor, "TOP")
		else
			qTip:SetPoint("TOP", lastAnchor, "BOTTOM")
		end
		return
	end

	--failsafe
	self:SetQTipAnchor(frame, qTip)
end

function Tooltip:SetQTipAnchor(frame, qTip)
	Debug(BSYC_DL.SL2, "SetQTipAnchor", frame, qTip)

    local x, y = frame:GetCenter()

    if not x or not y then
        qTip:SetPoint("TOPLEFT", frame, "BOTTOMLEFT")
		return
    end

    local hhalf = (x > UIParent:GetWidth() * 2 / 3) and "LEFT" or (x < UIParent:GetWidth() / 3) and "RIGHT" or ""
	--adjust the 4 to make it less sensitive on the top/bottom.  The higher the number the closer to the edges it's allowed.
    local vhalf = (y > UIParent:GetHeight() / 4) and "TOP" or "BOTTOM"

	qTip:SetPoint(vhalf .. hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP") .. hhalf)
end

function Tooltip:ResetCache()
	if Data.__cache and Data.__cache.tooltip then
		Data.__cache.tooltip = {}
	end
end

function Tooltip:ResetLastLink()
	self.__lastLink = nil
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
	if not BSYC.options.enableTooltips then return end
	if not CanAccessObject(objTooltip) then return end
	if Scanner.isScanningGuild then return end --don't tally while we are scanning the Guildbank

	--check for modifier option only in windows that isn't BagSync search
	if not self:CheckModifier() and not objTooltip.isBSYCSearch then return end

	local showQTip = Tooltip:QTipCheck(source, isBattlePet)
	local skipTally = false

	Tooltip.objTooltip = objTooltip

	--only show tooltips in search frame if the option is enabled
	if BSYC.options.tooltipOnlySearch and not objTooltip.isBSYCSearch then
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
		objTooltip:Show()
		Debug(BSYC_DL.WARN, "TallyUnits", "NoLink", origLink, source, isBattlePet)
		return
	end

	--if we already did the item, then display the previous information, use the unparsed link to verify
	if self.__lastLink and self.__lastLink == origLink then
		if self.__lastTally and #self.__lastTally > 0 then
			for i=1, #self.__lastTally do
				local color = self:GetClassColor(self.__lastTally[i].unitObj, 2, false, BSYC.colors.total)
				if showQTip then
					local lineNum = Tooltip.qTip:AddLine(self.__lastTally[i].colorized, string.rep(" ", 4), self.__lastTally[i].tallyString)
					Tooltip.qTip:SetLineTextColor(lineNum, color.r, color.g, color.b, 1)
				else
					objTooltip:AddDoubleLine(self.__lastTally[i].colorized, self.__lastTally[i].tallyString, color.r, color.g, color.b, color.r, color.g, color.b)
				end
			end
			objTooltip:Show()
			if showQTip then Tooltip.qTip:Show() end
		end
		objTooltip.__tooltipUpdated = true
		return
	end

	local permIgnore ={
		[6948] = "Hearthstone",
		[110560] = "Garrison Hearthstone",
		[140192] = "Dalaran Hearthstone",
		[128353] = "Admiral's Compass",
		[141605] = "Flight Master's Whistle",
	}

	--check blacklist
	local personalBlacklist = false
	local personalWhitelist = false

	if shortID and (permIgnore[tonumber(shortID)] or BSYC.db.blacklist[tonumber(shortID)]) then
		if BSYC.db.blacklist[tonumber(shortID)] then
			--don't use this on perm ignores only personal blacklist
			skipTally = not BSYC.options.showBLCurrentCharacterOnly
			personalBlacklist = true
		else
			skipTally = true
		end
		Debug(BSYC_DL.SL3, "TallyUnits", "|cFFe454fd[Blacklist]|r", link, shortID, personalBlacklist, BSYC.options.showBLCurrentCharacterOnly)
	end
	--check whitelist (blocks all items except those found in whitelist)
	if BSYC.options.enableWhitelist then
		if not BSYC.db.whitelist[tonumber(shortID)] then
			skipTally = true
			personalWhitelist = true
			Debug(BSYC_DL.SL3, "TallyUnits", "|cFFe454fd[Whitelist]|r", link, shortID, personalWhitelist)
		end
	end

	--short the shortID and ignore all BonusID's and stats
	if BSYC.options.enableShowUniqueItemsTotals then link = shortID end

	--store these in the addon itself not in the tooltip
	self.__lastTally = {}
	self.__lastLink = origLink

	local grandTotal = 0
	local unitList = {}
	local countList = {}
	local player = Unit:GetPlayerInfo()
	local guildObj = Data:GetPlayerGuildObj(player)
	local warbandObj = Data:GetWarbandBankObj()

	local allowList = {
		bag = true,
		bank = true,
		reagents = true,
		equip = true,
		mailbox = true,
		void = true,
		auction = true,
		warband = true,
	}

	--the true option for GetModule is to set it to silent and not return an error if not found
	--only display advanced search results in the BagSync search window, but make sure to show tooltips regularly outside of that by checking isBSYCSearch
	local advUnitList = not skipTally and objTooltip.isBSYCSearch and BSYC.advUnitList
	local turnOffCache = (BSYC.options.debug.enable and BSYC.options.debug.cache and true) or false
	local advPlayerChk = false
	local advPlayerGuildChk = false
	local doCurrentPlayerOnly = BSYC.options.showCurrentCharacterOnly or (BSYC.options.showBLCurrentCharacterOnly and personalBlacklist)

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

				countList = {}

				if not unitObj.isGuild then
					--Due to crafting items being used in reagents bank, or turning in quests with items in the bank, etc..
					--The cached item info for the current player would obviously be out of date until they returned to the bank to scan again.
					--In order to combat this, lets just get the realtime count for the currently logged in player every single time.
					--This is why we check for player name and realm below, we don't want to do anything in regards to the current player when the Database.
					if unitObj.data ~= BSYC.db.player then
						Debug(BSYC_DL.SL2, "TallyUnits", "[Unit]", unitObj.name, unitObj.realm)
						for k, v in pairs(allowList) do
							grandTotal = grandTotal + self:AddItems(unitObj, link, k, countList)
						end
					elseif advUnitList then
						advPlayerChk = true
					end
				else
					--don't cache the players guild bank, lets get that in real time in case they put stuff in it
					if not guildObj or (unitObj.data ~= guildObj.data) then
						Debug(BSYC_DL.SL2, "TallyUnits", "[Guild]", unitObj.name, unitObj.realm)
						grandTotal = grandTotal + self:AddItems(unitObj, link, "guild", countList)
					elseif advUnitList then
						advPlayerGuildChk = true
					end
				end

				--only process the totals if we have something to work with
				if grandTotal > 0 then
					--table variables gets passed as byRef
					self:UnitTotals(unitObj, countList, unitList, advUnitList)
				end
			end

			--do not cache if we are viewing an advanced search list, otherwise it won't display everything normally
			--finally, only cache if we have something to work with
			if not turnOffCache and not advUnitList then
				--store it in the cache, copy the tables don't reference them
				Data.__cache.tooltip[origLink] = Data.__cache.tooltip[origLink] or {}
				--only copy table if we have something to work with, otherwise return empty
				Data.__cache.tooltip[origLink].unitList = (grandTotal > 0 and CopyTable(unitList)) or {}
				Data.__cache.tooltip[origLink].grandTotal = grandTotal
			end
		elseif Data.__cache.tooltip[origLink] and not doCurrentPlayerOnly then
			--use the cached results from previous DB searches, copy the table don't reference it, 
			--otherwise we will add to it unintentially below with player data using table.insert()
			unitList = CopyTable(Data.__cache.tooltip[origLink].unitList)
			grandTotal = Data.__cache.tooltip[origLink].grandTotal
			Debug(BSYC_DL.INFO, "TallyUnits", "|cFF09DBE0CacheUsed|r", origLink)
		end

		Debug(BSYC_DL.SL2, "TallyUnits", "|cFF4DD827[AdvChk]|r", advUnitList, advPlayerChk, advPlayerGuildChk)

		--CURRENT PLAYER
		-----------------
		if (not personalWhitelist and not advUnitList) or advPlayerChk then
			countList = {}
			local playerObj = Data:GetPlayerObj(player)
			Debug(BSYC_DL.SL2, "TallyUnits", "|cFF4DD827[CurrentPlayer]|r", playerObj.name, playerObj.realm, link)

			--grab the equip count as we need that below for an accurate count on the bags, bank and reagents
			grandTotal = grandTotal + self:AddItems(playerObj, link, "equip", countList)
			--C_Item.GetItemCount does not work in the auction, void bank or mailbox, so grab it manually
			grandTotal = grandTotal + self:AddItems(playerObj, link, "auction", countList)
			grandTotal = grandTotal + self:AddItems(playerObj, link, "void", countList)
			grandTotal = grandTotal + self:AddItems(playerObj, link, "mailbox", countList)

			--C_Item.GetItemCount does not work on battlepet links either, grab bag, bank and reagents
			if isBattlePet then
				grandTotal = grandTotal + self:AddItems(playerObj, link, "bag", countList)
				grandTotal = grandTotal + self:AddItems(playerObj, link, "bank", countList)
				grandTotal = grandTotal + self:AddItems(playerObj, link, "reagents", countList)

			elseif not isBattlePet then
				local equipCount = countList["equip"] or 0
				local carryCount, bagCount, bankCount, regCount = 0, 0, 0, 0

				carryCount = C_Item.GetItemCount(origLink) or 0 --get the total amount the player is currently carrying (bags + equip)
				bagCount = carryCount - equipCount -- subtract the equipment count from the carry amount to get bag count
				if bagCount < 0 then bagCount = 0 end

				if IsReagentBankUnlocked and IsReagentBankUnlocked() then
					--C_Item.GetItemCount returns the bag count + reagent regardless of parameters.  So we have to subtract bag and reagents.  This does not include bank totals
					regCount = C_Item.GetItemCount(origLink, false, false, true) or 0
					regCount = regCount - carryCount
					if regCount < 0 then regCount = 0 end
				end

				--bankCount = C_Item.GetItemCount returns the bag + bank count regardless of parameters.  So we have to subtract the carry totals
				bankCount = C_Item.GetItemCount(origLink, true, false, false) or 0
				bankCount = (bankCount - carryCount)
				if bankCount < 0 then bankCount = 0 end

				-- --now assign the values (check for disabled modules)
				if not BSYC.tracking.bag then bagCount = 0 end
				if not BSYC.tracking.bank then bankCount = 0 end
				if not BSYC.tracking.reagents then regCount = 0 end

				if bagCount > 0 then
					self:GetEquipBags("bag", playerObj, link, countList)
				end
				if bankCount > 0 then
					self:GetEquipBags("bank", playerObj, link, countList)
				end

				countList.bag = bagCount
				countList.bank = bankCount
				countList.reagents = regCount
				grandTotal = grandTotal + (bagCount + bankCount + regCount)
			end

			if grandTotal > 0 then
				--table variables gets passed as byRef
				self:UnitTotals(playerObj, countList, unitList, advUnitList)
			end
		end

		--CURRENT PLAYER GUILD
		--We do this separately so that the guild has it's own line in the unitList and not included inline with the player character
		--We also want to do this in real time and not cache, otherwise they may put stuff in their guild bank which will not be reflected in a cache
		-----------------
		if not personalWhitelist and guildObj and (not advUnitList or advPlayerGuildChk) then
			Debug(BSYC_DL.SL2, "TallyUnits", "|cFF4DD827[CurrentPlayer-Guild]|r", player.guild, player.guildrealm)
			countList = {}
			grandTotal = grandTotal + self:AddItems(guildObj, link, "guild", countList)
			if grandTotal > 0 then
				--table variables gets passed as byRef
				self:UnitTotals(guildObj, countList, unitList, advUnitList)
			end
		end

		--Warband Bank can updated frequently, so we need to collect in real time and not cached
		if not personalWhitelist and warbandObj and allowList.warband and not advUnitList then
			Debug(BSYC_DL.SL2, "TallyUnits", "|cFF4DD827[Warband]|r")
			countList = {}
			grandTotal = grandTotal + self:AddItems(warbandObj, link, "warband", countList)
			if grandTotal > 0 then
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
	if BSYC.options.showBLCurrentCharacterOnly and personalBlacklist then
		table.insert(unitList, 1, { colorized="|cffff7d0a["..L.Blacklist.."]|r", tallyString=" "} )
	end

	--EXTRA OPTIONAL DISPLAYS
	-------------------------
	local desc, value = '', ''
	local addSeparator = false

	--add [Total] if we have more than one unit to work with
	if not skipTally and BSYC.options.showTotal and grandTotal > 0 and #unitList > 1 then
		--add a separator after the character list
		table.insert(unitList, { colorized=" ", tallyString=" "} )

		desc = self:HexColor(BSYC.colors.total, L.TooltipTotal)
		value = self:HexColor(BSYC.colors.second, comma_value(grandTotal))
		table.insert(unitList, { colorized=desc, tallyString=value} )
	end

	--add ItemID
	if BSYC.options.enableTooltipItemID and shortID then
		desc = self:HexColor(BSYC.colors.itemid, L.TooltipItemID)
		value = self:HexColor(BSYC.colors.second, shortID)
		if isBattlePet then
			desc = string.format("|cFFCA9BF7%s|r ", L.TooltipFakeID)
		end
		if not addSeparator then
			table.insert(unitList, 1, { colorized=" ", tallyString=" "} )
			addSeparator = true
		end
		table.insert(unitList, 1, { colorized=desc, tallyString=value} )
	end

	--don't do expansion or itemtype information for battlepets
	if not isBattlePet and not BSYC:IsBattlePetFakeID(shortID) then
		--add expansion
		if BSYC.IsRetail and BSYC.options.enableSourceExpansion and shortID then
			desc = self:HexColor(BSYC.colors.expansion, L.TooltipExpansion)
			local expacID
			if Data.__cache.items[shortID] then
				expacID = Data.__cache.items[shortID].expacID
			else
				expacID = select(15, C_Item.GetItemInfo(shortID))
			end
			value = self:HexColor(BSYC.colors.second, (expacID and _G["EXPANSION_NAME"..expacID]) or "?")

			if not addSeparator then
				table.insert(unitList, 1, { colorized=" ", tallyString=" "} )
				addSeparator = true
			end
			table.insert(unitList, 1, { colorized=desc, tallyString=value} )
		end
		--add item types
		if BSYC.options.enableItemTypes and shortID then
			local itemType, itemSubType, _, _, _, _, classID, subclassID
			if Data.__cache.items[shortID] then
				itemType = Data.__cache.items[shortID].itemType
				itemSubType = Data.__cache.items[shortID].itemSubType
				classID = Data.__cache.items[shortID].classID
				subclassID = Data.__cache.items[shortID].subclassID
			else
				itemType, itemSubType, _, _, _, _, classID, subclassID = select(6, C_Item.GetItemInfo(shortID))
			end
			local typeString = Tooltip:GetItemTypeString(itemType, itemSubType, classID, subclassID)

			if typeString then
				desc = self:HexColor(BSYC.colors.itemtypes, L.TooltipItemType)
				value = self:HexColor(BSYC.colors.second, typeString)

				if not addSeparator then
					table.insert(unitList, 1, { colorized=" ", tallyString=" "} )
					addSeparator = true
				end
				table.insert(unitList, 1, { colorized=desc, tallyString=value} )
			end
		end
	end

	--add separator if enabled and only if we have something to work with
	if not showQTip and BSYC.options.enableTooltipSeparator and #unitList > 0 then
		table.insert(unitList, 1, { colorized=" ", tallyString=" "} )
	end

	--finally display it
	for i=1, #unitList do
		local color = self:GetClassColor(unitList[i].unitObj, 2, false, BSYC.colors.total)
		if showQTip then
			-- Add an new line, using all columns
			local lineNum = Tooltip.qTip:AddLine(unitList[i].colorized, string.rep(" ", 4), unitList[i].tallyString)
			Tooltip.qTip:SetLineTextColor(lineNum, color.r, color.g, color.b, 1)
		else
			objTooltip:AddDoubleLine(unitList[i].colorized, unitList[i].tallyString, color.r, color.g, color.b, color.r, color.g, color.b)
		end
	end

	--this is only a local cache for the current tooltip and will be reset on bag updates, it is not the same as Data.__cache.tooltip
	self.__lastTally = unitList

	objTooltip.__tooltipUpdated = true
	objTooltip:Show()

	if showQTip then
		if #unitList > 0 then
			Tooltip.qTip:Show()
		else
			Tooltip.qTip:Hide()
		end
	end

	local WLChk = (BSYC.options.enableWhitelist and "WL-ON") or "WL-OFF"
	Debug(BSYC_DL.INFO, "|cFF52D386TallyUnits|r", link, shortID, source, isBattlePet, grandTotal, WLChk)
end

function Tooltip:CurrencyTooltip(objTooltip, currencyName, currencyIcon, currencyID, source)
	Debug(BSYC_DL.INFO, "CurrencyTooltip", currencyName, currencyIcon, currencyID, source, BSYC.tracking.currency)
	if not BSYC.tracking.currency then return end
	if not BSYC.options.enableCurrencyWindowTooltipData and source ~= "bagsync_currency" then return end

	--check for modifier option
	if not self:CheckModifier() and source ~= "bagsync_currency" then return end

	currencyID = tonumber(currencyID) --make sure it's a number we are working with and not a string
	if not currencyID then return end

	Tooltip.objTooltip = objTooltip

	--loop through our characters
	local usrData = {}
	local grandTotal = 0

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
	local showQTip = Tooltip:QTipCheck()

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
		if showQTip then
			Tooltip.qTip:AddLine(displayList[i][1], string.rep(" ", 4), displayList[i][2])
		else
			objTooltip:AddDoubleLine(displayList[i][1], displayList[i][2], 1, 1, 1, 1, 1, 1)
		end
	end

	objTooltip.__tooltipUpdated = true
	objTooltip:Show()
	if showQTip then
		Tooltip.qTip:Show()
	end
end

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
		--we don't want to Release() the qTip until we aren't using it anymore because they disabled it.  Otherwise just hide it.
		if Tooltip.qTip then Tooltip.qTip:Hide() end
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
					link = C_Item.GetItemLinkByGUID(data.guid)

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

		--add support for ArkInventory (Fixes #231)
		if ArkInventory and ArkInventory.API and ArkInventory.API.CustomBattlePetTooltipReady then
			hooksecurefunc(ArkInventory.API, "CustomBattlePetTooltipReady", function(tooltip, link)
				if tooltip.__tooltipUpdated then return end
				if link then
					Tooltip:TallyUnits(tooltip, link, "ArkInventory", true)
				end
			end)
		else
			--BattlePetToolTip_Show
			if objTooltip == BattlePetTooltip then
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
			if objTooltip == FloatingBattlePetTooltip then
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

	else

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

		hooksecurefunc(objTooltip, "SetQuestLogItem", function(self, itemType, index)
			if self.__tooltipUpdated then return end
			local link = GetQuestLogItemLink(itemType, index)
			if link then
				Tooltip:TallyUnits(self, link, "SetQuestLogItem")
			end
		end)
		hooksecurefunc(objTooltip, "SetQuestItem", function(self, itemType, index)
			if self.__tooltipUpdated then return end
			local link = GetQuestItemLink(itemType, index)
			if link then
				Tooltip:TallyUnits(self, link, "SetQuestItem")
			end
		end)

		--only parse CraftFrame when it's not the RETAIL but Classic and TBC, because this was changed to TradeSkillUI on retail
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

function Tooltip:OnEnable()
	Debug(BSYC_DL.INFO, "OnEnable")

	self:HookTooltip(GameTooltip)
	self:HookTooltip(ItemRefTooltip)
	self:HookTooltip(EmbeddedItemTooltip)
	self:HookTooltip(BattlePetTooltip)
	self:HookTooltip(FloatingBattlePetTooltip)
end