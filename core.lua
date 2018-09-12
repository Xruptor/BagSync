--[[
	core.lua
		Initiates the BagSync addon within Ace3, very important!
--]]

local BAGSYNC, BSYC = ... --grab the addon namespace
LibStub("AceAddon-3.0"):NewAddon(BSYC, "BagSync", "AceEvent-3.0", "AceConsole-3.0")
_G[BAGSYNC] = BSYC --add it to the global frame space, otherwise you won't be able to call it

local debugf = tekDebug and tekDebug:GetFrame("BagSync")

function BSYC:Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

function BSYC:ParseItemLink(link, count)

	if link then
	
		--there are times link comes in as a number and breaks string matching, convert to string to fix
		if type(link) == "number" then link = tostring(link) end
	
		--sometimes the profession window has a bug for the items it parses, so lets fix it
		-----------------------------
		if tonumber(self:GetShortItemID(link)) == 0 and TradeSkillFrame then
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
		
		local result = link:match("item:([%d:]+)")
		local shortID = self:GetShortItemID(link)
		
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

function BSYC:GetShortItemID(link)
	if link then
		if type(link) == "number" then link = tostring(link) end
		return link:match("item:(%d+):") or link:match("^(%d+):") or link
	end
end

--sort by key element rather then value
function BSYC:pairsByKeys (t, f)
	local a = {}
		for n in pairs(t) do table.insert(a, n) end
		table.sort(a, f)
		local i = 0      -- iterator variable
		local iter = function ()   -- iterator function
			i = i + 1
			if a[i] == nil then return nil
			else return a[i], t[a[i]]
			end
		end
	return iter
end

function BSYC:TableLength(tbl)
	local n = 0
	for k in pairs(tbl) do
		n = n + 1
	end
	return n
end
	
