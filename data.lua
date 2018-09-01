--[[
	data.lua
		Handles all the data elements for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync", true)
local Unit = BSYC:GetModule("Unit")
local Events = BSYC:GetModule("Events")

----------------------
--   DB Functions   --
----------------------

function BSYC:StartupDB()

	--get player information from Unit
	local player = Unit:GetUnitInfo()

	--initiate global db variable
	BagSyncDB = BagSyncDB or {}
	BagSyncDB["options§"] = BagSyncDB["options§"] or {}
	BagSyncDB["blacklist§"] = BagSyncDB["blacklist§"] or {}
	
	--main DB call
	self.db = self.db or {}
	self.db.global = BagSyncDB
	
	--realm DB
	BagSyncDB[player.realm] = BagSyncDB[player.realm] or {}
	self.db.realm = BagSyncDB[player.realm]
	
	--player DB
	self.db.realm[player.name] = self.db.realm[player.name] or {}
	self.db.player = self.db.realm[player.name]
	self.db.player.currency = self.db.player.currency or {}
	self.db.player.profession = self.db.player.profession or {}
	
	--blacklist DB
	self.db.blacklist = BagSyncDB["blacklist§"]
	
	--options DB
	self.db.options = BagSyncDB["options§"]
	if self.db.options.showTotal == nil then self.db.options.showTotal = true end
	if self.db.options.showGuildNames == nil then self.db.options.showGuildNames = false end
	if self.db.options.enableGuild == nil then self.db.options.enableGuild = true end
	if self.db.options.enableMailbox == nil then self.db.options.enableMailbox = true end
	if self.db.options.enableUnitClass == nil then self.db.options.enableUnitClass = false end
	if self.db.options.enableMinimap == nil then self.db.options.enableMinimap = true end
	if self.db.options.enableFaction == nil then self.db.options.enableFaction = true end
	if self.db.options.enableAuction == nil then self.db.options.enableAuction = true end
	if self.db.options.tooltipOnlySearch == nil then self.db.options.tooltipOnlySearch = false end
	if self.db.options.enableTooltips == nil then self.db.options.enableTooltips = true end
	if self.db.options.enableTooltipSeperator == nil then self.db.options.enableTooltipSeperator = true end
	if self.db.options.enableCrossRealmsItems == nil then self.db.options.enableCrossRealmsItems = true end
	if self.db.options.enableBNetAccountItems == nil then self.db.options.enableBNetAccountItems = false end
	if self.db.options.enableTooltipItemID == nil then self.db.options.enableTooltipItemID = false end
	if self.db.options.enableTooltipGreenCheck == nil then self.db.options.enableTooltipGreenCheck = true end
	if self.db.options.enableRealmIDTags == nil then self.db.options.enableRealmIDTags = true end
	if self.db.options.enableRealmAstrickName == nil then self.db.options.enableRealmAstrickName = false end
	if self.db.options.enableRealmShortName == nil then self.db.options.enableRealmShortName = false end
	if self.db.options.enableLoginVersionInfo == nil then self.db.options.enableLoginVersionInfo = true end
	if self.db.options.enableFactionIcons == nil then self.db.options.enableFactionIcons = true end
	if self.db.options.enableShowUniqueItemsTotals == nil then self.db.options.enableShowUniqueItemsTotals = true end

	--setup the default colors
	if self.db.options.colors == nil then self.db.options.colors = {} end
	if self.db.options.colors.first == nil then self.db.options.colors.first = { r = 128/255, g = 1, b = 0 }  end
	if self.db.options.colors.second == nil then self.db.options.colors.second = { r = 1, g = 1, b = 1 }  end
	if self.db.options.colors.total == nil then self.db.options.colors.total = { r = 244/255, g = 164/255, b = 96/255 }  end
	if self.db.options.colors.guild == nil then self.db.options.colors.guild = { r = 101/255, g = 184/255, b = 192/255 }  end
	if self.db.options.colors.cross == nil then self.db.options.colors.cross = { r = 1, g = 125/255, b = 10/255 }  end
	if self.db.options.colors.bnet == nil then self.db.options.colors.bnet = { r = 53/255, g = 136/255, b = 1 }  end
	if self.db.options.colors.itemid == nil then self.db.options.colors.itemid = { r = 82/255, g = 211/255, b = 134/255 }  end

	--do DB cleanup check by version number
	if not self.db.options.dbversion or self.db.options.dbversion ~= ver then	
		--self:FixDB()
		self.db.options.dbversion = ver
	end

	--player info
	self.db.player.money = player.money
	self.db.player.class = player.class
	self.db.player.race = player.race
	self.db.player.guild = player.guild
	self.db.player.gender = player.gender
	self.db.player.faction = player.faction

end

function BSYC:FixDB(onlyChkGuild)
	self:Print("|cFFFF9900"..L.FixDBComplete.."|r")
end

function BSYC:CleanAuctionsDB()
	--this function will remove expired auctions for all characters in every realm
	local timestampChk = { 30*60, 2*60*60, 12*60*60, 48*60*60 }
				
	for realm, rd in pairs(BagSyncDB) do
		--realm
		for k, v in pairs(rd) do
			--users k=name, v=values
			if BagSyncDB[realm][k].AH_LastScan and BagSyncDB[realm][k].AH_Count then --only proceed if we have an auction house time to work with
				--check to see if we even have something to work with
				if BagSyncDB[realm][k]["auction"] then
					--we do so lets do a loop
					local bVal = BagSyncDB[realm][k].AH_Count
					--do a loop through all of them and check to see if any expired
					for x = 1, bVal do
						if BagSyncDB[realm][k]["auction"][0][x] then
							--check for expired and remove if necessary
							--it's okay if the auction count is showing more then actually stored, it's just used as a means
							--to scan through all our items.  Even if we have only 3 and the count is 6 it will just skip the last 3.
							local dblink, dbcount, dbtimeleft = strsplit(",", BagSyncDB[realm][k]["auction"][0][x])
							
							--only proceed if we have everything to work with, otherwise this auction data is corrupt
							if dblink and dbcount and dbtimeleft then
								if tonumber(dbtimeleft) < 1 or tonumber(dbtimeleft) > 4 then dbtimeleft = 4 end --just in case
								--now do the time checks
								local diff = time() - BagSyncDB[realm][k].AH_LastScan 
								if diff > timestampChk[tonumber(dbtimeleft)] then
									--technically this isn't very realiable.  but I suppose it's better the  nothing
									BagSyncDB[realm][k]["auction"][0][x] = nil
								end
							else
								--it's corrupt delete it
								BagSyncDB[realm][k]["auction"][0][x] = nil
							end
						end
					end
				end
			end
		end
	end
	
end

----------------------
--  Bag Functions   --
----------------------


------------------------
--   Money Tooltip    --
------------------------

function BSYC:ShowMoneyTooltip(objTooltip)
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
	
	if objTooltip then
		tooltip:SetOwner(objTooltip, "ANCHOR_NONE")
		tooltip:SetPoint("CENTER",objTooltip,"CENTER",0,0)
	else
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetPoint("CENTER",UIParent,"CENTER",0,0)
	end

	tooltip:AddLine("BagSync")
	tooltip:AddLine(" ")
	
	--loop through our characters

	local playerName = ""


	for k, v in pairs(self.db.global) do
		if not k:find('§*') then --no options (astrick at end to start from right)
			for q, x in pairs(v) do
				if not q:find('©*') then --no guilds (well for right now lol)
					if x.money then
						playerName = self:GetClassColor(q or "Unknown", x.class)
						table.insert(usrData, { name=playerName, gold=x.money } )
					end
				end
			end
			
		end
	end
	table.sort(usrData, function(a,b) return (a.name < b.name) end)
	
	local gldTotal = 0
	
	for i=1, table.getn(usrData) do
		tooltip:AddDoubleLine(usrData[i].name, GetCoinTextureString(usrData[i].gold), 1, 1, 1, 1, 1, 1)
		gldTotal = gldTotal + usrData[i].gold
	end
	if self.db.options.showTotal and gldTotal > 0 then
		tooltip:AddLine(" ")
		tooltip:AddDoubleLine(self:tooltipColor(self.db.options.colors.total, L.TooltipTotal), GetCoinTextureString(gldTotal), 1, 1, 1, 1, 1, 1)
	end
	
	tooltip:AddLine(" ")
	tooltip:Show()
end

function BSYC:HideMoneyTooltip()
	local tooltip = _G["BagSyncMoneyTooltip"] or nil
	if tooltip then
		tooltip:Hide()
	end
end

------------------------
--      Currency      --
------------------------

function BSYC:ScanCurrency()
	--LETS AVOID CURRENCY SPAM AS MUCH AS POSSIBLE
	if self.doCurrencyUpdate and self.doCurrencyUpdate > 0 then return end
	if self:IsInBG() or self:IsInArena() or InCombatLockdown() or UnitAffectingCombat("player") then
		--avoid (Honor point spam), avoid (arena point spam), if it's world PVP...well then it sucks to be you
		self.doCurrencyUpdate = 1
		BSYC:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	local lastHeader
	local limit = GetCurrencyListSize()

	for i=1, limit do
	
		local name, isHeader, isExpanded, _, _, count, icon = GetCurrencyListInfo(i)
		--extraCurrencyType = 1 for arena points, 2 for honor points; 0 otherwise (an item-based currency).

		if name then
			if(isHeader and not isExpanded) then
				ExpandCurrencyList(i,1)
				lastHeader = name
				limit = GetCurrencyListSize()
			elseif isHeader then
				lastHeader = name
			end
			if (not isHeader) then
				self.db.player.currency[icon] = {title = name, header = lastHeader, count = count}
			end
		end
	end
	--we don't want to overwrite currency, because some characters may have currency that the others dont have	
end

------------------------
--      Tooltip       --
------------------------

function BSYC:ResetTooltip()
	self.PreviousItemTotals = {}
	self.PreviousItemLink = nil
end

function BSYC:CreateItemTotals(countTable)
	local info = ""
	local total = 0
	local grouped = 0
	
	--order in which we want stuff displayed
	local list = {
		[1] = { "bag", 			L.TooltipBag },
		[2] = { "bank", 		L.TooltipBank },
		[3] = { "reagentbank", 	L.TooltipReagent },
		[4] = { "equip", 		L.TooltipEquip },
		[5] = { "guild", 		L.TooltipGuild },
		[6] = { "mailbox", 		L.TooltipMail },
		[7] = { "void", 		L.TooltipVoid },
		[8] = { "auction", 		L.TooltipAuction },
	}
		
	for i = 1, #list do
		local count = countTable[list[i][1]]
		if count > 0 then
			grouped = grouped + 1
			info = info..L.TooltipDelimiter..self:tooltipColor(self.db.options.colors.first, list[i][2]).." "..self:tooltipColor(self.db.options.colors.second, count)
			total = total + count
		end
	end

	--remove the first delimiter since it's added to the front automatically
	info = strsub(info, string.len(L.TooltipDelimiter) + 1)
	if string.len(info) < 1 then return nil end --return nil for empty strings
	
	--if it's groupped up and has more then one item then use a different color and show total
	if grouped > 1 then
		info = self:tooltipColor(self.db.options.colors.second, total).." ("..info..")"
	end
	
	return info
end

function BSYC:GetClassColor(sName, sClass)
	if not self.db.options.enableUnitClass then
		return self:tooltipColor(self.db.options.colors.first, sName)
	else
		if sName ~= "Unknown" and sClass and RAID_CLASS_COLORS[sClass] then
			return rgbhex(RAID_CLASS_COLORS[sClass])..sName.."|r"
		end
	end
	return self:tooltipColor(self.db.options.colors.first, sName)
end

function BSYC:AddCurrencyTooltip(frame, currencyName, addHeader)
	if not self.db.options.enableTooltips then return end
	
	local tmp = {}
	local count = 0
	
	local xDB = BSYC:FilterDB(2) --dbSelect 2
		
	for k, v in pairs(xDB) do
		local yName, yRealm  = strsplit("^", k)
		local playerName = BSYC:GetRealmTags(yName, yRealm)

		playerName = self:GetClassColor(playerName or "Unknown", self.db.global[yRealm][yName].class)

		for q, r in pairs(v) do
			if q == currencyName then
				--we only really want to list the currency once for display
				table.insert(tmp, { name=playerName, count=r.count} )
				count = count + 1
			end
		end
	end
	
	if count > 0 then
		table.sort(tmp, function(a,b) return (a.name < b.name) end)
		if self.db.options.enableTooltipSeperator and not addHeader then
			frame:AddLine(" ")
		end
		if addHeader then
			local color = { r = 64/255, g = 224/255, b = 208/255 } --same color as header in Currency window
			frame:AddLine(rgbhex(color)..currencyName.."|r")
		end
		for i=1, #tmp do
			frame:AddDoubleLine(self:tooltipColor(self.db.options.colors.first, tmp[i].name), self:tooltipColor(self.db.options.colors.second, tmp[i].count))
		end
	end
	
	frame:Show()
end

function BSYC:AddItemToTooltip(frame, link) --workaround
	if not self.db.options.enableTooltips then return end
	
	--if we can't convert the item link then lets just ignore it altogether	
	local itemLink = self:ParseItemLink(link)
	if not itemLink then
		frame:Show()
		return
	end
	
	--get player information from Unit
	local player = Unit:GetUnitInfo()

	--use our stripped itemlink, not the full link
	local shortItemID = self:GetShortItemID(itemLink)

	--short the shortID and ignore all BonusID's and stats
	if self.db.options.enableShowUniqueItemsTotals then itemLink = shortItemID end
	
	--only show tooltips in search frame if the option is enabled
	if self.db.options.tooltipOnlySearch and frame:GetOwner() and frame:GetOwner():GetName() and string.sub(frame:GetOwner():GetName(), 1, 16) ~= "BagSyncSearchRow" then
		frame:Show()
		return
	end
	
	--HEARTHSTONE_ITEM_ID
	local permIgnore ={
		["6948"] = "Hearthstone",
		["110560"] = "Garrison Hearthstone",
		["140192"] = "Dalaran Hearthstone",
		["128353"] = "Admiral's Compass",
	}
	
	local blocked = permIgnore[shortItemID] or self.db.blacklist[shortItemID]
	if blocked then frame:Show() return end

--[[ 	local itemID = tonumber(link and GetItemInfo(link) and link:match('item:(%d+)')) -- Blizzard doing craziness when doing GetItemInfo
	if not itemID or itemID == HEARTHSTONE_ITEM_ID then
		return
	end ]]
	
	--lag check (check for previously displayed data) if so then display it
	if self.PreviousItemLink and itemLink and itemLink == self.PreviousItemLink then
		if table.getn(self.PreviousItemTotals) > 0 then
			for i = 1, #self.PreviousItemTotals do
				local ename, ecount  = strsplit("@", self.PreviousItemTotals[i])
				if ename and ecount then
					local color = self.db.options.colors.total
					frame:AddDoubleLine(ename, ecount, color.r, color.g, color.b, color.r, color.g, color.b)
				else
					local color = self.db.options.colors.second
					frame:AddLine(self.PreviousItemTotals[i], color.r, color.g, color.b)				
				end
			end
		end
		frame:Show()
		return
	end

	--reset our last displayed
	self.PreviousItemTotals = {}
	self.PreviousItemLink = itemLink
	
	--this is so we don't scan the same guild multiple times
	local previousGuilds = {}
	local previousGuildsXRList = {}
	local grandTotal = 0
	local first = true
	
	local xDB = self:FilterDB()
	
	--loop through our characters
	--k = player, v = stored data for player
	for k, v in pairs(xDB) do

		local allowList = {
			["bag"] = 0,
			["bank"] = 0,
			["reagentbank"] = 0,
			["equip"] = 0,
			["mailbox"] = 0,
			["vault"] = 0,
			["auction"] = 0,
			["guild"] = 0,
		}
	
		local infoString
		local pFaction = v.faction or self.playerFaction --just in case ;) if we dont know the faction yet display it anyways
		
		--check if we should show both factions or not
		if self.db.options.enableFaction or pFaction == self.playerFaction then
		
			--now count the stuff for the user
			--q = bag name, r = stored data for bag name
			for q, r in pairs(v) do
				--only loop through table items we want
				if allowList[q] and type(r) == "table" then
					--bagID = bag name bagID, bagInfo = data of specific bag with bagID
					for bagID, bagInfo in pairs(r) do
						--slotID = slotid for specific bagid, itemValue = data of specific slotid
						if type(bagInfo) == "table" then
							for slotID, itemValue in pairs(bagInfo) do
								local dblink, dbcount = strsplit(",", itemValue)
								if dblink and self.db.options.enableShowUniqueItemsTotals then dblink = self:GetShortItemID(dblink) end
								if dblink and dblink == itemLink then
									allowList[q] = allowList[q] + (dbcount or 1)
									grandTotal = grandTotal + (dbcount or 1)
								end
							end
						end
					end
				end
			end
		
			if self.db.options.enableGuild then
				local guildN = v.guild or nil
			
				--check the guild bank if the character is in a guild
				if guildN and self.db.guild[v.realm][guildN] then
					--check to see if this guild has already been done through this run (so we don't do it multiple times)
					--check for XR/B.Net support, you can have multiple guilds with same names on different servers
					local gName = self:GetRealmTags(guildN, v.realm, true)
					
					--check to make sure we didn't already add a guild from a connected-realm
					local trueRealmList = self.db.realmkey[0][v.realm] --get the connected realms
					if trueRealmList then
						table.sort(trueRealmList, function(a,b) return (a < b) end) --sort them alphabetically
						trueRealmList = table.concat(trueRealmList, "|") --concat them together
					else
						trueRealmList = v.realm
					end
					trueRealmList = guildN.."-"..trueRealmList --add the guild name in front of concat realm list

					if not previousGuilds[gName] and not previousGuildsXRList[trueRealmList] then
						--we only really need to see this information once per guild
						local tmpCount = 0
						for q, r in pairs(self.db.guild[v.realm][guildN]) do
							local dblink, dbcount = strsplit(",", r)
							if dblink and self.db.options.enableShowUniqueItemsTotals then dblink = self:GetShortItemID(dblink) end
							if dblink and dblink == itemLink then
								--if we have show guild names then don't show any guild info for the character, otherwise it gets repeated twice
								if not self.db.options.showGuildNames then
									allowList["guild"] = allowList["guild"] + (dbcount or 1)
								end
								tmpCount = tmpCount + (dbcount or 1)
								grandTotal = grandTotal + (dbcount or 1)
							end
						end
						previousGuilds[gName] = tmpCount
						previousGuildsXRList[trueRealmList] = true
					end
				end
			end
			
			--get class for the unit if there is one
			infoString = self:CreateItemTotals(allowList)

			if infoString then
				local yName, yRealm  = strsplit("^", k)
				local playerName = self:GetRealmTags(yName, yRealm)
				table.insert(self.PreviousItemTotals, self:GetClassColor(playerName or "Unknown", v.class).."@"..(infoString or "unknown"))
			end
			
		end
		
	end
	
	--sort it
	table.sort(self.PreviousItemTotals, function(a,b) return (a < b) end)
	
	--show guildnames last
	if self.db.options.enableGuild and self.db.options.showGuildNames then
		for k, v in self:pairsByKeys(previousGuilds) do
			--only print stuff higher then zero
			if v > 0 then
				table.insert(self.PreviousItemTotals, self:tooltipColor(self.db.options.colors.guild, k).."@"..self:tooltipColor(self.db.options.colors.second, v))
			end
		end
	end
	
	--show grand total if we have something
	--don't show total if there is only one item
	if self.db.options.showTotal and grandTotal > 0 and getn(self.PreviousItemTotals) > 1 then
		table.insert(self.PreviousItemTotals, self:tooltipColor(self.db.options.colors.total, L.TooltipTotal).."@"..self:tooltipColor(self.db.options.colors.second, grandTotal))
	end
	
	--add ItemID if it's enabled
	if table.getn(self.PreviousItemTotals) > 0 and self.db.options.enableTooltipItemID and shortItemID and tonumber(shortItemID) then
		table.insert(self.PreviousItemTotals, 1 , self:tooltipColor(self.db.options.colors.itemid, L.TooltipItemID).." "..self:tooltipColor(self.db.options.colors.second, shortItemID))
	end
	
	--now check for seperater and only add if we have something in the table already
	if table.getn(self.PreviousItemTotals) > 0 and self.db.options.enableTooltipSeperator then
		table.insert(self.PreviousItemTotals, 1 , " ")
	end
	
	--add it all together now
	if table.getn(self.PreviousItemTotals) > 0 then
		for i = 1, #self.PreviousItemTotals do
			local ename, ecount  = strsplit("@", self.PreviousItemTotals[i])
			if ename and ecount then
				local color = self.db.options.colors.total
				frame:AddDoubleLine(ename, ecount, color.r, color.g, color.b, color.r, color.g, color.b)
			else
				local color = self.db.options.colors.second
				frame:AddLine(self.PreviousItemTotals[i], color.r, color.g, color.b)				
			end
		end
	end

	frame:Show()
end

function BSYC:HookTooltip(tooltip)

	tooltip.isModified = false
	
	tooltip:HookScript("OnHide", function(self)
		self.isModified = false
		self.lastHyperLink = nil
	end)	
	tooltip:HookScript("OnTooltipCleared", function(self)
		self.isModified = false
	end)

	tooltip:HookScript("OnTooltipSetItem", function(self)
		if self.isModified then return end
		local name, link = self:GetItem()

		if link then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
			return
		end
		--sometimes we have a tooltip but no link because GetItem() returns nil, this is the case for recipes
		--so lets try something else to see if we can get the link.  Doesn't always work!  Thanks for breaking GetItem() Blizzard... you ROCK! :P
		if not self.isModified and self.lastHyperLink then
			local xName, xLink = GetItemInfo(self.lastHyperLink)
			if xLink then  --only show info if the tooltip text matches the link
				self.isModified = true
				BSYC:AddItemToTooltip(self, xLink)
			end		
		end
	end)

	---------------------------------
	--Special thanks to GetItem() being broken we need to capture the ItemLink before the tooltip shows sometimes
	hooksecurefunc(tooltip, "SetBagItem", function(self, tab, slot)
		local link = GetContainerItemLink(tab, slot)
		if link then
			self.lastHyperLink = link
		end
	end)
	hooksecurefunc(tooltip, "SetInventoryItem", function(self, tab, slot)
		local link = GetInventoryItemLink(tab, slot)
		if link then
			self.lastHyperLink = link
		end
	end)
	hooksecurefunc(tooltip, "SetGuildBankItem", function(self, tab, slot)
		local link = GetGuildBankItemLink(tab, slot)
		if link then
			self.lastHyperLink = link
		end
	end)
	hooksecurefunc(tooltip, "SetHyperlink", function(self, link)
		if self.isModified then return end
		if link then
			--I'm pretty sure there is a better way to do this but since Recipes fire OnTooltipSetItem with empty/nil GetItem().  There is really no way to my knowledge to grab the current itemID
			--without storing the ItemLink from the bag parsing or at least grabbing the current SetHyperLink.
			if tooltip:IsVisible() then self.isModified = true end --only do the modifier if the tooltip is showing, because this interferes with ItemRefTooltip if someone clicks it twice in chat
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	---------------------------------

	--lets hook other frames so we can show tooltips there as well, sometimes GetItem() doesn't work right and returns nil
	hooksecurefunc(tooltip, "SetVoidItem", function(self, tab, slot)
		if self.isModified then return end
		local link = GetVoidItemInfo(tab, slot)
		if link then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	hooksecurefunc(tooltip, "SetVoidDepositItem", function(self, slot)
		if self.isModified then return end
		local link = GetVoidTransferDepositInfo(slot)
		if link then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	hooksecurefunc(tooltip, "SetVoidWithdrawalItem", function(self, slot)
		if self.isModified then return end
		local link = GetVoidTransferWithdrawalInfo(slot)
		if link then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	hooksecurefunc(tooltip, "SetRecipeReagentItem", function(self, recipeID, reagentIndex)
		if self.isModified then return end
		local link = C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, reagentIndex)
		if link then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	hooksecurefunc(tooltip, "SetRecipeResultItem", function(self, recipeID)
		if self.isModified then return end
		local link = C_TradeSkillUI.GetRecipeItemLink(recipeID)
		if link then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)	
	hooksecurefunc(tooltip, "SetQuestLogItem", function(self, itemType, index)
		if self.isModified then return end
		local link = GetQuestLogItemLink(itemType, index)
		if link then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	hooksecurefunc(tooltip, "SetQuestItem", function(self, itemType, index)
		if self.isModified then return end
		local link = GetQuestItemLink(itemType, index)
		if link then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)	
	--------------------------------------------------
	hooksecurefunc(tooltip, "SetCurrencyToken", function(self, index)
		if self.isModified then return end
		self.isModified = true
		local currencyName = GetCurrencyListInfo(index)
		BSYC:AddCurrencyTooltip(self, currencyName)
	end)
	hooksecurefunc(tooltip, "SetCurrencyByID", function(self, id)
		if self.isModified then return end
		self.isModified = true
		local currencyName = GetCurrencyInfo(id)
		BSYC:AddCurrencyTooltip(self, currencyName)
	end)
	hooksecurefunc(tooltip, "SetBackpackToken", function(self, index)
		if self.isModified then return end
		self.isModified = true
		local currencyName = GetBackpackCurrencyInfo(index)
		BSYC:AddCurrencyTooltip(self, currencyName)
	end)

end

------------------------------
--    SLASH COMMAND         --
------------------------------

function BSYC:ChatCommand(input)

	local parts = { (" "):split(input) }
	local cmd, args = strlower(parts[1] or ""), table.concat(parts, " ", 2)

	if string.len(cmd) > 0 then

		if cmd == L.SlashSearch then
			self:GetModule("Search"):StartSearch()
			return true
		elseif cmd == L.SlashGold then
			self:ShowMoneyTooltip()
			return true
		elseif cmd == L.SlashCurrency then
			self:GetModule("Currency").frame:Show()
			return true
		elseif cmd == L.SlashProfiles then
			self:GetModule("Profiles").frame:Show()
			return true
		elseif cmd == L.SlashProfessions then
			self:GetModule("Professions").frame:Show()
			return true
		elseif cmd == L.SlashBlacklist then
			self:GetModule("Blacklist").frame:Show()
			return true
		elseif cmd == L.SlashFixDB then
			self:FixDB()
			return true
		elseif cmd == L.SlashConfig then
			InterfaceOptionsFrame:Show() --has to be here to load the about frame onLoad
			InterfaceOptionsFrame_OpenToCategory(self.aboutPanel) --force the panel to show
			return true
		else
			--do an item search, use the full command to search
			self:GetModule("Search"):StartSearch(input)
			return true
		end

	end

	self:Print(L.HelpSearchItemName)
	self:Print(L.HelpSearchWindow)
	self:Print(L.HelpGoldTooltip)
	self:Print(L.HelpCurrencyWindow)
	self:Print(L.HelpProfilesWindow)
	self:Print(L.HelpProfessionsWindow)
	self:Print(L.HelpBlacklistWindow)
	self:Print(L.HelpFixDB)
	self:Print(L.HelpConfigWindow )

end

------------------------------
--    KEYBINDING            --
------------------------------

function BagSync_ShowWindow(windowName)
	if windowName == "Search" then
		BSYC:GetModule("Search"):StartSearch()
	elseif windowName == "Gold" then
		BSYC:ShowMoneyTooltip()
	else
		BSYC:GetModule(windowName).frame:Show()
	end
end

------------------------------
--    LOGIN HANDLER         --
------------------------------

function BSYC:OnEnable_Old()
	--NOTE: Using OnEnable() instead of OnInitialize() because not all the SavedVarables fully loaded
	--also one of the major issues is that UnitFullName() will return nil for the short named realm

	--load the keybinding locale information
	BINDING_HEADER_BAGSYNC = "BagSync"
	BINDING_NAME_BAGSYNCBLACKLIST = L.KeybindBlacklist
	BINDING_NAME_BAGSYNCCURRENCY = L.KeybindCurrency
	BINDING_NAME_BAGSYNCGOLD = L.KeybindGold
	BINDING_NAME_BAGSYNCPROFESSIONS = L.KeybindProfessions
	BINDING_NAME_BAGSYNCPROFILES = L.KeybindProfiles
	BINDING_NAME_BAGSYNCSEARCH = L.KeybindSearch

	local ver = GetAddOnMetadata("BagSync","Version") or 0
	
	--initiate the db
	self:StartupDB()
	
	--force token scan
	hooksecurefunc("BackpackTokenFrame_Update", function(self) BSYC:ScanCurrency() end)
	self:ScanCurrency()
	
	--clean up old auctions
	--self:CleanAuctionsDB()
	
	--check for minimap toggle
	if self.db.options.enableMinimap and BagSync_MinimapButton and not BagSync_MinimapButton:IsVisible() then
		BagSync_MinimapButton:Show()
	elseif not self.db.options.enableMinimap and BagSync_MinimapButton and BagSync_MinimapButton:IsVisible() then
		BagSync_MinimapButton:Hide()
	end
	
	--[[ self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	self:RegisterEvent("GUILDBANKFRAME_OPENED")
	self:RegisterEvent("GUILDBANKFRAME_CLOSED")
	self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
	self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
	
	--currency
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

	--this will be used for getting the tradeskill link
	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED") ]]

	--hook the tooltips
	self:HookTooltip(GameTooltip)
	self:HookTooltip(ItemRefTooltip)
	
	--register the slash command
	self:RegisterChatCommand("bgs", "ChatCommand")
	self:RegisterChatCommand("bagsync", "ChatCommand")
	
	if self.db.options.enableLoginVersionInfo then
		self:Print("[v|cFF20ff20"..ver.."|r] /bgs, /bagsync")
	end

end

------------------------------
--      Event Handlers      --
------------------------------

function BSYC:CURRENCY_DISPLAY_UPDATE()
--if C_PetBattles.IsInBattle() then return end
	if self:IsInBG() or self:IsInArena() or InCombatLockdown() or UnitAffectingCombat("player") then return end
	self.doCurrencyUpdate = 0
	self:ScanCurrency()
end

function BSYC:PLAYER_REGEN_ENABLED()
	if self:IsInBG() or self:IsInArena() or InCombatLockdown() or UnitAffectingCombat("player") then return end
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	--were out of an arena or battleground scan the points
	self.doCurrencyUpdate = 0
	self:ScanCurrency()
end

------------------------------
--     PROFESSION           --
------------------------------

function BSYC:doRegularTradeSkill(numIndex, dbPlayer, dbIdx)
	local name, texture, rank, maxRank, numSpells, spelloffset, skillLine, rankModifier, specializationIndex, specializationOffset, skillLineName = GetProfessionInfo(numIndex)
	if name and rank then
		dbPlayer[dbIdx] = dbPlayer[dbIdx] or {}
		dbPlayer[dbIdx].name = name
		dbPlayer[dbIdx].texture = texture
		dbPlayer[dbIdx].rank = rank
		dbPlayer[dbIdx].maxRank = maxRank
		dbPlayer[dbIdx].skillLineName = skillLineName
	end
end

function BSYC:TRADE_SKILL_SHOW()
	--IsTradeSkillLinked() returns true only if trade window was opened from chat link (meaning another player)
	if (not _G.C_TradeSkillUI.IsTradeSkillLinked()) then
		
		local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()
		
		local dbPlayer = self.db.player.profession
		
		--prof1
		if prof1 then
			self:doRegularTradeSkill(prof1, dbPlayer, 1)
		elseif not prof1 and dbPlayer[1] then
			--they removed a profession
			dbPlayer[1] = nil
		end

		--prof2
		if prof2 then
			self:doRegularTradeSkill(prof2, dbPlayer, 2)
		elseif not prof2 and dbPlayer[2] then
			--they removed a profession
			dbPlayer[2] = nil
		end
		
		--archaeology
		if archaeology then
			self:doRegularTradeSkill(archaeology, dbPlayer, 3)
		elseif not archaeology and dbPlayer[3] then
			--they removed a profession
			dbPlayer[3] = nil
		end
		
		--fishing
		if fishing then
			self:doRegularTradeSkill(fishing, dbPlayer, 4)
		elseif not fishing and dbPlayer[4] then
			--they removed a profession
			dbPlayer[4] = nil
		end
		
		--cooking
		if cooking then
			self:doRegularTradeSkill(cooking, dbPlayer, 5)
		elseif not cooking and dbPlayer[5] then
			--they removed a profession
			dbPlayer[5] = nil
		end
		
		--firstAid
		if firstAid then
			self:doRegularTradeSkill(firstAid, dbPlayer, 6)
		elseif not firstAid and dbPlayer[6] then
			--they removed a profession
			dbPlayer[6] = nil
		end
	end
	
	--grab the player recipes but only scan once, TRADE_SKILL_LIST_UPDATE is triggered multiple times for some reason
	self:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
end

--this function pretty much only grabs the recipelist for the CURRENT opened profession, not all the profession info which TRADE_SKILL_SHOW does.
--this is because you can't open up herbalism, mining, etc...
function BSYC:TRADE_SKILL_LIST_UPDATE()

	if (not _G.C_TradeSkillUI.IsTradeSkillLinked()) then
	
		local getIndex = 0
		local getProfIndex = 0
		local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()
		--Blizzard_APIDocumentation/TradeSkillUIDocumentation.lua
		local tradeSkillID, skillLineName, skillLineRank, skillLineMaxRank, skillLineModifier, parentSkillLineID, parentSkillLineName = _G.C_TradeSkillUI.GetTradeSkillLine()
		
		if not parentSkillLineName then return end --don't do anything if no tradeskill name
		
		--prof1
		if prof1 and GetProfessionInfo(prof1) == parentSkillLineName then
			getIndex = 1
			getProfIndex = prof1
		elseif prof2 and GetProfessionInfo(prof2) == parentSkillLineName then
			getIndex = 2
			getProfIndex = prof2
		elseif archaeology and GetProfessionInfo(archaeology) == parentSkillLineName then
			getIndex = 3
			getProfIndex = archaeology
		elseif fishing and GetProfessionInfo(fishing) == parentSkillLineName then
			getIndex = 4
			getProfIndex = fishing
		elseif cooking and GetProfessionInfo(cooking) == parentSkillLineName then
			getIndex = 5
			getProfIndex = cooking
		elseif firstAid and GetProfessionInfo(firstAid) == parentSkillLineName then
			getIndex = 6
			getProfIndex = firstAid
		end
		
		--don't do anything if we have nothing to work with
		if getIndex < 1 then return end
		
		local name, texture, rank, maxRank, numSpells, spelloffset, skillLine, rankModifier, specializationIndex, specializationOffset, skillLineName = GetProfessionInfo(getProfIndex)
		
		local recipeString = ""
		local recipeIDs = _G.C_TradeSkillUI.GetAllRecipeIDs()
		local recipeInfo = {}

		for idx = 1, #recipeIDs do
			recipeInfo = _G.C_TradeSkillUI.GetRecipeInfo(recipeIDs[idx])
			
			if recipeInfo and recipeInfo.learned then
				recipeString = recipeString.."|"..recipeInfo.recipeID
			end
		end

		--only record if we have something to work with
		if name and rank and string.len(recipeString) > 0 then
			recipeString = strsub(recipeString, string.len("|") + 1) --remove the delimiter in front of recipeID list
			self.db.player.profession[getIndex] = self.db.player.profession[getIndex] or {}
			self.db.player.profession[getIndex].recipes = recipeString
		end
		
	end
	
	--unregister for next time the tradeskill window is opened
	self:UnregisterEvent("TRADE_SKILL_LIST_UPDATE")
end

--if they have the tradeskill window opened and then click on another professions it keeps the window opened and thus TRADE_SKILL_LIST_UPDATE never gets fired
function BSYC:TRADE_SKILL_DATA_SOURCE_CHANGED()
	self:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
end
