--[[
	tooltip.lua
		Tooltip module for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Tooltip = BSYC:NewModule("Tooltip")
local Unit = BSYC:GetModule("Unit")
local Data = BSYC:GetModule("Data")
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

function Tooltip:HexColor(color, str)
	if type(color) == "table" then
		return string.format("|cff%02x%02x%02x%s|r", (color.r or 1) * 255, (color.g or 1) * 255, (color.b or 1) * 255, tostring(str))
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

function Tooltip:ColorizeUnit(unitObj, bypass, showRealm)
	if not unitObj.data then return nil end
	
	if unitObj.isGuild then
		return self:HexColor(BSYC.options.colors.first, select(2, Unit:GetUnitAddress(unitObj.name)) )
	end
	
	local player = Unit:GetUnitInfo()
	local tmpTag = ""
	local realm = unitObj.realm
	local realmTag = ""
	local delimiter = " "
	
	--first colorize by class color
	if bypass or BSYC.options.enableUnitClass and RAID_CLASS_COLORS[unitObj.data.class] then
		tmpTag = self:HexColor(RAID_CLASS_COLORS[unitObj.data.class], unitObj.name)
	else
		tmpTag = self:HexColor(BSYC.options.colors.first, unitObj.name)
	end
	
	--add green checkmark
	if unitObj.name == player.name and unitObj.realm == player.realm then
		if bypass or BSYC.options.enableTooltipGreenCheck then
			local ReadyCheck = [[|TInterface\RaidFrame\ReadyCheck-Ready:0|t]]
			tmpTag = ReadyCheck.." "..tmpTag
		end
	end
	
	--add faction icons
	if bypass or BSYC.options.enableFactionIcons then
		local FactionIcon = [[|TInterface\Icons\Achievement_worldevent_brewmaster:18|t]]
		
		if unitObj.data.faction == "Alliance" then
			FactionIcon = [[|TInterface\Icons\Inv_misc_tournaments_banner_human:18|t]]
		elseif unitObj.data.faction == "Horde" then
			FactionIcon = [[|TInterface\Icons\Inv_misc_tournaments_banner_orc:18|t]]
		end
		
		tmpTag = FactionIcon.." "..tmpTag
	end
	
	--return the bypass to display all server tags
	if bypass then
		if showRealm then
			realmTag = L.TooltipBattleNetTag..delimiter
			tmpTag = self:HexColor(BSYC.options.colors.bnet, "["..realmTag..realm.."]").." "..tmpTag
		end
		return tmpTag
	end
	
	if BSYC.options.No_XR_BNET_RealmNames then
		realm = ""
		delimiter = ""
	elseif BSYC.options.enableRealmAstrickName then
		realm = "*"
	elseif BSYC.options.enableRealmShortName then
		realm = string.sub(realm, 1, 5)
	end
	
	if BSYC.options.enableBNetAccountItems and not unitObj.isConnectedRealm then
		realmTag = BSYC.options.enableRealmIDTags and L.TooltipBattleNetTag..delimiter or ""
		tmpTag = self:HexColor(BSYC.options.colors.bnet, "["..realmTag..realm.."]").." "..tmpTag
	end
	
	if BSYC.options.enableCrossRealmsItems and unitObj.isConnectedRealm and unitObj.realm ~= player.realm then
		realmTag = BSYC.options.enableRealmIDTags and L.TooltipCrossRealmTag..delimiter or ""
		tmpTag = self:HexColor(BSYC.options.colors.cross, "["..realmTag..realm.."]").." "..tmpTag
	end
	
	return tmpTag
end

function Tooltip:MoneyTooltip()
	local tooltip = _G["BagSyncMoneyTooltip"] or nil
	
	if (not tooltip) then
			tooltip = CreateFrame("GameTooltip", "BagSyncMoneyTooltip", UIParent, "GameTooltipTemplate")
			
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
	tooltip:SetPoint("CENTER",UIParent,"CENTER",0,0)
	tooltip:AddLine("BagSync")
	tooltip:AddLine(" ")
	
	--loop through our characters
	local usrData = {}
	local total = 0
	
	for unitObj in Data:IterateUnits() do
		if unitObj.data.money and unitObj.data.money > 0 then
			table.insert(usrData, { unitObj=unitObj, colorized=self:ColorizeUnit(unitObj), sortIndex=self:GetSortIndex(unitObj) } )
		end
	end
	
	--sort the list by our sortIndex then by realm and finally by name
	table.sort(usrData, function(a, b)
		if a.sortIndex == b.sortIndex then
			if a.unitObj.realm == b.unitObj.realm then
				return a.unitObj.name < b.unitObj.name;
			end
			return a.unitObj.realm < b.unitObj.realm;
		end
		return a.sortIndex < b.sortIndex;
	end)

	for i=1, table.getn(usrData) do
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
		[7] = { source="void", 		desc=L.TooltipVoid },
		[8] = { source="auction", 	desc=L.TooltipAuction },
	}
		
	for i = 1, #list do
		local count, desc = allowList[list[i].source], list[i].desc
		if count > 0 then
			grouped = grouped + 1
			total = total + count
			
			desc = self:HexColor(BSYC.options.colors.first, desc)
			count = self:HexColor(BSYC.options.colors.second, count)
			
			tallyString = tallyString..L.TooltipDelimiter..desc.." "..count
		end
	end
	
	tallyString = strsub(tallyString, string.len(L.TooltipDelimiter) + 1) --remove first delimiter
	if total < 1 or string.len(tallyString) < 1 then return end
	
	--if it's groupped up and has more then one item then use a different color and show total
	if grouped > 1 then
		tallyString = self:HexColor(BSYC.options.colors.second, total).." ("..tallyString..")"
	end
	
	--add to list
	table.insert(unitList, { unitObj=unitObj, colorized=self:ColorizeUnit(unitObj), tallyString=tallyString, sortIndex=self:GetSortIndex(unitObj) } )

end

function Tooltip:ItemCount(data, itemID, allowList, source, total)
	if table.getn(data) < 1 then return total end
	
	for i=1, table.getn(data) do
		if data[i] then
			local link, count = strsplit(";", data[i])
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

function Tooltip:TallyUnits(objTooltip, link, source)
	if not BSYC.options.enableTooltips then return end
	if not CanAccessObject(objTooltip) then return end
	
	--only show tooltips in search frame if the option is enabled
	if BSYC.options.tooltipOnlySearch and objTooltip:GetOwner() and objTooltip:GetOwner():GetName() and not string.find(objTooltip:GetOwner():GetName(), "BagSyncSearchRow") then
		objTooltip:Show()
		return
	end
	
	--make sure we have something to work with
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
	
	--short the shortID and ignore all BonusID's and stats
	if BSYC.options.enableShowUniqueItemsTotals then link = shortID end
	
	--if we already did the item, then display the previous information
	if self.__lastLink and self.__lastLink == link then
		if self.__lastTally and table.getn(self.__lastTally) > 0 then
			for i=1, table.getn(self.__lastTally) do
				local color = BSYC.options.colors.total --this is a cover all color we are going to use
				objTooltip:AddDoubleLine(self.__lastTally[i].colorized, self.__lastTally[i].tallyString, color.r, color.g, color.b, color.r, color.g, color.b)
			end
		end
		objTooltip.__tooltipUpdated = true
		objTooltip:Show()
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
			["void"] = 0,
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
						--auction, equip, void, mailbox
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
	if table.getn(unitList) > 0 then

		table.sort(unitList, function(a, b)
			if a.sortIndex == b.sortIndex then
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
	if BSYC.options.showTotal and grandTotal > 0 and table.getn(unitList) > 1 then
		desc = self:HexColor(BSYC.options.colors.total, L.TooltipTotal)
		value = self:HexColor(BSYC.options.colors.second, grandTotal)
		table.insert(unitList, { colorized=desc, tallyString=value} )
	end
		
	--add ItemID
	if BSYC.options.enableTooltipItemID and shortID then
		desc = self:HexColor(BSYC.options.colors.itemid, L.TooltipItemID)
		value = self:HexColor(BSYC.options.colors.second, shortID)
		table.insert(unitList, 1, { colorized=desc, tallyString=value} )
	end
	
	--add seperator if enabled and only if we have something to work with
	if BSYC.options.enableTooltipSeperator and table.getn(unitList) > 0 then
		table.insert(unitList, 1, { colorized=" ", tallyString=" "} )
	end
	
	--finally display it
	for i=1, table.getn(unitList) do
		local color = BSYC.options.colors.total --this is a cover all color we are going to use
		objTooltip:AddDoubleLine(unitList[i].colorized, unitList[i].tallyString, color.r, color.g, color.b, color.r, color.g, color.b)
	end
	
	self.__lastTally = unitList
	
	objTooltip.__tooltipUpdated = true
	objTooltip:Show()
end

function Tooltip:CurrencyTooltip(objTooltip, currencyName, currencyIcon)

	--loop through our characters
	local usrData = {}
	
	for unitObj in Data:IterateUnits() do
		if not unitObj.isGuild and unitObj.data.currency and unitObj.data.currency[currencyIcon] then
			table.insert(usrData, { unitObj=unitObj, colorized=self:ColorizeUnit(unitObj), sortIndex=self:GetSortIndex(unitObj), count=unitObj.data.currency[currencyIcon].count} )
		end
	end
	
	--sort the list by our sortIndex then by realm and finally by name
	table.sort(usrData, function(a, b)
		if a.sortIndex == b.sortIndex then
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

	for i=1, table.getn(usrData) do
		objTooltip:AddDoubleLine(usrData[i].colorized, usrData[i].count, 1, 1, 1, 1, 1, 1)
	end

	objTooltip.__tooltipUpdated = true
	objTooltip:Show()
end



-- To know if we are in the first or second call of OnTooltipSetItem()
-- for recipes without a sell price, we to scan the tooltip for "Use: Teaches you...".
-- There is the global string ITEM_SPELL_TRIGGER_ONUSE for "Use:"
-- but there is none for "Teaches you...".
-- Just scanning for "Use:" is not enough, as consumable recipe products have a "Use:" too.
-- Thus, we would have to store these strings for all locales:
local teachesYouString = {
	["deDE"] = "Lehrt Euch", 
	["enUS"] = "Teaches you", 
	["enGB"] = "Teaches you", 
	["esES"] = "Te enseña", 
	["esMX"] = "Te enseña", 
	["frFR"] = "Vous apprend", 
	["itIT"] = "Ti insegna", 
	["koKR"] = "배웁니다", -- (Right to Left)
	["ptBR"] = "Ensina",
	["ruRU"] = "Обучает",
	["zhCN"] = "教你",
	["zhTW"] = "教你"
}


function Tooltip:HookTooltip(objTooltip)
	
	objTooltip:HookScript("OnHide", function(self)
		self.__tooltipUpdated = false
		--reset __lastLink in the addon itself not within the tooltip
		Tooltip.__lastLink = nil
	end)
	objTooltip:HookScript("OnTooltipCleared", function(self)
		--this gets called repeatedly on some occasions. Do not reset Tooltip.__lastLink here
		self.__tooltipUpdated = false
	end)
	objTooltip:HookScript("OnTooltipSetItem", function(self)
		
		if self.__tooltipUpdated then return end
		
		local name, link = self:GetItem()


		-- -- OnTooltipSetItem gets called twice for recipes which contain embedded items. We only want the second one!
		-- if name and link then
		
			-- local _, _, _, _, _, _, _, _, _, _, _, itemTypeId, itemSubTypeId = GetItemInfo(link)
			-- if itemTypeId == LE_ITEM_CLASS_RECIPE and itemSubTypeId ~= LE_ITEM_RECIPE_BOOK then
			
				-- local locale = GetLocale()
				-- if teachesYouString[locale] then
				
					-- local foundUseTeachesYou = false
				
					-- -- We first search for the "Use: Teaches you" line.
					-- local searchPattern1 = nil
					-- -- koKR is right to left.
					-- if locale == "koKR" then
						-- searchPattern1 = "^" .. ITEM_SPELL_TRIGGER_ONUSE .. ".-" .. teachesYouString[locale]
					-- else
						-- searchPattern1 = "^" .. ITEM_SPELL_TRIGGER_ONUSE .. ".-" .. teachesYouString[locale]
					-- end
					
					
					-- -- Some recipes may even have two "Use: Teaches you" lines
					-- -- (e.g. https://www.wowhead.com/item=67538/recipe-vial-of-the-sands)
					-- -- which is why we have to check if the recipe's product name
					-- -- occurs in it.
					-- local productName = nil
					-- -- zhCN and zhTW have a special colon.
					-- if locale == "zhCN" or locale == "zhTW" then
						-- productName = string.match(name, ".-：(.+)")
					-- else
						-- productName = string.match(name, ".-: (.+)")
					-- end
					
					-- if productName then 

						-- -- The complete product name is sometimes not included in the
						-- -- "Use: Teaches you" line. E.g.:
						-- -- https://www.wowhead.com/item=2698
						-- -- https://de.wowhead.com/item=2889
						-- -- https://ru.wowhead.com/item=2701
						-- -- We therefore search for each word separately.
						-- -- This can go wrong as well, if e.g. for vial-of-the-sands
						-- -- "of" or "the" also occurs in the recipe product's "Use: Teaches you" line.
						-- -- But it seems like the best option right now
						-- -- until another counter-ecample is found.
						-- local productNameWords = {}
						-- for word in string.gmatch(productName, "%S+") do
							-- -- Insert word into the table and espace characters - + % . ( ) [ ].
							-- local escapedWord = string.gsub(word, "[%-+%%.()%[%]]", "%%%0")
							-- table.insert(productNameWords, escapedWord)
						-- end
						
						
						-- -- Search from bottom to top, because the searched line is most likely down.
						-- -- Only search up to line 2, because the searched line is definitely not topmost.
						-- for i = self:NumLines(), 2, -1 do
							-- local line = _G[self:GetName().."TextLeft"..i]:GetText()
							-- if string.find(line, searchPattern1) then
								
								-- -- Search from back to front as the last word is more likely to hit!
								-- for j = #productNameWords, 1, -1 do

									-- local searchPattern2 = nil
									-- -- koKR is right to left.
									-- if locale == "koKR" then
										-- searchPattern2 = "^" .. ITEM_SPELL_TRIGGER_ONUSE .. ".-" .. productNameWords[j] .. ".-" .. teachesYouString[locale]
									-- else
										-- searchPattern2 = "^" .. ITEM_SPELL_TRIGGER_ONUSE .. ".-" .. teachesYouString[locale] .. ".-" .. productNameWords[j]
									-- end
										
									-- if string.find(string.lower(line), string.lower(searchPattern2)) then
										-- foundUseTeachesYou = true
										-- break
									-- end
									
								-- end
								
								-- if foundUseTeachesYou then
									-- break
								-- end
							-- end
						-- end
					-- end
					
					-- if not foundUseTeachesYou then return end
					
				-- end
			-- end
		-- end

		
		
		if name and string.len(name) > 0 and link then
			Tooltip:TallyUnits(self, link, "OnTooltipSetItem")
		end
	end)
	hooksecurefunc(objTooltip, "SetRecipeReagentItem", function(self, recipeID, reagentIndex)
		if self.__tooltipUpdated then return end
		local link = C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, reagentIndex)
		if link then
			Tooltip:TallyUnits(self, link, "SetRecipeReagentItem")
		end
	end)
	hooksecurefunc(objTooltip, "SetRecipeResultItem", function(self, recipeID)
		if self.__tooltipUpdated then return end
		local link = C_TradeSkillUI.GetRecipeItemLink(recipeID)
		if link then
			Tooltip:TallyUnits(self, link, "SetRecipeResultItem")
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
	
	--------------------------------------------------
	hooksecurefunc(objTooltip, "SetCurrencyToken", function(self, index)
		if self.__tooltipUpdated then return end
		local name, isHeader, isExpanded, isUnused, isWatched, count, icon = GetCurrencyListInfo(index)
		if name and icon then
			Tooltip:CurrencyTooltip(self, name, icon)
		end
	end)
	hooksecurefunc(objTooltip, "SetCurrencyTokenByID", function(self, index)
		if self.__tooltipUpdated then return end
		local name, currentAmount, icon, earnedThisWeek, weeklyMax, totalMax, isDiscovered, rarity = GetCurrencyInfo(index)
		if name and icon then
			Tooltip:CurrencyTooltip(self, name, icon)
		end
	end)
	hooksecurefunc(objTooltip, "SetCurrencyByID", function(self, index)
		if self.__tooltipUpdated then return end
		local name, currentAmount, icon, earnedThisWeek, weeklyMax, totalMax, isDiscovered, rarity = GetCurrencyInfo(index)
		if name and icon then
			Tooltip:CurrencyTooltip(self, name, icon)
		end
	end)
	hooksecurefunc(objTooltip, "SetBackpackToken", function(self, index)
		if self.__tooltipUpdated then return end
		local name, count, icon, currencyID = GetBackpackCurrencyInfo(index)
		if name and icon then
			Tooltip:CurrencyTooltip(self, name, icon)
		end
	end)

end

function Tooltip:OnEnable()
	self:HookTooltip(GameTooltip)
	self:HookTooltip(ItemRefTooltip)
end