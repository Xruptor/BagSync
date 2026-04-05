--[[
	ext_tip.lua
		External tooltip (ExtTip) handling for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.

--]]

local BSYC = select(2, ...)
local ExtTip = BSYC:NewModule("ExtTip")
local Utility = BSYC:GetModule("Utility")
local L = BSYC.L

local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent

-- Cached API references
local IsAddOnLoaded = BSYC.API and BSYC.API.IsAddOnLoaded

local function Debug(level, ...)
	if BSYC.DEBUG then BSYC.DEBUG(level, "ExtTip", ...) end
end

local function CanAccessObject(obj)
	return issecure() or not obj:IsForbidden()
end

-- DEAD CODE REMOVED: Manual wipe fallback (lines 25-28 in original)
-- wipe is always available in WoW Lua environment; the else branch was unreachable

function ExtTip:EnsureTip()
	-- Use rawget to avoid triggering metatable
	local current = rawget(self, "extTip")
	if current then return current end

	local extTip = CreateFrame("GameTooltip", "BagSyncExtTip", UIParent, "GameTooltipTemplate")
	extTip:SetOwner(UIParent, "ANCHOR_NONE")
	extTip:SetClampedToScreen(true)
	extTip:SetFrameStrata("TOOLTIP")
	extTip:SetToplevel(true)
	-- Use rawset to bypass metatable when setting the frame
	rawset(self, "extTip", extTip)
	return extTip
end

function ExtTip:GetTip()
	return self:EnsureTip()
end

function ExtTip:Hide()
	-- Use rawget to safely access extTip without triggering metatable
	local extTip = rawget(self, "extTip")
	if extTip and type(extTip) == "table" and extTip.Hide then
		extTip:Hide()
	end
end

function ExtTip:ResetAnchorCache()
	self.__extTipAnchorOwner = nil
	self.__extTipAnchorSig = nil
	self.__extTipAnchorFrame = nil
	self.__extTipAnchorMode = nil
end

function ExtTip:OnTooltipHide()
	self:Hide()
	self.__currentOwner = nil
	self:ResetAnchorCache()
end

function ExtTip:ApplyFont()
	-- Use rawget to safely access extTip without triggering metatable
	local extTip = rawget(self, "extTip")
	if not extTip or not BSYC.__font then return end
	local fontPath, fontSize, fontFlags = BSYC.__font:GetFont()
	if not fontPath or not fontSize then return end

	local tip = extTip
	local name = tip:GetName()
	local numLines = tip:NumLines() or 0
	for i = 1, numLines do
		local left = _G[name .. "TextLeft" .. i]
		if left and left.SetFont then
			left:SetFont(fontPath, fontSize, fontFlags)
		end
		local right = _G[name .. "TextRight" .. i]
		if right and right.SetFont then
			right:SetFont(fontPath, fontSize, fontFlags)
		end
	end
end

-- NORMALIZATION HELPERS - Consolidated with lookup tables
local ANCHOR_MODE_LOOKUP = {
	LEFT = "LEFT", RIGHT = "RIGHT", BOTTOM = "BOTTOM",
}
local DEFAULT_ANCHOR_MODE = "BOTTOM"

local function NormalizeAnchorMode(mode)
	return ANCHOR_MODE_LOOKUP[tostring(mode or ""):upper()] or DEFAULT_ANCHOR_MODE
end

local LOCATION_LOOKUP = {
	TOPLEFT = "TOPLEFT", TOPRIGHT = "TOPRIGHT", BOTTOMLEFT = "BOTTOMLEFT",
	BOTTOMRIGHT = "BOTTOMRIGHT", CENTER = "CENTER", CENTER_TOP = "CENTER_TOP",
	CENTER_BOTTOM = "CENTER_BOTTOM", ANCHOR = "ANCHOR",
}
local DEFAULT_LOCATION = "CENTER"

local function NormalizeCustomLocation(mode)
	return LOCATION_LOOKUP[tostring(mode or ""):upper()] or DEFAULT_LOCATION
end

-- LOCATION LOOKUP TABLE for ApplyCustomPosition - O(1) instead of O(n) if-elseif chain
local LOCATION_POINT_MAP = {
	TOPLEFT = { point = "TOPLEFT", relPoint = "TOPLEFT", x = 16, y = -16 },
	TOPRIGHT = { point = "TOPRIGHT", relPoint = "TOPRIGHT", x = -16, y = -16 },
	BOTTOMLEFT = { point = "BOTTOMLEFT", relPoint = "BOTTOMLEFT", x = 16, y = 16 },
	BOTTOMRIGHT = { point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -16, y = 16 },
	CENTER = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 },
	CENTER_TOP = { point = "TOP", relPoint = "TOP", x = 0, y = -16 },
	CENTER_BOTTOM = { point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = 16 },
}

local function GetAnchorOffsets()
	local opts = BSYC.options or {}
	local x = opts.extTT_CustomAnchorX
	local y = opts.extTT_CustomAnchorY
	if not Utility:IsSafeNumber(x) then x = 0 end
	if not Utility:IsSafeNumber(y) then y = 0 end
	return x, y
end

local function ClampAnchorOffsets(frame, x, y)
	if not frame or not UIParent then return x, y end
	if not Utility:IsSafeNumber(x) or not Utility:IsSafeNumber(y) then return 0, 0 end

	local parentW = UIParent:GetWidth() or 0
	local parentH = UIParent:GetHeight() or 0
	local frameW = frame:GetWidth() or 0
	local frameH = frame:GetHeight() or 0

	if parentW <= 0 or parentH <= 0 or frameW <= 0 or frameH <= 0 then
		return x, y
	end

	local maxX = (parentW - frameW) / 2
	local maxY = (parentH - frameH) / 2
	if x > maxX then x = maxX end
	if x < -maxX then x = -maxX end
	if y > maxY then y = maxY end
	if y < -maxY then y = -maxY end

	return x, y
end

function ExtTip:SaveAnchorPosition(frame)
	if not frame then return end
	local cx, cy = frame:GetCenter()
	local ux, uy = UIParent:GetCenter()
	if not Utility:IsSafeNumber(cx) or not Utility:IsSafeNumber(cy) then return end
	if not Utility:IsSafeNumber(ux) or not Utility:IsSafeNumber(uy) then return end

	local x, y = ClampAnchorOffsets(frame, cx - ux, cy - uy)

	BSYC.options = BSYC.options or {}
	BSYC.options.extTT_CustomAnchorX = x
	BSYC.options.extTT_CustomAnchorY = y
end

function ExtTip:PositionAnchor(frame)
	if not frame then return end
	local x, y = GetAnchorOffsets()
	x, y = ClampAnchorOffsets(frame, x, y)
	frame:ClearAllPoints()
	frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

function ExtTip:EnsureAnchor()
	if self.anchorFrame then return self.anchorFrame end

	local frame = CreateFrame("Button", "BagSyncExtTipAnchor", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	frame:SetSize(220, 60)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	if frame.RegisterForClicks then
		frame:RegisterForClicks("AnyUp")
	end
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("DIALOG")

	local backdrop = {
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
	}
	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(0.9, 0.65, 0.1, 0.85)
	frame:SetBackdropBorderColor(0.9, 0.65, 0.1, 1)

	frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.text:SetJustifyH("CENTER")
	frame.text:SetJustifyV("MIDDLE")
	frame.text:SetWordWrap(true)
	frame.text:SetWidth(frame:GetWidth() - 8)
	frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0)
	frame.text:SetText(L.ExtTipAnchorLabel or "BagSync ExtTip Anchor\n\n(Right-Click to Save Position)")

	frame:SetScript("OnMouseDown", function(f, button)
		if button == "LeftButton" then
			f.isMoving = true
			f:StartMoving()
		else
			ExtTip:SaveAnchorPosition(f)
			f:Hide()
		end
	end)
	frame:SetScript("OnMouseUp", function(f)
		if f.isMoving then
			f.isMoving = nil
			f:StopMovingOrSizing()
			ExtTip:SaveAnchorPosition(f)
		end
	end)

	self.anchorFrame = frame
	self:PositionAnchor(frame)
	frame:Hide()
	return frame
end

function ExtTip:ShowAnchor()
	local frame = self:EnsureAnchor()
	self:PositionAnchor(frame)
	frame:Show()
end

-- HELPER FUNCTIONS - Must be defined before TooltipCandidateManager uses them
local function IsRelatedTooltipFrame(frame, owner)
	-- Use rawget to bypass metatable when accessing ExtTip.extTip
	local extTipFrame = rawget(ExtTip, "extTip")
	if not frame or not owner or frame == extTipFrame then return false end
	if not CanAccessObject(frame) then return false end
	if not frame:IsVisible() then return false end

	if frame == owner then return true end
	if frame.GetOwner and frame:GetOwner() == owner then return true end

	if not frame.GetNumPoints or not frame.GetPoint then return false end
	for i = 1, frame:GetNumPoints() do
		local _, relativeTo = frame:GetPoint(i)
		if relativeTo == owner then
			return true
		end
	end

	return false
end

-- DEAD CODE REMOVED: FrameAnchoredTo function (was defined but never called)
-- IsRelatedTooltipFrame performs its own anchor checking inline

-- OPTIMIZED: Replaced if-elseif chain with lookup table (O(n) → O(1))
function ExtTip:ApplyCustomPosition(extTip)
	local opts = BSYC.options
	if not opts or not opts.extTT_CustomAnchorEnabled then return false end
	if not extTip then return false end

	local location = NormalizeCustomLocation(opts.extTT_CustomAnchorLocation)
	local locInfo = LOCATION_POINT_MAP[location]

	if locInfo then
		extTip:ClearAllPoints()
		extTip:SetPoint(locInfo.point, UIParent, locInfo.relPoint, locInfo.x, locInfo.y)
		return true
	end

	-- Custom anchor position
	local anchor = self:EnsureAnchor()
	self:PositionAnchor(anchor)
	extTip:ClearAllPoints()
	extTip:SetPoint("CENTER", anchor, "CENTER", 0, 0)
	return true
end

local function IsOffscreen(frame)
	if not frame or not frame.GetLeft then return false end
	local left = Utility:GetSafeCoord("Tooltip", frame, "Left", frame, "offscreen", "IsOffscreen")
	local right = Utility:GetSafeCoord("Tooltip", frame, "Right", frame, "offscreen", "IsOffscreen")
	local top = Utility:GetSafeCoord("Tooltip", frame, "Top", frame, "offscreen", "IsOffscreen")
	local bottom = Utility:GetSafeCoord("Tooltip", frame, "Bottom", frame, "offscreen", "IsOffscreen")
	if not left or not right or not top or not bottom then
		return false
	end
	local width = UIParent:GetWidth() or 0
	local height = UIParent:GetHeight() or 0
	if width <= 0 or height <= 0 then return false end
	return (left < 0) or (right > width) or (bottom < 0) or (top > height)
end

-- TOOLTIP CANDIDATE MANAGER - Centralizes tooltip scanning logic
-- This eliminates massive duplication across GetBottomAnchor and GetBottomAnchorCached
local TooltipCandidateManager = {}
TooltipCandidateManager.__index = TooltipCandidateManager

function TooltipCandidateManager:new(owner, anchorMode, utility)
	return setmetatable({
		owner = owner,
		anchorMode = anchorMode,
		utility = utility,
		coord = (anchorMode == "LEFT" and "Left") or (anchorMode == "RIGHT" and "Right") or "Bottom",
		candidates = {},
	}, self)
end

function TooltipCandidateManager:HasRequiredMethod(frame)
	if not frame then return false end
	if self.anchorMode == "LEFT" then return frame.GetLeft ~= nil end
	if self.anchorMode == "RIGHT" then return frame.GetRight ~= nil end
	return frame.GetBottom ~= nil
end

function TooltipCandidateManager:IsValidFrame(frame, context)
	if not self:HasRequiredMethod(frame) then return false end
	if self.utility:IsSecretFrame("Tooltip", frame, self.owner, "anchor " .. context, "TooltipCandidateManager") then return false end
	if not IsRelatedTooltipFrame(frame, self.owner) then return false end
	return true
end

function TooltipCandidateManager:GetFramePosition(frame)
	if not self:IsValidFrame(frame, "position") then return nil end
	return self.utility:GetSafeCoord("Tooltip", frame, self.coord, self.owner, "anchor position", "TooltipCandidateManager")
end

function TooltipCandidateManager:AddFixedTooltip(tooltip, weight)
	if tooltip and tooltip.IsVisible and tooltip:IsVisible() then
		if self:IsValidFrame(tooltip, "fixed") then
			local pos = self:GetFramePosition(tooltip)
			if pos then
				table.insert(self.candidates, { frame = tooltip, pos = pos, weight = weight or 0 })
			end
		end
	end
end

function TooltipCandidateManager:AddTooltipTable(tooltips, startWeight)
	if not tooltips then return end
	local w = startWeight or 0
	for _, tip in pairs(tooltips) do
		w = w + 1
		self:AddFixedTooltip(tip, w)
	end
end

function TooltipCandidateManager:AddNumberedTooltip(pattern, maxNum, startWeight)
	for i = 1, maxNum or 20 do
		local t = _G[pattern .. i]
		if t and t.IsVisible and t:IsVisible() then
			self:AddFixedTooltip(t, (startWeight or 0) + i)
		elseif not t then
			break
		end
	end
end

function TooltipCandidateManager:AddLibraryTooltip(libName, getter, weight)
	if LibStub and LibStub.libs and LibStub.libs[libName] then
		local lib = LibStub(libName)
		if lib and getter then
			local t = getter(lib, self.owner)
			if t and t.IsVisible and t:IsVisible() then
				self:AddFixedTooltip(t, weight)
			end
		end
	end
end

function TooltipCandidateManager:AddGlobalTooltip(globalName, weight)
	local t = _G[globalName]
	if t and t.IsVisible and t:IsVisible() then
		self:AddFixedTooltip(t, weight)
	end
end

function TooltipCandidateManager:CollectAllCandidates()
	self:AddFixedTooltip(self.owner, 1)

	-- Blizzard comparison tooltips
	self:AddFixedTooltip(_G.ShoppingTooltip1, 2)
	self:AddFixedTooltip(_G.ShoppingTooltip2, 3)
	self:AddFixedTooltip(_G.ShoppingTooltip3, 4)
	self:AddFixedTooltip(_G.ItemRefShoppingTooltip1, 5)
	self:AddFixedTooltip(_G.ItemRefShoppingTooltip2, 6)
	self:AddFixedTooltip(_G.ItemRefShoppingTooltip3, 7)

	-- Retail: tooltip lists
	self:AddTooltipTable(self.owner.shoppingTooltips, 10)
	self:AddTooltipTable(self.owner.comparisonTooltips, 40)

	-- Addon: TradeSkillMaster
	if IsAddOnLoaded and IsAddOnLoaded("TradeSkillMaster") then
		self:AddNumberedTooltip("TSMExtraTip", 20, 100)
	end

	-- Library: LibExtraTip
	self:AddLibraryTooltip("LibExtraTip-1", function(lib, owner) return lib:GetExtraTip(owner) end, 200)

	-- Addon: BPBID
	if BPBID_BreedTooltip then self:AddGlobalTooltip("BPBID_BreedTooltip", 300) end
	if BPBID_BreedTooltip2 then self:AddGlobalTooltip("BPBID_BreedTooltip2", 301) end
end

function TooltipCandidateManager:SelectBestAnchor()
	local bestFrame, bestPos
	local isRightMode = (self.anchorMode == "RIGHT")

	for _, candidate in ipairs(self.candidates) do
		local frame, pos = candidate.frame, candidate.pos
		if isRightMode then
			if not bestPos or pos > bestPos then
				bestPos = pos
				bestFrame = frame
			end
		else
			if not bestPos or pos < bestPos then
				bestPos = pos
				bestFrame = frame
			end
		end
	end

	return bestFrame, bestPos
end

function TooltipCandidateManager:ComputeSignature()
	local sig = 5381

	local function sigAdd(n)
		sig = (sig * 33 + (n or 0)) % 2147483647
	end

	-- Owner position affects anchoring
	local cx, cy = Utility:GetSafeCenter("Tooltip", self.owner, self.owner, "anchor signature", "TooltipCandidateManager")
	sigAdd(math.floor((cx or 0) * 10 + 0.5))
	sigAdd(math.floor((cy or 0) * 10 + 0.5))
	sigAdd(self.anchorMode == "LEFT" and 11 or self.anchorMode == "RIGHT" and 17 or 23)

	-- Include all candidates in signature
	for _, candidate in ipairs(self.candidates) do
		local q = math.floor((candidate.pos or 0) * 10 + 0.5)
		sigAdd((q * 31) + candidate.weight)
	end

	return sig
end

function ExtTip:GetBottomAnchorCached(owner, anchorMode)
	if not owner then return nil end
	anchorMode = NormalizeAnchorMode(anchorMode)

	-- Collect candidates
	local manager = TooltipCandidateManager:new(owner, anchorMode, Utility)
	manager:CollectAllCandidates()

	-- Compute cache signature
	local sig = manager:ComputeSignature()

	-- Check cache
	local cachedOwner = self.__extTipAnchorOwner
	local cachedSig = self.__extTipAnchorSig
	local cachedAnchor = self.__extTipAnchorFrame
	local cachedMode = self.__extTipAnchorMode

	if cachedOwner == owner and cachedSig == sig and cachedMode == anchorMode
		and cachedAnchor and IsRelatedTooltipFrame(cachedAnchor, owner) then
		local coord = manager.coord
		local cachedPos = Utility:GetSafeCoord("Tooltip", cachedAnchor, coord, owner, "anchor cached", "GetBottomAnchorCached")
		if cachedPos then
			return cachedAnchor
		end
	end

	-- Cache miss: select best anchor
	local bestFrame = manager:SelectBestAnchor()

	if not bestFrame then
		self:ResetAnchorCache()
		return nil
	end

	self.__extTipAnchorOwner = owner
	self.__extTipAnchorSig = sig
	self.__extTipAnchorFrame = bestFrame
	self.__extTipAnchorMode = anchorMode

	return bestFrame
end

-- DUPLICATION REMOVED: GetBottomAnchor removed (180 lines)
-- GetBottomAnchorCached now handles all cases using TooltipCandidateManager
-- The separate GetBottomAnchor function was 95% duplicate and is now obsolete

-- EXTRACTED: place function from SetAnchor (avoids closure creation on every call)
local function PlaceTooltip(extTip, anchor, mode, ownerX, ownerY, vhalfOverride)
	mode = NormalizeAnchorMode(mode)
	local vhalf = vhalfOverride or ((ownerY > UIParent:GetHeight() / 4) and "TOP" or "BOTTOM")

	if mode == "LEFT" then
		extTip:SetPoint(vhalf .. "RIGHT", anchor, vhalf .. "LEFT")
		return vhalf
	elseif mode == "RIGHT" then
		extTip:SetPoint(vhalf .. "LEFT", anchor, vhalf .. "RIGHT")
		return vhalf
	else
		local hhalf = (ownerX > UIParent:GetWidth() * 2 / 3) and "LEFT"
			or (ownerX < UIParent:GetWidth() / 3) and "RIGHT" or ""
		extTip:SetPoint(vhalf .. hhalf, anchor, (vhalf == "TOP" and "BOTTOM" or "TOP") .. hhalf)
		return vhalf, hhalf
	end
end

function ExtTip:SetAnchor(owner, anchor, extTip, anchorMode)
	Debug(BSYC_DL.SL2, "SetExtTipAnchor", owner, anchor, extTip)

	anchor = anchor or owner
	anchorMode = NormalizeAnchorMode(anchorMode)
	local x, y = Utility:GetSafeCenter("Tooltip", owner, owner, "anchor place", "SetAnchor")
	if not x or not y then
		extTip:ClearAllPoints()
		if anchorMode == "LEFT" then
			extTip:SetPoint("TOPRIGHT", anchor, "TOPLEFT")
		elseif anchorMode == "RIGHT" then
			extTip:SetPoint("TOPLEFT", anchor, "TOPRIGHT")
		else
			extTip:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT")
		end
		return
	end

	extTip:ClearAllPoints()
	local usedVhalf, usedHhalf = PlaceTooltip(extTip, anchor, anchorMode, x, y)

	if IsOffscreen(extTip) then
		extTip:ClearAllPoints()
		if anchorMode == "LEFT" then
			PlaceTooltip(extTip, anchor, "RIGHT", x, y)
		elseif anchorMode == "RIGHT" then
			PlaceTooltip(extTip, anchor, "LEFT", x, y)
		else
			local flipVhalf = (usedVhalf == "TOP") and "BOTTOM" or "TOP"
			local hhalf = usedHhalf or ((x > UIParent:GetWidth() * 2 / 3) and "LEFT" or (x < UIParent:GetWidth() / 3) and "RIGHT" or "")
			extTip:SetPoint(flipVhalf .. hhalf, anchor, (flipVhalf == "TOP" and "BOTTOM" or "TOP") .. hhalf)
		end
	end
end

--MAIN Entry Positioning function for ExtTip.  This is the parent that calls our the other functions.
function ExtTip:Check(source, isBattlePet, owner)
	local opts = BSYC.options
	local shouldShow = (opts.enableExtTooltip or isBattlePet) and true or false

	local extTip = self:EnsureTip()

	if not shouldShow then
		self.__currentOwner = nil
		extTip:Hide()
		return false
	end

	extTip:ClearAllPoints()
	extTip:ClearLines()
	extTip:SetOwner(UIParent, "ANCHOR_NONE")

	self.__currentOwner = owner

	-- Custom positioning bypasses auto-anchoring and any tooltip scans.
	if owner and not (opts and opts.extTT_CustomAnchorEnabled) then
		-- If we cannot find a safe anchor (often due to Blizzard comparison tooltips
		-- returning secret values), fall back to inline tooltip output. Any overlap
		-- in that case is a Blizzard tooltip issue, not a BagSync one.
		-- Note: secret value diagnostics are logged via Utility:WarnSecretValue()
		-- but only when BagSync Debug is enabled.
		local anchor = self:GetBottomAnchorCached(owner, opts and opts.extTT_Anchor)
		if not anchor then
			-- For battle pets, always try to use the owner as anchor since they don't have comparison tooltips
			if not isBattlePet then
				self.__currentOwner = nil
				extTip:Hide()
				return false
			end
			-- For battle pets, set the owner as initial anchor so the extTip is positioned correctly
			-- UpdateAnchor will be called later to refine the position
			if owner and CanAccessObject(owner) then
				extTip:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2)
			end
		end
	end

	return true
end

function ExtTip:UpdateAnchor(owner, isBattlePet)
	-- Use rawget to safely access extTip without triggering metatable
	local extTip = rawget(self, "extTip")
	if not extTip then
		return false
	end

	-- Don't check IsShown() here - it may not be visible yet but we want to position it anyway
	-- The check was preventing battle pet tooltips from being positioned correctly

	-- Custom positioning bypasses auto-anchoring and any tooltip scans.
	if self:ApplyCustomPosition(extTip) then
		return true
	end

	local frame = owner or self.__currentOwner
	if not frame then
		return false
	end

	self.__currentOwner = frame
	extTip:ClearAllPoints()
	local anchorMode = NormalizeAnchorMode(BSYC.options and BSYC.options.extTT_Anchor)
	local anchor = self:GetBottomAnchorCached(frame, anchorMode)

	if not anchor then
		-- For battle pets, try to use the frame directly as anchor since they don't have comparison tooltips
		-- Check if the frame is accessible and has a valid position
		if isBattlePet and CanAccessObject(frame) then
			local cx, cy = Utility:GetSafeCenter("Tooltip", frame, frame, "anchor place", "UpdateAnchor:BattlePetFallback")
			if cx and cy then
				-- Use the frame itself as anchor for battle pets
				self:SetAnchor(frame, frame, extTip, anchorMode)
				return true
			end
			-- Keep the last known anchor from Check() if coords aren't safe yet.
			return true
		end
		extTip:Hide()
		return false
	end
	if anchor == extTip then anchor = frame end
	self:SetAnchor(frame, anchor, extTip, anchorMode)
	return true
end
