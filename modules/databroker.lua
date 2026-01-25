-- Optional LibDataBroker launcher (no hard dependency)

local _, BagSync = ...
local L = BagSync.L

local LDB = _G["LibDataBroker-1.1"]
if not LDB then return end

LDB:NewDataObject("BagSync", {
  type = "launcher",
  icon = "Interface/AddOns/BagSync/media/icon",
  label = "BagSync",

  OnClick = function(_, button)
    local search = BagSync.GetModule and BagSync:GetModule("Search", true)
    if button == "LeftButton" then
      if search and search.Toggle then
        search:Toggle()
      end
    else
      local minimap = BagSync.GetModule and BagSync:GetModule("Minimap", true)
      if minimap and minimap.button then
        ToggleDropDownMenu(1, nil, _G.BagSyncMinimapMenu, minimap.button, 0, 0)
      end
    end
  end,

  OnTooltipShow = function(tooltip)
    tooltip:AddLine("BagSync")
    tooltip:AddLine(L.LeftClickSearch, 0.8, 0.8, 0.8)
    tooltip:AddLine(L.RightClickBagSyncMenu, 0.8, 0.8, 0.8)
  end,
})
