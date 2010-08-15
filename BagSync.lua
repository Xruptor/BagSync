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
local NUM_EQUIPMENT_SLOTS = 19
local BS_DB
local BS_GD
local BS_TD
local MAX_GUILDBANK_SLOTS_PER_TAB = 98
local doTokenUpdate = 0
local ammoCount = 0

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
	icon = "Interface\\Icons\\INV_Misc_Bag_12",
	label = "BagSync",
	text = "BagSync",
		
	OnClick = function(self, button)
		if getglobal("BagSync_SearchFrame") then
			if getglobal("BagSync_SearchFrame"):IsVisible() then
				getglobal("BagSync_SearchFrame"):Hide()
			else
				getglobal("BagSync_SearchFrame"):Show()
			end
		end
	end,

	OnTooltipShow = function(self)
		self:Hide()
	end
})

------------------------------
--        MAIN OBJ	        --
------------------------------

local BagSync = CreateFrame("frame", "BagSync", UIParent)

BagSync:SetScript('OnEvent', function(self, event, ...)
	if self[event] then
		self[event](self, event, ...)
	end
end)

if IsLoggedIn() then BagSync:PLAYER_LOGIN() else BagSync:RegisterEvent('PLAYER_LOGIN') end

------------------------------
--      Event Handlers      --
------------------------------

function BagSync:PLAYER_LOGIN()
	
	 BINDING_HEADER_BAGSYNC = "BagSync"
	 BINDING_NAME_BAGSYNCTOGGLESEARCH = L["Toggle Search"]
	 BINDING_NAME_BAGSYNCTOGGLETOKENS = L["Toggle Tokens"]
	 BINDING_NAME_BAGSYNCTOGGLEPROFILES = L["Toggle Profiles"]
  
	local ver = GetAddOnMetadata("BagSync","Version") or 0
	
	--load our player info after login
	currentPlayer = UnitName('player')
	currentRealm = GetRealmName()
	playerClass = select(2, UnitClass("player"))

	--initiate the db
	self:StartupDB()
	
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
	BS_DB["gold:0:0"] = GetMoney()

	--save the class information
	BS_DB["class:0:0"] = playerClass
	
	--check for player not in guild
	if IsInGuild() or GetNumGuildMembers(true) > 0 then
		GuildRoster()
	else
		BS_DB.guild = nil
	end
	
	--check for hunter
	if playerClass == "HUNTER" then
		ammoCount = GetInventoryItemCount('player', 0) or 0
	end
	
	--this will force an update of the -2 key ring
	self:SaveBag('key', KEYRING_CONTAINER, true)
	
	--save all inventory data, including backpack(0)
	for i = BACKPACK_CONTAINER, BACKPACK_CONTAINER + NUM_BAG_SLOTS do
		self:SaveBag('bag', i, true)
	end

	--force an equipment scan
	self:SaveEquipment()
	
	--force token scan
	self:ScanTokens()

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
	
	local slashChk = {
		[L["total"]] = "showTotal",
		[L["guildname"]] = "showGuildNames",
		[L["throttle"]] = "enableThrottle",
		[L["guild"]] = "enableGuild",
		[L["mailbox"]] = "enableMailbox",
		[L["unitclass"]] = "enableUnitClass",
	}
	
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
			elseif c and c:lower() == L["fixdb"] then
				self:FixDB_Data()
				return true
			elseif c and slashChk[c:lower()] and BagSyncOpt[slashChk[c:lower()]] ~= nil then
				lastDisplayed = {}
				lastItem = nil
				BagSyncOpt[slashChk[c:lower()]] = not BagSyncOpt[slashChk[c:lower()]]
				if BagSyncOpt[slashChk[c:lower()]] then
					print("|cFFFF0000BagSync: |cFFFFFFFF"..(c:lower()).."|r |cFFFF0000"..L["ON"].."|r")
				else
					print("|cFFFF0000BagSync:|r |cFFFFFFFF"..(c:lower()).."|r |cFFFF0000"..L["OFF"].."|r")
				end
				return true
			elseif c and c:lower() ~= "" then
				--do an item search
				if BagSync_SearchFrame then
					if not BagSync_SearchFrame:IsVisible() then BagSync_SearchFrame:Show() end
					BagSync_SearchFrame.SEARCHBTN:SetText(c:lower())
					BagSync_SearchFrame:DoSearch()
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
		DEFAULT_CHAT_FRAME:AddMessage(L["/bgs fixdb - Runs the database fix (FixDB) on BagSync."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bgs total - Toggles the [Total] display in tooltips and gold display."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bgs guildname - Toggles the [Guild Name] display in tooltips."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bgs throttle - Toggles the throttle when displaying tooltips. (ON = Prevents Lag)."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bgs guild - Toggles the displaying of guild information."])
		
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

function BagSync:GUILD_ROSTER_UPDATE()
	if not IsInGuild() then
		BS_DB.guild = nil
	else
		--if they don't have guild name store it or update it
		if GetGuildInfo("player") then
			if not BS_DB.guild or BS_DB.guild ~= GetGuildInfo("player") then
				BS_DB.guild = GetGuildInfo("player")
			end
		end
	end
end

function BagSync:PLAYER_MONEY()
	BS_DB["gold:0:0"] = GetMoney()
end

function BagSync:BANKFRAME_OPENED()
	self.atBank = true
	self:ScanEntireBank()
end

function BagSync:BANKFRAME_CLOSED()
	self.atBank = nil
end

function BagSync:GUILDBANKFRAME_OPENED()
	self.atGuildBank = true
	if not BagSyncOpt.enableGuild then return end
	
	local numTabs = GetNumGuildBankTabs()
	for tab = 1, numTabs do
		QueryGuildBankTab(tab)
	end
end

function BagSync:GUILDBANKFRAME_CLOSED()
	self.atGuildBank = nil
end

function BagSync:GUILDBANKBAGSLOTS_CHANGED()
	if not BagSyncOpt.enableGuild then return end
	if self.atGuildBank then
		self:ScanGuildBank()
	end
end

function BagSync:BAG_UPDATE(event, bagid)
	--The new token bag or token currency tab has a bag number of -4, lets ignore this bag when new tokens are added
	--http://www.wowwiki.com/API_TYPE_bagID
	if bagid == -4 then return nil end
	--if not token bag then proceed
	if not(bagid == BANK_CONTAINER or bagid > NUM_BAG_SLOTS) or self.atBank then
		self:OnBagUpdate(bagid)
	end
end

function BagSync:UNIT_INVENTORY_CHANGED(event, unit)
	if unit == 'player' then
		self:SaveEquipment()
	end
end

function BagSync:MAIL_SHOW()
	if self.isCheckingMail then return end
	if not BagSyncOpt.enableMailbox then return end
	self:ScanMailbox()
end

function BagSync:MAIL_INBOX_UPDATE()
	if self.isCheckingMail then return end
	if not BagSyncOpt.enableMailbox then return end
	self:ScanMailbox()
end

----------------------
--   DB Functions   --
----------------------

function BagSync:StartupDB()
	BagSyncDB = BagSyncDB or {}
	BagSyncDB[currentRealm] = BagSyncDB[currentRealm] or {}
	BagSyncDB[currentRealm][currentPlayer] = BagSyncDB[currentRealm][currentPlayer] or {}
	BS_DB = BagSyncDB[currentRealm][currentPlayer]
	
	BagSyncOpt = BagSyncOpt or {}
	if BagSyncOpt.showTotal == nil then BagSyncOpt.showTotal = true end
	if BagSyncOpt.showGuildNames == nil then BagSyncOpt.showGuildNames = false end
	if BagSyncOpt.enableThrottle == nil then BagSyncOpt.enableThrottle = true end
	if BagSyncOpt.enableGuild == nil then BagSyncOpt.enableGuild = true end
	if BagSyncOpt.enableMailbox == nil then BagSyncOpt.enableMailbox = true end
	if BagSyncOpt.enableUnitClass == nil then BagSyncOpt.enableUnitClass = false end
	
	BagSyncGUILD_DB = BagSyncGUILD_DB or {}
	BagSyncGUILD_DB[currentRealm] = BagSyncGUILD_DB[currentRealm] or {}
	BS_GD = BagSyncGUILD_DB[currentRealm]

	BagSyncTOKEN_DB = BagSyncTOKEN_DB or {}
	BagSyncTOKEN_DB[currentRealm] = BagSyncTOKEN_DB[currentRealm] or {}
	BS_TD = BagSyncTOKEN_DB[currentRealm]
end

function BagSync:FixDB_Data()
	--this searches for incorrect bagid's attached to incorrect bag names
	--it also deletes old guild data if found
	--mind you this funcion runs once every version change or if they delete a profile
	local storeGuilds = {}
	local storeUsers = {}
	
	for realm, rd in pairs(BagSyncDB) do
		--realm
			storeUsers[realm] = storeUsers[realm] or {}
		for k, v in pairs(rd) do
			--users
				storeUsers[realm][k] = storeUsers[realm][k] or 1
			for q, r in pairs(v) do
				--bags
					local db1, db2, db3 = strsplit(':', q)
				if db1 and db2 and db3 and tonumber(db2) then
						db2 = tonumber(db2)
					if db1 == 'bank' then
						if not(db2 == BANK_CONTAINER or (db2 >= NUM_BAG_SLOTS + 1) and (db2 <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS)) then
							BagSyncDB[realm][k][q] = nil
						end
					elseif db1 == 'bag' then
						if not(db2 >= BACKPACK_CONTAINER and db2 <= BACKPACK_CONTAINER + NUM_BAG_SLOTS) then
							BagSyncDB[realm][k][q] = nil
						end
					elseif db1 == 'key' then
						if not(db2 == KEYRING_CONTAINER) then
							BagSyncDB[realm][k][q] = nil
						end
					elseif db1 == 'equip' then
						if not(db2 >= 0 and db2 <= NUM_EQUIPMENT_SLOTS) then
							BagSyncDB[realm][k][q] = nil
						end
					end
				elseif q == 'guild' then
					storeGuilds[r] = true
				end
			end
		end
	end

	--guildbank data
	for realm, rd in pairs(BagSyncGUILD_DB) do
		--realm
		for k, v in pairs(rd) do
			--users
			if storeGuilds[k] then
				--only store the guild data if at least one character is in the guild
				for q, r in pairs(v) do
					--items
					local db1, db2, db3 = strsplit(':', q)
					if db1 and db2 and db3 and tonumber(db2) and tonumber(db3) then
						db2 = tonumber(db2)
						db3 = tonumber(db3)
						if not(db2 > 0 and db2 <= MAX_GUILDBANK_TABS) then
							--guild:tab:slot
							BagSyncGUILD_DB[realm][k][q] = nil
						elseif not(db3 > 0 and db3 <= MAX_GUILDBANK_SLOTS_PER_TAB) then
							--if it's not between 1-98 slot then delete it
							BagSyncGUILD_DB[realm][k][q] = nil
						end
					end
				end
			else
				--otherwise delete the guild
				BagSyncGUILD_DB[realm][k] = nil
			end
		end
	end
	
	--token data
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
				--token or points
				for x, y in pairs(v) do
					--token id or honor id
					if x ~= "name" and x ~= "icon" and x ~= "header" then
						if not storeUsers[realm][x] then
							--if the user doesn't exist then delete data
							BagSyncTOKEN_DB[realm][k][x] = nil
						end
					end
				end
			end
			
		end
	end
	
	DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33BagSync:|r |cFFFF9900"..L["A FixDB has been performed on BagSync!  The database is now optimized!"].."|r")
end

----------------------
--      Local       --
----------------------

local function GetBagSize(bagid)
	if bagid == KEYRING_CONTAINER then
		return GetKeyRingSize()
	end
	if bagid == 'equip' then
		return NUM_EQUIPMENT_SLOTS
	end
	return GetContainerNumSlots(bagid)
end

local function GetTag(bagname, bagid, slot)
	if bagname and bagid and slot then
		return bagname..':'..bagid..':'..slot
	else
		return nil
	end
end

--special thanks to tuller :)
local function ToShortLink(link)
	if link and type(link) == "string" then
		local a,b,c,d,e,f,g,h = link:match('(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+)')
		if(b == '0' and b == c and c == d and d == e and e == f and f == g) then
			return a
		end
		return format('item:%s:%s:%s:%s:%s:%s:%s:%s', a, b, c, d, e, f, g, h)
	end
	return nil
end

----------------------
--  Bag Functions   --
----------------------

function BagSync:SaveBag(bagname, bagid, rollupdate)
	if not BS_DB then self:StartupDB() end
	--this portion of the code will save the bag data, (type of bag, size of bag, bag item link, etc..)
	--this is used later to quickly grab bag data and size without having to go through the whole
	--song and dance again
	--bd = bagdata
	--Example ["bd:bagid:0"] = size, link, count
	local size = GetBagSize(bagid)
	local index = GetTag('bd', bagname, bagid)
	if not index then return nil end
	
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
			self:SaveItem(bagname, bagid, slot)
		end
	end
	
end

function BagSync:SaveItem(bagname, bagid, slot)
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
	else
		BS_DB[index] = nil
	end
end

function BagSync:OnBagUpdate(bagid)

	--do hunter check
	if not BagSync:DoHunterChecks() then return end

	--this will update the bank/bag slots
	local bagname

	--get the correct bag name based on it's id, trying NOT to use numbers as Blizzard may change bagspace in the future
	--so instead I'm using constants :)
	
	if bagid == -4 then
		--we don't want to deal with the token bag
		return
	elseif bagid == BANK_CONTAINER then
		bagname = 'bank'
	elseif (bagid >= NUM_BAG_SLOTS + 1) and (bagid <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS) then
		bagname = 'bank'
	elseif bagid == KEYRING_CONTAINER then
		bagname = 'key'
	elseif (bagid >= BACKPACK_CONTAINER) and (bagid <= BACKPACK_CONTAINER + NUM_BAG_SLOTS) then
		bagname = 'bag'
	else
		return nil
	end

	if self.atBank then
		--force an update of the primary bank container (which is -1, in case something was moved)
		--blizzard doesn't send a bag update for the -1 bank slot for some reason
		--true = forces a rollupdate to scan entire bag
		self:SaveBag('bank', BANK_CONTAINER, true)
	end
	
	--save the bag data in case it was changed
	self:SaveBag(bagname, bagid, false)

	--now save the item information in the bag
	for slot = 1, GetBagSize(bagid) do
		self:SaveItem(bagname, bagid, slot)
	end
end

function BagSync:SaveEquipment()

	--reset our tooltip data since we scanned new items (we want current data not old)
	lastItem = nil
	lastDisplayed = {}
	
	--do hunter check
	if not BagSync:DoHunterChecks(true) then return end
	
	for slot = 0, NUM_EQUIPMENT_SLOTS do
		local link = GetInventoryItemLink('player', slot)
		local index = GetTag('equip', 0, slot)

		if link then
			local linkItem = ToShortLink(link)
			local count =  GetInventoryItemCount('player', slot)
			count = count > 1 and count or nil

			if (linkItem and count) then
				--check for ranged slot ammo, don't add twice
				if slot == GetInventorySlotInfo("AmmoSlot") and count <= 1 then
					BS_DB[index] = format('%s,%d', linkItem, count)
				elseif slot ~= GetInventorySlotInfo("AmmoSlot") then
					BS_DB[index] = format('%s,%d', linkItem, count)
				end
			else
				BS_DB[index] = linkItem
			end
		else
			BS_DB[index] = nil
		end
	end
end

function BagSync:ScanEntireBank()
	--scan the primary Bank Bag -1, for some reason Blizzard never sends updates on it
	self:SaveBag('bank', BANK_CONTAINER, true)
	--NUM_BAG_SLOTS+1 to NUM_BAG_SLOTS+NUM_BANKBAGSLOTS are your bank bags 
	for i = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
		self:SaveBag('bank', i, true)
	end
end

function BagSync:ScanGuildBank()
	--GetCurrentGuildBankTab()
	if not IsInGuild() or not BS_DB.guild then return nil end
	
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

function BagSync:ScanMailbox()
	--this is to prevent buffer overflow from the CheckInbox() function calling ScanMailbox too much :)
	if BagSync.isCheckingMail then return end
	BagSync.isCheckingMail = true

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
				if BS_DB[delIndex] then
					BS_DB[delIndex] = nil
				end
			end
		end
	end
	
	--store our mail count regardless
	BS_DB[bChk] = mailCount

	BagSync.isCheckingMail = nil
end

function BagSync:DoHunterChecks(equipSwitch)
	--if not hunter return true, or if not in combat return true
	if playerClass ~= "HUNTER" then return true end
	if not UnitAffectingCombat("player") then return true end

	--this function is used to prevent scan spamming of the bags due to hunter ammo being used
	local currAmmo = (GetInventoryItemCount('player', 0) or 0)
	
	if not equipSwitch and ammoCount ~= currAmmo then
		return false
	elseif ammoCount ~= currAmmo then
		ammoCount = (GetInventoryItemCount('player', 0) or 0)
		return false
	end
	
	return true
end

------------------------
--   Money Tooltip    --
------------------------

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
		for q, r in pairs(BagSyncDB[currentRealm][k]) do
			if string.find(q, 'gold') then
				if r then
					table.insert(usrData, { name=k, gold=r } )
				end
			end
		end
	end
	
	table.sort(usrData, function(a,b) return (a.name < b.name) end)
	
	local gldTotal = 0
	
	for i=1, table.getn(usrData) do
		tooltip:AddDoubleLine(usrData[i].name, self:buildMoneyString(usrData[i].gold, false), 1, 1, 1, 1, 1, 1)
		gldTotal = gldTotal + usrData[i].gold
	end
	if BagSyncOpt.showTotal and gldTotal > 0 then
		tooltip:AddLine(" ")
		tooltip:AddDoubleLine(format(TTL_C, L["Total:"]), self:buildMoneyString(gldTotal, false), 1, 1, 1, 1, 1, 1)
	end
	
	tooltip:AddLine(" ")
	tooltip:Show()
end

function BagSync:buildMoneyString(money, color)
 
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

------------------------
--      Tokens        --
------------------------

function BagSync:ScanTokens()
	--LETS AVOID TOKEN SPAM AS MUCH AS POSSIBLE
	if doTokenUpdate == 1 then return end
	if BagSync:IsInBG() or BagSync:IsInArena() or InCombatLockdown() or UnitAffectingCombat("player") then
		--avoid (Honor point spam), avoid (arena point spam), if it's world PVP...well then it sucks to be you
		doTokenUpdate = 1
		BagSync:RegisterEvent('PLAYER_REGEN_ENABLED')
		return
	end

	local lastHeader
	
	for i=1, GetCurrencyListSize() do
		local name, isHeader, isExpanded, _, _, count, extraCurrencyType, icon, itemID = GetCurrencyListInfo(i)
		--extraCurrencyType = 1 for arena points, 2 for honor points; 0 otherwise (an item-based currency). 
		if name then
			if(isHeader and not isExpanded) then
				ExpandCurrencyList(i,1)
				lastHeader = name
			elseif isHeader then
				lastHeader = name
			end
			if (not isHeader) then
				if BS_TD and itemID then
					BS_TD = BS_TD or {}
					BS_TD[itemID] = BS_TD[itemID] or {}
					BS_TD[itemID].name = name
					BS_TD[itemID].icon = icon
					BS_TD[itemID].header = lastHeader
					BS_TD[itemID][currentPlayer] = count
				end
			end
		end
	end
	
end

function BagSync:AddTokenTooltip(self)
	if not self:GetParent().index then return end
	local _, _, _, _, _, _, _, _, itemID = GetCurrencyListInfo(self:GetParent().index)

	if not BS_TD then return end
	if not BS_TD[itemID] then return end
	
	tmp = {}
	for k, v in pairs(BS_TD[itemID]) do
		if k ~= "name" and k ~= "icon" and k ~= "header" then
			if v > 0 then
				table.insert(tmp, { name=k, count=v} )
			end
		end
	end
	
	if #tmp > 0 then
		table.sort(tmp, function(a,b) return (a.name < b.name) end)

		GameTooltip:AddLine(' ')
		for i=1, #tmp do
			GameTooltip:AddDoubleLine(format(MOSS, tmp[i].name), format(SILVER, tmp[i].count))
		end
		GameTooltip:Show()
	end
end

function BagSync:PLAYER_REGEN_ENABLED()
	if BagSync:IsInBG() or BagSync:IsInArena() or InCombatLockdown() or UnitAffectingCombat("player") then return end
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	--were out of an arena or battleground scan the points
	doTokenUpdate = 0
	self:ScanTokens()
end

function BagSync:IsInBG()
	if (GetNumBattlefieldScores() > 0) then
		return true
	end
	local status, mapName, instanceID, minlevel, maxlevel
	for i=1, MAX_BATTLEFIELD_QUEUES do
		status, mapName, instanceID, minlevel, maxlevel, teamSize = GetBattlefieldStatus(i)
		if status == "active" then
			return true
		end
	end
	return false
end

function BagSync:IsInArena()
	local a,b = IsActiveBattlefieldArena()
	if (a == nil) then
		return false
	end
	return true
end

--display in currency window tooltip, this is from Blizzard_TokenUI
hooksecurefunc("TokenFrame_Update", function()
	local buttons = TokenFrameContainer.buttons
	for i = 1, #buttons do
		local button = buttons[i]
		if not button.hookedOnEnter then
			button.LinkButton:HookScript("OnEnter", function(self) BagSync:AddTokenTooltip(self) end)
			button.hookedOnEnter = true
		end
	end
end)

hooksecurefunc("BackpackTokenFrame_Update", BagSync.ScanTokens)

------------------------
--      Tooltip!      --
-- (Special thanks to tuller)
------------------------

local function CountsToInfoString(invCount, bankCount, equipCount, guildCount, mailboxCount)
	local info
	local total = invCount + bankCount + equipCount + guildCount + mailboxCount

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
	
	if info then
		if total and not(total == invCount or total == bankCount or total == equipCount or total == guildCount or total == mailboxCount) then
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
	
	local itemLink = ToShortLink(link)
	if not itemLink then
		frame:Show()
		return
	end

	--ignore the hearthstone
	if itemLink and tonumber(itemLink) and tonumber(itemLink) == 6948 then
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
		local invCount, bankCount, equipCount, guildCount, mailboxCount = 0, 0, 0, 0, 0
		
		--now count the stuff for the user
		for q, r in pairs(v) do
			if itemLink then
				local dblink, dbcount = strsplit(',', r)
				if dblink then
					if string.find(q, 'bank') and dblink == itemLink then
						bankCount = bankCount + (dbcount or 1)
					elseif string.find(q, 'bag') and dblink == itemLink then
						invCount = invCount + (dbcount or 1)
					elseif string.find(q, 'key') and dblink == itemLink then
						invCount = invCount + (dbcount or 1)
					elseif string.find(q, 'equip') and dblink == itemLink then
						equipCount = equipCount + (dbcount or 1)
					elseif string.find(q, 'mailbox') and dblink == itemLink then
						mailboxCount = mailboxCount + (dbcount or 1)
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
		local pClass = v["class:0:0"] or nil
		
		infoString = CountsToInfoString(invCount or 0, bankCount or 0, equipCount or 0, guildCount or 0, mailboxCount or 0)
		grandTotal = grandTotal + (invCount or 0) + (bankCount or 0) + (equipCount or 0) + (guildCount or 0) + (mailboxCount or 0)
		
		if infoString and infoString ~= '' then
			frame:AddDoubleLine(getNameColor(k, pClass), infoString)
			table.insert(lastDisplayed, getNameColor(k or 'Unknown', pClass).."@"..(infoString or 'unknown'))
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

local function HookTip(tooltip)
	tooltip:HookScript('OnTooltipSetItem', function(self, ...)
		local _, itemLink = self:GetItem()
		if itemLink and GetItemInfo(itemLink) then
			local itemName = GetItemInfo(itemLink)
			if BagSyncOpt.enableThrottle then
				if not self.BagSyncThrottle then self.BagSyncThrottle = GetTime() end
				if not self.BagSyncPrevious then self.BagSyncPrevious = itemName end
				if not self.BagSyncShowOnce and self:GetName() == "GameTooltip" then self.BagSyncShowOnce = true end
				
				if itemName ~= self.BagSyncPrevious then
					self.BagSyncPrevious = itemName
					self.BagSyncThrottle = GetTime()
				end
				if self:GetName() == "GameTooltip" and (GetTime() - self.BagSyncThrottle) >= 0.05 then
					self.BagSyncShowOnce = nil
					AddOwners(self, itemLink)
				elseif self:GetName() ~= "GameTooltip" then
					self.BagSyncShowOnce = nil
					AddOwners(self, itemLink)
				end
			else
				AddOwners(self, itemLink)
			end
		end
	end)
	
	tooltip:HookScript('OnUpdate', function(self, ...)
		if self:GetName() == "GameTooltip" and self.BagSyncShowOnce and self.BagSyncThrottle and (GetTime() - self.BagSyncThrottle) >= 0.05 then
			local _, itemLink = self:GetItem()
			self.BagSyncShowOnce = nil
			if itemLink then
				AddOwners(self, itemLink)
			end
		end
	end)
end

HookTip(GameTooltip)
HookTip(ItemRefTooltip)

