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
function Utility:IsSecretValue(v)
	local fn = _G.issecretvalue
	if type(fn) == "function" then
		local ok, res = pcall(fn, v)
		if ok then return not not res end
	end
	return false
end

function Utility:CanAccessValue(v)
	local fn = _G.canaccessvalue
	if type(fn) == "function" then
		local ok, res = pcall(fn, v)
		if ok then return not not res end
	end
	return true
end

function Utility:IsSecretTable(v)
	local fn = _G.issecrettable
	if type(fn) == "function" then
		local ok, res = pcall(fn, v)
		if ok then return not not res end
	end
	return false
end

function Utility:HasAnySecretValue(v)
	local fn = _G.hasanysecretvalue
	if type(fn) == "function" then
		local ok, res = pcall(fn, v)
		if ok then return not not res end
	end
	return false
end

function Utility:CanAccessAllValues(v)
	local fn = _G.canaccessallvalues
	if type(fn) == "function" then
		local ok, res = pcall(fn, v)
		if ok then return not not res end
	end
	return true
end

function Utility:IsSafeNumber(v)
	if type(v) ~= "number" then return false end
	if self:IsSecretValue(v) then return false end
	if not self:CanAccessValue(v) then return false end
	return true
end

function Utility:IsSafeTable(v)
	if type(v) ~= "table" then return false end
	if self:IsSecretTable(v) then return false end
	if self:HasAnySecretValue(v) then return false end
	if not self:CanAccessAllValues(v) then return false end
	return true
end

function Utility:IsSecretNumber(v)
	if type(v) ~= "number" then return false end
	if self:IsSecretValue(v) then return true end
	if not self:CanAccessValue(v) then return true end
	return false
end

function Utility:GetFrameLabel(frame)
	if not frame then return "<nil>" end
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
	if name == "UIParent" then return true end
	return false
end

function Utility:GetLoadedAddonNames()
	if self.__addonNameCache then return self.__addonNameCache end
	local getNum = (C_AddOns and C_AddOns.GetNumAddOns) or _G.GetNumAddOns
	local getInfo = (C_AddOns and C_AddOns.GetAddOnInfo) or _G.GetAddOnInfo
	local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded
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
	local key = ownerLabel .. "|" .. frameLabel .. "|" .. tostring(context or "") .. "|" .. tostring(valueName or "") .. "|" .. tostring(moduleName or "") .. "|" .. tostring(funcName or "")
	if warned[key] then return end
	warned[key] = true
	local msg = ("A secret value warning: module=%s, func=%s, context=%s, tooltipOwner=%s, frame=%s, source=%s")
		:format(tostring(moduleName or "Unknown"), tostring(funcName or "unknown"), tostring(context or "unknown"), ownerLabel, frameLabel, self:GetFrameSource(frame))
	if valueName then
		msg = msg .. ", value=" .. tostring(valueName)
	end
	BSYC:Print(msg)
end

function Utility:IsSecretFrame(moduleName, frame, owner, context, funcName)
	if not frame then return false end
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
	if self:IsSafeNumber(x) and self:IsSafeNumber(y) then
		return x, y
	end
	if self:IsSecretNumber(x) then
		self:WarnSecretValue(moduleName, owner or frame, frame, context, "CenterX", funcName)
	end
	if self:IsSecretNumber(y) then
		self:WarnSecretValue(moduleName, owner or frame, frame, context, "CenterY", funcName)
	end
	return nil, nil
end
