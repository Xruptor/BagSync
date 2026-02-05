-- Optional LibDataBroker launcher (no hard dependency)

local _, BagSync = ...
local L = BagSync.L

local LDB = _G["LibDataBroker-1.1"]
if not LDB and _G.LibStub then
  LDB = _G.LibStub("LibDataBroker-1.1", true)
end

local function RegisterLDB()
  if not LDB then return end
  if LDB.GetDataObjectByName and LDB:GetDataObjectByName("BagSync") then
    BagSync.LDBObject = LDB:GetDataObjectByName("BagSync")
    return
  end

  BagSync.LDBObject = LDB:NewDataObject("BagSync", {
    type = "launcher",
    icon = "Interface/AddOns/BagSync/media/icon",
    label = "BagSync",

    OnClick = function(frame, button)
      local search = BagSync.GetModule and BagSync:GetModule("Search", true)
      if button == "LeftButton" then
        if search and search.Toggle then
          search:Toggle()
        elseif search and search.frame and search.frame.Show then
          search.frame:Show()
        end
      else
        local minimap = BagSync.GetModule and BagSync:GetModule("Minimap", true)
        local anchor = frame
        if not anchor and minimap and minimap.button then
          anchor = minimap.button
        end
        ToggleDropDownMenu(1, nil, _G.BagSyncMinimapMenu, anchor or UIParent, 0, 0)
      end
    end,

    OnTooltipShow = function(tooltip)
      tooltip:AddLine("BagSync")
      tooltip:AddLine(L.LeftClickSearch, 0.8, 0.8, 0.8)
      tooltip:AddLine(L.RightClickBagSyncMenu, 0.8, 0.8, 0.8)
    end,
  })
end

--lets wait for LibDataBroker-1.1 to actually load, otherwise it won't show in ElvUI
if not LDB then
  local UI = BagSync:GetModule("UI")
  local waitFrame = UI:CreateFrame(UIParent, {})
  waitFrame:RegisterEvent("ADDON_LOADED")
  waitFrame:SetScript("OnEvent", function()
    if not LDB and _G.LibStub then
      LDB = _G.LibStub("LibDataBroker-1.1", true)
    end
    if LDB then
      RegisterLDB()
      waitFrame:UnregisterEvent("ADDON_LOADED")
    end
  end)
  return
end

RegisterLDB()
