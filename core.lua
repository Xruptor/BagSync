--[[
	core.lua
		Initiates the BagSync addon within Ace3, very important!
--]]

local BAGSYNC, BSYC = ... --grab the addon namespace
LibStub("AceAddon-3.0"):NewAddon(BSYC, "BagSync", "AceEvent-3.0", "AceConsole-3.0")
_G[BAGSYNC] = BSYC --add it to the global frame space, otherwise you won't be able to call it

BSYC.IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
local function Debug(...)
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", "CORE")
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end
end

function BagSync_ShowWindow(windowName)
    if windowName == "Gold" then
        BSYC:GetModule("Tooltip"):MoneyTooltip()
    else
        BSYC:GetModule(windowName).frame:Show()
    end
end

function BSYC:ParseItemLink(link, count)
	if link then
	
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
				link = GetTradeSkillItemLink(TradeSkillFrame.selectedSkill)
			else
				local i = focus:match('TradeSkillReagent(%d+)')
				if i then
					link = GetTradeSkillReagentItemLink(TradeSkillFrame.selectedSkill, tonumber(i))
				end
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
	
	--either pass the link or speciesID
	if link or speciesID then
	
		local isBattlepet = speciesID or string.match(link, ".*(battlepet):.*") == "battlepet"
		
		if isBattlepet then
		
			if not speciesID and link then
				local _, _ , _ , petID, petLevel, petRarity, petHP, petAtk, petSpeed, _ , petName = string.find(link,"(.*)battlepet:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(.*)%[(.*)%]")
				speciesID = petID
			end
		
			--lets generate our own fake PetID
			if speciesID then 
				local speciesName, _, petType, companionID, _, _, _, _, _, _, _, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
				
				if petType and companionID and creatureDisplayID then
					local fakePetID = 10000000000
					fakePetID = fakePetID + (speciesID * 100000)
					fakePetID = fakePetID + (petType * 1000)
					fakePetID = fakePetID + (companionID * 100)
					fakePetID = fakePetID + (creatureDisplayID)
					
					if fakePetID then
						if not count then count = 1 end
						--put a 2 at the end as an identifier to mark it as a battlepet
						return fakePetID..';'..count..';2;'..speciesID
					end
				end
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
		
		return link:match("item:(%d+):") or link:match("^(%d+):") or strsplit(";", link) or link
	end
end

function BSYC:GetShortCurrencyID(link)
	if link then
		if type(link) == "number" then link = tostring(link) end
		local link = link:match("currency:(%d+):") or link:match("^(%d+):") or link
		return tonumber(link)
	end
end

function BSYC:GetCurrencyID(link)
	if link then
		local result = link:match("currency:([%d:]+)")
		local currencyID = self:GetShortCurrencyID(link)
		if result then
			result = currencyID --set this to default currencyID, if we have something we will replace it below
		end
		link = result or currencyID
		return link
	end
end
