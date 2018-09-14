--[[
	tooltip.lua
		Tooltip module for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Tooltip = BSYC:NewModule("Tooltip", 'AceEvent-3.0')
local Unit = BSYC:GetModule("Unit")
local Data = BSYC:GetModule("Data")
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync", true)

function Tooltip:HexColor(color, str)
	if type(color) == "table" then
		return string.format("|cff%02x%02x%02x%s|r", (color.r or 1) * 255, (color.g or 1) * 255, (color.b or 1) * 255, tostring(str))
	elseif type(color) == "string" then
		string.format("|cff%s%s|r", tostring(color), tostring(str))
	end
	return str
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

function Tooltip:ColorizeUnit(unitObj)
	if not unitObj.data then return nil end
	
	if unitObj.isGuild then
		return self:HexColor(BSYC.options.colors.first, select(2, Unit:GetUnitAddress(unitObj.name)) )
	end
	
	local player = Unit:GetUnitInfo()
	local tmpTag = ""
	
	--first colorize by class color
	if BSYC.options.enableUnitClass and RAID_CLASS_COLORS[unitObj.data.class] then
		tmpTag = self:HexColor(RAID_CLASS_COLORS[unitObj.data.class], unitObj.name)
	else
		tmpTag = self:HexColor(BSYC.options.colors.first, unitObj.name)
	end
	
	--add green checkmark
	if unitObj.name == player.name and unitObj.realm == player.realm and BSYC.options.enableTooltipGreenCheck then
		local ReadyCheck = [[|TInterface\RaidFrame\ReadyCheck-Ready:0|t]]
		tmpTag = ReadyCheck.." "..tmpTag
	end
	
	--add faction icons
	if BSYC.options.enableFactionIcons then
		local FactionIcon = [[|TInterface\Icons\Achievement_worldevent_brewmaster:18|t]]
		
		if unitObj.data.faction == "Alliance" then
			FactionIcon = [[|TInterface\Icons\Inv_misc_tournaments_banner_human:18|t]]
		elseif unitObj.data.faction == "Horde" then
			FactionIcon = [[|TInterface\Icons\Inv_misc_tournaments_banner_orc:18|t]]
		end
		
		tmpTag = FactionIcon.." "..tmpTag
	end
	
	--add crossrealm and bnet tags
	local realm = unitObj.realm
	local realmTag = ""
	local delimiter = " "
	
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

	local usrData = {}
	
	tooltip:ClearLines()
	tooltip:ClearAllPoints()
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetPoint("CENTER",UIParent,"CENTER",0,0)
	tooltip:AddLine("BagSync")
	tooltip:AddLine(" ")
	
	--loop through our characters
	local usrData = {}
	local total = 0
	local player = Unit:GetUnitInfo()
	
	for unitObj in Data:IterateUnits() do
		if unitObj.data.money and unitObj.data.money > 0 then
			table.insert(usrData, { unitObj=unitObj, colorized=self:ColorizeUnit(unitObj), sortIndex=self:GetSortIndex(unitObj) } )
		end
	end
	
	--sort the list by our sortIndex then by realm and finally by name
	table.sort(usrData, function(a, b)
		if a.sortIndex  == b.sortIndex then
			if a.unitObj.realm == b.unitObj.realm then
				return a.unitObj.name < b.unitObj.name;
			end
			return a.unitObj.realm < b.unitObj.realm;
		else
			return a.sortIndex < b.sortIndex;
		end
	  
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
		local link, count = strsplit(";", data[i])
		if link then
			if BSYC.options.enableShowUniqueItemsTotals then link = BSYC:GetShortItemID(link) end
			if link == itemID then
				allowList[source] = allowList[source] + (count or 1)
				total = total + (count or 1)
			end
		end
	end
	return total
end

function Tooltip:TallyUnits(objTooltip, link, source)
	if not BSYC.options.enableTooltips then return end
	
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
	
	local player = Unit:GetUnitInfo()
	local shortID = BSYC:GetShortItemID(link)
	
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
						if (k ~= "auction" or k ~= "mailbox") or (k == "auction" and BSYC.options.enableAuction) or (k == "mailbox" and BSYC.options.enableMailbox) then
							grandTotal = self:ItemCount(k == "auction" and v.bag or v, link, allowList, k, grandTotal)
						end
					end
				end
			end
		else
			--it's a guild, use the guild bag, we don't have to worry about repeats.  IterateUnits takes care of this
			if unitObj.data.bag then
				grandTotal = self:ItemCount(unitObj.data.bag, link, allowList, "guild", grandTotal)
			end
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
			if a.sortIndex  == b.sortIndex then
				if a.unitObj.realm == b.unitObj.realm then
					return a.unitObj.name < b.unitObj.name;
				end
				return a.unitObj.realm < b.unitObj.realm;
			else
				return a.sortIndex < b.sortIndex;
			end
		  
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
	
end

function Tooltip:OnEnable()
	self:HookTooltip(GameTooltip)
	self:HookTooltip(ItemRefTooltip)
end