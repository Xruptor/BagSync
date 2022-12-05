--[[
	debug.lua
		Provides some debugging information to assist in squashing bugs.
--]]

local BSYC = select(2, ...) --grab the addon namespace
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync")
local Debug = BSYC:NewModule("Debug")

local AceGUI = LibStub("AceGUI-3.0")

local xListLen = 400
local xRowHeight = 14
local xMaxScroll = 29
local xFontHeight = 13.9

function Debug:OnEnable()
	--we have to do this as this module loads before Data which sets up the DB.  The reason we do this is to catch errors as earliest as possible by ensuring Debug loads first
	local BSOpts = BagSyncDB
	BSOpts = BagSyncDB["options§"]

	--lets create our widgets
	local DebugFrame = AceGUI:Create("Window")
	Debug.frame = DebugFrame

	DebugFrame:SetTitle("BagSync - "..L.Debug)
	DebugFrame:SetHeight(450)
	DebugFrame:SetWidth(800)
	DebugFrame:EnableResize(false)
	DebugFrame:SetPoint("CENTER",UIParent,"CENTER",0,120)
	
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
	Debug.optionsFrame:SetWidth(800)
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
		if BSOpts and BSOpts.debug then
			BSOpts.debug.enable = checked
		end
	end)
	
	local levels = {
		"DEBUG",
		"INFO",
		"TRACE",
		"WARN",
		"FINE",
		"SUBFINE",
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
			if BSOpts and BSOpts.debug then
				BSOpts.debug[self.level] = checked
			end
		end)
		
		table.insert(Debug.debugLevels, tmpLevel)
	end

	Debug.optionsFrame:SetScript("OnShow", function()
		if BSOpts and BSOpts.debug then
			for k=1, #Debug.debugLevels do
				Debug.debugLevels[k]:SetValue(BSOpts.debug[Debug.debugLevels[k].level])
			end
			enableDebugChk:SetValue(BSOpts.debug.enable)
		end
	end)

	local dumpOptions = AceGUI:Create("Button")
	dumpOptions.frame:SetParent(Debug.optionsFrame)
	dumpOptions:SetText(L.DebugDumpOptions)
	dumpOptions:SetHeight(30)
	dumpOptions:SetWidth(dumpOptions.text:GetStringWidth() + 40)
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
	iterateUnits:SetWidth(iterateUnits.text:GetStringWidth() + 40)
	iterateUnits:SetCallback("OnClick", function()
		local player = BSYC:GetModule("Unit"):GetUnitInfo()
		for unitObj in BSYC:GetModule("Data"):IterateUnits() do
			if not unitObj.isGuild then
				self:AddMessage(1, "Debug-IterateUnits", "player", unitObj.name, player.realm)
			else
				self:AddMessage(1, "Debug-IterateUnits", "guild", unitObj.name, player.realm, unitObj.data.realmKey)
			end
		end
	end)
	iterateUnits.frame:SetParent(Debug.optionsFrame)
	iterateUnits.frame:SetPoint("LEFT",dumpOptions.frame,"RIGHT",10,-0)
	iterateUnits.frame:Show()

	local exportBtn = AceGUI:Create("Button")
	exportBtn.frame:SetParent(Debug.optionsFrame)
	exportBtn:SetText(L.DebugExport)
	exportBtn:SetHeight(20)
	exportBtn:SetWidth(exportBtn.text:GetStringWidth() + 40)
	exportBtn:SetCallback("OnClick", function()
		local lines = {};
		for i=1, #self.scrollframe.children do
			local tmpObj = self.scrollframe.children[i]
			if tmpObj and tmpObj.label then
				table.insert(lines, tmpObj.label:GetText())
			end
		end
		
		local strLines = table.concat(lines, "\r\n")
	end)
	exportBtn.frame:SetParent(Debug.optionsFrame)
	exportBtn.frame:SetPoint("TOPRIGHT",Debug.optionsFrame,"TOPRIGHT",-5,-5)
	exportBtn.frame:Show()

	DebugFrame:Hide()
	--only annoy the user if the option is enabled
	if BSOpts and BSOpts.debug and BSOpts.debug.enable then
		DebugFrame:Show()
	end
end

function Debug:AddMessage(level, sName, ...)
	--just in case
	local BSOpts = BagSyncDB
	BSOpts = BagSyncDB["options§"]
	if not BSOpts or not BSOpts.debug or not BSOpts.debug.enable then return end
	if level == 1 and not BSOpts.debug.DEBUG then return end
	if level == 2 and not BSOpts.debug.INFO then return end
	if level == 3 and not BSOpts.debug.TRACE then return end
	if level == 4 and not BSOpts.debug.WARN then return end
	if level == 5 and not BSOpts.debug.FINE then return end
	if level == 6 and not BSOpts.debug.SUBFINE then return end

	local debugStr = string.join(", ", tostringall(...))
	local color = "778899" -- slate gray

	if level == 1 then
		--debug
		color = "4DD827" --fel green
	elseif level == 2 then
		--info
		color = "ffff00" --yellow
	elseif level == 3 then
		--trace
		color = "09DBE0" --teal blue
	elseif level == 4 then
		--warn
		color = "FF3C38" --rose red
	elseif level == 5 then
		--fine
		color = "e454fd" --dark lavender
	elseif level == 6 then
		--subfine
		color = "CF9FFF" --light lavender
	end

	local moduleName = string.format("|cFF"..color.."[%s]|r: ", sName)
	debugStr = moduleName..debugStr
	debugStr = "|cff808080["..date("%X").."]:|r "..debugStr

	local label = AceGUI:Create("Label")

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
