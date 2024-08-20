--[[
	core.lua
		Initiates the BagSync addon within Ace3, very important!

		BagSync - All Rights Reserved - (c) 2024
		License included with addon.
--]]

local BAGSYNC, BSYC = ... --grab the addon namespace
LibStub("AceAddon-3.0"):NewAddon(BSYC, "BagSync", "AceEvent-3.0", "AceConsole-3.0")
_G[BAGSYNC] = BSYC --add it to the global frame space, otherwise you won't be able to call it
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local SML = LibStub("LibSharedMedia-3.0")
local SML_FONT = SML.MediaType and SML.MediaType.FONT or "font"

local WOW_PROJECT_ID = _G.WOW_PROJECT_ID
local WOW_PROJECT_MAINLINE = _G.WOW_PROJECT_MAINLINE
local WOW_PROJECT_CLASSIC = _G.WOW_PROJECT_CLASSIC
--local WOW_PROJECT_BURNING_CRUSADE_CLASSIC = _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local WOW_PROJECT_WRATH_CLASSIC = _G.WOW_PROJECT_WRATH_CLASSIC

--Get TOC version
--/dump select(4, GetBuildInfo())
--https://warcraft.wiki.gg/wiki/Template:API_LatestInterface

--use the ingame trace tool to debug stuff
--/etrace or /eventtrace

--Dump tables DevTools_Dump({ table }) or DevTools_Dump(table)

BSYC.IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
BSYC.IsClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
--BSYC.IsTBC_C = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
BSYC.IsWLK_C = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

BSYC.GMF = GetMouseFocus or GetMouseFoci
--since FetchPurchasedBankTabData supports Guilds, it's possible in the future they will put it on a classic server with no Warband support.  So lets do it as last resort
BSYC.isWarbandActive = (C_Container and C_Container.SortAccountBankBags) and (Enum and Enum.BagIndex and Enum.BagIndex.AccountBankTab_1) and (C_Bank and C_Bank.FetchPurchasedBankTabData)

--increment forceDBReset to reset the ENTIRE db forcefully
local forceDBReset = 3

BSYC.FakePetCode = 10000000000
BSYC_DL = {
	DEBUG = 1,
	INFO = 2,
	TRACE = 3,
	WARN = 4,
	FINE = 5,
	SL1 = 6,
	SL2 = 7,
	SL3 = 8,
}

local debugDefaults = {
	enable = false,
	cache = false,
	DEBUG = false,
	INFO = true,
	TRACE = true,
	WARN = false,
	FINE = false,
	SL1 = false,
	SL2 = false,
	SL3 = false,
}

if BSYC.isWarbandActive then
	BSYC.WarbandIndex = {
		tabs = {
			Enum.BagIndex.AccountBankTab_1,
			Enum.BagIndex.AccountBankTab_2,
			Enum.BagIndex.AccountBankTab_3,
			Enum.BagIndex.AccountBankTab_4,
			Enum.BagIndex.AccountBankTab_5,
		},
		bags = {
			[Enum.BagIndex.AccountBankTab_1] = 1,
			[Enum.BagIndex.AccountBankTab_2] = 2,
			[Enum.BagIndex.AccountBankTab_3] = 3,
			[Enum.BagIndex.AccountBankTab_4] = 4,
			[Enum.BagIndex.AccountBankTab_5] = 5,
		},
	}
end

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

StaticPopupDialogs["BAGSYNC_RESETDB_INFO"] = {
	text = L.DatabaseReset,
	button1 = OKAY,
	button2 = nil,
	timeout = 0,
	OnAccept = function()
	end,
	OnCancel = function()
	end,
	whileDead = 1,
	hideOnEscape = 1,
}

function BSYC.DEBUG(level, sName, ...)
	if not BSYC.options or not BSYC.options.debug or not BSYC.options.debug.enable then return end

	local Debug = BSYC:GetModule("Debug")
	if not Debug then return end

	Debug:AddMessage(level, sName, ...)
end

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
function BSYC.T_DEBUG(...)

	--old tekDebug code just in case I want to track old debugging method
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", "BagSync")
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end
end

local function Debug(level, ...)
	BSYC.DEBUG(level, "CORE", ...)
end

--use /framestack to debug windows and show tooltip information
--if you press SHIFT while doing the above command it gives you a bit more information

--this is only for hash tables that aren't indexed with 1,2,3,4 etc.. but use custom index keys
--if you are using table.insert() or tables that are indexed with numbers then use # instead for table length.  #table as example
function BSYC:GetHashTableLen(tbl)
	local count = 0
	for _, __ in pairs(tbl) do
		count = count + 1
	end
	return count
end

function BSYC:DecodeOpts(tblString, mergeOpts)
	--Example = "petdata=245:12:4:5:3|auction=124567|foo=bar|tickle=elmo|test=12:3:4|forthe=horde"
	local t = mergeOpts or {}

	--([^=]+) everything except '='
	-- followed by '='
	-- ([^|]+) = then everything except '|'
	-- followed by an optional '|'

	if tblString and string.len(tblString) > 0 then
		for k, v in string.gmatch(tblString, "([^=]+)=([^|]+)|*") do
			--only overwrite if we don't have an existing value, the reason for this is because we don't want to overwrite any mergeOpts values that are newer
			if not t[k] then
				t[k] = v
			end
		end
	end

	return t
end

function BSYC:EncodeOpts(tbl, link, removeOpts)
	if not tbl then return end
	local tmpStr = ""
	--To Remove Opts: (example) BSYC:EncodeOpts(qOpts, link, {gtab=true})

	if link then
		--when doing the split, make sure to merge our table
		local xLink, xCount, xOpts = self:Split(link, nil, tbl)

		if xLink then
			if not xCount then xCount = 1 end

			for k, v in pairs(xOpts) do
				if not removeOpts or (type(removeOpts) == "table" and not removeOpts[k]) then
					tmpStr = tmpStr.."|"..k.."="..v
				end
			end
			tmpStr = string.sub(tmpStr, 2)  -- remove first pipe

			return xLink..";"..xCount..( (string.len(tmpStr) > 0 and ";"..tmpStr) or "")
		end

		--this is an invalid ParseItemLink, return empty string
		return
	end

	for k, v in pairs(tbl) do
		tmpStr = tmpStr.."|"..k.."="..v
	end

	tmpStr = string.sub(tmpStr, 2)  -- remove first pipe
	if tmpStr ~= "" then
		return tmpStr
	end

	return
end

function BSYC:Split(dataStr, skipOpts, mergeOpts)
	if not dataStr then return nil, nil, {} end

	local qLink, qCount, qOpts = strsplit(";", dataStr)
	if not qLink or string.len(qLink) < 1 then
		return nil, nil, {}
	end

	--only do Opts functions if we need too, otherwise just return the link and count
	if not skipOpts or mergeOpts then
		return qLink, qCount, self:DecodeOpts(qOpts, mergeOpts) or {}
	end

	return qLink, qCount, {}
end

function BagSync_ShowWindow(windowName)
	if windowName == "Professions" and not BSYC.tracking.professions then return end
	if windowName == "Currency" and not BSYC.tracking.currency then return end

	if BSYC:GetModule(windowName).frame:IsVisible() then
		BSYC:GetModule(windowName).frame:Hide()
	else
		BSYC:GetModule(windowName).frame:Show()
	end
end

--This function will always return the base short itemID if no count is provided or if the count is less than 1.
--Note: In addition to above, the base itemID is returned as an integer unless the item has bonusID, in which case the itemID with bonusID string is returned.
function BSYC:ParseItemLink(link, count)
	if link then
		if not count then count = 1 end

		--there are times link comes in as a number and breaks string matching, convert to string to fix
		if type(link) == "number" then link = tostring(link) end

		--if we are parsing a database entry just return it, chances are it's a battlepet anyways
		local qLink, qCount = BSYC:Split(link, true)
		if qLink and qCount then
			return link
		end

		--local linkType, linkOptions, name = LinkUtil.ExtractLink(battlePetLink);
		--if linkType ~= "battlepet" then
		--	return false;
		--end
		local isBattlepet = string.match(link, ".*(battlepet):.*") == "battlepet"
		if isBattlepet then
			return BSYC:CreateFakeID(link, count)
		end

		local result = link:match("item:([%d:]+)")
		local shortID = self:GetShortItemID(link)

		--sometimes the profession window has a bug for the items it parses, so lets fix it
		-----------------------------
		if shortID and tonumber(shortID) == 0 and TradeSkillFrame then
			local focus = BSYC.GMF():GetName()

			if focus == 'TradeSkillSkillIcon' then
				link = C_TradeSkillUI.GetRecipeItemLink(TradeSkillFrame.selectedSkill)
			else
				local i = focus:match('TradeSkillReagent(%d+)')
				if i then
					link = C_TradeSkillUI.GetRecipeReagentItemLink(TradeSkillFrame.selectedSkill, tonumber(i))
				end
			end
			if link then
				result = link:match("item:([%d:]+)")
				shortID = self:GetShortItemID(link)
			end
		end
		-----------------------------

		if result then
			--https://wowpedia.fandom.com/wiki/ItemLink

			--split everything into a table so we can count up to the bonusID portion
			local countSplit = {strsplit(":", result)}
			result = shortID --set this to default shortID, if we have something we will replace it below

			--make sure we have a bonusID count
			if countSplit and #countSplit > 13 then
				local bonusCount = countSplit[13] or 0 -- do we have a bonusID number count?
				bonusCount = bonusCount == "" and 0 or bonusCount --make sure we have a count if not default to zero
				bonusCount = tonumber(bonusCount)

				--check if we have even anything to work with for the amount of bonusID's
				--btw any numbers after the bonus ID are either upgradeValue which we don't care about or unknown use right now
				--http://wow.gamepedia.com/ItemString
				if bonusCount > 0 and countSplit[1] then
					--return the string with just the bonusID's in it
					local newItemStr = ""

					--11th place because 13 is bonus ID, one less from 13 (12) would be technically correct, but we have to compensate for ItemID we added in front so substract another one (11).
					newItemStr = countSplit[1]..":::::::::::"

					--lets add the bonusID's, ignore the end past bonusID's
					for i=13, (13 + bonusCount) do
						newItemStr = newItemStr..":"..countSplit[i]
					end

					--add the unknowns at the end, upgradeValue doesn't always have to be supplied.
					result = newItemStr.."::::::" --replace the default shortid with our new corrected one (total 19 variables in https://wowpedia.fandom.com/wiki/ItemLink)
				end
			end
		end

		--grab the link results if we have it, otherwise use the shortID
		link = result or shortID

		--if we have a count, then add it to the parse string
		if count and count > 1 then
			link = link .. ';' .. count
		end

		return link
	end
end

function BSYC:CreateFakeID(link, count, speciesID, level, breedQuality, maxHealth, power, speed, name)
	if not BattlePetTooltip then return end
	Debug(BSYC_DL.DEBUG, "CreateFakeID", link, count, speciesID, level, breedQuality, maxHealth, power, speed, name)
	--https://github.com/tomrus88/BlizzardInterfaceCode/blob/8633e552f3335b8c66b1fbcea6760a5cd8bcc06b/Interface/FrameXML/BattlePetTooltip.lua

	local petData

	if link and not speciesID then
		local linkType, linkOptions, petName = LinkUtil.ExtractLink(link)
		if linkType ~= "battlepet" then return end
		--speciesID, level, breedQuality, maxHealth, power, speed, name
		speciesID = linkOptions:match("(%d+):")
		petData = linkOptions:match("%d+:%d+:%d+:%d+:%d+:%d+")
	end

	--either pass the link or speciesID
	if speciesID then
		if not petData then
			petData = strjoin(":", speciesID, level or 0, breedQuality or 0, maxHealth or 0, power or 0, speed or 0)
		end
		--we do this so as to not interfere with standard itemid's.  Example a speciesID can be 1345 but there is a real item with itemID 1345.
		--to compensate for this we will use a ridiculous number to avoid conflicting with standard itemid's
		local fakePetID = BSYC.FakePetCode + (speciesID * 100000)

		if fakePetID then
			if not count then count = 1 end

			local encodeStr = self:EncodeOpts({petdata=petData})
			if encodeStr then
				return fakePetID..";"..count..";"..encodeStr
			end
		end
	end
end

function BSYC:IsBattlePetFakeID(fakeID)
	if not fakeID or not tonumber(fakeID) then return false end
	fakeID = tonumber(fakeID)

	if fakeID >= BSYC.FakePetCode then
		return true
	end
	return false
end

function BSYC:FakeIDToSpeciesID(fakeID)
	if not fakeID or not tonumber(fakeID) then return end
	fakeID = tonumber(fakeID)

	if fakeID >= BSYC.FakePetCode then
		fakeID = (fakeID - BSYC.FakePetCode) / 100000
		return fakeID
	end
end

function BSYC:GetShortItemID(link)
	if link then
		if type(link) == "number" then link = tostring(link) end

		--first check if we are being sent a battlepet link
		local isBattlepet = string.match(link, ".*(battlepet):.*") == "battlepet"
		if isBattlepet then
			--create a FakeID
			link = BSYC:CreateFakeID(link)
		end
		if not link then return end

		return link:match("item:(%d+):") or link:match("^(%d+):") or strsplit(";", link) or link
	end
end

function BSYC:GetShortCurrencyID(link)
	--https://wowpedia.fandom.com/wiki/Hyperlinks#currency
    if link then
        if type(link) == "number" then link = tostring(link) end
        link = link:match("currency:([%d:]+)[:]?") or link
        local link = link:match("currency:([%d:]+):") or link:match("currency:(%d+):") or link:match("^(%d+):") or link
        return tonumber(link)
    end
end

function BSYC:SetDefaults(category, defaults)
	local dbObj = BagSyncDB["options§"]
	if category and dbObj[category] == nil then dbObj[category] = {} end

	for k, v in pairs(defaults) do
		if category and dbObj[category][k] == nil then
			dbObj[category][k] = v
		elseif not category and dbObj[k] == nil then
			dbObj[k] = v
		end
	end
end

function BSYC:CreateFonts()
	if not BSYC.options then return end

	local flags = ""
	if BSYC.options.extTT_FontMonochrome and BSYC.options.extTT_FontOutline ~= "NONE" then
		flags = "MONOCHROME,"..BSYC.options.extTT_FontOutline
	elseif BSYC.options.extTT_FontMonochrome then
		flags = "MONOCHROME"
	elseif BSYC.options.extTT_FontOutline ~= "NONE" then
		flags = BSYC.options.extTT_FontOutline
	end
	BSYC.__fontFlags = flags

	local fontObject = CreateFont("BagSyncExtTT_Font")
	fontObject:SetFont(SML:Fetch(SML_FONT, BSYC.options.extTT_Font), BSYC.options.extTT_FontSize, flags)
	BSYC.__font = fontObject
end

function BSYC:CanDoCurrency()
	--Classic servers do have some implementations of these features installed, so we have to do checks
	--WOTLK has only a partial implementation of the C_CurrencyInfo API, so we have to check for that as well
	if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListInfo then return true end
	if GetCurrencyListInfo then return true end
	if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListLink then return true end
	if GetCurrencyListLink then return true end
	return false
end

function BSYC:CanDoProfessions()
	if not C_TradeSkillUI or not C_TradeSkillUI.GetAllRecipeIDs then return false end
	if not C_TradeSkillUI.IsTradeSkillLinked or not C_TradeSkillUI.IsTradeSkillGuild or not C_TradeSkillUI.IsNPCCrafting then return false end
	if not C_TradeSkillUI.GetBaseProfessionInfo or not C_TradeSkillUI.GetChildProfessionInfo then return false end
	if not C_TradeSkillUI.GetCategories or not C_TradeSkillUI.GetCategoryInfo then return false end
	if not C_TradeSkillUI.GetRecipeInfo then return false end
	if not GetProfessions or not GetProfessionInfo then return false end
	return true
end

function BSYC:ResetFramePositions()
	local moduleList = {
		"Blacklist",
		"Whitelist",
		"Currency",
		"Professions",
		"Recipes",
		"Gold",
		"Profiles",
		"Search",
		"AdvancedSearch",
		"SortOrder",
		"Debug",
		"Details",
	}
	for i=1, #moduleList do
		local mName = moduleList[i]
		if BSYC:GetModule(mName, true) and BSYC:GetModule(mName).frame then
			BSYC:GetModule(mName).frame:ClearAllPoints()
			BSYC:GetModule(mName).frame:SetPoint("CENTER",UIParent,"CENTER", 0, 0)
		end
	end
end

function BSYC:GetBSYC_FrameLevel()
	local count = 0
	local moduleList = {
		"Blacklist",
		"Whitelist",
		"Currency",
		"Professions",
		"Recipes",
		"Gold",
		"Profiles",
		"Search",
		"AdvancedSearch",
		"SortOrder",
		"Debug",
		"Details",
	}
	for i=1, #moduleList do
		local mName = moduleList[i]
		if BSYC:GetModule(mName, true) and BSYC:GetModule(mName).frame and BSYC:GetModule(mName).frame:IsVisible() then
			--20 is a nice healthy number to push the frame in levels, this compensates for frames within the frames that may have varying levels like scrollframes
			count = count + 20
		end
	end
	return count
end

function BSYC:SetBSYC_FrameLevel(module)
	if module and module.frame then
		local bsycLVL = self:GetBSYC_FrameLevel()
		--set the frame level higher than any visible ones to overlap it
		module.frame:SetFrameLevel(bsycLVL or 1)
		--check for the closeBtn otherwise it overlaps, because the Blizzard template sets the framelevel to 510 for UIPanelCloseButton
		if module.frame.closeBtn then
			module.frame.closeBtn:SetFrameLevel((bsycLVL or 1) + 1) --you have to increment it at least once to draw over our frame background
		end
	end
end

BSYC.timerFrame = CreateFrame("Frame")
BSYC.timerFrame:Hide()
BSYC.timers = {}

function BSYC:StartTimer(name, delay, selfObj, func, ...)
	local found = false
	for i=#BSYC.timers, 1, -1 do
		local tmr = BSYC.timers[i]
		if tmr.name == name then
			BSYC.timers[i].func = func
			BSYC.timers[i].object = selfObj
			BSYC.timers[i].delay = delay
			BSYC.timers[i].origDelay = delay
			BSYC.timers[i].argsCount = select("#", ...)
			BSYC.timers[i].argsList = {...}
			found = true
			break
		end
	end
	if not found then
		-- args (...) are passed a variable length arguments in an index table (https://www.lua.org/pil/5.2.html)
		table.insert(BSYC.timers, {
			func = func,
			object = selfObj,
			delay = delay,
			origDelay = delay,
			name = name,
			argsCount = select("#", ...),
			argsList = {...}
		})
	end
	BSYC.timerFrame:Show() --show frame to start the OnUpdate
end

function BSYC:StopTimer(name)
	--iterate backwards since we are using table.remove
	for i=#BSYC.timers, 1, -1 do
		if BSYC.timers[i] and BSYC.timers[i].name == name then
			table.remove(BSYC.timers, i)
		end
	end
end

BSYC.timerFrame:SetScript("OnUpdate", function(self, elapsed)
	local chk = false
	--iterate backwards since we are using table.remove
	for i=#BSYC.timers, 1, -1 do
		local tmr = BSYC.timers[i]
		tmr.delay = tmr.delay - elapsed

        if tmr.delay < 0 then
			Debug(BSYC_DL.SL3, "DoTimer", tmr.name, tmr.origDelay, tmr.object, tmr.func)
			if type(tmr.func) == "string" and tmr.object then
				tmr.object[tmr.func](tmr.object, unpack(tmr.argsList or {}, 1, tmr.argsCount))
			else
				tmr.func(unpack(tmr.argsList or {}, 1, tmr.argsCount))
			end
			table.remove(BSYC.timers, i)
        end
		chk = true
	end
    if not BSYC.timers or #BSYC.timers < 1 or not chk then
        BSYC.timerFrame:Hide()
    end
end)

-- function BSYC:CheckDB_Reset()
-- 	Debug(BSYC_DL.INFO, "CheckDB_Reset")
-- 	if not BagSyncDB["forceDBReset§"] or BagSyncDB["forceDBReset§"] < forceDBReset then
-- 		BagSyncDB = { ["forceDBReset§"] = forceDBReset }
-- 		BSYC:Print("|cFFFF9900"..L.DatabaseReset.."|r")
-- 		C_Timer.After(6, function()
-- 			StaticPopup_Show("BAGSYNC_RESETDB_INFO")
--			ReloadUI()
-- 		end)
-- 		return
-- 	end
-- end

--create base DB entries before we load any modules
function BSYC:OnEnable()

	--initiate database
	BagSyncDB = BagSyncDB or {}

	--load the options and blacklist
	BagSyncDB["options§"] = BagSyncDB["options§"] or {}
	BagSyncDB["blacklist§"] = BagSyncDB["blacklist§"] or {}
	BagSyncDB["whitelist§"] = BagSyncDB["whitelist§"] or {}
	BagSyncDB["savedsearch§"] = BagSyncDB["savedsearch§"] or {}
	BagSyncDB["forceDBReset§"] = BagSyncDB["forceDBReset§"] or forceDBReset

	--main DB table
	BSYC.db = BSYC.db or {}
	BSYC.db.blacklist = BagSyncDB["blacklist§"]
	BSYC.db.whitelist = BagSyncDB["whitelist§"]
	BSYC.db.savedsearch = BagSyncDB["savedsearch§"]

	--setup the debug values since Debug module loads before Data module
	BSYC.options = BagSyncDB["options§"]

	--check for resets
	--BSYC:CheckDB_Reset()

	BSYC:SetDefaults("debug", debugDefaults)
end