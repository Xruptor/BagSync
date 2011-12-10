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
	BagSyncDB = BagSyncDB or {}
	BagSyncDB[currentRealm] = BagSyncDB[currentRealm] or {}
	BagSyncDB[currentRealm][currentPlayer] = BagSyncDB[currentRealm][currentPlayer] or {}
	BS_DB = BagSyncDB[currentRealm][currentPlayer]
	
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
	
	--blacklist by realm
	BagSyncBLACKLIST_DB = BagSyncBLACKLIST_DB or {}
	BagSyncBLACKLIST_DB[currentRealm] = BagSyncBLACKLIST_DB[currentRealm] or {}
	BS_BL = BagSyncBLACKLIST_DB[currentRealm]
end

function BagSync:FixDB_Data(onlyChkGuild)
	--Removes obsolete character information
	--Removes obsolete guild information
	--Removes obsolete characters from tokens db
	--Removes obsolete keyring information
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
				elseif string.find(q, 'key') then
					--remove obsolete keyring information
					BagSyncDB[realm][k][q] = nil
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
				--delete the guild
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

--list of tradeskills with NO skill link but can be used as primaries (ex. a person with two gathering skills)
local noLinkTS = {
	["Interface\Icons\Trade_Herbalism"] = true, --this is Herbalism
	["Interface\Icons\INV_Misc_Pelt_Wolf_01"] = true, --this is Skinning
	["Interface\Icons\INV_Pick_02"] = true, --this is Mining
}

local function doRegularTradeSkill(numIndex, dbIdx)
	local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier = GetProfessionInfo(numIndex)
	if name and skillLevel then
		BS_CD[dbIdx] = format('%s,%s', name, skillLevel)
	end
end

local function GetBagSize(bagid)
	if bagid == 'equip' then
		return NUM_EQUIPMENT_SLOTS
	end
	return GetContainerNumSlots(bagid)
end

local function GetTag(bagname, bagid, slot)
	if bagname and bagid and slot then
		return bagname..':'..bagid..':'..slot
	end
	return nil
end

--special thanks to tuller :)
local function ToShortLink(link)
	--honestly I did it this half-ass way because of tired of having to update this everytime blizzard decides to alter their itemid format.
	--at least this way it will always pull the first number after itemid: and before the second :
	--it's not the best way to do this, but it's better then having to freaking modify a regex every so often.  Their latest change is due to Transmorgify.
	if link and type(link) == "string" then
		--first attempt
		local _, first = string.find(link, "item:")
		local second = string.find(link, ":", first+1) --first occurance of : after item:
		local finally = string.sub(link, first+1, second-1) --after item:  and before second :
		if tonumber(finally) then
			return finally
		end
		--second attempt
		local a,b,c,d,e,f,g,h = link:match('(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+)')
		if(b == '0' and b == c and c == d and d == e and e == f and f == g) then
			return a
		end
		--final attempt
		return format('item:%s:%s:%s:%s:%s:%s:%s:%s', a, b, c, d, e, f, g, h)
	end
	return nil
end

----------------------
--  Bag Functions   --
----------------------

local function SaveItem(bagname, bagid, slot)
	local index = GetTag(bagname, bagid, slot)
	if not index then return nil end
	
	--reset our tooltip data since we scanned new items (we want current data not old)
	lastItem = nil
	lastDisplayed = {}

	local texture, count = GetContainerItemInfo(bagid, slot)

	if texture then
		local link = ToShortLink(GetContainerItemLink(bagid, slot))
		count = count > 1 and count or nil
		
		--Example ["bag:0:1"] = link, count
		if (link and count) then
			BS_DB[index] = format('%s,%d', link, count)
		else
			BS_DB[index] = link
		end
		
		return
	end
	
	BS_DB[index] = nil
end

local function SaveBag(bagname, bagid, rollupdate)
	if not BS_DB then StartupDB() end
	--this portion of the code will save the bag data, (type of bag, size of bag, bag item link, etc..)
	--this is used later to quickly grab bag data and size without having to go through the whole
	--song and dance again
	--bd = bagdata
	--Example ["bd:bagid:0"] = size, link, count
	local size = GetBagSize(bagid)
	local index = GetTag('bd', bagname, bagid)
	if not index then return end
	
	if size > 0 then
		local invID = bagid > 0 and ContainerIDToInventoryID(bagid)
		local link = ToShortLink(GetInventoryItemLink('player', invID))
		local count =  GetInventoryItemCount('player', invID)
		if count < 1 then count = nil end

		if (size and link and count) then
			BS_DB[index] = format('%d,%s,%d', size, link, count)
		elseif (size and link) then
			BS_DB[index] = format('%d,%s', size, link)
		else
			BS_DB[index] = size
		end
	else
		BS_DB[index] = nil
	end
	
	--used to scan the entire bag and save it's item data
	if rollupdate then
		for slot = 1, GetBagSize(bagid) do
			SaveItem(bagname, bagid, slot)
		end
	end
end

local function OnBagUpdate(bagid)

	--this will update the bank/bag slots
	local bagname

	--get the correct bag name based on it's id, trying NOT to use numbers as Blizzard may change bagspace in the future
	--so instead I'm using constants :)
	
	if bagid == -4 or bagid == -2 then return end --dont touch tokens or keyring
	
	if bagid == BANK_CONTAINER then
		bagname = 'bank'
	elseif (bagid >= NUM_BAG_SLOTS + 1) and (bagid <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS) then
		bagname = 'bank'
	elseif (bagid >= BACKPACK_CONTAINER) and (bagid <= BACKPACK_CONTAINER + NUM_BAG_SLOTS) then
		bagname = 'bag'
	else
		return
	end

	if atBank then
		--force an update of the primary bank container (which is -1, in case something was moved)
		--blizzard doesn't send a bag update for the -1 bank slot for some reason
		--true = forces a rollupdate to scan entire bag
		SaveBag('bank', BANK_CONTAINER, true)
	end
	
	--save the bag data in case it was changed
	SaveBag(bagname, bagid, false)

	--now save the item information in the bag
	for slot = 1, GetBagSize(bagid) do
		SaveItem(bagname, bagid, slot)
	end
end

local function SaveEquipment()

	--reset our tooltip data since we scanned new items (we want current data not old)
	lastItem = nil
	lastDisplayed = {}
	
	--start at 1, 0 used to be the old range slot (not needed anymore)
	for slot = 1, NUM_EQUIPMENT_SLOTS do
		local link = GetInventoryItemLink('player', slot)
		local index = GetTag('equip', 0, slot)

		if link then
			local linkItem = ToShortLink(link)
			local count =  GetInventoryItemCount('player', slot)
			count = count > 1 and count or nil

			if (linkItem and count) then
					BS_DB[index] = format('%s,%d', linkItem, count)
			else
				BS_DB[index] = linkItem
			end
		else
			BS_DB[index] = nil
		end
	end
end

local function ScanEntireBank()
	--scan the primary Bank Bag -1, for some reason Blizzard never sends updates on it
	SaveBag('bank', BANK_CONTAINER, true)
	--NUM_BAG_SLOTS+1 to NUM_BAG_SLOTS+NUM_BANKBAGSLOTS are your bank bags 
	for i = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
		SaveBag('bank', i, true)
	end
end

local function ScanVoidBank()
	if VoidStorageFrame and VoidStorageFrame:IsShown() then
		for i = 1, 80 do
			itemID, textureName, locked, recentDeposit, isFiltered = GetVoidItemInfo(i)
			local index = GetTag('void', 0, i)
			if (itemID) then
				BS_DB[index] = tostring(itemID)
			else
				--itemID returned nil but we MAY have this location saved in DB, so remove it
				BS_DB[index] = nil
			end
		end
	end
end

local function ScanGuildBank()
	--GetCurrentGuildBankTab()
	if not IsInGuild() then return end
	
	BS_GD[BS_DB.guild] = BS_GD[BS_DB.guild] or {}

	local numTabs = GetNumGuildBankTabs()
	
	for tab = 1, numTabs do
		for slot = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
		
			local link = GetGuildBankItemLink(tab, slot)
			local index = GetTag('guild', tab, slot)
			
			if link then
				local linkItem = ToShortLink(link)
				local _, count = GetGuildBankItemInfo(tab, slot);
				count = count > 1 and count or nil
				
				if (linkItem and count) then
					BS_GD[BS_DB.guild][index] = format('%s,%d', linkItem, count)
				else
					BS_GD[BS_DB.guild][index] = linkItem
				end
			else
				BS_GD[BS_DB.guild][index] = nil
			end
		end
	end
	
end

local function ScanMailbox()
	--this is to prevent buffer overflow from the CheckInbox() function calling ScanMailbox too much :)
	if isCheckingMail then return end
	isCheckingMail = true

	 --used to initiate mail check from server, for some reason GetInboxNumItems() returns zero sometimes
	 --even though the user has mail in the mailbox.  This can be attributed to lag.
	CheckInbox()

	local mailCount = 0
	local numInbox = GetInboxNumItems()

	--scan the inbox
	if (numInbox > 0) then
		for mailIndex = 1, numInbox do
			for i=1, ATTACHMENTS_MAX_RECEIVE do
				local name, itemTexture, count, quality, canUse = GetInboxItem(mailIndex, i)
				local link = GetInboxItemLink(mailIndex, i)
				
				if name and link then
					mailCount = mailCount + 1
					
					local index = GetTag('mailbox', 0, mailCount)
					local linkItem = ToShortLink(link)
					
					if (count) then
						BS_DB[index] = format('%s,%d', linkItem, count)
					else
						BS_DB[index] = linkItem
					end
				end
				
			end
		end
	end
	
	--lets avoid looping through data if we can help it
	--store the amount of mail at our mailbox for comparison
	local bChk = GetTag('bd', 'inbox', 0)

	if BS_DB[bChk] then
		local bVal = BS_DB[bChk]
		--only delete if our current mail count is smaller then our stored amount
		if mailCount < bVal then
			for x = (mailCount + 1), bVal do
				local delIndex = GetTag('mailbox', 0, x)
				if BS_DB[delIndex] then BS_DB[delIndex] = nil end
			end
		end
	end
	
	--store our mail count regardless
	BS_DB[bChk] = mailCount

	isCheckingMail = false
end

local function ScanAuctionHouse()
	local ahCount = 0
	local numActiveAuctions = GetNumAuctionItems("owner")
	
	if not BS_DB.AH_LastScan then BS_DB.AH_LastScan = time() end --this is only really used once, at first activation of v6.7
	
	--scan the auction house
	if (numActiveAuctions > 0) then
		for ahIndex = 1, numActiveAuctions do
			local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner, saleStatus  = GetAuctionItemInfo("owner", ahIndex)
			if name then
				local link = GetAuctionItemLink("owner", ahIndex)
				local timeLeft = GetAuctionItemTimeLeft("owner", ahIndex)
				
				if link and timeLeft then
					ahCount = ahCount + 1
					local index = GetTag('auction', 0, ahCount)
					local linkItem = ToShortLink(link)
					if linkItem then
						count = (count or 1)
						BS_DB[index] = format('%s,%s,%s,%s', linkItem, count, timeLeft, time())
					else
						BS_DB[index] = linkItem
					end
				end
			end
		end
	end
	
	--check for stragglers from previous auction house count
	local bChk = GetTag('bd', 'auction_count', 0)

	if BS_DB[bChk] then
		local bVal = BS_DB[bChk]
		--only delete if our current auction count is smaller then our stored amount
		if ahCount < bVal then
			for x = (ahCount + 1), bVal do
				local delIndex = GetTag('auction', 0, x)
				if BS_DB[delIndex] then BS_DB[delIndex] = nil end
			end
		end
	end
	
	--store our new auction house count
	BS_DB[bChk] = ahCount
end

--this method is global for all toons
local function RemoveExpiredAuctions()
	local bChk = GetTag('bd', 'auction_count', 0)
	local timestampChk = { 30*60, 2*60*60, 12*60*60, 48*60*60 }
				
	for realm, rd in pairs(BagSyncDB) do
		--realm
		for k, v in pairs(rd) do
			--users k=name, v=values
			if BagSyncDB[realm][k].AH_LastScan then --only proceed if we have an auction house time to work with
				--check to see if we even have a count
				if BagSyncDB[realm][k][bChk] then
					--we do so lets do a loop
					local bVal = BagSyncDB[realm][k][bChk]
					--do a loop through all of them and check to see if any expired
					for x = 1, bVal do
						local getIndex = GetTag('auction', 0, x)
						if BagSyncDB[realm][k][getIndex] then
							--check for expired and remove if necessary
							--it's okay if the auction count is showing more then actually stored, it's just used as a means
							--to scan through all our items.  Even if we have only 3 and the count is 6 it will just skip the last 3.
							local dblink, dbcount, dbtimeleft, dbstoretime = strsplit(',', BagSyncDB[realm][k][getIndex])
							
							--only proceed if we have everything to work with, otherwise this auction data is corrupt
							if dblink and dbcount and dbtimeleft and dbstoretime then
								if tonumber(dbtimeleft) < 1 or tonumber(dbtimeleft) > 4 then dbtimeleft = 4 end --just in case
								--now do the time checks
								local diff = time() - BagSyncDB[realm][k].AH_LastScan 
								local diff_item = time() - tonumber(dbstoretime)
								if diff > timestampChk[tonumber(dbtimeleft)] or diff_item > timestampChk[tonumber(dbtimeleft)] then
									--technically this isn't very realiable.  but I suppose it's better the  nothing
									BagSyncDB[realm][k][getIndex] = nil
								end
							else
								--it's corrupt delete it
								BagSyncDB[realm][k][getIndex] = nil
							end
						end
					end
				end
			end
		end
	end
	
end

--this method is retricted to the current toon
local function CharRemoveExpired()
	if not BS_DB.AH_LastScan then return end
	
	local bChk = GetTag('bd', 'auction_count', 0)
	local timestampChk = { 30*60, 2*60*60, 12*60*60, 48*60*60 }
	
	--check to see if we even have a count
	if BS_DB[bChk] then
		--we do so lets do a loop
		local bVal = BS_DB[bChk]
		
		--do a loop through all of them and check to see if any expired
		for x = 1, bVal do
			local getIndex = GetTag('auction', 0, x)
			
			if BS_DB[getIndex] then
				--check for expired and remove if necessary
				--it's okay if the auction count is showing more then actually stored, it's just used as a means
				--to scan through all our items.  Even if we have only 3 and the count is 6 it will just skip the last 3.
				local dblink, dbcount, dbtimeleft, dbstoretime = strsplit(',', BS_DB[getIndex])
				
				--only proceed if we have everything to work with, otherwise this auction data is corrupt
				if dblink and dbcount and dbtimeleft and dbstoretime then
					if tonumber(dbtimeleft) < 1 or tonumber(dbtimeleft) > 4 then dbtimeleft = 4 end --just in case
					--now do the time checks
					local diff = time() - BS_DB.AH_LastScan
					local diff_item = time() - tonumber(dbstoretime)
					if diff > timestampChk[tonumber(dbtimeleft)] or diff_item > timestampChk[tonumber(dbtimeleft)] then
						--technically this isn't very realiable.  but I suppose it's better the  nothing
						BS_DB[getIndex] = nil
					end
				else
					--it's corrupt delete it
					BS_DB[getIndex] = nil
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
	local tooltip = getglobal("BagSyncMoneyTooltip") or nil
	
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
	
end

hooksecurefunc("BackpackTokenFrame_Update", ScanTokens)

------------------------
--      Tooltip!      --
-- (Special thanks to tuller)
------------------------

function BagSync:resetTooltip()
	lastDisplayed = {}
	lastItem = nil
end

local function CountsToInfoString(invCount, bankCount, equipCount, guildCount, mailboxCount, voidbankCount, auctionCount)
	local info
	local total = invCount + bankCount + equipCount + mailboxCount + voidbankCount + auctionCount

	if invCount > 0 then
		info = L["Bags: %d"]:format(invCount)
	end

	if bankCount > 0 then
		local count = L["Bank: %d"]:format(bankCount)
		if info then
			info = strjoin(', ', info, count)
		else
			info = count
		end
	end

	if equipCount > 0 then
		local count = L["Equipped: %d"]:format(equipCount)
		if info then
			info = strjoin(', ', info, count)
		else
			info = count
		end
	end

	if guildCount > 0 and BagSyncOpt.enableGuild and not BagSyncOpt.showGuildNames then
		total = total + guildCount --add the guild count only if we don't have showguildnames on, otherwise it's counted twice
		local count = L["Guild: %d"]:format(guildCount)
		if info then
			info = strjoin(', ', info, count)
		else
			info = count
		end
	end
	
	if mailboxCount > 0 and BagSyncOpt.enableMailbox then
		local count = L["Mailbox: %d"]:format(mailboxCount)
		if info then
			info = strjoin(', ', info, count)
		else
			info = count
		end
	end
	
	if voidbankCount > 0 then
		local count = L["Void: %d"]:format(voidbankCount)
		if info then
			info = strjoin(', ', info, count)
		else
			info = count
		end
	end
	
	if auctionCount > 0 and BagSyncOpt.enableAuction then
		local count = L["AH: %d"]:format(auctionCount)
		if info then
			info = strjoin(', ', info, count)
		else
			info = count
		end
	end
	
	
	if info then
		if total and not(total == invCount or total == bankCount or total == equipCount or total == guildCount
			or total == mailboxCount or total == voidbankCount or total == auctionCount) then
			local totalStr = format(MOSS, total)
			return totalStr .. format(SILVER, format(' (%s)', info))
		end
		return format(MOSS, info)
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

local function AddOwners(frame, link)
	frame.BagSyncShowOnce = nil

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
	
	--loop through our characters
	for k, v in pairs(BagSyncDB[currentRealm]) do

		local infoString
		local invCount, bankCount, equipCount, guildCount, mailboxCount, voidbankCount, auctionCount = 0, 0, 0, 0, 0, 0, 0
		local pFaction = v.faction or playerFaction --just in case ;) if we dont know the faction yet display it anyways
		
		--check if we should show both factions or not
		if BagSyncOpt.enableFaction or pFaction == playerFaction then

			--now count the stuff for the user
			for q, r in pairs(v) do
				if itemLink then
					local dblink, dbcount = strsplit(',', r)
					if dblink then
						if string.find(q, 'bank') and dblink == itemLink then
							bankCount = bankCount + (dbcount or 1)
						elseif string.find(q, 'bag') and dblink == itemLink then
							invCount = invCount + (dbcount or 1)
						elseif string.find(q, 'equip') and dblink == itemLink then
							equipCount = equipCount + (dbcount or 1)
						elseif string.find(q, 'mailbox') and dblink == itemLink then
							mailboxCount = mailboxCount + (dbcount or 1)
						elseif string.find(q, 'void') and dblink == itemLink then
							voidbankCount = voidbankCount + (dbcount or 1)
						elseif string.find(q, 'auction') and dblink == itemLink then
							auctionCount = auctionCount + (dbcount or 1)
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
							if itemLink then
								local dblink, dbcount = strsplit(',', r)
								if dblink and dblink == itemLink then
									guildCount = guildCount + (dbcount or 1)
									tmpCount = tmpCount + (dbcount or 1)
								end
							end
						end
						previousGuilds[guildN] = tmpCount
					end
				end
			end
		
			--get class for the unit if there is one
			local pClass = v.class or nil
		
			infoString = CountsToInfoString(invCount, bankCount, equipCount, guildCount, mailboxCount, voidbankCount, auctionCount)
			grandTotal = grandTotal + invCount + bankCount + equipCount + guildCount + mailboxCount + voidbankCount + auctionCount

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

--Thanks to Aranarth from wowinterface.  Replaced HookScript with insecure hooks
local orgTipSetItem = {}
local orgTipOnUpdate = {}

local function Tip_OnSetItem(self, ...)
	orgTipSetItem[self](self, ...)
	local _, itemLink = self:GetItem()
	if itemLink and GetItemInfo(itemLink) then
		local itemName = GetItemInfo(itemLink)
		if not self.BagSyncThrottle then self.BagSyncThrottle = GetTime() end
		if not self.BagSyncPrevious then self.BagSyncPrevious = itemName end
		if not self.BagSyncShowOnce and self:GetName() == "GameTooltip" then self.BagSyncShowOnce = true end

		if itemName ~= self.BagSyncPrevious then
			self.BagSyncPrevious = itemName
			self.BagSyncThrottle = GetTime()
		end

		if self:GetName() ~= "GameTooltip" or (GetTime() - self.BagSyncThrottle) >= 0.05 then
			self.BagSyncShowOnce = nil
			return AddOwners(self, itemLink)
		end
	end
end

local function Tip_OnUpdate(self, ...)
	orgTipOnUpdate[self](self, ...)
	if self:GetName() == "GameTooltip" and self.BagSyncShowOnce and self.BagSyncThrottle and (GetTime() - self.BagSyncThrottle) >= 0.05 then
		local _, itemLink = self:GetItem()
		self.BagSyncShowOnce = nil
		if itemLink then
			return AddOwners(self, itemLink)
		end
	end
end

for _, tip in next, { GameTooltip, ItemRefTooltip } do
	
	orgTipSetItem[tip] = tip:GetScript"OnTooltipSetItem"
	tip:SetScript("OnTooltipSetItem", Tip_OnSetItem)
	
	if tip == ItemRefTooltip then
		orgTipOnUpdate[tip] = tip.UpdateTooltip
		tip.UpdateTooltip = Tip_OnUpdate
	else
		orgTipOnUpdate[tip] = tip:GetScript"OnUpdate"
		tip:SetScript("OnUpdate", Tip_OnUpdate)
	end
end

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
	if BagSyncDB.dbversion then
		--remove old variable and replace with BagSyncOpt DB
		BagSyncDB.dbversion = nil
		BagSyncOpt.dbversion = ver
		self:FixDB_Data()
	elseif not BagSyncOpt.dbversion or BagSyncOpt.dbversion ~= ver then
		self:FixDB_Data()
		BagSyncOpt.dbversion = ver
	end
	
	--save the current user money (before bag update)
	if BS_DB["gold:0:0"] then BS_DB["gold:0:0"] = nil end --remove old format
	BS_DB.gold = GetMoney()

	--save the class information
	if BS_DB["class:0:0"] then BS_DB["class:0:0"] = nil end --remove old format
	BS_DB.class = playerClass

	--save the faction information
	--"Alliance", "Horde" or nil
	if BS_DB["faction:0:0"] then BS_DB["faction:0:0"] = nil end --remove old format
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
		SaveBag('bag', i, true)
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
	--The new token bag or token currency tab has a bag number of -4, lets ignore this bag when new tokens are added
	--http://www.wowwiki.com/API_TYPE_bagID
	if bagid == -4 or bagid == -2 then return end --dont do tokens or keyring
	--if not token bag then proceed
	if not(bagid == BANK_CONTAINER or bagid > NUM_BAG_SLOTS) or atBank or atVoidBank then
		OnBagUpdate(bagid)
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
		guildTabQueryQueue[tab] = true
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
	CharRemoveExpired()
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
		if not tradename then return end
		
		--prof1
		if prof1 and (GetProfessionInfo(prof1) == tradename) and GetTradeSkillListLink() then
			local skill = select(3, GetProfessionInfo(prof1))
			BS_CD[1] = { tradename, GetTradeSkillListLink(), skill }
		elseif prof1 and select(2, GetProfessionInfo(prof1)) and noLinkTS[select(2, GetProfessionInfo(prof1))] then
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
		elseif prof2 and select(2, GetProfessionInfo(prof2)) and noLinkTS[select(2, GetProfessionInfo(prof2))] then
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
