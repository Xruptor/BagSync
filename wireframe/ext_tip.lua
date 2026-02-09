--[[
	ext_tip.lua
		External tooltip (ExtTip) handling for BagSync
--]]

local BSYC = select(2, ...)
local ExtTip = BSYC:NewModule("ExtTip")
local Utility = BSYC:GetModule("Utility")
local L = BSYC.L
local wipe = _G.wipe

local function Debug(level, ...)
	if BSYC.DEBUG then BSYC.DEBUG(level, "ExtTip", ...) end
end

local function CanAccessObject(obj)
	return issecure() or not obj:IsForbidden()
end

local function WipeTable(tbl)
	if not tbl then return {} end
	if wipe then
		wipe(tbl)
	else
		for k in pairs(tbl) do
			tbl[k] = nil
		end
	end
	return tbl
end

function ExtTip:EnsureTip()
	if self.extTip then return self.extTip end
	local extTip = CreateFrame("GameTooltip", "BagSyncExtTip", UIParent, "GameTooltipTemplate")
	extTip:SetOwner(UIParent, "ANCHOR_NONE")
	extTip:SetClampedToScreen(true)
	extTip:SetFrameStrata("TOOLTIP")
	extTip:SetToplevel(true)
	self.extTip = extTip
	return extTip
end

function ExtTip:GetTip()
	return self:EnsureTip()
end

function ExtTip:Hide()
	if self.extTip then
		self.extTip:Hide()
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
	if not self.extTip or not BSYC.__font then return end
	local fontPath, fontSize, fontFlags = BSYC.__font:GetFont()
	if not fontPath or not fontSize then return end

	local tip = self.extTip
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
			self.__currentOwner = nil
			extTip:Hide()
			return false
		end
	end

	return true
end

local function FrameAnchoredTo(frame, rel)
	if not frame or not rel then return false end
	if not frame.GetNumPoints or not frame.GetPoint then return false end
	for i = 1, frame:GetNumPoints() do
		local _, relativeTo = frame:GetPoint(i)
		if relativeTo == rel then
			return true
		end
	end
	return false
end

local function IsRelatedTooltipFrame(frame, owner)
	if not frame or not owner or frame == ExtTip.extTip then return false end
	if not CanAccessObject(frame) then return false end
	if not frame.IsVisible or not frame:IsVisible() then return false end

	if frame == owner then return true end
	if frame.GetOwner and frame:GetOwner() == owner then return true end
	if FrameAnchoredTo(frame, owner) then return true end

	return false
end

local function QuantizeCoord(v)
	if not Utility:IsSafeNumber(v) then return 0 end
	return math.floor(v * 10 + 0.5) -- tenth-pixel-ish granularity, avoids jitter
end

local function NormalizeAnchorMode(mode)
	mode = tostring(mode or ""):upper()
	if mode == "LEFT" or mode == "RIGHT" or mode == "BOTTOM" then
		return mode
	end
	return "BOTTOM"
end

local function NormalizeCustomLocation(mode)
	mode = tostring(mode or ""):upper()
	if mode == "TOPLEFT" or mode == "TOPRIGHT" or mode == "BOTTOMLEFT" or mode == "BOTTOMRIGHT"
		or mode == "CENTER" or mode == "CENTER_TOP" or mode == "CENTER_BOTTOM" or mode == "ANCHOR" then
		return mode
	end
	return "CENTER"
end

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

	local parentW = UIParent.GetWidth and UIParent:GetWidth() or 0
	local parentH = UIParent.GetHeight and UIParent:GetHeight() or 0
	local frameW = frame.GetWidth and frame:GetWidth() or 0
	local frameH = frame.GetHeight and frame:GetHeight() or 0

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

function ExtTip:ApplyCustomPosition(extTip)
	local opts = BSYC.options
	if not opts or not opts.extTT_CustomAnchorEnabled then return false end
	if not extTip then return false end

	local location = NormalizeCustomLocation(opts.extTT_CustomAnchorLocation)
	local pad = 16

	extTip:ClearAllPoints()
	if location == "TOPLEFT" then
		extTip:SetPoint("TOPLEFT", UIParent, "TOPLEFT", pad, -pad)
	elseif location == "TOPRIGHT" then
		extTip:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -pad, -pad)
	elseif location == "BOTTOMLEFT" then
		extTip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", pad, pad)
	elseif location == "BOTTOMRIGHT" then
		extTip:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -pad, pad)
	elseif location == "CENTER" then
		extTip:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	elseif location == "CENTER_TOP" then
		extTip:SetPoint("TOP", UIParent, "TOP", 0, -pad)
	elseif location == "CENTER_BOTTOM" then
		extTip:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, pad)
	else
		local anchor = self:EnsureAnchor()
		self:PositionAnchor(anchor)
		extTip:SetPoint("CENTER", anchor, "CENTER", 0, 0)
	end

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
	local width = UIParent and UIParent.GetWidth and UIParent:GetWidth() or 0
	local height = UIParent and UIParent.GetHeight and UIParent:GetHeight() or 0
	if width <= 0 or height <= 0 then return false end
	return (left < 0) or (right > width) or (bottom < 0) or (top > height)
end

function ExtTip:GetBottomAnchor(owner, anchorMode)
	if not owner then return nil end
	anchorMode = NormalizeAnchorMode(anchorMode)

	local bestFrame, bestPos
	local coord = (anchorMode == "LEFT" and "Left") or (anchorMode == "RIGHT" and "Right") or "Bottom"

	local candidates = WipeTable(self.__scratchAnchorCandidates or {})
	self.__scratchAnchorCandidates = candidates

	local function consider(frame)
		if not frame or (anchorMode == "LEFT" and not frame.GetLeft)
			or (anchorMode == "RIGHT" and not frame.GetRight)
			or (anchorMode == "BOTTOM" and not frame.GetBottom) then
			return
		end
		if Utility:IsSecretFrame("Tooltip", frame, owner, "anchor scan", "GetBottomTooltipAnchor") then return end
		if not IsRelatedTooltipFrame(frame, owner) then return end
		local pos = Utility:GetSafeCoord("Tooltip", frame, coord, owner, "anchor scan", "GetBottomTooltipAnchor")
		if not pos then return end
		if anchorMode == "RIGHT" then
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

	-- Owner itself
	consider(owner)

	-- Blizzard comparison tooltips (common sources of "behind" issues)
	consider(_G.ShoppingTooltip1)
	consider(_G.ShoppingTooltip2)
	consider(_G.ShoppingTooltip3)
	consider(_G.ItemRefShoppingTooltip1)
	consider(_G.ItemRefShoppingTooltip2)
	consider(_G.ItemRefShoppingTooltip3)

	-- Retail: some tooltips keep a list of comparison tooltips
	if owner.shoppingTooltips then
		for _, tip in pairs(owner.shoppingTooltips) do
			consider(tip)
		end
	end
	if owner.comparisonTooltips then
		for _, tip in pairs(owner.comparisonTooltips) do
			consider(tip)
		end
	end

	-- Explicit known addon cases (cheap and predictable)
	local isAddOnLoaded = BSYC.API and BSYC.API.IsAddOnLoaded
	if isAddOnLoaded and isAddOnLoaded("TradeSkillMaster") then
		for i = 1, 20 do
			local t = _G["TSMExtraTip" .. i]
			if t and t.IsVisible and t:IsVisible() then
				consider(t)
			elseif not t then
				break
			end
		end
	end

	if LibStub and LibStub.libs and LibStub.libs["LibExtraTip-1"] then
		local t = LibStub("LibExtraTip-1"):GetExtraTip(owner)
		if t and t.IsVisible and t:IsVisible() then
			consider(t)
		end
	end

	if BPBID_BreedTooltip or BPBID_BreedTooltip2 then
		local t = BPBID_BreedTooltip or BPBID_BreedTooltip2
		if t and t.IsVisible and t:IsVisible() then
			consider(t)
		end
	end

	return bestFrame, bestPos
end

function ExtTip:GetBottomAnchorCached(owner, anchorMode)
	if not owner then return nil end
	anchorMode = NormalizeAnchorMode(anchorMode)

	-- Single-cache is enough: ExtTip shows for only one owner at a time.
	local cachedOwner = self.__extTipAnchorOwner
	local cachedSig = self.__extTipAnchorSig
	local cachedAnchor = self.__extTipAnchorFrame
	local cachedMode = self.__extTipAnchorMode

	local sig = 5381

	local function sigAdd(n)
		sig = (sig * 33 + (n or 0)) % 2147483647
	end

	local coord = (anchorMode == "LEFT" and "Left") or (anchorMode == "RIGHT" and "Right") or "Bottom"
	local function consider(frame, weight)
		if not frame or (anchorMode == "LEFT" and not frame.GetLeft)
			or (anchorMode == "RIGHT" and not frame.GetRight)
			or (anchorMode == "BOTTOM" and not frame.GetBottom) then
			sigAdd(7 + (weight or 0))
			return nil
		end

		-- Visibility/relationship gates both anchoring and signature.
		if Utility:IsSecretFrame("Tooltip", frame, owner, "anchor signature", "GetBottomTooltipAnchorCached:signature") then
			sigAdd(11 + (weight or 0))
			return nil
		end
		if not IsRelatedTooltipFrame(frame, owner) then
			sigAdd(13 + (weight or 0))
			return nil
		end

		local pos = Utility:GetSafeCoord("Tooltip", frame, coord, owner, "anchor signature", "GetBottomTooltipAnchorCached:signature")
		if not pos then
			sigAdd(17 + (weight or 0))
			return nil
		end
		local q = QuantizeCoord(pos)
		sigAdd((q * 31) + (weight or 0))

		return frame, pos
	end

	-- Owner position affects where we anchor (TOP/BOTTOM and LEFT/RIGHT logic).
	local cx, cy = Utility:GetSafeCenter("Tooltip", owner, owner, "anchor signature center", "GetBottomTooltipAnchorCached:center")
	sigAdd(QuantizeCoord(cx))
	sigAdd(QuantizeCoord(cy))
	sigAdd(anchorMode == "LEFT" and 11 or anchorMode == "RIGHT" and 17 or 23)

	-- Compute signature across the same candidate set used for anchoring.
	consider(owner, 1)
	consider(_G.ShoppingTooltip1, 2)
	consider(_G.ShoppingTooltip2, 3)
	consider(_G.ShoppingTooltip3, 4)
	consider(_G.ItemRefShoppingTooltip1, 5)
	consider(_G.ItemRefShoppingTooltip2, 6)
	consider(_G.ItemRefShoppingTooltip3, 7)

	if owner.shoppingTooltips then
		local w = 10
		for _, tip in pairs(owner.shoppingTooltips) do
			consider(tip, w)
			w = w + 1
		end
	end
	if owner.comparisonTooltips then
		local w = 40
		for _, tip in pairs(owner.comparisonTooltips) do
			consider(tip, w)
			w = w + 1
		end
	end

	local isAddOnLoaded = BSYC.API and BSYC.API.IsAddOnLoaded
	if isAddOnLoaded and isAddOnLoaded("TradeSkillMaster") then
		for i = 1, 20 do
			local t = _G["TSMExtraTip" .. i]
			if t and t.IsVisible and t:IsVisible() then
				consider(t, 100 + i)
			elseif not t then
				break
			end
		end
	end

	if LibStub and LibStub.libs and LibStub.libs["LibExtraTip-1"] then
		local t = LibStub("LibExtraTip-1"):GetExtraTip(owner)
		if t and t.IsVisible and t:IsVisible() then
			consider(t, 200)
		end
	end

	if BPBID_BreedTooltip or BPBID_BreedTooltip2 then
		local t = BPBID_BreedTooltip or BPBID_BreedTooltip2
		if t and t.IsVisible and t:IsVisible() then
			consider(t, 300)
		end
	end

	-- Cache hit: ensure the cached anchor still qualifies and is safe.
	if cachedOwner == owner and cachedSig == sig and cachedMode == anchorMode
		and cachedAnchor and IsRelatedTooltipFrame(cachedAnchor, owner) then
		local cachedPos = Utility:GetSafeCoord("Tooltip", cachedAnchor, coord, owner, "anchor pick cached", "GetBottomTooltipAnchorCached:cached")
		if cachedPos then
			return cachedAnchor
		end
	end

	-- Cache miss: compute best anchor and store signature.
	local bestFrame, bestPos

	local function pick(frame)
		if not frame or (anchorMode == "LEFT" and not frame.GetLeft)
			or (anchorMode == "RIGHT" and not frame.GetRight)
			or (anchorMode == "BOTTOM" and not frame.GetBottom) then
			return
		end
		if Utility:IsSecretFrame("Tooltip", frame, owner, "anchor pick", "GetBottomTooltipAnchorCached:pick") then return end
		if not IsRelatedTooltipFrame(frame, owner) then return end
		local pos = Utility:GetSafeCoord("Tooltip", frame, coord, owner, "anchor pick", "GetBottomTooltipAnchorCached:pick")
		if not pos then return end
		if anchorMode == "RIGHT" then
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

	pick(owner)
	pick(_G.ShoppingTooltip1)
	pick(_G.ShoppingTooltip2)
	pick(_G.ShoppingTooltip3)
	pick(_G.ItemRefShoppingTooltip1)
	pick(_G.ItemRefShoppingTooltip2)
	pick(_G.ItemRefShoppingTooltip3)

	if owner.shoppingTooltips then
		for _, tip in pairs(owner.shoppingTooltips) do
			pick(tip)
		end
	end
	if owner.comparisonTooltips then
		for _, tip in pairs(owner.comparisonTooltips) do
			pick(tip)
		end
	end

	local isAddOnLoaded = BSYC.API and BSYC.API.IsAddOnLoaded
	if isAddOnLoaded and isAddOnLoaded("TradeSkillMaster") then
		for i = 1, 20 do
			local t = _G["TSMExtraTip" .. i]
			if t and t.IsVisible and t:IsVisible() then
				pick(t)
			elseif not t then
				break
			end
		end
	end

	if LibStub and LibStub.libs and LibStub.libs["LibExtraTip-1"] then
		local t = LibStub("LibExtraTip-1"):GetExtraTip(owner)
		if t and t.IsVisible and t:IsVisible() then
			pick(t)
		end
	end

	if BPBID_BreedTooltip or BPBID_BreedTooltip2 then
		local t = BPBID_BreedTooltip or BPBID_BreedTooltip2
		if t and t.IsVisible and t:IsVisible() then
			pick(t)
		end
	end

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

function ExtTip:SetAnchor(owner, anchor, extTip, anchorMode)
	Debug(BSYC_DL.SL2, "SetExtTipAnchor", owner, anchor, extTip)

	anchor = anchor or owner
	anchorMode = NormalizeAnchorMode(anchorMode)
	local x, y = Utility:GetSafeCenter("Tooltip", owner, owner, "anchor place center", "SetExtTipAnchor")
	if not x or not y then
		if anchorMode == "LEFT" then
			extTip:SetPoint("TOPRIGHT", anchor, "TOPLEFT")
		elseif anchorMode == "RIGHT" then
			extTip:SetPoint("TOPLEFT", anchor, "TOPRIGHT")
		else
			extTip:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT")
		end
		return
	end

	local function place(mode, vhalfOverride)
		mode = NormalizeAnchorMode(mode)
		local vhalf = vhalfOverride or ((y > UIParent:GetHeight() / 4) and "TOP" or "BOTTOM")
		if mode == "LEFT" then
			extTip:SetPoint(vhalf .. "RIGHT", anchor, vhalf .. "LEFT")
			return vhalf
		elseif mode == "RIGHT" then
			extTip:SetPoint(vhalf .. "LEFT", anchor, vhalf .. "RIGHT")
			return vhalf
		else
			local hhalf = (x > UIParent:GetWidth() * 2 / 3) and "LEFT" or (x < UIParent:GetWidth() / 3) and "RIGHT" or ""
			extTip:SetPoint(vhalf .. hhalf, anchor, (vhalf == "TOP" and "BOTTOM" or "TOP") .. hhalf)
			return vhalf, hhalf
		end
	end

	extTip:ClearAllPoints()
	local usedVhalf, usedHhalf = place(anchorMode)
	if IsOffscreen(extTip) then
		extTip:ClearAllPoints()
		if anchorMode == "LEFT" then
			place("RIGHT")
		elseif anchorMode == "RIGHT" then
			place("LEFT")
		else
			-- bottom preference: flip vertical side if off-screen
			local flipVhalf = (usedVhalf == "TOP") and "BOTTOM" or "TOP"
			local hhalf = usedHhalf or ((x > UIParent:GetWidth() * 2 / 3) and "LEFT" or (x < UIParent:GetWidth() / 3) and "RIGHT" or "")
			extTip:SetPoint(flipVhalf .. hhalf, anchor, (flipVhalf == "TOP" and "BOTTOM" or "TOP") .. hhalf)
		end
	end
end

function ExtTip:UpdateAnchor(owner)
	local extTip = self.extTip
	if not extTip or not extTip:IsShown() then return false end

	-- Custom positioning bypasses auto-anchoring and any tooltip scans.
	if self:ApplyCustomPosition(extTip) then
		return true
	end

	local frame = owner or self.__currentOwner
	if not frame then return false end

	self.__currentOwner = frame
	extTip:ClearAllPoints()
	local anchorMode = NormalizeAnchorMode(BSYC.options and BSYC.options.extTT_Anchor)
	local anchor = self:GetBottomAnchorCached(frame, anchorMode)
	if not anchor then
		extTip:Hide()
		return false
	end
	if anchor == extTip then anchor = frame end
	self:SetAnchor(frame, anchor, extTip, anchorMode)
	return true
end
