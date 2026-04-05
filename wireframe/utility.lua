--[[
	utility.lua
		Utility helpers for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...) --grab the addon namespace
local Utility = BSYC:NewModule("Utility")

-----------------------------------------------------------------
-- Secret value helpers (Retail 12.0+). These APIs may not exist on older clients.
------------------------------------------------------------------

-- Cache secret API functions at load time (Retail 12.0+ may add/remove these)
-- Using table lookup is faster than repeated _G access and type() checks
local secretAPIs = {
	issecretvalue = _G.issecretvalue,
	canaccessvalue = _G.canaccessvalue,
	issecrettable = _G.issecrettable,
	hasanysecretvalue = _G.hasanysecretvalue,
	canaccessallvalues = _G.canaccessallvalues,
}

-- Unified helper for calling secret APIs safely (replaced 30+ lines of duplicated code)
-- All 5 secret API functions followed the exact same pattern: get function, check type, pcall, boolean convert
local function CallSecretAPI(apiName, ...)
	local fn = secretAPIs[apiName]
	if type(fn) ~= "function" then
		return nil -- API doesn't exist on this client version
	end
	local ok, result = pcall(fn, ...)
	if ok then return not not result end -- Ensure boolean return
	return nil
end

function Utility:IsSecretValue(v)
	return CallSecretAPI("issecretvalue", v) or false
end

function Utility:CanAccessValue(v)
	return CallSecretAPI("canaccessvalue", v) or true -- Default to true for older clients
end

function Utility:IsSecretTable(v)
	return CallSecretAPI("issecrettable", v) or false
end

function Utility:HasAnySecretValue(v)
	return CallSecretAPI("hasanysecretvalue", v) or false
end

function Utility:CanAccessAllValues(v)
	return CallSecretAPI("canaccessallvalues", v) or true -- Default to true for older clients
end

-- Safe type checker that handles secret values on Retail 12.0+
-- Calling type() on a secret value will throw an error, so we use pcall
-- Removed redundant _G.type reference - type() is always available
local function SafeType(v)
	local ok, result = pcall(type, v)
	if ok then return result end
	-- If type() failed, it's likely a secret value
	return nil
end

-- Shared helper for number validation (eliminates duplication between IsSafeNumber and IsSecretNumber)
-- Returns: isNumber (bool), isSecret (bool), canAccess (bool)
local function CheckNumberAccess(self, v)
	local t = SafeType(v)
	if t ~= "number" then
		return false, false, false
	end
	return true, self:IsSecretValue(v), self:CanAccessValue(v)
end

function Utility:IsSafeNumber(v)
	local isNumber, isSecret, canAccess = CheckNumberAccess(self, v)
	return isNumber and not isSecret and canAccess
end

function Utility:IsSafeTable(v)
	local t = SafeType(v)
	if t ~= "table" then return false end
	if self:IsSecretTable(v) then return false end
	if self:HasAnySecretValue(v) then return false end
	if not self:CanAccessAllValues(v) then return false end
	return true
end

function Utility:IsSecretNumber(v)
	local isNumber, isSecret, canAccess = CheckNumberAccess(self, v)
	return isNumber and (isSecret or not canAccess)
end

function Utility:GetFrameLabel(frame)
	if not frame then return "<nil>" end
	-- Removed redundant checks - if GetName/GetObjectType don't exist, we'll get nil which is handled
	local name = frame.GetName and frame:GetName()
	local objType = frame.GetObjectType and frame:GetObjectType()

	if name and objType then return name .. " (" .. objType .. ")" end
	if name then return name end
	if objType then return "<unnamed " .. objType .. ">" end
	return tostring(frame)
end

function Utility:IsBlizzardFrameName(name)
	if not name then return false end
	if name:find("^Blizzard") then return true end
	if name:find("^GameTooltip") or name:find("^ShoppingTooltip") or name:find("^ItemRef") then
		return true
	end
	return name == "UIParent" -- Removed explicit return false for consistency
end

-- Cache of loaded addon names - stored on module instance to allow invalidation if needed
-- Note: Currently never invalidated; if addons load/unload dynamically, cache may become stale
function Utility:GetLoadedAddonNames()
	if self.__addonNameCache then return self.__addonNameCache end

	-- Feature detection for classic vs retail addon APIs
	local getNum = C_AddOns and C_AddOns.GetNumAddOns or GetNumAddOns
	local getInfo = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo
	local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded

	if type(getNum) ~= "function" or type(getInfo) ~= "function" or type(isLoaded) ~= "function" then
		return nil
	end

	local out = {}
	for i = 1, getNum() do
		local name = getInfo(i)
		if name and isLoaded(name) then
			out[#out + 1] = name
		end
	end
	self.__addonNameCache = out
	return out
end

function Utility:GuessAddonFromFrameName(name)
	if not name then return nil end
	local list = self:GetLoadedAddonNames()
	if not list then return nil end

	-- Iterate through loaded addons to find a prefix match
	for i = 1, #list do
		local addon = list[i]
		if name:sub(1, #addon) == addon then
			return addon
		end
	end
	return nil
end

function Utility:GetFrameSource(frame)
	if not frame then return "Unknown" end
	local name = frame.GetName and frame:GetName()
	if name and self:IsBlizzardFrameName(name) then return "Blizzard" end
	if name and name:find("^BagSync") then return "BagSync" end
	local addon = self:GuessAddonFromFrameName(name)
	if addon then return "Addon: " .. addon end
	return "Addon: Unknown"
end

function Utility:WarnSecretValue(moduleName, owner, frame, context, valueName, funcName)
	if not BSYC or not BSYC.Print then return end
	if not (BSYC.options and BSYC.options.debug and BSYC.options.debug.enable) then
		return
	end

	local warned = self.__secretWarned or {}
	self.__secretWarned = warned

	local ownerLabel = self:GetFrameLabel(owner)
	local frameLabel = self:GetFrameLabel(frame)

	-- Use table.concat instead of repeated string concatenation (more efficient for multiple parts)
	local key = table.concat({
		ownerLabel,
		frameLabel,
		tostring(context or ""),
		tostring(valueName or ""),
		tostring(moduleName or ""),
		tostring(funcName or "")
	}, "|")

	if warned[key] then return end
	warned[key] = true

	local msg = ("A secret value warning: module=%s, func=%s, context=%s, tooltipOwner=%s, frame=%s, source=%s")
		:format(tostring(moduleName or "Unknown"), tostring(funcName or "unknown"), tostring(context or "unknown"), ownerLabel, frameLabel, self:GetFrameSource(frame))

	if valueName then
		msg = msg .. ", value=" .. tostring(valueName)
	end
	BSYC:Print(msg)
end

-- Helper to check if a frame contains secret values (consolidates duplicate secret checks)
local function CheckFrameSecrets(self, moduleName, frame, owner, context, funcName)
	if self:IsSecretTable(frame) then
		self:WarnSecretValue(moduleName, owner or frame, frame, context, "frame", funcName)
		return true
	end
	if self:HasAnySecretValue(frame) then
		self:WarnSecretValue(moduleName, owner or frame, frame, context, "frame", funcName)
		return true
	end
	if not self:CanAccessAllValues(frame) then
		self:WarnSecretValue(moduleName, owner or frame, frame, context, "frame", funcName)
		return true
	end
	return false
end

function Utility:IsSecretFrame(moduleName, frame, owner, context, funcName)
	if not frame then return false end
	return CheckFrameSecrets(self, moduleName, frame, owner, context, funcName)
end

function Utility:GetSafeCoord(moduleName, frame, coord, owner, context, funcName)
	if not frame then return nil end
	local getter = frame["Get" .. coord]
	if type(getter) ~= "function" then return nil end
	local v = getter(frame)
	if self:IsSafeNumber(v) then return v end
	if self:IsSecretNumber(v) then
		self:WarnSecretValue(moduleName, owner or frame, frame, context, coord, funcName)
	end
	return nil
end

function Utility:GetSafeCenter(moduleName, frame, owner, context, funcName)
	if not frame or not frame.GetCenter then return nil, nil end
	local x, y = frame:GetCenter()

	-- Check X coordinate
	if self:IsSafeNumber(x) then
		-- Check Y coordinate
		if self:IsSafeNumber(y) then
			return x, y
		end
		self:WarnSecretValue(moduleName, owner or frame, frame, context, "CenterY", funcName)
	else
		self:WarnSecretValue(moduleName, owner or frame, frame, context, "CenterX", funcName)
		-- Only check Y if X was bad (avoid double warning)
		if self:IsSecretNumber(y) then
			self:WarnSecretValue(moduleName, owner or frame, frame, context, "CenterY", funcName)
		end
	end

	return nil, nil
end
