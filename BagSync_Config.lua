local L = BAGSYNC_L
local currentPlayer = UnitName('player')
local currentRealm = GetRealmName()
local ver = GetAddOnMetadata("BagSync","Version") or 0

local bgsOpt = CreateFrame("Frame", "BagSyncConfig", InterfaceOptionsFramePanelContainer)
bgsOpt:Hide()
bgsOpt.name = "BagSync"

bgsOpt:SetScript("OnShow", function()
	if BagSyncOpt then
		BagSyncConfig_Total:SetChecked(BagSyncOpt["showTotal"])
		BagSyncConfig_GuildNames:SetChecked(BagSyncOpt["showGuildNames"])
		BagSyncConfig_BothFactions:SetChecked(BagSyncOpt["enableFaction"])
		BagSyncConfig_ClassColors:SetChecked(BagSyncOpt["enableUnitClass"])
		BagSyncConfig_Minimap:SetChecked(BagSyncOpt["enableMinimap"])
		BagSyncConfig_GuildInfo:SetChecked(BagSyncOpt["enableGuild"])
		BagSyncConfig_MailboxInfo:SetChecked(BagSyncOpt["enableMailbox"])
		BagSyncConfig_AuctionInfo:SetChecked(BagSyncOpt["enableAuction"])
		BagSyncConfig_TooltipSearchOnly:SetChecked(BagSyncOpt["tooltipOnlySearch"])
		BagSyncConfig_EnableBagSyncTooltips:SetChecked(BagSyncOpt["enableTooltips"])
		BagSyncConfig_EnableBagSyncTooltipsSeperator:SetChecked(BagSyncOpt["enableTooltipSeperator"])
	end
end)

local title = bgsOpt:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("|cFF99CC33BagSync|r [|cFFDF2B2B"..ver.."|r]")
InterfaceOptions_AddCategory(bgsOpt)

--[[ Total ]]--
local bgs_Total_Opt = CreateFrame("CheckButton", "BagSyncConfig_Total", bgsOpt, "OptionsBaseCheckButtonTemplate")
bgs_Total_Opt:SetPoint("TOPLEFT", 16, -45)
bgs_Total_Opt:SetScript("OnClick", function(frame)
	if BagSyncOpt then
		if frame:GetChecked() then
			PlaySound("igMainMenuOptionCheckBoxOn")
			BagSyncOpt["showTotal"] = true
			if BagSync then BagSync:resetTooltip() end
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
			BagSyncOpt["showTotal"] = false
			if BagSync then BagSync:resetTooltip() end
		end
	end
end)
local bgs_Total_OptText = bgs_Total_Opt:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
bgs_Total_OptText:SetPoint("LEFT", bgs_Total_Opt, "RIGHT", 0, 1)
bgs_Total_OptText:SetText(L["Display [Total] in tooltips and gold display."])

--[[ Guild Names ]]--
local bgs_GuildNames_Opt = CreateFrame("CheckButton", "BagSyncConfig_GuildNames", bgsOpt, "OptionsBaseCheckButtonTemplate")
bgs_GuildNames_Opt:SetPoint("TOPLEFT", 16, -73)
bgs_GuildNames_Opt:SetScript("OnClick", function(frame)
	if BagSyncOpt then
		if frame:GetChecked() then
			PlaySound("igMainMenuOptionCheckBoxOn")
			BagSyncOpt["showGuildNames"] = true
			if BagSync then BagSync:resetTooltip() end
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
			BagSyncOpt["showGuildNames"] = false
			if BagSync then BagSync:resetTooltip() end
		end
	end
end)
local bgs_GuildNames_OptText = bgs_GuildNames_Opt:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
bgs_GuildNames_OptText:SetPoint("LEFT", bgs_GuildNames_Opt, "RIGHT", 0, 1)
bgs_GuildNames_OptText:SetText(L["Display [Guild Name] display in tooltips."])

--[[ Display Both Factions ]]--
local bgs_BothFactions_Opt = CreateFrame("CheckButton", "BagSyncConfig_BothFactions", bgsOpt, "OptionsBaseCheckButtonTemplate")
bgs_BothFactions_Opt:SetPoint("TOPLEFT", 16, -101)
bgs_BothFactions_Opt:SetScript("OnClick", function(frame)
	if BagSyncOpt then
		if frame:GetChecked() then
			PlaySound("igMainMenuOptionCheckBoxOn")
			BagSyncOpt["enableFaction"] = true
			if BagSync then BagSync:resetTooltip() end
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
			BagSyncOpt["enableFaction"] = false
			if BagSync then BagSync:resetTooltip() end
		end
	end
end)
local bgs_BothFactions_OptText = bgs_BothFactions_Opt:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
bgs_BothFactions_OptText:SetPoint("LEFT", bgs_BothFactions_Opt, "RIGHT", 0, 1)
bgs_BothFactions_OptText:SetText(L["Display items for both factions (Alliance/Horde)."])

--[[ Class Colors ]]--
local bgs_ClassColors_Opt = CreateFrame("CheckButton", "BagSyncConfig_ClassColors", bgsOpt, "OptionsBaseCheckButtonTemplate")
bgs_ClassColors_Opt:SetPoint("TOPLEFT", 16, -129)
bgs_ClassColors_Opt:SetScript("OnClick", function(frame)
	if BagSyncOpt then
		if frame:GetChecked() then
			PlaySound("igMainMenuOptionCheckBoxOn")
			BagSyncOpt["enableUnitClass"] = true
			if BagSync then BagSync:resetTooltip() end
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
			BagSyncOpt["enableUnitClass"] = false
			if BagSync then BagSync:resetTooltip() end
		end
	end
end)
local bgs_ClassColors_OptText = bgs_ClassColors_Opt:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
bgs_ClassColors_OptText:SetPoint("LEFT", bgs_ClassColors_Opt, "RIGHT", 0, 1)
bgs_ClassColors_OptText:SetText(L["Display class colors for characters."])

--[[ Minimap ]]--
local bgs_Minimap_Opt = CreateFrame("CheckButton", "BagSyncConfig_Minimap", bgsOpt, "OptionsBaseCheckButtonTemplate")
bgs_Minimap_Opt:SetPoint("TOPLEFT", 16, -157)
bgs_Minimap_Opt:SetScript("OnClick", function(frame)
	if BagSyncOpt then
		if frame:GetChecked() then
			PlaySound("igMainMenuOptionCheckBoxOn")
			BagSyncOpt["enableMinimap"] = true
			if BagSync_MinimapButton and not BagSync_MinimapButton:IsVisible() then BagSync_MinimapButton:Show() end
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
			BagSyncOpt["enableMinimap"] = false
			if BagSync_MinimapButton and BagSync_MinimapButton:IsVisible() then BagSync_MinimapButton:Hide() end
		end
	end			
end)
local bgs_Minimap_OptText = bgs_Minimap_Opt:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
bgs_Minimap_OptText:SetPoint("LEFT", bgs_Minimap_Opt, "RIGHT", 0, 1)
bgs_Minimap_OptText:SetText(L["Display BagSync minimap button."])

--[[ Enable Guild Info ]]--
local bgs_GuildInfo_Opt = CreateFrame("CheckButton", "BagSyncConfig_GuildInfo", bgsOpt, "OptionsBaseCheckButtonTemplate")
bgs_GuildInfo_Opt:SetPoint("TOPLEFT", 16, -185)
bgs_GuildInfo_Opt:SetScript("OnClick", function(frame)
	if BagSyncOpt then
		if frame:GetChecked() then
			PlaySound("igMainMenuOptionCheckBoxOn")
			BagSyncOpt["enableGuild"] = true
			if BagSync then BagSync:resetTooltip() end
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
			BagSyncOpt["enableGuild"] = false
			if BagSync then BagSync:resetTooltip() end
		end
	end
end)
local bgs_GuildInfo_OptText = bgs_GuildInfo_Opt:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
bgs_GuildInfo_OptText:SetPoint("LEFT", bgs_GuildInfo_Opt, "RIGHT", 0, 1)
bgs_GuildInfo_OptText:SetText(L["Enable guild bank items."])

--[[ Enable Mailbox Info ]]--
local bgs_MailboxInfo_Opt = CreateFrame("CheckButton", "BagSyncConfig_MailboxInfo", bgsOpt, "OptionsBaseCheckButtonTemplate")
bgs_MailboxInfo_Opt:SetPoint("TOPLEFT", 16, -213)
bgs_MailboxInfo_Opt:SetScript("OnClick", function(frame)
	if BagSyncOpt then
		if frame:GetChecked() then
			PlaySound("igMainMenuOptionCheckBoxOn")
			BagSyncOpt["enableMailbox"] = true
			if BagSync then BagSync:resetTooltip() end
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
			BagSyncOpt["enableMailbox"] = false
			if BagSync then BagSync:resetTooltip() end
		end
	end
end)
local bgs_MailboxInfo_OptText = bgs_MailboxInfo_Opt:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
bgs_MailboxInfo_OptText:SetPoint("LEFT", bgs_MailboxInfo_Opt, "RIGHT", 0, 1)
bgs_MailboxInfo_OptText:SetText(L["Enable mailbox items."])

--[[ Enable Auction House Info Info ]]--
local bgs_AuctionInfo_Opt = CreateFrame("CheckButton", "BagSyncConfig_AuctionInfo", bgsOpt, "OptionsBaseCheckButtonTemplate")
bgs_AuctionInfo_Opt:SetPoint("TOPLEFT", 16, -241)
bgs_AuctionInfo_Opt:SetScript("OnClick", function(frame)
	if BagSyncOpt then
		if frame:GetChecked() then
			PlaySound("igMainMenuOptionCheckBoxOn")
			BagSyncOpt["enableAuction"] = true
			if BagSync then BagSync:resetTooltip() end
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
			BagSyncOpt["enableAuction"] = false
			if BagSync then BagSync:resetTooltip() end
		end
	end
end)
local bgs_AuctionInfo_OptText = bgs_AuctionInfo_Opt:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
bgs_AuctionInfo_OptText:SetPoint("LEFT", bgs_AuctionInfo_Opt, "RIGHT", 0, 1)
bgs_AuctionInfo_OptText:SetText(L["Enable auction house items."])

--[[ Display tooltips only in the BagSync Search window ]]--
local bgs_TooltipSearchOnly_Opt = CreateFrame("CheckButton", "BagSyncConfig_TooltipSearchOnly", bgsOpt, "OptionsBaseCheckButtonTemplate")
bgs_TooltipSearchOnly_Opt:SetPoint("TOPLEFT", 16, -269)
bgs_TooltipSearchOnly_Opt:SetScript("OnClick", function(frame)
	if BagSyncOpt then
		if frame:GetChecked() then
			PlaySound("igMainMenuOptionCheckBoxOn")
			BagSyncOpt["tooltipOnlySearch"] = true
			if BagSync then BagSync:resetTooltip() end
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
			BagSyncOpt["tooltipOnlySearch"] = false
			if BagSync then BagSync:resetTooltip() end
		end
	end
end)
local bgs_TooltipSearchOnly_OptText = bgs_TooltipSearchOnly_Opt:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
bgs_TooltipSearchOnly_OptText:SetPoint("LEFT", bgs_TooltipSearchOnly_Opt, "RIGHT", 0, 1)
bgs_TooltipSearchOnly_OptText:SetText(L["Display modified tooltips ONLY in the BagSync Search window."])

--[[ Toggle for BagSync tooltips]]--
local bgs_EnableBagSyncTooltips_Opt = CreateFrame("CheckButton", "BagSyncConfig_EnableBagSyncTooltips", bgsOpt, "OptionsBaseCheckButtonTemplate")
bgs_EnableBagSyncTooltips_Opt:SetPoint("TOPLEFT", 16, -297)
bgs_EnableBagSyncTooltips_Opt:SetScript("OnClick", function(frame)
	if BagSyncOpt then
		if frame:GetChecked() then
			PlaySound("igMainMenuOptionCheckBoxOn")
			BagSyncOpt["enableTooltips"] = true
			if BagSync then BagSync:resetTooltip() end
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
			BagSyncOpt["enableTooltips"] = false
			if BagSync then BagSync:resetTooltip() end
		end
	end
end)
local bgs_EnableBagSyncTooltips_OptText = bgs_EnableBagSyncTooltips_Opt:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
bgs_EnableBagSyncTooltips_OptText:SetPoint("LEFT", bgs_EnableBagSyncTooltips_Opt, "RIGHT", 0, 1)
bgs_EnableBagSyncTooltips_OptText:SetText(L["Enable BagSync Tooltips"])

--[[ Toggle for BagSync Tooltip Seperator]]--
local bgs_EnableBagSyncTooltipsSeperator_Opt = CreateFrame("CheckButton", "BagSyncConfig_EnableBagSyncTooltipsSeperator", bgsOpt, "OptionsBaseCheckButtonTemplate")
bgs_EnableBagSyncTooltipsSeperator_Opt:SetPoint("TOPLEFT", 16, -325)
bgs_EnableBagSyncTooltipsSeperator_Opt:SetScript("OnClick", function(frame)
	if BagSyncOpt then
		if frame:GetChecked() then
			PlaySound("igMainMenuOptionCheckBoxOn")
			BagSyncOpt["enableTooltipSeperator"] = true
			if BagSync then BagSync:resetTooltip() end
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
			BagSyncOpt["enableTooltipSeperator"] = false
			if BagSync then BagSync:resetTooltip() end
		end
	end
end)
local bgs_EnableBagSyncTooltipsSeperator_OptText = bgs_EnableBagSyncTooltipsSeperator_Opt:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
bgs_EnableBagSyncTooltipsSeperator_OptText:SetPoint("LEFT", bgs_EnableBagSyncTooltipsSeperator_Opt, "RIGHT", 0, 1)
bgs_EnableBagSyncTooltipsSeperator_OptText:SetText(L["Enable empty line seperator above BagSync tooltip display."])
