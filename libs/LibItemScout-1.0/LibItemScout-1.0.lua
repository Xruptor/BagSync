--[[
	Updated By: Xruptor

	LibItemScout-1.0 is distributed under the terms of the GNU General Public License (Version 3).
	As a special exception, the copyright holders of this library give you permission to embed it with independent modules to produce an addon,
	regardless of the license terms of these independent modules, and to copy and distribute the resulting software under terms of your choice, provided that you also meet,
	for each embedded independent module, the terms and conditions of the license of that module.
	
	This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
	See the GNU General Public License for more details.

	------------------------------

	NOTE: This is an updated/continuation of Tullers original LibItemSearch-1.0 code.  Since there already is a LibItemSearch-1.2, this library was renamed in order to prevent
	confusion from any future updates to the updated LibItemSearch-1.2 code by Jaliborc.  That way this code can be updated seperatly from LibItemSearch-1.2 and act as a continuation of the
	original base code.
	Original source credit goes to Jaliborc (João Libório), Tuller, Yewbacca (Equipment Set Searching) for the work on the original LibItemSearch-1.0 code.
	Tuller had given me permission to use this Library to incorporate into BagSync back in 2011-2012.  Original credit goes to Tuller for the original code.
	https://github.com/Tuller/LibItemSearch-1.0

	------------------------------

	Public API (optional, for better performance):

	Compiling a search once and reusing it avoids repeated parsing per item.

		local ItemScout = LibStub("LibItemScout-1.0")
		local compiled = ItemScout:CompileSearch("bind:boe && lvl:>=20 && name:robe")

		-- later, per-item:
		local matches = ItemScout:Find(itemLinkOrName, compiled, cacheObj)

	Notes:
	- `cacheObj` is optional but recommended for speed; it is required for some filters (ex: battle pet metadata).
	- `cacheObj` should be a plain Lua table with Blizzard API-like field names (so this library can avoid extra API calls).
	  Use the same naming used by the return values from `C_Item.GetItemInfo` and related APIs.

	  Common fields this library will use when present:
	    itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemEquipLoc,
	    classID, subclassID, bindType, expacID

	  Battle pet extras (BagSync-style FakeID support):
	    speciesID, speciesName, speciesIcon

	  Example:
	    local cacheObj = {
	      itemName = itemName,
	      itemLink = itemLink,
	      itemQuality = itemQuality,
	      itemLevel = itemLevel,
	      itemMinLevel = itemMinLevel,
	      itemType = itemType,
	      itemSubType = itemSubType,
	      itemEquipLoc = itemEquipLoc,
	      classID = classID,
	      subclassID = subclassID,
	      bindType = bindType,
	      expacID = expacID,
	    }

	  References (field naming / return ordering):
	    https://warcraft.wiki.gg/wiki/API_C_Item.GetItemInfo
	    https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
	- If you dynamically register typed searches at runtime and want to force recompilation of existing search strings,
	  call `ItemScout:ClearSearchCache()`.

	ItemSearch
	An item text search engine of some sort

	Grammar:
	<search> 				:=	<intersect search>
	<intersect search> 		:=	<union search> && <union search> ; <union search>
	<union search>			:=	<negatable search>  || <negatable search> ; <negatable search>
	<negatable search> 		:=	!<primitive search> ; <primitive search>
	<item name search>		:=	n ; name | n:<text> ; name:<text>
	<item bind search>		:=	bind | bind:<type> ; types (boe, bop, bou, boq) i.e boe = bind on equip
	<quality search>		:=	q ; quality | q<op><text> ; q<op><digit> (q:rare ; q:>2 ; q:>=3)
	<ilvl search>			:=	l ; level ; lvl ; ilvl | ilvl<op><number> ; lvl<op><number> (lvl:>5 ; lvl:>=20)
	<required ilvl search>	:=	r ; req ; rl ; reql ; reqlvl | req<op><number> ; req<op><number> (req:>5 ; req:>=20)
	<type / slot search>	:=	t ; type ; slot | t:<text> ; t:battlepet or t:petcage ; t:head ; t:shoulder; t:armor; t:weapon
	<tooltip search>		:=	tt ; tip; tooltip | tt:<text>
	<text search>			:=	<text>
	<item set search>		:=	s ; set | s:<setname> (setname can be * for all sets)
	<expansion search>		:=	x ; xpac ; expansion | x:<expacID> ; x:<expansion name> ; xpac:<expansion name> ; expansion:<expansion name>
	<keyword search>		:=	k ; key ; keyword | k:<keyword> ; (keywords: soulbound, bound, boe, bop, bou, boa, quest, unique, toy, reagent, crafting, naval, follower, follow, power, apperance)
	<class search>			:=	c ; class | c:<classname> ; class:<classname>
	<op>					:=  : | = | == | != | ~= | < | > | <= | >=
--]]

local Lib = LibStub:NewLibrary('LibItemScout-1.0', 2)
if not Lib then
	return
else
	Lib.searchTypes = Lib.searchTypes or {}
end

--[[ Locals ]]--

local tonumber, select, split, trim = tonumber, select, strsplit, strtrim
local strfind, strlower, strsub, strlen = string.find, string.lower, string.sub, string.len
local tinsert = table.insert
local cache = {}
local EMPTY_CACHE = {}

local xGetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local xGetItemNameByID = (C_Item and C_Item.GetItemNameByID) or function(item)
	return xGetItemInfo and select(1, xGetItemInfo(item))
end

Lib._compiledCache = Lib._compiledCache or setmetatable({}, { __mode = "kv" })
Lib._tagPrefixCache = Lib._tagPrefixCache or setmetatable({}, { __mode = "kv" })
Lib._indexDirty = true
Lib._freeSearchTypes = Lib._freeSearchTypes or {}
Lib._tagAliases = Lib._tagAliases or {}

local function useful(a) -- check if the search has a decent size
	return a and #a >= 1
end

local function dotrim(a)
	if a then return trim(a) end
	return a
end

local function compare(op, a, b)
	if op == '<=' then return a <= b end
	if op == '<' then return a < b end
	if op == '>' then return a > b end
	if op == '>=' then return a >= b end
	if op == '!=' or op == '~=' then return a ~= b end
	-- : = == (and nil) are treated as equality
	return a == b
end

local function match(search, ...)
	for i = 1, select('#', ...) do
		local text = select(i, ...)
		--use plain text search and turn off pattern searching
		--https://www.lua.org/manual/5.1/manual.html#5.4
		if text and text:lower():find(search, 1, true) then
			return true
		end
	end
	return false
end


--[[ User API ]]--
--cache object must use same variable names as --https://wowpedia.fandom.com/wiki/API_C_Item.GetItemInfo
--Table Example: {itemName=<name>, itemLink=<link>, itemQuality=<quality>}
--For battlepets/petcages make sure to include speciesID=<speciesID> as part of the cache object
--Note: C_Item.GetItemInfo does not like BattlePet id's, so do not pass that as a link.  Just use the battlepet name instead of a link.)
function Lib:Find(itemLink, search, cacheObj)
	if not useful(search) then
		return true
	end

	if not itemLink then
		return false
	end

	cache = cacheObj or EMPTY_CACHE

	-- allow callers to pass a precompiled search object
	if type(search) == "table" and search.__libItemScoutCompiled then
		return self:_EvalCompiledSearch(itemLink, search)
	end

	if type(search) ~= "string" then
		return true
	end

	local normalized = trim(strlower(search))
	if not useful(normalized) then
		return true
	end

	local compiled = self._compiledCache[normalized]
	if not compiled then
		compiled = self:Compile(normalized)
		self._compiledCache[normalized] = compiled
	end

	return self:_EvalCompiledSearch(itemLink, compiled)
end

-- Optional: compile a search string once and reuse it across many items for better performance.
function Lib:CompileSearch(search)
	return self:Compile(search)
end

function Lib:IsCompiledSearch(obj)
	return type(obj) == "table" and obj.__libItemScoutCompiled == true
end

-- Clears the internal compiled-search caches (does not affect tooltip caching).
function Lib:ClearSearchCache()
	self._compiledCache = setmetatable({}, { __mode = "kv" })
	self._tagPrefixCache = setmetatable({}, { __mode = "kv" })
end


--[[ Top-Layer Processing ]]--

-- union search: <search>&&<search>
function Lib:FindUnionSearch(item, ...)
	for i = 1, select('#', ...) do
		local search = select(i, ...)
		search = dotrim(search)
		--\038 ascii code for &
		if useful(search) and self:FindIntersectSearch(item, split('\038\038', search)) then
			return true
		end
	end
end


-- intersect search: <search>||<search>
function Lib:FindIntersectSearch(item, ...)
	for i = 1, select('#', ...) do
		local search = select(i, ...)
		search = dotrim(search)
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
		negatedSearch = dotrim(negatedSearch)
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
	self._indexDirty = true
	-- a new search type changes parsing/evaluation; drop caches to avoid stale compiled queries
	self._compiledCache = setmetatable({}, { __mode = "kv" })
	self._tagPrefixCache = setmetatable({}, { __mode = "kv" })
end

function Lib:GetTypedSearches()
	return pairs(self.searchTypes)
end

function Lib:GetTypedSearch(id)
	return self.searchTypes[id]
end

local function parseOperator(text)
	if not useful(text) then
		return nil, text
	end

	text = dotrim(text)
	if not useful(text) then
		return nil, text
	end

	local op2 = strsub(text, 1, 2)
	if op2 == "<=" or op2 == ">=" or op2 == "==" or op2 == "~=" or op2 == "!=" then
		return op2, dotrim(strsub(text, 3))
	end

	local op1 = strsub(text, 1, 1)
	if op1 == "<" or op1 == ">" or op1 == "=" or op1 == ":" then
		return op1, dotrim(strsub(text, 2))
	end

	return nil, text
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

	local operator
	operator, search = parseOperator(search)
	if not useful(search) then
		return default
	end

	if tag then
		tag = '^' .. tag
		for _, searchType in pairs(self.searchTypes) do
			if searchType.tags then
				for _, value in pairs(searchType.tags) do
					if value:find(tag) then
						return self:UseTypedSearch(searchType, item, operator, search)
					end
				end
			end
		end
	else
		--onlyTag forces general searches to require the tags instead of doing a free for all search through all the filters
		--so long as onlyTags is true, then the tag MUST exist in the search string
		for _, searchType in pairs(self.searchTypes) do
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

function Lib:_RebuildIndex()
	if not self._indexDirty then
		return
	end

	local free = {}
	local aliases = {}

	for _, searchType in pairs(self.searchTypes) do
		if not searchType.onlyTags then
			free[#free + 1] = searchType
		end
		if searchType.tags then
			for _, tag in pairs(searchType.tags) do
				aliases[#aliases + 1] = { tag = strlower(tag), searchType = searchType }
			end
		end
	end

	self._freeSearchTypes = free
	self._tagAliases = aliases
	self._tagPrefixCache = setmetatable({}, { __mode = "kv" })
	self._indexDirty = false
end

function Lib:_GetSearchTypesForTagPrefix(prefix)
	self:_RebuildIndex()

	prefix = strlower(prefix or "")
	if not useful(prefix) then
		return nil
	end

	local cached = self._tagPrefixCache[prefix]
	if cached then
		return cached
	end

	local out, seen = {}, {}
	local prefixLen = strlen(prefix)

	for _, entry in ipairs(self._tagAliases) do
		if strsub(entry.tag, 1, prefixLen) == prefix then
			local st = entry.searchType
			if not seen[st] then
				seen[st] = true
				out[#out + 1] = st
			end
		end
	end

	self._tagPrefixCache[prefix] = out
	return out
end

local function splitPlain(delim, text)
	local out = {}
	local start = 1
	while true do
		local pos = strfind(text, delim, start, true)
		if not pos then
			out[#out + 1] = dotrim(strsub(text, start))
			break
		end
		out[#out + 1] = dotrim(strsub(text, start, pos - 1))
		start = pos + #delim
	end
	return out
end

local function evalTerm(itemLink, term)
	local primitive = term.defaultPrimitive
	for i = 1, #term.entries do
		local e = term.entries[i]
		if e.searchType:findItem(itemLink, e.operator, e.c1, e.c2, e.c3) then
			primitive = true
			break
		end
	end

	if term.negated then
		return not primitive
	end
	return primitive
end

function Lib:_CompileTerm(text)
	text = dotrim(text)
	if not useful(text) then
		return nil
	end

	local negated, raw = false, text
	local negatedSearch = raw:match('^[!~][%s]*(.+)$')
	if negatedSearch then
		negated = true
		raw = dotrim(negatedSearch)
	end

	local tag, rest = raw:match('^[%s]*(%w+):(.*)$')
	if tag then
		if useful(rest) then
			raw = rest
		else
			-- preserve legacy behavior: invalid tagged search is ignored (true), unless negated (!tag:) which becomes false
			return {
				negated = negated,
				defaultPrimitive = (not negated),
				entries = {},
			}
		end
	end

	local operator
	operator, raw = parseOperator(raw)
	if not useful(raw) then
		return {
			negated = negated,
			defaultPrimitive = (tag and not negated) and true or false,
			entries = {},
		}
	end

	local candidates
	if tag then
		candidates = self:_GetSearchTypesForTagPrefix(tag) or {}
	else
		self:_RebuildIndex()
		candidates = self._freeSearchTypes
	end

	local entries = {}
	for i = 1, #candidates do
		local st = candidates[i]
		local c1, c2, c3 = st:canSearch(operator, raw)
		if c1 ~= nil then
			entries[#entries + 1] = { searchType = st, operator = operator, c1 = c1, c2 = c2, c3 = c3 }
		end
	end

	return {
		negated = negated,
		-- legacy: tagged terms default to true unless negated
		defaultPrimitive = (tag and not negated) and true or false,
		entries = entries,
	}
end

function Lib:Compile(search)
	self:_RebuildIndex()

	local normalized = dotrim(strlower(search or ""))
	if not useful(normalized) then
		return { __libItemScoutCompiled = true, groups = {} }
	end

	local groups = {}
	local orParts = splitPlain("||", normalized)
	for _, orPart in ipairs(orParts) do
		orPart = dotrim(orPart)
		if useful(orPart) then
			local terms = {}
			local andParts = splitPlain("&&", orPart)
			for _, andPart in ipairs(andParts) do
				andPart = dotrim(andPart)
				if useful(andPart) then
					local term = self:_CompileTerm(andPart)
					if term then
						terms[#terms + 1] = term
					end
				end
			end
			if #terms > 0 then
				groups[#groups + 1] = terms
			end
		end
	end

	return { __libItemScoutCompiled = true, groups = groups }
end

function Lib:_EvalCompiledSearch(itemLink, compiled)
	if not compiled or not compiled.groups or #compiled.groups == 0 then
		return true
	end

	for _, andTerms in ipairs(compiled.groups) do
		local ok = true
		for i = 1, #andTerms do
			if not evalTerm(itemLink, andTerms[i]) then
				ok = false
				break
			end
		end
		if ok then
			return true
		end
	end

	-- preserve legacy behavior: a non-match returns nil (which is falsy)
	return nil
end

--[[ Item name ]]--

Lib:RegisterTypedSearch{
	id = 'itemName',
	tags = {'n', 'name'},

	canSearch = function(self, operator, search)
		return not operator and search
	end,

	findItem = function(self, item, _, search)
		local name = cache.itemName or xGetItemNameByID(item) or item:match('%[(.+)%]') or (item and tostring(item))
		return match(search, name)
	end
}

Lib:RegisterTypedSearch{
	id = 'itemBind',
	tags = {'bind'},
	onlyTags = true,

	canSearch = function(self, operator, search)
		return not operator and self.keywords[search]
	end,

	findItem = function(self, item, _, search)
		return search == (cache.bindType or (xGetItemInfo and select(14, xGetItemInfo(item))))
	end,

	keywords = {
		['boe'] = LE_ITEM_BIND_ON_EQUIP,
		['bop'] = LE_ITEM_BIND_ON_ACQUIRE,
		['bou'] = LE_ITEM_BIND_ON_USE,
		['boq'] = LE_ITEM_BIND_QUEST,
	}
}

--[[ Expansion Type ]]--
Lib:RegisterTypedSearch{
	id = 'xpacType',
	tags = {'x', 'xpac', 'expansion'},
	onlyTags = true,

	canSearch = function(self, operator, search)
		return not operator and search
	end,

	findItem = function(self, item, _, search)
		local expacID = (cache.expacID or (xGetItemInfo and select(15, xGetItemInfo(item))))
		local xPacName = expacID and _G["EXPANSION_NAME"..expacID]
		return match(search, expacID and tostring(expacID), xPacName)
	end
}

--[[ Item type, subtype and equiploc ]]--

Lib:RegisterTypedSearch{
	id = 'itemType',
	tags = {'t', 'type', 'slot'},
	onlyTags = true,

	canSearch = function(self, operator, search)
		return not operator and search
	end,

	findItem = function(self, item, _, search)
		local type, subType, equipSlot, classID, subclassID

		if cache.itemType then
			type, subType, equipSlot, classID, subclassID = cache.itemType, cache.itemSubType, cache.itemEquipLoc, cache.classID, cache.subclassID
		elseif xGetItemInfo then
			type, subType, _, equipSlot, _, _, classID, subclassID = select(6, xGetItemInfo(item))
		end
		--check for battlepets, petcages, companions and such
		if (search == "battlepet" or search == "petcage") then
			--subclassID 2 = Companion Pets, requires ClassID 15 of Miscellaneous
			if (classID and classID == Enum.ItemClass.Miscellaneous) and (subclassID and subclassID == Enum.ItemMiscellaneousSubclass.CompanionPet) then
				return true
			end
			if (cache.speciesID) then
				return true
			end
			return false
		end
		return match(search, type, subType, _G[equipSlot])
	end
}


--[[ Item quality ]]--

local qualities = {}
local qualityCount = (Enum and Enum.ItemQualityMeta and Enum.ItemQualityMeta.NumValues) or (ITEM_QUALITY_COLORS and #ITEM_QUALITY_COLORS) or 0
for i = 0, qualityCount - 1 do
	local desc = _G['ITEM_QUALITY' .. i .. '_DESC']
	if desc then
		qualities[i] = strlower(desc)
	end
end

Lib:RegisterTypedSearch{
	id = 'itemQuality',
	tags = {'q', 'quality'},
	onlyTags = true,

	canSearch = function(self, _, search)
		for i, name in pairs(qualities) do
			if name:find(search) then
				return i
			end
		end
	end,

	findItem = function(self, link, operator, num)
		local quality = (cache.itemQuality or (xGetItemInfo and select(3, xGetItemInfo(link))))
		return compare(operator, quality, num)
	end,
}


--[[ Item level ]]--

Lib:RegisterTypedSearch{
	id = 'itemLevel',
	tags = {'l', 'level', 'lvl', 'ilvl'},
	onlyTags = true,

	canSearch = function(self, _, search)
		return tonumber(search)
	end,

	findItem = function(self, link, operator, num)
		local lvl = (cache.itemLevel or (xGetItemInfo and select(4, xGetItemInfo(link))))
		if lvl then
			return compare(operator, lvl, num)
		end
	end,
}

--[[ Required Item level ]]--

Lib:RegisterTypedSearch{
	id = 'reqItemLevel',
	tags = {'r', 'req', 'rl', 'reql', 'reqlvl'},
	onlyTags = true,

	canSearch = function(self, _, search)
		return tonumber(search)
	end,

	findItem = function(self, link, operator, num)
		local lvl = (cache.itemMinLevel or (xGetItemInfo and select(5, xGetItemInfo(link))))
		if lvl then
			return compare(operator, lvl, num)
		end
	end,
}

--[[ Tooltip searches ]]--

local tooltipCache = setmetatable({}, {__index = function(t, k) local v = {} t[k] = v return v end})

if not C_TooltipInfo then
	local tip = _G['LibItemScoutTooltipScanner'] or CreateFrame('GameTooltip', 'LibItemScoutTooltipScanner', UIParent, 'GameTooltipTemplate')
	tip:SetOwner(UIParent, 'ANCHOR_NONE')
	tip.GetHyperlink = function(itemLink)
		tip:SetHyperlink(itemLink)

		local data = {lines={}}
		for i = 1, tip:NumLines() do
		  data.lines[i] = {args = {nil, {stringVal = _G['LibItemScoutTooltipScannerTextLeft' .. i]:GetText()}}}
		end
		return data
	end
	Lib.Tooltip = tip
else
	Lib.Tooltip = C_TooltipInfo
end

local function stripColor(text)
	if not text or type(text) ~= "string" then return nil end
	-- remove color codes; keep other formatting intact
	return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local function link_FindSearchInTooltip(itemLink, search)
	local itemID = itemLink:match('item:(%d+)')
	if not itemID then
		return
	end

	local cachedResult = tooltipCache[search][itemID]
	if cachedResult ~= nil then
		return cachedResult
	end

	local result = false
	local data = Lib.Tooltip.GetHyperlink(itemLink)
	if data then
		for i, line in ipairs(data.lines) do
			local text = line.args[2].stringVal
			if text then
				text = stripColor(text)
				if text == search then
					result = true
					break
				end
			end
		end
	end

	tooltipCache[search][itemID] = result
	return result
end

--GetItemClassInfo was depreciated in TWW
local xGetItemClassInfo = (C_Item and C_Item.GetItemClassInfo) or GetItemClassInfo

Lib:RegisterTypedSearch{
	id = 'keyWord',
	tags = {'k', 'key', 'keyword'},
	onlyTags = true,

	canSearch = function(self, _, search)
		return self.keywords[search]
	end,

	findItem = function(self, itemLink, _, search)
		return search and link_FindSearchInTooltip(itemLink, search)
	end,

	keywords = {
		[ITEM_SOULBOUND:lower()] = ITEM_BIND_ON_PICKUP,
		['soulbound'] = ITEM_BIND_ON_PICKUP,
		['bound'] = ITEM_BIND_ON_PICKUP,
		['boe'] = ITEM_BIND_ON_EQUIP,
		['bop'] = ITEM_BIND_ON_PICKUP,
		['bou'] = ITEM_BIND_ON_USE,
		['boa'] = ITEM_BIND_TO_BNETACCOUNT,
		['quest'] = ITEM_BIND_QUEST,
		[xGetItemClassInfo(Enum.ItemClass.Questitem):lower()] = ITEM_BIND_QUEST,
		[QUESTS_LABEL:lower()] = ITEM_BIND_QUEST,
		['unique'] = ITEM_UNIQUE,
		[TOY:lower()] = TOY,
		[MINIMAP_TRACKING_VENDOR_REAGENT:lower()] = PROFESSIONS_USED_IN_COOKING,
		[PROFESSIONS_USED_IN_COOKING:lower()] = PROFESSIONS_USED_IN_COOKING,
		[APPEARANCE_LABEL:lower()] = TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN,
		['appearance'] = TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN,
		['apperance'] = TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN, -- legacy typo kept for backwards compatibility
		['reagent'] = PROFESSIONS_USED_IN_COOKING,
		['crafting'] = PROFESSIONS_USED_IN_COOKING,
		['naval'] = 'naval equipment',
		['follower'] = 'follower',
		['follow'] = 'follower',
		["power"] = ARTIFACT_POWER,
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
		local data = Lib.Tooltip.GetHyperlink(link)
        if data then
            for i, line in ipairs(data.lines) do
				local text = line.args[2].stringVal
				if text then
					text = stripColor(text)
					if text and strlower(text):find(search, 1, true) then
					return true
					end
				end
            end
        end
		return false
	end,
}

Lib:RegisterTypedSearch{
	id = 'classRestriction',
	tags = {'c', 'class'},
	onlyTags = true,

	canSearch = function(self, _, search)
		return search
	end,

	findItem = function(self, link, _, search)
		if link:find("battlepet") then return false end

		local itemID = link:match('item:(%d+)')
		if not itemID then
			return
		end

		local cachedResult = tooltipCache[search][itemID]
		if cachedResult ~= nil then
			return cachedResult
		end

		local result = false
		local pattern = string.gsub(ITEM_CLASSES_ALLOWED:lower(), "%%s", "(.+)")

		local data = Lib.Tooltip.GetHyperlink(link)
        if data then
            for i, line in ipairs(data.lines) do
				local text = line.args[2].stringVal
				if text then
					text = text:lower()
					local textChk = string.find(text, pattern)
					if textChk and text:find(search) then
						result = true
						break
					end
				end
            end
        end

		tooltipCache[search][itemID] = result
		return result
	end,
}

--[[ Equipment sets ]]--

--Placeholder variables; will be replaced with references to the addon-appropriate handlers at runtime
local ES_FindSets, ES_CheckItem

--Helper: Global Pattern Matching Function (matches ANY set name if search is *, or the EXACT set name if exactMatch is true, or any set name STARTING with the provided search terms if exactMatch is false (this means it will not match in middle of strings). all equipment set searches below use this function to FIRST try to find a set with the EXACT name entered, and if that fails they'll look for all sets that START with the search term, using recursive calls.
local function ES_TrySetName(setName, search, exactMatch)
	return (search == '*') or (exactMatch and setName:lower() == search) or (not exactMatch and setName:lower():sub(1,strlen(search)) == search)
end

function ES_FindSets(setList, search, exactMatch)
	for i, setID in pairs(C_EquipmentSet.GetEquipmentSetIDs()) do
		local setName = C_EquipmentSet.GetEquipmentSetInfo(setID)
		if setName and ES_TrySetName(setName, search, exactMatch) then
			table.insert(setList, setID)
		end
	end

	if (search ~= '*') and exactMatch and #setList == 0 then --if we just finished an exact, non-global (not "*"), name match search and still have no results, try one more time with partial ("starts with") set name matching instead
		ES_FindSets(setList, search, false)
	end
end

function ES_CheckItem(itemLink, setList)
	local itemID = tonumber(string.match(itemLink or '','item:(%-?%d+)') or 0) --grab the baseID of the item we are searching for (we don't need the full itemString, since we'll only be doing a loose baseID comparison below)

	for _, setID in pairs(setList) do
		local bzSetItemIDs = C_EquipmentSet.GetItemIDs(setID)
		for _, bzItemID in pairs(bzSetItemIDs) do --note: do not change this to ipairs() or it will abort scanning at empty slots in a set
			if itemID == bzItemID then --loose match: compare the current item's baseID to the baseID of the set item
				return true
			end
		end
	end

	return false
end

Lib:RegisterTypedSearch{
	id = 'equipmentSet',
	tags = {'s', 'set'},
	onlyTags = true,

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
