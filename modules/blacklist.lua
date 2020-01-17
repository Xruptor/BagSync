--[[
	blacklist.lua
		A blacklist frame for BagSync items
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Blacklist = BSYC:NewModule("Blacklist")
local Data = BSYC:GetModule("Data")
local Unit = BSYC:GetModule("Unit")

local debugf = tekDebug and tekDebug:GetFrame("BagSync")
local function Debug(...)
    if debugf then
		local debugStr = string.join(", ", tostringall(...))
		local moduleName = string.format("|cFFffff00[%s]|r: ", "BLACKLIST")
		debugStr = moduleName..debugStr
		debugf:AddMessage(debugStr)
	end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
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
	w:SetLayout("List")
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
	
	local spacer = AceGUI:Create("Label")
    spacer:SetFullWidth(true)
	spacer:SetText(" ")
	BlacklistFrame:AddChild(spacer)
	
	------------------------------------------
	--Scrollframe has to be in its own group with Fill set
	--otherwise it will always be a fixed height based on how many child elements
	local q = AceGUI:Create("SimpleGroup")
	q:SetLayout("Fill")
	q:SetFullWidth(true)
	q:SetHeight(390)
	BlacklistFrame:AddChild(q)
	
	local scrollframe = AceGUI:Create("ScrollFrame");
	scrollframe:SetFullWidth(true)
	scrollframe:SetLayout("Flow")

	Blacklist.scrollframe = scrollframe
	q:AddChild(scrollframe)
	------------------------------------------

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
	
	guildAddButton:SetCallback("OnClick", function()
		if not guildDDlist:GetValue() then return end
		
		if BSYC.db.blacklist[guildDDlist:GetValue()] then
			BSYC:Print(L.GuildExist:format(guildDDlist.text:GetText()))
			guildDDlist:SetValue(nil) --reset
			return
		end
		
		BSYC.db.blacklist[guildDDlist:GetValue()] = guildDDlist.text:GetText()
		BSYC:Print(L.GuildAdded:format(guildDDlist.text:GetText()))
		guildDDlist:SetValue(nil) --reset
		
		self:DisplayList()
	end)
	
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

	StaticPopupDialogs["BAGSYNC_BLACKLIST_REMOVE"] = {
		text = L.BlackListRemove,
		button1 = "Yes",
		button2 = "No",
		hasEditBox = false,
		timeout = 0,
		exclusive = 1,
		hideOnEscape = 1,
		OnShow = function (self)
			self.text:SetText(L.BlackListRemove:format(self.data.value));
		end,
		OnAccept = function (self)
			if BSYC.db.blacklist[self.data.key] then
				if type(self.data.key) == "number" then
					BSYC:Print(L.ItemIDRemoved:format(self.data.value))
				else
					BSYC:Print(L.GuildRemoved:format(self.data.value))
				end
				BSYC.db.blacklist[self.data.key] = nil
				Blacklist:DisplayList()
			else
				BSYC:Print(L.BlackListErrorRemove)
			end
		end,
		whileDead = 1,
	}

	BlacklistFrame:Hide()
end

function Blacklist:AddItemID()
	local itemid = self.editbox:GetText()
	
	if string.len(self.editbox:GetText()) < 1 or not tonumber(itemid) then
		BSYC:Print(L.EnterItemID)
		self.editbox:SetText()
		return
	end
	
	itemid = tonumber(itemid)
	
	if BSYC.db.blacklist[itemid] then
		BSYC:Print(L.ItemIDExist:format(itemid))
		self.editbox:SetText()
		return
	end
	
	if not GetItemInfo(itemid) then
		BSYC:Print(L.ItemIDNotValid:format(itemid))
		self.editbox:SetText()
		return
	end
	
	local dName, dItemLink = GetItemInfo(itemid)
	
	BSYC.db.blacklist[itemid] = dName
	BSYC:Print(L.ItemIDAdded:format(itemid), dItemLink)
	
	self.editbox:SetText()
	
	self:DisplayList()
end

function Blacklist:AddEntry(entry)

	local label = AceGUI:Create("InteractiveLabel")

	label:SetText(entry.value)
	label:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
	label:SetFullWidth(true)
	label:SetColor(1, 1, 1)
	label:SetCallback(
		"OnClick", 
		function (widget, sometable, button)
			StaticPopup_Show("BAGSYNC_BLACKLIST_REMOVE", '', '', entry) --cannot pass nil as it's expected for SetFormattedText (Interface/FrameXML/StaticPopup.lua)
		end)
	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			label:SetColor(1, 0, 0)
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
			label:SetColor(1, 1, 1)
			GameTooltip:Hide()
		end)

	self.scrollframe:AddChild(label)
end

function Blacklist:DisplayList()
	
	self.scrollframe:ReleaseChildren() --clear out the scrollframe
	
	local blacklistTable = {}

	--loop through our blacklist
	for k, v in pairs(BSYC.db.blacklist) do
		table.insert(blacklistTable, {key=k, value=v})
	end

	--show or hide the scrolling frame depending on count
	if table.getn(blacklistTable) > 0 then
		table.sort(blacklistTable, function(a,b) return (a.value < b.value) end)
		for i=1, #blacklistTable do
			self:AddEntry(blacklistTable[i])
		end
		self.scrollframe.frame:Show()
	else
		self.scrollframe.frame:Hide()
	end
	
end