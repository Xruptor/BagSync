--[[
	BagSync.lua
		A item tracking addon similar to Bagnon_Forever (special thanks to Tuller).
		Works with practically any Bag mod available, Bagnon not required.

	NOTE: Parts of this mod were inspired by code from Bagnon_Forever by Tuller.
	
	This project was originally done a long time ago when I used the default blizzard bags.  I wanted something like what
	was available in Bagnon for tracking items, but I didn't want to use Bagnon.  So I decided to code one that works with
	pretty much any inventory addon.
	
	It was intended to be a beta addon as I never really uploaded it to a interface website.  Instead I used the
	SVN of wowace to work on it.  The last revision done on the old BagSync was r50203.11 (29 Sep 2007).
	Note: This addon has been completely rewritten. 

	Author: Xruptor

--]]

local L = BAGSYNC_L
local lastItem
local lastDisplayed = {}
local currentPlayer
local currentRealm
local playerClass
local playerFaction
local NUM_EQUIPMENT_SLOTS = 19
local BS_DB
local BS_GD
local BS_TD
local BS_CD
local BS_BL
local MAX_GUILDBANK_SLOTS_PER_TAB = 98
local doTokenUpdate = 0
local guildTabQueryQueue = {}
local atBank = false
local atVoidBank = false
local atGuildBank = false
local isCheckingMail = false

local SILVER = '|cffc7c7cf%s|r'
local MOSS = '|cFF80FF00%s|r'
local TTL_C = '|cFFF4A460%s|r'
local GN_C = '|cFF65B8C0%s|r'

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

------------------------------
--    LibDataBroker-1.1	    --
------------------------------

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")

local dataobj = ldb:NewDataObject("BagSyncLDB", {
	type = "data source",
	--icon = "Interface\\Icons\\INV_Misc_Bag_12",
	icon = "Interface\\AddOns\\BagSync\\media\\icon",
	label = "BagSync",
	text = "BagSync",
		
	OnClick = function(self, button)
		if button == 'LeftButton' and BagSync_SearchFrame then
			if BagSync_SearchFrame:IsVisible() then
				BagSync_SearchFrame:Hide()
			else
				BagSync_SearchFrame:Show()
			end
		elseif button == 'RightButton' and BagSync_TokensFrame then
			if bgsMinimapDD then
				ToggleDropDownMenu(1, nil, bgsMinimapDD, 'cursor', 0, 0)
			end
		end
	end,

	OnTooltipShow = function(self)
		self:AddLine("BagSync")
		self:AddLine(L["Left Click = Search Window"])
		self:AddLine(L["Right Click = BagSync Menu"])
	end
})

------------------------------
--        MAIN OBJ	        --
------------------------------

local BagSync = CreateFrame("Frame", "BagSync", UIParent)

BagSync:SetScript('OnEvent', function(self, event, ...)
	if self[event] then
		self[event](self, event, ...)
	end
end)

if IsLoggedIn() then BagSync:PLAYER_LOGIN() else BagSync:RegisterEvent('PLAYER_LOGIN') end

----------------------
--   DB Functions   --
----------------------

local function StartupDB()

	BagSyncOpt = BagSyncOpt or {}
	if BagSyncOpt.showTotal == nil then BagSyncOpt.showTotal = true end
	if BagSyncOpt.showGuildNames == nil then BagSyncOpt.showGuildNames = false end
	if BagSyncOpt.enableGuild == nil then BagSyncOpt.enableGuild = true end
	if BagSyncOpt.enableMailbox == nil then BagSyncOpt.enableMailbox = true end
	if BagSyncOpt.enableUnitClass == nil then BagSyncOpt.enableUnitClass = false end
	if BagSyncOpt.enableMinimap == nil then BagSyncOpt.enableMinimap = true end
	if BagSyncOpt.enableFaction == nil then BagSyncOpt.enableFaction = true end
	if BagSyncOpt.enableAuction == nil then BagSyncOpt.enableAuction = true end
	if BagSyncOpt.tooltipOnlySearch == nil then BagSyncOpt.tooltipOnlySearch = false end
	if BagSyncOpt.enableTooltips == nil then BagSyncOpt.enableTooltips = true end
	if BagSyncOpt.enableTooltipSeperator == nil then BagSyncOpt.enableTooltipSeperator = true end
	
	--new format, get rid of old
	if not BagSyncOpt.dbversion or not tonumber(BagSyncOpt.dbversion) or tonumber(BagSyncOpt.dbversion) < 7 then
		BagSyncDB = {}
		BagSyncGUILD_DB = {}
		print("|cFFFF0000BagSync: You have been updated to latest database version!  You will need to rescan all your characters again!|r")
	end
	
	BagSyncDB = BagSyncDB or {}
	BagSyncDB[currentRealm] = BagSyncDB[currentRealm] or {}
	BagSyncDB[currentRealm][currentPlayer] = BagSyncDB[currentRealm][currentPlayer] or {}
	BS_DB = BagSyncDB[currentRealm][currentPlayer]
	
	BagSyncGUILD_DB = BagSyncGUILD_DB or {}
	BagSyncGUILD_DB[currentRealm] = BagSyncGUILD_DB[currentRealm] or {}
	BS_GD = BagSyncGUILD_DB[currentRealm]

	BagSyncTOKEN_DB = BagSyncTOKEN_DB or {}
	BagSyncTOKEN_DB[currentRealm] = BagSyncTOKEN_DB[currentRealm] or {}
	BS_TD = BagSyncTOKEN_DB[currentRealm]
	
	BagSyncCRAFT_DB = BagSyncCRAFT_DB or {}
	BagSyncCRAFT_DB[currentRealm] = BagSyncCRAFT_DB[currentRealm] or {}
	BagSyncCRAFT_DB[currentRealm][currentPlayer] = BagSyncCRAFT_DB[currentRealm][currentPlayer] or {}
	BS_CD = BagSyncCRAFT_DB[currentRealm][currentPlayer]
	
	BagSyncBLACKLIST_DB = BagSyncBLACKLIST_DB or {}
	BagSyncBLACKLIST_DB[currentRealm] = BagSyncBLACKLIST_DB[currentRealm] or {}
	BS_BL = BagSyncBLACKLIST_DB[currentRealm]
	
end

function BagSync:FixDB_Data(onlyChkGuild)
	--Removes obsolete character information
	--Removes obsolete guild information
	--Removes obsolete characters from tokens db
	--Removes obsolete profession information
	--Will only check guild related information if the paramater is passed as true

	local storeUsers = {}
	local storeGuilds = {}
	
	for realm, rd in pairs(BagSyncDB) do
		--realm
		storeUsers[realm] = storeUsers[realm] or {}
		storeGuilds[realm] = storeGuilds[realm] or {}
		for k, v in pairs(rd) do
			--users
			storeUsers[realm][k] = storeUsers[realm][k] or 1
			for q, r in pairs(v) do
				if q == 'guild' then
					storeGuilds[realm][r] = true
				end
			end
		end
	end

	--guildbank data
	for realm, rd in pairs(BagSyncGUILD_DB) do
		--realm
		for k, v in pairs(rd) do
			--users
			if not storeGuilds[realm][k] then
				--delete the guild because no one has it
				BagSyncGUILD_DB[realm][k] = nil
			end
		end
	end
	
	--token data and profession data, only do if were not doing a guild check
	--also display fixdb message only if were not doing a guild check
	if not onlyChkGuild then
	
		--fix tokens
		for realm, rd in pairs(BagSyncTOKEN_DB) do
			--realm
			if not storeUsers[realm] then
				--if it's not a realm that ANY users are on then delete it
				BagSyncTOKEN_DB[realm] = nil
			else
				--delete old db information for tokens if it exists
				if BagSyncTOKEN_DB[realm] and BagSyncTOKEN_DB[realm][1] then BagSyncTOKEN_DB[realm][1] = nil end
				if BagSyncTOKEN_DB[realm] and BagSyncTOKEN_DB[realm][2] then BagSyncTOKEN_DB[realm][2] = nil end
				
				for k, v in pairs(rd) do
					for x, y in pairs(v) do
						if x ~= "icon" and x ~= "header" then
							if not storeUsers[realm][x] then
								--if the user doesn't exist then delete data
								BagSyncTOKEN_DB[realm][k][x] = nil
							end
						end
					end
				end
			end
		end
		
		--fix professions
		for realm, rd in pairs(BagSyncCRAFT_DB) do
			--realm
			if not storeUsers[realm] then
				--if it's not a realm that ANY users are on then delete it
				BagSyncCRAFT_DB[realm] = nil
			else
				for k, v in pairs(rd) do
					if not storeUsers[realm][k] then
						--if the user doesn't exist then delete data
						BagSyncCRAFT_DB[realm][k] = nil
					end
				end
			end
		end

		DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33BagSync:|r |cFFFF9900"..L["A FixDB has been performed on BagSync!  The database is now optimized!"].."|r")
	end
end

----------------------
--      Local       --
----------------------

local function doRegularTradeSkill(numIndex, dbIdx)
	local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier = GetProfessionInfo(numIndex)
	if name and skillLevel then
		BS_CD[dbIdx] = format('%s,%s', name, skillLevel)
	end
end

local function ToShortLink(link)
	if not link then return nil end
	return link:match("item:(%d+):") or nil
end

----------------------
--  Bag Functions   --
----------------------

local function SaveBag(bagname, bagid)
	if not bagname or not bagid then return nil end
	if not BS_DB then StartupDB() end
	BS_DB[bagname] = BS_DB[bagname] or {}

	if GetContainerNumSlots(bagid) > 0 then
		local slotItems = {}
		for slot = 1, GetContainerNumSlots(bagid) do
			local _, count, _,_,_,_, link = GetContainerItemInfo(bagid, slot)
			if ToShortLink(link) then
				count = (count > 1 and count) or nil
				if count then
					slotItems[slot] = format('%s,%d', ToShortLink(link), count)
				else
					slotItems[slot] = ToShortLink(link)
				end
			end
		end
		BS_DB[bagname][bagid] = slotItems
	else
		BS_DB[bagname][bagid] = nil
	end
end

local function SaveEquipment()

	--reset our tooltip data since we scanned new items (we want current data not old)
	lastItem = nil
	lastDisplayed = {}
	
	if not BS_DB then StartupDB() end
	BS_DB['equip'] = BS_DB['equip'] or {}

	local slotItems = {}
	--start at 1, 0 used to be the old range slot (not needed anymore)
	for slot = 1, NUM_EQUIPMENT_SLOTS do
		local link = GetInventoryItemLink('player', slot)
		if link and ToShortLink(link) then
			local count =  GetInventoryItemCount('player', slot)
			count = (count and count > 1) or nil
			if count then
				slotItems[slot] = format('%s,%d', ToShortLink(link), count)
			else
				slotItems[slot] = ToShortLink(link)
			end
		end
	end
	BS_DB['equip'][0] = slotItems
end

local function ScanEntireBank()
	--force scan of bank bag -1, since blizzard never sends updates for it
	SaveBag('bank', BANK_CONTAINER)
	for i = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
		SaveBag('bank', i)
	end
end

local function ScanVoidBank()
	if VoidStorageFrame and VoidStorageFrame:IsShown() then
		if not BS_DB then StartupDB() end
		BS_DB['void'] = BS_DB['void'] or {}
		
		local slotItems = {}
		for i = 1, 80 do
			itemID, textureName, locked, recentDeposit, isFiltered = GetVoidItemInfo(i)
			if (itemID) then
				slotItems[i] = itemID and tostring(itemID) or nil
			end
		end
		
		BS_DB['void'][0] = slotItems
	end
end

local function ScanGuildBank()

	--GetCurrentGuildBankTab()
	if not IsInGuild() then return end
	
	if not BS_GD then StartupDB() end
	BS_GD[BS_DB.guild] = BS_GD[BS_DB.guild] or {}

	local numTabs = GetNumGuildBankTabs()
	local index = 0
	local slotItems = {}
	
	for tab = 1, numTabs do
		local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals = GetGuildBankTabInfo(tab)
		--if we don't check for isViewable we get a weirdo permissions error for the player when they attempt it
		if isViewable then
			for slot = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
			
				local link = GetGuildBankItemLink(tab, slot)

				if link and ToShortLink(link) then
					index = index + 1
					local _, count = GetGuildBankItemInfo(tab, slot)
					count = (count > 1 and count) or nil
					
					if count then
						slotItems[index] = format('%s,%d', ToShortLink(link), count)
					else
						slotItems[index] = ToShortLink(link)
					end
				end
			end
		end
	end
	
	BS_GD[BS_DB.guild] = slotItems
	
end

local function ScanMailbox()
	--this is to prevent buffer overflow from the CheckInbox() function calling ScanMailbox too much :)
	if isCheckingMail then return end
	isCheckingMail = true

	 --used to initiate mail check from server, for some reason GetInboxNumItems() returns zero sometimes
	 --even though the user has mail in the mailbox.  This can be attributed to lag.
	CheckInbox()

	if not BS_DB then StartupDB() end
	BS_DB['mailbox'] = BS_DB['mailbox'] or {}
	
	local slotItems = {}
	local mailCount = 0
	local numInbox = GetInboxNumItems()

	--scan the inbox
	if (numInbox > 0) then
		for mailIndex = 1, numInbox do
			for i=1, ATTACHMENTS_MAX_RECEIVE do
				local name, itemTexture, count, quality, canUse = GetInboxItem(mailIndex, i)
				local link = GetInboxItemLink(mailIndex, i)
				
				if name and link and ToShortLink(link) then
					mailCount = mailCount + 1
					count = (count > 1 and count) or nil
					if count then
						slotItems[mailCount] = format('%s,%d', ToShortLink(link), count)
					else
						slotItems[mailCount] = ToShortLink(link)
					end
				end
			end
		end
	end
	
	BS_DB['mailbox'][0] = slotItems
	isCheckingMail = false
end

local function ScanAuctionHouse()
	if not BS_DB then StartupDB() end
	BS_DB['auction'] = BS_DB['auction'] or {}
	
	local slotItems = {}
	local ahCount = 0
	local numActiveAuctions = GetNumAuctionItems("owner")
	
	--scan the auction house
	if (numActiveAuctions > 0) then
		for ahIndex = 1, numActiveAuctions do
			local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner, saleStatus  = GetAuctionItemInfo("owner", ahIndex)
			if name then
				local link = GetAuctionItemLink("owner", ahIndex)
				local timeLeft = GetAuctionItemTimeLeft("owner", ahIndex)
				if link and ToShortLink(link) and timeLeft then
					ahCount = ahCount + 1
					count = (count or 1)
					slotItems[ahCount] = format('%s,%s,%s', ToShortLink(link), count, timeLeft)
				end
			end
		end
	end
	
	BS_DB['auction'][0] = slotItems
	BS_DB.AH_Count = ahCount
end

--this method is global for all toons, removes expired auctions on login
local function RemoveExpiredAuctions()
	local timestampChk = { 30*60, 2*60*60, 12*60*60, 48*60*60 }
				
	for realm, rd in pairs(BagSyncDB) do
		--realm
		for k, v in pairs(rd) do
			--users k=name, v=values
			if BagSyncDB[realm][k].AH_LastScan and BagSyncDB[realm][k].AH_Count then --only proceed if we have an auction house time to work with
				--check to see if we even have something to work with
				if BagSyncDB[realm][k]['auction'] then
					--we do so lets do a loop
					local bVal = BagSyncDB[realm][k].AH_Count
					--do a loop through all of them and check to see if any expired
					for x = 1, bVal do
						if BagSyncDB[realm][k]['auction'][0][x] then
							--check for expired and remove if necessary
							--it's okay if the auction count is showing more then actually stored, it's just used as a means
							--to scan through all our items.  Even if we have only 3 and the count is 6 it will just skip the last 3.
							local dblink, dbcount, dbtimeleft = strsplit(',', BagSyncDB[realm][k]['auction'][0][x])
							
							--only proceed if we have everything to work with, otherwise this auction data is corrupt
							if dblink and dbcount and dbtimeleft then
								if tonumber(dbtimeleft) < 1 or tonumber(dbtimeleft) > 4 then dbtimeleft = 4 end --just in case
								--now do the time checks
								local diff = time() - BagSyncDB[realm][k].AH_LastScan 
								if diff > timestampChk[tonumber(dbtimeleft)] then
									--technically this isn't very realiable.  but I suppose it's better the  nothing
									BagSyncDB[realm][k]['auction'][0][x] = nil
								end
							else
								--it's corrupt delete it
								BagSyncDB[realm][k]['auction'][0][x] = nil
							end
						end
					end
				end
			end
		end
	end
	
end

------------------------
--   Money Tooltip    --
------------------------

local function buildMoneyString(money, color)
 
	local iconSize = 14
	local goldicon = string.format("\124TInterface\\MoneyFrame\\UI-GoldIcon:%d:%d:1:0\124t ", iconSize, iconSize)
	local silvericon = string.format("\124TInterface\\MoneyFrame\\UI-SilverIcon:%d:%d:1:0\124t ", iconSize, iconSize)
	local coppericon = string.format("\124TInterface\\MoneyFrame\\UI-CopperIcon:%d:%d:1:0\124t ", iconSize, iconSize)
	local moneystring
	local g,s,c
	local neg = false
  
	if(money <0) then 
		neg = true
		money = money * -1
	end
	
	g=floor(money/10000)
	s=floor((money-(g*10000))/100)
	c=money-s*100-g*10000
	moneystring = g..goldicon..s..silvericon..c..coppericon
	
	if(neg) then
		moneystring = "-"..moneystring
	end
	
	if(color) then
		if(neg) then
			moneystring = "|cffff0000"..moneystring.."|r"
		elseif(money ~= 0) then
			moneystring = "|cff44dd44"..moneystring.."|r"
		end
	end
	
	return moneystring
end

function BagSync:ShowMoneyTooltip()
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
	
	tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	tooltip:ClearLines()
	tooltip:ClearAllPoints()
	tooltip:SetPoint("CENTER",UIParent,"CENTER",0,0)

	tooltip:AddLine("BagSync")
	tooltip:AddLine(" ")
	
	--loop through our characters
	for k, v in pairs(BagSyncDB[currentRealm]) do
		if BagSyncDB[currentRealm][k].gold then
			table.insert(usrData, { name=k, gold=BagSyncDB[currentRealm][k].gold } )
		end
	end
	table.sort(usrData, function(a,b) return (a.name < b.name) end)
	
	local gldTotal = 0
	
	for i=1, table.getn(usrData) do
		tooltip:AddDoubleLine(usrData[i].name, buildMoneyString(usrData[i].gold, false), 1, 1, 1, 1, 1, 1)
		gldTotal = gldTotal + usrData[i].gold
	end
	if BagSyncOpt.showTotal and gldTotal > 0 then
		tooltip:AddLine(" ")
		tooltip:AddDoubleLine(format(TTL_C, L["Total:"]), buildMoneyString(gldTotal, false), 1, 1, 1, 1, 1, 1)
	end
	
	tooltip:AddLine(" ")
	tooltip:Show()
end

------------------------
--      Tokens        --
------------------------

local function IsInBG()
	if (GetNumBattlefieldScores() > 0) then
		return true
	end
	local status, mapName, instanceID, minlevel, maxlevel
	for i=1, GetMaxBattlefieldID() do
		status, mapName, instanceID, minlevel, maxlevel, teamSize = GetBattlefieldStatus(i)
		if status == "active" then
			return true
		end
	end
	return false
end

local function IsInArena()
	local a,b = IsActiveBattlefieldArena()
	if (a == nil) then
		return false
	end
	return true
end

local function ScanTokens()
	--LETS AVOID TOKEN SPAM AS MUCH AS POSSIBLE
	if doTokenUpdate == 1 then return end
	if IsInBG() or IsInArena() or InCombatLockdown() or UnitAffectingCombat("player") then
		--avoid (Honor point spam), avoid (arena point spam), if it's world PVP...well then it sucks to be you
		doTokenUpdate = 1
		BagSync:RegisterEvent('PLAYER_REGEN_ENABLED')
		return
	end

	local lastHeader
	
	for i=1, GetCurrencyListSize() do
		local name, isHeader, isExpanded, _, _, count, icon = GetCurrencyListInfo(i)
		--extraCurrencyType = 1 for arena points, 2 for honor points; 0 otherwise (an item-based currency).

		if name then
			if(isHeader and not isExpanded) then
				ExpandCurrencyList(i,1)
				lastHeader = name
			elseif isHeader then
				lastHeader = name
			end
			if (not isHeader) then
				if BS_TD then
					BS_TD = BS_TD or {}
					BS_TD[name] = BS_TD[name] or {}
					BS_TD[name].icon = icon
					BS_TD[name].header = lastHeader
					BS_TD[name][currentPlayer] = count
				end
			end
		end
	end
	--we don't want to overwrite tokens, because some characters may have currency that the others dont have
end

hooksecurefunc("BackpackTokenFrame_Update", ScanTokens)

------------------------
--      Tooltip!      --
-- (Special thanks to tuller)
------------------------

--a function call to reset these local variables outside the scope ;)
function BagSync:resetTooltip()
	lastDisplayed = {}
	lastItem = nil
end

local function CountsToInfoString(countTable)
	local info
	local total = 0
	
	if countTable['bag'] > 0 then
		info = L["Bags: %d"]:format(countTable['bag'])
		total = total + countTable['bag']
	end

	if countTable['bank'] > 0 then
		local count = L["Bank: %d"]:format(countTable['bank'])
		if info then
			info = strjoin(', ', info, count)
		else
			info = count
		end
		total = total + countTable['bank']
	end

	if countTable['equip'] > 0 then
		local count = L["Equipped: %d"]:format(countTable['equip'])
		if info then
			info = strjoin(', ', info, count)
		else
			info = count
		end
		total = total + countTable['equip']
	end

	if countTable['guild'] > 0 and BagSyncOpt.enableGuild and not BagSyncOpt.showGuildNames then
		local count = L["Guild: %d"]:format(countTable['guild'])
		if info then
			info = strjoin(', ', info, count)
		else
			info = count
		end
		total = total + countTable['guild'] --add the guild count only if we don't have showguildnames on, otherwise it's counted twice
	end
	
	if countTable['mailbox'] > 0 and BagSyncOpt.enableMailbox then
		local count = L["Mailbox: %d"]:format(countTable['mailbox'])
		if info then
			info = strjoin(', ', info, count)
		else
			info = count
		end
		total = total + countTable['mailbox']
	end
	
	if countTable['void'] > 0 then
		local count = L["Void: %d"]:format(countTable['void'])
		if info then
			info = strjoin(', ', info, count)
		else
			info = count
		end
		total = total + countTable['void']
	end
	
	if countTable['auction'] > 0 and BagSyncOpt.enableAuction then
		local count = L["AH: %d"]:format(countTable['auction'])
		if info then
			info = strjoin(', ', info, count)
		else
			info = count
		end
		total = total + countTable['auction']
	end
	
	if info and info ~= "" then
		--check to see if we show multiple items or just a single one per character
		local totalPass = false
		for q, v in pairs(countTable) do
			if v == total then
				totalPass = true
				break
			end
		end
		
		if not totalPass then
			local totalStr = format(MOSS, total)
			return totalStr .. format(SILVER, format(' (%s)', info))
		else
			return format(MOSS, info)
		end
	end
end

--sort by key element rather then value
local function pairsByKeys (t, f)
	local a = {}
		for n in pairs(t) do table.insert(a, n) end
		table.sort(a, f)
		local i = 0      -- iterator variable
		local iter = function ()   -- iterator function
			i = i + 1
			if a[i] == nil then return nil
			else return a[i], t[a[i]]
			end
		end
	return iter
end

local function rgbhex(r, g, b)
  if type(r) == "table" then
	if r.r then
	  r, g, b = r.r, r.g, r.b
	else
	  r, g, b = unpack(r)
	end
  end
  return string.format("|cff%02x%02x%02x", (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
end

local function getNameColor(sName, sClass)
	if not BagSyncOpt.enableUnitClass then
		return format(MOSS, sName)
	else
		if sName ~= "Unknown" and sClass and RAID_CLASS_COLORS[sClass] then
			return rgbhex(RAID_CLASS_COLORS[sClass])..sName.."|r"
		end
	end
	return format(MOSS, sName)
end

local function AddToTooltip(frame, link)
	--if we can't convert the item link then lets just ignore it altogether
	local itemLink = ToShortLink(link)
	if not itemLink then
		frame:Show()
		return
	end
	
	--only show tooltips in search frame if the option is enabled
	if BagSyncOpt.tooltipOnlySearch and frame:GetOwner() and frame:GetOwner():GetName() and string.sub(frame:GetOwner():GetName(), 1, 16) ~= "BagSyncSearchRow" then
		frame:Show()
		return
	end
	
	--ignore the hearthstone and blacklisted items
	if itemLink and tonumber(itemLink) and (tonumber(itemLink) == 6948 or BS_BL[tonumber(itemLink)]) then
		frame:Show()
		return
	end

	--lag check (check for previously displayed data) if so then display it
	if lastItem and itemLink and itemLink == lastItem then
		for i = 1, #lastDisplayed do
			local ename, ecount  = strsplit('@', lastDisplayed[i])
			if ename and ecount then
				frame:AddDoubleLine(ename, ecount)
			end
		end
		frame:Show()
		return
	end

	--reset our last displayed
	lastDisplayed = {}
	lastItem = itemLink
	
	--this is so we don't scan the same guild multiple times
	local previousGuilds = {}
	local grandTotal = 0
	
	--check for seperator
	if BagSyncOpt.enableTooltipSeperator then
		frame:AddDoubleLine(" ", " ")
		table.insert(lastDisplayed, " @ ")
	end

	--loop through our characters
	--k = player, v = stored data for player
	for k, v in pairs(BagSyncDB[currentRealm]) do

		local allowList = {
			["bag"] = 0,
			["bank"] = 0,
			["equip"] = 0,
			["mailbox"] = 0,
			["void"] = 0,
			["auction"] = 0,
			["guild"] = 0,
		}
	
		local infoString
		local invCount, bankCount, equipCount, guildCount, mailboxCount, voidbankCount, auctionCount = 0, 0, 0, 0, 0, 0, 0
		local pFaction = v.faction or playerFaction --just in case ;) if we dont know the faction yet display it anyways
		
		--check if we should show both factions or not
		if BagSyncOpt.enableFaction or pFaction == playerFaction then

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
								local dblink, dbcount = strsplit(',', itemValue)
								if dblink and dblink == itemLink then
									allowList[q] = allowList[q] + (dbcount or 1)
									grandTotal = grandTotal + (dbcount or 1)
								end
							end
						end
					end
				end
			end
		
			if BagSyncOpt.enableGuild then
				local guildN = v.guild or nil
			
				--check the guild bank if the character is in a guild
				if BS_GD and guildN and BS_GD[guildN] then
					--check to see if this guild has already been done through this run (so we don't do it multiple times)
					if not previousGuilds[guildN] then
						--we only really need to see this information once per guild
						local tmpCount = 0
						for q, r in pairs(BS_GD[guildN]) do
							local dblink, dbcount = strsplit(',', r)
							if dblink and dblink == itemLink then
								allowList["guild"] = allowList["guild"] + (dbcount or 1)
								tmpCount = tmpCount + (dbcount or 1)
								grandTotal = grandTotal + (dbcount or 1)
							end
						end
						previousGuilds[guildN] = tmpCount
					end
				end
			end
			
			--get class for the unit if there is one
			local pClass = v.class or nil
			infoString = CountsToInfoString(allowList)

			if infoString and infoString ~= '' then
				frame:AddDoubleLine(getNameColor(k, pClass), infoString)
				table.insert(lastDisplayed, getNameColor(k or 'Unknown', pClass).."@"..(infoString or 'unknown'))
			end
			
		end
		
	end
	
	--show guildnames last
	if BagSyncOpt.enableGuild and BagSyncOpt.showGuildNames then
		for k, v in pairsByKeys(previousGuilds) do
			--only print stuff higher then zero
			if v > 0 then
				frame:AddDoubleLine(format(GN_C, k), format(SILVER, v))
				table.insert(lastDisplayed, format(GN_C, k).."@"..format(SILVER, v))
			end
		end
	end
	
	--show grand total if we have something
	--don't show total if there is only one item
	if BagSyncOpt.showTotal and grandTotal > 0 and getn(lastDisplayed) > 1 then
		frame:AddDoubleLine(format(TTL_C, L["Total:"]), format(SILVER, grandTotal))
		table.insert(lastDisplayed, format(TTL_C, L["Total:"]).."@"..format(SILVER, grandTotal))
	end
	
	frame:Show()
end

--simplified tooltip function, similar to the past HookTip that was used before Jan 06, 2011 (commit:a89046f844e24585ab8db60d10f2f168498b9af4)
--Honestly we aren't going to care about throttleing or anything like that anymore.  The lastdisplay array token should take care of that
--Special thanks to Tuller for tooltip hook function
local function hookTip(tooltip)
	local modified = false
	tooltip:HookScript('OnTooltipCleared', function(self)
		modified = false
	end)
	tooltip:HookScript('OnTooltipSetItem', function(self)
		if not modified and BagSyncOpt.enableTooltips then
			modified = true
			
			local name, link = self:GetItem()
			if link and GetItemInfo(link) then
				AddToTooltip(self, link)
			end
		end
	end)
end

hookTip(GameTooltip)
hookTip(ItemRefTooltip)

------------------------------
--    LOGIN HANDLER         --
------------------------------

function BagSync:PLAYER_LOGIN()
	
	BINDING_HEADER_BAGSYNC = "BagSync"
	BINDING_NAME_BAGSYNCTOGGLESEARCH = L["Toggle Search"]
	BINDING_NAME_BAGSYNCTOGGLETOKENS = L["Toggle Tokens"]
	BINDING_NAME_BAGSYNCTOGGLEPROFILES = L["Toggle Profiles"]
	BINDING_NAME_BAGSYNCTOGGLECRAFTS = L["Toggle Professions"]
	BINDING_NAME_BAGSYNCTOGGLEBLACKLIST = L["Toggle Blacklist"]
	
	local ver = GetAddOnMetadata("BagSync","Version") or 0
	
	--load our player info after login
	currentPlayer = UnitName('player')
	currentRealm = GetRealmName()
	playerClass = select(2, UnitClass("player"))
	playerFaction = UnitFactionGroup("player")

	--initiate the db
	StartupDB()
	
	--do DB cleanup check by version number
	if not BagSyncOpt.dbversion or BagSyncOpt.dbversion ~= ver then	
		self:FixDB_Data()
		BagSyncOpt.dbversion = ver
	end
	
	--save the current user money (before bag update)
	BS_DB.gold = GetMoney()

	--save the class information
	BS_DB.class = playerClass

	--save the faction information
	--"Alliance", "Horde" or nil
	BS_DB.faction = playerFaction
	
	--check for player not in guild
	if IsInGuild() or GetNumGuildMembers(true) > 0 then
		GuildRoster()
	elseif BS_DB.guild then
		BS_DB.guild = nil
		self:FixDB_Data(true)
	end
	
	--save all inventory data, including backpack(0)
	for i = BACKPACK_CONTAINER, BACKPACK_CONTAINER + NUM_BAG_SLOTS do
		SaveBag('bag', i)
	end

	--force an equipment scan
	SaveEquipment()
	
	--force token scan
	ScanTokens()
	
	--clean up old auctions
	RemoveExpiredAuctions()
	
	--check for minimap toggle
	if BagSyncOpt.enableMinimap and BagSync_MinimapButton and not BagSync_MinimapButton:IsVisible() then
		BagSync_MinimapButton:Show()
	elseif not BagSyncOpt.enableMinimap and BagSync_MinimapButton and BagSync_MinimapButton:IsVisible() then
		BagSync_MinimapButton:Hide()
	end
				
	self:RegisterEvent('PLAYER_MONEY')
	self:RegisterEvent('BANKFRAME_OPENED')
	self:RegisterEvent('BANKFRAME_CLOSED')
	self:RegisterEvent('GUILDBANKFRAME_OPENED')
	self:RegisterEvent('GUILDBANKFRAME_CLOSED')
	self:RegisterEvent('GUILDBANKBAGSLOTS_CHANGED')
	self:RegisterEvent('BAG_UPDATE')
	self:RegisterEvent('UNIT_INVENTORY_CHANGED')
	self:RegisterEvent('GUILD_ROSTER_UPDATE')
	self:RegisterEvent('MAIL_SHOW')
	self:RegisterEvent('MAIL_INBOX_UPDATE')
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
	
	--void storage
	self:RegisterEvent('VOID_STORAGE_OPEN')
	self:RegisterEvent('VOID_STORAGE_CLOSE')
	self:RegisterEvent("VOID_STORAGE_UPDATE")
	self:RegisterEvent("VOID_STORAGE_CONTENTS_UPDATE")
	self:RegisterEvent("VOID_TRANSFER_DONE")
	
	--this will be used for getting the tradeskill link
	self:RegisterEvent("TRADE_SKILL_SHOW")

	SLASH_BAGSYNC1 = "/bagsync"
	SLASH_BAGSYNC2 = "/bgs"
	SlashCmdList["BAGSYNC"] = function(msg)
	
		local a,b,c=strfind(msg, "(%S+)"); --contiguous string of non-space characters
		
		if a then
			if c and c:lower() == L["search"] then
				if BagSync_SearchFrame:IsVisible() then
					BagSync_SearchFrame:Hide()
				else
					BagSync_SearchFrame:Show()
				end
				return true
			elseif c and c:lower() == L["gold"] then
				self:ShowMoneyTooltip()
				return true
			elseif c and c:lower() == L["tokens"] then
				if BagSync_TokensFrame:IsVisible() then
					BagSync_TokensFrame:Hide()
				else
					BagSync_TokensFrame:Show()
				end
				return true
			elseif c and c:lower() == L["profiles"] then
				if BagSync_ProfilesFrame:IsVisible() then
					BagSync_ProfilesFrame:Hide()
				else
					BagSync_ProfilesFrame:Show()
				end
				return true
			elseif c and c:lower() == L["professions"] then
				if BagSync_CraftsFrame:IsVisible() then
					BagSync_CraftsFrame:Hide()
				else
					BagSync_CraftsFrame:Show()
				end
				return true
			elseif c and c:lower() == L["blacklist"] then
				if BagSync_BlackListFrame:IsVisible() then
					BagSync_BlackListFrame:Hide()
				else
					BagSync_BlackListFrame:Show()
				end
				return true
			elseif c and c:lower() == L["fixdb"] then
				self:FixDB_Data()
				return true
			elseif c and c:lower() == L["config"] then
				InterfaceOptionsFrame_OpenToCategory("BagSync")
				return true
			elseif c and c:lower() ~= "" then
				--do an item search
				if BagSync_SearchFrame then
					if not BagSync_SearchFrame:IsVisible() then BagSync_SearchFrame:Show() end
					BagSync_SearchFrame.SEARCHBTN:SetText(msg)
					BagSync_SearchFrame:initSearch()
				end
				return true
			end
		end

		DEFAULT_CHAT_FRAME:AddMessage("BAGSYNC")
		DEFAULT_CHAT_FRAME:AddMessage(L["/bgs [itemname] - Does a quick search for an item"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bgs search - Opens the search window"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bgs gold - Displays a tooltip with the amount of gold on each character."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bgs tokens - Opens the tokens/currency window."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bgs profiles - Opens the profiles window."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bgs professions - Opens the professions window."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bgs blacklist - Opens the blacklist window."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bgs fixdb - Runs the database fix (FixDB) on BagSync."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bgs config - Opens the BagSync Config Window"] )

	end
	
	DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33BagSync|r [v|cFFDF2B2B"..ver.."|r]   /bgs, /bagsync")
	
	--we deleted someone with the Profile Window, display name of user deleted
	if BagSyncOpt.delName then
		print("|cFFFF0000BagSync: "..L["Profiles"].." "..L["Delete"].." ["..BagSyncOpt.delName.."]!|r")
		BagSyncOpt.delName = nil
	end
	
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

------------------------------
--      Event Handlers      --
------------------------------

function BagSync:PLAYER_REGEN_ENABLED()
	if IsInBG() or IsInArena() or InCombatLockdown() or UnitAffectingCombat("player") then return end
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	--were out of an arena or battleground scan the points
	doTokenUpdate = 0
	ScanTokens()
end

function BagSync:GUILD_ROSTER_UPDATE()
	if not IsInGuild() and BS_DB.guild then
		BS_DB.guild = nil
		self:FixDB_Data(true)
	elseif IsInGuild() then
		--if they don't have guild name store it or update it
		if GetGuildInfo("player") then
			if not BS_DB.guild or BS_DB.guild ~= GetGuildInfo("player") then
				BS_DB.guild = GetGuildInfo("player")
				self:FixDB_Data(true)
			end
		end
	end
end

function BagSync:PLAYER_MONEY()
	BS_DB.gold = GetMoney()
end

------------------------------
--      BAG UPDATES  	    --
------------------------------

function BagSync:BAG_UPDATE(event, bagid)
	-- -1 happens to be the primary bank slot ;)
	if bagid <= BANK_CONTAINER then return end
	if not(bagid > NUM_BAG_SLOTS) or atBank or atVoidBank then
	
		--this will update the bank/bag slots
		local bagname

		--get the correct bag name based on it's id, trying NOT to use numbers as Blizzard may change bagspace in the future
		--so instead I'm using constants :)
		if bagid < -1 then return end
		
		if (bagid >= NUM_BAG_SLOTS + 1) and (bagid <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS) then
			bagname = 'bank'
		elseif (bagid >= BACKPACK_CONTAINER) and (bagid <= BACKPACK_CONTAINER + NUM_BAG_SLOTS) then
			bagname = 'bag'
		else
			return
		end

		if atBank then
			--we have to force the -1 default bank container because blizzard doesn't push updates for it (for some stupid reason)
			SaveBag('bank', BANK_CONTAINER)
		end

		--now save the item information in the bag from bagupdate, this could be bag or bank
		SaveBag(bagname, bagid)
		
	end
end

function BagSync:UNIT_INVENTORY_CHANGED(event, unit)
	if unit == 'player' then
		SaveEquipment()
	end
end

------------------------------
--      BANK	            --
------------------------------

function BagSync:BANKFRAME_OPENED()
	atBank = true
	ScanEntireBank()
end

function BagSync:BANKFRAME_CLOSED()
	atBank = false
end

------------------------------
--      VOID BANK	        --
------------------------------

function BagSync:VOID_STORAGE_OPEN()
	atVoidBank = true
	ScanVoidBank()
end

function BagSync:VOID_STORAGE_CLOSE()
	atVoidBank = false
end

function BagSync:VOID_STORAGE_UPDATE()
	ScanVoidBank()
end

function BagSync:VOID_STORAGE_CONTENTS_UPDATE()
	ScanVoidBank()
end

function BagSync:VOID_TRANSFER_DONE()
	ScanVoidBank()
end

------------------------------
--      GUILD BANK	        --
------------------------------

function BagSync:GUILDBANKFRAME_OPENED()
	atGuildBank = true
	if not BagSyncOpt.enableGuild then return end
	
	local numTabs = GetNumGuildBankTabs()
	for tab = 1, numTabs do
		-- add this tab to the queue to refresh; if we do them all at once the server bugs and sends massive amounts of events
		local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals = GetGuildBankTabInfo(tab)
		if isViewable then
			guildTabQueryQueue[tab] = true
		end
	end
end

function BagSync:GUILDBANKFRAME_CLOSED()
	atGuildBank = false
end

function BagSync:GUILDBANKBAGSLOTS_CHANGED()
	if not BagSyncOpt.enableGuild then return end

	if atGuildBank then
		-- check if we need to process the queue
		local tab = next(guildTabQueryQueue)
		if tab then
			QueryGuildBankTab(tab)
			guildTabQueryQueue[tab] = nil
		else
			-- the bank is ready for reading
			ScanGuildBank()
		end
	end
end

------------------------------
--      MAILBOX  	        --
------------------------------

function BagSync:MAIL_SHOW()
	if isCheckingMail then return end
	if not BagSyncOpt.enableMailbox then return end
	ScanMailbox()
end

function BagSync:MAIL_INBOX_UPDATE()
	if isCheckingMail then return end
	if not BagSyncOpt.enableMailbox then return end
	ScanMailbox()
end

------------------------------
--     AUCTION HOUSE        --
------------------------------

function BagSync:AUCTION_HOUSE_SHOW()
	if not BagSyncOpt.enableAuction then return end
	ScanAuctionHouse()
end

function BagSync:AUCTION_OWNED_LIST_UPDATE()
	if not BagSyncOpt.enableAuction then return end
	BS_DB.AH_LastScan = time()
	ScanAuctionHouse()
end

------------------------------
--     PROFESSION           --
------------------------------

function BagSync:TRADE_SKILL_SHOW()
	--IsTradeSkillLinked() returns true only if trade window was opened from chat link (meaning another player)
	if (not IsTradeSkillLinked()) then
		
		local tradename = _G.GetTradeSkillLine()
		local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()
		
		local iconProf1 = prof1 and select(2, GetProfessionInfo(prof1))
		local iconProf2 = prof2 and select(2, GetProfessionInfo(prof2))
		
		--list of tradeskills with NO skill link but can be used as primaries (ex. a person with two gathering skills)
		local noLinkTS = {
			["Interface\\Icons\\Trade_Herbalism"] = true, --this is Herbalism
			["Interface\\Icons\\INV_Misc_Pelt_Wolf_01"] = true, --this is Skinning
			["Interface\\Icons\\INV_Pick_02"] = true, --this is Mining
		}
		
		--prof1
		if prof1 and (GetProfessionInfo(prof1) == tradename) and GetTradeSkillListLink() then
			local skill = select(3, GetProfessionInfo(prof1))
			BS_CD[1] = { tradename, GetTradeSkillListLink(), skill }
		elseif prof1 and iconProf1 and noLinkTS[iconProf1] then
			--only store if it's herbalism, skinning, or mining
			doRegularTradeSkill(prof1, 1)
		elseif not prof1 and BS_CD[1] then
			--they removed a profession
			BS_CD[1] = nil
		end

		--prof2
		if prof2 and (GetProfessionInfo(prof2) == tradename) and GetTradeSkillListLink() then
			local skill = select(3, GetProfessionInfo(prof2))
			BS_CD[2] = { tradename, GetTradeSkillListLink(), skill }
		elseif prof2 and iconProf2 and noLinkTS[iconProf2] then
			--only store if it's herbalism, skinning, or mining
			doRegularTradeSkill(prof2, 2)
		elseif not prof2 and BS_CD[2] then
			--they removed a profession
			BS_CD[2] = nil
		end
		
		--archaeology
		if archaeology then
			doRegularTradeSkill(archaeology, 3)
		elseif not archaeology and BS_CD[3] then
			--they removed a profession
			BS_CD[3] = nil
		end
		
		--fishing
		if fishing then
			doRegularTradeSkill(fishing, 4)
		elseif not fishing and BS_CD[4] then
			--they removed a profession
			BS_CD[4] = nil
		end
		
		--cooking
		if cooking and (GetProfessionInfo(cooking) == tradename) and GetTradeSkillListLink() then
			local skill = select(3, GetProfessionInfo(cooking))
			BS_CD[5] = { tradename, GetTradeSkillListLink(), skill }
		elseif not cooking and BS_CD[5] then
			--they removed a profession
			BS_CD[5] = nil
		end
		
		--firstAid
		if firstAid and (GetProfessionInfo(firstAid) == tradename) and GetTradeSkillListLink() then
			local skill = select(3, GetProfessionInfo(firstAid))
			BS_CD[6] = { tradename, GetTradeSkillListLink(), skill }
		elseif not firstAid and BS_CD[6] then
			--they removed a profession
			BS_CD[6] = nil
		end
		
	end
end
