--[[
	core.lua
		Initiates the BagSync addon within Ace3, very important!
--]]

local BAGSYNC, BSYC = ... --grab the addon namespace
LibStub("AceAddon-3.0"):NewAddon(BSYC, "BagSync", "AceEvent-3.0", "AceConsole-3.0")
_G[BAGSYNC] = BSYC --add it to the global frame space, otherwise you won't be able to call it

local WOW_PROJECT_ID = _G.WOW_PROJECT_ID
local WOW_PROJECT_MAINLINE = _G.WOW_PROJECT_MAINLINE
local WOW_PROJECT_CLASSIC = _G.WOW_PROJECT_CLASSIC
--local WOW_PROJECT_BURNING_CRUSADE_CLASSIC = _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local WOW_PROJECT_WRATH_CLASSIC = _G.WOW_PROJECT_WRATH_CLASSIC

--Get TOC version
--/dump select(4, GetBuildInfo())
--https://wowpedia.fandom.com/wiki/Template:API_LatestInterface

--use the ingame trace tool to debug stuff
--/etrace or /eventtrace

--Dump tables DevTools_Dump({ table }) or DevTools_Dump(table)

BSYC.IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
BSYC.IsClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
--BSYC.IsTBC_C = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
BSYC.IsWLK_C = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
function BSYC.DEBUG(level, sName, ...)
	if not BSYC.options or not BSYC.options.debug or not BSYC.options.debug.enable then return end

	--old tekDebug code just in case I want to track old debugging method
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", sName)
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end

	local Debug = BSYC:GetModule("Debug")
	if not Debug then return end

	Debug:AddMessage(level, sName, ...)
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
	--Example = "battlepet=245|auction=124567|foo=bar|tickle=elmo|gtab=3|test=12:3:4|forthe=horde"
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

function BSYC:EncodeOpts(tbl, link)
	if not tbl then return nil end
	local tmpStr = ""

	if link then
		--when doing the split, make sure to merge our table
		local xLink, xCount, xOpts = self:Split(link, false, tbl)

		if xLink then
			if not xCount then xCount = 1 end

			for k, v in pairs(xOpts) do
				tmpStr = tmpStr.."|"..k.."="..v
			end
			tmpStr = string.sub(tmpStr, 2)  -- remove first pipe

			if tmpStr ~= "" then
				return xLink..";"..xCount..";"..tmpStr
			end
		end

		--this is an invalid ParseItemLink, return empty string
		return nil
	end

	for k, v in pairs(tbl) do
		tmpStr = tmpStr.."|"..k.."="..v
	end

	tmpStr = string.sub(tmpStr, 2)  -- remove first pipe
	if tmpStr ~= "" then
		return tmpStr
	end

	return nil
end

function BSYC:Split(dataStr, skipOpts, mergeOpts)
	local qLink, qCount, qOpts = strsplit(";", dataStr)
	--only do Opts functions if we need too, otherwise just return the link and count
	if not skipOpts or mergeOpts then
		return qLink, qCount, self:DecodeOpts(qOpts, mergeOpts)
	end
	return qLink, qCount
end

function BagSync_ShowWindow(windowName)
    if windowName == "Gold" then
        BSYC:GetModule("Tooltip"):MoneyTooltip()
    else
		if BSYC:GetModule(windowName).frame:IsVisible() then
			BSYC:GetModule(windowName).frame:Hide()
		else
			BSYC:GetModule(windowName).frame:Show()
		end
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
			return BSYC:CreateFakeBattlePetID(link, count)
		end

		local result = link:match("item:([%d:]+)")
		local shortID = self:GetShortItemID(link)

		--sometimes the profession window has a bug for the items it parses, so lets fix it
		-----------------------------
		if shortID and tonumber(shortID) == 0 and TradeSkillFrame then
			local focus = GetMouseFocus():GetName()

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

function BSYC:CreateFakeBattlePetID(link, count, speciesID)
	if not BattlePetTooltip then return end
	Debug(1, "CreateFakeBattlePetID", link, count, speciesID)

	--https://github.com/tomrus88/BlizzardInterfaceCode/blob/8633e552f3335b8c66b1fbcea6760a5cd8bcc06b/Interface/FrameXML/BattlePetTooltip.lua

	if link and not speciesID then
		local linkType, linkOptions, name = LinkUtil.ExtractLink(link)
		if linkType ~= "battlepet" then return end

		speciesID = strsplit(":", linkOptions)
	end

	--either pass the link or speciesID
	if speciesID then

		--we do this so as to not interfere with standard itemid's.  Example a speciesID can be 1345 but there is a real item with itemID 1345.
		--to compensate for this we will use a ridiculous number to avoid conflicting with standard itemid's
		local fakePetID = 10000000000
		fakePetID = fakePetID + (speciesID * 100000)

		if fakePetID then
			if not count then count = 1 end

			local encodeStr = self:EncodeOpts({battlepet=speciesID})
			if encodeStr then
				return fakePetID..";"..count..";"..encodeStr
			end
		end
	end
end

function BSYC:GetShortItemID(link)
	if link then
		if type(link) == "number" then link = tostring(link) end

		--first check if we are being sent a battlepet link
		local isBattlepet = string.match(link, ".*(battlepet):.*") == "battlepet"
		if isBattlepet then
			--create a FakeID
			link = BSYC:CreateFakeBattlePetID(link)
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

--create base DB entries before we load any modules
function BSYC:OnEnable()

	--initiate database
	BagSyncDB = BagSyncDB or {}

	--load the options and blacklist
	BagSyncDB["options§"] = BagSyncDB["options§"] or {}
	BagSyncDB["blacklist§"] = BagSyncDB["blacklist§"] or {}
	BagSyncDB["whitelist§"] = BagSyncDB["whitelist§"] or {}

	--setup the debug values since Debug module loads before Data module
	BSYC.options = BagSyncDB["options§"]
	if BSYC.options.debug == nil then BSYC.options.debug = {} end
	if BSYC.options.debug.enable == nil then BSYC.options.debug.enable = false end
	if BSYC.options.debug.DEBUG == nil then BSYC.options.debug.DEBUG = false end
	if BSYC.options.debug.INFO == nil then BSYC.options.debug.INFO = true end
	if BSYC.options.debug.TRACE == nil then BSYC.options.debug.TRACE = true end
	if BSYC.options.debug.WARN == nil then BSYC.options.debug.WARN = false end
	if BSYC.options.debug.FINE == nil then BSYC.options.debug.FINE = false end
	if BSYC.options.debug.SL1 == nil then BSYC.options.debug.SL1 = false end
	if BSYC.options.debug.SL2 == nil then BSYC.options.debug.SL2 = false end
	if BSYC.options.debug.SL3 == nil then BSYC.options.debug.SL3 = false end

end