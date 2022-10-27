--[[
	tooltip.lua
		Tooltip module for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Tooltip = BSYC:NewModule("Tooltip")
local Unit = BSYC:GetModule("Unit")
local Data = BSYC:GetModule("Data")
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local LibQTip = LibStub('LibQTip-1.0')

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
local function Debug(...)
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", "Tooltip")
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end
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
	return string.format("|cff%s%s|r", tostring(color), tostring(str))
end

function Tooltip:GetSortIndex(unitObj)
	if unitObj then
		if not unitObj.isGuild and unitObj.realm == Unit:GetUnitInfo().realm then
			return 1
		elseif not unitObj.isGuild and unitObj.isConnectedRealm then
			return 2
		elseif not unitObj.isGuild then
			return 3
		end
	end
	return 4
end

function Tooltip:ColorizeUnit(unitObj, bypass, showRealm, showSimple)
	if not unitObj.data then return nil end
	
	local player = Unit:GetUnitInfo()
	local tmpTag = ""
	local realm = unitObj.realm
	local realmTag = ""
	local delimiter = " "
	
	--showSimple: returns only colorized name no images
	--bypass: shows colorized names, checkmark, and faction icons but no XR or BNET tags
	--showRealm: is used for debugging purposes and adds realm tags
	
	if not unitObj.isGuild then
	
		--first colorize by class color
		if bypass or showSimple or BSYC.options.enableUnitClass and RAID_CLASS_COLORS[unitObj.data.class] then
			tmpTag = self:HexColor(RAID_CLASS_COLORS[unitObj.data.class], unitObj.name)
		else
			tmpTag = self:HexColor(BSYC.options.colors.first, unitObj.name)
		end
		
		--ignore certain stuff if we only want to return simple colored units
		if not showSimple then
		
			--add green checkmark
			if unitObj.name == player.name and unitObj.realm == player.realm then
				if bypass or BSYC.options.enableTooltipGreenCheck then
					local ReadyCheck = [[|TInterface\RaidFrame\ReadyCheck-Ready:0|t]]
					tmpTag = ReadyCheck.." "..tmpTag
				end
			end
			
			--add faction icons
			if bypass or BSYC.options.enableFactionIcons then
				local FactionIcon = ""
				
				if BSYC.IsRetail then
					FactionIcon = [[|TInterface\Icons\Achievement_worldevent_brewmaster:18|t]]
					if unitObj.data.faction == "Alliance" then
						FactionIcon = [[|TInterface\Icons\Inv_misc_tournaments_banner_human:18|t]]
					elseif unitObj.data.faction == "Horde" then
						FactionIcon = [[|TInterface\Icons\Inv_misc_tournaments_banner_orc:18|t]]
					end
				else
					FactionIcon = [[|TInterface\Icons\ability_seal:18|t]]
					if unitObj.data.faction == "Alliance" then
						FactionIcon = [[|TInterface\Icons\inv_bannerpvp_02:18|t]]
					elseif unitObj.data.faction == "Horde" then
						FactionIcon = [[|TInterface\Icons\inv_bannerpvp_01:18|t]]
					end
				end
				
				if FactionIcon ~= "" then
					tmpTag = FactionIcon.." "..tmpTag
				end
			end
			
		end

	else
		--is guild
		tmpTag = self:HexColor(BSYC.options.colors.guild, select(2, Unit:GetUnitAddress(unitObj.name)) )
	end
	
	----------------
	--If we Bypass or showSimple none of the XR or BNET stuff will be shown
	----------------
	if bypass or showSimple then
		--DEBUGGING: check for showRealm tag before returning, this is mostly used for DEBUGGING purposes.  We don't want to add default tags normally.
		--for that we want to use the XREALM procedures below for tagging.
		if showRealm then
			realmTag = L.TooltipBattleNetTag..delimiter
			tmpTag = self:HexColor(BSYC.options.colors.bnet, "["..realmTag..realm.."]").." "..tmpTag
		end
		--since we Bypass don't show anything else just return what we got
		return tmpTag
	end
	----------------
	
	--Always set certain features off if it conflicts with currently enabled options.
	if BSYC.options.enableXR_BNETRealmNames then
		BSYC.options.enableRealmAstrickName = false
		BSYC.options.enableRealmShortName = false
	
		realm = unitObj.realm
	
	elseif BSYC.options.enableRealmAstrickName then
		BSYC.options.enableXR_BNETRealmNames = false
		BSYC.options.enableRealmShortName = false
		
		realm = "*"
	
	elseif BSYC.options.enableRealmShortName then
		BSYC.options.enableXR_BNETRealmNames = false
		BSYC.options.enableRealmAstrickName = false
		
		realm = string.sub(unitObj.realm, 1, 5)
	
	else
		realm = ""
		delimiter = ""
	end
	
	if BSYC.options.enableBNetAccountItems and not unitObj.isConnectedRealm then
		realmTag = BSYC.options.enableRealmIDTags and L.TooltipBattleNetTag..delimiter or ""
		if string.len(realm) > 0 or string.len(realmTag) > 0 then
			tmpTag = self:HexColor(BSYC.options.colors.bnet, "["..realmTag..realm.."]").." "..tmpTag
		end
	end
	
	if BSYC.options.enableCrossRealmsItems and unitObj.isConnectedRealm and unitObj.realm ~= player.realm then
		realmTag = BSYC.options.enableRealmIDTags and L.TooltipCrossRealmTag..delimiter or ""
		if string.len(realm) > 0 or string.len(realmTag) > 0 then
			tmpTag = self:HexColor(BSYC.options.colors.cross, "["..realmTag..realm.."]").." "..tmpTag
		end
	end
	
	return tmpTag
end

function Tooltip:MoneyTooltip()
	local tooltip = _G["BagSyncMoneyTooltip"] or nil
	
	if (not tooltip) then
			tooltip = CreateFrame("GameTooltip", "BagSyncMoneyTooltip", UIParent, "GameTooltipTemplate")
			_G["BagSyncMoneyTooltip"] = tooltip
			--Add to special frames so window can be closed when the escape key is pressed.
			tinsert(UISpecialFrames, "BagSyncMoneyTooltip")
	
			local closeButton = CreateFrame("Button", nil, tooltip, "UIPanelCloseButton")
			closeButton:SetPoint("TOPRIGHT", tooltip, 1, 0)
			
			tooltip:SetToplevel(true)
			tooltip:EnableMouse(true)
			tooltip:SetMovable(true)
			tooltip:SetClampedToScreen(true)
			
			tooltip:SetScript("OnMouseDown",function(self)
					self.isMoving = true
					self:StartMoving();
			end)
			tooltip:SetScript("OnMouseUp",function(self)
				if( self.isMoving ) then
					self.isMoving = nil
					self:StopMovingOrSizing()
				end
			end)
	end

	tooltip:ClearLines()
	tooltip:ClearAllPoints()
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	tooltip:AddLine("BagSync")
	tooltip:AddLine(" ")
	
	--loop through our characters
	local usrData = {}
	local total = 0
	
	for unitObj in Data:IterateUnits() do
		if unitObj.data.money and unitObj.data.money > 0 then
			if not unitObj.isGuild or (unitObj.isGuild and BSYC.options.showGuildInGoldTooltip) then
				table.insert(usrData, { unitObj=unitObj, colorized=self:ColorizeUnit(unitObj), sortIndex=self:GetSortIndex(unitObj) } )
			end
		end
	end
	
	--sort the list by our sortIndex then by realm and finally by name
	table.sort(usrData, function(a, b)
		if a.sortIndex  == b.sortIndex then
			if a.unitObj.realm == b.unitObj.realm then
				return a.unitObj.name < b.unitObj.name;
			end
			return a.unitObj.realm < b.unitObj.realm;
		end
		return a.sortIndex < b.sortIndex;
	end)

	for i=1, #usrData do
		--use GetMoneyString and true to seperate it by thousands
		tooltip:AddDoubleLine(usrData[i].colorized, GetMoneyString(usrData[i].unitObj.data.money, true), 1, 1, 1, 1, 1, 1)
		total = total + usrData[i].unitObj.data.money
	end
	if BSYC.options.showTotal and total > 0 then
		tooltip:AddLine(" ")
		tooltip:AddDoubleLine(self:HexColor(BSYC.options.colors.total, L.TooltipTotal), GetMoneyString(total, true), 1, 1, 1, 1, 1, 1)
	end
	
	tooltip:AddLine(" ")
	tooltip:Show()
end

function Tooltip:UnitTotals(unitObj, allowList, unitList)
	local tallyString = ""
	local total = 0
	local grouped = 0
	
	--order in which we want stuff displayed
	local list = {
		[1] = { source="bag", 		desc=L.TooltipBag },
		[2] = { source="bank", 		desc=L.TooltipBank },
		[3] = { source="reagents", 	desc=L.TooltipReagent },
		[4] = { source="equip", 	desc=L.TooltipEquip },
		[5] = { source="guild", 	desc=L.TooltipGuild },
		[6] = { source="mailbox", 	desc=L.TooltipMail },
		[7] = { source="auction", 	desc=L.TooltipAuction },
	}
		
	for i = 1, #list do
		local count, desc = allowList[list[i].source], list[i].desc
		if count > 0 then
			grouped = grouped + 1
			total = total + count
			
			desc = self:HexColor(BSYC.options.colors.first, desc)
			count = self:HexColor(BSYC.options.colors.second, comma_value(count))
			
			tallyString = tallyString..L.TooltipDelimiter..desc.." "..count
		end
	end
	
	tallyString = strsub(tallyString, string.len(L.TooltipDelimiter) + 1) --remove first delimiter
	if total < 1 or string.len(tallyString) < 1 then return end

	--if it's groupped up and has more then one item then use a different color and show total
	if grouped > 1 then
		tallyString = self:HexColor(BSYC.options.colors.second, comma_value(total)).." ("..tallyString..")"
	end

	--add to list
	table.insert(unitList, { unitObj=unitObj, colorized=self:ColorizeUnit(unitObj), tallyString=tallyString, sortIndex=self:GetSortIndex(unitObj) } )

end

function Tooltip:ItemCount(data, itemID, allowList, source, total)
	if #data < 1 then return total end
	
	for i=1, #data do
		if data[i] then
			local link, count, identifier = strsplit(";", data[i])
			if link then
				if BSYC.options.enableShowUniqueItemsTotals then link = BSYC:GetShortItemID(link) end
				if link == itemID then
					allowList[source] = allowList[source] + (count or 1)
					total = total + (count or 1)
				end
			end
		end
	end
	return total
end

function Tooltip:TallyUnits(objTooltip, link, source, isBattlePet)
	if not BSYC.options.enableTooltips then return end
	if not CanAccessObject(objTooltip) then return end
	
	--only show tooltips in search frame if the option is enabled
	if BSYC.options.tooltipOnlySearch and objTooltip.GetOwner and objTooltip:GetOwner() and objTooltip:GetOwner():GetName() and not string.find(objTooltip:GetOwner():GetName(), "BagSyncSearchRow") then
		objTooltip:Show()
		return
	end
	
	--make sure we have something to work with
	--since we aren't using a count, it will return only the itemid
	local link = BSYC:ParseItemLink(link)
	if not link then
		objTooltip:Show()
		return
	end

	local shortID = BSYC:GetShortItemID(link)

	local permIgnore ={
		[6948] = "Hearthstone",
		[110560] = "Garrison Hearthstone",
		[140192] = "Dalaran Hearthstone",
		[128353] = "Admiral's Compass",
		[141605] = "Flight Master's Whistle",
	}
	if permIgnore[tonumber(shortID)] or BSYC.db.blacklist[tonumber(shortID)] then
		objTooltip:Show()
		return
	end
	
	--if we are parsing a database entry, fix it, it's probably a battlepet
	local qLink, qCount, qIdentifier = strsplit(";", link)
	if qLink and qCount and qIdentifier then
		--just use the itemid or fakeid
		link = qLink
	end
	
	--short the shortID and ignore all BonusID's and stats
	if BSYC.options.enableShowUniqueItemsTotals then link = shortID end
	
	if (BSYC.options.enableExtTooltip or isBattlePet) and not objTooltip.qTip then
		objTooltip.qTip = LibQTip:Acquire(objTooltip:GetName(), 3, "LEFT", "CENTER", "RIGHT")
		objTooltip.qTip:Clear()
		--objTooltip.qTip:SmartAnchorTo(objTooltip)
		objTooltip.qTip:SetPoint("TOPRIGHT", objTooltip, "BOTTOMRIGHT")
		objTooltip.qTip.OnRelease = function() objTooltip.qTip = nil end
	elseif objTooltip.qTip then
		--clear any item data already in the tooltip
		objTooltip.qTip:Clear()
	end
	
	--check if are requesting that the tooltip be refreshed regardless if it has last item stored
	if BSYC.refreshTooltip then
		BSYC.refreshTooltip = nil
		self.__lastLink = nil
	end

	--if we already did the item, then display the previous information
	if self.__lastLink and self.__lastLink == link then
		if self.__lastTally and #self.__lastTally > 0 then
			for i=1, #self.__lastTally do
				local color = BSYC.options.colors.total --this is a cover all color we are going to use
				if BSYC.options.enableExtTooltip or isBattlePet then
					local lineNum = objTooltip.qTip:AddLine(self.__lastTally[i].colorized, 	string.rep(" ", 4), self.__lastTally[i].tallyString)
					objTooltip.qTip:SetLineTextColor(lineNum, color.r, color.g, color.b, 1)
				else
					objTooltip:AddDoubleLine(self.__lastTally[i].colorized, self.__lastTally[i].tallyString, color.r, color.g, color.b, color.r, color.g, color.b)
				end
			end
			objTooltip:Show()
			if objTooltip.qTip then objTooltip.qTip:Show() end
		else
			if objTooltip.qTip then LibQTip:Release(objTooltip.qTip) end
		end
		objTooltip.__tooltipUpdated = true
		return
	end
	
	--store these in the addon itself not in the tooltip
	self.__lastTally = {}
	self.__lastLink = link
	
	local grandTotal = 0
	local previousGuilds = {}
	local unitList = {}
	
	for unitObj in Data:IterateUnits() do
	
		local allowList = {
			["bag"] = 0,
			["bank"] = 0,
			["reagents"] = 0,
			["equip"] = 0,
			["mailbox"] = 0,
			["auction"] = 0,
			["guild"] = 0,
		}
		
		if not unitObj.isGuild then
			for k, v in pairs(unitObj.data) do
				if allowList[k] and type(v) == "table" then
					--bags, bank, reagents are stored in individual bags
					if k == "bag" or k == "bank" or k == "reagents" then
						for bagID, bagData in pairs(v) do
							grandTotal = self:ItemCount(bagData, link, allowList, k, grandTotal)
						end
					else
						--with the exception of auction, everything else is stored in a numeric list
						--auction is stored in a numeric list but within an individual bag
						--auction, equip, mailbox
						local passChk = true
						if k == "auction" and not BSYC.options.enableAuction then passChk = false end
						if k == "mailbox" and not BSYC.options.enableMailbox then passChk = false end
						
						if passChk then
							grandTotal = self:ItemCount(k == "auction" and v.bag or v, link, allowList, k, grandTotal)
						end
					end
				end
			end
		else
			grandTotal = self:ItemCount(unitObj.data.bag, link, allowList, "guild", grandTotal)
		end
		
		--only process the totals if we have something to work with
		if grandTotal > 0 then
			--table variables gets passed as byRef
			self:UnitTotals(unitObj, allowList, unitList)
		end
		
	end
	
	--only sort items if we have something to work with
	if #unitList > 0 then

		table.sort(unitList, function(a, b)
			if a.sortIndex  == b.sortIndex then
				if a.unitObj.realm == b.unitObj.realm then
					return a.unitObj.name < b.unitObj.name;
				end
				return a.unitObj.realm < b.unitObj.realm;
			end
			return a.sortIndex < b.sortIndex;
		end)
		
	end
	
	local desc, value = '', ''
	
	--add [Total] if we have more than one unit to work with
	if BSYC.options.showTotal and grandTotal > 0 and #unitList > 1 then
		desc = self:HexColor(BSYC.options.colors.total, L.TooltipTotal)
		value = self:HexColor(BSYC.options.colors.second, comma_value(grandTotal))
		table.insert(unitList, { colorized=desc, tallyString=value} )
	end
		
	--add ItemID
	if BSYC.options.enableTooltipItemID and shortID then
		desc = self:HexColor(BSYC.options.colors.itemid, L.TooltipItemID)
		value = self:HexColor(BSYC.options.colors.second, shortID)
		if isBattlePet then
			desc = string.format("|cFFCA9BF7%s|r ", L.TooltipFakeID)
		end
		table.insert(unitList, 1, { colorized=desc, tallyString=value} )
	end
	
	--add debug info
	if BSYC.options.enableSourceDebugInfo and source then
		desc = self:HexColor(BSYC.options.colors.debug, L.TooltipDebug)
		value = self:HexColor(BSYC.options.colors.second, "1;"..source..";"..tostring(shortID or 0)..";"..tostring(isBattlePet or "false"))
		table.insert(unitList, 1, { colorized=" ", tallyString=" "} )
		table.insert(unitList, 1, { colorized=desc, tallyString=value} )
	end

	--add seperator if enabled and only if we have something to work with
	if not objTooltip.qTip and BSYC.options.enableTooltipSeperator and #unitList > 0 then
		table.insert(unitList, 1, { colorized=" ", tallyString=" "} )
	end
	
	--finally display it
	for i=1, #unitList do
		local color = BSYC.options.colors.total --this is a cover all color we are going to use
		if BSYC.options.enableExtTooltip or isBattlePet then
			-- Add an new line, using all columns
			local lineNum = objTooltip.qTip:AddLine(unitList[i].colorized, string.rep(" ", 4), unitList[i].tallyString)
			objTooltip.qTip:SetLineTextColor(lineNum, color.r, color.g, color.b, 1)
		else
			objTooltip:AddDoubleLine(unitList[i].colorized, unitList[i].tallyString, color.r, color.g, color.b, color.r, color.g, color.b)
		end
	end
	
	self.__lastTally = unitList
	
	objTooltip.__tooltipUpdated = true
	objTooltip:Show()
	
	if objTooltip.qTip then
		if grandTotal > 0 then
			objTooltip.qTip:Show()
		else
			LibQTip:Release(objTooltip.qTip)
		end
	end
end

function Tooltip:CurrencyTooltip(objTooltip, currencyName, currencyIcon, currencyID, source)

	currencyID = tonumber(currencyID) --make sure it's a number we are working with and not a string
	if not currencyID then return end

	--loop through our characters
	local usrData = {}
	
	for unitObj in Data:IterateUnits() do
		if not unitObj.isGuild and unitObj.data.currency and unitObj.data.currency[currencyID] then
			table.insert(usrData, { unitObj=unitObj, colorized=self:ColorizeUnit(unitObj), sortIndex=self:GetSortIndex(unitObj), count=unitObj.data.currency[currencyID].count} )
		end
	end
	
	--sort the list by our sortIndex then by realm and finally by name
	table.sort(usrData, function(a, b)
		if a.sortIndex  == b.sortIndex then
			if a.unitObj.realm == b.unitObj.realm then
				return a.unitObj.name < b.unitObj.name;
			end
			return a.unitObj.realm < b.unitObj.realm;
		end
		return a.sortIndex < b.sortIndex;
	end)
	
	if currencyName then
		objTooltip:AddLine(currencyName, 64/255, 224/255, 208/255)
		objTooltip:AddLine(" ")
	end

	for i=1, #usrData do
		if usrData[i].count then
			objTooltip:AddDoubleLine(usrData[i].colorized, comma_value(usrData[i].count), 1, 1, 1, 1, 1, 1)
		end
	end
	
	if BSYC.options.enableTooltipItemID and currencyID then
		desc = self:HexColor(BSYC.options.colors.itemid, L.TooltipCurrencyID)
		value = self:HexColor(BSYC.options.colors.second, currencyID)
		objTooltip:AddDoubleLine(desc, value, 1, 1, 1, 1, 1, 1)
	end
	
	if BSYC.options.enableSourceDebugInfo and source then
		desc = self:HexColor(BSYC.options.colors.debug, L.TooltipDebug)
		value = self:HexColor(BSYC.options.colors.second, "2;"..source..";"..tostring(currencyID or 0)..";"..tostring(currencyIcon or 0))
		objTooltip:AddDoubleLine(" ", " ", 1, 1, 1, 1, 1, 1)
		objTooltip:AddDoubleLine(desc, value, 1, 1, 1, 1, 1, 1)
	end

	objTooltip.__tooltipUpdated = true
	objTooltip:Show()
end

function Tooltip:HookTooltip(objTooltip)

	objTooltip:HookScript("OnHide", function(self)
		self.__tooltipUpdated = false
		--reset __lastLink in the addon itself not within the tooltip
		Tooltip.__lastLink = nil
		
		if self.qTip then
			LibQTip:Release(self.qTip)
			self.qTip = nil
		end
	end)
	objTooltip:HookScript("OnTooltipCleared", function(self)
		--this gets called repeatedly on some occasions. Do not reset Tooltip.__lastLink here
		self.__tooltipUpdated = false
	end)
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
	if not BSYC.IsRetail then
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
	
	--------------------------------------------------
	if BSYC.IsRetail then
		--------------------------------------------------RECIPES
		hooksecurefunc(objTooltip, "SetRecipeReagentItem", function(self, recipeID, reagentIndex)
			if self.__tooltipUpdated then return end
			local link = C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, reagentIndex)
			if link then
				Tooltip:TallyUnits(self, link, "SetRecipeReagentItem")
			end
		end)
		--------------------------------------------------CURRENCY
		hooksecurefunc(objTooltip, "SetCurrencyToken", function(self, index)
			if self.__tooltipUpdated then return end
			
			local currencyData = C_CurrencyInfo.GetCurrencyListInfo(index)
			local link = C_CurrencyInfo.GetCurrencyListLink(index)
			
			if currencyData.name and currencyData.iconFileID and link then
				local currencyID = BSYC:GetShortCurrencyID(link)
				if currencyID then
					Tooltip:CurrencyTooltip(self, currencyData.name, currencyData.iconFileID, currencyID, "SetCurrencyToken")
				end
			end
			
		end)
		hooksecurefunc(objTooltip, "SetCurrencyTokenByID", function(self, currencyID)
			if self.__tooltipUpdated then return end
			
			local currencyData = C_CurrencyInfo.GetCurrencyInfo(currencyID)
			
			if currencyData.name and currencyData.iconFileID then
				Tooltip:CurrencyTooltip(self, currencyData.name, currencyData.iconFileID, currencyID, "SetCurrencyTokenByID")
			end
		end)
		hooksecurefunc(objTooltip, "SetCurrencyByID", function(self, currencyID)
			if self.__tooltipUpdated then return end
			
			local currencyData = C_CurrencyInfo.GetCurrencyInfo(currencyID)
			
			if currencyData.name and currencyData.iconFileID then
				Tooltip:CurrencyTooltip(self, currencyData.name, currencyData.iconFileID, currencyID, "SetCurrencyByID")
			end
		end)
		hooksecurefunc(objTooltip, "SetBackpackToken", function(self, index)
			if self.__tooltipUpdated then return end
			
			local currencyData = C_CurrencyInfo.GetBackpackCurrencyInfo(index)
			
			if currencyData.name and currencyData.iconFileID and currencyData.currencyTypesID then
				Tooltip:CurrencyTooltip(self, currencyData.name, currencyData.iconFileID, currencyData.currencyTypesID, "SetBackpackToken")
			end
		end)
		hooksecurefunc(objTooltip, "SetMerchantCostItem", function(self, index, currencyIndex)
			--see MerchantFrame_UpdateAltCurrency
			if self.__tooltipUpdated then return end
			
			--https://wowpedia.fandom.com/wiki/API_GetMerchantItemCostItem
			local currencyID
			local itemTexture, itemValue, itemLink, currencyName = GetMerchantItemCostItem(index, currencyIndex)
			local itemCurrencyID = BSYC:GetShortCurrencyID(itemLink)

			--if there is no itemlink or currency name then an item is required instead of currency
			if itemCurrencyID or currencyName then
			
				local currencies = { GetMerchantCurrencies() }
				
				if itemCurrencyID then
					currencyID = itemCurrencyID
				else
					--we didn't get the currencyID from the link so lets try the currency array list
					for i=1, #currencies do
						if currencies[i] then
							local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(currencies[i])
							if currencyInfo then
								local name = currencyInfo.name
								if ( currencyName and name and name ~= "" and name == currencyName ) then
									currencyID = currencies[i]
									break
								end
							end
						end
					end
				end

				if currencyID then
					local currencyData = C_CurrencyInfo.GetCurrencyInfo(currencyID)
					
					if currencyData.name and currencyData.iconFileID then
						Tooltip:CurrencyTooltip(self, currencyData.name, currencyData.iconFileID, currencyID, "SetMerchantCostItem")
					end
					return
				end
				
			end
			
			--if we don't have a currency token id that means it's probably and item required to purchase like Raid Finder token turnins or whatnot.
			--make sure we have something to work with
			if itemLink then
				Tooltip:TallyUnits(self, itemLink, "SetMerchantCostItem")
			end
			
		end)
		
	end

end

function Tooltip:HookBattlePetTooltip(objTooltip)
	if not BSYC.IsRetail then end
	
	--BattlePetToolTip_Show
	if objTooltip == BattlePetTooltip then
		hooksecurefunc("BattlePetToolTip_Show", function(speciesID)
			if objTooltip.__tooltipUpdated then return end
			if speciesID then
				local fakeID = BSYC:CreateFakeBattlePetID(nil, nil, speciesID)
				if fakeID then
					Tooltip:TallyUnits(objTooltip, fakeID, "BattlePetToolTip_Show", true)
				end
			end
		end)
	end
	--FloatingBattlePet_Show
	if objTooltip == FloatingBattlePetTooltip then
		hooksecurefunc("FloatingBattlePet_Show", function(speciesID)
			if objTooltip.__tooltipUpdated then return end
			if speciesID then
				local fakeID = BSYC:CreateFakeBattlePetID(nil, nil, speciesID)
				if fakeID then
					Tooltip:TallyUnits(objTooltip, fakeID, "FloatingBattlePet_Show", true)
				end
			end
		end)
	end
	objTooltip:HookScript("OnHide", function(self)
		self.__tooltipUpdated = false
		--reset __lastLink in the addon itself not within the tooltip
		Tooltip.__lastLink = nil
		
		if self.qTip then
			LibQTip:Release(self.qTip)
			self.qTip = nil
		end
	end)
	objTooltip:HookScript("OnShow", function(self)
		if self.__tooltipUpdated then return end
	end)

end

function Tooltip:OnEnable()
	self:HookTooltip(GameTooltip)
	self:HookTooltip(ItemRefTooltip)
	if BSYC.IsRetail then
		self:HookBattlePetTooltip(BattlePetTooltip)
		self:HookBattlePetTooltip(FloatingBattlePetTooltip)
	end
end