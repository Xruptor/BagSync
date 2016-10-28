--[[
	BagSync.lua
		A item tracking addon that works with practically any bag addon available.
		This addon has been heavily rewritten several times since it's creation back in 2007.
		
		This addon was inspired by Tuller and his Bagnon addon.  (Thanks Tuller!)

	Author: Xruptor

--]]

local BSYC = select(2, ...) --grab the addon namespace
BSYC = LibStub("AceAddon-3.0"):NewAddon(BSYC, "BagSync", "AceEvent-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync", true)

local debugf = tekDebug and tekDebug:GetFrame("BagSync")

function BSYC:Debug(...)
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
		if button == "LeftButton" then
			BSYC:GetModule("Search").frame:Show()
		elseif button == "RightButton" then
			if bgsMinimapDD then
				ToggleDropDownMenu(1, nil, bgsMinimapDD, "cursor", 0, 0)
			end
		end
	end,

	OnTooltipShow = function(self)
		self:AddLine("BagSync")
		self:AddLine(L.LeftClickSearch)
		self:AddLine(L.RightClickBagSyncMenu)
	end
})

----------------------
--      Local       --
----------------------

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

local function tooltipColor(color, str)
	return string.format("|cff%02x%02x%02x%s|r", (color.r or 1) * 255, (color.g or 1) * 255, (color.b or 1) * 255, tostring(str))
end

local function ParseItemLink(link)
	if not link then return nil end
	if tonumber(link) then return link end
	local result = link:match("item:([%d:]+)") --strip the item: portion of the string
	
	if result then
		result = gsub(result, ":0:", "::") --supposedly blizzard removed all the zero's in patch 7.0. Lets do it just in case!
		--split everything into a table so we can count up to the bonusID portion
		local countSplit = {strsplit(":", result)}
		
		--make sure we have a bonusID count
		if countSplit and #countSplit > 13 then
			local count = countSplit[13] or 0 -- do we have a bonusID number count?
			count = count == "" and 0 or count --make sure we have a count if not default to zero
			count = tonumber(count)
			
			--check if we have even anything to work with for the amount of bonusID's
			--btw any numbers after the bonus ID are either upgradeValue which we don't care about or unknown use right now
			--http://wow.gamepedia.com/ItemString
			if count > 0 and countSplit[1] then
				--return the string with just the bonusID's in it
				local newItemStr = ""
				
				--11th place because 13 is bonus ID, one less from 13 (12) would be technically correct, but we have to compensate for ItemID we added in front so substract another one (11).
				--string.rep repeats a pattern.
				newItemStr = countSplit[1]..string.rep(":", 11)
				
				--lets add the bonusID's, ignore the end past bonusID's
				for i=13, (13 + count) do
					--check for certain bonus ID's
					if i == 14 and tonumber(countSplit[i]) == 3407 then
						--the tradeskill window returns a 1:3407 for bonusID on regeant info and craft item in C_TradeSkillUI, ignore it
						return result:match("^(%d+):")
					end
					newItemStr = newItemStr..":"..countSplit[i]
				end
				
				--add the unknowns at the end, upgradeValue doesn't always have to be supplied.
				newItemStr = newItemStr..":::"

				return newItemStr
			end
		end
		
		--we don't have any bonusID's that we care about, so return just the ItemID which is the first number
		return result:match("^(%d+):")
	end
	
	--nothing to return so return nil
	return nil
end

local function ToShortItemID(link)
	if not link then return nil end
	if tonumber(link) then return link end
	link = gsub(link, ":0:", "::")
	return link:match("^(%d+):") or nil
end

local function IsInBG()
	if (GetNumBattlefieldScores() > 0) then
		return true
	end
	return false
end

local function IsInArena()
	local a,b = IsActiveBattlefieldArena()
	if not a then
		return false
	end
	return true
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

----------------------
--   DB Functions   --
----------------------

function BSYC:StartupDB()

	BagSyncOpt = BagSyncOpt or {}
	self.options = BagSyncOpt
	
	if self.options.showTotal == nil then self.options.showTotal = true end
	if self.options.showGuildNames == nil then self.options.showGuildNames = false end
	if self.options.enableGuild == nil then self.options.enableGuild = true end
	if self.options.enableMailbox == nil then self.options.enableMailbox = true end
	if self.options.enableUnitClass == nil then self.options.enableUnitClass = false end
	if self.options.enableMinimap == nil then self.options.enableMinimap = true end
	if self.options.enableFaction == nil then self.options.enableFaction = true end
	if self.options.enableAuction == nil then self.options.enableAuction = true end
	if self.options.tooltipOnlySearch == nil then self.options.tooltipOnlySearch = false end
	if self.options.enableTooltips == nil then self.options.enableTooltips = true end
	if self.options.enableTooltipSeperator == nil then self.options.enableTooltipSeperator = true end
	if self.options.enableCrossRealmsItems == nil then self.options.enableCrossRealmsItems = true end
	if self.options.enableBNetAccountItems == nil then self.options.enableBNetAccountItems = false end
	if self.options.enableTooltipItemID == nil then self.options.enableTooltipItemID = false end
	if self.options.enableTooltipGreenCheck == nil then self.options.enableTooltipGreenCheck = true end
	if self.options.enableRealmIDTags == nil then self.options.enableRealmIDTags = true end
	if self.options.enableRealmAstrickName == nil then self.options.enableRealmAstrickName = false end
	if self.options.enableRealmShortName == nil then self.options.enableRealmShortName = false end
	if self.options.enableLoginVersionInfo == nil then self.options.enableLoginVersionInfo = true end
	
	--setup the default colors
	if self.options.colors == nil then self.options.colors = {} end
	if self.options.colors.first == nil then self.options.colors.first = { r = 128/255, g = 1, b = 0 }  end
	if self.options.colors.second == nil then self.options.colors.second = { r = 1, g = 1, b = 1 }  end
	if self.options.colors.total == nil then self.options.colors.total = { r = 244/255, g = 164/255, b = 96/255 }  end
	if self.options.colors.guild == nil then self.options.colors.guild = { r = 101/255, g = 184/255, b = 192/255 }  end
	if self.options.colors.cross == nil then self.options.colors.cross = { r = 1, g = 125/255, b = 10/255 }  end
	if self.options.colors.bnet == nil then self.options.colors.bnet = { r = 53/255, g = 136/255, b = 1 }  end
	if self.options.colors.itemid == nil then self.options.colors.itemid = { r = 82/255, g = 211/255, b = 134/255 }  end

	self.db = {}
	
	--initiate global db variable
	BagSyncDB = BagSyncDB or {}
	self.db.global = BagSyncDB
	
	--the player DB defaults to the current realm, if you want more then you need to use db.global
	BagSyncDB[self.currentRealm] = BagSyncDB[self.currentRealm] or {}
	BagSyncDB[self.currentRealm][self.currentPlayer] = BagSyncDB[self.currentRealm][self.currentPlayer] or {}
	self.db.player = BagSyncDB[self.currentRealm][self.currentPlayer]
	
	BagSyncGUILD_DB = BagSyncGUILD_DB or {}
	BagSyncGUILD_DB[self.currentRealm] = BagSyncGUILD_DB[self.currentRealm] or {}
	self.db.guild = BagSyncGUILD_DB

	BagSyncCURRENCY_DB = BagSyncCURRENCY_DB or {}
	BagSyncCURRENCY_DB[self.currentRealm] = BagSyncCURRENCY_DB[self.currentRealm] or {}
	self.db.currency = BagSyncCURRENCY_DB
	
	BagSyncPROFESSION_DB = BagSyncPROFESSION_DB or {}
	BagSyncPROFESSION_DB[self.currentRealm] = BagSyncPROFESSION_DB[self.currentRealm] or {}
	BagSyncPROFESSION_DB[self.currentRealm][self.currentPlayer] = BagSyncPROFESSION_DB[self.currentRealm][self.currentPlayer] or {}
	self.db.profession = BagSyncPROFESSION_DB
	
	BagSyncBLACKLIST_DB = BagSyncBLACKLIST_DB or {}
	BagSyncBLACKLIST_DB[self.currentRealm] = BagSyncBLACKLIST_DB[self.currentRealm] or {}
	self.db.blacklist = BagSyncBLACKLIST_DB
	
	BagSync_REALMKEY = BagSync_REALMKEY or {}
	BagSync_REALMKEY[self.currentRealm] = GetRealmName()
	BagSync_REALMKEY[0] = BagSync_REALMKEY[0] or {} --this will maintain a list of connected realms
	self.db.realmkey = BagSync_REALMKEY
	
end

function BSYC:FixDB(onlyChkGuild)
	--Removes obsolete character information
	--Removes obsolete guild information
	--Removes obsolete characters from currency db
	--Removes obsolete profession information
	--removes obsolete blacklist information
	--Will only check guild related information if the paramater is passed as true
	--Adds realm name to characters profiles if missing, v8.6

	local storeUsers = {}
	local storeGuilds = {}
	
	for realm, rd in pairs(BagSyncDB) do
		if string.find(realm, " ") then
			--get rid of old realm names with whitespaces, we aren't going to use it anymore
			BagSyncDB[realm] = nil
		else
			--realm
			storeUsers[realm] = storeUsers[realm] or {}
			storeGuilds[realm] = storeGuilds[realm] or {}
			for k, v in pairs(rd) do
				--users
				storeUsers[realm][k] = storeUsers[realm][k] or 1
				if v.realm == nil then v.realm = realm end  --Adds realm name to characters profiles if missing, v8.6
				for q, r in pairs(v) do
					if q == "guild" then
						storeGuilds[realm][r] = true
					end
				end
			end
		end
	end

	--guildbank data
	for realm, rd in pairs(BagSyncGUILD_DB) do
		if string.find(realm, " ") then
			--get rid of old realm names with whitespaces, we aren't going to use it anymore
			BagSyncGUILD_DB[realm] = nil
		else
			--realm
			for k, v in pairs(rd) do
				--users
				if not storeGuilds[realm][k] then
					--delete the guild because no one has it
					BagSyncGUILD_DB[realm][k] = nil
				end
			end
		end
	end
	
	--currency data and profession data, only do if were not doing a guild check
	--also display fixdb message only if were not doing a guild check
	if not onlyChkGuild then
	
		--fix currency
		for realm, rd in pairs(BagSyncCURRENCY_DB) do
			if string.find(realm, " ") then
				--get rid of old realm names with whitespaces, we aren't going to use it anymore
				BagSyncCURRENCY_DB[realm] = nil
			else
				--realm
				if not storeUsers[realm] then
					--if it's not a realm that ANY users are on then delete it
					BagSyncCURRENCY_DB[realm] = nil
				else
					for k, v in pairs(rd) do
						if not storeUsers[realm][k] then
							--if the user doesn't exist then delete data
							BagSyncCURRENCY_DB[realm][k] = nil
						end
					end
				end
			end
		end

		--fix professions
		for realm, rd in pairs(BagSyncPROFESSION_DB) do
			if string.find(realm, " ") then
				--get rid of old realm names with whitespaces, we aren't going to use it anymore
				BagSyncPROFESSION_DB[realm] = nil
			else
				--realm
				if not storeUsers[realm] then
					--if it's not a realm that ANY users are on then delete it
					BagSyncPROFESSION_DB[realm] = nil
				else
					for k, v in pairs(rd) do
						if not storeUsers[realm][k] then
							--if the user doesn't exist then delete data
							BagSyncPROFESSION_DB[realm][k] = nil
						end
					end
				end
			end
		end
		
		--fix blacklist
		for realm, rd in pairs(BagSyncBLACKLIST_DB) do
			if string.find(realm, " ") then
				--get rid of old realm names with whitespaces, we aren't going to use it anymore
				BagSyncBLACKLIST_DB[realm] = nil
			else
				--realm
				if not storeUsers[realm] then
					--if it's not a realm that ANY users are on then delete it
					BagSyncBLACKLIST_DB[realm] = nil
				end
			end
		end
		
		if BagSyncCRAFT_DB then BagSyncCRAFT_DB = nil end --remove old crafting DB
		if BagSyncTOKEN_DB then BagSyncTOKEN_DB = nil end --remove old tokens db
		
		self:Print("|cFFFF9900"..L.FixDBComplete.."|r")
	end
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

function BSYC:FilterDB(dbSelect)

	local xIndex = {}
	local dbObj = self.db.global
	
	if dbSelect and dbSelect == 1 then
		--use BagSyncPROFESSION_DB
		dbObj = self.db.profession
	elseif dbSelect and dbSelect == 2 then
		--use BagSyncCURRENCY_DB
		dbObj = self.db.currency
	end

	--add more realm names if necessary based on BNet or Cross Realms
	if self.options.enableBNetAccountItems then
		for k, v in pairs(dbObj) do
			for q, r in pairs(v) do
				--we do this incase there are multiple characters with same name
				xIndex[q.."^"..k] = r
			end
		end
	elseif self.options.enableCrossRealmsItems then
		for k, v in pairs(dbObj) do
			if k == self.currentRealm or self.crossRealmNames[k] then
				for q, r in pairs(v) do
					----we do this incase there are multiple characters with same name
					xIndex[q.."^"..k] = r
				end
			end
		end
	else
		--do only the current realm if they don't have anything else configured
		for k, v in pairs(dbObj) do
			if k == self.currentRealm then
				for q, r in pairs(v) do
					----can't have multiple characters on same realm, but we need formatting anyways
					xIndex[q.."^"..k] = r
				end
			end
		end
	end
	
	return xIndex
end

function BSYC:GetRealmTags(srcName, srcRealm, isGuild)
	
	local fullRealmName = srcRealm --default to shortened realm first
	
	if self.db.realmkey[srcRealm] then fullRealmName = self.db.realmkey[srcRealm] end --second, if we have a realmkey with a true realm name then use it
	
	if not isGuild then
		local ReadyCheck = [[|TInterface\RaidFrame\ReadyCheck-Ready:0|t]]
		--local NotReadyCheck = [[|TInterface\RaidFrame\ReadyCheck-NotReady:0|t]]
		
		--put a green check next to the currently logged in character name
		if srcName == self.currentPlayer and self.options.enableTooltipGreenCheck then
			srcName = srcName.." "..ReadyCheck
		end
	else
		--sometimes a person has characters on multiple connected servers joined to the same guild.
		--the guild information is saved twice because although the guild is on the connected server, the characters themselves are on different servers.
		--too compensate for this, lets check the connected server and return only the guild name.  So it doesn't get processed twice.
		for k, v in pairs(self.crossRealmNames) do
			--check to see if the guild exists already on a connected realm and not the current realm
			if k ~= srcRealm and self.db.guild[k] and self.db.guild[k][srcName] then
				--return non-modified guild name, we only want the guild listed once for the cross-realm
				return srcName
			end
		end
	end
	
	--add Cross-Realm and BNet identifiers to Characters not on same realm
	local crossString = ""
	local bnetString = ""
	
	if self.options.enableRealmIDTags then
		crossString = "XR-"
		bnetString = "BNet-"
	end
	
	if self.options.enableRealmAstrickName then
		fullRealmName = "*"
	elseif self.options.enableRealmShortName then
		fullRealmName = string.sub(fullRealmName, 1, 5) --only use 5 characters of the server name
	end
	
	if self.options.enableBNetAccountItems then
		if srcRealm and srcRealm ~= self.currentRealm then
			if not self.crossRealmNames[srcRealm] then
				srcName = srcName.." "..rgbhex(self.options.colors.bnet).."["..bnetString..fullRealmName.."]|r"
			else
				srcName = srcName.." "..rgbhex(self.options.colors.cross).."["..crossString..fullRealmName.."]|r"
			end
		end
	elseif self.options.enableCrossRealmsItems then
		if srcRealm and srcRealm ~= self.currentRealm then
			srcName = srcName.." "..rgbhex(self.options.colors.cross).."["..crossString..fullRealmName.."]|r"
		end
	end
		
	return srcName
end

----------------------
--  Bag Functions   --
----------------------

function BSYC:SaveBag(bagname, bagid)
	if not bagname or not bagid then return end
	self.db.player[bagname] = self.db.player[bagname] or {}
	
	--reset our tooltip data since we scanned new items (we want current data not old)
	self.PreviousItemLink = nil
	self.PreviousItemTotals = {}

	if GetContainerNumSlots(bagid) > 0 then
		local slotItems = {}
		for slot = 1, GetContainerNumSlots(bagid) do
			local _, count, _,_,_,_, link = GetContainerItemInfo(bagid, slot)
			if ParseItemLink(link) then
				count = (count > 1 and count) or nil
				if count then
					slotItems[slot] = format("%s,%d", ParseItemLink(link), count)
				else
					slotItems[slot] = ParseItemLink(link)
				end
			end
		end
		self.db.player[bagname][bagid] = slotItems
	else
		self.db.player[bagname][bagid] = nil
	end
end

function BSYC:SaveEquipment()
	self.db.player["equip"] = self.db.player["equip"] or {}
	
	--reset our tooltip data since we scanned new items (we want current data not old)
	self.PreviousItemLink = nil
	self.PreviousItemTotals = {}
	
	local slotItems = {}
	local NUM_EQUIPMENT_SLOTS = 19
	
	--start at 1, 0 used to be the old range slot (not needed anymore)
	for slot = 1, NUM_EQUIPMENT_SLOTS do
		local link = GetInventoryItemLink("player", slot)
		if link and ParseItemLink(link) then
			local count =  GetInventoryItemCount("player", slot)
			count = (count and count > 1) or nil
			if count then
				slotItems[slot] = format("%s,%d", ParseItemLink(link), count)
			else
				slotItems[slot] = ParseItemLink(link)
			end
		end
	end
	self.db.player["equip"][0] = slotItems
end

function BSYC:ScanEntireBank()
	--force scan of bank bag -1, since blizzard never sends updates for it
	self:SaveBag("bank", BANK_CONTAINER)
	for i = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
		self:SaveBag("bank", i)
	end
	if IsReagentBankUnlocked() then 
		self:SaveBag("reagentbank", REAGENTBANK_CONTAINER)
	end
end

function BSYC:ScanVoidBank()
	if not self.atVoidBank then return end
	
	self.db.player["void"] = self.db.player["void"] or {}

	--reset our tooltip data since we scanned new items (we want current data not old)
	self.PreviousItemLink = nil
	self.PreviousItemTotals = {}

	local numTabs = 2
	local index = 0
	local slotItems = {}
	
	for tab = 1, numTabs do
		for i = 1, 80 do
			local itemID, textureName, locked, recentDeposit, isFiltered = GetVoidItemInfo(tab, i)
			if (itemID) then
				index = index + 1
				slotItems[index] = itemID and tostring(itemID) or nil
			end
		end
	end
	
	self.db.player["void"][0] = slotItems
end

function BSYC:ScanGuildBank()
	if not IsInGuild() then return end
	
	local MAX_GUILDBANK_SLOTS_PER_TAB = 98
	
	--reset our tooltip data since we scanned new items (we want current data not old)
	self.PreviousItemLink = nil
	self.PreviousItemTotals = {}
	
	local numTabs = GetNumGuildBankTabs()
	local index = 0
	local slotItems = {}
	
	for tab = 1, numTabs do
		local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals = GetGuildBankTabInfo(tab)
		--if we don't check for isViewable we get a weirdo permissions error for the player when they attempt it
		if isViewable then
			for slot = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
			
				local link = GetGuildBankItemLink(tab, slot)

				if link and ParseItemLink(link) then
					index = index + 1
					local _, count = GetGuildBankItemInfo(tab, slot)
					count = (count > 1 and count) or nil
					
					if count then
						slotItems[index] = format("%s,%d", ParseItemLink(link), count)
					else
						slotItems[index] = ParseItemLink(link)
					end
				end
			end
		end
	end
	
	self.db.guild[self.currentRealm][self.db.player.guild] = slotItems
	
end

function BSYC:ScanMailbox()
	--this is to prevent buffer overflow from the CheckInbox() function calling ScanMailbox too much :)
	if self.isCheckingMail then return end
	self.isCheckingMail = true

	 --used to initiate mail check from server, for some reason GetInboxNumItems() returns zero sometimes
	 --even though the user has mail in the mailbox.  This can be attributed to lag.
	CheckInbox()

	self.db.player["mailbox"] = self.db.player["mailbox"] or {}
	
	local slotItems = {}
	local mailCount = 0
	local numInbox = GetInboxNumItems()

	--reset our tooltip data since we scanned new items (we want current data not old)
	self.PreviousItemLink = nil
	self.PreviousItemTotals = {}
	
	--scan the inbox
	if (numInbox > 0) then
		for mailIndex = 1, numInbox do
			for i=1, ATTACHMENTS_MAX_RECEIVE do
				local name, itemID, itemTexture, count, quality, canUse = GetInboxItem(mailIndex, i)
				local link = GetInboxItemLink(mailIndex, i)
				
				if name and link and ParseItemLink(link) then
					mailCount = mailCount + 1
					count = (count > 1 and count) or nil
					if count then
						slotItems[mailCount] = format("%s,%d", ParseItemLink(link), count)
					else
						slotItems[mailCount] = ParseItemLink(link)
					end
				end
			end
		end
	end
	
	self.db.player["mailbox"][0] = slotItems
	self.isCheckingMail = false
end

function BSYC:ScanAuctionHouse()
	self.db.player["auction"] = self.db.player["auction"] or {}
	
	local slotItems = {}
	local ahCount = 0
	local numActiveAuctions = GetNumAuctionItems("owner")
	
	--reset our tooltip data since we scanned new items (we want current data not old)
	self.PreviousItemLink = nil
	self.PreviousItemTotals = {}
	
	--scan the auction house
	if (numActiveAuctions > 0) then
		for ahIndex = 1, numActiveAuctions do
			local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner, saleStatus  = GetAuctionItemInfo("owner", ahIndex)
			if name then
				local link = GetAuctionItemLink("owner", ahIndex)
				local timeLeft = GetAuctionItemTimeLeft("owner", ahIndex)
				if link and ParseItemLink(link) and timeLeft then
					ahCount = ahCount + 1
					count = (count or 1)
					slotItems[ahCount] = format("%s,%s,%s", ParseItemLink(link), count, timeLeft)
				end
			end
		end
	end
	
	self.db.player["auction"][0] = slotItems
	self.db.player.AH_Count = ahCount
end

------------------------
--   Money Tooltip    --
------------------------

function BSYC:CreateMoneyString(money, color)
 
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
	local xDB = self:FilterDB()

	for k, v in pairs(xDB) do
		local yName, yRealm  = strsplit("^", k)
		local playerName = BSYC:GetRealmTags(yName, yRealm)
		
		if v.gold then
			playerName = self:GetClassColor(playerName or "Unknown", v.class)
			table.insert(usrData, { name=playerName, gold=v.gold } )
		end
	end
	table.sort(usrData, function(a,b) return (a.name < b.name) end)
	
	local gldTotal = 0
	
	for i=1, table.getn(usrData) do
		tooltip:AddDoubleLine(usrData[i].name, self:CreateMoneyString(usrData[i].gold, false), 1, 1, 1, 1, 1, 1)
		gldTotal = gldTotal + usrData[i].gold
	end
	if self.options.showTotal and gldTotal > 0 then
		tooltip:AddLine(" ")
		tooltip:AddDoubleLine(tooltipColor(self.options.colors.total, L.TooltipTotal), self:CreateMoneyString(gldTotal, false), 1, 1, 1, 1, 1, 1)
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
	if IsInBG() or IsInArena() or InCombatLockdown() or UnitAffectingCombat("player") then
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
				self.db.currency[self.currentRealm][self.currentPlayer] = self.db.currency[self.currentRealm][self.currentPlayer] or {}
				self.db.currency[self.currentRealm][self.currentPlayer][name] = {}
				self.db.currency[self.currentRealm][self.currentPlayer][name].count = count
				self.db.currency[self.currentRealm][self.currentPlayer][name].header = lastHeader
				self.db.currency[self.currentRealm][self.currentPlayer][name].icon = icon
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
			info = info..L.TooltipDelimiter..tooltipColor(self.options.colors.first, list[i][2]).." "..tooltipColor(self.options.colors.second, count)
			total = total + count
		end
	end

	--remove the first delimiter since it's added to the front automatically
	info = strsub(info, string.len(L.TooltipDelimiter) + 1)
	if string.len(info) < 1 then return nil end --return nil for empty strings
	
	--if it's groupped up and has more then one item then use a different color and show total
	if grouped > 1 then
		info = tooltipColor(self.options.colors.second, total).." ("..info..")"
	end
	
	return info
end

function BSYC:GetClassColor(sName, sClass)
	if not self.options.enableUnitClass then
		return tooltipColor(self.options.colors.first, sName)
	else
		if sName ~= "Unknown" and sClass and RAID_CLASS_COLORS[sClass] then
			return rgbhex(RAID_CLASS_COLORS[sClass])..sName.."|r"
		end
	end
	return tooltipColor(self.options.colors.first, sName)
end

function BSYC:AddCurrencyTooltip(frame, currencyName, addHeader)
	if not BagSyncOpt.enableTooltips then return end
	
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
		if self.options.enableTooltipSeperator and not addHeader then
			frame:AddLine(" ")
		end
		if addHeader then
			local color = { r = 64/255, g = 224/255, b = 208/255 } --same color as header in Currency window
			frame:AddLine(rgbhex(color)..currencyName.."|r")
		end
		for i=1, #tmp do
			frame:AddDoubleLine(tooltipColor(BagSyncOpt.colors.first, tmp[i].name), tooltipColor(BagSyncOpt.colors.second, tmp[i].count))
		end
	end
	
	frame:Show()
end

function BSYC:AddItemToTooltip(frame, link) --workaround
	if not BagSyncOpt.enableTooltips then return end
	
	--if we can't convert the item link then lets just ignore it altogether	
	local itemLink = ParseItemLink(link)
	if not itemLink then
		frame:Show()
		return
	end
	
	--use our stripped itemlink, not the full link
	local shortItemID = ToShortItemID(itemLink)

	--only show tooltips in search frame if the option is enabled
	if self.options.tooltipOnlySearch and frame:GetOwner() and frame:GetOwner():GetName() and string.sub(frame:GetOwner():GetName(), 1, 16) ~= "BagSyncSearchRow" then
		frame:Show()
		return
	end
	
	local permIgnore ={
		[6948] = "Hearthstone",
		[110560] = "Garrison Hearthstone",
		[140192] = "Dalaran Hearthstone",
		[128353] = "Admiral's Compass",
	}
	
	--ignore the hearthstone and blacklisted items
	if shortItemID and tonumber(shortItemID) then
		if permIgnore[tonumber(shortItemID)] or self.db.blacklist[self.currentRealm][tonumber(shortItemID)] then
			frame:Show()
			return
		end
	end
	
	--lag check (check for previously displayed data) if so then display it
	if self.PreviousItemLink and itemLink and itemLink == self.PreviousItemLink then
		if table.getn(self.PreviousItemTotals) > 0 then
			for i = 1, #self.PreviousItemTotals do
				local ename, ecount  = strsplit("@", self.PreviousItemTotals[i])
				if ename and ecount then
					local color = self.options.colors.total
					frame:AddDoubleLine(ename, ecount, color.r, color.g, color.b, color.r, color.g, color.b)
				else
					local color = self.options.colors.second
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
			["void"] = 0,
			["auction"] = 0,
			["guild"] = 0,
		}
	
		local infoString
		local pFaction = v.faction or self.playerFaction --just in case ;) if we dont know the faction yet display it anyways
		
		--check if we should show both factions or not
		if self.options.enableFaction or pFaction == self.playerFaction then
		
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
								if dblink and dblink == itemLink then
									allowList[q] = allowList[q] + (dbcount or 1)
									grandTotal = grandTotal + (dbcount or 1)
								end
							end
						end
					end
				end
			end
		
			if self.options.enableGuild then
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
							if dblink and dblink == itemLink then
								--if we have show guild names then don't show any guild info for the character, otherwise it gets repeated twice
								if not self.options.showGuildNames then
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
	if self.options.enableGuild and self.options.showGuildNames then
		for k, v in pairsByKeys(previousGuilds) do
			--only print stuff higher then zero
			if v > 0 then
				table.insert(self.PreviousItemTotals, tooltipColor(self.options.colors.guild, k).."@"..tooltipColor(self.options.colors.second, v))
			end
		end
	end
	
	--show grand total if we have something
	--don't show total if there is only one item
	if self.options.showTotal and grandTotal > 0 and getn(self.PreviousItemTotals) > 1 then
		table.insert(self.PreviousItemTotals, tooltipColor(self.options.colors.total, L.TooltipTotal).."@"..tooltipColor(self.options.colors.second, grandTotal))
	end
	
	--add ItemID if it's enabled
	if table.getn(self.PreviousItemTotals) > 0 and self.options.enableTooltipItemID and shortItemID and tonumber(shortItemID) then
		table.insert(self.PreviousItemTotals, 1 , tooltipColor(self.options.colors.itemid, L.TooltipItemID).." "..tooltipColor(self.options.colors.second, shortItemID))
	end
	
	--now check for seperater and only add if we have something in the table already
	if table.getn(self.PreviousItemTotals) > 0 and self.options.enableTooltipSeperator then
		table.insert(self.PreviousItemTotals, 1 , " ")
	end
	
	--add it all together now
	if table.getn(self.PreviousItemTotals) > 0 then
		for i = 1, #self.PreviousItemTotals do
			local ename, ecount  = strsplit("@", self.PreviousItemTotals[i])
			if ename and ecount then
				local color = self.options.colors.total
				frame:AddDoubleLine(ename, ecount, color.r, color.g, color.b, color.r, color.g, color.b)
			else
				local color = self.options.colors.second
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

		if link and ParseItemLink(link) then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
			return
		end
		--sometimes we have a tooltip but no link because GetItem() returns nil, this is the case for recipes
		--so lets try something else to see if we can get the link.  Doesn't always work!  Thanks for breaking GetItem() Blizzard... you ROCK! :P
		if not self.isModified and self.lastHyperLink then
			local xName, xLink = GetItemInfo(self.lastHyperLink)
			--local title = _G[tooltip:GetName().."TextLeft1"]
			-- if xName and xLink and title and title:GetText() and title:GetText() == xName and ParseItemLink(xLink) then  --only show info if the tooltip text matches the link
				-- self.isModified = true
				-- BSYC:AddItemToTooltip(self, xLink)
			-- end
			if xLink and ParseItemLink(xLink) then  --only show info if the tooltip text matches the link
				self.isModified = true
				BSYC:AddItemToTooltip(self, xLink)
			end		
		end
	end)

	---------------------------------
	--Special thanks to GetItem() being broken we need to capture the ItemLink before the tooltip shows sometimes
	hooksecurefunc(tooltip, "SetBagItem", function(self, tab, slot)
		local link = GetContainerItemLink(tab, slot)
		if link and ParseItemLink(link) then
			self.lastHyperLink = link
		end
	end)
	hooksecurefunc(tooltip, "SetInventoryItem", function(self, tab, slot)
		local link = GetInventoryItemLink(tab, slot)
		if link and ParseItemLink(link) then
			self.lastHyperLink = link
		end
	end)
	hooksecurefunc(tooltip, "SetGuildBankItem", function(self, tab, slot)
		local link = GetGuildBankItemLink(tab, slot)
		if link and ParseItemLink(link) then
			self.lastHyperLink = link
		end
	end)
	hooksecurefunc(tooltip, "SetHyperlink", function(self, link)
		if self.isModified then return end
		if link and ParseItemLink(link) then
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
		if link and ParseItemLink(link) then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	hooksecurefunc(tooltip, "SetVoidDepositItem", function(self, slot)
		if self.isModified then return end
		local link = GetVoidTransferDepositInfo(slot)
		if link and ParseItemLink(link) then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	hooksecurefunc(tooltip, "SetVoidWithdrawalItem", function(self, slot)
		if self.isModified then return end
		local link = GetVoidTransferWithdrawalInfo(slot)
		if link and ParseItemLink(link) then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	hooksecurefunc(tooltip, "SetRecipeReagentItem", function(self, recipeID, reagentIndex)
		if self.isModified then return end
		local link = C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, reagentIndex)
		if link and ParseItemLink(link) then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	hooksecurefunc(tooltip, "SetRecipeResultItem", function(self, recipeID)
		if self.isModified then return end
		local link = C_TradeSkillUI.GetRecipeItemLink(recipeID)
		if link and ParseItemLink(link) then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)	
	hooksecurefunc(tooltip, "SetQuestLogItem", function(self, itemType, index)
		if self.isModified then return end
		local link = GetQuestLogItemLink(itemType, index)
		if link and ParseItemLink(link) then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	hooksecurefunc(tooltip, "SetQuestItem", function(self, itemType, index)
		if self.isModified then return end
		local link = GetQuestItemLink(itemType, index)
		if link and ParseItemLink(link) then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)	
	-- hooksecurefunc(tooltip, 'SetItemByID', function(self, link)
		-- if self.isModified or not BagSyncOpt.enableTooltips then return end
		-- if link and ParseItemLink(link) then
			-- self.isModified = true
			-- BSYC:AddItemToTooltip(self, link)
		-- end
	-- end)
	
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
			LibStub("AceConfigDialog-3.0"):Open("BagSync")
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

function BSYC:OnEnable()
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
	
	--load our player info after login
	self.currentPlayer = UnitName("player")
	self.currentRealm = select(2, UnitFullName("player")) --get shortend realm name with no spaces and dashes
	self.playerClass = select(2, UnitClass("player"))
	self.playerFaction = UnitFactionGroup("player")

	--strip realm of whitespace and special characters, alternative to UnitFullName, since UnitFullName does not work on OnInitialize()
	--BSYC:Debug(gsub(GetRealmName(),"[%s%-]",""))
	
	local realmList = {} --we are going to use this to store a list of connected realms, including the current realm
	local autoCompleteRealms = GetAutoCompleteRealms() or { self.currentRealm }
	
	table.insert(realmList, self.currentRealm)
	
	self.crossRealmNames = {}
	for k, v in pairs(autoCompleteRealms) do
		if v ~= self.currentRealm then
			self.crossRealmNames[v] = true
			table.insert(realmList, v)
		end
	end
	
	--initiate the db
	self:StartupDB()
	
	--do DB cleanup check by version number
	if not self.options.dbversion or self.options.dbversion ~= ver then	
		self:FixDB()
		self.options.dbversion = ver
	end

	--save the connected realm list, if there is any
	self.db.realmkey[0][self.currentRealm] = realmList

	--save the current user money (before bag update)
	self.db.player.gold = GetMoney()

	--save the class information
	self.db.player.class = self.playerClass

	--save the faction information
	--"Alliance", "Horde" or nil
	self.db.player.faction = self.playerFaction
	
	--save player Realm for quick access later
	self.db.player.realm = self.currentRealm
	
	--check for player not in guild
	if IsInGuild() or GetNumGuildMembers(true) > 0 then
		GuildRoster()
	elseif self.db.player.guild then
		self.db.player.guild = nil
		self:FixDB(true)
	end
	
	--save all inventory data, including backpack(0)
	for i = BACKPACK_CONTAINER, BACKPACK_CONTAINER + NUM_BAG_SLOTS do
		self:SaveBag("bag", i)
	end

	--force an equipment scan
	self:SaveEquipment()
	
	--force token scan
	hooksecurefunc("BackpackTokenFrame_Update", function(self) BSYC:ScanCurrency() end)
	self:ScanCurrency()
	
	--clean up old auctions
	self:CleanAuctionsDB()
	
	--check for minimap toggle
	if self.options.enableMinimap and BagSync_MinimapButton and not BagSync_MinimapButton:IsVisible() then
		BagSync_MinimapButton:Show()
	elseif not self.options.enableMinimap and BagSync_MinimapButton and BagSync_MinimapButton:IsVisible() then
		BagSync_MinimapButton:Hide()
	end
				
	self:RegisterEvent("PLAYER_MONEY")
	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	self:RegisterEvent("GUILDBANKFRAME_OPENED")
	self:RegisterEvent("GUILDBANKFRAME_CLOSED")
	self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
	self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	self:RegisterEvent("MAIL_SHOW")
	self:RegisterEvent("MAIL_INBOX_UPDATE")
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
	
	--currency
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

	--void storage
	self:RegisterEvent("VOID_STORAGE_OPEN")
	self:RegisterEvent("VOID_STORAGE_CLOSE")
	self:RegisterEvent("VOID_STORAGE_UPDATE")
	self:RegisterEvent("VOID_STORAGE_CONTENTS_UPDATE")
	self:RegisterEvent("VOID_TRANSFER_DONE")
	
	--this will be used for getting the tradeskill link
	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")

	--hook the tooltips
	self:HookTooltip(GameTooltip)
	self:HookTooltip(ItemRefTooltip)
	
	--register the slash command
	self:RegisterChatCommand("bgs", "ChatCommand")
	self:RegisterChatCommand("bagsync", "ChatCommand")
	
	if self.options.enableLoginVersionInfo then
		self:Print("[v|cFFDF2B2B"..ver.."|r] /bgs, /bagsync")
	end
end

------------------------------
--      Event Handlers      --
------------------------------

function BSYC:CURRENCY_DISPLAY_UPDATE()
	if IsInBG() or IsInArena() or InCombatLockdown() or UnitAffectingCombat("player") then return end
	self.doCurrencyUpdate = 0
	self:ScanCurrency()
end

function BSYC:PLAYER_REGEN_ENABLED()
	if IsInBG() or IsInArena() or InCombatLockdown() or UnitAffectingCombat("player") then return end
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	--were out of an arena or battleground scan the points
	self.doCurrencyUpdate = 0
	self:ScanCurrency()
end

function BSYC:GUILD_ROSTER_UPDATE()
	if not IsInGuild() and self.db.player.guild then
		self.db.player.guild = nil
		self:FixDB(true)
	elseif IsInGuild() then
		--if they don't have guild name store it or update it
		if GetGuildInfo("player") then
			if not self.db.player.guild or self.db.player.guild ~= GetGuildInfo("player") then
				self.db.player.guild = GetGuildInfo("player")
				self:FixDB(true)
			end
		end
	end
end

function BSYC:PLAYER_MONEY()
	self.db.player.gold = GetMoney()
end

------------------------------
--      BAG UPDATES  	    --
------------------------------

function BSYC:BAG_UPDATE(event, bagid)
	-- -1 happens to be the primary bank slot ;)
	if (bagid > BANK_CONTAINER) then
	
		--this will update the bank/bag slots
		local bagname

		--get the correct bag name based on it's id, trying NOT to use numbers as Blizzard may change bagspace in the future
		--so instead I'm using constants :)
		if ((bagid >= NUM_BAG_SLOTS + 1) and (bagid <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS)) then
			bagname = "bank"
		elseif (bagid >= BACKPACK_CONTAINER) and (bagid <= BACKPACK_CONTAINER + NUM_BAG_SLOTS) then
			bagname = "bag"
		else
			return
		end
		
		if bagname == "bank" and not self.atBank then return; end
		--now save the item information in the bag from bagupdate, this could be bag or bank
		self:SaveBag(bagname, bagid)
		
	end
end

function BSYC:UNIT_INVENTORY_CHANGED(event, unit)
	if unit == "player" then
		self:SaveEquipment()
	end
end

------------------------------
--      BANK	            --
------------------------------

function BSYC:BANKFRAME_OPENED()
	self.atBank = true
	self:ScanEntireBank()
end

function BSYC:BANKFRAME_CLOSED()
	self.atBank = false
end

function BSYC:PLAYERBANKSLOTS_CHANGED(event, slotid)
	--Remove self.atBank when/if Blizzard allows Bank access without being at the bank
	if self.atBank then
		self:SaveBag("bank", BANK_CONTAINER)
	end
end

------------------------------
--		REAGENT BANK		--
------------------------------

function BSYC:PLAYERREAGENTBANKSLOTS_CHANGED()
	self:SaveBag("reagentbank", REAGENTBANK_CONTAINER)
end

------------------------------
--      VOID BANK	        --
------------------------------

function BSYC:VOID_STORAGE_OPEN()
	self.atVoidBank = true
	self:ScanVoidBank()
end

function BSYC:VOID_STORAGE_CLOSE()
	self.atVoidBank = false
end

function BSYC:VOID_STORAGE_UPDATE()
	self:ScanVoidBank()
end

function BSYC:VOID_STORAGE_CONTENTS_UPDATE()
	self:ScanVoidBank()
end

function BSYC:VOID_TRANSFER_DONE()
	self:ScanVoidBank()
end

------------------------------
--      GUILD BANK	        --
------------------------------

function BSYC:GUILDBANKFRAME_OPENED()
	self.atGuildBank = true
	if not self.options.enableGuild then return end
	if not self.GuildTabQueryQueue then self.GuildTabQueryQueue = {} end
	
	local numTabs = GetNumGuildBankTabs()
	for tab = 1, numTabs do
		-- add this tab to the queue to refresh; if we do them all at once the server bugs and sends massive amounts of events
		local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals = GetGuildBankTabInfo(tab)
		if isViewable then
			self.GuildTabQueryQueue[tab] = true
		end
	end
end

function BSYC:GUILDBANKFRAME_CLOSED()
	self.atGuildBank = false
end

function BSYC:GUILDBANKBAGSLOTS_CHANGED()
	if not self.options.enableGuild then return end

	if self.atGuildBank then
		-- check if we need to process the queue
		local tab = next(self.GuildTabQueryQueue)
		if tab then
			QueryGuildBankTab(tab)
			self.GuildTabQueryQueue[tab] = nil
		else
			-- the bank is ready for reading
			self:ScanGuildBank()
		end
	end
end

------------------------------
--      MAILBOX  	        --
------------------------------

function BSYC:MAIL_SHOW()
	if self.isCheckingMail then return end
	if not self.options.enableMailbox then return end
	self:ScanMailbox()
end

function BSYC:MAIL_INBOX_UPDATE()
	if self.isCheckingMail then return end
	if not self.options.enableMailbox then return end
	self:ScanMailbox()
end

------------------------------
--     AUCTION HOUSE        --
------------------------------

function BSYC:AUCTION_HOUSE_SHOW()
	if not self.options.enableAuction then return end
	self:ScanAuctionHouse()
end

function BSYC:AUCTION_OWNED_LIST_UPDATE()
	if not self.options.enableAuction then return end
	self.db.player.AH_LastScan = time()
	self:ScanAuctionHouse()
end

------------------------------
--     PROFESSION           --
------------------------------

function BSYC:doRegularTradeSkill(numIndex, dbPlayer, dbIdx)
	local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier = GetProfessionInfo(numIndex)
	if name and skillLevel then
		dbPlayer[dbIdx] = dbPlayer[dbIdx] or {}
		dbPlayer[dbIdx].name = name
		dbPlayer[dbIdx].level = skillLevel
	end
end

function BSYC:TRADE_SKILL_SHOW()
	--IsTradeSkillLinked() returns true only if trade window was opened from chat link (meaning another player)
	if (not _G.C_TradeSkillUI.IsTradeSkillLinked()) then
		
		local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()
		
		local dbPlayer = self.db.profession[self.currentRealm][self.currentPlayer]
		
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
		local tradeid, tradename = _G.C_TradeSkillUI.GetTradeSkillLine()
		
		if not tradename then return end --don't do anything if no tradeskill name
		
		local dbPlayer = self.db.profession[self.currentRealm][self.currentPlayer]
		
		--prof1
		if prof1 and GetProfessionInfo(prof1) == tradename then
			getIndex = 1
			getProfIndex = prof1
		elseif prof2 and GetProfessionInfo(prof2) == tradename then
			getIndex = 2
			getProfIndex = prof2
		elseif archaeology and GetProfessionInfo(archaeology) == tradename then
			getIndex = 3
			getProfIndex = archaeology
		elseif fishing and GetProfessionInfo(fishing) == tradename then
			getIndex = 4
			getProfIndex = fishing
		elseif cooking and GetProfessionInfo(cooking) == tradename then
			getIndex = 5
			getProfIndex = cooking
		elseif firstAid and GetProfessionInfo(firstAid) == tradename then
			getIndex = 6
			getProfIndex = firstAid
		end
		
		--don't do anything if we have nothing to work with
		if getIndex < 1 then return end

		local name, icon, skillLevel = GetProfessionInfo(getProfIndex)

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
		if name and skillLevel and string.len(recipeString) > 0 then
			recipeString = strsub(recipeString, string.len("|") + 1) --remove the delimiter in front of recipeID list
			dbPlayer[getIndex] = dbPlayer[getIndex] or {}
			dbPlayer[getIndex].recipes = recipeString
		end
		
	end
	
	--unregister for next time the tradeskill window is opened
	self:UnregisterEvent("TRADE_SKILL_LIST_UPDATE")
end

--if they have the tradeskill window opened and then click on another professions it keeps the window opened and thus TRADE_SKILL_LIST_UPDATE never gets fired
function BSYC:TRADE_SKILL_DATA_SOURCE_CHANGED()
	self:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
end