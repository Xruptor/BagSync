--[[
	events.lua
		Event module for BagSync, captures and processes events

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.
--]]

-- Changes made:
-- - Added one-time hook guards and centralized feature-disable handling for safer re-enables.
-- - Streamlined bag-update queuing and routing with cached helpers to reduce hot-path churn.
-- - Added nil-safe fallbacks for optional APIs and cleaned redundant state/parameters.

local BSYC = select(2, ...) --grab the addon namespace
local Events = BSYC:NewModule("Events")
local Unit = BSYC:GetModule("Unit")
local Scanner = BSYC:GetModule("Scanner")
local L = BSYC.L

local hooksecurefunc = _G.hooksecurefunc
local IsReagentBankUnlocked = _G.IsReagentBankUnlocked
local CanUseVoidStorage = _G.CanUseVoidStorage
local GetVoidItemInfo = _G.GetVoidItemInfo
local CanGuildBankRepair = _G.CanGuildBankRepair
local C_GuildInfo = _G.C_GuildInfo
local GuildRoster = _G.GuildRoster
local C_CurrencyInfo = _G.C_CurrencyInfo
local GetMoney = _G.GetMoney
local GetCursorMoney = _G.GetCursorMoney
local GetPlayerTradeMoney = _G.GetPlayerTradeMoney
local GetNumGuildBankTabs = _G.GetNumGuildBankTabs
local GetGuildBankTabInfo = _G.GetGuildBankTabInfo
local QueryGuildBankTab = _G.QueryGuildBankTab
local GetCurrentGuildBankTab = _G.GetCurrentGuildBankTab or _G.GetCurrentGuildTab
local next = _G.next
local pairs = _G.pairs

local StartTimer = BSYC.StartTimer
local StopTimer = BSYC.StopTimer
local Print = BSYC.Print

local UnitGetPlayerInfo = Unit.GetPlayerInfo
local UnitInCombatLockdown = Unit.InCombatLockdown

local IsBackpack = Scanner.IsBackpack
local IsBackpackBag = Scanner.IsBackpackBag
local IsKeyring = Scanner.IsKeyring
local IsReagentBag = Scanner.IsReagentBag
local IsBank = Scanner.IsBank
local IsBankBag = Scanner.IsBankBag
local IsWarbandBank = Scanner.IsWarbandBank
local SaveBag = Scanner.SaveBag
local SaveWarbandBank = Scanner.SaveWarbandBank

local function Debug(level, ...)
	if BSYC.DEBUG then BSYC.DEBUG(level, "Events", ...) end
end

local function DisableTracking(moduleKey, dbKey)
	if BSYC.tracking then
		BSYC.tracking[moduleKey] = false
	end
	if dbKey and BSYC.db and BSYC.db.player then
		BSYC.db.player[dbKey] = nil
	end
	Debug(BSYC_DL.WARN, "Module-Inactive", moduleKey)
end

local function ProcessQueuedBag(bagid)
	if IsBackpack(Scanner, bagid) or IsBackpackBag(Scanner, bagid) or IsKeyring(Scanner, bagid) or IsReagentBag(Scanner, bagid) then
		SaveBag(Scanner, "bag", bagid)
		return true
	end

	if IsBank(Scanner, bagid) or IsBankBag(Scanner, bagid) then
		if Unit.atBank then
			SaveBag(Scanner, "bank", bagid)
			return true
		end
		return false
	end

	if IsWarbandBank(Scanner, bagid) then
		-- Warband bank updates are processed but not counted in totalProcessed to preserve legacy debug output.
		SaveWarbandBank(Scanner, bagid)
	end

	return false
end

local function HookSendMailOnce(self)
	if self._sendMailHooked or not hooksecurefunc then return end
	self._sendMailHooked = true
	hooksecurefunc("SendMail", function(mailTo)
		Scanner:SendMail(mailTo, false)
	end)
end

local function HookCurrencyTransferOnce(self)
	if self._currencyTransferHooked or not hooksecurefunc then return end
	local requestFunc = C_CurrencyInfo and C_CurrencyInfo.RequestCurrencyFromAccountCharacter
	if type(requestFunc) ~= "function" then return end

	self._currencyTransferHooked = true
	hooksecurefunc(C_CurrencyInfo, "RequestCurrencyFromAccountCharacter", function(sourceGUID, currencyID, transferAmt)
		-- Get the transfer cost if the API is available
		local transferCost = 0
		if type(C_CurrencyInfo.GetCostToTransferCurrency) == "function" then
			transferCost = C_CurrencyInfo.GetCostToTransferCurrency(currencyID, transferAmt) or 0
		end
		Scanner:ProcessCurrencyTransfer(false, sourceGUID, currencyID, transferAmt, transferCost)
	end)
end

local function SaveWarbandBankData()
	Scanner:SaveWarbandBank()
	Scanner:SaveWarbandBankMoney()
end

local function SaveReagents()
	Scanner:SaveReagents()
end

local function SaveGuildBankMoney()
	Scanner:SaveGuildBankMoney()
end

function Events:OnEnable()
	Debug(BSYC_DL.INFO, "OnEnable")

	self.SpamBagQueue = self.SpamBagQueue or {}
	self.SpamBagTotal = self.SpamBagTotal or 0

	local registerEvent = self.RegisterEvent
	local registerMessage = self.RegisterMessage

	registerEvent(self, "PLAYER_MONEY")
	registerEvent(self, "GUILD_ROSTER_UPDATE", "UpdateGuildRoster")
	registerEvent(self, "PLAYER_GUILD_UPDATE", "UpdateGuildRoster")

	-- Track inventory changes for issue #458 - items like Imperial Silk
	registerEvent(self, "UNIT_INVENTORY_CHANGED", "HandleInventoryChanged")

	-- Retail (Dragonflight+): Use TRADE_SKILL_CRAFT_RESULT for targeted crafting detection
	if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
		registerEvent(self, "TRADE_SKILL_CRAFT_RESULT", "HandleTradeSkillCraftResult")
	end

	registerEvent(self, "QUEST_ACCEPTED", "HandleQuestEvent")
	registerEvent(self, "QUEST_TURNED_IN", "HandleQuestEvent")

	registerEvent(self, "TRADE_SKILL_SHOW")
	registerEvent(self, "TRADE_SKILL_LIST_UPDATE")
	-- Classic only - fires after TRADE_SKILL_SHOW when recipes are loaded
	if not C_TradeSkillUI or not C_TradeSkillUI.GetAllRecipeIDs then
		registerEvent(self, "TRADE_SKILL_UPDATE")
	end
	registerEvent(self, "TRADE_SKILL_DATA_SOURCE_CHANGED")

	registerEvent(self, "MAIL_INBOX_UPDATE")
	registerEvent(self, "MAIL_SEND_SUCCESS")
	HookSendMailOnce(self)

	registerEvent(self, "PLAYERBANKSLOTS_CHANGED")

	--register our custom Event Handlers
	registerMessage(self, "BAGSYNC_EVENT_MAILBOX")
	registerMessage(self, "BAGSYNC_EVENT_BANK")
	registerMessage(self, "BAGSYNC_EVENT_AUCTION")
	registerMessage(self, "BAGSYNC_EVENT_VOIDBANK")
	registerMessage(self, "BAGSYNC_EVENT_GUILDBANK")
	registerMessage(self, "BAGSYNC_EVENT_WARBANDBANK")

	--check to see if the ReagentBank is even enabled on server
	if IsReagentBankUnlocked then
		registerEvent(self, "PLAYERREAGENTBANKSLOTS_CHANGED")
		registerEvent(self, "REAGENTBANK_PURCHASED")
	else
		DisableTracking("reagents", "reagents")
	end

	--check if voidbank is even enabled on server
	if CanUseVoidStorage and GetVoidItemInfo then
		registerEvent(self, "VOID_TRANSFER_DONE")
	else
		DisableTracking("void", "void")
	end

	--check to see if guildbanks are even enabled on server
	if CanGuildBankRepair then
		registerEvent(self, "GUILDBANKBAGSLOTS_CHANGED")
		registerEvent(self, "GUILDBANK_UPDATE_MONEY")
		registerEvent(self, "GUILDBANK_UPDATE_WITHDRAWMONEY")
	else
		DisableTracking("guild")
	end

	--check to see if warband banks are even enabled on server
	if BSYC.isWarbandActive then
		registerEvent(self, "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED")
		registerEvent(self, "ACCOUNT_MONEY")
	else
		DisableTracking("warband")
	end

	--only do currency checks if the server even supports it
	if BSYC:CanDoCurrency() then
		registerEvent(self, "CURRENCY_DISPLAY_UPDATE")
		--check for the ability to do currency transfer
		if C_CurrencyInfo and C_CurrencyInfo.RequestCurrencyFromAccountCharacter then
			registerEvent(self, "CURRENCY_TRANSFER_LOG_UPDATE")
			HookCurrencyTransferOnce(self)
		end
	else
		DisableTracking("currency")
	end

	--Force guild roster update, so we can grab guild name.  Note this is nil on login, have to check for Classic and Retail though
	--https://wowpedia.fandom.com/wiki/API_C_GuildInfo.GuildRoster
	if C_GuildInfo and C_GuildInfo.GuildRoster then
		C_GuildInfo.GuildRoster() -- Retail
	elseif GuildRoster then
		GuildRoster() -- Classic
	end

	StartTimer(BSYC, "StartupScans", 2, Scanner, "StartupScans") --do the login player scans

	--BAG_UPDATE fires A LOT during login and when in between loading screens.  In general it's a very spammy event.
	--to combat this we are going to use the DELAYED event which fires after all the BAG_UPDATE are done.  Then go through the spam queue.
	registerEvent(self, "BAG_UPDATE")
	registerEvent(self, "BAG_UPDATE_DELAYED")

	registerEvent(self, "PLAYER_EQUIPMENT_CHANGED")
end

function Events:BAGSYNC_EVENT_MAILBOX(_, isOpen)
	Debug(BSYC_DL.DEBUG, "BAGSYNC_EVENT_MAILBOX", isOpen)
	if isOpen then
		Scanner:SaveMailbox(true)
	end
end

function Events:BAGSYNC_EVENT_BANK(_, isOpen)
	Debug(BSYC_DL.DEBUG, "BAGSYNC_EVENT_BANK", isOpen)
	if isOpen then
		Scanner:SaveBank()

		if BSYC.isWarbandActive then
			SaveWarbandBankData()
		end
	end
end

function Events:BAGSYNC_EVENT_AUCTION(_, isOpen, isReady)
	Debug(BSYC_DL.DEBUG, "BAGSYNC_EVENT_AUCTION", isOpen, isReady)
	if isOpen and isReady then
		Scanner:SaveAuctionHouse()
	end
end

function Events:BAGSYNC_EVENT_VOIDBANK(_, isOpen)
	Debug(BSYC_DL.DEBUG, "BAGSYNC_EVENT_VOIDBANK", isOpen)
	if isOpen then
		Scanner:SaveVoidBank()
	end
end

function Events:BAGSYNC_EVENT_GUILDBANK(_, isOpen)
	Debug(BSYC_DL.DEBUG, "BAGSYNC_EVENT_GUILDBANK", isOpen)
	if isOpen then
		self:GuildBank_Open()
	end
end

function Events:BAGSYNC_EVENT_WARBANDBANK(_, isOpen)
	Debug(BSYC_DL.DEBUG, "BAGSYNC_EVENT_WARBANDBANK", isOpen)
	if isOpen then
		SaveWarbandBankData()
	end
end

function Events:MAIL_INBOX_UPDATE()
	StartTimer(BSYC, "MAIL_INBOX_UPDATE", 0.3, Scanner, "SaveMailbox")
end

function Events:MAIL_SEND_SUCCESS()
	Scanner:SendMail(nil, true)
end

function Events:PLAYERBANKSLOTS_CHANGED()
	Scanner:SaveBank(true)
end

function Events:PLAYERREAGENTBANKSLOTS_CHANGED()
	SaveReagents()
end

function Events:REAGENTBANK_PURCHASED()
	SaveReagents()
end

function Events:VOID_TRANSFER_DONE()
	Scanner:SaveVoidBank()
end

function Events:GUILDBANKBAGSLOTS_CHANGED()
	StartTimer(BSYC, "GUILDBANKBAGSLOTS_CHANGED", 1, Events, "GuildBank_Changed")
end

function Events:GUILDBANK_UPDATE_MONEY()
	SaveGuildBankMoney()
end

function Events:GUILDBANK_UPDATE_WITHDRAWMONEY()
	SaveGuildBankMoney()
end

function Events:PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED()
	Scanner:SaveWarbandBank()
end

function Events:ACCOUNT_MONEY()
	Scanner:SaveWarbandBankMoney()
end

function Events:PLAYER_MONEY()
	local money = GetMoney and GetMoney() or 0
	local cursorMoney = GetCursorMoney and GetCursorMoney() or 0
	local tradeMoney = GetPlayerTradeMoney and GetPlayerTradeMoney() or 0
	if BSYC.db and BSYC.db.player then
		BSYC.db.player.money = money - cursorMoney - tradeMoney
	end
end

function Events:PLAYER_EQUIPMENT_CHANGED()
	Scanner:SaveEquipment()
end

-- Helper function to queue bag updates for issue #458
-- This avoids code duplication and follows existing BAG_UPDATE_DELAYED pattern
local function QueueBagUpdates()
	Debug(BSYC_DL.SL3, "QueueBagUpdates", "Queueing bag updates for rescan")
	local minCnt, maxCnt = Scanner:GetBagSlots("bag")
	for i = minCnt, maxCnt do
		Events:BAG_UPDATE(nil, i)
	end
end

-- Track inventory changes for issue #458 - incremental updates only
-- Debounced to prevent spam during login when UNIT_INVENTORY_CHANGED fires rapidly
function Events:HandleInventoryChanged(_, unit)
	if unit == "player" then
		Debug(BSYC_DL.SL3, "UNIT_INVENTORY_CHANGED", unit)
		QueueBagUpdates()
	end
end

-- Internal function called by debounced timer
function Events:_DoQueuedBagUpdates()
	-- Queue bag update event for processing by BAG_UPDATE_DELAYED
	-- This follows existing pattern and avoids full scan
	QueueBagUpdates()
end

-- Track quest-related item changes for issue #458 - incremental updates only
function Events:HandleQuestEvent(_, questID)
	Debug(BSYC_DL.SL3, "QUEST_EVENT", questID)
	-- Queue bag update event for processing by BAG_UPDATE_DELAYED
	-- This follows existing pattern and avoids full scan
	QueueBagUpdates()
end

function Events:BAG_UPDATE(_, bagid)
	Debug(BSYC_DL.SL3, "BAG_UPDATE", bagid)
	if not bagid then return end

	local queue = self.SpamBagQueue
	if not queue then
		queue = {}
		self.SpamBagQueue = queue
		self.SpamBagTotal = 0
	end

	local totalQueued = self.SpamBagTotal or 0
	if not queue[bagid] then
		queue[bagid] = true
		self.SpamBagTotal = totalQueued + 1
	end

	--this will act as a failsafe in case BAG_UPDATE_DELAYED doesn't get fired for some weird reason on a faulty server
	StartTimer(BSYC, "BagUpdateFailsafe", 3, Events, "BAG_UPDATE_DELAYED")
end

function Events:BAG_UPDATE_DELAYED()
	Debug(BSYC_DL.SL3, "BAG_UPDATE_DELAYED")
	local queue = self.SpamBagQueue
	if not queue then
		queue = {}
		self.SpamBagQueue = queue
	end
	if not self.SpamBagTotal then self.SpamBagTotal = 0 end
	--NOTE: BSYC:GetHashTableLen(self.SpamBagQueue) may show more then is actually processed.  Example it has the banks in queue but we aren't at a bank.
	Debug(BSYC_DL.INFO, "SpamBagQueue", self.SpamBagTotal)

	--stop failsafe timer
	StopTimer(BSYC, "BagUpdateFailsafe")

	if not next(queue) then
		self.SpamBagTotal = 0
		return
	end

	local totalProcessed = 0

	for bagid in pairs(queue) do
		Debug(BSYC_DL.SL1, "SpamBagCheck", bagid)
		if ProcessQueuedBag(bagid) then
			totalProcessed = totalProcessed + 1
		end

		queue[bagid] = nil
	end

	self.SpamBagTotal = 0

	Debug(BSYC_DL.INFO, "SpamBagQueue", "totalProcessed", totalProcessed)
end

function Events:UpdateGuildRoster()
	local player = UnitGetPlayerInfo(Unit, true)
	if not player then return end
	if BSYC.db and BSYC.db.player then
		BSYC.db.player.guild = player.guild
		BSYC.db.player.guildrealm = player.guildrealm
	end
end

function Events:GuildBank_Open()
	Debug(BSYC_DL.SL3, "GuildBank_Open", BSYC.tracking.guild)
	if not BSYC.tracking.guild then return end

	--I used to do one query per server response, but honestly it wasn't much of a difference then just spamming them all
	local numTabs = GetNumGuildBankTabs and GetNumGuildBankTabs() or 0
	if GetGuildBankTabInfo and QueryGuildBankTab then
		for tab = 1, numTabs do
			--permissions issue, only query tabs we can see duh (isViewable)
			if select(3, GetGuildBankTabInfo(tab)) then
				QueryGuildBankTab(tab)
			end
		end
	end
	self.queryGuild = true
end

function Events:GuildBank_Changed()
	Debug(BSYC_DL.SL3, "GuildBank_Changed", BSYC.tracking.guild)
	if not BSYC.tracking.guild then return end

	if not Unit.atGuildBank then
		if self.queryGuild then
			Print(BSYC, L.ScanGuildBankError)
			self.queryGuild = false
		end
		return
	end

	if self.queryGuild then
		self.queryGuild = false
		Print(BSYC, L.ScanGuildBankDone)
		--save all tabs
		Scanner:SaveGuildBank()
	else
		--save only current tab we are viewing or changed to
		local currentTab = GetCurrentGuildBankTab and GetCurrentGuildBankTab() or nil
		Scanner:SaveGuildBank(currentTab)
	end
end

function Events:CURRENCY_DISPLAY_UPDATE()
	Debug(BSYC_DL.FINE, "CURRENCY_DISPLAY_UPDATE ENTRY - tracking.currency:", BSYC.tracking.currency)

	if not BSYC.tracking.currency then
		Debug(BSYC_DL.FINE, "CURRENCY_DISPLAY_UPDATE EXIT - tracking.currency is false")
		return
	end

	if UnitInCombatLockdown(Unit) then
		Debug(BSYC_DL.FINE, "CURRENCY_DISPLAY_UPDATE - In combat, delaying until PLAYER_REGEN_ENABLED")
		if not self.doCurrencyUpdate then
			self.doCurrencyUpdate = true
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
			Debug(BSYC_DL.FINE, "CURRENCY_DISPLAY_UPDATE - Registered PLAYER_REGEN_ENABLED")
		end
		return
	end

	-- Reset all per-player retry counters to ensure SaveCurrency tries again when CURRENCY_DISPLAY_UPDATE fires
	local resetCount = 0
	for key in pairs(Scanner) do
		if key:match("^_currencyRetryCount_") then
			Scanner[key] = nil
			resetCount = resetCount + 1
			Debug(BSYC_DL.FINE, "CURRENCY_DISPLAY_UPDATE - Reset retry counter:", key)
		end
	end
	Debug(BSYC_DL.FINE, "CURRENCY_DISPLAY_UPDATE - Reset", resetCount, "retry counters")

	-- Also reset the startup pending retry counter if it exists
	if Scanner._currencyRetryCount_startup_pending then
		Debug(BSYC_DL.FINE, "CURRENCY_DISPLAY_UPDATE - Reset startup_pending counter, was:", Scanner._currencyRetryCount_startup_pending)
		Scanner._currencyRetryCount_startup_pending = nil
	else
		Debug(BSYC_DL.FINE, "CURRENCY_DISPLAY_UPDATE - startup_pending counter was already nil")
	end

	-- Pass skipRetry=true to force save regardless of listSize state
	Debug(BSYC_DL.FINE, "CURRENCY_DISPLAY_UPDATE - Queueing SaveCurrency with skipRetry=true in 1 second")
	StartTimer(BSYC, "CURRENCY_DISPLAY_UPDATE", 1, Scanner, "SaveCurrency", false, true)
end

function Events:PLAYER_REGEN_ENABLED()
	Debug(BSYC_DL.FINE, "PLAYER_REGEN_ENABLED ENTRY - doCurrencyUpdate:", self.doCurrencyUpdate)

	--only run this if triggered by CURRENCY_DISPLAY_UPDATE
	if UnitInCombatLockdown(Unit) then
		Debug(BSYC_DL.FINE, "PLAYER_REGEN_ENABLED - Still in combat, exiting")
		return
	end

	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self.doCurrencyUpdate = nil
	Debug(BSYC_DL.FINE, "PLAYER_REGEN_ENABLED - Unregistered PLAYER_REGEN_ENABLED, cleared doCurrencyUpdate flag")

	-- Pass skipRetry=true to force save regardless of listSize state
	Debug(BSYC_DL.FINE, "PLAYER_REGEN_ENABLED - Queueing SaveCurrency with skipRetry=true in 1 second")
	StartTimer(BSYC, "CURRENCY_DISPLAY_UPDATE", 1, Scanner, "SaveCurrency", false, true)
end

-- Shared function to queue profession scan with debounce prevention
-- StartTimer already calls StopTimer internally, so this handles rapid events automatically
function Events:QueueProfessionScan()
	Debug(BSYC_DL.INFO, "QueueProfessionScan: Queuing scan with 1s delay")
	-- Scan after a delay to ensure data is loaded
	-- Classic: TRADE_SKILL_UPDATE fires shortly after TRADE_SKILL_SHOW
	-- Retail: TRADE_SKILL_LIST_UPDATE fires after TRADE_SKILL_SHOW
	-- Increased delay to 3s to give Classic more time to load recipe data
	StartTimer(BSYC, "ProfessionScan", 1, Scanner, "SaveProfessions")
end

-- Modern Retail (Dragonflight+) crafting event - ONLY fires for actual crafts
function Events:HandleTradeSkillCraftResult(_, craftingResult)
	if not craftingResult or not craftingResult.success then return end

	Debug(BSYC_DL.SL1, "TRADE_SKILL_CRAFT_RESULT", craftingResult.recipeID, craftingResult.success, "Crafting complete - queueing bag update")
	QueueBagUpdates()
end

function Events:TRADE_SKILL_SHOW()
	Debug(BSYC_DL.SL3, "TRADE_SKILL_SHOW: Fired, queueing scan")
	self._TradeSkillEvent = true
	self:QueueProfessionScan()
end

function Events:TRADE_SKILL_LIST_UPDATE()
	if self._TradeSkillEvent then
		self._TradeSkillEvent = nil
		self:QueueProfessionScan()
	end
end

function Events:TRADE_SKILL_UPDATE()
	-- Classic only event - fires after TRADE_SKILL_SHOW when recipes are loaded
	Debug(BSYC_DL.SL3, "TRADE_SKILL_UPDATE: Fired, queuing profession scan")
	-- Queue another scan to ensure we have complete data
	self:QueueProfessionScan()
end

function Events:TRADE_SKILL_DATA_SOURCE_CHANGED()
	--this gets fired when they switch professions while still having the tradeskill window open
	if not self._TradeSkillEvent then
		self._TradeSkillEvent = true
		-- Queue scan instead of relying on TRADE_SKILL_LIST_UPDATE
		self:QueueProfessionScan()
	end
end

function Events:CURRENCY_TRANSFER_LOG_UPDATE()
	Scanner:ProcessCurrencyTransfer(true)
	Scanner.currencyTransferInProgress = false
end
