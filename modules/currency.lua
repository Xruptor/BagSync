--[[
	currency.lua
		A currency frame for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Currency = BSYC:NewModule("Currency")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
local function Debug(...)
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", "CURRENCY")
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local AceGUI = LibStub("AceGUI-3.0")

function Currency:OnEnable()

	--lets create our widgets
	local CurrencyFrame = AceGUI:Create("Window")
	Currency.frame = CurrencyFrame
	Currency.parentFrame = CurrencyFrame.frame

	CurrencyFrame:SetTitle("BagSync - "..L.Currency)
	CurrencyFrame:SetHeight(500)
	CurrencyFrame:SetWidth(380)
	CurrencyFrame:EnableResize(false)
	
	local scrollframe = AceGUI:Create("ScrollFrame");
	scrollframe:SetFullWidth(true)
	scrollframe:SetLayout("Flow")

	Currency.scrollframe = scrollframe
	CurrencyFrame:AddChild(scrollframe)

	hooksecurefunc(CurrencyFrame, "Show" ,function()
		self:DisplayList()
	end)
	
	CurrencyFrame:Hide()
	
end

function Currency:AddEntry(entry, isHeader)

	local highlightColor = {1, 0, 0}
	local label = AceGUI:Create("BagSyncInteractiveLabel")

	label.userdata.color = {1, 1, 1}

	label:SetHeaderHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	label:ToggleHeaderHighlight(false)

	if isHeader then
		label:SetText(entry.header)
		label:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label:SetColor(unpack(label.userdata.color))
		label:ApplyJustifyH("CENTER")
		label.userdata.isHeader = true
		label.userdata.text = entry.header
		label.userdata.icon = entry.icon
		label.userdata.currencyID = entry.currencyID
		
		label:ToggleHeaderHighlight(true)
	else
		label:SetText(entry.name)
		label:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label.userdata.color = {64/255, 224/255, 208/255} --hex: 40e0d0
		label:SetColor(unpack(label.userdata.color))
		label:ApplyJustifyH("LEFT")
		label:SetImage(entry.icon)
		label:SetImageSize(18, 18)
		label.userdata.isHeader = false
		label.userdata.text = entry.name
		label.userdata.icon = entry.icon
		label.userdata.currencyID = entry.currencyID
	end

	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			if not label.userdata.isHeader then
				label:SetColor(unpack(highlightColor))
				GameTooltip:SetOwner(label.frame, "ANCHOR_RIGHT")
				if not label.userdata.isHeader then
					Tooltip:CurrencyTooltip(GameTooltip, label.userdata.text, label.userdata.icon, label.userdata.currencyID)
				end
			end
		end)
	label:SetCallback(
		"OnLeave",
		function (widget, sometable)
			label:SetColor(unpack(label.userdata.color))
			GameTooltip:Hide()
		end)

	self.scrollframe:AddChild(label)
end

function Currency:DisplayList()

	self.scrollframe:ReleaseChildren() --clear out the scrollframe
	
	local usrData = {}
	local tempList = {}

	for unitObj in Data:IterateUnits() do
		if not unitObj.isGuild and unitObj.data.currency then
			for k, v in pairs(unitObj.data.currency) do
				--only do the entry once per heading and name
				if not tempList[v.header..v.name] then
					table.insert(usrData, { header=v.header, name=v.name, icon=v.icon, currencyID=k} )
					tempList[v.header..v.name] = true
				end
			end
		end
	end
	
	if table.getn(usrData) > 0 then
	
		--sort the list by header, name
		table.sort(usrData, function(a, b)
			if a.header  == b.header then
				return a.name < b.name;
			end
			return a.header < b.header;
		end)
	
		local lastHeader = ""
		for i=1, #usrData do
			if lastHeader ~= usrData[i].header then
				self:AddEntry(usrData[i], true) --add header
				self:AddEntry(usrData[i], false) --add entry
				lastHeader = usrData[i].header
			else
				self:AddEntry(usrData[i], false) --add entry
			end
		end
		self.scrollframe.frame:Show()
	else
		self.scrollframe.frame:Hide()
	end
	
end