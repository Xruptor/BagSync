--[[
	scanner.lua
		Scanner module for BagSync, scans bags, bank, currency, etc...

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Scanner = BSYC:NewModule("Scanner")
local Unit = BSYC:GetModule("Unit")
local Data = BSYC:GetModule("Data")
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Scanner", ...) end
end

--https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/AddOns/Blizzard_VoidStorageUI/Blizzard_VoidStorageUI.lua
local VOID_STORAGE_MAX = 80
local VOID_STORAGE_PAGES = 2
-- local VOID_DEPOSIT_MAX = 9
-- local VOID_WITHDRAW_MAX = 9

local MAX_GUILDBANK_SLOTS_PER_TAB = 98
-- local NUM_SLOTS_PER_GUILDBANK_GROUP = 14
-- local NUM_GUILDBANK_ICONS_SHOWN = 0
-- local NUM_GUILDBANK_ICONS_PER_ROW = 10
-- local NUM_GUILDBANK_ICON_ROWS = 9
-- local NUM_GUILDBANK_COLUMNS = 7
-- local MAX_TRANSACTIONS_SHOWN = 21

local FirstEquipped = INVSLOT_FIRST_EQUIPPED
local LastEquipped = INVSLOT_LAST_EQUIPPED

--backup scanner in case C_TooltipInfo doesn't exist
local scannerTooltip = CreateFrame("GameTooltip", "BagSyncScannerTooltip", UIParent, "GameTooltipTemplate")

Scanner.currencyTransferInProgress = false
Scanner.lastCurrencyID = 0
Scanner.pendingdMail = {items={}}

function Scanner:ResetTooltips()
	--the true is to set it to silent and not return an error if not found
	if BSYC:GetModule("Tooltip", true) then BSYC:GetModule("Tooltip"):ResetLastLink() end
end

--https://warcraft.wiki.gg/wiki/BagID
--https://warcraft.wiki.gg/wiki/Enum.BagIndex
function Scanner:GetBagSlots(bagType)
	if bagType == "bag" then
		return Enum.BagIndex.Backpack, Enum.BagIndex.Bag_4

	elseif bagType == "bank" then
		if BSYC.IsBankTabsActive then
			return Enum.BagIndex.CharacterBankTab_1, Enum.BagIndex.CharacterBankTab_6
		else
			--classic server bank bags start at 5 so these are off by one, the actual bank slot 5 is the reagentbank variable, so we have to use that
			--that's because the classic bank slots are wrong, so all of them need to be subtracted by 1.
			--https://us.forums.blizzard.com/en/wow/t/bug-enumbagslotflags-keys-different-to-retail/1912948
			--Special thanks to Schlapstick on anniversary server for helping me out with this. :)
			local firstBankSlot = (not BSYC.IsReagentBagActive and Enum.BagIndex.ReagentBag) or Enum.BagIndex.BankBag_1
			return firstBankSlot, Enum.BagIndex.BankBag_7
		end
	end
end

function Scanner:IsBackpack(bagid)
	if not bagid then return false end
	return bagid == Enum.BagIndex.Backpack
end

function Scanner:IsBackpackBag(bagid)
	if not bagid then return false end
	local minCnt, maxCnt = self:GetBagSlots("bag")
	return bagid >= minCnt and bagid <= maxCnt
end

function Scanner:IsKeyring(bagid)
	if not bagid then return false end
	if bagid == Enum.BagIndex.Keyring and (not HasKey or not HasKey()) then
		return false
	end
	return bagid == Enum.BagIndex.Keyring
end

function Scanner:IsBank(bagid)
	if not bagid then return false end
	return bagid == Enum.BagIndex.Bank
end

function Scanner:IsBankBag(bagid)
	if not bagid then return false end
	local minCnt, maxCnt = self:GetBagSlots("bank")
	return bagid >= minCnt and bagid <= maxCnt
end

function Scanner:IsReagentBag(bagid)
	if not bagid then return false end
	--don't process if it's not enabled or we are at the bank (since on classic the reagentbag num 5 is the first bank bag slot)
	if not BSYC.IsReagentBagActive then return false end
	return bagid == Enum.BagIndex.ReagentBag
end

function Scanner:IsWarbandBank(bagid)
	if not bagid then return false end
	if not BSYC.isWarbandActive then return false end
	return BSYC.WarbandIndex.bags[bagid]
end

function Scanner:StartupScans()
	Debug(BSYC_DL.INFO, "StartupScans", BSYC.startupScanChk)
	if BSYC.startupScanChk then return end --only do this once per load.  Does not include /reloadui

	self:SaveEquipment()

	local minCnt, maxCnt = self:GetBagSlots("bag")
	for i = minCnt, maxCnt do
		self:SaveBag("bag", i)
	end

	--check keyring, Enum.BagIndex.Keyring is nil on servers that have it disabled
	if Enum.BagIndex.Keyring and HasKey and HasKey() then
		self:SaveBag("bag", Enum.BagIndex.Keyring)
	else
		--cleanup old keyring stuff if it's disabled
		local xKeyRing = Enum.BagIndex.Keyring
		if xKeyRing and BSYC.db.player.bag and BSYC.db.player.bag[xKeyRing] then
			BSYC.db.player.bag[xKeyRing] = nil
		end
	end

	self:SaveCurrency(true)

	--cleanup the auction DB
	Data:CheckExpiredAuctions()

	--cleanup any unlearned tradeskills
	self:CleanupProfessions()

	--populate the cache
	Data:PopulateItemCache()

	BSYC.startupScanChk = true
end

function Scanner:SaveBag(bagtype, bagid)
	Debug(BSYC_DL.INFO, "SaveBag", bagtype, bagid, BSYC.tracking.bag)
	if not bagtype or not bagid then return end
	if not BSYC.tracking[bagtype] then return end
	if not BSYC.db.player[bagtype] then BSYC.db.player[bagtype] = {} end

	local xGetNumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
	local xGetContainerInfo = (C_Container and C_Container.GetContainerItemInfo) or GetContainerItemInfo

	local numSlots = xGetNumSlots(bagid)

	if numSlots > 0 then
		local slotItems = {}

		for slot = 1, numSlots do
			local xObj, count, _,_,_,_, link = xGetContainerInfo(bagid, slot)

			--lets check for C_Container
			if xObj and xObj.hyperlink then
				link = xObj.hyperlink
				count = xObj.stackCount or 1
			end
			if link then
				local tmpItem = BSYC:ParseItemLink(link, count)
				Debug(BSYC_DL.FINE, "SaveBag", bagtype, bagid, tmpItem)
				table.insert(slotItems, tmpItem)
			end
		end

		BSYC.db.player[bagtype][bagid] = slotItems
	else
		BSYC.db.player[bagtype][bagid] = nil
	end
	self:ResetTooltips()
end

function Scanner:SaveEquippedBags(bagtype)
	Debug(BSYC_DL.INFO, "SaveEquippedBags", bagtype, BSYC.options.showEquipBagSlots, BSYC.IsBankTabsActive)
	if not bagtype then return end

	--don't save bank bags if tabs is enabled, because they are using bank tabs instead
	if bagtype == "bank" and BSYC.IsBankTabsActive then
		if BSYC.db.player.equipbags and BSYC.db.player.equipbags.bank then BSYC.db.player.equipbags.bank = nil end
		return
	end
	if not BSYC.db.player.equipbags then BSYC.db.player.equipbags = {} end
	if not BSYC.db.player.equipbags.bag then BSYC.db.player.equipbags.bag = {} end
	if not BSYC.IsBankTabsActive and not BSYC.db.player.equipbags.bank then BSYC.db.player.equipbags.bank = {} end

	if not C_Container or not C_Container.ContainerIDToInventoryID then return end

	local slotItems = {}

	--add the bag slots
	local minCnt, maxCnt = self:GetBagSlots(bagtype)
	for i = minCnt, maxCnt do
		local invID = C_Container.ContainerIDToInventoryID(i)
		local bagLink = GetInventoryItemLink("player",invID)
		if bagLink then
			local parseLink =  BSYC:ParseItemLink(bagLink)
			if parseLink then
				local encodeStr = BSYC:EncodeOpts({bagslot=i}, parseLink)
				table.insert(slotItems,  encodeStr)
			end
		end
	end

	BSYC.db.player.equipbags[bagtype] = slotItems
	self:ResetTooltips()
end

function Scanner:SaveEquipment()
	Debug(BSYC_DL.INFO, "SaveEquipment", BSYC.tracking.equip)
	if not BSYC.tracking.equip then return end
	if not BSYC.db.player.equip then BSYC.db.player.equip = {} end

	local slotItems = {}

	for slot = FirstEquipped, LastEquipped do
		local link = GetInventoryItemLink("player", slot)
		local count =  GetInventoryItemCount("player", slot)
		if link then
			local tmpItem =  BSYC:ParseItemLink(link, count)
			Debug(BSYC_DL.FINE, "SaveEquipment", tmpItem, slot)
			table.insert(slotItems,  tmpItem)
		end
	end

	self:SaveEquippedBags("bag")

	--check for ProfessionsFrame Inventory Slots
	if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInventorySlots then

		--https://github.com/tomrus88/BlizzardInterfaceCode/blob/fe4bab5c1ffc87ae2919478efc59d03b76ef6b19/Interface/AddOns/Blizzard_Tutorials/Blizzard_Tutorials_Professions.lua
		local profInvSlots = C_TradeSkillUI.GetProfessionInventorySlots()

		for _, i in ipairs(profInvSlots) do

			--this starts at tabard which is 19, you want to do +1 to start at 20
			--https://wowpedia.fandom.com/wiki/InventorySlotId
			local slotNumber = i + 1

			local link = GetInventoryItemLink("player", slotNumber)
			local count =  GetInventoryItemCount("player", slotNumber)

			if link and count then
				local tmpItem =  BSYC:ParseItemLink(link, count)
				Debug(BSYC_DL.FINE, "SaveEquipment", "ProfessionSlot", tmpItem, slotNumber)
				table.insert(slotItems,  tmpItem)
			end
		end

	end

	BSYC.db.player.equip = slotItems
	self:ResetTooltips()
end

function Scanner:SaveBank(rootOnly)
	Debug(BSYC_DL.INFO, "SaveBank", rootOnly, Unit.atBank, BSYC.tracking.bank, BSYC.IsBankTabsActive)
	if not Unit.atBank or not BSYC.tracking.bank then return end

	--save bank bags
	self:SaveEquippedBags("bank")

	if not rootOnly then
		--lets refresh the bank database, especially if the bagids got changed or we are using bank tabs now
		if BSYC.db.player.bank then BSYC.db.player.bank = {} end

		--force scan of bank bag -1, since blizzard never sends updates for it
		if Enum.BagIndex.Bank then
			self:SaveBag("bank", Enum.BagIndex.Bank)
		end

		local minCnt, maxCnt = self:GetBagSlots("bank")

		for i = minCnt, maxCnt do
			self:SaveBag("bank", i)
		end
		--scan the reagents as part of the bank scan, but make sure it's even enabled on server
		if IsReagentBankUnlocked then self:SaveReagents() end
	else
		--force scan of bank bag -1, since blizzard never sends updates for it
		if Enum.BagIndex.Bank then
			self:SaveBag("bank", Enum.BagIndex.Bank)
		end
	end

	self:ResetTooltips()
end

function Scanner:SaveReagents()
	Debug(BSYC_DL.INFO, "SaveReagents", Unit.atBank, BSYC.tracking.reagents)
	if not Unit.atBank or not BSYC.tracking.reagents then return end

	if IsReagentBankUnlocked() then
		self:SaveBag("reagents", Enum.BagIndex.Reagentbank)
	end
	self:ResetTooltips()
end

function Scanner:SaveVoidBank()
	Debug(BSYC_DL.INFO, "SaveVoidBank", Unit.atVoidBank, BSYC.tracking.void)
	if not Unit.atVoidBank or not BSYC.tracking.void then return end
	if not BSYC.db.player.void then BSYC.db.player.void = {} end

	local slotItems = {}

	for tab = 1, VOID_STORAGE_PAGES do
		for i = 1, VOID_STORAGE_MAX do
			local link = GetVoidItemInfo(tab, i)
			if link then
				table.insert(slotItems, BSYC:ParseItemLink(link))
			end
		end
	end

	BSYC.db.player.void = slotItems
	self:ResetTooltips()
end

local function findBattlePet(iconTexture, petName, typeSlot, arg1, arg2)
	Debug(BSYC_DL.INFO, "findBattlePet", iconTexture, petName, typeSlot, arg1, arg2, C_TooltipInfo and 'C_TooltipInfo', C_PetJournal and 'C_PetJournal')

	if BSYC.options.enableAccurateBattlePets and arg1 then
		local data = {}

		--https://github.com/tomrus88/BlizzardInterfaceCode/blob/4e7b4f5df63d240038912624218ebb9c0c8a3edf/Interface/SharedXML/Tooltip/TooltipDataRules.lua
		--it may be possible to use C_PetJournal.GetPetStats(petID) in the future if the guildbank and mailbox return the GUID of the pet
		if typeSlot == "guild" then
			--MOP Classic and a few other classic servers don't have C_TooltipInfo implemented for some stupid reason. So check for that.  *facepalm*
			if C_TooltipInfo then
				data = C_TooltipInfo.GetGuildBankItem(arg1, arg2)
			else
				--local speciesID, level, breedQuality, maxHealth, power, speed, name = GameTooltip:SetGuildBankItem(arg1, arg2)
				local speciesID, level, breedQuality, maxHealth, power, speed, name = scannerTooltip:SetGuildBankItem(arg1, arg2)
				if speciesID and speciesID > 0 then
					data.battlePetSpeciesID = speciesID
					data.battlePetLevel = level
					data.battlePetBreedQuality = breedQuality
					data.battlePetMaxHealth = maxHealth
					data.battlePetPower = power
					data.battlePetSpeed = speed
					data.battlePetName = name
				end
				scannerTooltip:Hide()
			end
		else
			--MOP Classic and a few other classic servers don't have C_TooltipInfo implemented for some stupid reason. So check for that.  *facepalm*
			if C_TooltipInfo then
				data = C_TooltipInfo.GetInboxItem(arg1, arg2)
			else
				--local hasCooldown, speciesID, level, breedQuality, maxHealth, power, speed, name = scannerTooltip:SetInboxItem(mailIndex)
				local hasCooldown, speciesID, level, breedQuality, maxHealth, power, speed, name = scannerTooltip:SetInboxItem(arg1)
				if speciesID and speciesID > 0 then
					data.battlePetSpeciesID = speciesID
					data.battlePetLevel = level
					data.battlePetBreedQuality = breedQuality
					data.battlePetMaxHealth = maxHealth
					data.battlePetPower = power
					data.battlePetSpeed = speed
					data.battlePetName = name
				end
				scannerTooltip:Hide()
			end
		end

		--fixes a slight issue where occasionally due to server delay, the BattlePet tooltips are still shown on the screen and overlaps the GameTooltip
		if BattlePetTooltip then BattlePetTooltip:Hide() end
		if FloatingBattlePetTooltip then FloatingBattlePetTooltip:Hide() end

		if (data and data.battlePetSpeciesID) then
			return data.battlePetSpeciesID, data.battlePetLevel, data.battlePetBreedQuality, data.battlePetMaxHealth, data.battlePetPower, data.battlePetSpeed, data.battlePetName
		end
	end

	if petName and C_PetJournal then
		local speciesId = C_PetJournal.FindPetIDByName(petName)
		if speciesId then
			return speciesId
		end
	end

	--this can be totally inaccurate, but until Blizzard allows us to get more info from the GuildBank in regards to Battle Pets.  This is the fastest way without scanning in tooltips.
	--Example:  Toxic Wasteling shares the same icon as Jade Oozeling
	if iconTexture and C_PetJournal then
		for index = 1, C_PetJournal.GetNumPets() do
			local _, speciesID, _, _, _, _, _, _, icon = C_PetJournal.GetPetInfoByIndex(index)
			if icon == iconTexture then
				return speciesID
			end
		end
	end
end

function Scanner:SaveGuildBank(tabID)
	if not BSYC.tracking.guild then return end
	if Scanner.isScanningGuild then return end

	local guildDB = Data:CheckGuildDB()
	if not guildDB then
		--we don't have a guild object to work with
		Scanner.isScanningGuild = false
		self:ResetTooltips()
		return
	end

	Scanner.isScanningGuild = true
	if not guildDB.tabs then guildDB.tabs = {} end

	local tabMin, tabMax = 1, GetNumGuildBankTabs()
	if tabID then
		--if we have tabID we are only scanning a specific tab
		tabMin, tabMax = tabID, tabID
	end
	Debug(BSYC_DL.INFO, "SaveGuildBank", "FoundGuild", Unit.atGuildBank, tabMin, tabMax)

	for tab=tabMin, tabMax do
		local slotItems = {}
		local _, _, isViewable = GetGuildBankTabInfo(tab)

		--if we don't check for isViewable we get a weirdo permissions error for the player when they attempt it
		if isViewable then
			for slot = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
				local link = GetGuildBankItemLink(tab, slot)

				if link then
					local shortID = BSYC:GetShortItemID(link)
					local iconTexture, count = GetGuildBankItemInfo(tab, slot)

					--check if it's a battle pet cage or something, pet cage is 82800.  This is the placeholder for battle pets
					--if it's a battlepet link it will be parsed anyways in ParseItemLink
					if shortID and tonumber(shortID) == 82800 then
						link = BSYC:CreateFakeID(nil, nil, findBattlePet(iconTexture, nil, "guild", tab, slot))
					else
						link = BSYC:ParseItemLink(link, count)
					end

					if link then
						Debug(BSYC_DL.FINE, "SaveGuildBank", tab, slot, iconTexture, link)
						table.insert(slotItems, link)
					end
				end
			end
		end

		guildDB.tabs[tab] = slotItems
	end

	local player = Unit:GetPlayerInfo()
	guildDB.money = GetGuildBankMoney()
	guildDB.faction = player.faction
	guildDB.realmKey = player.realmKey
	guildDB.rwsKey = player.rwsKey

	Scanner.isScanningGuild = false
	self:ResetTooltips()
end

function Scanner:SaveGuildBankMoney()
	if not BSYC.tracking.guild then return end
	if not Unit.atGuildBank then return end
	if Scanner.isScanningGuild then return end

	local guildDB = Data:CheckGuildDB()
	if not guildDB then
		self:ResetTooltips()
		return
	end
	Debug(BSYC_DL.INFO, "SaveGuildBankMoney", GetGuildBankMoney())
	guildDB.money = GetGuildBankMoney()
	self:ResetTooltips()
end

function Scanner:SaveWarbandBank(bagID)
	Debug(BSYC_DL.INFO, "SaveWarbandBank", BSYC.tracking.warband)
	if not BSYC.isWarbandActive then return end
	if not BSYC.tracking.warband then return end
	if not Unit.atWarbandBank and not Unit.atBank then return end

	local warbandDB = Data:CheckWarbandBankDB()

	local allTabs = C_Bank.FetchPurchasedBankTabData(Enum.BankType.Account)
	local xGetNumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
	local xGetContainerInfo = (C_Container and C_Container.GetContainerItemInfo) or GetContainerItemInfo

	local function doWarbandSlot(bagID, slotID, tabID)
		if not bagID or not slotID then return end
		local xObj, count, _,_,_,_, link = xGetContainerInfo(bagID, slotID)

		--lets check for C_Container
		if xObj and xObj.hyperlink then
			link = xObj.hyperlink
			count = xObj.stackCount or 1
		end
		if link then
			local tmpItem = BSYC:ParseItemLink(link, count)
			Debug(BSYC_DL.FINE, "doWarbandSlot", bagID, slotID, tabID, tmpItem)
			return tmpItem
		end
	end

	if not bagID then
		--scan everything
		for tabID, tabData in ipairs(allTabs) do
			local slotItems = {}
			if not warbandDB.tabs then warbandDB.tabs = {} end

			if BSYC.WarbandIndex.tabs[tabID] then
				bagID = BSYC.WarbandIndex.tabs[tabID]
				local numSlots = xGetNumSlots(bagID)
				Debug(BSYC_DL.INFO, "SaveWarbandBank", tabID, bagID, numSlots, tabData)

				for slotID = 1, numSlots do
					local link = doWarbandSlot(bagID, slotID, tabID)
					table.insert(slotItems, link)
				end
			end

			warbandDB.tabs[tabID] = slotItems
		end
	else
		--scan specific bag/tab
		local slotItems = {}
		local tabID = BSYC.WarbandIndex.bags[bagID]

		if tabID then
			if not warbandDB.tabs then warbandDB.tabs = {} end
			local numSlots = xGetNumSlots(bagID)
			Debug(BSYC_DL.INFO, "SaveWarbandBank", tabID, bagID, numSlots)

			for slotID = 1, numSlots do
				local link = doWarbandSlot(bagID, slotID, tabID)
				table.insert(slotItems, link)
			end

			warbandDB.tabs[tabID] = slotItems
		end
	end

	self:ResetTooltips()
end

function Scanner:SaveWarbandBankMoney()
	if not BSYC.tracking.warband then return end
	if not Unit.atWarbandBank and not Unit.atBank then return end

	local warbandDB = Data:CheckWarbandBankDB()
	local money = C_Bank.FetchDepositedMoney(Enum.BankType.Account)

	Debug(BSYC_DL.INFO, "SaveWarbandBankMoney", money)
	warbandDB.money = money
	self:ResetTooltips()
end

function Scanner:SaveMailbox(isShow)
	Debug(BSYC_DL.INFO, "SaveMailbox", isShow, Unit.atMailbox, BSYC.tracking.mailbox, self.isCheckingMail)
	if not Unit.atMailbox or not BSYC.tracking.mailbox then return end
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
				local name, itemID, itemTexture, count = GetInboxItem(mailIndex, i)
				local link = GetInboxItemLink(mailIndex, i)

				if name and link then

					--check for battle pet cages
					if itemID and itemID == 82800 then
						link = BSYC:CreateFakeID(nil, nil, findBattlePet(itemTexture, name, "mail", mailIndex, i))
					else
						link = BSYC:ParseItemLink(link, count)
					end

					if link then
						Debug(BSYC_DL.FINE, "SaveMailbox", mailIndex, i, link)
						table.insert(slotItems, link)
					end
				end
			end
		end
	end

	BSYC.db.player.mailbox = slotItems

	self.isCheckingMail = false
	self:ResetTooltips()
end

function Scanner:SendMail(mailTo, addMail)
	Debug(BSYC_DL.INFO, "SendMail", mailTo, addMail, BSYC.tracking.mailbox)
	if not BSYC.tracking.mailbox then return end

	if not addMail then
		if not mailTo then return end
		Scanner.pendingdMail = {items={}}
		Scanner.pendingdMail.mailTo = mailTo

		for i = 1, ATTACHMENTS_MAX_SEND do
			if (_G.HasSendMailItem(i)) then
				local name, itemID, texture, count, quality = _G.GetSendMailItem(i)

				if (itemID) then
					--we don't have to worry about BattletPets as the actual itemLink is returned instead of the PetCage
					local sendLink = _G.GetSendMailItemLink(i)
					local link = BSYC:ParseItemLink(sendLink, count)
					Debug(BSYC_DL.FINE, "SendMail-Queue", mailTo, name, itemID, count, quality, link)

					local slotItems = {}
					slotItems.name = name
					slotItems.link = link
					slotItems.itemID = itemID
					slotItems.texture = texture
					slotItems.count = count
					slotItems.quality = quality
					slotItems.sendLink = sendLink

					table.insert(Scanner.pendingdMail.items, slotItems)
				end
			end
		end
	else
		if not Scanner.pendingdMail.mailTo then return end
		mailTo = Scanner.pendingdMail.mailTo
		local mailItems = Scanner.pendingdMail.items

		local mailRealm = _G.GetRealmName() --get current realm, we will replace if sending to another realm
		if mailTo:find("%-") then --check for another realm
			mailTo, mailRealm = mailTo:match("(.+)-(.+)") --strip the realm
		end
		mailTo = strtrim(mailTo) --strip any spaces/characters just in case

		--grab our DB entry for the recipient if they even exist, if they don't then ignore
		if not BagSyncDB[mailRealm] then return end
		if not BagSyncDB[mailRealm][mailTo] then return end
		local unitObj = BagSyncDB[mailRealm][mailTo]

		if not unitObj.mailbox then unitObj.mailbox = {} end

		for i=1, #mailItems do
			tinsert(unitObj.mailbox, mailItems[i].link)
			--check the cache and remove it to refresh that item
			Data:RemoveTooltipCacheLink(mailItems[i].sendLink)
			Debug(BSYC_DL.FINE, "SendMail-Add", mailTo, mailRealm, mailItems[i].name, mailItems[i].itemID, mailItems[i].link)
		end

		Scanner.pendingdMail = {items={}} --reset everything
	end
	self:ResetTooltips()
end

function Scanner:SaveAuctionHouse()
	Debug(BSYC_DL.INFO, "SaveAuctionHouse", Unit.atAuction, BSYC.tracking.auction)
	if not Unit.atAuction or not BSYC.tracking.auction then return end
	if not BSYC.db.player.auction then BSYC.db.player.auction = {} end

	local slotItems = {}

	if C_AuctionHouse then
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

					local encodeStr = BSYC:EncodeOpts({auction=expTime}, parseLink)
					if encodeStr then
						table.insert(slotItems, encodeStr)
					end
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
				local name, _, count = GetAuctionItemInfo("owner", ahIndex)
				if name then
					local link = GetAuctionItemLink("owner", ahIndex)
					local timeLeft = GetAuctionItemTimeLeft("owner", ahIndex)
					if link and timeLeft and tonumber(timeLeft) then

						count = (count or 1)
						timeLeft = tonumber(timeLeft)

						if not timeLeft or timeLeft < 1 or timeLeft > 4 then timeLeft = 4 end --just in case	

						--since classic doesn't return the exact time on old auction house, we got to add it manually
						--it only does short, long and very long
						local expTime = time() + timestampChk[timeLeft]
						local parseLink = BSYC:ParseItemLink(link, count)

						local encodeStr = BSYC:EncodeOpts({auction=expTime}, parseLink)
						if encodeStr then
							table.insert(slotItems, encodeStr)
						end
					end
				end
			end
		end

	end

	BSYC.db.player.auction.bag = slotItems
	BSYC.db.player.auction.count = #slotItems or 0
	BSYC.db.player.auction.lastscan = time()
	self:ResetTooltips()
end

function Scanner:ProcessCurrencyTransfer(doCurrentPlayer, sourceGUID, currencyID, transferAmt)
	if not BSYC.tracking.currency then return end
	
	--update the source player
	if not doCurrentPlayer and sourceGUID and not Scanner.currencyTransferInProgress then
		Scanner.currencyTransferInProgress = true
		Scanner.lastCurrencyID = currencyID

		local localizedClass, englishClass, localizedRace, englishRace, sex, name, realm = GetPlayerInfoByGUID(sourceGUID)
		Debug(BSYC_DL.INFO, "ProcessCurrencyTransfer", doCurrentPlayer, sourceGUID, name, realm, currencyID, transferAmt)

		if name then
			local player = Unit:GetPlayerInfo(true)
			local tmpRealm = player.realm --default to our current realm.  Because GetPlayerInfoByGUID() returns empty realm if sourceGUID is on the same server.

			--lets get the true realm name from localized for our DB
			--blizzard for some reason sends back an empty string instead of nil, so check for that
			if realm ~= nil and realm ~= '' then
				tmpRealm = Unit:GetTrueRealmName(realm)
			end

			Debug(BSYC_DL.INFO, "CurrencyTransferSourceUpt-1", name, tmpRealm, sourceGUID, currencyID, transferAmt)
			--lets check to see that the source player even exists

			local currencyObj = Data:GetPlayerCurrencyObj(name, tmpRealm, sourceGUID)
			if currencyObj and currencyObj[currencyID] and currencyObj[currencyID].count then
				currencyObj[currencyID].count = currencyObj[currencyID].count - transferAmt
				Debug(BSYC_DL.FINE, "CurrencyTransferSourceUpt-2", name, tmpRealm, sourceGUID, currencyID, transferAmt, currencyObj[currencyID].count)
			else
				BSYC:Print(L.WarningCurrencyUpt.." "..name.." | "..tmpRealm)
			end

			self:ResetTooltips()
			--do not process below as we wait for the CURRENCY_TRANSFER_LOG_UPDATE to process the player
			return
		end

	elseif doCurrentPlayer and Scanner.lastCurrencyID > 0 and Scanner.currencyTransferInProgress then
		--update the current player
		local xGetCurrencyInfo = (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) or GetCurrencyInfo
		local currencyData = xGetCurrencyInfo(Scanner.lastCurrencyID)
		local dofullScan = true

		if currencyData and currencyData.quantity then
			Debug(BSYC_DL.INFO, "CurrencyTransferPlayerUpt", Scanner.lastCurrencyID, currencyData.quantity)
			--lets try to individually update the currency
			if BSYC.db.player.currency[Scanner.lastCurrencyID] then
				BSYC.db.player.currency[Scanner.lastCurrencyID].count = currencyData.quantity
				dofullScan = false
			end
		end
		if dofullScan then
			--something went wrong so lets just scan the entire thing
			Scanner:SaveCurrency(false)
		end
	end

	Scanner.currencyTransferInProgress = false
	Scanner.lastCurrencyID = 0
	self:ResetTooltips()
end

function Scanner:SaveCurrency(showDebug)
	if not BSYC:CanDoCurrency() then return end
	if Unit:InCombatLockdown() then return end
	if showDebug then Debug(BSYC_DL.INFO, "SaveCurrency", BSYC.tracking.currency) end --this function gets spammed like crazy sometimes, so only show debug when requested
	if not BSYC.tracking.currency then return end

	local lastHeader
	local slotItems = {}

	--first lets expand everything just in case
	local whileChk = true
	local exitCount = 0

	--WOTLK still doesn't have all the correct C_CurrencyInfo functions
	local xGetCurrencyListSize = (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize) or GetCurrencyListSize
	local xGetCurrencyListInfo = (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListInfo) or GetCurrencyListInfo
	local xGetCurrencyListLink = (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListLink) or GetCurrencyListLink
	local xExpandCurrencyList = (C_CurrencyInfo and C_CurrencyInfo.ExpandCurrencyList) or ExpandCurrencyList

	--only do this if we have the functions to work with
	if xGetCurrencyListSize then
		while whileChk do
			whileChk = false -- turn the while loop off, it will only continue if we found an unexpanded header until all are expanded
			exitCount = exitCount + 1 --catch all to prevent endless loop

			for k=1, xGetCurrencyListSize() do
				local headerCheck = xGetCurrencyListInfo(k)
				if headerCheck.isHeader and not headerCheck.isHeaderExpanded then
					xExpandCurrencyList(k, true)
					whileChk = true
				end
			end

			--this is a catch all in case something happens above and for some reason it's always true
			if exitCount >= 50 then
				whileChk = false --just in case
				break
			end
		end

		for i=1, xGetCurrencyListSize() do
			local xHeader, xCount, xUseIcon, xIcon1, xIcon2

			local currencyinfo = xGetCurrencyListInfo(i)
			local link = xGetCurrencyListLink(i)
			local currencyID = BSYC:GetShortCurrencyID(link)

			local currName = currencyinfo.name or currencyinfo --classic and wotlk servers don't return an array but a string name instead

			--classic and wotlk do not use array returns for xGetCurrencyListInfo, so lets compensate for it
			if not currencyinfo.name then
				_, xHeader, _, _, _, xCount, xIcon1, xIcon2 = xGetCurrencyListInfo(i)
				--xIcon1 is actually extraCurrencyType, but for SOME REASON they occasionally pass the iconFileID here rather then in xIcon2.  This is straight from the Wow API Wiki
				if xIcon1 and tonumber(xIcon1) and tonumber(xIcon1) > 5 then
					xUseIcon = xIcon1
				elseif xIcon2 and tonumber(xIcon2) and tonumber(xIcon2) > 5 then
					xUseIcon = xIcon2
				else
					xUseIcon = 134400 --question mark
				end
			end

			local isHeader = not currencyID or currencyinfo.isHeader or xHeader
			local currQuantity = currencyinfo.quantity or xCount or 0
			local currIcon = currencyinfo.iconFileID or xUseIcon or 134400 --question mark

			if currName then
				if isHeader then
					lastHeader = currName
				elseif currencyID and not slotItems[currencyID] then --make sure we don't do the same currency twice
					slotItems[currencyID] = slotItems[currencyID] or {}
					slotItems[currencyID].name = currName
					slotItems[currencyID].header = lastHeader
					slotItems[currencyID].count = currQuantity
					slotItems[currencyID].icon = currIcon

				end
			end
		end
	end

	BSYC.db.player.currency = slotItems
	self:ResetTooltips()
end

function Scanner:SaveProfessions()
	Debug(BSYC_DL.INFO, "SaveProfessions", BSYC.tracking.professions)
	if not BSYC:CanDoProfessions() then return end
	if not BSYC.tracking.professions then return end

	--we don't want to do linked tradeskills, guild tradeskills, or a tradeskill from an NPC
	if _G.C_TradeSkillUI.IsTradeSkillLinked() or _G.C_TradeSkillUI.IsTradeSkillGuild() or _G.C_TradeSkillUI.IsNPCCrafting() then return end

	local recipeData = {}
	local tmpRecipe = {}
	local catCheck, catCleanup = {}, {}
	local orderIndex = 0

	Scanner.recipeIDs = C_TradeSkillUI.GetAllRecipeIDs()
	--invert the table, forcing the value to be the key and the key the value, inverted[v] = k  (see TableUtil.lua)
	Scanner.invertedRecipeIDs = tInvert(Scanner.recipeIDs)

	--https://wowpedia.fandom.com/wiki/API_C_TradeSkillUI.GetBaseProfessionInfo
	--https://wowpedia.fandom.com/wiki/API_C_TradeSkillUI.GetTradeSkillLineInfoByID
	local baseInfo = C_TradeSkillUI.GetBaseProfessionInfo()

	local parentSkillLineID, parentSkillLineName

	if not baseInfo or not baseInfo.professionID then
		local professionInfo = C_TradeSkillUI.GetChildProfessionInfo()
		if not professionInfo or not professionInfo.parentProfessionID then return end

		parentSkillLineID = professionInfo.parentProfessionID
		parentSkillLineName = professionInfo.parentProfessionName
	else
		parentSkillLineID = baseInfo.professionID
		parentSkillLineName = baseInfo.professionName
	end

	--https://wowpedia.fandom.com/wiki/API_C_TradeSkillUI.GetTradeSkillLineInfoByID
	--info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)

	if parentSkillLineID and parentSkillLineName then
		--create the categories, sometimes we have professions with no recipes.  We want to store this anyways
		local categories = {C_TradeSkillUI.GetCategories()}
		local categoryCount = 0

		--always refresh the DB to prevent old data from remaining
		BSYC.db.player.professions[parentSkillLineID] = {}
		BSYC.db.player.professions[parentSkillLineID].name = parentSkillLineName
		local parentIDSlot = BSYC.db.player.professions[parentSkillLineID]

		for i, categoryID in ipairs(categories) do
			local categoryData = C_TradeSkillUI.GetCategoryInfo(categoryID)

			if categoryData and categoryData.categoryID and categoryData.skillLineCurrentLevel and categoryData.skillLineCurrentLevel > 0 then

				parentIDSlot.categories = parentIDSlot.categories or {}

				--Legion Engineering, Cateclysm Engineering, etc...
				parentIDSlot.categories[categoryID] = parentIDSlot.categories[categoryID] or {}
				local subCatSlot = parentIDSlot.categories[categoryID]

				--always overwrite because we can have a different level or name then last time
				subCatSlot.name = categoryData.name
				subCatSlot.skillLineCurrentLevel = categoryData.skillLineCurrentLevel
				subCatSlot.skillLineMaxLevel = categoryData.skillLineMaxLevel

				if not catCheck[categoryID] then
					orderIndex = orderIndex + 1
					subCatSlot.orderIndex = orderIndex
					catCheck[categoryID] = orderIndex

					categoryCount = categoryCount + 1
					parentIDSlot.categoryCount = categoryCount
				end
			end
		end

		local recipeCount = 0

		--store the recipes
		for i = 1, #Scanner.recipeIDs do

			if C_TradeSkillUI.GetRecipeInfo(Scanner.recipeIDs[i]) then

				--grab the info in a table
				recipeData = C_TradeSkillUI.GetRecipeInfo(Scanner.recipeIDs[i])

				if recipeData then

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
								subCatSlot.orderIndex = catCheck[subCatData.categoryID]
							end

							--now store the recipe information, but make sure we don't already have the recipe stored
							--we have to do this as sometimes the recipe is scanned multiple times.  It will get refreshed once the profession is saved again though.
							--so technically it will always be up to date
							if not tmpRecipe[recipeData.recipeID] then
								subCatSlot.recipes = (subCatSlot.recipes or "").."|"..recipeData.recipeID
								tmpRecipe[recipeData.recipeID] = true

								recipeCount = recipeCount + 1
								parentIDSlot.recipeCount = recipeCount
							end

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
		BSYC.db.player.professions[skillLine] = BSYC.db.player.professions[skillLine] or {} --use any refreshed DB from above or start a new one if not found

		local parentIDSlot = BSYC.db.player.professions[skillLine]
		parentIDSlot.name = name
		parentIDSlot.skillLineCurrentLevel = rank
		parentIDSlot.skillLineMaxLevel = maxRank
	end

	if fishing then
		local name, _, rank, maxRank, _, _, skillLine = GetProfessionInfo(fishing)
		BSYC.db.player.professions[skillLine] = BSYC.db.player.professions[skillLine] or {} --use any refreshed DB from above or start a new one if not found

		local parentIDSlot = BSYC.db.player.professions[skillLine]
		parentIDSlot.name = name
		parentIDSlot.skillLineCurrentLevel = rank
		parentIDSlot.skillLineMaxLevel = maxRank
	end

	--as a precaution lets do a tradeskill cleanup just in case
	self:CleanupProfessions()
end

function Scanner:CleanupProfessions()
	Debug(BSYC_DL.INFO, "CleanupProfessions", BSYC.tracking.professions)
	if not BSYC:CanDoProfessions() then return end
	if not BSYC.tracking.professions then return end

	--lets remove unlearned tradeskills
	local tmpList = {}

	for i = 1, select("#", GetProfessions()) do
		local prof = select(i, GetProfessions())
		if prof then
			local name, _, _, _, _, _, skillLine = GetProfessionInfo(prof)
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

