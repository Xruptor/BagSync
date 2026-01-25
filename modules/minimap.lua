--[[
	Minimap.lua
		A Minimap icon for BagSync

		BagSync - All Rights Reserved - (c) 2025
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
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
local menuFrame = CreateFrame("Frame", "BagSyncMinimapMenu", UIParent, "UIDropDownMenuTemplate")

local function ShowModuleFrame(name)
  local module = BSYC.GetModule and BSYC:GetModule(name, true)
  if module and module.frame and module.frame.Show then
    module.frame:Show()
  end
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
  AddButton(level, L.Close, CloseDropDownMenus)
end

-- Shape-aware positioning (LibDBIcon logic)
local function SetButtonAngle(button, angle)
  local rad = math.rad(angle)
  local x, y = math.cos(rad), math.sin(rad)

  local shape = (GetMinimapShape and GetMinimapShape()) or "ROUND"
  local quadTable = minimapShapes[shape] or minimapShapes.ROUND

  local w = (MinimapFrame:GetWidth() / 2) + ICON_PADDING
  local h = (MinimapFrame:GetHeight() / 2) + ICON_PADDING

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
end

function MinimapModule:LoadPosition()
  self.button:ClearAllPoints()
  local angle = DEFAULT_ANGLE
  if BSYC.options then
    angle = BSYC.options.minimapPos
      or (BSYC.options.minimap and BSYC.options.minimap.minimapPos)
      or DEFAULT_ANGLE
  end
  SetButtonAngle(self.button, angle)
end

function MinimapModule:Create()
  if self.button then return end
  if not MinimapFrame then
    Debug(1, "Minimap frame missing; minimap icon not created.")
    return
  end

  local f = CreateFrame("Button", "BagSyncMinimapButton", MinimapFrame)
  f:SetFrameStrata("MEDIUM")
  f:SetFrameLevel(8)
  f:SetSize(31, 31)
  local overlay = f:CreateTexture(nil, "OVERLAY")
  overlay:SetSize(53, 53)
  overlay:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")
  overlay:SetPoint("TOPLEFT")

  local background = f:CreateTexture(nil, "BACKGROUND")
  background:SetSize(20, 20)
  background:SetTexture("Interface/Minimap/UI-Minimap-Background")
  background:SetPoint("TOPLEFT", 7, -5)

  local icon = f:CreateTexture(nil, "ARTWORK")
  icon:SetSize(32, 32)
  icon:SetTexture("Interface/AddOns/BagSync/media/minimap.tga")
  icon:SetPoint("TOPLEFT", 0, -1)
  f.icon = icon

  local highlight = f:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")
  highlight:SetBlendMode("ADD")

  f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  f:RegisterForDrag("LeftButton")

  f:SetScript("OnClick", function(_, button)
    if button == "LeftButton" then
      ShowModuleFrame("Search")
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
      local px, py = GetCursorPosition()
      local scale = UIParent:GetScale()
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
  UIDropDownMenu_Initialize(menuFrame, InitMinimapMenu, "MENU")
  if BSYC.options and (BSYC.options.enableMinimap == false or (BSYC.options.minimap and BSYC.options.minimap.hide)) then
    f:Hide()
  end

end

function MinimapModule:UpdateVisibility()
  if not self.button then return end
  if BSYC.options and (BSYC.options.enableMinimap == false or (BSYC.options.minimap and BSYC.options.minimap.hide)) then
    self.button:Hide()
  else
    self.button:Show()
  end
end

function MinimapModule:OnEnable()
  self:Create()
  self:UpdateVisibility()
end
