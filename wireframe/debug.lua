--[[
	debug.lua
		Provides some debugging information to assist in squashing bugs.

		BagSync - All Rights Reserved - (c) 2006-2023
		License included with addon.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local Debug = BSYC:NewModule("Debug")

local AceGUI = LibStub("AceGUI-3.0")

local xListLen = 400
local debugWidth = 880
local debugHeight = 450

local function unescape(str)
    str = gsub(str, "|T.-|t", "") --textures in chat like currency coins and such
	str = gsub(str, "|H.-|h(.-)|h", "%1") --links, just put the item description and chat color
	str = gsub(str, "{.-}", "") --remove raid icons from chat

    return str
end

local function SetExportFrameText(pageNum)
	if not Debug.exportFrame then return end

	Debug.exportFrame.MLEditBox:SetText("") --clear it first in case there were previous messages
	Debug.exportFrame.currChatIndex = chatIndex

	--the editbox of the multiline editbox (The parent of the multiline object)
	local parentEditBox = Debug.exportFrame.MLEditBox.editBox

	--there is a hard limit of text that can be highlighted in an editbox to 500 lines.
	local MAXLINES = 150 --150 don't use large numbers or it will cause LAG when frame opens.  EditBox was not made for large amounts of text
	local msgCount = #Debug.scrollframe.children
	local startPos = 0
	local endPos = 0
	local lineText

	--lets create the pages
	local pages = {}
	local pageCount = 0 --start at zero
	for i = 1, msgCount, MAXLINES do
	  pageCount = i-1 --the block will extend by 1 past 150, so subtract 1
	  if pageCount <= 0 then pageCount = 1 end --this is the first page, so start at 1
	  table.insert(pages, pageCount)
	end

	--load past page if we don't have a pageNum
	if not pageNum and startPos < 1 then
		if msgCount > MAXLINES then
			startPos = msgCount - MAXLINES
			endPos = startPos + MAXLINES
		else
			startPos = 1
			endPos = msgCount
		end
	--otherwise load the page number
	elseif pageNum and pages[pageNum] then
		if pages[pageNum] == 1 then
			--first page
			startPos = 1
			endPos = MAXLINES
		else
			startPos = pages[pageNum]
			endPos = pages[pageNum] + MAXLINES
		end
	else
		return
	end

	--adjust the endPos if it's greater than the total messages we have
	if endPos > msgCount then endPos = msgCount end

	for i = startPos, endPos do

		local tmpObj = Debug.scrollframe.children[i]

		if tmpObj and tmpObj.label then
			lineText = tmpObj.label:GetText()
		else
			break
		end

		--we add |r at the end to break any color codes that don't terminate properly and will taint the next lines
		if (i == startPos) then
			lineText = unescape(lineText).."|r"
		else
			lineText = "\n"..unescape(lineText).."|r"
		end

		parentEditBox:Insert(lineText)
	end

	if pageNum then
		Debug.exportFrame.currentPage = pageNum
	else
		Debug.exportFrame.currentPage = #pages
	end

	Debug.exportFrame.pages = pages
	Debug.exportFrame.pageNumText:SetText(L.Page.." "..Debug.exportFrame.currentPage)

	Debug.exportFrame.handleCursorChange = true -- just in case
	Debug.exportFrame:Show()
end

local function CreateExportFrame()
	--check to see if we have the frame already, if we do then return it
	if Debug.exportFrame then return Debug.exportFrame end

	local exportFrame = CreateFrame("FRAME", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	exportFrame:SetClampedToScreen(true)

	exportFrame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 }
	})
	exportFrame:SetBackdropColor(0, 0, 0, 1)
	exportFrame:EnableMouse(true)
	exportFrame:SetFrameStrata("DIALOG")
	exportFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	exportFrame:SetWidth(830)
	exportFrame:SetHeight(490)

	local group = AceGUI:Create("InlineGroup")
	group.frame:SetParent(exportFrame)
	group.frame:SetPoint("BOTTOMRIGHT", exportFrame, "BOTTOMRIGHT", -17, 12)
	group.frame:SetPoint("TOPLEFT", exportFrame, "TOPLEFT", 17, -10)
	group.frame:Hide()
	group:SetLayout("fill")
	group.frame:Show() --show the group so everything in it displays in the frame

	local MLEditBox = AceGUI:Create("MultiLineEditBox")
	MLEditBox:SetWidth(400)
	MLEditBox.button:Hide()
	MLEditBox.frame:SetClipsChildren(true)
	MLEditBox:SetLabel(L.DebugExport)
    MLEditBox:ClearFocus()
	MLEditBox:SetText("")
	group:AddChild(MLEditBox)
	exportFrame.MLEditBox = MLEditBox

	exportFrame.handleCursorChange = false --setting this to true will update the scrollbar to the cursor position
	MLEditBox.scrollFrame:HookScript("OnUpdate", function(self, elapsed)
		if not MLEditBox.scrollFrame:IsVisible() then return end

		self.OnUpdateCounter = (self.OnUpdateCounter or 0) + elapsed
		if self.OnUpdateCounter < 0.1 then return end
		self.OnUpdateCounter = 0

		local pos = math.max(string.len(MLEditBox:GetText()), MLEditBox.editBox:GetNumLetters())

		if ( exportFrame.handleCursorChange ) then
			MLEditBox:SetFocus()
			MLEditBox:SetCursorPosition(pos)
			MLEditBox:ClearFocus()
			--put the scrollbar button at the max it can go
			local statusMin, statusMax = MLEditBox.scrollBar:GetMinMaxValues()
			MLEditBox.scrollBar:SetValue(statusMax + 100) --extra 100 just in case (sometimes the offset is slightly off)
			exportFrame.handleCursorChange = false
		end

	end)
	exportFrame:HookScript("OnShow", function() exportFrame.handleCursorChange = true end)

	local close = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate")
	close:SetScript("OnClick", function() exportFrame:Hide() end)
	close:SetPoint("BOTTOMRIGHT", -27, 13)
	close:SetFrameLevel(close:GetFrameLevel() + 1)
	close:SetHeight(20)
	close:SetWidth(100)
	close:SetText(L.Done)

    local buttonBack = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate")
    buttonBack:SetText("<")
    buttonBack:SetHeight(25)
    buttonBack:SetWidth(25)
    buttonBack:SetPoint("BOTTOMLEFT", 10, 13)
	buttonBack:SetFrameLevel(buttonBack:GetFrameLevel() + 1)
    buttonBack:SetScript("OnClick", function()
		if exportFrame.currentPage then
			if (exportFrame.currentPage - 1) > 0 then
				SetExportFrameText(exportFrame.currentPage - 1)
			end
		end
    end)
    exportFrame.buttonBack = buttonBack

    local buttonForward = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate")
    buttonForward:SetText(">")
    buttonForward:SetHeight(25)
    buttonForward:SetWidth(25)
    buttonForward:SetPoint("BOTTOMLEFT", 40, 13)
	buttonForward:SetFrameLevel(buttonForward:GetFrameLevel() + 1)
    buttonForward:SetScript("OnClick", function()
		if exportFrame.currentPage and exportFrame.pages then
			if (exportFrame.currentPage + 1) <= #exportFrame.pages then
				SetExportFrameText(exportFrame.currentPage + 1)
			end
		end
    end)
    exportFrame.buttonForward = buttonForward

	--this is to place it above the group layer
	local textFrame = CreateFrame("FRAME", nil, group.frame, BackdropTemplateMixin and "BackdropTemplate")
	textFrame:SetFrameLevel(textFrame:GetFrameLevel() + 1)
	textFrame:SetPoint("BOTTOMLEFT", 80, 18)
	textFrame:Show()

    local pageNumText = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageNumText:SetPoint("LEFT", textFrame)
    pageNumText:SetShadowOffset(1, -1)
    pageNumText:SetText(L.Page.." 1")
	textFrame:SetHeight(pageNumText:GetHeight() + 2)
	textFrame:SetWidth(pageNumText:GetWidth() + 2)
    exportFrame.pageNumText = pageNumText

	exportFrame:Hide()

	--store it for the future
	Debug.exportFrame = exportFrame
end

function Debug:OnEnable()

	--lets create our widgets
	local DebugFrame = AceGUI:Create("Window")
	Debug.frame = DebugFrame

	DebugFrame:SetTitle("BagSync - "..L.Debug)
	DebugFrame:SetHeight(debugHeight)
	DebugFrame:SetWidth(debugWidth)
	DebugFrame:EnableResize(false)
	DebugFrame:SetPoint("CENTER",UIParent,"CENTER",0,120)
	DebugFrame.frame:SetFrameStrata("BACKGROUND")

	--scrollbar:SetMinMaxValues(0, 1000)
	local scrollframe = AceGUI:Create("ScrollFrame");
	scrollframe:SetFullWidth(true)
	scrollframe:SetLayout("Flow")

	Debug.scrollframe = scrollframe
	DebugFrame:AddChild(scrollframe)

	Debug.optionsFrame = CreateFrame("Frame", "OptionsFrame", DebugFrame.frame, BackdropTemplateMixin and "BackdropTemplate")

	local backdrop = {
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
		tile = true,
		tileSize = 16,
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	}

	Debug.optionsFrame:SetHeight(100)
	Debug.optionsFrame:SetWidth(debugWidth)
	Debug.optionsFrame:SetBackdrop(backdrop)
	Debug.optionsFrame:SetBackdropColor(0, 0, 0, 0.6)
	Debug.optionsFrame:SetPoint("TOPLEFT",DebugFrame.frame,"BOTTOMLEFT",0,0)

	local enableDebugChk = AceGUI:Create("CheckBox")
	enableDebugChk:SetLabel(L.DebugEnable)
	enableDebugChk.frame:Show()
	enableDebugChk:SetWidth(enableDebugChk.text:GetStringWidth() + 40) --add length for checkbox and what not
	enableDebugChk.frame:SetParent(Debug.optionsFrame)
	enableDebugChk.frame:SetPoint("TOPLEFT",Debug.optionsFrame,"TOPLEFT",10,-5)
	enableDebugChk:SetCallback("OnValueChanged",function(self, func, checked)
		if BSYC.options and BSYC.options.debug then
			BSYC.options.debug.enable = checked
		end
	end)

	local levels = {
		"DEBUG",
		"INFO",
		"TRACE",
		"WARN",
		"FINE",
		"SL1",
		"SL2",
		"SL3",
	}

	local lastPoint

	Debug.debugLevels = {}

	for k=1, #levels do
		local tmpLevel = AceGUI:Create("CheckBox")
		tmpLevel:SetLabel(L["Debug_"..levels[k]])
		tmpLevel.frame:Show()
		tmpLevel.level = levels[k]
		tmpLevel:SetWidth(tmpLevel.text:GetStringWidth() + 30) --add length for checkbox and what not
		--tmpLevel.text:SetWidth(tmpLevel.text:GetStringHeight())
		tmpLevel.frame:SetParent(Debug.optionsFrame)
		if not lastPoint then
			tmpLevel.frame:SetPoint("BOTTOMLEFT",Debug.optionsFrame,"BOTTOMLEFT",10,5)
		else
			tmpLevel.frame:SetPoint("LEFT",lastPoint.frame,"RIGHT", 10,0)
		end
		lastPoint = tmpLevel

		tmpLevel:SetCallback("OnValueChanged",function(self, func, checked)
			if BSYC.options and BSYC.options.debug then
				BSYC.options.debug[self.level] = checked
			end
		end)

		table.insert(Debug.debugLevels, tmpLevel)
	end

	Debug.optionsFrame:SetScript("OnShow", function()
		if BSYC.options and BSYC.options.debug then
			for k=1, #Debug.debugLevels do
				Debug.debugLevels[k]:SetValue(BSYC.options.debug[Debug.debugLevels[k].level])
			end
			enableDebugChk:SetValue(BSYC.options.debug.enable)
		end
	end)

	local dumpOptions = AceGUI:Create("Button")
	dumpOptions.frame:SetParent(Debug.optionsFrame)
	dumpOptions:SetText(L.DebugDumpOptions)
	dumpOptions:SetHeight(30)
	dumpOptions:SetAutoWidth(true)
	dumpOptions:SetCallback("OnClick", function()
		BSYC:GetModule("Data"):DebugDumpOptions()
	end)
	dumpOptions.frame:SetParent(Debug.optionsFrame)
	dumpOptions.frame:SetPoint("TOPLEFT",Debug.optionsFrame,"TOPLEFT",10,-35)
	dumpOptions.frame:Show()

	local iterateUnits = AceGUI:Create("Button")
	iterateUnits.frame:SetParent(Debug.optionsFrame)
	iterateUnits:SetText(L.DebugIterateUnits)
	iterateUnits:SetHeight(30)
	iterateUnits:SetAutoWidth(true)
	iterateUnits:SetCallback("OnClick", function()
		local player = BSYC:GetModule("Unit"):GetUnitInfo()

		self:AddMessage(1, "IterateUnits", "UnitInfo-1", player.name, player.realm)
		self:AddMessage(1, "IterateUnits", "UnitInfo-2", player.class, player.race, player.gender, player.faction)
		self:AddMessage(1, "IterateUnits", "UnitInfo-3", player.guild, player.guildrealm)
		self:AddMessage(1, "IterateUnits", "RealmKey", player.realmKey)
		self:AddMessage(1, "IterateUnits", "RealmKey_RWS", player.rwsKey)

		for unitObj in BSYC:GetModule("Data"):IterateUnits() do
			if not unitObj.isGuild then
				self:AddMessage(1, "IterateUnits", "player", unitObj.name, unitObj.realm, unitObj.isConnectedRealm, unitObj.data.guild, unitObj.data.guildrealm, unitObj.data.realmKey, unitObj.data.rwsKey)
			else
				self:AddMessage(1, "IterateUnits", "guild", unitObj.name, unitObj.realm, unitObj.isConnectedRealm, unitObj.isXRGuild, unitObj.data.realmKey, unitObj.data.rwsKey)
			end
		end
	end)
	iterateUnits.frame:SetParent(Debug.optionsFrame)
	iterateUnits.frame:SetPoint("LEFT",dumpOptions.frame,"RIGHT",10,-0)
	iterateUnits.frame:Show()

	local dumpTotals = AceGUI:Create("Button")
	dumpTotals.frame:SetParent(Debug.optionsFrame)
	dumpTotals:SetText(L.DebugDBTotals)
	dumpTotals:SetHeight(30)
	dumpTotals:SetAutoWidth(true)
	dumpTotals:SetCallback("OnClick", function()
		local totalUnits = 0
		local totalGuilds = 0
		local totalRealms = 0
		local biggestRealmName
		local biggestRealmCount = 0
		local toatlItems = 0

		local realmCount = 0
		local lastRealm

		local allowList = {
			["bag"] = 0,
			["bank"] = 0,
			["reagents"] = 0,
			["equip"] = 0,
			["mailbox"] = 0,
			["void"] = 0,
			["auction"] = 0,
			["guild"] = 0,
		}

		for unitObj in BSYC:GetModule("Data"):IterateUnits(true) do
			if not biggestRealmName then
				biggestRealmName = unitObj.realm
				lastRealm = unitObj.realm
				totalRealms = totalRealms + 1
			end

			--realm statistics
			if unitObj.realm == lastRealm then
				realmCount = realmCount + 1
			else
				--check to see if the realm count is larger then the one stored
				if realmCount > biggestRealmCount then
					biggestRealmName = lastRealm
					biggestRealmCount = realmCount
				end
				lastRealm = unitObj.realm
				totalRealms = totalRealms + 1
				realmCount = 1
			end

			if not unitObj.isGuild then
				totalUnits = totalUnits + 1

				for k, v in pairs(unitObj.data) do
					if allowList[k] and type(v) == "table" then
						--bags, bank, reagents are stored in individual bags
						if k == "bag" or k == "bank" or k == "reagents" then
							for bagID, bagData in pairs(v) do
								toatlItems = toatlItems + (#bagData or 0)
							end
						else
							if k == "auction" then
								toatlItems = toatlItems + (#v.bag or 0)
							elseif k == "mailbox" then
								toatlItems = toatlItems + (#v or 0)
							end
						end
					end
				end
			else
				totalGuilds = totalGuilds + 1
				for tabID, tabData in pairs(unitObj.data.tabs) do
					toatlItems = toatlItems + (#tabData or 0)
				end
			end
		end

		self:AddMessage(1, "DBTotals", "totalUnits", totalUnits)
		self:AddMessage(1, "DBTotals", "totalGuilds", totalGuilds)
		self:AddMessage(1, "DBTotals", "totalRealms", totalRealms)
		self:AddMessage(1, "DBTotals", "biggestRealmName", biggestRealmName)
		self:AddMessage(1, "DBTotals", "biggestRealmCount", biggestRealmCount)
		self:AddMessage(1, "DBTotals", "toatlItems", toatlItems)

	end)
	dumpTotals.frame:SetParent(Debug.optionsFrame)
	dumpTotals.frame:SetPoint("LEFT",iterateUnits.frame,"RIGHT",10,-0)
	dumpTotals.frame:Show()

	local addonList = AceGUI:Create("Button")
	addonList.frame:SetParent(Debug.optionsFrame)
	addonList:SetText(L.DebugAddonList)
	addonList:SetHeight(30)
	addonList:SetAutoWidth(true)
	addonList:SetCallback("OnClick", function()
		for i=1, GetNumAddOns() do
			local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(i)
			self:AddMessage(1, "AddonList", title)
		end
	end)
	addonList.frame:SetParent(Debug.optionsFrame)
	addonList.frame:SetPoint("LEFT",dumpTotals.frame,"RIGHT",10,-0)
	addonList.frame:Show()

	local exportBtn = AceGUI:Create("Button")
	exportBtn.frame:SetParent(Debug.optionsFrame)
	exportBtn:SetText(L.DebugExport)
	exportBtn:SetHeight(20)
	exportBtn:SetAutoWidth(true)
	exportBtn:SetCallback("OnClick", function()
		-- local lines = {};
		-- for i=1, #self.scrollframe.children do
		-- 	local tmpObj = self.scrollframe.children[i]
		-- 	if tmpObj and tmpObj.label then
		-- 		table.insert(lines, tmpObj.label:GetText())
		-- 	end
		-- end

		-- local strLines = table.concat(lines, "\r\n")

		SetExportFrameText()
	end)
	exportBtn.frame:SetParent(Debug.optionsFrame)
	exportBtn.frame:SetPoint("TOPRIGHT",Debug.optionsFrame,"TOPRIGHT",-5,-5)
	exportBtn.frame:Show()

	local clearBtn = AceGUI:Create("Button")
	clearBtn.frame:SetParent(Debug.optionsFrame)
	clearBtn:SetText(L.Clear)
	clearBtn:SetHeight(20)
	clearBtn:SetAutoWidth(true)
	clearBtn:SetCallback("OnClick", function()
		scrollframe:ReleaseChildren()
	end)
	clearBtn.frame:SetParent(Debug.optionsFrame)
	clearBtn.frame:SetPoint("BOTTOMRIGHT",Debug.optionsFrame,"BOTTOMRIGHT",-5,5)
	clearBtn.frame:Show()

	--create the export frame
	CreateExportFrame()

	DebugFrame:Hide()

	--only annoy the user if the option is enabled, making sure to remind them that debugging is on.
	--can you tell that I really don't want them to leave this on? LOL
	if BSYC.options and BSYC.options.debug and BSYC.options.debug.enable then
		DebugFrame:Show()
	end

	--put warnings everywhere! Including if they hide the window WHILE debugging is enabled
	DebugFrame.frame:SetScript("OnHide", function()
		if BSYC.options and BSYC.options.debug and BSYC.options.debug.enable then
			BSYC:Print(L.DebugWarning)
		end
	end)
end

function Debug:AddMessage(level, sName, ...)
	if not BSYC.options or not BSYC.options.debug or not BSYC.options.debug.enable then return end

	if level == BSYC_DL.DEBUG and not BSYC.options.debug.DEBUG then return end
	if level == BSYC_DL.INFO and not BSYC.options.debug.INFO then return end
	if level == BSYC_DL.TRACE and not BSYC.options.debug.TRACE then return end
	if level == BSYC_DL.WARN and not BSYC.options.debug.WARN then return end
	if level == BSYC_DL.FINE and not BSYC.options.debug.FINE then return end
	if level == BSYC_DL.SL1 and not BSYC.options.debug.SL1 then return end
	if level == BSYC_DL.SL2 and not BSYC.options.debug.SL2 then return end
	if level == BSYC_DL.SL3 and not BSYC.options.debug.SL3 then return end

	local debugStr = string.join(", ", tostringall(...))
	local color = "778899" -- slate gray

	if level == BSYC_DL.DEBUG then
		--debug
		color = "FF4DD827" --fel green
	elseif level == BSYC_DL.INFO then
		--info
		color = "FFffff00" --yellow
	elseif level == BSYC_DL.TRACE then
		--trace
		color = "FF09DBE0" --teal blue
	elseif level == BSYC_DL.WARN then
		--warn
		color = "FFFF3C38" --rose red
	elseif level == BSYC_DL.FINE then
		--fine
		color = "FFe454fd" --dark lavender
	elseif level == BSYC_DL.SL1 then
		--SL1 (SUBLEVEL1)
		color = "FFCF9FFF" --light lavender
	elseif level == BSYC_DL.SL2 then
		--SL2 (SUBLEVEL2)
		color = "FFFFD580" --light orange
	elseif level == BSYC_DL.SL3 then
		--SL3 (SUBLEVEL3)
		color = "FFd1d1d1" --light gray
	end

	local moduleName = string.format("|c"..color.."[%s]|r: ", sName)
	debugStr = moduleName..debugStr
	debugStr = "|cff808080["..date("%X").."]:|r "..debugStr

	local label = AceGUI:Create("BagSyncLabel")

	--if it exceeds the amount of labels then remove top most one before adding
	if #self.scrollframe.children > xListLen then
		local tmpTable = table.remove(self.scrollframe.children, 1)
		tmpTable:Release()
	end

	label:SetText(debugStr)
	label:SetFont("Fonts\\ARIALN.TTF", 14, "OUTLINE")
	label:SetFullWidth(true)
	self.scrollframe:AddChild(label)

	self.scrollframe:SetScroll(1000)
end
