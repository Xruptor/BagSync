--[[
	events.lua
		Event module for BagSync, captures and processes events

		BagSync - All Rights Reserved - (c) 2024
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Events = BSYC:NewModule("Events", 'AceEvent-3.0')
local Unit = BSYC:GetModule("Unit")
local Scanner = BSYC:GetModule("Scanner")
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Events", ...) end
end

function Events:OnEnable()
	Debug(BSYC_DL.INFO, "OnEnable")

	self:RegisterEvent("PLAYER_MONEY")
	self:RegisterEvent("GUILD_ROSTER_UPDATE", function() Events:UpdateGuildRoster() end)
	self:RegisterEvent("PLAYER_GUILD_UPDATE", function() Events:UpdateGuildRoster() end)

	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
	self:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")

	--this event is when we trigger a CheckInbox()
	self:RegisterEvent("MAIL_INBOX_UPDATE", function()
		BSYC:StartTimer("MAIL_INBOX_UPDATE", 0.3, Scanner, "SaveMailbox")
	end)
	self:RegisterEvent("MAIL_SEND_SUCCESS", function()
		Scanner:SendMail(nil, true)
	end)
    hooksecurefunc("SendMail", function(mailTo)
		Scanner:SendMail(mailTo, false)
    end)

	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", function(event, slotID)
		Scanner:SaveBank(true)
	end)

	--register our custom Event Handlers
	self:RegisterMessage('BAGSYNC_EVENT_MAILBOX')
	self:RegisterMessage('BAGSYNC_EVENT_BANK')
	self:RegisterMessage('BAGSYNC_EVENT_AUCTION')
	self:RegisterMessage('BAGSYNC_EVENT_VOIDBANK')
	self:RegisterMessage('BAGSYNC_EVENT_GUILDBANK')
	self:RegisterMessage('BAGSYNC_EVENT_WARBANDBANK')

	--check to see if the ReagentBank is even enabled on server
	if IsReagentBankUnlocked then
		self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED", function(event, slotID)
			Scanner:SaveReagents()
		end)
		self:RegisterEvent("REAGENTBANK_PURCHASED", function() Scanner:SaveReagents() end)
	else
		BSYC.tracking.reagents = false
		Debug(BSYC_DL.WARN, "Module-Inactive", "reagents")
	end

	--check if voidbank is even enabled on server
	if CanUseVoidStorage then
		--scan when transfers of any kind are done at the void storage
		self:RegisterEvent("VOID_TRANSFER_DONE", function() Scanner:SaveVoidBank() end)
	else
		BSYC.tracking.void = false
		Debug(BSYC_DL.WARN, "Module-Inactive", "void")
	end

	--check to see if guildbanks are even enabled on server
	if CanGuildBankRepair then
		self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED", function()
			BSYC:StartTimer("GUILDBANKBAGSLOTS_CHANGED", 1, Events, "GuildBank_Changed")
		end)
		self:RegisterEvent("GUILDBANK_UPDATE_MONEY", function() Scanner:SaveGuildBankMoney() end)
		self:RegisterEvent("GUILDBANK_UPDATE_WITHDRAWMONEY", function() Scanner:SaveGuildBankMoney() end)
	else
		BSYC.tracking.guild = false
		Debug(BSYC_DL.WARN, "Module-Inactive", "guild")
	end

	--check to see if warband banks are even enabled on server
	if BSYC.isWarbandActive then
		--C_Bank.CanPurchaseBankTab(Enum.BankType.Account)
		self:RegisterEvent("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED", function() Scanner:SaveWarbandBank() end)
		self:RegisterEvent("ACCOUNT_MONEY", function() Scanner:SaveWarbandBankMoney() end)
	else
		BSYC.tracking.warband = false
		Debug(BSYC_DL.WARN, "Module-Inactive", "warband")
	end

	--only do currency checks if the server even supports it
	if BSYC:CanDoCurrency() then
		self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

		--check for the ability to do currency transfer
		if C_CurrencyInfo and C_CurrencyInfo.RequestCurrencyFromAccountCharacter then
			self:RegisterEvent("CURRENCY_TRANSFER_LOG_UPDATE", function()
				Scanner:ProcessCurrencyTransfer(true)
				Scanner.currencyTransferInProgress = false
			end)

			hooksecurefunc(C_CurrencyInfo, "RequestCurrencyFromAccountCharacter", function(sourceGUID, currencyID, transferAmt)
				Scanner:ProcessCurrencyTransfer(false, sourceGUID, currencyID, transferAmt)
			end)
		end
	else
		BSYC.tracking.currency = false
		Debug(BSYC_DL.WARN, "Module-Inactive", "currency")
	end

	--Force guild roster update, so we can grab guild name.  Note this is nil on login, have to check for Classic and Retail though
	--https://wowpedia.fandom.com/wiki/API_C_GuildInfo.GuildRoster
	if C_GuildInfo and C_GuildInfo.GuildRoster then
		C_GuildInfo.GuildRoster() -- Retail
	elseif GuildRoster then
		GuildRoster() -- Classic
	end

	Scanner:StartupScans() --do the login player scans

	--BAG_UPDATE fires A LOT during login and when in between loading screens.  In general it's a very spammy event.
	--to combat this we are going to use the DELAYED event which fires after all the BAG_UPDATE are done.  Then go through the spam queue.
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("BAG_UPDATE_DELAYED")

	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
end

function Events:BAGSYNC_EVENT_MAILBOX(event, isOpen)
	Debug(BSYC_DL.DEBUG, "BAGSYNC_EVENT_MAILBOX", isOpen)
	if isOpen then
		Scanner:SaveMailbox(true)
	end
end

function Events:BAGSYNC_EVENT_BANK(event, isOpen)
	Debug(BSYC_DL.DEBUG, "BAGSYNC_EVENT_BANK", isOpen)
	if isOpen then
		Scanner:SaveBank()

		if BSYC.isWarbandActive then
			Scanner:SaveWarbandBank()
			Scanner:SaveWarbandBankMoney()
		end
	end
end

function Events:BAGSYNC_EVENT_AUCTION(event, isOpen, isReady)
	Debug(BSYC_DL.DEBUG, "BAGSYNC_EVENT_AUCTION", isOpen, isReady)
	if isOpen and isReady then
		Scanner:SaveAuctionHouse()
	end
end

function Events:BAGSYNC_EVENT_VOIDBANK(event, isOpen)
	Debug(BSYC_DL.DEBUG, "BAGSYNC_EVENT_VOIDBANK", isOpen)
	if isOpen then
		Scanner:SaveVoidBank()
	end
end

function Events:BAGSYNC_EVENT_GUILDBANK(event, isOpen)
	Debug(BSYC_DL.DEBUG, "BAGSYNC_EVENT_GUILDBANK", isOpen)
	if isOpen then
		self:GuildBank_Open()
	end
end

function Events:BAGSYNC_EVENT_WARBANDBANK(event, isOpen)
	Debug(BSYC_DL.DEBUG, "BAGSYNC_EVENT_WARBANDBANK", isOpen)
	if isOpen then
		Scanner:SaveWarbandBank()
		Scanner:SaveWarbandBankMoney()
	end
end

function Events:PLAYER_MONEY()
	BSYC.db.player.money = (_G.GetMoney() or 0) - _G.GetCursorMoney() - _G.GetPlayerTradeMoney()
end

function Events:PLAYER_EQUIPMENT_CHANGED(event)
	Scanner:SaveEquipment()
end

function Events:BAG_UPDATE(event, bagid)
	Debug(BSYC_DL.SL3, "BAG_UPDATE", bagid)
	if not self.SpamBagQueue then self.SpamBagQueue = {} end
	self.SpamBagQueue[bagid] = true
	self.SpamBagTotal = (self.SpamBagTotal or 0) + 1
end

function Events:BAG_UPDATE_DELAYED(event)
	Debug(BSYC_DL.SL3, "BAG_UPDATE_DELAYED")
	if not self.SpamBagQueue then self.SpamBagQueue = {} end
	if not self.SpamBagTotal then self.SpamBagTotal = 0 end
	--NOTE: BSYC:GetHashTableLen(self.SpamBagQueue) may show more then is actually processed.  Example it has the banks in queue but we aren't at a bank.
	Debug(BSYC_DL.INFO, "SpamBagQueue", self.SpamBagTotal)

	local totalProcessed = 0

	for bagid in pairs(self.SpamBagQueue) do
		local bagname

		Debug(BSYC_DL.SL1, "SpamBagCheck", bagid)
		if Scanner:IsBackpack(bagid) or Scanner:IsBackpackBag(bagid) or Scanner:IsKeyring(bagid) then
			bagname = "bag"
		elseif Scanner:IsBank(bagid) or Scanner:IsBankBag(bagid) then
			--only do this while we are at a bank
			if Unit.atBank then
				bagname = "bank"
			end
		elseif Scanner:IsWarbandBank(bagid) then
			Scanner:SaveWarbandBank(bagid)
		end

		if bagname then
			Scanner:SaveBag(bagname, bagid)
			totalProcessed = totalProcessed + 1
		end

		--remove it
		self.SpamBagQueue[bagid] = nil
		bagname = nil
	end
	self.SpamBagTotal = 0

	Debug(BSYC_DL.INFO, "SpamBagQueue", "totalProcessed", totalProcessed)
end

function Events:UpdateGuildRoster()
	local player = Unit:GetPlayerInfo(true)
	BSYC.db.player.guild = player.guild
	BSYC.db.player.guildrealm = player.guildrealm
end

function Events:GuildBank_Open()
	Debug(BSYC_DL.SL3, "GuildBank_Open", BSYC.tracking.guild)
	if not BSYC.tracking.guild then return end

	--I used to do one query per server response, but honestly it wasn't much of a difference then just spamming them all
	for tab=1, GetNumGuildBankTabs() do
		--permissions issue, only query tabs we can see duh (isViewable)
		if select(3,GetGuildBankTabInfo(tab)) then
			QueryGuildBankTab(tab)
		end
	end
	self.queryGuild = true
end

function Events:GuildBank_Changed()
	Debug(BSYC_DL.SL3, "GuildBank_Changed", BSYC.tracking.guild)
	if not BSYC.tracking.guild then return end

	if not Unit.atGuildBank then
		if self.queryGuild then
			BSYC:Print(L.ScanGuildBankError)
			self.queryGuild = false
		end
		return
	end

	if self.queryGuild then
		self.queryGuild = false
		BSYC:Print(L.ScanGuildBankDone)
		--save all tabs
		Scanner:SaveGuildBank()
	else
		--save only current tab we are viewing or changed to
		Scanner:SaveGuildBank(GetCurrentGuildBankTab())
	end
end

function Events:CURRENCY_DISPLAY_UPDATE()
	if not BSYC.tracking.currency then return end

	if Unit:InCombatLockdown() then
		if not self.doCurrencyUpdate then
			self.doCurrencyUpdate = true
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
		return
	end
	BSYC:StartTimer("CURRENCY_DISPLAY_UPDATE", 1, Scanner, "SaveCurrency")
end

function Events:PLAYER_REGEN_ENABLED()
	--only run this if triggered by CURRENCY_DISPLAY_UPDATE
	if Unit:InCombatLockdown() then return end
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self.doCurrencyUpdate = nil
	BSYC:StartTimer("CURRENCY_DISPLAY_UPDATE", 1, Scanner, "SaveCurrency")
end

function Events:TRADE_SKILL_SHOW()
	if not self._TradeSkillEvent then
		self._TradeSkillEvent = true
	end
end

function Events:TRADE_SKILL_LIST_UPDATE()
	if self._TradeSkillEvent then
		self._TradeSkillEvent = nil
		Scanner:SaveProfessions()
	end
end

function Events:TRADE_SKILL_DATA_SOURCE_CHANGED()
	--this gets fired when they switch professions while still having the tradeskill window open
	if not self._TradeSkillEvent then
		self._TradeSkillEvent = true
		--this will trigger TRADE_SKILL_LIST_UPDATE and SaveProfessions which will save all the recipesIDs to Scanner.recipeIDs
	end
end