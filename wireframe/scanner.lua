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

function Scanner:SaveEquipment(slot, count)
	BSYC.db.player.equip = BSYC.db.player.equip or {}

	local link = GetInventoryItemLink("player", slot)
	local count =  count or GetInventoryItemCount("player", slot)
	BSYC.db.player.equip[slot] = link and BSYC:ParseItemLink(link, count) or nil
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

	BSYC.db.player.mailbox = {} --reset it since we can have less mail then the last time we scan.  So we would have old mail still in table
	
	local mailCount = 0
	local numInbox = GetInboxNumItems()

	--scan the inbox
	if (numInbox > 0) then
		for mailIndex = 1, numInbox do
			for i = 1, ATTACHMENTS_MAX_RECEIVE do
				local name, itemID, itemTexture, count, quality, canUse = GetInboxItem(mailIndex, i)
				local link = GetInboxItemLink(mailIndex, i)
				mailCount = mailCount + 1
				BSYC.db.player.mailbox[mailCount] = link and self:ParseItemLink(link, count) or nil
			end
		end
	end
	
	self.isCheckingMail = false
end