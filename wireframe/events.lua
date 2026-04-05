--[[
	events.lua
		Event module for BagSync, captures and processes events

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...) --grab the addon namespace
local Events = BSYC:NewModule("Events")
local Unit = BSYC:GetModule("Unit")
local Scanner = BSYC:GetModule("Scanner")
local L = BSYC.L

-- Cache frequently accessed global references
local hooksecurefunc = _G.hooksecurefunc
local C_GuildInfo = _G.C_GuildInfo
local GuildRoster = _G.GuildRoster
local C_CurrencyInfo = _G.C_CurrencyInfo
local C_TradeSkillUI = _G.C_TradeSkillUI
local IsReagentBankUnlocked = _G.IsReagentBankUnlocked
local CanUseVoidStorage = _G.CanUseVoidStorage
local GetVoidItemInfo = _G.GetVoidItemInfo
local CanGuildBankRepair = _G.CanGuildBankRepair
local GetNumGuildBankTabs = _G.GetNumGuildBankTabs
local GetGuildBankTabInfo = _G.GetGuildBankTabInfo
local QueryGuildBankTab = _G.QueryGuildBankTab
local GetCurrentGuildBankTab = _G.GetCurrentGuildBankTab or _G.GetCurrentGuildTab
local GetMoney = _G.GetMoney
local GetCursorMoney = _G.GetCursorMoney
local GetPlayerTradeMoney = _G.GetPlayerTradeMoney
local next = _G.next
local pairs = _G.pairs

local StartTimer = BSYC.StartTimer
local StopTimer = BSYC.StopTimer
local Print = BSYC.Print

local UnitGetPlayerInfo = Unit.GetPlayerInfo

-- Cache Scanner method references for hot path optimization
local ScannerSaveBag = Scanner.SaveBag
local ScannerSaveWarbandBank = Scanner.SaveWarbandBank
local ScannerSaveWarbandBankMoney = Scanner.SaveWarbandBankMoney
local ScannerSaveBank = Scanner.SaveBank
local ScannerSaveMailbox = Scanner.SaveMailbox
local ScannerSendMail = Scanner.SendMail
local ScannerSaveVoidBank = Scanner.SaveVoidBank
local ScannerSaveGuildBank = Scanner.SaveGuildBank
local ScannerSaveGuildBankMoney = Scanner.SaveGuildBankMoney
local ScannerSaveEquipment = Scanner.SaveEquipment
local ScannerSaveAuctionHouse = Scanner.SaveAuctionHouse
local ScannerProcessCurrencyTransfer = Scanner.ProcessCurrencyTransfer
local ScannerGetBagSlots = Scanner.GetBagSlots

local function Debug(level, ...)
	if BSYC.DEBUG then BSYC.DEBUG(level, "Events", ...) end
end

-- Generic helper to register a one-time hook, eliminating duplication
local function GenericHook(self, hookKey, targetTable, funcName, handler)
	if self[hookKey] or not hooksecurefunc then return end
	self[hookKey] = true

	if targetTable then
		hooksecurefunc(targetTable, funcName, handler)
	else
		hooksecurefunc(funcName, handler)
	end
end

-- Optimized ProcessQueuedBag using cached Scanner methods (no Scanner parameter needed)
local function ProcessQueuedBag(bagid)
	if Scanner.IsBackpack(Scanner, bagid) or Scanner.IsBackpackBag(Scanner, bagid) or
	   Scanner.IsKeyring(Scanner, bagid) or Scanner.IsReagentBag(Scanner, bagid) then
		ScannerSaveBag(Scanner, "bag", bagid)
		return true
	end

	if Scanner.IsBank(Scanner, bagid) or Scanner.IsBankBag(Scanner, bagid) then
		if Unit.atBank then
			ScannerSaveBag(Scanner, "bank", bagid)
			return true
		end
		return false
	end

	if Scanner.IsWarbandBank(Scanner, bagid) then
		-- Warband bank updates are processed but not counted in totalProcessed to preserve legacy debug output.
		ScannerSaveWarbandBank(Scanner, bagid)
	end

	return false
end

-- Helper to register one-liner event handlers that just call Scanner methods
local function RegisterScannerEventHandler(self, eventName, scannerMethod)
	self:RegisterEvent(eventName, function()
		Scanner[scannerMethod](Scanner)
	end)
end

-- Helper to reset currency retry counters.
--
-- The currency scanner (scanner.lua:RetryCurrencyScan) uses per-player retry
-- counters stored on the Scanner table when the currency API isn't ready yet:
--   Scanner._currencyRetryCount_<name>-<realm>  (per-character key)
--   Scanner._currencyRetryCount_startup_pending (fallback before player info is available)
--
-- These counters self-clean on success or after 5 failed attempts, but this
-- function acts as a safety net to wipe any stale counters that might linger
-- across character switches, reloads, or edge cases where a retry was
-- interrupted. Called from CURRENCY_DISPLAY_UPDATE to ensure a clean slate
-- before forcing a currency save.
local function ResetCurrencyRetryCounters()
	local resetCount = 0
	for key in pairs(Scanner) do
		if type(key) == "string" and key:match("^_currencyRetryCount_") then
			Scanner[key] = nil
			resetCount = resetCount + 1
			Debug(BSYC_DL.FINE, "ResetCurrencyRetryCounters - Reset:", key)
		end
	end
	Debug(BSYC_DL.FINE, "ResetCurrencyRetryCounters - Total reset:", resetCount)

	-- Also reset the startup pending retry counter if it exists
	if Scanner._currencyRetryCount_startup_pending then
		Debug(BSYC_DL.FINE, "ResetCurrencyRetryCounters - Reset startup_pending counter, was:", Scanner._currencyRetryCount_startup_pending)
		Scanner._currencyRetryCount_startup_pending = nil
	else
		Debug(BSYC_DL.FINE, "ResetCurrencyRetryCounters - startup_pending counter was already nil")
	end
end

-- Helper to queue bag updates for issue #458
local cachedBagMin, cachedBagMax

local function QueueBagUpdates()
	Debug(BSYC_DL.SL3, "QueueBagUpdates", "Queueing bag updates for rescan")

	-- Cache bag slot bounds to avoid repeated GetBagSlots calls
	if not cachedBagMin or not cachedBagMax then
		cachedBagMin, cachedBagMax = ScannerGetBagSlots(Scanner, "bag")
	end

	for i = cachedBagMin, cachedBagMax do
		Events:BAG_UPDATE(nil, i)
	end
end

-- Helper to queue profession scan with debouncing
function Events:QueueProfessionUpdate()
	Debug(BSYC_DL.INFO, "QueueProfessionUpdate: Queuing scan with 1s delay")
	StartTimer(BSYC, "ProfessionScan", 1, Scanner, "SaveProfessions")
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

	registerEvent(self, "TRADE_SKILL_SHOW", "OnTradeSkillShow")
	registerEvent(self, "TRADE_SKILL_LIST_UPDATE", "OnTradeSkillListUpdate")
	-- Classic only - fires after TRADE_SKILL_SHOW when recipes are loaded
	if not C_TradeSkillUI or not C_TradeSkillUI.GetAllRecipeIDs then
		registerEvent(self, "TRADE_SKILL_UPDATE", "OnTradeSkillUpdate")
	end
	registerEvent(self, "TRADE_SKILL_DATA_SOURCE_CHANGED", "OnTradeSkillDataSourceChanged")

	registerEvent(self, "MAIL_INBOX_UPDATE")
	registerEvent(self, "MAIL_SEND_SUCCESS")
	GenericHook(self, "_sendMailHooked", nil, "SendMail", function(mailTo)
		ScannerSendMail(Scanner, mailTo, false)
	end)

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
		-- Use consolidated helper for one-liner event handlers
		RegisterScannerEventHandler(self, "PLAYERREAGENTBANKSLOTS_CHANGED", "SaveReagents")
		RegisterScannerEventHandler(self, "REAGENTBANK_PURCHASED", "SaveReagents")
	else
		-- Inlined DisableTracking logic (was only used here)
		if BSYC.tracking then BSYC.tracking.reagents = false end
		if BSYC.db and BSYC.db.player then BSYC.db.player.reagents = nil end
		Debug(BSYC_DL.WARN, "Module-Inactive", "reagents")
	end

	--check if voidbank is even enabled on server
	if CanUseVoidStorage and GetVoidItemInfo then
		RegisterScannerEventHandler(self, "VOID_TRANSFER_DONE", "SaveVoidBank")
	else
		if BSYC.tracking then BSYC.tracking.void = false end
		if BSYC.db and BSYC.db.player then BSYC.db.player.void = nil end
		Debug(BSYC_DL.WARN, "Module-Inactive", "void")
	end

	--check to see if guildbanks are even enabled on server
	if CanGuildBankRepair then
		registerEvent(self, "GUILDBANKBAGSLOTS_CHANGED")
		registerEvent(self, "GUILDBANK_UPDATE_MONEY")
		registerEvent(self, "GUILDBANK_UPDATE_WITHDRAWMONEY")
	else
		if BSYC.tracking then BSYC.tracking.guild = false end
		Debug(BSYC_DL.WARN, "Module-Inactive", "guild")
	end

	--check to see if warband banks are even enabled on server
	if BSYC.isWarbandActive then
		RegisterScannerEventHandler(self, "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED", "SaveWarbandBank")
		RegisterScannerEventHandler(self, "ACCOUNT_MONEY", "SaveWarbandBankMoney")
	else
		if BSYC.tracking then BSYC.tracking.warband = false end
		Debug(BSYC_DL.WARN, "Module-Inactive", "warband")
	end

	--only do currency checks if the server even supports it
	if BSYC:CanDoCurrency() then
		registerEvent(self, "CURRENCY_DISPLAY_UPDATE")
		--check for the ability to do currency transfer
		local requestFunc = C_CurrencyInfo and C_CurrencyInfo.RequestCurrencyFromAccountCharacter
		if requestFunc then
			registerEvent(self, "CURRENCY_TRANSFER_LOG_UPDATE")
			GenericHook(self, "_currencyTransferHooked", C_CurrencyInfo, "RequestCurrencyFromAccountCharacter",
				function(sourceGUID, currencyID, transferAmt)
					-- Get the transfer cost if the API is available
					local transferCost = 0
					if type(C_CurrencyInfo.GetCostToTransferCurrency) == "function" then
						transferCost = C_CurrencyInfo.GetCostToTransferCurrency(currencyID, transferAmt) or 0
					end
					ScannerProcessCurrencyTransfer(Scanner, false, sourceGUID, currencyID, transferAmt, transferCost)
				end
			)
		end
	else
		if BSYC.tracking then BSYC.tracking.currency = false end
		Debug(BSYC_DL.WARN, "Module-Inactive", "currency")
	end

	--Force guild roster update, so we can grab guild name.  Note this is nil on login, have to check for Classic and Retail though
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
		ScannerSaveMailbox(Scanner, true)
	end
end

function Events:BAGSYNC_EVENT_BANK(_, isOpen)
	Debug(BSYC_DL.DEBUG, "BAGSYNC_EVENT_BANK", isOpen)
	if isOpen then
		ScannerSaveBank(Scanner)

		if BSYC.isWarbandActive then
			ScannerSaveWarbandBank(Scanner)
			ScannerSaveWarbandBankMoney(Scanner)
		end
	end
end

function Events:BAGSYNC_EVENT_AUCTION(_, isOpen, isReady)
	Debug(BSYC_DL.DEBUG, "BAGSYNC_EVENT_AUCTION", isOpen, isReady)
	if isOpen and isReady then
		ScannerSaveAuctionHouse(Scanner)
	end
end

function Events:BAGSYNC_EVENT_VOIDBANK(_, isOpen)
	Debug(BSYC_DL.DEBUG, "BAGSYNC_EVENT_VOIDBANK", isOpen)
	if isOpen then
		ScannerSaveVoidBank(Scanner)
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
		ScannerSaveWarbandBank(Scanner)
		ScannerSaveWarbandBankMoney(Scanner)
	end
end

function Events:MAIL_INBOX_UPDATE()
	StartTimer(BSYC, "MAIL_INBOX_UPDATE", 0.3, Scanner, "SaveMailbox")
end

function Events:MAIL_SEND_SUCCESS()
	ScannerSendMail(Scanner, nil, true)
end

function Events:PLAYERBANKSLOTS_CHANGED()
	ScannerSaveBank(Scanner, true)
end

function Events:GUILDBANKBAGSLOTS_CHANGED()
	StartTimer(BSYC, "GUILDBANKBAGSLOTS_CHANGED", 1, Events, "GuildBank_Changed")
end

function Events:GUILDBANK_UPDATE_MONEY()
	ScannerSaveGuildBankMoney(Scanner)
end

function Events:GUILDBANK_UPDATE_WITHDRAWMONEY()
	ScannerSaveGuildBankMoney(Scanner)
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
	ScannerSaveEquipment(Scanner)
end

-- Track inventory changes for issue #458 - incremental updates only
function Events:HandleInventoryChanged(_, unit)
	if unit == "player" then
		Debug(BSYC_DL.SL3, "UNIT_INVENTORY_CHANGED", unit)
		QueueBagUpdates()
	end
end

-- Track quest-related item changes for issue #458 - incremental updates only
function Events:HandleQuestEvent(_, questID)
	Debug(BSYC_DL.SL3, "QUEST_EVENT", questID)
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

	if not queue[bagid] then
		queue[bagid] = true
		self.SpamBagTotal = (self.SpamBagTotal or 0) + 1
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
	-- Removed redundant nil checks on GetNumGuildBankTabs/GetGuildBankTabInfo/QueryGuildBankTab (verified at OnEnable)
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
		ScannerSaveGuildBank(Scanner)
	else
		--save only current tab we are viewing or changed to
		local currentTab = GetCurrentGuildBankTab and GetCurrentGuildBankTab() or nil
		ScannerSaveGuildBank(Scanner, currentTab)
	end
end

function Events:CURRENCY_DISPLAY_UPDATE()
	Debug(BSYC_DL.FINE, "CURRENCY_DISPLAY_UPDATE ENTRY - tracking.currency:", BSYC.tracking.currency)

	if not BSYC.tracking.currency then
		Debug(BSYC_DL.FINE, "CURRENCY_DISPLAY_UPDATE EXIT - tracking.currency is false")
		return
	end

	if Unit.InCombatLockdown(Unit) then
		Debug(BSYC_DL.FINE, "CURRENCY_DISPLAY_UPDATE - In combat, delaying until PLAYER_REGEN_ENABLED")
		if not self.doCurrencyUpdate then
			self.doCurrencyUpdate = true
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
			Debug(BSYC_DL.FINE, "CURRENCY_DISPLAY_UPDATE - Registered PLAYER_REGEN_ENABLED")
		end
		return
	end

	-- Use dedicated reset helper instead of inline loop
	ResetCurrencyRetryCounters()

	-- Pass skipRetry=true to force save regardless of listSize state
	Debug(BSYC_DL.FINE, "CURRENCY_DISPLAY_UPDATE - Queueing SaveCurrency with skipRetry=true in 1 second")
	StartTimer(BSYC, "CURRENCY_DISPLAY_UPDATE", 1, Scanner, "SaveCurrency", false, true)
end

function Events:PLAYER_REGEN_ENABLED()
	Debug(BSYC_DL.FINE, "PLAYER_REGEN_ENABLED ENTRY - doCurrencyUpdate:", self.doCurrencyUpdate)

	-- Removed redundant combat check - this event only fires when leaving combat

	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self.doCurrencyUpdate = nil
	Debug(BSYC_DL.FINE, "PLAYER_REGEN_ENABLED - Unregistered PLAYER_REGEN_ENABLED, cleared doCurrencyUpdate flag")

	-- Pass skipRetry=true to force save regardless of listSize state
	Debug(BSYC_DL.FINE, "PLAYER_REGEN_ENABLED - Queueing SaveCurrency with skipRetry=true in 1 second")
	StartTimer(BSYC, "CURRENCY_DISPLAY_UPDATE", 1, Scanner, "SaveCurrency", false, true)
end

-- Modern Retail (Dragonflight+) crafting event - ONLY fires for actual crafts
function Events:HandleTradeSkillCraftResult(_, craftingResult)
	if not craftingResult or not craftingResult.success then return end

	Debug(BSYC_DL.SL1, "TRADE_SKILL_CRAFT_RESULT", craftingResult.recipeID, craftingResult.success, "Crafting complete - queueing bag update")
	QueueBagUpdates()
end

function Events:OnTradeSkillShow()
	Debug(BSYC_DL.SL3, "TRADE_SKILL_SHOW: Fired, queueing scan")
	self._TradeSkillEvent = true
	self:QueueProfessionUpdate()
end

function Events:OnTradeSkillListUpdate()
	-- Only queue if this is following a TRADE_SKILL_SHOW event
	if self._TradeSkillEvent then
		self._TradeSkillEvent = nil
		self:QueueProfessionUpdate()
	end
end

function Events:OnTradeSkillUpdate()
	-- Classic only event - fires after TRADE_SKILL_SHOW when recipes are loaded
	Debug(BSYC_DL.SL3, "TRADE_SKILL_UPDATE: Fired, queuing profession scan")
	self:QueueProfessionUpdate()
end

function Events:OnTradeSkillDataSourceChanged()
	--this gets fired when they switch professions while still having the tradeskill window open
	if not self._TradeSkillEvent then
		self._TradeSkillEvent = true
		self:QueueProfessionUpdate()
	end
end

function Events:CURRENCY_TRANSFER_LOG_UPDATE()
	ScannerProcessCurrencyTransfer(Scanner, true)
	Scanner.currencyTransferInProgress = false
end
