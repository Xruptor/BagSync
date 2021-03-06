--[[
	scanner.lua
		Scanner module for BagSync, scans bags, bank, currency, etc...
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Scanner = BSYC:NewModule("Scanner")
local Unit = BSYC:GetModule("Unit")

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
local function Debug(...)
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", "Scanner")
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end
end

--https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/AddOns/Blizzard_VoidStorageUI/Blizzard_VoidStorageUI.lua
local VOID_DEPOSIT_MAX = 9
local VOID_WITHDRAW_MAX = 9
local VOID_STORAGE_MAX = 80
local VOID_STORAGE_PAGES = 2

local FirstEquipped = INVSLOT_FIRST_EQUIPPED
local LastEquipped = INVSLOT_LAST_EQUIPPED

local scannerTooltip = CreateFrame("GameTooltip", "BagSyncScannerTooltip", UIParent, "GameTooltipTemplate")
scannerTooltip:Hide()

function Scanner:StartupScans()

	self:SaveEquipment()

	for i = BACKPACK_CONTAINER, BACKPACK_CONTAINER + NUM_BAG_SLOTS do
		self:SaveBag("bag", i)
	end
	
	self:SaveCurrency()
	
	--cleanup the auction DB
	BSYC:GetModule("Data"):CheckExpiredAuctions()
	
	--cleanup any unlearned tradeskills
	self:CleanupProfessions()
end

function Scanner:SaveBag(bagtype, bagid)
	if not bagtype or not bagid then return end
	if not BSYC.db.player[bagtype] then BSYC.db.player[bagtype] = {} end

	if GetContainerNumSlots(bagid) > 0 then
		
		local slotItems = {}
		
		for slot = 1, GetContainerNumSlots(bagid) do
			local _, count, _,_,_,_, link = GetContainerItemInfo(bagid, slot)
			if link then
				table.insert(slotItems,  BSYC:ParseItemLink(link, count))
			end
		end
			
		BSYC.db.player[bagtype][bagid] = slotItems
	else
		BSYC.db.player[bagtype][bagid] = nil
	end
end

function Scanner:SaveEquipment()
	if not BSYC.db.player.equip then BSYC.db.player.equip = {} end
	
	local slotItems = {}
	
	for slot = FirstEquipped, LastEquipped do
		local link = GetInventoryItemLink("player", slot)
		local count =  GetInventoryItemCount("player", slot)
		if link then
			table.insert(slotItems,  BSYC:ParseItemLink(link, count))
		end
	end
	
	BSYC.db.player.equip = slotItems
end

function Scanner:SaveBank(rootOnly)
	if not Unit.atBank then return end
	
	--force scan of bank bag -1, since blizzard never sends updates for it
	self:SaveBag("bank", BANK_CONTAINER)
	
	if not rootOnly then
		--https://wow.gamepedia.com/BagId#/search
		for i = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
			self:SaveBag("bank", i)
		end
		--scan the reagents as part of the bank scan
		self:SaveReagents()
	end
end

function Scanner:SaveReagents()
	if not Unit.atBank or not BSYC.IsRetail then return end
	
	if IsReagentBankUnlocked() then 
		self:SaveBag("reagents", REAGENTBANK_CONTAINER)
	end
end

function Scanner:SaveVoidBank()
	if not Unit.atVoidBank or not BSYC.IsRetail then return end
	if not BSYC.db.player.void then BSYC.db.player.void = {} end
	
	local slotItems = {}
	
	for tab = 1, VOID_STORAGE_PAGES do
		for i = 1, VOID_STORAGE_MAX do
			local link, textureName, locked, recentDeposit, isFiltered = GetVoidItemInfo(tab, i)
			if link then
				table.insert(slotItems, BSYC:ParseItemLink(link))
			end
		end
	end
	
	BSYC.db.player.void = slotItems
end

function Scanner:GetXRGuild()
	if not IsInGuild() then return end
	
	--only return one guild stored from a connected realm list, otherwise we will have multiple entries of the same guild on several connected realms
	local realms = {strsplit(';', Unit:GetRealmKey())}
	local player = Unit:GetUnitInfo()
	
	if #realms > 0 then
		for i = 1, #realms do
			if player.guild and BagSyncDB[realms[i]] and BagSyncDB[realms[i]][player.guild] then
				return BagSyncDB[realms[i]][player.guild]
			end
		end
	end
	
	if not BSYC.db.realm[player.guild] then BSYC.db.realm[player.guild] = {} end
	return BSYC.db.realm[player.guild]
end

function Scanner:SaveGuildBank()
	if not Unit.atGuildBank or not BSYC.IsRetail then return end
	if Scanner.isScanningGuild then return end

	local numTabs = GetNumGuildBankTabs()
	local slotItems = {}
	Scanner.isScanningGuild = true
	
	for tab = 1, numTabs do
		local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals = GetGuildBankTabInfo(tab)
		--if we don't check for isViewable we get a weirdo permissions error for the player when they attempt it
		if isViewable then
			for slot = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
				local link = GetGuildBankItemLink(tab, slot)
				if link then
					local speciesID
					local shortID = BSYC:GetShortItemID(link)
					local _, count = GetGuildBankItemInfo(tab, slot)
					
					--check if it's a battle pet cage or something, pet cage is 82800.  This is the placeholder for battle pets
					--if it's a battlepet link it will be parsed anyways in ParseItemLink
					if shortID and tonumber(shortID) == 82800 then
						speciesID = scannerTooltip:SetGuildBankItem(tab, slot)
						scannerTooltip:Hide()
					end
					if speciesID then
						link = BSYC:CreateFakeBattlePetID(nil, nil, speciesID)
					else
						link = BSYC:ParseItemLink(link, count)
					end
					table.insert(slotItems, link)
				end
			end
		end
	end

	local guildDB = self:GetXRGuild()
	if guildDB then
		guildDB.bag = slotItems
		guildDB.money = GetGuildBankMoney()
		guildDB.faction = Unit:GetUnitInfo().faction
		guildDB.realmKey = Unit:GetRealmKey()
	end
	
	Scanner.isScanningGuild = false
end

function Scanner:SaveMailbox(isShow)
	if not Unit.atMailbox or not BSYC.options.enableMailbox then return end
	if not BSYC.db.player.mailbox then BSYC.db.player.mailbox = {} end
	
	if self.isCheckingMail then return end --prevent overflow from CheckInbox()
	self.isCheckingMail = true

	--used to initiate mail check from server, for some reason GetInboxNumItems() returns zero sometimes
	--even though the user has mail in the mailbox.  This can be attributed to lag.
	if isShow then
		--only do this once it causes a continously mail spam loop in Classic and we can avoid spam as well in Retail
		CheckInbox()
	end
	
	local slotItems = {}
	local numInbox = GetInboxNumItems()

	--scan the inbox
	if (numInbox > 0) then
		for mailIndex = 1, numInbox do
			for i = 1, ATTACHMENTS_MAX_RECEIVE do
				local name, itemID, itemTexture, count, quality, canUse = GetInboxItem(mailIndex, i)
				local link = GetInboxItemLink(mailIndex, i)
				local byPass = false
				if name and link then
					--check for battle pet cages
					if BSYC.IsRetail and itemID and itemID == 82800 then
						local hasCooldown, speciesID, level, breedQuality, maxHealth, power, speed, name = scannerTooltip:SetInboxItem(mailIndex)
						scannerTooltip:Hide()
						
						if speciesID then
							link = BSYC:CreateFakeBattlePetID(nil, nil, speciesID)
							byPass = true
						end
					end
					if not byPass then
						link = BSYC:ParseItemLink(link, count)
					end
					table.insert(slotItems, link)
				end
			end
		end
	end
	
	BSYC.db.player.mailbox = slotItems

	self.isCheckingMail = false
end

function Scanner:SaveAuctionHouse()
	if not Unit.atAuction or not BSYC.options.enableAuction then return end
	if not BSYC.db.player.auction then BSYC.db.player.auction = {} end

	local slotItems = {}
	
	if BSYC.IsRetail then
		local numActiveAuctions = C_AuctionHouse.GetNumOwnedAuctions()
			
		--scan the auction house
		if (numActiveAuctions > 0) then
			for ahIndex = 1, numActiveAuctions do
			
				--https://wow.gamepedia.com/API_C_AuctionHouse.GetOwnedAuctionInfo
				local itemObj = C_AuctionHouse.GetOwnedAuctionInfo(ahIndex)
				
				--we only want active auctions not sold one.  So check itemObj.status
				if itemObj and itemObj.timeLeftSeconds and itemObj.status == 0 then

					local expTime = time() + itemObj.timeLeftSeconds -- current Time + advance time in seconds to get expiration time and date
					local itemCount = itemObj.quantity or 1
					local parseLink = ""
					
					if itemObj.itemLink then
						parseLink = BSYC:ParseItemLink(itemObj.itemLink, itemCount)
					elseif itemObj.itemKey and itemObj.itemKey.itemID then
						parseLink = BSYC:ParseItemLink(itemObj.itemKey.itemID, itemCount)
					end
					
					--we are going to make the third field an identifier field, so we can know what it is for future reference
					--for now auction house will be 1, with 4th field being expTime
					if itemCount <= 1 then
						parseLink = parseLink..";1;1;"..expTime
					else
						parseLink = parseLink..";1;"..expTime
					end

					table.insert(slotItems, parseLink)
				end
			end
		end
		
	else
		--this is for WOW Classic Auction House
		local numActiveAuctions = GetNumAuctionItems("owner")
		local timestampChk = { 30*60, 2*60*60, 12*60*60, 48*60*60 }
		
		--scan the auction house
		if (numActiveAuctions > 0) then
			for ahIndex = 1, numActiveAuctions do
				local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner, saleStatus  = GetAuctionItemInfo("owner", ahIndex)
				if name then
					local link = GetAuctionItemLink("owner", ahIndex)
					local timeLeft = GetAuctionItemTimeLeft("owner", ahIndex)
					if link and timeLeft and tonumber(timeLeft) then
						count = (count or 1)
						timeLeft = tonumber(timeLeft)
						if not timeLeft or timeLeft < 1 or timeLeft > 4 then timeLeft = 4 end --just in case				
						--since classic doesn't return the exact time on old auction house, we got to add it manually
						--it only does short, long and very long
						local expireTime = time() + timestampChk[timeLeft]
						local parseLink = BSYC:ParseItemLink(link, count)
						--we are going to make the third field an identifier field, so we can know what it is for future reference
						--for now auction house will be 1, with 4th field being expTime
						if count <= 1 then
							parseLink = parseLink..";1;1;"..expireTime
						else
							parseLink = parseLink..";1;"..expireTime
						end
						
						table.insert(slotItems, parseLink)
					end
				end
			end
		end
		
	end
	
	BSYC.db.player.auction.bag = slotItems
	BSYC.db.player.auction.count = #slotItems or 0
	BSYC.db.player.auction.lastscan = time()
end

function Scanner:SaveCurrency()
	if not BSYC.IsRetail then return end
	if Unit:InCombatLockdown() then return end
	
	local lastHeader
	local limit = C_CurrencyInfo.GetCurrencyListSize()
	local slotItems = {}

	for i=1, limit do

		local currencyinfo = C_CurrencyInfo.GetCurrencyListInfo(i)
		--local name = currencyinfo.name
		--local name, isHeader, isExpanded, _, _, count, icon = C_CurrencyInfo.GetCurrencyListInfo(i)
		local link = C_CurrencyInfo.GetCurrencyListLink(i)
		
		local currencyID = BSYC:GetCurrencyID(link)
		
		if currencyinfo.name then
			if(currencyinfo.isHeader and not currencyinfo.isHeaderExpanded) then
				C_CurrencyInfo.ExpandCurrencyList(i,1)
				lastHeader = currencyinfo.name
				limit = C_CurrencyInfo.GetCurrencyListSize()
			elseif currencyinfo.isHeader then
				lastHeader = currencyinfo.name
			end
			if (not currencyinfo.isHeader) then
				slotItems[currencyID] = slotItems[currencyID] or {}
				slotItems[currencyID].name = currencyinfo.name
				slotItems[currencyID].header = lastHeader
				slotItems[currencyID].count = currencyinfo.quantity
				slotItems[currencyID].icon = currencyinfo.iconFileID
			end
		end
	end
	
	BSYC.db.player.currency = slotItems
end
	
function Scanner:SaveProfessions()
	if not BSYC.IsRetail then return end
	
	--we don't want to do linked tradeskills, guild tradeskills, or a tradeskill from an NPC
	if _G.C_TradeSkillUI.IsTradeSkillLinked() or _G.C_TradeSkillUI.IsTradeSkillGuild() or _G.C_TradeSkillUI.IsNPCCrafting() then return end
	
	local recipeData = {}
	local tmpRecipe = {}
	local catCheck, catCleanup = {}, {}
	local orderIndex = 0
	
	Scanner.recipeIDs = C_TradeSkillUI.GetAllRecipeIDs()
	--invert the table, forcing the value to be the key and the key the value, inverted[v] = k  (see TableUtil.lua)
	Scanner.invertedRecipeIDs = tInvert(Scanner.recipeIDs)

	local tradeSkillID, skillLineName, skillLineRank, skillLineMaxRank, skillLineModifier, parentSkillLineID, parentSkillLineName =  C_TradeSkillUI.GetTradeSkillLine()
	
	if parentSkillLineID and parentSkillLineName then
	
		--create the categories, sometimes we have professions with no recipes.  We want to store this anyways
		local categories = {C_TradeSkillUI.GetCategories()}
		
		for i, categoryID in ipairs(categories) do
			local categoryData = C_TradeSkillUI.GetCategoryInfo(categoryID)

			if categoryData and categoryData.categoryID and categoryData.skillLineCurrentLevel and categoryData.skillLineCurrentLevel > 0 then

				if not BSYC.db.player.professions[parentSkillLineID] then
					BSYC.db.player.professions[parentSkillLineID] = BSYC.db.player.professions[parentSkillLineID] or {}
					BSYC.db.player.professions[parentSkillLineID].name = parentSkillLineName
				end
				
				local parentIDSlot = BSYC.db.player.professions[parentSkillLineID]
				parentIDSlot.categories = parentIDSlot.categories or {}
				
				--Legion Engineering, Cateclysm Engineering, etc...
				parentIDSlot.categories[categoryID] = parentIDSlot.categories[categoryID] or {}
				local subCatSlot = parentIDSlot.categories[categoryID]

				--always overwrite because we can have a different level or name then last time
				subCatSlot.name = categoryData.name
				subCatSlot.skillLineCurrentLevel = categoryData.skillLineCurrentLevel
				subCatSlot.skillLineMaxLevel = categoryData.skillLineMaxLevel

				if not catCheck[categoryID] then
					catCheck[categoryID] = true
					orderIndex = orderIndex + 1
					subCatSlot.orderIndex = orderIndex
				end
						
			end
		end
	
		--store the recipes
		for i = 1, #Scanner.recipeIDs do
		
			if C_TradeSkillUI.GetRecipeInfo(Scanner.recipeIDs[i]) then
			
				--grab the info in a table
				recipeData = C_TradeSkillUI.GetRecipeInfo(Scanner.recipeIDs[i])
				
				local categoryID = recipeData.categoryID
				local categoryData = C_TradeSkillUI.GetCategoryInfo(categoryID)

				--grab the parent name, Engineering, Herbalism, Blacksmithing, etc...
				if recipeData.learned and categoryData and categoryData.categoryID == categoryID and categoryData.parentCategoryID then

					--grab categories, Legion Engineering, Cateclysm Engineering, etc...
					local subCatData = C_TradeSkillUI.GetCategoryInfo(categoryData.parentCategoryID)
					
					--make sure we have something to work with, we don't want to store stuff that doesn't have levels
					if subCatData and subCatData.categoryID == categoryData.parentCategoryID then

						if not BSYC.db.player.professions[parentSkillLineID] then
							BSYC.db.player.professions[parentSkillLineID] = BSYC.db.player.professions[parentSkillLineID] or {}
							BSYC.db.player.professions[parentSkillLineID].name = parentSkillLineName
						end

						local parentIDSlot = BSYC.db.player.professions[parentSkillLineID]
						parentIDSlot.categories = parentIDSlot.categories or {}
						
						--store the sub category information, Legion Engineering, Cateclysm Engineering, etc...
						parentIDSlot.categories[subCatData.categoryID] = parentIDSlot.categories[subCatData.categoryID] or {}
						local subCatSlot = parentIDSlot.categories[subCatData.categoryID]

						--always overwrite because we can have a different level or name then last time
						subCatSlot.name = subCatData.name
						subCatSlot.skillLineCurrentLevel = subCatData.skillLineCurrentLevel
						subCatSlot.skillLineMaxLevel = subCatData.skillLineMaxLevel
						
						--cleanout the recipe list first time entering the category, otherwise it will constantly have repeats
						if not catCleanup[subCatData.categoryID] then
							catCleanup[subCatData.categoryID] = true
							subCatSlot.recipes = nil
						end
						if not subCatSlot.orderIndex then
							orderIndex = orderIndex + 1
							subCatSlot.orderIndex = orderIndex
						end
						
						--now store the recipe information, but make sure we don't already have the recipe stored
						if not tmpRecipe[recipeData.recipeID] then
							subCatSlot.recipes = (subCatSlot.recipes or "").."|"..recipeData.recipeID
						end
						
					end
				
				end
				
			end
			
		end
		
	end

	--grab archaeology, fishing
	--first aid was removed in battle for azeroth
	local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()
	
	if archaeology then
		local name, _, rank, maxRank, _, _, skillLine = GetProfessionInfo(archaeology)
		BSYC.db.player.professions[skillLine] = BSYC.db.player.professions[skillLine] or {}
		BSYC.db.player.professions[skillLine].name = name
		BSYC.db.player.professions[skillLine].skillLineCurrentLevel = rank
		BSYC.db.player.professions[skillLine].skillLineMaxLevel = maxRank
		BSYC.db.player.professions[skillLine].secondary = true --mark is as a secondary profession
	end
	
	if fishing then
		local name, _, rank, maxRank, _, _, skillLine = GetProfessionInfo(fishing)
		BSYC.db.player.professions[skillLine] = BSYC.db.player.professions[skillLine] or {}
		BSYC.db.player.professions[skillLine].name = name
		BSYC.db.player.professions[skillLine].skillLineCurrentLevel = rank
		BSYC.db.player.professions[skillLine].skillLineMaxLevel = maxRank
		BSYC.db.player.professions[skillLine].secondary = true --mark is as a secondary profession
	end
	
	--as a precaution lets do a tradeskill cleanup just in case
	self:CleanupProfessions()
end

function Scanner:CleanupProfessions()
	if not BSYC.IsRetail then return end
	
	--lets remove unlearned tradeskills
	local tmpList = {}

	for i = 1, select("#", GetProfessions()) do
		local prof = select(i, GetProfessions())
		if prof then
			local name, _, rank, maxRank, _, _, skillLine = GetProfessionInfo(prof)
			if name and skillLine then
				tmpList[skillLine] = name
			end
		end
	end
	
	for k, v in pairs(BSYC.db.player.professions) do
		if not tmpList[k] then
			--it's an unlearned or unused tradeskill, lets remove it
			BSYC.db.player.professions[k] = nil
		end
	end
end

function Scanner:ParseCraftedInfo(unitTarget, castGUID, spellID)
	if not BSYC.IsRetail then return end
	--only do this when they are not at a bank
	if Unit.atBank then return end
	if not Scanner.recipeIDs or not Scanner.invertedRecipeIDs then return end
	
	--reset
	Scanner.currentReagents = {}
	
	--use the inverted since the spellID is the key
    if Scanner.invertedRecipeIDs[spellID] then
        for i = 1, C_TradeSkillUI.GetRecipeNumReagents(spellID) do
            local link = C_TradeSkillUI.GetRecipeReagentItemLink(spellID, i)
            if link then
				local itemID = BSYC:ParseItemLink(link)
				if itemID then
					--save zero to check for reagent count later
					Scanner.currentReagents[itemID] = 0
				end
			end
        end
    end
end

function Scanner:SaveCraftedReagents()
	if not BSYC.IsRetail then return end
	--only do this when they are not at a bank
	if Unit.atBank then return end

	--don't do anything if we have nothing to work with
	if not Scanner.currentReagents or BSYC:GetHashTableLen(Scanner.currentReagents) < 1 then return end

	--reset the stored reagent counts to calculate bank count (minus reagentBank)
	for k, v in pairs(Scanner.currentReagents) do
		Scanner.currentReagents[k] = 0
	end

	local bagtype = "reagents"
	local bagid = REAGENTBANK_CONTAINER

	--we are allowed to scan the Reagents outside of the bank. GetContainerItemInfo will return information
	--so lets just save the Reagent data again and grab the reagent counts as we do
	if IsReagentBankUnlocked() then
		
		if not BSYC.db.player[bagtype] then BSYC.db.player[bagtype] = {} end
		
		if GetContainerNumSlots(bagid) > 0 then
			
			local slotItems = {}
			
			for slot = 1, GetContainerNumSlots(bagid) do
				local _, rgCount, _,_,_,_, rgLink = GetContainerItemInfo(bagid, slot)
				if rgLink then
					local rgItemID = BSYC:ParseItemLink(rgLink)
					if rgItemID and Scanner.currentReagents[rgItemID] then
						Scanner.currentReagents[rgItemID] = Scanner.currentReagents[rgItemID] + rgCount
					end
					table.insert(slotItems,  BSYC:ParseItemLink(rgLink, rgCount))
				end
			end
			
			BSYC.db.player[bagtype][bagid] = slotItems
		else
			BSYC.db.player[bagtype][bagid] = nil
		end
		
	end
	
	--------------
	--BANK SLOT
	--------------
	
	--we cannot scan the bank though when we aren't visiting it.  So this makes a bit more complicated.
	--First we need to delete all entries that have the reagents that were used
	--Second we have to force a manual entry in the root Bank bag (BANK_CONTAINER) with the reagent counts if any
	
	local bagtype = "bank"
	if not BSYC.db.player[bagtype] then BSYC.db.player[bagtype] = {} end
	
	--first lets delete any reagents used from our database, before we put them back in.
	for bagID, bagData in pairs(BSYC.db.player[bagtype]) do
	
		local slotItems = {}
	
		--search individual bank bags
		for i=1, #bagData do
			--do we even have something to work with?
			if bagData[i] then
				local itemID, count, identifier = strsplit(";", bagData[i])
				--only save if it's not one of the reagents that was used
				if itemID and not Scanner.currentReagents[itemID] then
					table.insert(slotItems, bagData[i])
				end
			end
		end
		BSYC.db.player[bagtype][bagID] = slotItems
	end
	
	--now lets add them manually to the root bank location (BANK_CONTAINER), create it if it's not found
	local rootBankItems = BSYC.db.player[bagtype][BANK_CONTAINER] or {}
	
	for k, v in pairs(Scanner.currentReagents) do
	
		local bankCount = GetItemCount(k, true) --set true to search all bank including reagentBank
		bankCount = bankCount - v --subtract the reagent count if any
		
		if bankCount and bankCount > 0 then
			table.insert(rootBankItems,  BSYC:ParseItemLink(k, bankCount))
		end
	end
	
	--now save it back to the bank root
	BSYC.db.player[bagtype][BANK_CONTAINER] = rootBankItems
	
	--set the tooltip to be refreshed so that it displays the new values
	BSYC.refreshTooltip = true

end
