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
	if not Unit.atBank then return end
	
	if IsReagentBankUnlocked() then 
		self:SaveBag("reagents", REAGENTBANK_CONTAINER)
	end
end

function Scanner:SaveVoidBank()
	if not Unit.atVoidBank then return end
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
	if not IsInGuild() then return end

	local numTabs = GetNumGuildBankTabs()
	local slotItems = {}
	
	for tab = 1, numTabs do
		local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals = GetGuildBankTabInfo(tab)
		--if we don't check for isViewable we get a weirdo permissions error for the player when they attempt it
		if isViewable then
			for slot = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
				local link = GetGuildBankItemLink(tab, slot)
				local speciesID, level, breedQuality, maxHealth, power, speed, name = GameTooltip:SetGuildBankItem(tab, slot)
				if link then
					if speciesID then
						link = BSYC:CreateFakeBattlePetID(nil, nil, speciesID)
					else
						link = BSYC:ParseItemLink(link, count)
					end
					
					local _, count = GetGuildBankItemInfo(tab, slot)
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
end

function Scanner:SaveMailbox()
	if not Unit.atMailbox or not BSYC.options.enableMailbox then return end
	if not BSYC.db.player.mailbox then BSYC.db.player.mailbox = {} end
	
	if self.isCheckingMail then return end --prevent overflow from CheckInbox()
	self.isCheckingMail = true

	 --used to initiate mail check from server, for some reason GetInboxNumItems() returns zero sometimes
	 --even though the user has mail in the mailbox.  This can be attributed to lag.
	CheckInbox()
	
	local slotItems = {}
	local numInbox = GetInboxNumItems()

	--scan the inbox
	if (numInbox > 0) then
		for mailIndex = 1, numInbox do
			local hasCooldown, speciesID, level, breedQuality, maxHealth, power, speed, name = GameTooltip:SetInboxItem(mailIndex)
			for i = 1, ATTACHMENTS_MAX_RECEIVE do
				local name, itemID, itemTexture, count, quality, canUse = GetInboxItem(mailIndex, i)
				local link = GetInboxItemLink(mailIndex, i)
				if name and link then
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
	
	BSYC.db.player.mailbox = slotItems
	
	self.isCheckingMail = false
end

function Scanner:SaveAuctionHouse()
	if not Unit.atAuction or not BSYC.options.enableAuction then return end
	if not BSYC.db.player.auction then BSYC.db.player.auction = {} end

	local slotItems = {}
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
	
	BSYC.db.player.auction.bag = slotItems
	BSYC.db.player.auction.count = #slotItems or 0
	BSYC.db.player.auction.lastscan = time()
end

function Scanner:SaveCurrency()
	if Unit:InCombatLockdown() then return end

	local lastHeader
	local limit = GetCurrencyListSize()
	local slotItems = {}

	for i=1, limit do

		local name, isHeader, isExpanded, _, _, count, icon = GetCurrencyListInfo(i)
		local link = GetCurrencyListLink(i)
		
		local currencyID = BSYC:GetCurrencyID(link)
		
		if name then
			if(isHeader and not isExpanded) then
				ExpandCurrencyList(i,1)
				lastHeader = name
				limit = GetCurrencyListSize()
			elseif isHeader then
				lastHeader = name
			end
			if (not isHeader) then
				slotItems[currencyID] = slotItems[currencyID] or {}
				slotItems[currencyID].name = name
				slotItems[currencyID].header = lastHeader
				slotItems[currencyID].count = count
				slotItems[currencyID].icon = icon
			end
		end
	end
	
	BSYC.db.player.currency = slotItems
end
	
function Scanner:SaveProfessions()
	--we don't want to do linked tradeskills, guild tradeskills, or a tradeskill from an NPC
	if _G.C_TradeSkillUI.IsTradeSkillLinked() or _G.C_TradeSkillUI.IsTradeSkillGuild() or _G.C_TradeSkillUI.IsNPCCrafting() then return end
	
	local recipeData = {}
	local tmpRecipe = {}
	local catCheck, catCleanup = {}, {}
	local orderIndex = 0
	local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs()

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
		for i = 1, #recipeIDs do
		
			if C_TradeSkillUI.GetRecipeInfo(recipeIDs[i], recipeData) then
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

