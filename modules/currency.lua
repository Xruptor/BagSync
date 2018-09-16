--[[
	currency.lua
		A currency frame for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Currency = BSYC:NewModule("Currency")
local Unit = BSYC:GetModule("Unit")
local Data = BSYC:GetModule("Data")
local Tooltip = BSYC:GetModule("Tooltip")

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync", true)
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
		label:SetFont(L.GetFontType, 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label:SetColor(unpack(label.userdata.color))
		label:ApplyJustifyH("CENTER")
		label.userdata.isHeader = true
		label.userdata.text = entry.header
		label:ToggleHeaderHighlight(true)
	else
		label:SetText(entry.name)
		label:SetFont(L.GetFontType, 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label.userdata.color = {64/255, 224/255, 208/255}
		label:SetColor(unpack(label.userdata.color))
		label:ApplyJustifyH("LEFT")
		label.userdata.isHeader = false
		label.userdata.text = entry.name
	end

	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			label:SetColor(unpack(highlightColor))
			GameTooltip:SetOwner(label.frame, "ANCHOR_BOTTOMRIGHT")
			if not label.userdata.isHeader then
				BSYC:AddCurrencyTooltip(GameTooltip, label.userdata.text, true)
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

	local tmp = {}
	local tempList = {}
	local count = 0

	self.scrollframe:ReleaseChildren() --clear out the scrollframe
	
	
	local usrData = {}
	local total = 0
	local player = Unit:GetUnitInfo()

	for unitObj in Data:IterateUnits() do
		if not unitObj.isGuild and unitObj.data.currency then
			for k, v in pairs(unitObj.unitObj.data.currency) do

				table.insert(usrData, { header=v.header, name=v.name, count=v.count, colorized=Tooltip:ColorizeUnit(unitObj), sortIndex=Tooltip:GetSortIndex(unitObj) } )
			end
		end
	end
	
	--sort the list by our sortIndex then by realm and finally by name
	table.sort(usrData, function(a, b)
		if a.header  == b.header then
			if a.name == b.name then
				if a.sortIndex  == b.sortIndex then
					if a.unitObj.realm == b.unitObj.realm then
						return a.unitObj.name < b.unitObj.name;
					end
					return a.unitObj.realm < b.unitObj.realm;
				end
				return a.sortIndex < b.sortIndex;
			end
			return a.name < b.name;
		end
		return a.header < b.header;
	end)
	
	--show or hide the scrolling frame depending on count
	-- if count > 0 then
		-- table.sort(tmp, function(a,b)
			-- if a.header < b.header then
				-- return true;
			-- elseif a.header == b.header then
				-- return (a.name < b.name);
			-- end
		-- end)
		
		-- local lastHeader = ""
		-- for i=1, #tmp do
			-- if lastHeader ~= tmp[i].header then
				-- self:AddEntry(tmp[i], true) --add header
				-- self:AddEntry(tmp[i], false) --add entry
				-- lastHeader = tmp[i].header
			-- else
				-- self:AddEntry(tmp[i], false) --add entry
			-- end
		-- end
		-- self.scrollframe.frame:Show()
	-- else
		-- self.scrollframe.frame:Hide()
	-- end
	
end