--[[
	blacklist.lua
		A blacklist frame for BagSync items
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Blacklist = BSYC:NewModule("Blacklist")
local Data = BSYC:GetModule("Data")
local Unit = BSYC:GetModule("Unit")

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
	addbutton:SetWidth(160)
	addbutton:SetHeight(20)
	addbutton:SetCallback("OnClick", function()
		editbox:ClearFocus()
		self:AddItemID()
	end)
	w:AddChild(addbutton)
	
	local scrollframe = AceGUI:Create("ScrollFrame");
	scrollframe:SetFullWidth(true)
	scrollframe:SetLayout("Flow")

	Blacklist.scrollframe = scrollframe
	BlacklistFrame:AddChild(scrollframe)

	--do the guild dropdown box on right
	-----------------------------------------------------
	local guildFrame = AceGUI:Create("Window")
	local guildAddButton = AceGUI:Create("Button")
	local guildDDlist = AceGUI:Create("Dropdown")

	Blacklist.guildFrame = guildFrame
	Blacklist.guildAddButton = guildAddButton
	Blacklist.guildDDlist = guildDDlist

	local spacer = AceGUI:Create("Label")
    spacer:SetFullWidth(true)
	spacer:SetText(" ")
	
	guildFrame:AddChild(guildDDlist)
	guildFrame:AddChild(spacer)
	guildFrame:AddChild(guildAddButton)

	guildFrame:SetTitle(L.TooltipGuild)
	guildFrame:SetHeight(120)
	guildFrame:SetWidth(330)
	guildFrame:EnableResize(false)
	guildFrame:ClearAllPoints()
	guildFrame:SetPoint("TOPLEFT", BlacklistFrame.frame, "TOPRIGHT", 0, 0)
	guildFrame.closebutton:Hide()
	guildFrame.closebutton = nil
	
	guildDDlist:SetWidth(300)
	guildAddButton:SetWidth(100)
	guildAddButton:SetText(L.AddGuild)
	-----------------------------------------------------
	
	hooksecurefunc(BlacklistFrame, "Show" ,function()
		guildFrame:Show()
	
		local tmp = {}
		for unitObj in Data:IterateUnits() do
			if unitObj.isGuild then
				local guildName = select(2, Unit:GetUnitAddress(unitObj.name))
				local key = unitObj.name..unitObj.data.realmKey --note key is different then displayed name
				tmp[key] = guildName.."-"..unitObj.data.realmKey
			end
		end
		table.sort(tmp, function(a,b) return (a < b) end)
		guildDDlist:SetList(tmp)
		
		self:DisplayList()
	end)
	hooksecurefunc(BlacklistFrame, "Hide" ,function()
		guildFrame:Hide()
	end)

	BlacklistFrame:Hide()
end

function Blacklist:AddItemID()
	local itemid = self.editbox:GetText()
	
	if string.len(self.editbox:GetText()) < 1 or not tonumber(itemid) then
		BSYC:Print(L.EnterItemID)
		return
	end
	
	--if BSYC.db.blacklist[BSYC.currentRealm][tonumber(itemid)] then
	--	BSYC:Print(L.ItemIDExist:format(tonumber(itemid)))
	--	return
	--end
	
	--if not GetItemInfo(tonumber(self.editbox:GetText())) then
	--	BSYC:Print(L.ItemIDNotValid:format(tonumber(itemid)))
	--	return
	--end
	
	--local dName, dItemLink = GetItemInfo(tonumber(itemid))
	
	--BSYC.db.blacklist[BSYC.currentRealm][tonumber(itemid)] = true
	--BSYC:Print(L.ItemIDAdded:format(tonumber(itemid)), dItemLink)
	
	--self.editbox:SetText()
	
	self:DisplayList()
end

function Blacklist:RemoveItemID()
	local itemid = self.editbox:GetText()
	
	-- if string.len(self.editbox:GetText()) < 1 or not tonumber(itemid) then
		-- BSYC:Print(L.EnterItemID)
		-- return
	-- end

	-- if not BSYC.db.blacklist[BSYC.currentRealm][tonumber(itemid)] then
		-- BSYC:Print(L.ItemIDNotFound:format(tonumber(itemid)))
		-- return
	-- end
	
	-- BSYC.db.blacklist[BSYC.currentRealm][tonumber(itemid)] = nil
	-- BSYC:Print(L.ItemIDRemoved:format(tonumber(itemid)))
	
	-- self.editbox:SetText()
	
	self:DisplayList()
end

function Blacklist:AddEntry(entry)

	local highlightColor = {1, 0, 0}
	local label = AceGUI:Create("InteractiveLabel")

	label:SetText(entry.value)
	label:SetFont(L.GetFontType, 14, THICKOUTLINE)
	label:SetFullWidth(true)
	label:SetColor( r, g, b)
	label:SetCallback(
		"OnClick", 
		function (widget, sometable, button)
			self.editbox:SetText(entry.value)
			self.editbox.dbValue = entry
		end)
	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			label:SetColor(unpack(highlightColor))
			self.editbox.dbValue = entry
			GameTooltip:SetOwner(label.frame, "ANCHOR_BOTTOMRIGHT")
			if type(entry.key) == "number" then
				GameTooltip:SetHyperlink("item:"..entry.key)
			else
				GameTooltip:AddLine(entry.value)
				GameTooltip:AddLine(L.TooltipRealmKey.." "..entry.key)
			end
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

	--loop through our blacklist
	for k, v in pairs(BSYC.db.blacklist) do
		table.insert(searchTable, {key=k, value=v})
	end

	--show or hide the scrolling frame depending on count
	if table.getn(searchTable) > 0 then
		table.sort(searchTable, function(a,b) return (a.value < b.value) end)
		for i=1, #searchTable do
			self:AddEntry(searchTable[i])
		end
		self.scrollframe.frame:Show()
	else
		self.scrollframe.frame:Hide()
	end
	
end