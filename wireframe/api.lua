--[[
	api.lua
		Standard core API calls for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace

function BSYC:rgbhex(r, g, b)
	if type(r) == "table" then
		if r.r then
			r, g, b = r.r, r.g, r.b
		else
			r, g, b = unpack(r)
		end
	end
	return string.format("|cff%02x%02x%02x", (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
end

function BSYC:tooltipColor(color, str)
	return string.format("|cff%02x%02x%02x%s|r", (color.r or 1) * 255, (color.g or 1) * 255, (color.b or 1) * 255, tostring(str))
end

function BSYC:ParseItemLink(link, count)

	if link then

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
				local count = countSplit[13] or 0 -- do we have a bonusID number count?
				count = count == "" and 0 or count --make sure we have a count if not default to zero
				count = tonumber(count)
				
				--check if we have even anything to work with for the amount of bonusID's
				--btw any numbers after the bonus ID are either upgradeValue which we don't care about or unknown use right now
				--http://wow.gamepedia.com/ItemString
				if count > 0 and countSplit[1] then
					--return the string with just the bonusID's in it
					local newItemStr = ""
					
					--11th place because 13 is bonus ID, one less from 13 (12) would be technically correct, but we have to compensate for ItemID we added in front so substract another one (11).
					--string.rep repeats a pattern.
					newItemStr = countSplit[1]..string.rep(":", 11)
					
					--lets add the bonusID's, ignore the end past bonusID's
					for i=13, (13 + count) do
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
		return link:match("item:(%d+):") or link:match("^(%d+):") or link
	end
end

function BSYC:IsInBG()
	if (GetNumBattlefieldScores() > 0) then
		return true
	end
	return false
end

function BSYC:IsInArena()
	local a,b = IsActiveBattlefieldArena()
	if not a then
		return false
	end
	return true
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