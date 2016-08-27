
local BSYC = select(2, ...) --grab the addon namespace
local Blacklist = BSYC:NewModule("Blacklist")

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync", true)
local AceGUI = LibStub("AceGUI-3.0")

function Blacklist:OnEnable()

	--lets create our widgets
	local BlacklistFrame = AceGUI:Create("Window")
	Blacklist.frame = BlacklistFrame

	BlacklistFrame:SetTitle("BagSync - "..L.Blacklist)
	BlacklistFrame:SetHeight(500)
	BlacklistFrame:SetWidth(380)
	BlacklistFrame:EnableResize(false)
	

	local editbox = AceGUI:Create("EditBox")
	editbox:SetText()
	editbox:SetWidth(357)
	editbox.disablebutton = true --disable the okay button
	editbox:SetCallback("OnEnterPressed",function(widget)
		editbox:ClearFocus()
	end)
	
	Blacklist.editbox = editbox
	BlacklistFrame:AddChild(editbox)
	
	local w = AceGUI:Create("SimpleGroup")
	w:SetLayout("Flow")
	w:SetFullWidth(true)
	BlacklistFrame:AddChild(w)
	
	local addbutton = AceGUI:Create("Button")
	addbutton:SetText(L.AddItemID)
	addbutton:SetWidth(150)
	addbutton:SetHeight(20)
	addbutton:SetCallback("OnClick", function()
		editbox:ClearFocus()
		self:AddItemID()
	end)
	w:AddChild(addbutton)
	
	local removebutton = AceGUI:Create("Button")
	removebutton:SetText(L.RemoveItemID)
	removebutton:SetWidth(150)
	removebutton:SetHeight(20)
	removebutton:SetCallback("OnClick", function()
		editbox:ClearFocus()
		self:RemoveItemID()
	end)
	w:AddChild(removebutton)
	
	local scrollframe = AceGUI:Create("ScrollFrame");
	scrollframe:SetFullWidth(true)
	scrollframe:SetLayout("Flow")

	Blacklist.scrollframe = scrollframe
	BlacklistFrame:AddChild(scrollframe)

	hooksecurefunc(BlacklistFrame, "Show" ,function()
		self:DisplayList()
	end)

	BlacklistFrame:Hide()
end

function Blacklist:AddItemID()
	local itemid = self.editbox:GetText()
	
	if string.len(self.editbox:GetText()) < 1 or not tonumber(itemid) then
		BSYC:Print(L.EnterItemID)
		return
	end
	
	if BSYC.db.blacklist[BSYC.currentRealm][tonumber(itemid)] then
		BSYC:Print(L.ItemIDExist:format(tonumber(itemid)))
		return
	end
	
	if not GetItemInfo(tonumber(self.editbox:GetText())) then
		BSYC:Print(L.ItemIDNotValid:format(tonumber(itemid)))
		return
	end
	
	local dName, dItemLink = GetItemInfo(tonumber(itemid))
	
	BSYC.db.blacklist[BSYC.currentRealm][tonumber(itemid)] = true
	BSYC:Print(L.ItemIDAdded:format(tonumber(itemid)), dItemLink)
	
	self.editbox:SetText()
	
	self:DisplayList()
end

function Blacklist:RemoveItemID()
	local itemid = self.editbox:GetText()
	
	if string.len(self.editbox:GetText()) < 1 or not tonumber(itemid) then
		BSYC:Print(L.EnterItemID)
		return
	end

	if not BSYC.db.blacklist[BSYC.currentRealm][tonumber(itemid)] then
		BSYC:Print(L.ItemIDNotFound:format(tonumber(itemid)))
		return
	end
	
	BSYC.db.blacklist[BSYC.currentRealm][tonumber(itemid)] = nil
	BSYC:Print(L.ItemIDRemoved:format(tonumber(itemid)))
	
	self.editbox:SetText()
	
	self:DisplayList()
end

function Blacklist:AddEntry(entry)

	local highlightColor = {1, 0, 0}
	local label = AceGUI:Create("InteractiveLabel")

	label:SetText(entry)
	label:SetFont("Fonts\\FRIZQT__.TTF", 14, THICKOUTLINE)
	label:SetFullWidth(true)
	label:SetColor( r, g, b)
	label:SetCallback(
		"OnClick", 
		function (widget, sometable, button)
			self.editbox:SetText(entry)
		end)
	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			label:SetColor(unpack(highlightColor))
			GameTooltip:SetOwner(label.frame, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:SetHyperlink("item:"..entry)
			GameTooltip:Show()
		end)
	label:SetCallback(
		"OnLeave",
		function (widget, sometable)
			label:SetColor(r, g, b)
			GameTooltip:Hide()
		end)

	self.scrollframe:AddChild(label)
end

function Blacklist:DisplayList()
	
	self.scrollframe:ReleaseChildren() --clear out the scrollframe
	
	local searchTable = {}
	local count = 0
	
	--loop through our blacklist
	for k, v in pairs(BSYC.db.blacklist[BSYC.currentRealm]) do
		table.insert(searchTable, k)
		count = count + 1
	end

	--show or hide the scrolling frame depending on count
	if count > 0 then
		table.sort(searchTable, function(a,b) return (a < b) end)
		for i=1, #searchTable do
			self:AddEntry(searchTable[i])
		end
		self.scrollframe.frame:Show()
	else
		self.scrollframe.frame:Hide()
	end
	
end