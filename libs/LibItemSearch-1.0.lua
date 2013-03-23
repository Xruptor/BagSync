--[[
	ItemSearch
		An item text search engine of some sort
		
	Grammar:
		<search> 			:=	<intersect search>
		<intersect search> 	:=	<union search> & <union search> ; <union search>
		<union search>		:=	<negatable search>  | <negatable search> ; <negatable search>
		<negatable search> 	:=	!<primitive search> ; <primitive search>
		<primitive search>	:=	<tooltip search> ; <quality search> ; <type search> ; <text search>
		<tooltip search>	:=  bop ; boa ; bou ; boe ; quest
		<quality search>	:=	q<op><text> ; q<op><digit>
		<ilvl search>		:=	ilvl<op><number>
		<type search>		:=	t:<text>
		<text search>		:=	<text>
		<item set search>	:=	s:<setname> (setname can be * for all sets)
		<op>				:=  : | = | == | != | ~= | < | > | <= | >=
--]]

local Lib = LibStub:NewLibrary('LibItemSearch-1.0', 9)
if not Lib then
  return
else
  Lib.searchTypes = Lib.searchTypes or {}
end


--[[ Locals ]]--

local tonumber, select, split = tonumber, select, strsplit
local function useful(a) -- check if the search has a decent size
  return a and #a >= 1
end

local function compare(op, a, b)
  if op == '<=' then
    return a <= b
  end

  if op == '<' then
    return a < b
  end

  if op == '>' then
    return a > b
  end

  if op == '>=' then
    return a >= b
  end

  return a == b
end

local function match(search, ...)
  for i = 1, select('#', ...) do
    local text = select(i, ...)
    if text and text:lower():find(search) then
      return true
    end
  end
  return false
end


--[[ User API ]]--

function Lib:Find(itemLink, search)
	if not useful(search) then
		return true
	end

	if not itemLink then
		return false
	end

  return self:FindUnionSearch(itemLink, split('\124', search:lower()))
end


--[[ Top-Layer Processing ]]--

-- union search: <search>&<search>
function Lib:FindUnionSearch(item, ...)
	for i = 1, select('#', ...) do
		local search = select(i, ...)
		if useful(search) and self:FindIntersectSearch(item, split('\038', search)) then
      		return true
		end
	end
end


-- intersect search: <search>|<search>
function Lib:FindIntersectSearch(item, ...)
	for i = 1, select('#', ...) do
		local search = select(i, ...)
		if useful(search) and not self:FindNegatableSearch(item, search) then
        	return false
		end
	end
	return true
end


-- negated search: !<search>
function Lib:FindNegatableSearch(item, search)
  local negatedSearch = search:match('^[!~][%s]*(.+)$')
  if negatedSearch then
    return not self:FindTypedSearch(item, negatedSearch)
  end
  return self:FindTypedSearch(item, search, true)
end


--[[
     Search Types:
      easly defined search types

      A typed search object should look like the following:
        {
          string id
            unique identifier for the search type,

          string searchCapture = function canSearch(self, search)
            returns a capture if the given search matches this typed search

          bool isMatch = function findItem(self, itemLink, searchCapture)
            returns true if <itemLink> is in the search defined by <searchCapture>
          }
--]]

function Lib:RegisterTypedSearch(object)
	self.searchTypes[object.id] = object
end

function Lib:GetTypedSearches()
	return pairs(self.searchTypes)
end

function Lib:GetTypedSearch(id)
	return self.searchTypes[id]
end

function Lib:FindTypedSearch(item, search, default)
  if not useful(search) then
    return default
  end

  local tag, rest = search:match('^[%s]*(%w+):(.*)$')
  if tag then
    if useful(rest) then
      search = rest
    else
      return default
    end
  end

  local operator, search = search:match('^[%s]*([%>%<%=]*)[%s]*(.*)$')
  if useful(search) then
    operator = useful(operator) and operator
  else
    return default
  end

  if tag then
    tag = '^' .. tag
    for id, searchType in self:GetTypedSearches() do
      if searchType.tags then
        for _, value in pairs(searchType.tags) do
          if value:find(tag) then
            return self:UseTypedSearch(searchType, item, operator, search)
          end
        end
      end
    end
  else
    for id, searchType in self:GetTypedSearches() do
      if not searchType.onlyTags and self:UseTypedSearch(searchType, item, operator, search) then
        return true
      end
    end
    return false
  end

  return default
end

function Lib:UseTypedSearch(searchType, item, operator, search)
  local capture1, capture2, capture3 = searchType:canSearch(operator, search)
  if capture1 then
    if searchType:findItem(item, operator, capture1, capture2, capture3) then
      return true
    end
  end
end


--[[ Item name ]]--

Lib:RegisterTypedSearch{
  id = 'itemName',
  tags = {'n', 'name'},

	canSearch = function(self, operator, search)
		return not operator and search
	end,

	findItem = function(self, item, _, search)
		local name = item:match('%[(.-)%]')
		return match(search, name)
	end
}


--[[ Item type, subtype and equiploc ]]--

Lib:RegisterTypedSearch{
	id = 'itemType',
	tags = {'t', 'type', 'slot'},

	canSearch = function(self, operator, search)
		return not operator and search
	end,

	findItem = function(self, item, _, search)
		local type, subType, _, equipSlot = select(6, GetItemInfo(item))
		return match(search, type, subType, _G[equipSlot])
	end
}


--[[ Item quality ]]--

local qualities = {}
for i = 0, #ITEM_QUALITY_COLORS do
  qualities[i] = _G['ITEM_QUALITY' .. i .. '_DESC']:lower()
end

Lib:RegisterTypedSearch{
	id = 'itemQuality',
	tags = {'q', 'quality'},

	canSearch = function(self, _, search)
		for i, name in pairs(qualities) do
		  if name:find(search) then
			return i
		  end
		end
	end,

	findItem = function(self, link, operator, num)
		local quality = select(3, GetItemInfo(link))
		return compare(operator, quality, num)
	end,
}


--[[ Item level ]]--

Lib:RegisterTypedSearch{
	id = 'itemLevel',
	tags = {'l', 'level', 'lvl'},

	canSearch = function(self, _, search)
		return tonumber(search)
	end,

	findItem = function(self, link, operator, num)
		local lvl = select(4, GetItemInfo(link))
		if lvl then
			return compare(operator, lvl, num)
		end
	end,
}


--[[ Tooltip searches ]]--

local tooltipCache = setmetatable({}, {__index = function(t, k) local v = {} t[k] = v return v end})
local tooltipScanner = _G['LibItemSearchTooltipScanner'] or CreateFrame('GameTooltip', 'LibItemSearchTooltipScanner', UIParent, 'GameTooltipTemplate')

local function link_FindSearchInTooltip(itemLink, search)
	local itemID = itemLink:match('item:(%d+)')
	if not itemID then
		return
	end
	
	local cachedResult = tooltipCache[search][itemID]
	if cachedResult ~= nil then
		return cachedResult
	end

	tooltipScanner:SetOwner(UIParent, 'ANCHOR_NONE')
	tooltipScanner:SetHyperlink(itemLink)

	local result = false
	if tooltipScanner:NumLines() > 1 and _G[tooltipScanner:GetName() .. 'TextLeft2']:GetText() == search then
		result = true
	elseif tooltipScanner:NumLines() > 2 and _G[tooltipScanner:GetName() .. 'TextLeft3']:GetText() == search then
		result = true
	end

	tooltipCache[search][itemID] = result
	return result
end


Lib:RegisterTypedSearch{
	id = 'bindType',

	canSearch = function(self, _, search)
		return self.keywords[search]
	end,

	findItem = function(self, itemLink, _, search)
		return search and link_FindSearchInTooltip(itemLink, search)
	end,

	keywords = {
    		['soulbound'] = ITEM_BIND_ON_PICKUP,
    		['bound'] = ITEM_BIND_ON_PICKUP,
		['boe'] = ITEM_BIND_ON_EQUIP,
		['bop'] = ITEM_BIND_ON_PICKUP,
		['bou'] = ITEM_BIND_ON_USE,
		['quest'] = ITEM_BIND_QUEST,
		['boa'] = ITEM_BIND_TO_BNETACCOUNT
	}
}

Lib:RegisterTypedSearch{
	id = 'tooltip',
	tags = {'tt', 'tip', 'tooltip'},
	onlyTags = true,

	canSearch = function(self, _, search)
		return search
	end,

	findItem = function(self, link, _, search)
		tooltipScanner:SetOwner(UIParent, 'ANCHOR_NONE')
		tooltipScanner:SetHyperlink(link)

		for i = 1, tooltipScanner:NumLines() do
			local text =  _G[tooltipScanner:GetName() .. 'TextLeft' .. i]:GetText():lower()
			
			if text:find(search) then
				return true
			end
		end

		return false
	end,
}


--[[ Equipment sets ]]--

--Placeholder variables; will be replaced with references to the addon-appropriate handlers at runtime
local ES_FindSets, ES_CheckItem

--Helper: Global Pattern Matching Function (matches ANY set name if search is *, or the EXACT set name if exactMatch is true, or any set name STARTING with the provided search terms if exactMatch is false (this means it will not match in middle of strings). all equipment set searches below use this function to FIRST try to find a set with the EXACT name entered, and if that fails they'll look for all sets that START with the search term, using recursive calls.
local function ES_TrySetName(setName, search, exactMatch)
	return (search == '*') or (exactMatch and setName:lower() == search) or (not exactMatch and setName:lower():sub(1,strlen(search)) == search)
end

--Addon Support: ItemRack
if IsAddOnLoaded('ItemRack') then
	function ES_FindSets(setList, search, exactMatch)
		for setName, _ in pairs(ItemRackUser.Sets) do
			if ES_TrySetName(setName, search, exactMatch) then
				if (search ~= '*') or (search == '*' and setName:sub(1,1) ~= '~') then --note: this additional tilde check skips internal ItemRack sets when doing a global set search (internal sets are prefixed with tilde, such as ~Unequip, and they contain temporary data that should not be part of a global search)
					table.insert(setList, setName)
				end
			end
		end
		if (search ~= '*') and exactMatch and #setList == 0 then --if we just finished an exact, non-global (not "*"), name match search and still have no results, try one more time with partial ("starts with") set name matching instead
			ES_FindSets(setList, search, false)
		end
	end

	local irSameID = (ItemRack and ItemRack.SameID or nil) --set up local reference for speed if they're an ItemRack user
	function ES_CheckItem(itemLink, setList)
		local itemID = string.match(itemLink or '','item:(%-?%d+)') or 0 --grab the baseID of the item we are searching for (we don't need the full itemString, since we'll only be doing a loose baseID comparison below)

		for _, setName in pairs(setList) do
			for _, irItemData in pairs(ItemRackUser.Sets[setName].equip) do --note: do not change this to ipairs() or it will abort scanning at empty slots in a set
				--[[ commented out due to libItemSearch lacking a "best match before generic match" priority matching system, so we'll have to go for "generic match" only (below), which matches items that have the same base ItemID as items from the set, as ItemRack cannot guarantee that the stored ItemString will be valid anymore (if the user has modified the item since last saving the set)
				if itemString == irItemData then -- strict match: perform a strict match to check if this is the *exact* same item (same gems, enchants, etc)
					return true
				end]]--

				if irSameID(itemID, irItemData) then --loose match: use ItemRack's built-in "Base ItemID" comparison function to allow us to match any items that have the same base itemID (disregarding strict matching of gems, enchants, etc); due to libItemSearch limitations it's the best compromise and guarantees to always highlight the correct items even if we may catch some extras/duplicates that weren't part of the set
					return true
				end
			end
		end

		return false
	end

--Addon Support: Wardrobe
elseif IsAddOnLoaded('Wardrobe') then
	function ES_FindSets(setList, search, exactMatch)
		for _, waOutfit in ipairs(Wardrobe.CurrentConfig.Outfit) do
			if ES_TrySetName(waOutfit.OutfitName, search, exactMatch) then
				table.insert(setList, waOutfit) --insert an actual reference to the matching set's data table, instead of just storing the /name/ of the set. we do this due to how Wardrobe works (all sets are in a numerically indexed table and storing the table offset would therefore be unreliable)
			end
		end
		if (search ~= '*') and exactMatch and #setList == 0 then --if we just finished an exact, non-global (not "*"), name match search and still have no results, try one more time with partial ("starts with") set name matching instead
			ES_FindSets(setList, search, false)
		end
	end

	function ES_CheckItem(itemLink, setList)
		local itemID = tonumber(string.match(itemLink or '','item:(%-?%d+)') or 0) --grab the baseID of the item we are searching for (we don't need the full itemString, since we'll only be doing a loose baseID comparison below)

		for _, waOutfit in pairs(setList) do
			for _, waItemData in pairs(waOutfit.Item) do
				if (waItemData.IsSlotUsed == 1) and (waItemData.ItemID == itemID) then --loose match: compare the current item's baseID to the baseID of the set item
					return true
				end
			end
		end

		return false
	end

--Last Resort: Blizzard Equipment Manager
else
	function ES_FindSets(setList, search, exactMatch)
		for i = 1, GetNumEquipmentSets() do
			local setName = GetEquipmentSetInfo(i)
			if ES_TrySetName(setName, search, exactMatch) then
				table.insert(setList, setName)
			end
		end
		if (search ~= '*') and exactMatch and #setList == 0 then --if we just finished an exact, non-global (not "*"), name match search and still have no results, try one more time with partial ("starts with") set name matching instead
			ES_FindSets(setList, search, false)
		end
	end

	function ES_CheckItem(itemLink, setList)
		local itemID = tonumber(string.match(itemLink or '','item:(%-?%d+)') or 0) --grab the baseID of the item we are searching for (we don't need the full itemString, since we'll only be doing a loose baseID comparison below)

		for _, setName in pairs(setList) do
			local bzSetItemIDs = GetEquipmentSetItemIDs(setName)
			for _, bzItemID in pairs(bzSetItemIDs) do --note: do not change this to ipairs() or it will abort scanning at empty slots in a set
				if itemID == bzItemID then --loose match: compare the current item's baseID to the baseID of the set item
					return true
				end
			end
		end

		return false
	end
end

Lib:RegisterTypedSearch{
	id = 'equipmentSet',
	tags = {'s', 'set'},

	canSearch = function(self, operator, search)
		return not operator and search
	end,

	findItem = function(self, itemLink, _, search)
		--this is an item-set search and we know that the only items that can possibly match will be *equippable* items, so we'll short-circuit the response for non-equippable items to speed up searches.
		if not IsEquippableItem(itemLink) then return false end
		
		--default to matching *all* equipment sets if no set name has been provided yet
		if search == '' then search = '*' end
		
		--generate a list of all equipment sets whose names begin with the search term (or a single set if an exact set name match is found), then look for our item in those equipment sets
		local setList = {}
		ES_FindSets(setList, search, true)
		if #setList == 0 then return false end
		return ES_CheckItem(itemLink, setList)
	end,
}