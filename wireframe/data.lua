--[[
	data.lua
		Handles all the data elements for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Data = BSYC:NewModule("Data")
local Unit = BSYC:GetModule("Unit")
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
local function Debug(...)
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", "Data")
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end
end

--increment forceDBReset to reset the ENTIRE db forcefully
local forceDBReset = 2
--these just reset individual items in the DB
local unitDBVersion = {
	auction = 1,
}

StaticPopupDialogs["BAGSYNC_RESETDATABASE"] = {
	text = L.ResetDBInfo,
	button1 = L.Yes,
	button2 = L.No,
	OnAccept = function()
		BagSyncDB = { ["forceDBReset§"] = forceDBReset }
		ReloadUI()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

----------------------
--   DB Functions   --
----------------------

function Data:OnEnable()
	
	local ver = GetAddOnMetadata("BagSync","Version") or 0
	
	--get player information from Unit
	local player = Unit:GetUnitInfo()
	
	--initiate database
	BagSyncDB = BagSyncDB or {}
	
	--before we do ANYTHING with the databse, lets do a cleanup or upgrade if necessary
	self:CleanDB()
	
	--load the options and blacklist
	BagSyncDB["options§"] = BagSyncDB["options§"] or {}
	BagSyncDB["blacklist§"] = BagSyncDB["blacklist§"] or {}
	
	--main DB call
	BSYC.db = BSYC.db or {}
	
	--realm DB
	BagSyncDB[player.realm] = BagSyncDB[player.realm] or {}
	BSYC.db.realm = BagSyncDB[player.realm]
	
	--player DB
	BSYC.db.realm[player.name] = BSYC.db.realm[player.name] or {}
	BSYC.db.player = BSYC.db.realm[player.name]
	BSYC.db.player.currency = BSYC.db.player.currency or {}
	BSYC.db.player.professions = BSYC.db.player.professions or {}
	
	--blacklist DB
	BSYC.db.blacklist = BagSyncDB["blacklist§"]
	
	--options DB
	BSYC.options = BagSyncDB["options§"]
	if BSYC.options.showTotal == nil then BSYC.options.showTotal = true end
	if BSYC.options.enableGuild == nil then BSYC.options.enableGuild = true end
	if BSYC.options.enableMailbox == nil then BSYC.options.enableMailbox = true end
	if BSYC.options.enableUnitClass == nil then BSYC.options.enableUnitClass = true end
	if BSYC.options.enableMinimap == nil then BSYC.options.enableMinimap = true end
	if BSYC.options.enableFaction == nil then BSYC.options.enableFaction = true end
	if BSYC.options.enableAuction == nil then BSYC.options.enableAuction = true end
	if BSYC.options.tooltipOnlySearch == nil then BSYC.options.tooltipOnlySearch = false end
	if BSYC.options.enableTooltips == nil then BSYC.options.enableTooltips = true end
	if BSYC.options.enableExtTooltip == nil then BSYC.options.enableExtTooltip = false end
	if BSYC.options.enableTooltipSeperator == nil then BSYC.options.enableTooltipSeperator = true end
	if BSYC.options.enableCrossRealmsItems == nil then BSYC.options.enableCrossRealmsItems = true end
	if BSYC.options.enableBNetAccountItems == nil then BSYC.options.enableBNetAccountItems = false end
	if BSYC.options.enableTooltipItemID == nil then BSYC.options.enableTooltipItemID = false end
	if BSYC.options.enableSourceDebugInfo == nil then BSYC.options.enableSourceDebugInfo = false end
	if BSYC.options.enableTooltipGreenCheck == nil then BSYC.options.enableTooltipGreenCheck = true end
	if BSYC.options.enableRealmIDTags == nil then BSYC.options.enableRealmIDTags = true end
	if BSYC.options.enableRealmAstrickName == nil then BSYC.options.enableRealmAstrickName = false end
	if BSYC.options.enableRealmShortName == nil then BSYC.options.enableRealmShortName = false end
	if BSYC.options.enableLoginVersionInfo == nil then BSYC.options.enableLoginVersionInfo = true end
	if BSYC.options.enableFactionIcons == nil then BSYC.options.enableFactionIcons = false end
	if BSYC.options.enableShowUniqueItemsTotals == nil then BSYC.options.enableShowUniqueItemsTotals = true end
	if BSYC.options.enableXR_BNETRealmNames == nil then BSYC.options.enableXR_BNETRealmNames = true end
	if BSYC.options.showGuildInGoldTooltip == nil then BSYC.options.showGuildInGoldTooltip = true end
	if BSYC.options.showGuildCurrentCharacter == nil then BSYC.options.showGuildCurrentCharacter = false end
	if BSYC.options.showGuildBankScanAlert == nil then BSYC.options.showGuildBankScanAlert = true end
	if BSYC.options.focusSearchEditBox == nil then BSYC.options.focusSearchEditBox = false end
	
	--setup the default colors
	if BSYC.options.colors == nil then BSYC.options.colors = {} end
	if BSYC.options.colors.first == nil then BSYC.options.colors.first = { r = 128/255, g = 1, b = 0 }  end
	if BSYC.options.colors.second == nil then BSYC.options.colors.second = { r = 1, g = 1, b = 1 }  end
	if BSYC.options.colors.total == nil then BSYC.options.colors.total = { r = 244/255, g = 164/255, b = 96/255 }  end
	if BSYC.options.colors.guild == nil then BSYC.options.colors.guild = { r = 101/255, g = 184/255, b = 192/255 }  end --very grayish light blue
	if BSYC.options.colors.debug == nil then BSYC.options.colors.debug = { r = 77/255, g = 216/255, b = 39/255 }  end --fel green
	if BSYC.options.colors.cross == nil then BSYC.options.colors.cross = { r = 1, g = 125/255, b = 10/255 }  end
	if BSYC.options.colors.bnet == nil then BSYC.options.colors.bnet = { r = 53/255, g = 136/255, b = 1 }  end
	if BSYC.options.colors.itemid == nil then BSYC.options.colors.itemid = { r = 82/255, g = 211/255, b = 134/255 }  end

	--do DB cleanup check by version number
	if not BSYC.options.addonversion or BSYC.options.addonversion ~= ver then	
		self:FixDB()
		BSYC.options.addonversion = ver
	end
	
	--player info
	BSYC.db.player.money = player.money
	BSYC.db.player.class = player.class
	BSYC.db.player.race = player.race
	BSYC.db.player.gender = player.gender
	BSYC.db.player.faction = player.faction
	--we cannot store guild as on login the guild name returns nil
	--https://wow.gamepedia.com/API_GetGuildInfo

	--load the slash commands
	self:LoadSlashCommand()
	
	if BSYC.options.enableLoginVersionInfo then
		BSYC:Print("[v|cFF20ff20"..ver.."|r] /bgs, /bagsync")
	end

end

function Data:ResetColors()
	if BSYC.options.colors == nil then BSYC.options.colors = {} end
	BSYC.options.colors.first = { r = 128/255, g = 1, b = 0 }
	BSYC.options.colors.second = { r = 1, g = 1, b = 1 }
	BSYC.options.colors.total = { r = 244/255, g = 164/255, b = 96/255 }
	BSYC.options.colors.guild = { r = 101/255, g = 184/255, b = 192/255 } --very grayish light blue
	BSYC.options.colors.debug = { r = 77/255, g = 216/255, b = 39/255 } --fel green
	BSYC.options.colors.cross = { r = 1, g = 125/255, b = 10/255 }
	BSYC.options.colors.bnet = { r = 53/255, g = 136/255, b = 1 }
	BSYC.options.colors.itemid = { r = 82/255, g = 211/255, b = 134/255 }
end

function Data:CleanDB()

	--delete old DB variables
	if BagSyncOpt then
		BagSyncOpt = nil
	end
	if BagSyncGUILD_DB then
		BagSyncGUILD_DB = nil
	end
	if BagSyncCURRENCY_DB then
		BagSyncCURRENCY_DB = nil
	end
	if BagSyncPROFESSION_DB then
		BagSyncPROFESSION_DB = nil
	end
	if BagSyncBLACKLIST_DB then
		BagSyncBLACKLIST_DB = nil
	end
	if BagSync_REALMKEY then
		BagSync_REALMKEY = nil
	end

	--check for empty table table to prevent loops
	if next(BagSyncDB) == nil then
		BagSyncDB["forceDBReset§"] = forceDBReset
		BSYC:Print("|cFFFF9900"..L.DatabaseReset.."|r")
		return
	elseif not BagSyncDB["forceDBReset§"] or BagSyncDB["forceDBReset§"] < forceDBReset then
		BagSyncDB = { ["forceDBReset§"] = forceDBReset }
		BSYC:Print("|cFFFF9900"..L.DatabaseReset.."|r")
		return
	end
end

function Data:FixDB()

    local storeUsers = {}
    local storeGuilds = {}
	
	if not BSYC.options.unitDBVersion then BSYC.options.unitDBVersion = {} end
	
	for unitObj in self:IterateUnits(true) do
		--store only user guild names
		if not unitObj.isGuild then
			storeUsers[unitObj.name] = true
			if unitObj.data.guild then
				storeGuilds[unitObj.data.guild] = true
			end
		end
	end

	--cleanup guilds
	for realm, rd in pairs(BagSyncDB) do
		--ignore options
		if not string.match(realm, '§*') then
			--iterate through realm data
			for k, v in pairs(rd) do
				local isGuild = (k:find('©*') and true) or false
				if isGuild then
					if not storeGuilds[k] then
						--remove obsolete guild
						BagSyncDB[realm][k] = nil
					end
				else
					--users lets do a individual db cleanup if necessary
					if BSYC.options.unitDBVersion.auction ~= unitDBVersion.auction and v.auction then
						v.auction = nil
					end
				end
			end
		end
	end
	
	if BSYC.options.unitDBVersion.auction ~= unitDBVersion.auction then
		BSYC:Print("|cFFffff00"..L.UnitDBAuctionReset.."|r")
	end
	
	--update db unit version information
	BSYC.options.unitDBVersion = unitDBVersion
	
	BSYC:Print("|cFFFF9900"..L.FixDBComplete.."|r")
end

function Data:LoadSlashCommand()
	--load the keybinding locale information
	BINDING_HEADER_BAGSYNC = "BagSync"
	BINDING_NAME_BAGSYNCBLACKLIST = L.KeybindBlacklist
	BINDING_NAME_BAGSYNCCURRENCY = L.KeybindCurrency
	BINDING_NAME_BAGSYNCGOLD = L.KeybindGold
	BINDING_NAME_BAGSYNCPROFESSIONS = L.KeybindProfessions
	BINDING_NAME_BAGSYNCPROFILES = L.KeybindProfiles
	BINDING_NAME_BAGSYNCSEARCH = L.KeybindSearch
	
	local function ChatCommand(input)
	
		local parts = { (" "):split(input) }
		local cmd, args = strlower(parts[1] or ""), table.concat(parts, " ", 2)

		if string.len(cmd) > 0 then

			if cmd == L.SlashSearch then
				BSYC:GetModule("Search"):StartSearch()
				return true
			elseif cmd == L.SlashGold or cmd == L.SlashMoney then
				BSYC:GetModule("Tooltip"):MoneyTooltip()
				return true
			elseif cmd == L.SlashCurrency and BSYC.IsRetail then
				BSYC:GetModule("Currency").frame:Show()
				return true
			elseif cmd == L.SlashProfiles then
				BSYC:GetModule("Profiles").frame:Show()
				return true
			elseif cmd == L.SlashProfessions and BSYC.IsRetail then
				BSYC:GetModule("Professions").frame:Show()
				return true
			elseif cmd == L.SlashBlacklist then
				BSYC:GetModule("Blacklist").frame:Show()
				return true
			elseif cmd == L.SlashFixDB then
				self:FixDB()
				return true
			elseif cmd == L.SlashResetDB then
				StaticPopup_Show("BAGSYNC_RESETDATABASE")
				return true
			elseif cmd == L.SlashConfig then
				if InCombatLockdown() or GameMenuFrame:IsShown() or InterfaceOptionsFrame then
					return false
				end
				InterfaceOptionsFrame_OpenToCategory(BSYC.aboutPanel) --force the panel to show
				return true
			else
				--do an item search, use the full command to search
				BSYC:GetModule("Search"):StartSearch(input)
				return true
			end

		end
		
		BSYC:Print(L.HelpSearchItemName)
		BSYC:Print(L.HelpSearchWindow)
		BSYC:Print(L.HelpGoldTooltip)
		BSYC:Print(L.HelpProfilesWindow)
		if BSYC.IsRetail then
			BSYC:Print(L.HelpProfessionsWindow)
			BSYC:Print(L.HelpCurrencyWindow)
		end
		BSYC:Print(L.HelpBlacklistWindow)
		BSYC:Print(L.HelpFixDB)
		BSYC:Print(L.HelpResetDB)
		BSYC:Print(L.HelpConfigWindow)
	end
	
	--/bgs and /bagsync
	BSYC:RegisterChatCommand("bgs", ChatCommand)
	BSYC:RegisterChatCommand("bagsync", ChatCommand)
	
end

function Data:CheckExpiredAuctions()

	for unitObj in self:IterateUnits(true) do
		if not unitObj.isGuild and unitObj.data.auction and unitObj.data.auction.count then
			
			local slotItems = {}

			for x = 1, unitObj.data.auction.count do
				if unitObj.data.auction.bag[x] then

					local link, count, identifier, timeleft = strsplit(";", unitObj.data.auction.bag[x])
					--we are using the auction data, no need to check identifier for 1
					
					--if the timeleft is greater than current time than keep it, it's not expired
					if link and timeleft then
						if tonumber(timeleft) > time() then
							table.insert(slotItems, unitObj.data.auction.bag[x])
						end
					end
					
				end
			end
			
			unitObj.data.auction.bag = slotItems
			unitObj.data.auction.count = #slotItems or 0
			
		end
	end
	
end

function Data:IterateUnits(dumpAll, filterList)
	if filterList then dumpAll = true end
	
	local player = Unit:GetUnitInfo()
	local previousGuilds = {}
	local argKey, argValue = next(BagSyncDB)
	local k, v

	return function()
		while argKey do

			if argKey and string.match(argKey, '§*') then
				argKey, argValue = next(BagSyncDB, argKey)
			elseif argKey then
				k, v = next(argValue, k)

				if k then
					if v.faction and (v.faction == BSYC.db.player.faction or BSYC.options.enableFaction) then
						local isGuild = (k:find('©*') and true) or false
						local isConnectedRealm = (Unit:isConnectedRealm(argKey) and true) or false
						
						--return everything regardless of user settings
						if dumpAll then
							local skipReturn = false
							
							if filterList then
								--check realm, name and realmkey
								if filterList[argKey] and filterList[argKey][k] then
								
									local realmKey = filterList[argKey][k].realmKey
									
									if realmKey and v.realmKey and realmKey ~= v.realmKey then
										--if it has a realmkey it's because it's a guild, lets check if it doesn't match to skip
										skipReturn = true
									end
								else
									skipReturn = true
								end
							end
						
							if not skipReturn then
								return {realm=argKey, name=k, data=v, isGuild=isGuild, isConnectedRealm=isConnectedRealm}
							end
							
						elseif (argKey == player.realm) or (isConnectedRealm and BSYC.options.enableCrossRealmsItems) or (BSYC.options.enableBNetAccountItems) then
							
							local skipChk = false
							
							--check for previous listed guilds just in case, because of connected realms (can have same guild on multiple connected realms)
							if BSYC.options.enableGuild and isGuild and v.realmKey then
							
								--realmKey is a concat of connected realms to determine if one guild exists on multiple realms
								--it's also used for any XR connection matching.  See GetXRGuild and Unit module in wireframe.
								if BSYC.options.showGuildCurrentCharacter and player.guild then
									if v.realmKey == player.realmKey then
										--same realm, but lets check name
										if k ~= player.guild then
											skipChk = true
										end
										--otherwise it matches so don't skip it
									else
										--not same realm so skip it
										skipChk = true
									end
								end
							
								local XRName = k .. v.realmKey
								if not previousGuilds[XRName] then
									previousGuilds[XRName] = true
								else
									skipChk = true
								end
								--check for the guild blacklist
								if BSYC.db.blacklist[XRName] then skipChk = true end
							elseif not BSYC.options.enableGuild and isGuild then
								skipChk = true
							end
							
							if not skipChk then
								return {realm=argKey, name=k, data=v, isGuild=isGuild, isConnectedRealm=isConnectedRealm}
							end
						end
					end
				else
					argKey, argValue = next(BagSyncDB, argKey)
				end
				
			--else if no next key then exit while
			end
		end
	end

end
