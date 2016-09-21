
local BSYC = select(2, ...) --grab the addon namespace
local Currency = BSYC:NewModule("Currency")

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
		label:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label:SetColor(unpack(label.userdata.color))
		label:ApplyJustifyH("CENTER")
		label.userdata.isHeader = true
		label.userdata.text = entry.header
		label:ToggleHeaderHighlight(true)
	else
		label:SetText(entry.name)
		label:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
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
	
	local xDB = BSYC:FilterDB(2) --dbSelect 2
	
	--loop through our database and collect the currenry headers
	for k, v in pairs(xDB) do
		--no need to split to get playername and realm as it's not important, we let AddCurrencyTooltip() handle that
		--loop through each player table and grab only the headers and insert it into a temp table if it doesn't already exist
		for q, r in pairs(v) do
			if not tempList[q] then
				--we only really want to list the currency once for display
				table.insert(tmp, { header=r.header, icon=r.icon, name=q} )
				tempList[q] = true
				count = count + 1
			end
		end
	end
		
	--show or hide the scrolling frame depending on count
	if count > 0 then
		table.sort(tmp, function(a,b)
			if a.header < b.header then
				return true;
			elseif a.header == b.header then
				return (a.name < b.name);
			end
		end)
		
		local lastHeader = ""
		for i=1, #tmp do
			if lastHeader ~= tmp[i].header then
				self:AddEntry(tmp[i], true) --add header
				self:AddEntry(tmp[i], false) --add entry
				lastHeader = tmp[i].header
			else
				self:AddEntry(tmp[i], false) --add entry
			end
		end
		self.scrollframe.frame:Show()
	else
		self.scrollframe.frame:Hide()
	end
	
end