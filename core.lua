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

BSYC.debugTrace = false --custom option just for me to debug stuff, do not turn this on :P, you have been warned

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
local function Debug(...)
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", "CORE")
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end
end

--According to https://github.com/Xruptor/BagSync/issues/196 this partciular OnEvent causes a significant delay on startup for users.
--Perhaps the event is being fired WAY too much for folks?
if LibStub("LibItemSearch-1.2") and LibStub("LibItemSearch-1.2").Scanner and LibStub("LibItemSearch-1.2").Scanner:GetScript("OnEvent") then
	LibStub("LibItemSearch-1.2").Scanner:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
	LibStub("LibItemSearch-1.2").Scanner:SetScript("OnEvent", nil)
end
	
--use /framestack to debug windows and show tooltip information
--use if you press SHIFT while doing the above command it gives you a bit more information

--this is only for hash tables that aren't indexed with 1,2,3,4 etc.. but use custom index keys
--if you are using table.insert() or tables that are indexed with numbers then use # instead for table length.  #table as example
function BSYC:GetHashTableLen(tbl)
	local count = 0
	for _, __ in pairs(tbl) do
		count = count + 1
	end
	return count
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

function BSYC:ParseItemLink(link, count)
	if link then
		if not count then count = 1 end
		
		--if we are parsing a database entry just return it, chances are it's a battlepet anyways
		local qLink, qCount, qIdentifier = strsplit(";", link)
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
	
		--there are times link comes in as a number and breaks string matching, convert to string to fix
		if type(link) == "number" then link = tostring(link) end
		
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
					--string.rep repeats a pattern.
					newItemStr = countSplit[1]..string.rep(":", 11)
					
					--lets add the bonusID's, ignore the end past bonusID's
					for i=13, (13 + bonusCount) do
						newItemStr = newItemStr..":"..countSplit[i]
					end
					
					--add the unknowns at the end, upgradeValue doesn't always have to be supplied.
					result = newItemStr..":::" --replace the default shortid with our new corrected one
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
	if not BSYC.IsRetail then return nil end
	
	--https://github.com/tomrus88/BlizzardInterfaceCode/blob/8633e552f3335b8c66b1fbcea6760a5cd8bcc06b/Interface/FrameXML/BattlePetTooltip.lua
	
	if link and not speciesID then
		local linkType, linkOptions, name = LinkUtil.ExtractLink(link)
		if linkType ~= "battlepet" then
			return nil
		end

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
			--put a 2 at the end as an identifier to mark it as a battlepet
			return fakePetID..';'..count..';2;'..speciesID
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
