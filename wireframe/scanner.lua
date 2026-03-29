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
local Utility = BSYC:GetModule("Utility")
local L = BSYC.L

local _G = _G
local type, tonumber, tostring = type, tonumber, tostring
local pairs, ipairs = pairs, ipairs
local tinsert, tconcat = table.insert, table.concat
local strtrim = _G.strtrim
local strmatch = string.match
local strfind = string.find
local time = _G.time
local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local Enum = _G.Enum
local C_Container = _G.C_Container
local C_TooltipInfo = _G.C_TooltipInfo
local C_PetJournal = _G.C_PetJournal
local C_TradeSkillUI = _G.C_TradeSkillUI
local C_AuctionHouse = _G.C_AuctionHouse
local C_Bank = _G.C_Bank
local GetInventoryItemLink = _G.GetInventoryItemLink
local GetInventoryItemCount = _G.GetInventoryItemCount
local GetInventorySlotInfo = _G.GetInventorySlotInfo
local GetVoidItemInfo = _G.GetVoidItemInfo
local GetNumGuildBankTabs = _G.GetNumGuildBankTabs
local GetGuildBankTabInfo = _G.GetGuildBankTabInfo
local GetGuildBankItemLink = _G.GetGuildBankItemLink
local GetGuildBankItemInfo = _G.GetGuildBankItemInfo
local GetGuildBankMoney = _G.GetGuildBankMoney
local CheckInbox = _G.CheckInbox
local GetInboxNumItems = _G.GetInboxNumItems
local GetInboxItem = _G.GetInboxItem
local GetInboxItemLink = _G.GetInboxItemLink
local GetSendMailItem = _G.GetSendMailItem
local GetSendMailItemLink = _G.GetSendMailItemLink
local GetRealmName = _G.GetRealmName
local GetNumAuctionItems = _G.GetNumAuctionItems
local GetAuctionItemInfo = _G.GetAuctionItemInfo
local GetAuctionItemLink = _G.GetAuctionItemLink
local GetAuctionItemTimeLeft = _G.GetAuctionItemTimeLeft
local GetPlayerInfoByGUID = _G.GetPlayerInfoByGUID
local GetProfessions = _G.GetProfessions
local GetProfessionInfo = _G.GetProfessionInfo
local IsReagentBankUnlocked = _G.IsReagentBankUnlocked
local HasKey = _G.HasKey
local CanUseVoidStorage = _G.CanUseVoidStorage
local ATTACHMENTS_MAX_RECEIVE = _G.ATTACHMENTS_MAX_RECEIVE
local ATTACHMENTS_MAX_SEND = _G.ATTACHMENTS_MAX_SEND
local tInvert = _G.tInvert

local BagIndex = Enum and Enum.BagIndex
local BankType = Enum and Enum.BankType

--https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/AddOns/Blizzard_VoidStorageUI/Blizzard_VoidStorageUI.lua
local VOID_STORAGE_MAX = 80
local VOID_STORAGE_PAGES = 2

local MAX_GUILDBANK_SLOTS_PER_TAB = 98

local FirstEquipped = _G.INVSLOT_FIRST_EQUIPPED
local LastEquipped = _G.INVSLOT_LAST_EQUIPPED

local CURRENCY_QUESTION_ICON = 134400
local AUCTION_TIMELEFT_SECONDS = { 30*60, 2*60*60, 12*60*60, 48*60*60 } -- reuse to avoid per-scan alloc

--backup scanner in case C_TooltipInfo doesn't exist
local scannerTooltip = CreateFrame("GameTooltip", "BagSyncScannerTooltip", UIParent, "GameTooltipTemplate")

Scanner.currencyTransferInProgress = false
Scanner.lastCurrencyID = 0
Scanner.pendingMail = { items = {} }

local function Debug(level, ...)
	if BSYC.DEBUG then BSYC.DEBUG(level, "Scanner", ...) end
end

local function IsSafeTable(v)
	if Utility and Utility.IsSafeTable then
		return Utility:IsSafeTable(v)
	end
	-- Safe type check to avoid crashing on secret values (Retail 12.0+)
	local ok, result = pcall(_G.type, v)
	if ok then return result == "table" end
	return false
end

local function InvertArray(list)
	if not list then return {} end
	if tInvert then
		return tInvert(list)
	end
	local inverted = {}
	for k, v in pairs(list) do
		inverted[v] = k
	end
	return inverted
end

local function PickCurrencyIcon(icon1, icon2)
	--icon1 is extraCurrencyType on older APIs, but some clients pass iconFileID here.
	if icon1 and tonumber(icon1) and tonumber(icon1) > 5 then
		return icon1
	end
	if icon2 and tonumber(icon2) and tonumber(icon2) > 5 then
		return icon2
	end
	return CURRENCY_QUESTION_ICON
end

local function UnpackCurrencyInfo(infoOrName, isHeaderFlag, isHeaderExpandedFlag, count, extraCurrencyType, iconFileID)
	if type(infoOrName) == "table" then
		-- Currency info tables from C_CurrencyInfo.GetCurrencyListInfo are safe to read
		-- (name, isHeader, quantity, iconFileID are public API properties)
		return infoOrName.name, infoOrName.isHeader, infoOrName.isHeaderExpanded, infoOrName.quantity or 0, infoOrName.iconFileID or CURRENCY_QUESTION_ICON
	end
	return infoOrName, isHeaderFlag, isHeaderExpandedFlag, count or 0, PickCurrencyIcon(extraCurrencyType, iconFileID)
end

--run once we are not queued by a queue check
function Scanner:_ResetTooltipsNow()
	self._tooltipResetQueued = nil
	--the true is to set it to silent and not return an error if not found
	local tooltipModule = BSYC:GetModule("Tooltip", true)
	if tooltipModule then tooltipModule:ResetLastLink() end
end

--lets add a spam check for this because multiple scanners can be requesting it at same time.
function Scanner:ResetTooltips()
	if self._tooltipResetQueued then return end
	self._tooltipResetQueued = true
	BSYC:StartTimer("BAGSYNC_SCANNER_RESET_TOOLTIPS", 0, Scanner, "_ResetTooltipsNow")
end

--https://warcraft.wiki.gg/wiki/BagID
--https://warcraft.wiki.gg/wiki/Enum.BagIndex
function Scanner:GetBagSlots(bagType)
	if bagType == "bag" then
		return BagIndex.Backpack, BagIndex.Bag_4

	elseif bagType == "bank" then
		if BSYC.IsBankTabsActive then
			return BagIndex.CharacterBankTab_1, BagIndex.CharacterBankTab_6
		else
			--classic server bank bags start at 5 so these are off by one, the actual bank slot 5 is the reagentbank variable, so we have to use that
			--that's because the classic bank slots are wrong, so all of them need to be subtracted by 1.
			--https://us.forums.blizzard.com/en/wow/t/bug-enumbagslotflags-keys-different-to-retail/1912948
			--Special thanks to Schlapstick on anniversary server for helping me out with this. :)
			local firstBankSlot = (not BSYC.IsReagentBagActive and BagIndex.ReagentBag) or BagIndex.BankBag_1
			return firstBankSlot, BagIndex.BankBag_7
		end
	end
end

function Scanner:IsBackpack(bagid)
	if not bagid then return false end
	return bagid == BagIndex.Backpack
end

function Scanner:IsBackpackBag(bagid)
	if not bagid then return false end
	local minCnt, maxCnt = self:GetBagSlots("bag")
	return bagid >= minCnt and bagid <= maxCnt
end

function Scanner:IsKeyring(bagid)
	if not bagid then return false end
	if bagid == BagIndex.Keyring and (not HasKey or not HasKey()) then
		return false
	end
	return bagid == BagIndex.Keyring
end

function Scanner:IsBank(bagid)
	if not bagid then return false end
	return bagid == BagIndex.Bank
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
	return bagid == BagIndex.ReagentBag
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

	--save reagent bag if active
	if BSYC.IsReagentBagActive then
		self:SaveBag("bag", BagIndex.ReagentBag)
	end

	--check keyring, Enum.BagIndex.Keyring is nil on servers that have it disabled
	if BagIndex.Keyring and HasKey and HasKey() then
		self:SaveBag("bag", BagIndex.Keyring)
	else
		--cleanup old keyring stuff if it's disabled
		local xKeyRing = BagIndex.Keyring or -1
		if xKeyRing and BSYC.db.player.bag and BSYC.db.player.bag[xKeyRing] then
			BSYC.db.player.bag[xKeyRing] = nil
		end
	end

	--save currency (skip retry logic during startup - if list is empty, save empty and let CURRENCY_DISPLAY_UPDATE fix it)
	-- Delay by 3 seconds to allow login events (UNIT_INVENTORY_CHANGED, BAG_UPDATE) to settle
	-- This prevents race conditions where rapid bag updates interrupt currency scanning
	Debug(BSYC_DL.FINE, "StartupScans - Queueing SaveCurrency with 3-second delay to allow login events to settle")
	BSYC:StartTimer("StartupCurrency", 3, Scanner, "SaveCurrency", true, true)
	-- Note: CURRENCY_DISPLAY_UPDATE will handle any additional currency updates if needed

	--cleanup the auction DB
	Data:CheckExpiredAuctions()

	--cleanup any unlearned tradeskills
	self:CleanupProfessions()

	--populate the cache
	Data:PopulateItemCache("background")

	BSYC.startupScanChk = true
end

function Scanner:SaveBag(bagtype, bagid)
	Debug(BSYC_DL.INFO, "SaveBag", bagtype, bagid, BSYC.tracking.bag)
	if not bagtype or not bagid then return end
	if not BSYC.tracking[bagtype] then return end
	if not BSYC.db.player then return end

	local bagDB = BSYC.db.player[bagtype]
	if not bagDB then
		bagDB = {}
		BSYC.db.player[bagtype] = bagDB
	end

	-- CLEAR FIRST (important!)
	bagDB[bagid] = nil

	local api = BSYC.API
	local getNumSlots = api and api.GetContainerNumSlots
	local getContainerLinkCount = api and api.GetContainerItemLinkCount
	if not getNumSlots or not getContainerLinkCount then
		-- API missing on this client; skip scan to avoid errors.
		return
	end

	local numSlots = getNumSlots(bagid)
	if numSlots and numSlots > 0 then
		local slotItems = {}

		for slot = 1, numSlots do
			local link, count = getContainerLinkCount(bagid, slot)
			if link then
				local tmpItem = BSYC:ParseItemLink(link, count)
				Debug(BSYC_DL.FINE, "SaveBag", bagtype, bagid, tmpItem)
				slotItems[#slotItems + 1] = tmpItem
			end
		end

		bagDB[bagid] = slotItems
	else
		bagDB[bagid] = nil
	end
	self:ResetTooltips()
end

function Scanner:SaveEquippedBags(bagtype)
	Debug(BSYC_DL.INFO, "SaveEquippedBags", bagtype, BSYC.options.showEquipBagSlots, BSYC.IsBankTabsActive)
	if not bagtype then return end
	if not BSYC.db.player then return end

	--don't save bank bags if tabs is enabled, because they are using bank tabs instead
	if bagtype == "bank" and BSYC.IsBankTabsActive then
		if BSYC.db.player.equipbags and BSYC.db.player.equipbags.bank then BSYC.db.player.equipbags.bank = nil end
		return
	end
	if not BSYC.db.player.equipbags then BSYC.db.player.equipbags = {} end
	if not BSYC.db.player.equipbags.bag then BSYC.db.player.equipbags.bag = {} end
	if not BSYC.IsBankTabsActive and not BSYC.db.player.equipbags.bank then BSYC.db.player.equipbags.bank = {} end

	local containerToInventoryID = C_Container and C_Container.ContainerIDToInventoryID
	if not containerToInventoryID then return end

	local slotItems = {}

	-- add the bag slots (EQUIPPED bags only; do NOT include Backpack/container 0)
	local minCnt, maxCnt

	if bagtype == "bag" then
		-- equipped bag containers are 1..4; backpack (0) is NOT an equipped bag slot
		minCnt, maxCnt = BagIndex.Bag_1, BagIndex.Bag_4
	else
		-- bank equip bags stay based on GetBagSlots()
		minCnt, maxCnt = self:GetBagSlots(bagtype)
	end

	-- sanity range for equipped bag inventory slots (Bag0Slot..Bag3Slot)
	local bagInvMin, bagInvMax
	if bagtype == "bag" and GetInventorySlotInfo then
		bagInvMin = GetInventorySlotInfo("Bag0Slot")
		bagInvMax = GetInventorySlotInfo("Bag3Slot")
	end

	for i = minCnt, maxCnt do
		local invID = containerToInventoryID(i)

		-- OPTIONAL HARDENING: ensure this invID is actually a bag slot
		if bagtype == "bag" then
			if not (invID and bagInvMin and bagInvMax and invID >= bagInvMin and invID <= bagInvMax) then
				invID = nil
			end
		end

		if invID then
			local bagLink = GetInventoryItemLink("player", invID)
			if bagLink then
				local parseLink = BSYC:ParseItemLink(bagLink)
				if parseLink then
					local encodeStr = BSYC:EncodeOpts({bagslot=i}, parseLink)
					if encodeStr then
						slotItems[#slotItems + 1] = encodeStr
					end
				end
			end
		end
	end

	BSYC.db.player.equipbags[bagtype] = slotItems
	self:ResetTooltips()
end

function Scanner:SaveEquipment()
	Debug(BSYC_DL.INFO, "SaveEquipment", BSYC.tracking.equip)
	if not BSYC.tracking.equip then return end
	if not BSYC.db.player then return end
	if not BSYC.db.player.equip then BSYC.db.player.equip = {} end

	local slotItems = {}

	for slot = FirstEquipped, LastEquipped do
		local link = GetInventoryItemLink("player", slot)
		if link then
			local count = GetInventoryItemCount("player", slot)
			local tmpItem =  BSYC:ParseItemLink(link, count)
			Debug(BSYC_DL.FINE, "SaveEquipment", tmpItem, slot)
			slotItems[#slotItems + 1] = tmpItem
		end
	end

	self:SaveEquippedBags("bag")

	--check for ProfessionsFrame Inventory Slots
	if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInventorySlots then

		--https://github.com/tomrus88/BlizzardInterfaceCode/blob/fe4bab5c1ffc87ae2919478efc59d03b76ef6b19/Interface/AddOns/Blizzard_Tutorials/Blizzard_Tutorials_Professions.lua
		local profInvSlots = C_TradeSkillUI.GetProfessionInventorySlots()

		if IsSafeTable(profInvSlots) then
			for index = 1, #profInvSlots do
				local slotNumber = profInvSlots[index] + 1
				local link = GetInventoryItemLink("player", slotNumber)
				if link then
					local count = GetInventoryItemCount("player", slotNumber)
					local tmpItem =  BSYC:ParseItemLink(link, count)
					Debug(BSYC_DL.FINE, "SaveEquipment", "ProfessionSlot", tmpItem, slotNumber)
					slotItems[#slotItems + 1] = tmpItem
				end
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

	if rootOnly then
		--force scan of bank bag -1, since blizzard never sends updates for it
		if BagIndex.Bank then
			self:SaveBag("bank", BagIndex.Bank)
		end
		self:ResetTooltips()
		return
	end

	--lets refresh the bank database, especially if the bagids got changed or we are using bank tabs now
	if BSYC.db.player.bank then BSYC.db.player.bank = {} end

	--force scan of bank bag -1, since blizzard never sends updates for it
	if BagIndex.Bank then
		self:SaveBag("bank", BagIndex.Bank)
	end

	local minCnt, maxCnt = self:GetBagSlots("bank")
	if minCnt and maxCnt then
		for i = minCnt, maxCnt do
			self:SaveBag("bank", i)
		end
	end
	--scan the reagents as part of the bank scan, but make sure it's even enabled on server
	if IsReagentBankUnlocked then self:SaveReagents() end

	self:ResetTooltips()
end

function Scanner:SaveReagents()
	Debug(BSYC_DL.INFO, "SaveReagents", Unit.atBank, BSYC.tracking.reagents)
	if not Unit.atBank or not BSYC.tracking.reagents then return end

	if IsReagentBankUnlocked and IsReagentBankUnlocked() then
		self:SaveBag("reagents", BagIndex.Reagentbank)
	end
	self:ResetTooltips()
end

function Scanner:SaveVoidBank()
	Debug(BSYC_DL.INFO, "SaveVoidBank", Unit.atVoidBank, BSYC.tracking.void)
	if not Unit.atVoidBank or not BSYC.tracking.void then return end

	if not CanUseVoidStorage or not GetVoidItemInfo then
		-- API missing; clear stored data to avoid stale output.
		if BSYC.db.player.void then BSYC.db.player.void = nil end
		return
	end
	if not CanUseVoidStorage() then return end

	if not BSYC.db.player.void then BSYC.db.player.void = {} end

	local slotItems = {}

	for tab = 1, VOID_STORAGE_PAGES do
		for i = 1, VOID_STORAGE_MAX do
			local link = GetVoidItemInfo(tab, i)
			if link then
				slotItems[#slotItems + 1] = BSYC:ParseItemLink(link)
			end
		end
	end

	BSYC.db.player.void = slotItems
	self:ResetTooltips()
end

local petCacheByName = {}
local petCacheByIcon = {}
local petCachePetCount = 0

local function HideBattlePetTooltips()
	local battlePetTooltip = _G.BattlePetTooltip
	if battlePetTooltip then battlePetTooltip:Hide() end
	local floatingBattlePetTooltip = _G.FloatingBattlePetTooltip
	if floatingBattlePetTooltip then floatingBattlePetTooltip:Hide() end
end

local function GetBattlePetInfoFromTooltip(typeSlot, arg1, arg2)
	if typeSlot == "guild" then
		--MOP Classic and a few other classic servers don't have C_TooltipInfo implemented for some stupid reason. So check for that.  *facepalm*
		if C_TooltipInfo and C_TooltipInfo.GetGuildBankItem then
			local data = C_TooltipInfo.GetGuildBankItem(arg1, arg2)
			if IsSafeTable(data) then
				return data.battlePetSpeciesID, data.battlePetLevel, data.battlePetBreedQuality,
					data.battlePetMaxHealth, data.battlePetPower, data.battlePetSpeed, data.battlePetName, data.id
			end
			return
		end

		local speciesID, level, breedQuality, maxHealth, power, speed, name = scannerTooltip:SetGuildBankItem(arg1, arg2)
		scannerTooltip:Hide()
		if speciesID and speciesID > 0 then
			return speciesID, level, breedQuality, maxHealth, power, speed, name
		end
		return
	end

	-- mail
	if C_TooltipInfo and C_TooltipInfo.GetInboxItem then
		local data = C_TooltipInfo.GetInboxItem(arg1, arg2)
		if IsSafeTable(data) then
			return data.battlePetSpeciesID, data.battlePetLevel, data.battlePetBreedQuality,
				data.battlePetMaxHealth, data.battlePetPower, data.battlePetSpeed, data.battlePetName, data.id
		end
		return
	end

	local _, speciesID, level, breedQuality, maxHealth, power, speed, name = scannerTooltip:SetInboxItem(arg1)
	scannerTooltip:Hide()
	if speciesID and speciesID > 0 then
		return speciesID, level, breedQuality, maxHealth, power, speed, name
	end
end

local function findBattlePet(iconTexture, petName, typeSlot, arg1, arg2)
	Debug(BSYC_DL.INFO, "findBattlePet", iconTexture, petName, typeSlot, arg1, arg2, C_TooltipInfo and 'C_TooltipInfo', C_PetJournal and 'C_PetJournal')

	local speciesID, level, breedQuality, maxHealth, power, speed, name, dataID

	if BSYC.options.enableAccurateBattlePets and arg1 then
		--https://github.com/tomrus88/BlizzardInterfaceCode/blob/4e7b4f5df63d240038912624218ebb9c0c8a3edf/Interface/SharedXML/Tooltip/TooltipDataRules.lua
		--it may be possible to use C_PetJournal.GetPetStats(petID) in the future if the guildbank and mailbox return the GUID of the pet
		speciesID, level, breedQuality, maxHealth, power, speed, name, dataID = GetBattlePetInfoFromTooltip(typeSlot, arg1, arg2)

		--fixes a slight issue where occasionally due to server delay, the BattlePet tooltips are still shown on the screen and overlaps the GameTooltip
		HideBattlePetTooltips()

		if speciesID then
			return speciesID, level, breedQuality, maxHealth, power, speed, name
		end
	end

	if petName and C_PetJournal then
		local cachedSpeciesId = petCacheByName[petName]
		if cachedSpeciesId then
			return cachedSpeciesId
		end
		local speciesId = C_PetJournal.FindPetIDByName(petName)
		if speciesId then
			petCacheByName[petName] = speciesId
			return speciesId
		end
	end

	--this can be totally inaccurate, but until Blizzard allows us to get more info from the GuildBank in regards to Battle Pets.  This is the fastest way without scanning in tooltips.
	--Example:  Toxic Wasteling shares the same icon as Jade Oozeling
	if iconTexture and C_PetJournal and dataID ~= 82800 then
		local cachedSpeciesId = petCacheByIcon[iconTexture]
		if cachedSpeciesId then
			return cachedSpeciesId
		end

		local numPetsFn = C_PetJournal.GetNumPets
		local numPets = numPetsFn and numPetsFn() or 0
		if numPets ~= petCachePetCount then
			petCachePetCount = numPets
			for k in pairs(petCacheByIcon) do
				petCacheByIcon[k] = nil
			end
		end

		if numPets > 0 and C_PetJournal.GetPetInfoByIndex then
			for index = 1, numPets do
				local _, speciesID, _, _, _, _, _, _, icon = C_PetJournal.GetPetInfoByIndex(index)
				if icon == iconTexture then
					petCacheByIcon[iconTexture] = speciesID
					return speciesID
				end
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
	if not tabMax or tabMax < 1 then
		Scanner.isScanningGuild = false
		self:ResetTooltips()
		return
	end
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
						slotItems[#slotItems + 1] = link
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

local function ParseWarbandSlot(getContainerLinkCount, bagID, slotID)
	if not bagID or not slotID then return end
	local link, count = getContainerLinkCount(bagID, slotID)
	if link then
		local tmpItem = BSYC:ParseItemLink(link, count)
		Debug(BSYC_DL.FINE, "ParseWarbandSlot", bagID, slotID, tmpItem)
		return tmpItem
	end
end

function Scanner:SaveWarbandBank(bagID)
	Debug(BSYC_DL.INFO, "SaveWarbandBank", BSYC.tracking.warband)
	if not BSYC.isWarbandActive then return end
	if not BSYC.tracking.warband then return end
	if not Unit.atWarbandBank and not Unit.atBank then return end

	if not C_Bank or not C_Bank.FetchPurchasedBankTabData then return end
	if not BankType or not BankType.Account then return end
	local warbandDB = Data:CheckWarbandBankDB()
	if not warbandDB then return end

	local allTabs = C_Bank.FetchPurchasedBankTabData(BankType.Account)
	if not allTabs then return end

	local api = BSYC.API
	local getNumSlots = api and api.GetContainerNumSlots
	local getContainerLinkCount = api and api.GetContainerItemLinkCount
	if not getNumSlots or not getContainerLinkCount then
		-- API missing on this client; skip scan to avoid errors.
		return
	end

	if not bagID then
		--scan everything
		for tabID, tabData in ipairs(allTabs) do
			local slotItems = {}
			if not warbandDB.tabs then warbandDB.tabs = {} end

			local tabBagID = BSYC.WarbandIndex.tabs[tabID]
			if tabBagID then
				local numSlots = getNumSlots(tabBagID)
				Debug(BSYC_DL.INFO, "SaveWarbandBank", tabID, tabBagID, numSlots, tabData)

				for slotID = 1, numSlots do
					local link = ParseWarbandSlot(getContainerLinkCount, tabBagID, slotID)
					if link then
						slotItems[#slotItems + 1] = link
					end
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
			local numSlots = getNumSlots(bagID)
			Debug(BSYC_DL.INFO, "SaveWarbandBank", tabID, bagID, numSlots)

			for slotID = 1, numSlots do
				local link = ParseWarbandSlot(getContainerLinkCount, bagID, slotID)
				if link then
					slotItems[#slotItems + 1] = link
				end
			end

			warbandDB.tabs[tabID] = slotItems
		end
	end

	self:ResetTooltips()
end

function Scanner:SaveWarbandBankMoney()
	if not BSYC.tracking.warband then return end
	if not Unit.atWarbandBank and not Unit.atBank then return end
	if not C_Bank or not C_Bank.FetchDepositedMoney then return end
	if not BankType or not BankType.Account then return end

	local warbandDB = Data:CheckWarbandBankDB()
	if not warbandDB then return end
	local money = C_Bank.FetchDepositedMoney(BankType.Account)

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
						slotItems[#slotItems + 1] = link
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
	Debug(BSYC_DL.INFO, "SendMail", mailTo, addMail)
	if not BSYC.tracking.mailbox then return end
	if not Unit.atMailbox then return end

	if not addMail then
		if not mailTo then return end

		Scanner.pendingMail = Scanner.pendingMail or {items={}}
		Scanner.pendingMail.mailTo = mailTo
		local pendingItems = Scanner.pendingMail.items
		for i = #pendingItems, 1, -1 do
			pendingItems[i] = nil
		end

		for i=1, ATTACHMENTS_MAX_SEND do
			local name, itemID, texture, count, quality = GetSendMailItem(i)
			if itemID then
				--we don't have to worry about BattlePets as the actual itemLink is returned instead of the PetCage
				local sendLink = GetSendMailItemLink(i)
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

				tinsert(pendingItems, slotItems)
			end
		end
	else
		if not Scanner.pendingMail or not Scanner.pendingMail.mailTo then return end
		mailTo = Scanner.pendingMail.mailTo
		local mailItems = Scanner.pendingMail.items

		local mailRealm = GetRealmName() --get current realm, we will replace if sending to another realm
		if strfind(mailTo, "%-") then --check for another realm
			local target, realm = strmatch(mailTo, "(.+)-(.+)") --strip the realm
			if target and realm then
				mailTo, mailRealm = target, realm
			end
		end
		if strtrim then
			mailTo = strtrim(mailTo) --strip any spaces/characters just in case
		end

		--grab our DB entry for the recipient if they even exist, if they don't then ignore
		if not BagSyncDB[mailRealm] then return end
		if not BagSyncDB[mailRealm][mailTo] then return end
		local unitObj = BagSyncDB[mailRealm][mailTo]

		if not unitObj.mailbox then unitObj.mailbox = {} end

		for i=1, #mailItems do
			local entry = mailItems[i]
			tinsert(unitObj.mailbox, entry.link)
			--check the cache and remove it to refresh that item
			Data:RemoveTooltipCacheLink(entry.sendLink)
			Debug(BSYC_DL.FINE, "SendMail-Add", mailTo, mailRealm, entry.name, entry.itemID, entry.link)
		end

		Scanner.pendingMail.mailTo = nil
		for i = #Scanner.pendingMail.items, 1, -1 do
			Scanner.pendingMail.items[i] = nil
		end
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
		if (numActiveAuctions and numActiveAuctions > 0) then
			for ahIndex = 1, numActiveAuctions do

				--https://wow.gamepedia.com/API_C_AuctionHouse.GetOwnedAuctionInfo
				local itemObj = C_AuctionHouse.GetOwnedAuctionInfo(ahIndex)
				if itemObj and not IsSafeTable(itemObj) then
					itemObj = nil
				end

				--we only want active auctions not sold one.  So check itemObj.status
				if itemObj and itemObj.timeLeftSeconds and itemObj.status == 0 then

					local expTime = time() + itemObj.timeLeftSeconds -- current Time + advance time in seconds to get expiration time and date
					local itemCount = itemObj.quantity or 1
					local parseLink

					if itemObj.itemLink then
						parseLink = BSYC:ParseItemLink(itemObj.itemLink, itemCount)
					elseif itemObj.itemKey and itemObj.itemKey.itemID then
						parseLink = BSYC:ParseItemLink(itemObj.itemKey.itemID, itemCount)
					end

					local encodeStr = parseLink and BSYC:EncodeOpts({auction=expTime}, parseLink)
					if encodeStr then
						slotItems[#slotItems + 1] = encodeStr
					end
				end
			end
		end

	else
		--this is for WOW Classic Auction House
		local numActiveAuctions = GetNumAuctionItems and GetNumAuctionItems("owner") or 0

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
						local expTime = time() + AUCTION_TIMELEFT_SECONDS[timeLeft]
						local parseLink = BSYC:ParseItemLink(link, count)

						local encodeStr = parseLink and BSYC:EncodeOpts({auction=expTime}, parseLink)
						if encodeStr then
							slotItems[#slotItems + 1] = encodeStr
						end
					end
				end
			end
		end

	end

	BSYC.db.player.auction.bag = slotItems
	BSYC.db.player.auction.count = #slotItems
	BSYC.db.player.auction.lastscan = time()
	self:ResetTooltips()
end

function Scanner:ProcessCurrencyTransfer(doCurrentPlayer, sourceGUID, currencyID, transferAmt, transferCost)
	if not BSYC.tracking.currency then return end

	--update the source player
	if not doCurrentPlayer and sourceGUID and not Scanner.currencyTransferInProgress then
		Scanner.currencyTransferInProgress = true
		Scanner.lastCurrencyID = currencyID
		transferCost = transferCost or 0

		local _, _, _, _, _, name, realm = GetPlayerInfoByGUID(sourceGUID)
		Debug(BSYC_DL.INFO, "ProcessCurrencyTransfer", doCurrentPlayer, sourceGUID, name, realm, currencyID, transferAmt, transferCost)

		if name then
			local player = Unit:GetPlayerInfo(true)
			local tmpRealm = player.realm --default to our current realm.  Because GetPlayerInfoByGUID() returns empty realm if sourceGUID is on the same server.

			--lets get the true realm name from localized for our DB
			--blizzard for some reason sends back an empty string instead of nil, so check for that
			if realm ~= nil and realm ~= '' then
				tmpRealm = Unit:GetTrueRealmName(realm)
			end

			Debug(BSYC_DL.INFO, "CurrencyTransferSourceUpt-1", name, tmpRealm, sourceGUID, currencyID, transferAmt, transferCost)
			--lets check to see that the source player even exists

			local currencyObj = Data:GetPlayerCurrencyObj(name, tmpRealm, sourceGUID)
			if currencyObj and currencyObj[currencyID] and currencyObj[currencyID].count then
				-- GetCostToTransferCurrency returns the TOTAL amount deducted (amount + fee), not just the fee
				local originalCount = currencyObj[currencyID].count
				currencyObj[currencyID].count = originalCount - transferCost
				Debug(BSYC_DL.FINE, "CurrencyTransferSourceUpt-2", name, tmpRealm, sourceGUID, currencyID, transferAmt, transferCost, originalCount, currencyObj[currencyID].count)

				-- Validate that the currency count is not negative after transfer
				if currencyObj[currencyID].count < 0 then
					BSYC:Print("|cFFFF0000Warning:|r Currency transfer resulted in negative count for "..name.." ("..tmpRealm.."). CurrencyID: "..currencyID..", Original: "..originalCount..", Final: "..currencyObj[currencyID].count)
					-- Reset to 0 to prevent corruption
					currencyObj[currencyID].count = 0
				end
			else
				-- Provide more detailed error information
				local errorMsg = L.WarningCurrencyUpt.." "..name.." | "..tmpRealm
				if not currencyObj then
					errorMsg = errorMsg.." (Currency object not found)"
				elseif not currencyObj[currencyID] then
					errorMsg = errorMsg.." (Currency ID "..currencyID.." not found)"
				elseif not currencyObj[currencyID].count then
					errorMsg = errorMsg.." (Currency count is nil)"
				end
				BSYC:Print(errorMsg)
				Debug(BSYC_DL.WARN, "CurrencyTransferSourceUpt-Error", name, tmpRealm, sourceGUID, currencyID, transferAmt, transferCost, currencyObj)
			end

			self:ResetTooltips()
			--do not process below as we wait for the CURRENCY_TRANSFER_LOG_UPDATE to process the player
			return
		end

	elseif doCurrentPlayer and Scanner.lastCurrencyID > 0 and Scanner.currencyTransferInProgress then
		--update the current player
		local getCurrencyInfo = BSYC.API and BSYC.API.GetCurrencyInfo
		local currencyData = getCurrencyInfo and getCurrencyInfo(Scanner.lastCurrencyID)
		-- Currency info tables from C_CurrencyInfo.GetCurrencyInfo are safe to read
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

function Scanner:SaveCurrency(showDebug, skipRetry)
	if not BSYC:CanDoCurrency() then
		return false
	end
	if Unit:InCombatLockdown() then
		return false
	end

	local player = Unit:GetPlayerInfo(true)

	if showDebug then Debug(BSYC_DL.INFO, "SaveCurrency", BSYC.tracking.currency, player and player.name, skipRetry) end --this function gets spammed like crazy sometimes, so only show debug when requested
	if not BSYC.tracking.currency then
		return false
	end

	local lastHeader
	local slotItems = {}

	--WOTLK still doesn't have all the correct C_CurrencyInfo functions
	local getCurrencyListSize = BSYC.API and BSYC.API.GetCurrencyListSize
	local getCurrencyListInfo = BSYC.API and BSYC.API.GetCurrencyListInfo
	local getCurrencyListLink = BSYC.API and BSYC.API.GetCurrencyListLink
	local expandCurrencyList = BSYC.API and BSYC.API.ExpandCurrencyList

	-- Per-player retry counter to prevent cross-character contamination
	-- Use fallback key if player info is not available yet (happens during early startup)
	local playerKey = player and (player.name .. "-" .. (player.realm or ""))
	local retryKey
	if playerKey then
		retryKey = "_currencyRetryCount_" .. playerKey:gsub("[^%w_]", "_")
	else
		-- Fallback for early startup when player info isn't available yet
		-- This allows retries to be queued even without full player information
		retryKey = "_currencyRetryCount_startup_pending"
	end

	-- If skipRetry is true, bypass all retry logic and save whatever we have
	-- This is used when retry attempts have been exhausted or when CURRENCY_DISPLAY_UPDATE forces a save
	if skipRetry then
		-- Skip all retry logic and proceed directly to saving
		if showDebug then Debug(BSYC_DL.INFO, "SaveCurrency", "skipRetry=true, proceeding to save") end
	else
		-- Check if the API is ready - if not, retry with a delay
		-- This handles the race condition where currency list hasn't loaded from server yet
		if not (getCurrencyListSize and getCurrencyListInfo) then
			if retryKey then
				self[retryKey] = (self[retryKey] or 0) + 1
				if self[retryKey] <= 5 then
					Debug(BSYC_DL.INFO, "SaveCurrency", "Retry", self[retryKey], "API not ready yet, player:", playerKey)
					BSYC:StartTimer("SaveCurrency_Retry", 1, Scanner, "SaveCurrency", false)
				else
					Debug(BSYC_DL.WARN, "SaveCurrency", "Max retries reached, API not available, player:", playerKey)
					self[retryKey] = nil
				end
			else
				-- No player key available - don't save empty table
				-- CURRENCY_DISPLAY_UPDATE will retry when player data is ready
				if showDebug then Debug(BSYC_DL.WARN, "SaveCurrency -> (Deferred: API not ready and no Player Key)") end
			end
			self:ResetTooltips()
			return false
		end

		-- Check if the list has any data - if listSize is 0 or nil, the currency
		-- data hasn't loaded from server yet. Retry with a delay.
		local listSize = getCurrencyListSize()
		if not listSize or listSize == 0 then
			if retryKey then
				self[retryKey] = (self[retryKey] or 0) + 1
				if self[retryKey] <= 5 then
					Debug(BSYC_DL.INFO, "SaveCurrency", "Retry", self[retryKey], "listSize not ready yet:", listSize, "player:", playerKey)
					BSYC:StartTimer("SaveCurrency_Retry", 1, Scanner, "SaveCurrency", false)
					self:ResetTooltips()
					return
				else
					-- Max retries reached - defer to CURRENCY_DISPLAY_UPDATE instead of saving empty table
					-- Reset retry counter so CURRENCY_DISPLAY_UPDATE can trigger a fresh save
					Debug(BSYC_DL.WARN, "SaveCurrency", "Max retries reached, deferring to CURRENCY_DISPLAY_UPDATE, player:", playerKey)
					self[retryKey] = nil
					self:ResetTooltips()
					return
				end
			else
				-- No player key available yet - don't save empty table during startup
				-- CURRENCY_DISPLAY_UPDATE will retry when player data is ready
				if showDebug then Debug(BSYC_DL.WARN, "SaveCurrency -> (Deferred: No Player Key - waiting for CURRENCY_DISPLAY_UPDATE)") end
				self:ResetTooltips()
				return
			end
		end

		-- Reset retry count on success
		if retryKey then
			self[retryKey] = nil
		end
	end

	--first lets expand everything just in case (supports both retail-table and classic multi-return APIs)
	if expandCurrencyList then
		for _ = 1, 50 do
			local expandedAny = false
			local listSize = getCurrencyListSize()

			-- Safety check: if listSize becomes 0 or nil during expansion, stop
			if not listSize or listSize == 0 then
				break
			end

			for i = 1, listSize do
				--Retail returns a table; Classic/WotLK can return multiple values.
				local currencyInfoOrName, isHeaderFlag, isHeaderExpandedFlag = getCurrencyListInfo(i)

				-- Handle nil returns from getCurrencyListInfo - can happen due to race conditions
				if currencyInfoOrName then
					local isHeader, isExpanded
					if type(currencyInfoOrName) == "table" then
						-- Currency info tables from C_CurrencyInfo.GetCurrencyListInfo are safe to read
						isHeader = currencyInfoOrName.isHeader
						isExpanded = currencyInfoOrName.isHeaderExpanded
					else
						isHeader = isHeaderFlag
						isExpanded = isHeaderExpandedFlag
					end
					if isHeader and not isExpanded then
						-- Wrap expansion in pcall to catch any errors and continue
						local ok, err = pcall(expandCurrencyList, i, true)
						if not ok then
							Debug(BSYC_DL.WARN, "SaveCurrency", "expandCurrencyList failed at index", i, "error:", tostring(err))
						else
							expandedAny = true
						end
					end
				end
			end

			if not expandedAny then
				break
			end
		end
	end

	local currencyCount = 0

	-- Re-fetch listSize as it may have changed during expansion
	local listSize = getCurrencyListSize()

	-- Safety check: if listSize is 0 or nil, exit early
	if not listSize or listSize == 0 then
		-- Ensure BSYC.db.player exists before accessing it
		if not BSYC.db then BSYC.db = {} end
		if not BSYC.db.player then BSYC.db.player = {} end
		BSYC.db.player.currency = {}
		self:ResetTooltips()
		return false
	end

	for i = 1, listSize do
		--Retail (C_CurrencyInfo.GetCurrencyListInfo) returns a table.
		--Classic (GetCurrencyListInfo) returns multiple values:
		--name, isHeader, isHeaderExpanded, isTypeUnused, isShowInBackpack, count, extraCurrencyType, iconFileID
		local currencyInfoOrName, isHeaderFlag, isHeaderExpandedFlag, _, _, count, extraCurrencyType, iconFileID = getCurrencyListInfo(i)

		-- Handle nil returns from getCurrencyListInfo - can happen due to race conditions
		if currencyInfoOrName then
			local currName, isHeader, _, currQuantity, currIcon = UnpackCurrencyInfo(currencyInfoOrName, isHeaderFlag, isHeaderExpandedFlag, count, extraCurrencyType, iconFileID)

			if currName then
				if isHeader then
					lastHeader = currName
				else
					local currencyID
					if getCurrencyListLink then
						local link = getCurrencyListLink(i)
						currencyID = BSYC:GetShortCurrencyID(link)
					end

					--Some clients can return nil links sporadically; treat those as headers to preserve grouping behavior.
					if not currencyID then
						lastHeader = currName
					elseif currencyID and not slotItems[currencyID] then --make sure we don't do the same currency twice
						slotItems[currencyID] = {
							name = currName,
							header = lastHeader,
							count = currQuantity,
							icon = currIcon,
						}
						currencyCount = currencyCount + 1
					end
				end
			end
		end
	end

	if showDebug then Debug(BSYC_DL.INFO, "SaveCurrency -> (Index & Saved) CurrencyCount=",currencyCount, player and player.name, "listSize=", listSize) end --this function gets spammed like crazy sometimes, so only show debug when requested

	-- Verify we have a valid player and database before saving
	if not player then
		self:ResetTooltips()
		return listSize and listSize > 0
	end

	if not BSYC.db or not BSYC.db.player then
		if not BSYC.db then BSYC.db = {} end
		if not BSYC.db.player then BSYC.db.player = {} end
	end

	BSYC.db.player.currency = slotItems
	self:ResetTooltips()

	-- Log if we saved an empty table for debugging purposes
	if currencyCount == 0 and showDebug then
		if listSize and listSize > 0 then
			Debug(BSYC_DL.INFO, "SaveCurrency -> User has 0 currencies (list was ready, count=0)")
		else
			Debug(BSYC_DL.WARN, "SaveCurrency -> Saved empty currency table for", player and player.name or "unknown", "- listSize was 0, currency list not loaded yet")
		end
	end

	local returnValue = listSize and listSize > 0

	-- Return true if the currency list was loaded from server (listSize > 0), false if not ready
	-- This distinguishes between "list not loaded" (need fallback) and "user has 0 currencies" (no fallback needed)
	return returnValue
end

function Scanner:SaveProfessions(bypassCleanup)
	Debug(BSYC_DL.INFO, "SaveProfessions", BSYC.tracking.professions)
	if not BSYC:CanDoProfessions() then return end
	if not BSYC.tracking.professions then return end

	if not BSYC.db.player.professions then BSYC.db.player.professions = {} end

	local player = Unit:GetPlayerInfo(true)
	Debug(BSYC_DL.INFO, "SaveProfessions: Called for player =", player and player.name)

	-- Retail (Dragonflight+): Uses C_TradeSkillUI
	-- Classic/TBC/Wrath: Uses GetTradeSkillInfo/GetCraftInfo APIs
	if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs then
		self:SaveProfessionsRetail(player.name)
	elseif GetNumTradeSkills then
		self:SaveProfessionsClassic(player.name)
	end

	--grab archaeology, fishing (shared between Retail and Classic)
	--first aid was removed in battle for azeroth
	local _, _, archaeology, fishing = GetProfessions()

	local function StoreSecondaryProfession(profIndex)
		if not profIndex then return end
		local name, _, rank, maxRank, _, _, skillLine = GetProfessionInfo(profIndex)
		if not name or not skillLine then return end

		BSYC.db.player.professions[skillLine] = BSYC.db.player.professions[skillLine] or {}
		local parentIDSlot = BSYC.db.player.professions[skillLine]
		parentIDSlot.name = name
		parentIDSlot.skillLineCurrentLevel = rank
		parentIDSlot.skillLineMaxLevel = maxRank
	end

	StoreSecondaryProfession(archaeology)
	StoreSecondaryProfession(fishing)

	--as a precaution lets do a tradeskill cleanup just in case
	if not bypassCleanup then
		self:CleanupProfessions()
	end
end

-- Retail (Dragonflight+) profession saving using C_TradeSkillUI
function Scanner:SaveProfessionsRetail(playerName)
	Debug(BSYC_DL.INFO, "SaveProfessionsRetail", playerName)
	--we don't want to do linked tradeskills, guild tradeskills, or a tradeskill from an NPC
	if C_TradeSkillUI.IsTradeSkillLinked and C_TradeSkillUI.IsTradeSkillLinked() then
		return
	end
	if C_TradeSkillUI.IsTradeSkillGuild and C_TradeSkillUI.IsTradeSkillGuild() then
		return
	end
	if C_TradeSkillUI.IsNPCCrafting and C_TradeSkillUI.IsNPCCrafting() then
		return
	end

	local tmpRecipe = {}
	local catCheck = {}
	local orderIndex = 0
	local recipesByCategory = {}

	-- Wrap GetAllRecipeIDs in pcall to handle potential errors
	local okGetAll, recipeIDs = pcall(C_TradeSkillUI.GetAllRecipeIDs)
	if not okGetAll or not recipeIDs then
		recipeIDs = {}
	end
	Scanner.recipeIDs = recipeIDs
	Scanner.invertedRecipeIDs = InvertArray(Scanner.recipeIDs)

	--https://wowpedia.fandom.com/wiki/API_C_TradeSkillUI.GetBaseProfessionInfo
	--https://wowpedia.fandom.com/wiki/API_C_TradeSkillUI.GetTradeSkillLineInfoByID
	local okBase, baseInfo = pcall(C_TradeSkillUI.GetBaseProfessionInfo)
	if okBase and baseInfo and not IsSafeTable(baseInfo) then baseInfo = nil end
	if not okBase then baseInfo = nil end

	local parentSkillLineID, parentSkillLineName

	if not baseInfo or not baseInfo.professionID then
		local okChild, professionInfo = pcall(C_TradeSkillUI.GetChildProfessionInfo)
		if okChild and professionInfo and not IsSafeTable(professionInfo) then professionInfo = nil end
		if not okChild then professionInfo = nil end

		if not professionInfo or not professionInfo.parentProfessionID then
			-- Fallback: Try to get profession info from GetProfessions()
			-- This can happen when viewing profession UIs that don't have standard base/child structure
			local prof1, prof2, prof3 = GetProfessions()
			local professions = {prof1, prof2, prof3}

			for _, profIndex in ipairs(professions) do
				if profIndex then
					local name, _, _, _, _, _, skillLineID, _, _, _, className = GetProfessionInfo(profIndex)
					-- Skip secondary professions (fishing, archaeology) as they're handled elsewhere
					if skillLineID and name and className ~= "Secondary" then
						-- Check if this profession matches what we have in the trade skill window
						-- by checking if we have recipes for it
						local hasRecipes = false
						if Scanner.recipeIDs and #Scanner.recipeIDs > 0 then
							-- We have recipes open, so this is likely the active profession
							hasRecipes = true
						end

						if hasRecipes then
							parentSkillLineID = skillLineID
							parentSkillLineName = name
							break
						end
					end
				end
			end

			if not parentSkillLineID or not parentSkillLineName then
				return
			end
		else
			parentSkillLineID = professionInfo.parentProfessionID
			parentSkillLineName = professionInfo.parentProfessionName
		end
	else
		parentSkillLineID = baseInfo.professionID
		parentSkillLineName = baseInfo.professionName
	end

	--https://wowpedia.fandom.com/wiki/API_C_TradeSkillUI.GetTradeSkillLineInfoByID
	--info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)

	-- Declare categoryCount outside the if block so it's accessible at the end of the function
	local categoryCount = 0

	if parentSkillLineID and parentSkillLineName then
		--create the categories, sometimes we have professions with no recipes.  We want to store this anyways
		-- GetCategories returns vararg, so we need to wrap it in a function and use pcall properly
		local okCats, categories = pcall(function() return {C_TradeSkillUI.GetCategories()} end)
		if not okCats or not categories or type(categories) ~= "table" then
			categories = {}
		end

		--always refresh the DB to prevent old data from remaining
		BSYC.db.player.professions[parentSkillLineID] = {}
		BSYC.db.player.professions[parentSkillLineID].name = parentSkillLineName
		local parentIDSlot = BSYC.db.player.professions[parentSkillLineID]

		for _, categoryID in ipairs(categories) do
			local okCatData, categoryData = pcall(C_TradeSkillUI.GetCategoryInfo, categoryID)
			if okCatData and categoryData and not IsSafeTable(categoryData) then categoryData = nil end
			if not okCatData then categoryData = nil end

			-- For modern WoW (The War Within+), categories might not have skillLineCurrentLevel
			-- Check if the category has valid data before processing
			if categoryData and categoryData.categoryID then
				local shouldProcess = false

				-- Old way: check if skillLineCurrentLevel > 0
				if categoryData.skillLineCurrentLevel and categoryData.skillLineCurrentLevel > 0 then
					shouldProcess = true
				end

				-- New way: also process if we have recipes in this category
				if not shouldProcess then
					local recipeCountForCat = 0
					for _, recipeID in ipairs(Scanner.recipeIDs) do
						local okRecipe, recipeData = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
						if okRecipe and recipeData and recipeData.categoryID == categoryID then
							recipeCountForCat = recipeCountForCat + 1
						end
					end
					if recipeCountForCat > 0 then
						shouldProcess = true
					end
				end

				if shouldProcess then
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
		end

		local recipeCount = 0

		--store the recipes
		for i = 1, #Scanner.recipeIDs do
			local okRecipe, recipeData = pcall(C_TradeSkillUI.GetRecipeInfo, Scanner.recipeIDs[i])
			if okRecipe and recipeData and not IsSafeTable(recipeData) then recipeData = nil end
			if not okRecipe then recipeData = nil end

			if recipeData then
				if recipeData.learned then
					local categoryID = recipeData.categoryID

					-- In modern WoW (The War Within+), GetCategories() may not return all categoryIDs
					-- So we need to create categories dynamically from recipe data
					if categoryID then
						-- Create the category slot if it doesn't exist
						if not parentIDSlot.categories then
							parentIDSlot.categories = {}
						end
						if not parentIDSlot.categories[categoryID] then
							-- Get category info for this recipe's category
							local okCatInfo, catInfo = pcall(C_TradeSkillUI.GetCategoryInfo, categoryID)
							if okCatInfo and catInfo and not IsSafeTable(catInfo) then catInfo = nil end
							if not okCatInfo then catInfo = nil end

							parentIDSlot.categories[categoryID] = {
								name = catInfo and catInfo.name or "Unknown",
								skillLineCurrentLevel = catInfo and catInfo.skillLineCurrentLevel,
								skillLineMaxLevel = catInfo and catInfo.skillLineMaxLevel,
								orderIndex = catCheck[categoryID] or (#parentIDSlot.categories + 1)
							}
							categoryCount = categoryCount + 1
							parentIDSlot.categoryCount = categoryCount
						end

						if recipeData.recipeID and not tmpRecipe[recipeData.recipeID] then
							tmpRecipe[recipeData.recipeID] = true

							local recipeList = recipesByCategory[categoryID]
							if not recipeList then
								recipeList = {}
								recipesByCategory[categoryID] = recipeList
							end
							recipeList[#recipeList + 1] = tostring(recipeData.recipeID)

							recipeCount = recipeCount + 1
							parentIDSlot.recipeCount = recipeCount
						end
					end
				end
			end

		end

		--finalize recipe strings using the existing DB format: "|<id>|<id>|..."
		local recipeStringCount = 0
		for categoryID, recipeList in pairs(recipesByCategory) do
			local subCatSlot = parentIDSlot.categories and parentIDSlot.categories[categoryID]
			if subCatSlot and recipeList and #recipeList > 0 then
				subCatSlot.recipes = "|" .. tconcat(recipeList, "|")
				recipeStringCount = recipeStringCount + 1
			end
		end
	end
	Debug(BSYC_DL.INFO, "SaveProfessionsRetail [Complete]", playerName)
end

-- Classic (Vanilla/TBC/Wrath) profession saving using GetTradeSkillInfo
-- https://warcraft.wiki.gg/wiki/API_GetTradeSkillInfo
function Scanner:SaveProfessionsClassic(playerName)
	Debug(BSYC_DL.INFO, "SaveProfessionsClassic: START", playerName)

	local numTradeSkills = GetNumTradeSkills()
	if not numTradeSkills or numTradeSkills == 0 then return end

	-- Get profession name from GetTradeSkillLine() (may return "UNKNOWN" on some servers)
	local professionName = GetTradeSkillLine()
	if not professionName then return end

	-- Get skillLine, rank, and maxRank from GetProfessions()
	local professionSkillLine, professionRank, professionMaxRank
	local prof1, prof2 = GetProfessions()

	-- Try to find matching profession from GetProfessions()
	-- GetTradeSkillLine() may return "UNKNOWN" while GetProfessionInfo() returns the real name
	if prof1 or prof2 then
		for _, profIndex in ipairs({prof1, prof2}) do
			if profIndex then
				local name, _, rank, maxRank, _, _, skillLine = GetProfessionInfo(profIndex)
				if name then
					-- Try exact match first
					if name:lower() == professionName:lower() then
						professionSkillLine = tostring(skillLine)
						professionRank = rank
						professionMaxRank = maxRank
						professionName = name  -- Use the correct name from GetProfessionInfo
						break
					end
				end
			end
		end

		-- If exact match failed, try matching against first recipe name
		-- GetTradeSkillInfo(1) often returns the profession name as the first entry
		if not professionSkillLine then
			for i = 1, numTradeSkills do
				local skillName, skillType = GetTradeSkillInfo(i)
				if skillName and skillType ~= "header" and skillType ~= "subheader" then
					-- Found first actual recipe, try matching against it
					for _, profIndex in ipairs({prof1, prof2}) do
						if profIndex then
							local name, _, rank, maxRank, _, _, skillLine = GetProfessionInfo(profIndex)
							if name and (skillName:lower():find(name:lower(), 1, true) or name:lower():find(skillName:lower(), 1, true)) then
								professionSkillLine = tostring(skillLine)
								professionRank = rank
								professionMaxRank = maxRank
								professionName = name
								break
							end
						end
					end
					if professionSkillLine then break end
				end
			end
		end
	end

	-- Fallback for Classic Era: Use a hash of the profession name as skillLine
	-- This is needed because GetProfessions() doesn't work on some Classic servers
	if not professionSkillLine then
		local hash = 0
		for i = 1, #professionName do
			hash = (hash * 31 + string.byte(professionName, i)) % 0x100000000
		end
		professionSkillLine = tostring(hash)
	end

	-- Collect recipes
	local tmpRecipe = {}
	local recipeList = {}
	local recipeCount = 0
	Scanner.recipeIDs = Scanner.recipeIDs or {}

	for i = 1, numTradeSkills do
		local skillName, skillType = GetTradeSkillInfo(i)
		-- Skip headers and subheaders, only collect actual recipes
		if skillName and skillType ~= "header" and skillType ~= "subheader" then
			local recipeID
			local linkType  -- Track link type: "enchant", "item", or nil (trade links are skipped)

			-- Try GetTradeSkillRecipeLink first (Wrath/Cata+)
			-- Note: We skip trade: links as they're not useful for tooltip display
			local recipeLink = GetTradeSkillRecipeLink and GetTradeSkillRecipeLink(i)
			if recipeLink then
				-- Check for enchant: link first (Classic Enchanting)
				recipeID = tonumber(recipeLink:match("enchant:(%d+)"))
				if recipeID then
					linkType = "enchant"
				end
				-- trade: links are skipped - not useful for tooltips
			end

			-- Fallback: Use GetTradeSkillItemLink (works on all Classic servers)
			if not recipeID then
				local itemLink = GetTradeSkillItemLink(i)
				if itemLink then
					-- Try item: pattern first (most Classic professions)
					recipeID = tonumber(itemLink:match("item:(%d+)"))
					if recipeID then
						linkType = "item"
					else
						-- Try enchant: pattern (Classic Enchanting)
						recipeID = tonumber(itemLink:match("enchant:(%d+)"))
						if recipeID then
							linkType = "enchant"
						end
					end
				end
			end

			if recipeID and not tmpRecipe[recipeID] then
				tmpRecipe[recipeID] = true
				Scanner.recipeIDs[recipeID] = true
				-- Store as table with id and linkType for proper tooltip handling
				recipeList[#recipeList + 1] = tostring(recipeID) .. (linkType and ":" .. linkType or "")
				recipeCount = recipeCount + 1
			end
		end
	end

	if recipeCount == 0 then return end

	-- Check for duplicate entries with "UNKNOWN" name and remove them
	-- This can happen when GetTradeSkillLine() returns "UNKNOWN" but GetProfessionInfo() returns the real name
	for skillLineKey, profData in pairs(BSYC.db.player.professions) do
		if profData.isClassic and profData.name == "UNKNOWN" and skillLineKey ~= professionSkillLine then
			-- Check if this UNKNOWN entry has the same recipe count (likely a duplicate)
			if profData.recipeCount == recipeCount then
				BSYC.db.player.professions[skillLineKey] = nil
				Debug(BSYC_DL.INFO, "SaveProfessionsClassic - Removed duplicate UNKNOWN entry:", skillLineKey)
			end
		end
	end

	-- Save to DB
	BSYC.db.player.professions[professionSkillLine] = {}
	BSYC.db.player.professions[professionSkillLine].name = professionName
	BSYC.db.player.professions[professionSkillLine].skillLineCurrentLevel = professionRank or 0
	BSYC.db.player.professions[professionSkillLine].skillLineMaxLevel = professionMaxRank or 0
	BSYC.db.player.professions[professionSkillLine].isClassic = true

	local categoryID = professionSkillLine
	BSYC.db.player.professions[professionSkillLine].categories = {}
	BSYC.db.player.professions[professionSkillLine].categories[categoryID] = {
		name = professionName,
		skillLineCurrentLevel = professionRank or 0,
		skillLineMaxLevel = professionMaxRank or 0,
		orderIndex = 1,
		recipes = "|" .. tconcat(recipeList, "|")
	}
	BSYC.db.player.professions[professionSkillLine].categoryCount = 1
	BSYC.db.player.professions[professionSkillLine].recipeCount = recipeCount

	Debug(BSYC_DL.INFO, "SaveProfessionsClassic [Complete] -", professionName, recipeCount, "recipes saved")
end

function Scanner:CleanupProfessions()
	Debug(BSYC_DL.INFO, "CleanupProfessions", BSYC.tracking.professions)
	if not BSYC:CanDoProfessions() then return end
	if not BSYC.tracking.professions then return end
	if not BSYC.db.player or not BSYC.db.player.professions then return end

	--lets remove unlearned tradeskills
	local tmpList = {}

	local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()
	local hasPrimaryProfessions = prof1 or prof2

	local function TrackProfession(prof)
		if not prof then return end
		local name, _, _, _, _, _, skillLine = GetProfessionInfo(prof)
		if name and skillLine then
			tmpList[tostring(skillLine)] = name
		end
	end

	TrackProfession(prof1)
	TrackProfession(prof2)
	TrackProfession(archaeology)
	TrackProfession(fishing)
	TrackProfession(cooking)
	TrackProfession(firstAid)

	-- Only clean up if GetProfessions() actually returns data (not all Classic servers support it)
	if hasPrimaryProfessions then
		for k in pairs(BSYC.db.player.professions) do
			-- Convert k to string for comparison since tmpList uses string keys
			if not tmpList[tostring(k)] then
				--it's an unlearned or unused tradeskill, lets remove it
				BSYC.db.player.professions[k] = nil
			end
		end
	end
end
