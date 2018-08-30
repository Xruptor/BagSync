--[[
	scanner.lua
		Scanner module for BagSync, scans bags, bank, currency, etc...
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Scanner = BSYC:NewModule("Scanner", 'AceEvent-3.0')
local Unit = BSYC:GetModule("Unit")

--https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/AddOns/Blizzard_VoidStorageUI/Blizzard_VoidStorageUI.lua
local VOID_DEPOSIT_MAX = 9
local VOID_WITHDRAW_MAX = 9
local VOID_STORAGE_MAX = 80
local VOID_STORAGE_PAGES = 2

local FirstEquipped = INVSLOT_FIRST_EQUIPPED
local LastEquipped = INVSLOT_LAST_EQUIPPED

function Scanner:SaveBag(bagtype, bagid)
	if not not bagid then return end
	BSYC.db.player[bagtype] = BSYC.db.player[bagtype] or {}

	if GetContainerNumSlots(bagid) > 0 then
		local slotItems = {}
		for slot = 1, GetContainerNumSlots(bagid) do
			local _, count, _,_,_,_, link = GetContainerItemInfo(bagid, slot)
			slotItems[slot] = BSYC:ParseItemLink(link, count)
		end
		BSYC.db.player[bagtype][bagid] = slotItems
	else
		BSYC.db.player[bagtype][bagid] = nil
	end
end

function Scanner:SaveEquipment()
	BSYC.db.player.equip = BSYC.db.player.equip or {}

	for slot = FirstEquipped, LastEquipped do
		local link = GetInventoryItemLink("player", slot)
		local count =  GetInventoryItemCount("player", slot)
		BSYC.db.player.equip[slot] = link and BSYC:ParseItemLink(link, count) or nil
	end
end

function Scanner:ScanVoidBank()
	if not Unit.atVoidBank then return end
	
	BSYC.db.player.void = BSYC.db.player.void or {}
	local slot = 0

	for tab = 1, VOID_STORAGE_PAGES do
		for i = 1, VOID_STORAGE_MAX do
			local itemID, textureName, locked, recentDeposit, isFiltered = GetVoidItemInfo(tab, i)
			slot = slot + 1
			BSYC.db.player.void[slot] = itemID and tostring(itemID) or nil
		end
	end
end

function Scanner:ScanMailbox()
	if not Unit.atMailbox then return end
	
	if self.isCheckingMail then return end --prevent overflow from CheckInbox()
	self.isCheckingMail = true

	 --used to initiate mail check from server, for some reason GetInboxNumItems() returns zero sometimes
	 --even though the user has mail in the mailbox.  This can be attributed to lag.
	CheckInbox()
	
	local slotItems = {}
	local mailCount = 0
	local numInbox = GetInboxNumItems()

	--scan the inbox
	if (numInbox > 0) then
		for mailIndex = 1, numInbox do
			for i = 1, ATTACHMENTS_MAX_RECEIVE do
				local name, itemID, itemTexture, count, quality, canUse = GetInboxItem(mailIndex, i)
				local link = GetInboxItemLink(mailIndex, i)
				if name and link then
					mailCount = mailCount + 1
					slotItems[mailCount] = BSYC:ParseItemLink(link, count)
				end
			end
		end
	end
	
	BSYC.db.player.mailbox = slotItems
	
	self.isCheckingMail = false
end

function Scanner:ScanBank(rootOnly)
	if not Unit.atBank then return end
	
	--force scan of bank bag -1, since blizzard never sends updates for it
	self:SaveBag("bank", BANK_CONTAINER)
	
	if not rootOnly then
		--https://wow.gamepedia.com/BagId#/search
		for i = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
			self:SaveBag("bank", i)
		end
	
		--scan the reagents as part of the bank scan
		self:ScanReagents()
	end
end

function Scanner:ScanReagents()
	if not Unit.atBank then return end
	
	if IsReagentBankUnlocked() then 
		self:SaveBag("reagents", REAGENTBANK_CONTAINER)
	end
end