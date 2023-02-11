--[[
	whitelist.lua
		A whitelist frame for BagSync items
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Whitelist = BSYC:NewModule("Whitelist")

local function Debug(level, ...)
    if BSYC.DEBUG then BSYC.DEBUG(level, "Whitelist", ...) end
end

local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local AceGUI = LibStub("AceGUI-3.0")

function Whitelist:OnEnable()

	--lets create our widgets
	local WhitelistFrame = AceGUI:Create("Window")
	_G["BagSyncWhitelistFrame"] = WhitelistFrame
    --Add to special frames so window can be closed when the escape key is pressed.
    tinsert(UISpecialFrames, "BagSyncWhitelistFrame")
	Whitelist.frame = WhitelistFrame
	Whitelist.parentFrame = WhitelistFrame.frame

	WhitelistFrame:SetTitle("BagSync - "..L.Whitelist)
	WhitelistFrame:SetHeight(500)
	WhitelistFrame:SetWidth(380)
	WhitelistFrame:EnableResize(false)

	local editbox = AceGUI:Create("EditBox")
	editbox:SetText()
	editbox:SetWidth(357)
	editbox.disablebutton = true --disable the okay button
	editbox:SetCallback("OnEnterPressed",function(widget)
		editbox:ClearFocus()
	end)

	Whitelist.editbox = editbox
	WhitelistFrame:AddChild(editbox)

	local w = AceGUI:Create("SimpleGroup")
	w:SetLayout("List")
	w:SetFullWidth(true)
	WhitelistFrame:AddChild(w)

	local addbutton = AceGUI:Create("Button")
	addbutton:SetText(L.AddItemID)
	addbutton:SetWidth(160)
	addbutton:SetHeight(20)
	addbutton:SetCallback("OnClick", function()
		editbox:ClearFocus()
		self:AddItemID()
	end)
	w:AddChild(addbutton)

	local spacer = AceGUI:Create("BagSyncLabel")
    spacer:SetFullWidth(true)
	spacer:SetText(" ")
	WhitelistFrame:AddChild(spacer)

	------------------------------------------
	--Scrollframe has to be in its own group with Fill set
	--otherwise it will always be a fixed height based on how many child elements
	local q = AceGUI:Create("SimpleGroup")
	q:SetLayout("Fill")
	q:SetFullWidth(true)
	q:SetHeight(390)
	WhitelistFrame:AddChild(q)

	local scrollframe = AceGUI:Create("ScrollFrame");
	scrollframe:SetFullWidth(true)
	scrollframe:SetLayout("Flow")

	Whitelist.scrollframe = scrollframe
	q:AddChild(scrollframe)

	----------------------------------------------------------
	----------------------------------------------------------
	-------  WARNING FRAME

	local WLInfoFrame = AceGUI:Create("Window")
	WLInfoFrame:SetTitle(L.DisplayWhitelistHelp)
	WLInfoFrame:SetWidth(300)
	WLInfoFrame:SetHeight(280)
	WLInfoFrame.frame:SetParent(WhitelistFrame.frame)
	WLInfoFrame:SetLayout("Flow")
	WLInfoFrame:EnableResize(false)

	local wl_infolabel = AceGUI:Create("BagSyncLabel")
	wl_infolabel:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
	wl_infolabel:SetColor(1, 165/255, 0) --orange, red is just too much sometimes
	wl_infolabel:SetFullWidth(true)
	WLInfoFrame:AddChild(wl_infolabel)

	local wl_infolabel2 = AceGUI:Create("BagSyncLabel")
	wl_infolabel2:SetText(L.DisplayWhitelistHelpInfo)
	wl_infolabel2:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
	wl_infolabel2:SetColor(50/255, 165/255, 0)
	wl_infolabel2:SetFullWidth(true)
	WLInfoFrame:AddChild(wl_infolabel2)

	Whitelist.WLInfoFrame = WLInfoFrame
	Whitelist.wl_infolabel = wl_infolabel

	hooksecurefunc(WLInfoFrame, "Show" ,function()
		--always show the info frame on the right of the whitelist window
		WLInfoFrame.frame:ClearAllPoints()
		WLInfoFrame:SetPoint( "TOPLEFT", WhitelistFrame.frame, "TOPRIGHT", 0, 0)

		local getStatus = (BSYC.options.enableWhitelist and ("|cFF99CC33"..L.ON.."|r")) or ( "|cFFDF2B2B"..L.OFF.."|r")
		wl_infolabel:SetText(L.DisplayWhitelistStatus:format(getStatus))
	end)

	--hide the info window if they close the whitelist window
	WhitelistFrame:SetCallback("OnClose",function(widget)
		WLInfoFrame:Hide()
	end)

	WLInfoFrame:Show()
	----------------------------------------------------------
	----------------------------------------------------------

	hooksecurefunc(WhitelistFrame, "Show" ,function()
		self:DisplayList()
		WLInfoFrame:Show()
	end)

	StaticPopupDialogs["BAGSYNC_WHITELIST_REMOVE"] = {
		text = L.WhiteListRemove,
		button1 = "Yes",
		button2 = "No",
		hasEditBox = false,
		timeout = 0,
		exclusive = 1,
		hideOnEscape = 1,
		OnShow = function (self)
			self.text:SetText(L.WhiteListRemove:format(self.data.value));
		end,
		OnAccept = function (self)
			if BSYC.db.whitelist[self.data.key] then
				if type(self.data.key) == "number" then
					BSYC:Print(L.ItemIDRemoved:format(self.data.value))
				end
				BSYC.db.whitelist[self.data.key] = nil
				Whitelist:DisplayList()
			else
				BSYC:Print(L.WhiteListErrorRemove)
			end
		end,
		whileDead = 1,
	}

	WhitelistFrame:Hide()
end

function Whitelist:AddItemID()
	local itemid = self.editbox:GetText()

	if not itemid or string.len(self.editbox:GetText()) < 1 or not tonumber(itemid) then
		BSYC:Print(L.EnterItemID)
		self.editbox:SetText()
		return
	end

	itemid = tonumber(itemid)

	if BSYC.db.whitelist[itemid] then
		BSYC:Print(L.ItemIDExistWhitelist:format(itemid))
		self.editbox:SetText()
		return
	end

	local dName, dItemLink

	if itemid >= BSYC.FakePetCode then
		local fakeID, fakeLink

		if C_PetJournal then
			fakeID, fakeLink = BSYC:FakeIDToBattlePetID(itemid)
			if fakeID and fakeLink then
				dName = C_PetJournal.GetPetInfoBySpeciesID(fakeID)
				dItemLink = "["..dName.."] - "..fakeLink
			end
		end

		if not fakeID then
			BSYC:Print(L.ItemIDNotValid:format(itemid))
			self.editbox:SetText()
			return
		end
	else
		dName, dItemLink = GetItemInfo(itemid)
	end

	if not dName then
		BSYC:Print(L.ItemIDNotValid:format(itemid))
		self.editbox:SetText()
		return
	end

	BSYC.db.whitelist[itemid] = dName
	BSYC:Print(L.ItemIDAdded:format(itemid), dItemLink)

	self.editbox:SetText()

	self:DisplayList()
end

function Whitelist:AddEntry(entry)

	local label = AceGUI:Create("InteractiveLabel")

	label:SetText(entry.value)
	label:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
	label:SetFullWidth(true)
	label:SetColor(1, 1, 1)
	label:SetCallback(
		"OnClick",
		function (widget, sometable, button)
			StaticPopup_Show("BAGSYNC_WHITELIST_REMOVE", '', '', entry) --cannot pass nil as it's expected for SetFormattedText (Interface/FrameXML/StaticPopup.lua)
		end)
	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			label:SetColor(1, 0, 0)
			GameTooltip:SetOwner(label.frame, "ANCHOR_BOTTOMRIGHT")
			if type(entry.key) == "number" then
				if entry.key >= BSYC.FakePetCode then
					local fakeID, fakeLink = BSYC:FakeIDToBattlePetID(entry.key)
					if fakeID then
						BattlePetToolTip_Show(fakeID, 0, 0, 0, 0, 0, nil, nil)
					end
				else
					GameTooltip:SetHyperlink("item:"..entry.key)
				end
			end
			GameTooltip:Show()
		end)
	label:SetCallback(
		"OnLeave",
		function (widget, sometable)
			label:SetColor(1, 1, 1)
			if type(entry.key) == "number" then
				if entry.key >= BSYC.FakePetCode then
					BattlePetTooltip:Hide()
				else
					GameTooltip:Hide()
				end
			end
			GameTooltip:Hide()
		end)

	self.scrollframe:AddChild(label)
end

function Whitelist:DisplayList()

	self.scrollframe:ReleaseChildren() --clear out the scrollframe

	local whitelistTable = {}

	--loop through our whitelist
	for k, v in pairs(BSYC.db.whitelist) do
		table.insert(whitelistTable, {key=k, value=v})
	end

	--show or hide the scrolling frame depending on count
	if #whitelistTable > 0 then
		table.sort(whitelistTable, function(a,b) return (a.value < b.value) end)
		for i=1, #whitelistTable do
			self:AddEntry(whitelistTable[i])
		end
		self.scrollframe.frame:Show()
	else
		self.scrollframe.frame:Hide()
	end

end