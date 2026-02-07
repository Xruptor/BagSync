--[[
	Minimap.lua
		A Minimap icon for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local UI = BSYC:GetModule("UI")
local MinimapModule = BSYC:NewModule("Minimap")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Minimap", ...) end
end

local L = BSYC.L

local DEFAULT_ANGLE = 220
local ICON_PADDING = 5
local MinimapFrame = _G.Minimap

-- LibDBIcon minimap shape table
local minimapShapes = {
  ROUND = { true, true, true, true },
  SQUARE = { false, false, false, false },
  ["CORNER-TOPLEFT"] = { false, false, false, true },
  ["CORNER-TOPRIGHT"] = { false, false, true, false },
  ["CORNER-BOTTOMLEFT"] = { false, true, false, false },
  ["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
  ["SIDE-LEFT"] = { false, true, false, true },
  ["SIDE-RIGHT"] = { true, false, true, false },
  ["SIDE-TOP"] = { false, false, true, true },
  ["SIDE-BOTTOM"] = { true, true, false, false },
  ["TRICORNER-TOPLEFT"] = { false, true, true, true },
  ["TRICORNER-TOPRIGHT"] = { true, false, true, true },
  ["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
  ["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

-- Dropdown menu
local menuFrame = UI:CreateDropdown(UIParent, {
  globalName = "BagSyncMinimapMenu",
})
local menuInitialized = false

local function ShowModuleFrame(name)
  local module = BSYC.GetModule and BSYC:GetModule(name, true)
  if module and module.frame and module.frame.Show then
    module.frame:Show()
  end
end

local function GetLibDBIcon()
  if _G.LibStub then
    return _G.LibStub("LibDBIcon-1.0", true)
  end
end

local function GetLDBObject()
  return BSYC and BSYC.LDBObject
end

local function DoFixDB()
  local data = BSYC.GetModule and BSYC:GetModule("Data", true)
  if data and data.FixDB then
    data:FixDB()
  end
end

local function OpenConfig()
  if BSYC.OpenConfig then
    BSYC:OpenConfig()
    return
  end
  if BSYC.Config and BSYC.Config.OpenOptions then
    BSYC.Config:OpenOptions()
  elseif BSYC.Config and BSYC.Config.Toggle then
    BSYC.Config:Toggle()
  end
end

local function AddButton(level, text, func, disabled, isTitle)
  local info = UIDropDownMenu_CreateInfo()
  info.text = text
  info.func = func
  info.disabled = disabled
  info.isTitle = isTitle
  info.notCheckable = true
  UIDropDownMenu_AddButton(info, level)
end

local function InitMinimapMenu(_, level)
  level = level or 1
  if level ~= 1 then return end

  if PlaySound and SOUNDKIT and SOUNDKIT.GS_TITLE_OPTION_EXIT then
    PlaySound(SOUNDKIT.GS_TITLE_OPTION_EXIT)
  end

  AddButton(level, "BagSync", nil, true, true)
  AddButton(level, L.Search, function() ShowModuleFrame("Search") end)

  if BSYC.CanDoCurrency and BSYC:CanDoCurrency() and BSYC.tracking and BSYC.tracking.currency then
    AddButton(level, L.Currency, function() ShowModuleFrame("Currency") end)
  end
  if BSYC.CanDoProfessions and BSYC:CanDoProfessions() and BSYC.tracking and BSYC.tracking.professions then
    AddButton(level, L.Professions, function() ShowModuleFrame("Professions") end)
  end

  AddButton(level, L.Blacklist, function() ShowModuleFrame("Blacklist") end)
  AddButton(level, L.Whitelist, function() ShowModuleFrame("Whitelist") end)
  AddButton(level, L.Gold, function() ShowModuleFrame("Gold") end)
  AddButton(level, L.Profiles, function() ShowModuleFrame("Profiles") end)
  AddButton(level, L.SortOrder, function() ShowModuleFrame("SortOrder") end)
  AddButton(level, L.FixDB, DoFixDB)
  AddButton(level, L.Config, OpenConfig)
  AddButton(level, "", nil, true)
  AddButton(level, L.Close, function() CloseDropDownMenus() end)
end

local function InitMenuFrame()
  if menuInitialized then return end
  menuFrame.displayMode = "MENU"
  UIDropDownMenu_Initialize(menuFrame, InitMinimapMenu, "MENU")
  menuInitialized = true
end

-- Shape-aware positioning (LibDBIcon logic)
local function SetButtonAngle(button, angle)
  if not MinimapFrame or not MinimapFrame.GetWidth or not MinimapFrame.GetHeight then return end
  local rad = math.rad(angle)
  local x, y = math.cos(rad), math.sin(rad)

  local shape = (GetMinimapShape and GetMinimapShape()) or "ROUND"
  local quadTable = minimapShapes[shape] or minimapShapes.ROUND

  local w = (MinimapFrame:GetWidth() / 2) + ICON_PADDING
  local h = (MinimapFrame:GetHeight() / 2) + ICON_PADDING
  if w <= 0 or h <= 0 then return end

  local q = 1
  if x < 0 then q = q + 1 end
  if y > 0 then q = q + 2 end

  if quadTable[q] then
    x = x * w
    y = y * h
  else
    local diagW = math.sqrt(2 * w * w) - 10
    local diagH = math.sqrt(2 * h * h) - 10
    x = math.max(-w, math.min(x * diagW, w))
    y = math.max(-h, math.min(y * diagH, h))
  end

  button:SetPoint("CENTER", MinimapFrame, "CENTER", x, y)
end

function MinimapModule:SaveAngle(angle)
  BSYC.options = BSYC.options or {}
  BSYC.options.minimapPos = angle
  if self.libDBIconDB then
    -- ------
    -- LibDBIcon: keep registered icon position in sync
    -- ------
    self.libDBIconDB.minimapPos = angle
    local ldbicon = GetLibDBIcon()
    if self.usingLibDBIcon and ldbicon and ldbicon.Refresh then
      ldbicon:Refresh("BagSync", self.libDBIconDB)
    end
  end
end

function MinimapModule:ResetPosition()
  BSYC.options = BSYC.options or {}
  BSYC.options.enableMinimap = true
  BSYC.options.minimapPos = DEFAULT_ANGLE
  if self.libDBIconDB then
    -- ------
    -- LibDBIcon: reset to defaults and refresh if active
    -- ------
    self.libDBIconDB.hide = false
    self.libDBIconDB.minimapPos = DEFAULT_ANGLE
    local ldbicon = GetLibDBIcon()
    if self.usingLibDBIcon and ldbicon and ldbicon.Refresh then
      ldbicon:Refresh("BagSync", self.libDBIconDB)
    end
  end
  if self.button then
    self.button:Show()
    self:LoadPosition()
  end
end

function MinimapModule:LoadPosition()
  if self.usingLibDBIcon then
    -- ------
    -- LibDBIcon: position is handled by LibDBIcon; just refresh
    -- ------
    local ldbicon = GetLibDBIcon()
    if ldbicon and ldbicon.Refresh and self.libDBIconDB then
      ldbicon:Refresh("BagSync", self.libDBIconDB)
    end
    return
  end
  self.button:ClearAllPoints()
  local angle = DEFAULT_ANGLE
  if BSYC.options then
    angle = BSYC.options.minimapPos or DEFAULT_ANGLE
  end
  angle = tonumber(angle)
  if not angle then
    angle = DEFAULT_ANGLE
  end
  angle = angle % 360
  SetButtonAngle(self.button, angle)
end

--------------------------------------------------------
--------------------------------------------------------
--- LDB and LibDBIcon fallback checks

function MinimapModule:InitLibDBIconDB()
  if self.libDBIconDB then return self.libDBIconDB end
  local angle = DEFAULT_ANGLE
  if BSYC.options and BSYC.options.minimapPos then
    angle = tonumber(BSYC.options.minimapPos) or DEFAULT_ANGLE
  end
  self.libDBIconDB = {
    minimapPos = angle,
    hide = BSYC.options and BSYC.options.enableMinimap == false,
  }
  return self.libDBIconDB
end

function MinimapModule:TryEnableLibDBIcon()
  -- ------
  -- LibDBIcon: use it only if already loaded and we have an LDB object
  -- ------
  if self.usingLibDBIcon then return true end
  local ldbicon = GetLibDBIcon()
  if not ldbicon then return false end
  local obj = GetLDBObject()
  if not obj then return false end

  local db = self:InitLibDBIconDB()
  if ldbicon.GetMinimapButton and ldbicon:GetMinimapButton("BagSync") then
    self.usingLibDBIcon = true
    if self.button then self.button:Hide() end
    return true
  end

  local ok, err = pcall(ldbicon.Register, ldbicon, "BagSync", obj, db)
  if not ok then
    Debug(1, "LibDBIcon register failed:", err)
    return false
  end
  self.usingLibDBIcon = true
  if self.button then self.button:Hide() end
  if ldbicon.Refresh then
    ldbicon:Refresh("BagSync", db)
  end
  return true
end

function MinimapModule:SetupLibDBIconWatcher()
  -- ------
  -- LibDBIcon: watch for late-loading libs and switch over if available
  -- ------
  if self.libDBIconWaitFrame then return end
  if self.usingLibDBIcon then return end
  local waitFrame = UI:CreateFrame(UIParent, {})
  waitFrame:RegisterEvent("ADDON_LOADED")
  waitFrame:SetScript("OnEvent", function()
    if self:TryEnableLibDBIcon() then
      waitFrame:UnregisterEvent("ADDON_LOADED")
    end
  end)
  self.libDBIconWaitFrame = waitFrame
end

--------------------------------------------------------
--------------------------------------------------------

function MinimapModule:Create()
	if self.button then return end
	if self.usingLibDBIcon then return end
	if not MinimapFrame then
		Debug(1, "Minimap frame missing; minimap icon not created.")
		return
	end

	local function IsSafeNumber(v)
		return (BSYC and BSYC.IsSafeNumber and BSYC:IsSafeNumber(v)) or type(v) == "number"
	end

	--migrate the older format to a more flatter approach, to use enableMinimap and minimapPos
	if BSYC.options and BSYC.options.minimap then
		if BSYC.options.minimapPos == nil and BSYC.options.minimap.minimapPos ~= nil then
			BSYC.options.minimapPos = BSYC.options.minimap.minimapPos
    end
    if BSYC.options.enableMinimap == nil and BSYC.options.minimap.hide ~= nil then
      BSYC.options.enableMinimap = not BSYC.options.minimap.hide
    end
    BSYC.options.minimap = nil
  end

  local f = UI:CreateButton(MinimapFrame, {
    globalName = "BagSyncMinimapButton",
    size = { 31, 31 },
    frameStrata = "MEDIUM",
    frameLevel = 8,
    registerForClicks = { "LeftButtonUp", "RightButtonUp" },
    registerForDrag = "LeftButton",
  })
  local overlay = UI:CreateTexture(f, { layer = "OVERLAY" })
  overlay:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")

  local background = UI:CreateTexture(f, { layer = "BACKGROUND" })
  background:SetTexture("Interface/Minimap/UI-Minimap-Background")

  local icon = UI:CreateTexture(f, {
    layer = "ARTWORK",
    globalName = "BagSyncMinimapButtonIcon",
  })
  icon:SetTexture("Interface/AddOns/BagSync/media/icon")

  if BSYC.IsRetail then
    overlay:SetSize(50, 50)
    overlay:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)

    background:SetSize(24, 24)
    background:SetPoint("CENTER", f, "CENTER", 0, 1)

    icon:SetSize(18, 18)
    icon:SetPoint("CENTER", f, "CENTER", 0, 1)
  else
    overlay:SetSize(53, 53)
    overlay:SetPoint("TOPLEFT")

    background:SetSize(20, 20)
    background:SetPoint("TOPLEFT", 7, -5)

    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", 7, -6)
  end
  f.icon = icon

  local highlight = UI:CreateTexture(f, { layer = "HIGHLIGHT" })
  highlight:SetAllPoints()
  highlight:SetTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")
  highlight:SetBlendMode("ADD")

  f:SetScript("OnClick", function(_, button)
    if button == "LeftButton" then
      local search = BSYC.GetModule and BSYC:GetModule("Search", true)
      if search and search.Toggle then
        search:Toggle()
      else
        ShowModuleFrame("Search")
      end
    else
      ToggleDropDownMenu(1, nil, menuFrame, f, 0, 0)
    end
  end)

	  f:SetScript("OnEnter", function()
	    GameTooltip:SetOwner(f, "ANCHOR_LEFT")
	    GameTooltip:AddLine("BagSync")
	    GameTooltip:AddLine(L.LeftClickSearch)
    GameTooltip:AddLine(L.RightClickBagSyncMenu)
    GameTooltip:Show()
  end)
  f:SetScript("OnLeave", GameTooltip_Hide)
	  -- Dragging (shape-aware)
		  f:SetScript("OnDragStart", function(self)
		    self:SetScript("OnUpdate", function()
		      local mx, my = MinimapFrame:GetCenter()
		      if not (IsSafeNumber(mx) and IsSafeNumber(my)) then return end
		      local px, py = GetCursorPosition()
		      if not (IsSafeNumber(px) and IsSafeNumber(py)) then return end
		      local scale = (MinimapFrame.GetEffectiveScale and MinimapFrame:GetEffectiveScale()) or UIParent:GetScale()
		      if not IsSafeNumber(scale) or scale <= 0 then return end
		      px, py = px / scale, py / scale

      local angle = math.deg(math.atan2(py - my, px - mx)) % 360
      MinimapModule:SaveAngle(angle)
      SetButtonAngle(self, angle)
    end)
  end)
  f:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
  end)
  self.button = f
  self:LoadPosition()
  InitMenuFrame()
  if BSYC.options and BSYC.options.enableMinimap == false then
    f:Hide()
  end

  f:RegisterEvent("PLAYER_LOGIN")
  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:RegisterEvent("MINIMAP_UPDATE_SHAPE")
  f:RegisterEvent("UI_SCALE_CHANGED")
  f:SetScript("OnEvent", function()
    MinimapModule:LoadPosition()
  end)

end

function MinimapModule:UpdateVisibility()
  if self.usingLibDBIcon then
    -- ------
    -- LibDBIcon: reflect BagSync visibility in the LibDBIcon db
    -- ------
    local ldbicon = GetLibDBIcon()
    if self.libDBIconDB then
      self.libDBIconDB.hide = BSYC.options and BSYC.options.enableMinimap == false
      if ldbicon and ldbicon.Refresh then
        ldbicon:Refresh("BagSync", self.libDBIconDB)
      end
    end
    return
  end
  if not self.button then return end
  if BSYC.options and BSYC.options.enableMinimap == false then
    self.button:Hide()
  else
    self.button:Show()
  end
end

local function CanRegisterAddonCompartment()
	return _G.AddonCompartmentFrame and _G.AddonCompartmentFrame.RegisterAddon
end

function MinimapModule:TryRegisterAddonCompartment()
	if self.addonCompartmentRegistered then return end
	if BSYC.options and BSYC.options.enableAddonCompartment == false then return end
	if not CanRegisterAddonCompartment() then return end
	local entry = {
		text = "BagSync",
		icon = "Interface/AddOns/BagSync/media/icon",
		notCheckable = true,
		func = function()
			_G.BagSync_AddonCompartmentFunc()
		end,
	}

	local ok = pcall(_G.AddonCompartmentFrame.RegisterAddon, _G.AddonCompartmentFrame, entry)
	if ok then
		self.addonCompartmentRegistered = true
	end
end

function MinimapModule:OnEnable()
  InitMenuFrame()
  self:TryEnableLibDBIcon()
  self:Create()
  self:UpdateVisibility()
  self:TryRegisterAddonCompartment()
  self:SetupLibDBIconWatcher()

  if not self.addonCompartmentRegistered and not self.addonCompartmentWaitFrame then
    local waitFrame = CreateFrame("Frame")
    waitFrame:RegisterEvent("PLAYER_LOGIN")
    waitFrame:SetScript("OnEvent", function()
      MinimapModule:TryRegisterAddonCompartment()
    end)
    self.addonCompartmentWaitFrame = waitFrame
  end
end

function MinimapModule:AddonCompartmentFunc()
  if BSYC.options and BSYC.options.enableAddonCompartment == false then return end
  if InCombatLockdown and InCombatLockdown() then return end
  InitMenuFrame()
  local anchor = _G.AddonCompartmentFrame or UIParent
  ToggleDropDownMenu(1, nil, menuFrame, anchor, 0, 0)
end

_G.BagSync_AddonCompartmentFunc = function()
  if BSYC and BSYC.options and BSYC.options.enableAddonCompartment == false then return end
  local minimap = BSYC.GetModule and BSYC:GetModule("Minimap", true)
  if minimap and minimap.AddonCompartmentFunc then
    minimap:AddonCompartmentFunc()
  elseif BSYC and BSYC.OpenConfig then
    BSYC:OpenConfig()
  end
end
