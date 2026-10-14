--- Kaliel's Tracker
--- Copyright (c) 2012-2026, Marouan Sabbagh <mar.sabbagh@gmail.com>
--- All Rights Reserved.
---
--- This file is part of addon Kaliel's Tracker.

local addonName, addon = ...
---@class KT
local KT = addon

---@class KT
local KT = LibStub("MSA-AceAddon-3.0"):NewAddon(addon, addonName, "LibSink-2.0", "MSA-Event-1.0", "MSA-ProtRouter-1.0")
KT:SetDefaultModuleState(false)

local LSM = LibStub("LibSharedMedia-3.0")

-- Lua API
local abs = math.abs
local floor = math.floor
local format = string.format
local ipairs = ipairs
local pairs = pairs
local strfind = string.find
local tonumber = tonumber
local tinsert = table.insert
local tremove = table.remove
local unpack = unpack
local round = function(n) return floor(n + 0.5) end

-- WoW API
local _G = _G
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local InCombatLockdown = InCombatLockdown
local UIParent = UIParent

local trackerWidth = 280
local paddingBottom = 16
local freeTags = {}
local freeButtons = {}
local msgPatterns = {}
local combatLockdown = false
---@type KT.Profile
local profile
local dbChar

-- Main frame
local KTF = CreateFrame("Frame", addonName.."Frame", UIParent, "BackdropTemplate")
KT.frame = KTF

-- Blizzard frame
local OTF = KT_ObjectiveTrackerFrame
local OTFHeader = OTF.HeaderMenu

AUTO_QUEST_WATCH = GetCVar("autoQuestWatch")
DEFAULT_OBJECTIVE_TRACKER_MODULE.blockTemplate = "KT_ObjectiveTrackerBlockTemplate"
DEFAULT_OBJECTIVE_TRACKER_MODULE.lineTemplate = "KT_ObjectiveTrackerLineTemplate"
QUEST_TRACKER_MODULE.buttonOffsets.groupFinder = { 2, 4 }
if WOW_PROJECT_ID >= WOW_PROJECT_MISTS_CLASSIC then
	SCENARIO_CONTENT_TRACKER_MODULE.blockOffsetX = -16
	SCENARIO_CONTENT_TRACKER_MODULE.fromHeaderOffsetY = -9
end

-- Prototype -----------------------------------------------------------------------------------------------------------

---@type KT|Options|Filters|QuestLog|AddonQuestie|AddonPetTracker|AddonOthers|Help
local prototype = {}

---SetForced (prototype)
function prototype:SetForced(forced)
	if forced then
		KT.skinID = KT.skinID + 1
	end
end

local mt = getmetatable(KT)
mt.__index = prototype
setmetatable(KT, mt)
KT:SetDefaultModulePrototype(prototype)

-- Internal ------------------------------------------------------------------------------------------------------------

local Noop = function() end

local function ObjectiveTracker_Toggle()
	if OTF.collapsed then
		ObjectiveTracker_Expand()
	else
		ObjectiveTracker_Collapse()
	end
	ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.TRACKER_TOGGLE)
end

local function SetHeaders(type)
	local bgrColor = profile.headerBgrColorShare and KT.borderColor or profile.headerBgrColor
	local txtColor = profile.headerTxtColorShare and KT.borderColor or profile.headerTxtColor

	if not type or type == "background" then
		for _, header in ipairs(KT.headers) do
			if profile.headerBgr == 1 then
				header.Background:Hide()
			elseif profile.headerBgr == 2 then
				header.Background:SetAtlas("Objective-Header")
				header.Background:SetVertexColor(1, 1, 1)
				header.Background:ClearAllPoints()
				header.Background:SetPoint("TOPLEFT", -29, 14)
				header.Background:Show()
			elseif profile.headerBgr >= 3 then
				header.Background:SetTexture(KT.MEDIA_PATH.."UI-KT-HeaderBackground-"..(profile.headerBgr - 2))
				header.Background:SetVertexColor(bgrColor.r, bgrColor.g, bgrColor.b)
				header.Background:SetPoint("TOPLEFT", -20, 0)
				header.Background:SetPoint("BOTTOMRIGHT", 17, -7)
				header.Background:Show()
			end
		end
	end
	if not type or type == "text" then
		OTFHeader.Title:SetFont(KT.font, profile.fontSize, profile.fontFlag)
		OTFHeader.Title:SetTextColor(txtColor.r, txtColor.g, txtColor.b)
		OTFHeader.Title:SetShadowColor(0, 0, 0, profile.fontShadow)

		for _, header in ipairs(KT.headers) do
			if type == "text" then
				header.Text:SetFont(KT.font, profile.fontSize+1, profile.fontFlag)
				if profile.headerBgr == 2 then
					header.Text:SetTextColor(1, 0.82, 0)
				else
					header.Text:SetTextColor(txtColor.r, txtColor.g, txtColor.b)
				end
				header.Text:SetShadowColor(0, 0, 0, profile.fontShadow)
				header.Text:SetPoint("LEFT", 4, 0.5)
				header.animateReason = 0
			end
		end
	end
end

local function SetMsgPatterns()
	local patterns = {
		-- enUS/frFR/etc. ... "%s: %d/%d"
		-- deDE (only) ...... "%1$s: %2$d/%3$d"
		ERR_QUEST_ADD_FOUND_SII,
		ERR_QUEST_ADD_ITEM_SII,
		ERR_QUEST_ADD_KILL_SII,
		ERR_QUEST_ADD_PLAYER_KILL_SII,
	}
	for _, patt in ipairs(patterns) do
		patt = "^"..patt:gsub("%d+%$", ""):gsub("%%s", ".*"):gsub("%%d", "%%d+").."$"
		tinsert(msgPatterns, patt)
	end
end

local function SlashHandler(msg, editbox)
	local cmd, value = msg:match("^(%S*)%s*(.-)$")
	if cmd == "config" then
		KT:OpenOptions()
	else
		KT:MinimizeButton_OnClick()
	end
end

local function SetScrollbarPosition()
	local xOffset = -5
	local yOffset = -5
	local scrollRange = OTF.height - profile.maxHeight
	if scrollRange > 0 then
		local barSpace = 60  -- 50 + 2×5
		local usableHeight = profile.maxHeight - barSpace
		local scrollRatio = KTF.Scroll.value / scrollRange
		yOffset = -1 * round(5 + (usableHeight * scrollRatio))
	end
	KTF.Bar:SetPoint("TOPRIGHT", xOffset, yOffset)
end

local function GetTaskTimeLeftData(questID)
	local timeString = ""
	local timeColor = OBJECTIVE_TRACKER_COLOR["TimeLeft2"]
	local timeLeftMinutes = C_TaskQuest.GetQuestTimeLeftMinutes(questID)
	if timeLeftMinutes and timeLeftMinutes > 0 then
		timeString = SecondsToTime(timeLeftMinutes * 60)
		if timeLeftMinutes <= WORLD_QUESTS_TIME_CRITICAL_MINUTES then
			timeColor = OBJECTIVE_TRACKER_COLOR["TimeLeft"]
		end
	end
	return timeString, timeColor
end

-- Init ----------------------------------------------------------------------------------------------------------------

local function Init()
	if profile.keyBindMinimize ~= "" then
		SetOverrideBindingClick(KTF, false, profile.keyBindMinimize, KTF.MinimizeButton:GetName())
	end

	for i, module in ipairs(profile.modulesOrder) do
		OTF.MODULES_UI_ORDER[i] = _G[module]
		KT:SaveHeader(OTF.MODULES_UI_ORDER[i])
	end

	KT:MoveTracker()
	KT:SetBackground()
	KT:SetText(true)

	C_Timer.After(0, function()
		KT.stopUpdate = false
		KT.inWorld = true

		if dbChar.collapsed then
			ObjectiveTracker_Toggle()
		else
			ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.TRACKER_INITIALIZE)
		end

		KT:SetQuestsHeaderText()
		KT:SetAchievementsHeaderText()

		OTF:KTSetPoint("TOPLEFT", 30, -1)
		OTF:KTSetPoint("BOTTOMRIGHT")

		KT.initialized = true
	end)
end

-- Frames --------------------------------------------------------------------------------------------------------------

local function SetFrames()
	-- Main frame
	KTF:SetWidth(trackerWidth)
	KTF:SetFrameStrata(profile.frameStrata)
	KTF:SetFrameLevel(KTF:GetFrameLevel() + 25)

	KTF:SetScript("OnEvent", function(_, event, ...)
		KT.Utils.Log("Event - "..event)
		if event == "PLAYER_ENTERING_WORLD" and not KT.stopUpdate then
			KT.inWorld = true
			KT.inInstance = IsInInstance()
			if profile.collapseInInstance and KT.inInstance and not dbChar.collapsed then
				ObjectiveTracker_Toggle()
			end
		elseif event == "PLAYER_LEAVING_WORLD" then
			KT.inWorld = false
		elseif event == "SCENARIO_UPDATE" then
			local newStage = ...
			if newStage == nil then
				KT.inScenario = false
			elseif not KT.inScenario then
				KT.inScenario = true
				KT:ToggleEmptyTracker(true)
			end
			if not newStage then
				local numSpells = ScenarioObjectiveBlock.numSpells or 0
				for i = 1, numSpells do
					KT:RemoveFixedButton(ScenarioObjectiveBlock.spells[i])
				end
				ObjectiveTracker_Update(OBJECTIVE_TRACKER_UPDATE_SCENARIO)
			end
		elseif event == "SCENARIO_COMPLETED" then
			KT.inScenario = false
			ObjectiveTracker_Update(OBJECTIVE_TRACKER_UPDATE_SCENARIO)
		elseif event == "QUEST_AUTOCOMPLETE" then
			KTF.Scroll.value = 0
		elseif event == "QUEST_ACCEPTED" then
			local _, questID = ...
			KT.QuestsCache_AddUpdateQuest(questID)
			KT:SetQuestsHeaderText()
		elseif event == "QUEST_REMOVED" then
			local questID = ...
			KT.QuestsCache_RemoveQuest(questID)
			KT:SetQuestsHeaderText()
		elseif event == "ACHIEVEMENT_EARNED" then
			KT:SetAchievementsHeaderText()
		elseif event == "PLAYER_REGEN_ENABLED" and combatLockdown then
			combatLockdown = false
			KT:RemoveFixedButton()
			ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.COMBAT_STOP)
		elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
			KTF.QuestButtonBar.reanchor = (KTF.QuestButtonBar.num > 0)
		elseif event == "UPDATE_BINDINGS" then
			KT:UpdateHotkey()
		elseif event == "PLAYER_LEVEL_UP" then
			local level = ...
			KT.playerLevel = level
		elseif event == "PET_BATTLE_OPENING_START" then
			KT:prot("SetShown", KT, false)
			KT.locked = true
		elseif event == "PET_BATTLE_CLOSE" then
			KT:prot("SetShown", KT, true)
			KT.locked = false
			ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.PET_BATTLE_CLOSE)
		elseif event == "CVAR_UPDATE" then
			local varName = ...
			if varName == "autoQuestWatch" then
				AUTO_QUEST_WATCH = GetCVar("autoQuestWatch")
			end
		end
	end)
	KTF:RegisterEvent("PLAYER_ENTERING_WORLD")
	KTF:RegisterEvent("PLAYER_LEAVING_WORLD")
	if WOW_PROJECT_ID >= WOW_PROJECT_MISTS_CLASSIC then
		KTF:RegisterEvent("SCENARIO_UPDATE")
		KTF:RegisterEvent("SCENARIO_COMPLETED")
	end
	KTF:RegisterEvent("QUEST_AUTOCOMPLETE")
	KTF:RegisterEvent("QUEST_ACCEPTED")
	KTF:RegisterEvent("QUEST_REMOVED")
	KTF:RegisterEvent("ACHIEVEMENT_EARNED")
	KTF:RegisterEvent("PLAYER_REGEN_ENABLED")
	KTF:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	KTF:RegisterEvent("ZONE_CHANGED")
	KTF:RegisterEvent("UPDATE_BINDINGS")
	KTF:RegisterEvent("PLAYER_LEVEL_UP")
	KTF:RegisterEvent("PET_BATTLE_OPENING_START")
	KTF:RegisterEvent("PET_BATTLE_CLOSE")
	KTF:RegisterEvent("CVAR_UPDATE")

	-- DropDown frame
	KT.DropDown = MSA_DropDownMenu_Create(addonName.."DropDown", KTF)
	MSA_DropDownMenu_Initialize(KT.DropDown, nil, "MENU")

	-- Minimize button
	OTFHeader.MinimizeButton:Hide()
	local button = CreateFrame("Button", addonName.."MinimizeButton", KTF)
	button:SetSize(16, 16)
	button:SetPoint("TOPRIGHT", -10, -8)
	button:SetFrameLevel(KTF:GetFrameLevel() + 10)
	button:SetNormalTexture(KT.MEDIA_PATH.."UI-KT-HeaderButtons")
	button:GetNormalTexture():SetTexCoord(0, 0.5, 0.25, 0.5)

	button:RegisterForClicks("AnyDown")
	button:SetScript("OnClick", function(self, btn)
		if IsAltKeyDown() then
			KT:OpenOptions()
		elseif not KT:IsTrackerEmpty() and not KT.locked then
			KT:MinimizeButton_OnClick()
		end
	end)
	button:SetScript("OnEnter", function(self)
		self:GetNormalTexture():SetVertexColor(1, 1, 1)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		local title = KT.TITLE..((profile.keyBindMinimize ~= "") and NORMAL_FONT_COLOR_CODE.." ("..profile.keyBindMinimize..")|r" or "")
		GameTooltip:AddLine(title, 1, 1, 1)
		GameTooltip:AddLine("Alt+Click - addon Options", 0.5, 0.5, 0.5)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function(self)
		self:GetNormalTexture():SetVertexColor(KT.headerBtnColor.r, KT.headerBtnColor.g, KT.headerBtnColor.b)
		GameTooltip:Hide()
	end)
	KTF.MinimizeButton = button

	-- Scroll frame
	local Scroll = CreateFrame("ScrollFrame", addonName.."Scroll", KTF)
	Scroll:SetPoint("TOPLEFT", 4, -4)
	Scroll:SetPoint("BOTTOMRIGHT", -4, 4)
    Scroll:SetClipsChildren(true)
	Scroll:EnableMouseWheel(true)
	Scroll.step = 20
	Scroll.value = 0
	Scroll:SetScript("OnMouseWheel", function(self, delta)
		if not dbChar.collapsed and OTF.height > profile.maxHeight then
			if delta < 0 then
				self.value = (self.value+self.step < OTF.height-profile.maxHeight) and self.value + self.step or OTF.height - profile.maxHeight
			else
				self.value = (self.value-self.step > 0) and self.value - self.step or 0
			end
			self:SetVerticalScroll(self.value)
			if profile.frameScrollbar then
				SetScrollbarPosition()
			end
			if self.value > 0 and self.value < OTF.height-profile.maxHeight then
				MSA_CloseDropDownMenus()
			end
		end
	end)
	KTF.Scroll = Scroll

	-- Scroll child frame
	local Child = CreateFrame("Frame", addonName.."ScrollChild", KTF.Scroll)
	Child:SetSize(trackerWidth-8, 8000)
	KTF.Scroll:SetScrollChild(Child)

	-- Scroll indicator
	local Bar = CreateFrame("Frame", addonName.."ScrollBar", KTF)
	Bar:SetSize(2, 50)
	Bar:SetPoint("TOPRIGHT", -5, -5)
	Bar:SetFrameLevel(KTF:GetFrameLevel() + 10)
	Bar.texture = Bar:CreateTexture()
	Bar.texture:SetAllPoints()
	Bar:Hide()
	KTF.Bar = Bar

	-- Blizzard frame
	OTF:KTSetPoint("TOPLEFT")
	OTF:KTSetParent(Child)
	OTFHeader:Show()
	OTFHeader.Hide = Noop
	OTFHeader.SetShown = Noop
	OTFHeader:SetSize(10, 21)
	OTFHeader:ClearAllPoints()
	OTFHeader:SetPoint("TOPLEFT", -20, -1)
	OTFHeader.Title:ClearAllPoints()
	OTFHeader.Title:SetPoint("LEFT", -5, -1)
	OTFHeader.Title:SetWidth(trackerWidth - 40)
	OTFHeader.Title:SetJustifyH("LEFT")
	OTFHeader.Title:SetWordWrap(false)
	if WOW_PROJECT_ID >= WOW_PROJECT_MISTS_CLASSIC then
		ScenarioBlocksFrame:SetWidth(243)
		ScenarioStageBlock:SetWidth(243)
	end

	-- Other buttons
	KT:ToggleOtherButtons()

	-- Buttons frame
	local questButtonBar = CreateFrame("Frame", addonName.."_QuestButtonBar", UIParent, "BackdropTemplate")
	questButtonBar:SetSize(40, 40)
	questButtonBar:SetPoint("TOPLEFT", 0, 0)
	questButtonBar:SetFrameStrata(profile.frameStrata)
	questButtonBar:SetFrameLevel(KTF:GetFrameLevel() - 1)
	questButtonBar:SetAlpha(0)
	questButtonBar.num = 0
	questButtonBar.reanchor = false
	KTF.QuestButtonBar = questButtonBar
end

-- Hooks ---------------------------------------------------------------------------------------------------------------

local function SetHooks()
	local function SetFixedButton(questBlock, idx, height, yOfs)
		if questBlock.fixedTag and KT.questButtons[questBlock.id] then

			idx = idx + 1
			questBlock.fixedTag.text:SetText(idx)
			KT.questButtons[questBlock.id].text:SetText(idx)
			KT.questButtons[questBlock.id].num = idx

			yOfs = -(height + 7)
			height = height + 26 + 3
			KT.questButtons[questBlock.id]:SetPoint("TOP", 0, yOfs)
		end
		return idx, height, yOfs
	end

	local function ReanchorQuestButtons()
		if InCombatLockdown() then
			if KTF.QuestButtonBar.num > 0 then
				combatLockdown = true
			end
			return
		end

		if KTF.QuestButtonBar.reanchor then
			local yOfs
			local idx = 0
			local contentsHeight = 0
			-- Quest items
			KT.Utils.Log("Reanchor quest buttons")
			for i = 1, GetNumQuestWatches() do
				local questLogIndex = GetQuestIndexForWatch(i)
				local questID = GetQuestIDFromLogIndex(questLogIndex)
				local block = QUEST_TRACKER_MODULE.usedBlocks[questID]
				if block and block.itemButton then
					idx, contentsHeight, yOfs = SetFixedButton(block, idx, contentsHeight, yOfs)
				end
			end
			if contentsHeight > 0 then
				contentsHeight = contentsHeight + 7 + 4
			end
			KTF.QuestButtonBar:SetHeight(contentsHeight)
			KTF.QuestButtonBar.num = idx
			KTF.QuestButtonBar.reanchor = false
		end
		if dbChar.collapsed or KTF.QuestButtonBar.num == 0 then
			KTF.QuestButtonBar:Hide()
		else
			KTF.QuestButtonBar:SetShown(not KT.locked)
		end
	end

	local function SetQuestBarVisibility()
		if dbChar.collapsed or KTF.QuestButtonBar.num == 0 then
			KTF.QuestButtonBar:SetAlpha(0)
		else
			KTF.QuestButtonBar:SetAlpha(1)
		end
	end

	local bck_ObjectiveTracker_Update = ObjectiveTracker_Update

	---@param reason number Either a byte that helps update concerned modules or a debug number to log reason
	---@param itemId number Either a quest or achievement id
	ObjectiveTracker_Update = function(reason, itemId)
		if KT.stopUpdate then return end

		if reason and DEBUG_UPDATE_DESCS[reason] then
			KT.Utils.Log(KT.Utils.AppendCategory("UPDATE", DEBUG_UPDATE_DESCS[reason]))
		else
			KT.Utils.LogWarning(KT.Utils.AppendCategory("UPDATE","Update has no reason ! Add one to the dictionnary or default to \"forced\"."))
		end

		if reason and reason < 0 then reason = nil end -- Prevent debug reason to get in the way of bitwise operations

		bck_ObjectiveTracker_Update(reason, itemId)
		KT:ToggleEmptyTracker(itemId)
		ReanchorQuestButtons()
		SetQuestBarVisibility()
		if dbChar.collapsed then
			local _, numQuests = GetNumQuestLogEntries()
			local title = ""
			if profile.headerCollapsedTxt == 2 then
				title = "|T"..KT.MEDIA_PATH.."KT_logo:22:22:0:1|t"..("%d/%d"):format(numQuests, MAX_QUESTLOG_QUESTS)
			elseif profile.headerCollapsedTxt == 3 then
				title = "|T"..KT.MEDIA_PATH.."KT_logo:22:22:0:1|t"..("%d/%d Quests"):format(numQuests, MAX_QUESTLOG_QUESTS)
			end
			OTFHeader.Title:SetText(title)
		end
		if reason == OBJECTIVE_TRACKER_UPDATE_STATIC then
			return
		end
		KT:SetSize()

		-- Set Quest Log tracking indicator
		if WOW_PROJECT_ID < WOW_PROJECT_CATACLYSM_CLASSIC then
			if GetNumQuestWatches() > 0 then
				QuestLogTrackTracking:SetVertexColor(0, 1.0, 0)
			else
				QuestLogTrackTracking:SetVertexColor(1.0, 0, 0)
			end
		end
	end

	function DEFAULT_OBJECTIVE_TRACKER_MODULE:AddObjective(block, objectiveKey, text, lineType, useFullHeight, dashStyle, colorStyle, adjustForNoText, overrideHeight)  -- RO
		if objectiveKey == "TimeLeft" then
			text, colorStyle = GetTaskTimeLeftData(block.id)
			self:FreeProgressBar(block, block.currentLine)	-- fix ProgressBar duplicity
		end
		if self == ACHIEVEMENT_TRACKER_MODULE and text == "" then
			text = "..."	-- fix Blizz bug
		end
		local _, _, leftText, colon, progress, numHave, numNeed, rightText = strfind(text, "(.-)(%s?:?%s?)((%d+)%s?/%s?(%d+))(.*)")
		if progress then
			if tonumber(numHave) > 0 and tonumber(numHave) < tonumber(numNeed) then
				progress = "|cffc8c800" .. progress .. "|r"
			end
			if not profile.questsObjectiveNumSwitch then
				text = leftText .. colon .. progress .. rightText
			else
				text = progress
				if rightText ~= " " then
					text = text .. rightText
				end
				if leftText ~= "" then
					text = text .. " " .. leftText
				end
			end
		end

		local line = self:GetLine(block, objectiveKey, lineType);
		-- width
		if ( block.lineWidth ~= line.width ) then
			line.Text:SetWidth(block.lineWidth or self.lineWidth);
			line.width = block.lineWidth;	-- default should be nil
		end
		-- dash
		if ( line.Dash ) then
			if ( not dashStyle ) then
				dashStyle = OBJECTIVE_DASH_STYLE_SHOW;
			end
			if ( line.dashStyle ~= dashStyle ) then
				if ( dashStyle == OBJECTIVE_DASH_STYLE_SHOW ) then
					line.Dash:Show();
					line.Dash:SetText(KT.QUEST_DASH);
				elseif ( dashStyle == OBJECTIVE_DASH_STYLE_HIDE ) then
					line.Dash:Hide();
					line.Dash:SetText(KT.QUEST_DASH);
				elseif ( dashStyle == OBJECTIVE_DASH_STYLE_HIDE_AND_COLLAPSE ) then
					line.Dash:Hide();
					line.Dash:SetText(nil);
				else
					error("Invalid dash style: " .. tostring(dashStyle));
				end
				line.dashStyle = dashStyle;
			end
			if line.Dash.KTskinID ~= KT.skinID then
				line.Dash:SetFont(KT.font, profile.fontSize, profile.fontFlag)
				line.Dash:SetShadowColor(0, 0, 0, profile.fontShadow)
				line.Dash.KTskinID = KT.skinID
			end
		end
		-- check
		if line.Check and line.Check.KTskinID ~= KT.skinID then
			line.Check:SetSize(profile.fontSize-2.5, profile.fontSize-2.5)
			line.Check:ClearAllPoints()
			line.Check:SetPoint("TOPLEFT", -profile.fontSize*0.2+(profile.fontFlag == "" and 0 or 1), -2)
			line.Check.KTskinID = KT.skinID
		end
		-- set the text
		local textHeight = self:SetStringText(line.Text, text, useFullHeight, colorStyle, block.isHighlighted);
		local height = overrideHeight or textHeight;
		line:SetHeight(height);

		local yOffset;

		if ( adjustForNoText and text == "" ) then
			-- don't change the height
			-- move the line up so the next object ends up in the same position as if there had been no line
			yOffset = height;
		else
			block.height = block.height + height + block.module.lineSpacing;
			yOffset = -block.module.lineSpacing;
		end
		-- anchor the line
		local anchor = block.currentLine or block.HeaderText;
		if ( anchor ) then
			line:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset);
		else
			line:SetPoint("TOPLEFT", 0, yOffset);
		end
		block.currentLine = line;

		-- completion state
		if KT.inWorld and type(objectiveKey) == "string" then
			if strfind(objectiveKey, "QuestComplete") then
				local state = KT.QuestsCache_GetProperty(block.id, "state")
				if state and state ~= "complete" then
					if profile.messageQuest then
						KT:SetMessage(block.title, 0, 1, 0, ERR_QUEST_COMPLETE_S, "Interface\\GossipFrame\\ActiveQuestIcon", -2, 0)
					end
					if profile.soundQuest then
						KT.PlayQuestCompletedSound()
					end
					KT.QuestsCache_SetProperty(block.id, "state", "complete")
				end
			elseif strfind(objectiveKey, "QuestFailed") then
				local state = KT.QuestsCache_GetProperty(block.id, "state")
				if state and state ~= "failed" then
					if profile.messageQuest then
						KT:SetMessage(block.title, 1, 0, 0, ERR_QUEST_FAILED_S, "Interface\\GossipFrame\\AvailableQuestIcon", -2, 0)
					end
					KT.QuestsCache_SetProperty(block.id, "state", "failed")
				end
			end
		end

		return line;
	end

	function KT.PlayQuestCompletedSound()
		if profile.useSoundKit == false then
			KT:PlaySound(profile.soundQuestComplete)
		else
			KT.SoundKits.PlaySoundKits(profile.useRandomSoundKit, profile.selectedSoundKits)
		end
	end

	function DEFAULT_OBJECTIVE_TRACKER_MODULE:SetStringText(fontString, text, useFullHeight, colorStyle, useHighlight)  -- RO
		if fontString.KTskinID ~= KT.skinID then
			fontString:SetFont(KT.font, profile.fontSize, profile.fontFlag)
			fontString:SetShadowColor(0, 0, 0, profile.fontShadow)
			fontString:SetWordWrap(profile.textWordWrap)
			fontString.KTskinID = KT.skinID
		end
		if self == QUEST_TRACKER_MODULE and not useHighlight then
			useHighlight = fontString:GetParent().isHighlighted		-- Fix Blizz bug
		end
		fontString:SetHeight(0)
		fontString:SetText(text)
		local stringHeight = fontString:GetHeight()
		if ( stringHeight > KT.OBJECTIVE_TRACKER_DOUBLE_LINE_HEIGHT and not useFullHeight ) then
			fontString:SetHeight(KT.OBJECTIVE_TRACKER_DOUBLE_LINE_HEIGHT)
			stringHeight = KT.OBJECTIVE_TRACKER_DOUBLE_LINE_HEIGHT
		end
		colorStyle = colorStyle or OBJECTIVE_TRACKER_COLOR["Normal"]
		if ( useHighlight and colorStyle.reverse ) then
			colorStyle = colorStyle.reverse
		end
		if ( fontString.colorStyle ~= colorStyle ) then
			fontString:SetTextColor(colorStyle.r, colorStyle.g, colorStyle.b)
			fontString.colorStyle = colorStyle
		end
		return stringHeight
	end

	hooksecurefunc(DEFAULT_OBJECTIVE_TRACKER_MODULE, "OnBlockHeaderEnter", function(self, block)
		local colorStyle, _
		if self == QUEST_TRACKER_MODULE then
			if block.questCompleted then
				colorStyle = OBJECTIVE_TRACKER_COLOR["CompleteHighlight"]
			elseif profile.colorDifficulty then
				_, colorStyle = GetQuestDifficultyColor(block.level)
			end
		end
		if colorStyle then
			block.HeaderText:SetTextColor(colorStyle.r, colorStyle.g, colorStyle.b)
			block.HeaderText.colorStyle = colorStyle
		end

		if profile.tooltipShow and (self == QUEST_TRACKER_MODULE or self == ACHIEVEMENT_TRACKER_MODULE) then
			GameTooltip:SetOwner(block, "ANCHOR_NONE")
			GameTooltip:ClearAllPoints()
			if KTF.anchorLeft then
				GameTooltip:SetPoint("TOPLEFT", block, "TOPRIGHT", 12, 1)
			else
				GameTooltip:SetPoint("TOPRIGHT", block, "TOPLEFT", -32, 1)
			end
			if self == QUEST_TRACKER_MODULE then
				local questLogIndex = GetQuestLogIndexByID(block.id)
				local questTitle = KT.QuestUtils_GetQuestName(block.id)
				local _, questDescription = GetQuestLogQuestText(questLogIndex)
				local questZone = KT.QuestsCache_GetProperty(block.id, "zone")
				GameTooltip:AddLine(questTitle, nil, nil, nil, true)
			    if questZone then
				    GameTooltip:AddLine(questZone, OBJECTIVE_TRACKER_COLOR["Zone"].r, OBJECTIVE_TRACKER_COLOR["Zone"].g, OBJECTIVE_TRACKER_COLOR["Zone"].b, true)
				end
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(questDescription, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true)
				if profile.tooltipShowRewards then
					KT.GameTooltip_AddQuestRewardsToTooltip(GameTooltip, block.id)
				end
			else
				GameTooltip:SetHyperlink(GetAchievementLink(block.id))
			end
			if profile.tooltipShowID then
				GameTooltip:AddLine(" ")
				GameTooltip:AddDoubleLine(" ", "ID: |cffffffff"..block.id)
			end
			GameTooltip:Show()
		end

		if block.fixedTag then
			colorStyle = OBJECTIVE_TRACKER_COLOR["NormalHighlight"]
			block.fixedTag:SetBackdropColor(colorStyle.r, colorStyle.g, colorStyle.b)
			block.fixedTag.text:SetTextColor(colorStyle.r, colorStyle.g, colorStyle.b)
		end
	end)

	hooksecurefunc(DEFAULT_OBJECTIVE_TRACKER_MODULE, "OnBlockHeaderLeave", function(self, block)
		local colorStyle
		if self == QUEST_TRACKER_MODULE then
			if block.questCompleted then
				colorStyle = OBJECTIVE_TRACKER_COLOR["Complete"]
			elseif profile.colorDifficulty then
				colorStyle = GetQuestDifficultyColor(block.level)
			end
		end
		if colorStyle then
			block.HeaderText:SetTextColor(colorStyle.r, colorStyle.g, colorStyle.b)
			block.HeaderText.colorStyle = colorStyle
		end

		if profile.tooltipShow then
			GameTooltip:Hide()
		end

		if block.fixedTag then
			colorStyle = OBJECTIVE_TRACKER_COLOR["Normal"]
			block.fixedTag:SetBackdropColor(colorStyle.r, colorStyle.g, colorStyle.b)
			block.fixedTag.text:SetTextColor(colorStyle.r, colorStyle.g, colorStyle.b)
		end
	end)

	hooksecurefunc(QUEST_TRACKER_MODULE, "OnBlockHeaderClick", function(self, block, mouseButton)
		GameTooltip:Hide()
	end)
	if WOW_PROJECT_ID >= WOW_PROJECT_WRATH_CLASSIC then
		hooksecurefunc(ACHIEVEMENT_TRACKER_MODULE, "OnBlockHeaderClick", function(self, block, mouseButton)
			GameTooltip:Hide()
		end)
	end

	function KT_ObjectiveTrackerBlock_OnEnter(self)
		self.module:OnBlockHeaderEnter(self)
	end

	function KT_ObjectiveTrackerBlock_OnLeave(self)
		self.module:OnBlockHeaderLeave(self)
	end

	function KT_ObjectiveTrackerBlock_OnClick(self, mouseButton)
		self.module:OnBlockHeaderClick(self, mouseButton)
	end

	hooksecurefunc(DEFAULT_OBJECTIVE_TRACKER_MODULE, "FreeUnusedLines", function(self, block)
		local colorStyle
		if block.questCompleted then
			colorStyle = OBJECTIVE_TRACKER_COLOR["Complete"]
		elseif profile.colorDifficulty and self == QUEST_TRACKER_MODULE then
			colorStyle = GetQuestDifficultyColor(block.level)
		end
		if colorStyle then
			block.HeaderText:SetTextColor(colorStyle.r, colorStyle.g, colorStyle.b)
			block.HeaderText.colorStyle = colorStyle
		end
	end)

	local function CreateFixedTag(block, x, y, anchor)
		local tag = block.fixedTag
		if not tag then
			local numFreeButtons = #freeTags
			if numFreeButtons > 0 then
				tag = freeTags[numFreeButtons]
				tremove(freeTags, numFreeButtons)
				tag:SetParent(block)
				tag:ClearAllPoints()
			else
				tag = CreateFrame("Frame", nil, block, "BackdropTemplate")
				tag:SetSize(32, 32)
				tag:SetBackdrop({ bgFile = KT.MEDIA_PATH.."UI-KT-QuestItemTag" })
				tag.text = tag:CreateFontString(nil, "ARTWORK", "GameFontNormalMed1")
				tag.text:SetFont(LSM:Fetch("font", "Arial Narrow"), 13, "")
				tag.text:SetPoint("CENTER", -0.5, 1)
			end
			tag:SetPoint(anchor or "TOPRIGHT", block, x, y)
			tag:Show()
			block.fixedTag = tag
		end

		local colorStyle = OBJECTIVE_TRACKER_COLOR["Normal"]
		if block.isHighlighted and colorStyle.reverse then
			colorStyle = colorStyle.reverse
		end
		tag:SetBackdropColor(colorStyle.r, colorStyle.g, colorStyle.b)
		tag.text:SetTextColor(colorStyle.r, colorStyle.g, colorStyle.b)
	end

	---Create quest button visual
	---@param questID number
	---@return table|Button|SecureActionButtonTemplate
	local function CreateQuestButton(questID)
		KT.Utils.Log("Create new quest button for quest: "..questID)
		local name = addonName.."_QuestButton_"..questID
		local button = CreateFrame("Button", name, KTF.QuestButtonBar, "SecureActionButtonTemplate")
		button:SetSize(26, 26)

		button.icon = button:CreateTexture(name.."_Icon", "BORDER")
		button.icon:SetAllPoints()
		button.Icon = button.icon   -- for Spell

		button.Count = button:CreateFontString(name.."_Count", "BORDER", "NumberFontNormal")
		button.Count:SetJustifyH("RIGHT")
		button.Count:SetPoint("BOTTOMRIGHT", button.icon, -3, 2)

		button.Cooldown = CreateFrame("Cooldown", name.."Cooldown", button, "CooldownFrameTemplate")
		button.Cooldown:SetAllPoints()

		button.HotKey = button:CreateFontString(name.."_HotKey", "ARTWORK", "NumberFontNormalSmallGray")
		button.HotKey:SetSize(29, 10)
		button.HotKey:SetJustifyH("RIGHT")
		button.HotKey:SetText(RANGE_INDICATOR)
		button.HotKey:SetPoint("TOPRIGHT", button.icon, 2, -2)

		button.text = button:CreateFontString(name.."_Text", "ARTWORK", "NumberFontNormalSmall")
		button.text:SetSize(29, 10)
		button.text:SetJustifyH("LEFT")
		button.text:SetPoint("TOPLEFT", button.icon, 1, -3)

		button:RegisterForClicks("AnyUp", "AnyDown")

		button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
		do local tex = button:GetNormalTexture()
			tex:ClearAllPoints()
			tex:SetPoint("CENTER")
			tex:SetSize(44, 44)
		end

		button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
		button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		button:SetFrameLevel(KTF:GetFrameLevel() + 1)
		button:Hide()

		return button;
	end

	---@param button table|Button
	---@param isSpell boolean
	local function BindEventOnQuestButton(button, isSpell)
		if not isSpell then
			button:SetScript("OnEvent", QuestObjectiveItem_OnEvent)
			button:SetScript("OnUpdate", QuestObjectiveItem_OnUpdate)
			button:SetScript("OnShow", QuestObjectiveItem_OnShow)
			button:SetScript("OnHide", QuestObjectiveItem_OnHide)
			button:SetScript("OnEnter", QuestObjectiveItem_OnEnter)
			button:SetScript("OnLeave", QuestObjectiveItem_OnLeave)
		else
			button.HotKey:Hide()
			button:SetScript("OnEvent", nil)
			button:SetScript("OnUpdate", nil)
			button:SetScript("OnShow", nil)
			button:SetScript("OnHide", nil)
			button:SetScript("OnEnter", ScenarioSpellButton_OnEnter)
			button:SetScript("OnLeave", GameTooltip_Hide)
		end

		button:SetScript("OnMouseDown", QuestObjectiveItem_OnClick)
		button:SetAttribute("type*", isSpell and "spell" or "item")
	end

	---@param questID number
	---@param isSpell boolean
	---@return table|Button
	local function RecycleOrCreateQuestButton(questID, isSpell)
		local button

		local numFreeButtons = #freeButtons
		if numFreeButtons > 0 then
			KT.Utils.Log("Use existing free button for quest : "..questID)
			button = freeButtons[numFreeButtons]
			tremove(freeButtons, numFreeButtons)
		else
			button = CreateQuestButton(questID)
		end

		BindEventOnQuestButton(button, isSpell)

		return button
	end

	local function GetOrCreateQuestButton(block, isSpell)
		local questID = block.id
		local button = KT:GetFixedButton(questID)
		if not button then
			if InCombatLockdown() then
				KT.Utils.LogWarning("Prevent creating quest button during combat !")
				combatLockdown = true
				return nil
			end

			button = RecycleOrCreateQuestButton(questID, isSpell)

			button:Show()
			KT.questButtons[questID] = button
			KTF.QuestButtonBar.reanchor = true
		end

		button.block = block
		button:SetAlpha(1)

		return button
	end

	hooksecurefunc(DEFAULT_OBJECTIVE_TRACKER_MODULE, "SetBlockHeader", function(self, block, text)
		block.lineWidth = block.lineWidth or self.lineWidth - 8		-- mod default
	end)

	local bck_QUEST_TRACKER_MODULE_SetBlockHeader = QUEST_TRACKER_MODULE.SetBlockHeader
	function QUEST_TRACKER_MODULE:SetBlockHeader(block, text, questLogIndex, isQuestComplete, questID)
		local _, level, suggestedGroup, _, _, _, frequency, _ = GetQuestLogTitle(questLogIndex)
		if profile.questsShowLevels then
			text = KT:CreateQuestLevel(level)..text
		end
		block.title = text
		if profile.questsShowTags then
			local tagID, _ = GetQuestTagInfo(questID)
			text = text..KT:CreateQuestTag(tagID, frequency, suggestedGroup)
		end
		bck_QUEST_TRACKER_MODULE_SetBlockHeader(self, block, text, questLogIndex, isQuestComplete, questID)
		block.lineWidth = block.lineWidth or self.lineWidth - 8		-- mod default
		block.level = level

		local link, item, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(questLogIndex)
		if item and (not isQuestComplete or showItemWhenComplete) then
			block.itemButton:Hide()
			CreateFixedTag(block, 3, 4)
			local button = GetOrCreateQuestButton(block)
			if not InCombatLockdown() then
				button:SetID(questLogIndex)
				button.charges = charges
				button.rangeTimer = -1
				button.item = item
				button.link = link
				SetItemButtonTexture(button, item)
				SetItemButtonCount(button, charges)
				QuestObjectiveItem_UpdateCooldown(button)
				button:SetAttribute("item", link)
			end
		else
			KT:RemoveFixedButton(block)
		end
	end

	local bck_QUEST_TRACKER_MODULE_OnFreeBlock = QUEST_TRACKER_MODULE.OnFreeBlock
	function QUEST_TRACKER_MODULE:OnFreeBlock(block)
		KT:RemoveFixedButton(block)
		bck_QUEST_TRACKER_MODULE_OnFreeBlock(self, block)
	end

	local function SetProgressBarStyle(progressBar)
		if progressBar.KTskinID ~= KT.skinID then
			local block = progressBar.block
			block.height = block.height - progressBar.height

			progressBar:SetSize(232, 23)
			progressBar.height = 23
			--_C(progressBar, { r = 0, g = 1, b = 0 })

			progressBar.Bar:SetSize(208, 13)
			progressBar.Bar:EnableMouse(false)
			progressBar.Bar:ClearAllPoints()

			if progressBar.Bar.BarFrame then
				-- World Quest
				progressBar.Bar:SetPoint("LEFT", 22, 0)
				progressBar.Bar.BarFrame:Hide()
				progressBar.Bar.BarFrame2:Hide()
				progressBar.Bar.BarFrame3:Hide()
				progressBar.Bar.BarGlow:Hide()
				progressBar.Bar.Sheen:Hide()
				progressBar.Bar.Starburst:Hide()
			else
				-- Default
				progressBar.Bar:SetPoint("LEFT", 2, 0)
				progressBar.Bar.BorderLeft:Hide()
				progressBar.Bar.BorderRight:Hide()
				progressBar.Bar.BorderMid:Hide()
			end

			local border1 = progressBar.Bar:CreateTexture(nil, "BACKGROUND", nil, -2)
			border1:SetPoint("TOPLEFT", -1, 1)
			border1:SetPoint("BOTTOMRIGHT", 1, -1)
			border1:SetColorTexture(0, 0, 0)

			local border2 = progressBar.Bar:CreateTexture(nil, "BACKGROUND", nil, -3)
			border2:SetPoint("TOPLEFT", -2, 2)
			border2:SetPoint("BOTTOMRIGHT", 2, -2)
			border2:SetColorTexture(0.4, 0.4, 0.4)

			progressBar.Bar.Label:SetPoint("CENTER", 0, 0.5)
			progressBar.Bar.Label:SetFont(LSM:Fetch("font", "Arial Narrow"), 13, "")
			progressBar.Bar:SetStatusBarTexture(LSM:Fetch("statusbar", profile.progressBar))
			progressBar.KTskinID = KT.skinID
			progressBar.isSkinned = true	-- ElvUI hack

			block.height = block.height + progressBar.height
		end
	end

	local bck_DEFAULT_OBJECTIVE_TRACKER_MODULE_AddProgressBar = DEFAULT_OBJECTIVE_TRACKER_MODULE.AddProgressBar
	function DEFAULT_OBJECTIVE_TRACKER_MODULE:AddProgressBar(block, line, questID)
		local progressBar = bck_DEFAULT_OBJECTIVE_TRACKER_MODULE_AddProgressBar(self, block, line, questID)
		SetProgressBarStyle(progressBar)
		return progressBar
	end

	hooksecurefunc("ObjectiveTracker_OnSlideBlockUpdate", function(block, elapsed)
		local slideData = block.slideData
		if block.slideTime >= slideData.duration + (slideData.endDelay or 0) then
			ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.FORCED)	-- update after expand collapsed tracker
		end
	end)

	if WOW_PROJECT_ID >= WOW_PROJECT_MISTS_CLASSIC then
		local bck_SCENARIO_CONTENT_TRACKER_MODULE_Update = SCENARIO_CONTENT_TRACKER_MODULE.Update
		function SCENARIO_CONTENT_TRACKER_MODULE:Update()
			local _, _, numStages, _ = C_Scenario.GetInfo()
			local BlocksFrame = SCENARIO_TRACKER_MODULE.BlocksFrame
			self.topBlock = nil
			self.lastBlock = nil
			bck_SCENARIO_CONTENT_TRACKER_MODULE_Update(self)
			if numStages > 0 and BlocksFrame.currentBlock then
				self.lastBlock = ScenarioBlocksFrame
			end
		end

		local bck_SCENARIO_TRACKER_MODULE_AddProgressBar = SCENARIO_TRACKER_MODULE.AddProgressBar
		function SCENARIO_TRACKER_MODULE:AddProgressBar(block, line, criteriaIndex)
			local progressBar = bck_SCENARIO_TRACKER_MODULE_AddProgressBar(self, block, line, criteriaIndex)
			SetProgressBarStyle(progressBar)
			return progressBar
		end

		ScenarioStageBlock:HookScript("OnEnter", function(self)
			GameTooltip:ClearAllPoints()
			if KTF.anchorLeft then
				GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 17, -1)
			else
				GameTooltip:SetPoint("TOPRIGHT", self, "TOPLEFT",  -16, -1)
			end
		end)

		ScenarioBonusHeader:HookScript("OnEnter", function(self)
			GameTooltip:ClearAllPoints()
			if KTF.anchorLeft then
				GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 17, -1)
			else
				GameTooltip:SetPoint("TOPRIGHT", self, "TOPLEFT",  -16, -1)
			end
		end)

		hooksecurefunc(AUTO_QUEST_POPUP_TRACKER_MODULE, "EndLayout", function(self)
			for i = 1, GetNumAutoQuestPopUps() do
				local questID, popUpType = GetAutoQuestPopUp(i)
				if not IsQuestBounty(questID) then
					local questTitle = GetQuestLogTitle(GetQuestLogIndexByID(questID))
					if questTitle and questTitle ~= "" then
						local block = self:GetBlock(questID)
						block.height = 68
						local blockContents = block.ScrollChild
						blockContents.QuestName:SetFont(KT.font, 14, "")
						blockContents.BottomText:SetPoint("BOTTOM", 0, 7)
					end
				end
			end
		end)
	end

	function ObjectiveTracker_Collapse()  -- R
		KT.Utils.Log("Collaspe Tracker")
		OTF.collapsed = true
		dbChar.collapsed = OTF.collapsed
		OTF.BlocksFrame:Hide()
		KTF.MinimizeButton:GetNormalTexture():SetTexCoord(0, 0.5, 0, 0.25)
		OTFHeader.Title:Show()
		MSA_CloseDropDownMenus()
	end

	function ObjectiveTracker_Expand()  -- R
		KT.Utils.Log("Expand Tracker")
		OTF.collapsed = nil
		dbChar.collapsed = OTF.collapsed
		OTF.BlocksFrame:Show()
		KTF.MinimizeButton:GetNormalTexture():SetTexCoord(0, 0.5, 0.25, 0.5)
		OTFHeader.Title:Hide()
		MSA_CloseDropDownMenus()
	end

	local bck_ObjectiveTracker_ReorderModules = ObjectiveTracker_ReorderModules
	ObjectiveTracker_ReorderModules = function()
		local reorder = false
		for i = 1, #OTF.MODULES do
			if OTF.MODULES[i] ~= OTF.MODULES_UI_ORDER[i] then
				reorder = true
				break
			end
		end
		if reorder then
			bck_ObjectiveTracker_ReorderModules()
		end
	end

	if WOW_PROJECT_ID >= WOW_PROJECT_WRATH_CLASSIC then
		hooksecurefunc("QuestPOI_UpdateButtonStyle", function(poiButton)
			if poiButton.Glow then
				poiButton.Glow:SetShown(false)
			end
		end)
	end

	local bck_UIErrorsFrame_OnEvent = UIErrorsFrame:GetScript("OnEvent")
	UIErrorsFrame:SetScript("OnEvent", function(self, event, ...)
		if profile.messageQuest and event == "UI_INFO_MESSAGE" then
			local text, _ = ...
			for _, patt in ipairs(msgPatterns) do
				if strfind(text, patt) then
					KT:SetMessage(text, 1, 1, 0, nil, "Interface\\GossipFrame\\AvailableQuestIcon", -2, 0)
					return
				end
			end
		end
		bck_UIErrorsFrame_OnEvent(self, event, ...)
	end)

	function QuestMapFrame_OpenToQuestDetails(questID)	-- R
		local mapID = GetQuestUiMapID(questID);
		if ( mapID == 0 ) then mapID = nil; end
		OpenQuestMapLog(mapID);  -- fix Blizz bug
		QuestMapFrame_ShowQuestDetails(questID);
	end

	-- Item handler functions
	function QuestObjectiveItem_OnEnter(self)  -- R
		self.block.module:OnBlockHeaderEnter(self.block)
		if KTF.anchorLeft then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 3)
		else
			GameTooltip:SetOwner(self, "ANCHOR_LEFT", -3)
		end
		GameTooltip:SetHyperlink(self.link)
	end

	function QuestObjectiveItem_OnLeave(self)
		self.block.module:OnBlockHeaderLeave(self.block)
		GameTooltip:Hide()
	end

	function QuestObjectiveItem_OnUpdate(self, elapsed)  -- R
		local rangeTimer = self.rangeTimer
		if rangeTimer then
			rangeTimer = rangeTimer - elapsed
			if rangeTimer <= 0 then
				local link, item, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(self:GetID())
				if charges and charges ~= self.charges then
					ObjectiveTracker_Update(OBJECTIVE_TRACKER_UPDATE_MODULE_QUEST)
					return
				end
				local hotkey = self.HotKey
				local valid = IsQuestLogSpecialItemInRange(self:GetID())
				if hotkey:GetText() == RANGE_INDICATOR then
					if valid == 0 then
						hotkey:Show()
						hotkey:SetVertexColor(1.0, 0.1, 0.1)
					elseif valid == 1 then
						hotkey:Show()
						hotkey:SetVertexColor(0.6, 0.6, 0.6)
					else
						hotkey:Hide()
					end
				else
					if valid == 0 then
						hotkey:SetVertexColor(1.0, 0.1, 0.1)
					else
						hotkey:SetVertexColor(0.6, 0.6, 0.6)
					end
				end
				rangeTimer = TOOLTIP_UPDATE_TIME
			end
			self.rangeTimer = rangeTimer
		end
	end

	-- DropDown
	function ObjectiveTracker_ToggleDropDown(frame, handlerFunc)  -- R
		local dropDown = KT.DropDown;
		if ( dropDown.activeFrame ~= frame ) then
			MSA_CloseDropDownMenus();
		end
		dropDown.activeFrame = frame;
		dropDown.initialize = handlerFunc;
		MSA_ToggleDropDownMenu(1, nil, dropDown, "cursor", 3, -3, nil, nil, MSA_DROPDOWNMENU_SHOW_TIME);
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	end

	function QUEST_TRACKER_MODULE:OnBlockHeaderClick(block, mouseButton)  -- R
		if ( IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow() ) then
			local questLink = GetQuestLink(block.id);
			if ( questLink ) then
				ChatEdit_InsertLink(questLink);
			end
		elseif ( mouseButton ~= "RightButton" ) then
			MSA_CloseDropDownMenus();
			if ( IsModifiedClick("QUESTWATCHTOGGLE") ) then
				QuestObjectiveTracker_UntrackQuest(nil, block.id);
			elseif IsModifiedClick(profile.menuWowheadURLModifier) then
				KT:Alert_WowheadURL("quest", block.id)
			else
				local questLogIndex = GetQuestLogIndexByID(block.id);
				if ( IsQuestComplete(block.id) and GetQuestLogIsAutoComplete(questLogIndex) ) then
					if WOW_PROJECT_ID >= WOW_PROJECT_CATACLYSM_CLASSIC then
						AutoQuestPopupTracker_RemovePopUp(block.id);
					end
					ShowQuestComplete(questLogIndex);
				else
					QuestObjectiveTracker_OpenQuestDetails(nil, block.id)
				end
			end
			return;
		else
			ObjectiveTracker_ToggleDropDown(block, QuestObjectiveTracker_OnOpenDropDown);
		end
	end

	function QuestObjectiveTracker_OnOpenDropDown(self)  -- R
		local block = self.activeFrame;
		local questLogIndex = GetQuestLogIndexByID(block.id);

		local info = MSA_DropDownMenu_CreateInfo();
		info.text = GetQuestLogTitle(questLogIndex);
		info.isTitle = 1;
		info.notCheckable = 1;
		MSA_DropDownMenu_AddButton(info, MSA_DROPDOWN_MENU_LEVEL);

		info = MSA_DropDownMenu_CreateInfo();
		info.notCheckable = 1;

		info.text = OBJECTIVES_VIEW_IN_QUESTLOG;
		info.func = QuestObjectiveTracker_OpenQuestDetails;
		info.arg1 = block.id;
		info.noClickSound = 1;
		info.checked = false;
		MSA_DropDownMenu_AddButton(info, MSA_DROPDOWN_MENU_LEVEL);

		if ( GetQuestLogPushable(questLogIndex) and IsInGroup() ) then
			info.text = SHARE_QUEST;
			info.func = QuestObjectiveTracker_ShareQuest;
			info.arg1 = block.id;
			info.checked = false;
			MSA_DropDownMenu_AddButton(info, MSA_DROPDOWN_MENU_LEVEL);
		end

		info.text = OBJECTIVES_STOP_TRACKING;
		info.func = QuestObjectiveTracker_UntrackQuest;
		info.arg1 = block.id;
		info.checked = false;
		info.disabled = (profile.filterAuto[1]);
		MSA_DropDownMenu_AddButton(info, MSA_DROPDOWN_MENU_LEVEL);

		info.text = ABANDON_QUEST;
		info.func = function(_, questID)
			QuestMapQuestOptions_AbandonQuest(questID)
		end;
		info.arg1 = block.id;
		info.disabled = not CanAbandonQuest(block.id);
		MSA_DropDownMenu_AddButton(info, MSA_DROPDOWNMENU_MENU_LEVEL);

		info.disabled = false;

		if profile.menuWowheadURL then
			info.text = "|cff33ff99Wowhead|r URL";
			info.func = KT.Alert_WowheadURL;
			info.arg1 = "quest";
			info.arg2 = block.id;
			info.checked = false;
			MSA_DropDownMenu_AddButton(info, MSA_DROPDOWN_MENU_LEVEL);
		end

		KT:SendSignal("CONTEXT_MENU_UPDATE", info, block.id)
	end

	if WOW_PROJECT_ID >= WOW_PROJECT_WRATH_CLASSIC then
		function ACHIEVEMENT_TRACKER_MODULE:OnBlockHeaderClick(block, mouseButton)  -- R
			if ( IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow() ) then
				local achievementLink = GetAchievementLink(block.id);
				if ( achievementLink ) then
					ChatEdit_InsertLink(achievementLink);
				end
			elseif ( mouseButton ~= "RightButton" ) then
				MSA_CloseDropDownMenus();
				if ( not AchievementFrame ) then
					AchievementFrame_LoadUI();
				end
				if ( IsModifiedClick("QUESTWATCHTOGGLE") ) then
					AchievementObjectiveTracker_UntrackAchievement(_, block.id);
				elseif IsModifiedClick(profile.menuWowheadURLModifier) then
					KT:Alert_WowheadURL("achievement", block.id)
				elseif ( not AchievementFrame:IsShown() ) then
					AchievementFrame_ToggleAchievementFrame();
					AchievementFrame_SelectAchievement(block.id);
				else
					if ( AchievementFrameAchievements.selection ~= block.id ) then
						AchievementFrame_SelectAchievement(block.id);
					else
						AchievementFrame_ToggleAchievementFrame();
					end
				end
			else
				ObjectiveTracker_ToggleDropDown(block, AchievementObjectiveTracker_OnOpenDropDown);
			end
		end

		function AchievementObjectiveTracker_OnOpenDropDown(self)  -- R
			local block = self.activeFrame;
			local _, achievementName, _, completed, _, _, _, _, _, icon = GetAchievementInfo(block.id);

			local info = MSA_DropDownMenu_CreateInfo();
			info.text = achievementName;
			info.isTitle = 1;
			info.notCheckable = 1;
			MSA_DropDownMenu_AddButton(info, MSA_DROPDOWN_MENU_LEVEL);

			info = MSA_DropDownMenu_CreateInfo();
			info.notCheckable = 1;

			info.text = OBJECTIVES_VIEW_ACHIEVEMENT;
			info.func = function (button, ...) OpenAchievementFrameToAchievement(...); end;
			info.arg1 = block.id;
			info.checked = false;
			MSA_DropDownMenu_AddButton(info, MSA_DROPDOWN_MENU_LEVEL);

			info.text = OBJECTIVES_STOP_TRACKING;
			info.func = AchievementObjectiveTracker_UntrackAchievement;
			info.arg1 = block.id;
			info.checked = false;
			info.disabled = (profile.filterAuto[2]);
			MSA_DropDownMenu_AddButton(info, MSA_DROPDOWN_MENU_LEVEL);

			info.disabled = false;

			if profile.menuWowheadURL then
				info.text = "|cff33ff99Wowhead|r URL";
				info.func = KT.Alert_WowheadURL;
				info.arg1 = "achievement";
				info.arg2 = block.id;
				info.checked = false;
				MSA_DropDownMenu_AddButton(info, MSA_DROPDOWN_MENU_LEVEL);
			end
		end
	end
end

--------------
-- External --
--------------

function KT:Update(forced)
	self:SetForced(forced)
	ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.FORCED)
end

function KT:MinimizeButton_OnClick()
	ObjectiveTracker_MinimizeButton_OnClick()
end

function KT:SetSize()
	local height = 33
	local mod = 0

	if OTF.BlocksFrame.contentsHeight then
		OTF.BlocksFrame.contentsHeight = round(OTF.BlocksFrame.contentsHeight)
	else
		return
	end

	if not dbChar.collapsed and not self:IsTrackerEmpty() then
		-- width
		KTF:SetWidth(trackerWidth)

		-- height
		height = OTF.BlocksFrame.contentsHeight + mod + 10 + paddingBottom
		OTF.height = height

		if height > profile.maxHeight then
			if KTF.Scroll.value > OTF.height-profile.maxHeight then
				KTF.Scroll.value = OTF.height - profile.maxHeight
			end
			KTF.Scroll:SetVerticalScroll(KTF.Scroll.value)
			if profile.frameScrollbar then
				SetScrollbarPosition()
				KTF.Bar:Show()
			end
			height = profile.maxHeight
		elseif height <= profile.maxHeight then
			if KTF.Scroll.value > 0 then
				KTF.Scroll.value = 0
				KTF.Scroll:SetVerticalScroll(0)
			end
			if profile.frameScrollbar then
				KTF.Bar:Hide()
			end
		end
		if height ~= KTF.height then
			KTF:SetHeight(height)
			KTF.height = height
		end
		self:MoveQuestButtonBar()
	else
		-- width
		if profile.headerCollapsedTxt == 1 then
			local width = 35
			if KTF.FilterButton then
				width = width + 20
			end
			if profile.headerOtherButtons then
				if KTF.AchievementsButton then
					width = width + 20
				end
				if KTF.QuestLogButton then
					width = width + 20
				end
			end
			KTF:SetWidth(width)
		else
			KTF:SetWidth(trackerWidth)
		end

		-- height
		OTF.height = height - 10
		OTF:SetHeight(OTF.height)
        if OTF.BlocksFrame.contentsHeight == 0 then
            KTF.Scroll.value = 0
        end
		KTF.Scroll:SetVerticalScroll(0)
		if profile.frameScrollbar then
			KTF.Bar:Hide()
		end
		if height ~= KTF.height then
			KTF:SetHeight(height)
			KTF.height = height
		end
	end
end

function KT:MoveTracker()
	KTF:ClearAllPoints()
	KTF:SetPoint(profile.anchorPoint, UIParent, profile.anchorPoint, profile.xOffset, profile.yOffset)
	KTF.directionUp = (profile.anchorPoint == "BOTTOMLEFT" or profile.anchorPoint == "BOTTOMRIGHT")
	KTF.anchorLeft = (profile.anchorPoint == "TOPLEFT" or profile.anchorPoint == "BOTTOMLEFT")

	local options = self.options.args.general.args.sec1.args
	if KTF.anchorLeft then
		options.xOffset.min = 0
		options.xOffset.max = self.screenWidth - trackerWidth
	else
		options.xOffset.min = -(self.screenWidth - trackerWidth)
		options.xOffset.max = 0
	end

	if KTF.directionUp then
		options.yOffset.min = 0
		options.yOffset.max = self.screenHeight - options.maxHeight.min
	else
		options.yOffset.min = -(self.screenHeight - options.maxHeight.min)
		options.yOffset.max = 0
	end

	options.maxHeight.max = self.screenHeight - abs(profile.yOffset)
	profile.maxHeight = (abs(profile.yOffset)+profile.maxHeight > self.screenHeight) and options.maxHeight.max or profile.maxHeight

	self:MoveQuestButtonBar()
end

function KT:SetShown(show)
	KTF:SetShown(show)
	KTF.QuestButtonBar:SetShown(show)
end

function KT:SetBackground()
	local backdrop = {
		bgFile = LSM:Fetch("background", profile.bgr),
		edgeFile = LSM:Fetch("border", profile.border),
		edgeSize = profile.borderThickness,
		insets = { left=profile.bgrInset, right=profile.bgrInset, top=profile.bgrInset, bottom=profile.bgrInset }
	}
	self.borderColor = profile.classBorder and self.classColor or profile.borderColor

	KTF:SetBackdrop(backdrop)
	KTF:SetBackdropColor(profile.bgrColor.r, profile.bgrColor.g, profile.bgrColor.b, profile.bgrColor.a)
	KTF:SetBackdropBorderColor(self.borderColor.r, self.borderColor.g, self.borderColor.b, profile.borderAlpha)

	SetHeaders("background")

	self.headerBtnColor = profile.headerBtnColorShare and self.borderColor or profile.headerBtnColor
	KTF.MinimizeButton:GetNormalTexture():SetVertexColor(self.headerBtnColor.r, self.headerBtnColor.g, self.headerBtnColor.b)
	if self.Filters:IsEnabled() then
		if profile.filterAuto[1] or profile.filterAuto[2] or profile.filterAuto[3] then
			KTF.FilterButton:GetNormalTexture():SetVertexColor(0, 1, 0)
		else
			KTF.FilterButton:GetNormalTexture():SetVertexColor(self.headerBtnColor.r, self.headerBtnColor.g, self.headerBtnColor.b)
		end
	end
	if profile.headerOtherButtons then
		KTF.QuestLogButton:GetNormalTexture():SetVertexColor(self.headerBtnColor.r, self.headerBtnColor.g, self.headerBtnColor.b)
		if WOW_PROJECT_ID >= WOW_PROJECT_WRATH_CLASSIC then
			KTF.AchievementsButton:GetNormalTexture():SetVertexColor(self.headerBtnColor.r, self.headerBtnColor.g, self.headerBtnColor.b)
		end
	end

	if profile.questBarBtnBackgroundBorder then
		KTF.QuestButtonBar:SetBackdrop(backdrop)
		KTF.QuestButtonBar:SetBackdropColor(profile.bgrColor.r, profile.bgrColor.g, profile.bgrColor.b, profile.bgrColor.a)
		KTF.QuestButtonBar:SetBackdropBorderColor(self.borderColor.r, self.borderColor.g, self.borderColor.b, profile.borderAlpha)
	else
		KTF.QuestButtonBar:SetBackdrop(nil)
	end

	KTF.Bar.texture:SetColorTexture(self.borderColor.r, self.borderColor.g, self.borderColor.b, profile.borderAlpha)

	if profile.bgr == "None" and profile.border == "None" then
		KTF.Scroll:SetHitRectInsets(-150, 0, 0, 0.1)
	else
		KTF.Scroll:SetHitRectInsets(0.1, 0, 0, 0.1)
    end

    OTFHeader.Title:SetJustifyH(profile.bgr == "None" and "RIGHT" or "LEFT")
end

function KT:SetText(forced)
	if forced then
		self.skinID = self.skinID + 1
	end

	self.font = LSM:Fetch("font", profile.font)

	KT.OBJECTIVE_TRACKER_DOUBLE_LINE_HEIGHT = (2 * profile.fontSize) + 1

	-- Headers
	SetHeaders("text")

	-- Others
	if WOW_PROJECT_ID >= WOW_PROJECT_MISTS_CLASSIC then
		if ScenarioBlocksFrame.KTskinID ~= KT.skinID then
			ScenarioStageBlock.Stage:SetFont(self.font, profile.fontSize+5, profile.fontFlag)
			ScenarioStageBlock.Name:SetFont(self.font, profile.fontSize, profile.fontFlag)
			ScenarioStageBlock.CompleteLabel:SetFont(self.font, profile.fontSize+5, profile.fontFlag)
			ScenarioBonusHeader.Label:SetFont(self.font, profile.fontSize, profile.fontFlag)
			ScenarioChallengeModeBlock.TimeLeft:SetFont(LSM:Fetch("font", "Arial Narrow"), 19, "")
			ScenarioProvingGroundsBlock.WaveLabel:SetFont(self.font, profile.fontSize+2, profile.fontFlag)
			ScenarioProvingGroundsBlock.Wave:SetFont(self.font, profile.fontSize+2, profile.fontFlag)
			ScenarioBlocksFrame.KTskinID = KT.skinID
		end
	end
end

function KT:SaveHeader(module)
	module.Header.Text:SetWidth(165)
	module.Header.LineGlow:Hide()
	module.Header.SoftGlow:Hide()
	module.Header.StarBurst:Hide()
	module.Header.LineSheen:Hide()
	tinsert(KT.headers, module.Header)
	module.title = module.Header.Text:GetText()
end

function KT:SetHeaderText(module, append)
	local text = module.title
	if append then
		text = format("%s (%s)", text, append)
	end
	module.Header.Text:SetText(text)
end

function KT:SetQuestsHeaderText(reset)
	if profile.questsHeaderTitleAppend then
		local _, numQuests = GetNumQuestLogEntries()
		self:SetHeaderText(QUEST_TRACKER_MODULE, numQuests.."/"..MAX_QUESTLOG_QUESTS)
	elseif reset then
		self:SetHeaderText(QUEST_TRACKER_MODULE)
	end
end

function KT:SetAchievementsHeaderText(reset)
	if WOW_PROJECT_ID < WOW_PROJECT_WRATH_CLASSIC then return end
	if profile.achievementsHeaderTitleAppend then
		self:SetHeaderText(ACHIEVEMENT_TRACKER_MODULE, GetTotalAchievementPoints())
	elseif reset then
		self:SetHeaderText(ACHIEVEMENT_TRACKER_MODULE)
	end
end

function KT:ToggleOtherButtons()
	if profile.headerOtherButtons then
		local button
		-- Achievements button
		if WOW_PROJECT_ID >= WOW_PROJECT_WRATH_CLASSIC then
			if KTF.AchievementsButton then
				KTF.AchievementsButton:Show()
			else
				button = CreateFrame("Button", addonName.."AchievementsButton", KTF)
				button:SetSize(16, 16)
				button:SetPoint("TOPRIGHT", (KTF.FilterButton or KTF.MinimizeButton), "TOPLEFT", -4, 0)
				button:SetFrameLevel(KTF:GetFrameLevel() + 10)
				button:SetNormalTexture(KT.MEDIA_PATH.."UI-KT-HeaderButtons")
				button:GetNormalTexture():SetTexCoord(0.5, 1, 0.25, 0.5)
				button:RegisterForClicks("AnyDown")
				button:SetScript("OnClick", function(self, btn)
					ToggleAchievementFrame()
				end)
				button:SetScript("OnEnter", function(self)
					self:GetNormalTexture():SetVertexColor(1, 1, 1)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:AddLine(AchievementMicroButton.tooltipText, 1, 1, 1)
					GameTooltip:Show()
				end)
				button:SetScript("OnLeave", function(self)
					self:GetNormalTexture():SetVertexColor(KT.headerBtnColor.r, KT.headerBtnColor.g, KT.headerBtnColor.b)
					GameTooltip:Hide()
				end)
				KTF.AchievementsButton = button
			end
			OTFHeader.Title:SetWidth(OTFHeader.Title:GetWidth() - 20)
		end

		-- Quest Log button
		if KTF.QuestLogButton then
			KTF.QuestLogButton:Show()
		else
			button = CreateFrame("Button", addonName.."QuestLogButton", KTF)
			button:SetSize(16, 16)
			button:SetPoint("TOPRIGHT", (KTF.AchievementsButton or KTF.FilterButton or KTF.MinimizeButton), "TOPLEFT", -4, 0)
			button:SetFrameLevel(KTF:GetFrameLevel() + 10)
			button:SetNormalTexture(KT.MEDIA_PATH.."UI-KT-HeaderButtons")
			button:GetNormalTexture():SetTexCoord(0.5, 1, 0, 0.25)
			button:RegisterForClicks("AnyDown")
			button:SetScript("OnClick", function(self, btn)
				ToggleQuestLog()
			end)
			button:SetScript("OnEnter", function(self)
				self:GetNormalTexture():SetVertexColor(1, 1, 1)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:AddLine(QuestLogMicroButton.tooltipText, 1, 1, 1)
				GameTooltip:Show()
			end)
			button:SetScript("OnLeave", function(self)
				self:GetNormalTexture():SetVertexColor(KT.headerBtnColor.r, KT.headerBtnColor.g, KT.headerBtnColor.b)
				GameTooltip:Hide()
			end)
			KTF.QuestLogButton = button
		end
		OTFHeader.Title:SetWidth(OTFHeader.Title:GetWidth() - 20)
	else
		if KTF.AchievementsButton then
			KTF.AchievementsButton:Hide()
			OTFHeader.Title:SetWidth(OTFHeader.Title:GetWidth() + 20)
		end
		if KTF.QuestLogButton then
			KTF.QuestLogButton:Hide()
			OTFHeader.Title:SetWidth(OTFHeader.Title:GetWidth() + 20)
		end
	end
end

function KT:MoveQuestButtonBar()
	if InCombatLockdown() then return end

	local parentAnchor = "BOTTOMLEFT"
	local point, xOfs, yOfs
	if KTF.anchorLeft then
		point = "LEFT"
		xOfs = KTF:GetRight() and KTF:GetRight() + profile.questBarXOffset
	else
		point = "RIGHT"
		xOfs = KTF:GetLeft() and KTF:GetLeft() - profile.questBarXOffset
	end

	local hMod = 2 * (4 - profile.bgrInset)
	local yMod = 0
	if not profile.questBarBtnBackgroundBorder then
		hMod = hMod + 4
		yMod = 2 + (4 - profile.bgrInset)
	end

	if KTF.directionUp and (profile.maxHeight + hMod) < KTF.QuestButtonBar:GetHeight() then
		point = "BOTTOM"..point
		yOfs = KTF:GetBottom() and KTF:GetBottom() - yMod - profile.questBarYOffset
	else
		point = "TOP"..point
		yOfs = KTF:GetTop() and KTF:GetTop() + yMod + profile.questBarYOffset
	end

	if not profile.anchorQuestBar then
		xOfs = profile.questBarXOffset
		yOfs = profile.questBarYOffset
		if profile.questBarAnchor == "AUTO" then
			parentAnchor = "CENTER"
		else
			parentAnchor = profile.questBarAnchor
		end
	end


	if xOfs and yOfs then
		KTF.QuestButtonBar:ClearAllPoints()
		KTF.QuestButtonBar:SetPoint(point, UIParent, parentAnchor, xOfs, yOfs)
		end
end

function KT:RemoveFixedButton(block)
	if block then
		local tag = block.fixedTag
		if tag then
			tinsert(freeTags, tag)
			tag.text:SetText("")
			tag:Hide()
			block.fixedTag = nil
		end
		local questID = block.id
		local button = self:GetFixedButton(questID)
		if button then
			button:SetAlpha(0)
			if InCombatLockdown() then
				KT.Utils.Log(" - STOP Remove button")
				combatLockdown = true
			else
				KT.Utils.Log(" - REMOVE button "..questID)
				tinsert(freeButtons, button)
				self.questButtons[questID] = nil
				button:Hide()
				KTF.QuestButtonBar.reanchor = true
			end
		end
	else
		for questID, button in pairs(self.questButtons) do
			KT.Utils.Log(" - REMOVE button "..questID)
			tinsert(freeButtons, button)
			self.questButtons[questID] = nil
			button:Hide()
		end
		KTF.QuestButtonBar.reanchor = true
	end
end

function KT:GetFixedButton(questID)
	if self.questButtons[questID] then
		return self.questButtons[questID]
	else
		return nil
	end
end

function KT:CreateQuestLevel(level)
	if level == -1 then
		level = "*"
	else
		level = tostring(level)
	end
	return format("[%s] ", level)
end

function KT:CreateQuestTag(questTag, frequency, suggestedGroup)
	local tagIcons = ""
	local texCoords
	if questTag then
		if questTag == Enum.QuestTag.Scenario then
			tagIcons = tagIcons.."S"
		elseif questTag == Enum.QuestTag.Legendary then
			tagIcons = tagIcons..self.CreateQuestTagIcon(nil, 7, 12, 2, 0, 0.055, 0.134, 0.28125, 0.5625)
		else
			texCoords = QuestUtils_GetQuestTagTextureCoords(questTag)
			if texCoords then
				tagIcons = tagIcons..self.CreateQuestTagIcon(nil, 12, 12, 0, 0, unpack(texCoords))
			end
		end
	end
	if frequency > 1 then  -- daily
		tagIcons = tagIcons..self.CreateQuestTagIcon(nil, 7, 12, 2, 0, 0.34, 0.425, 0, 0.28125)
		if frequency == 3 then  -- weekly
			tagIcons = tagIcons..self.CreateQuestTagIcon(nil, 7, 12, 0, 0, 0.34, 0.425, 0, 0.28125)
		end
	end
	if tagIcons ~= "" then
		tagIcons = format(" |cff00b3ff%s|r", tagIcons)
	end
	return tagIcons
end

function KT:IsTrackerEmpty(noaddon)
	local result = (GetNumQuestWatches() == 0 and
		GetNumAutoQuestPopUps() == 0 and
		GetNumTrackedAchievements() == 0 and
		not self.inScenario)
	if not noaddon then
		if WOW_PROJECT_ID >= WOW_PROJECT_MISTS_CLASSIC then
			result = (result and not self.AddonPetTracker:IsShown())
		end
	end
	return result
end

function KT:ToggleEmptyTracker(added)
	local alpha, mouse = 1, true
	if self:IsTrackerEmpty() then
		if not dbChar.collapsed then
			ObjectiveTracker_Collapse()
			self.forceExpand = (profile.filterAuto[1] or profile.filterAuto[2])
		end
		KTF.MinimizeButton:GetNormalTexture():SetTexCoord(0, 0.5, 0.5, 0.75)
		if profile.hideEmptyTracker then
			alpha = 0
			mouse = false
		end
	else
		if dbChar.collapsed then
			if self.forceExpand or (profile.expandTrackerAfterTrack and added) then
				ObjectiveTracker_Expand()
				self.forceExpand = false
			else
				KTF.MinimizeButton:GetNormalTexture():SetTexCoord(0, 0.5, 0, 0.25)
			end
		else
			KTF.MinimizeButton:GetNormalTexture():SetTexCoord(0, 0.5, 0.25, 0.5)
		end
	end
	KTF:SetAlpha(alpha)
	KTF.MinimizeButton:EnableMouse(mouse)
	if self.Filters:IsEnabled() then
		KTF.FilterButton:EnableMouse(mouse)
	end
	if profile.headerOtherButtons then
		KTF.QuestLogButton:EnableMouse(mouse)
		if WOW_PROJECT_ID >= WOW_PROJECT_WRATH_CLASSIC then
			KTF.AchievementsButton:EnableMouse(mouse)
		end
	end
end

function KT:SetMessage(text, r, g, b, pattern, icon, x, y)
	if pattern then
		text = format(pattern, text.." ...")
	end
	if icon then
		x = x or 0
		y = y or 0
		if profile.sink20OutputSink == "Blizzard" then
			x = floor(x * 3)
			y = y - 8
		end
		text = format("|T%s:0:0:%d:%d|t%s", icon, x, y, text)
	end
	self:Pour(text, r, g, b)
end

function KT:PlaySound(key)
	PlaySoundFile(LSM:Fetch("sound", key))
end

function KT:UpdateHotkey()
	local key = GetBindingKey("EXTRAACTIONBUTTON1")
	if profile.keyBindMinimize == key then
		SetOverrideBinding(KTF, false, profile.keyBindMinimize, nil)
		profile.keyBindMinimize = ""
	end
end

-- Load ----------------------------------------------------------------------------------------------------------------

function KT:OnInitialize()
	KT.Utils.Log("|cffffff00Init|r - "..self:GetName())

	SLASH_KALIELSTRACKER1, SLASH_KALIELSTRACKER2 = "/kt", "/kalielstracker"
	SlashCmdList["KALIELSTRACKER"] = SlashHandler

	SetMsgPatterns()

	-- Get character data
	self.playerName = UnitName("player")
	self.playerFaction = UnitFactionGroup("player")
	self.playerLevel = UnitLevel("player")
	local class
	self.playerClass, class = UnitClass("player")
	self.classColor = RAID_CLASS_COLORS[class]

	self.headers = {}
	self.borderColor = {}
	self.headerBtnColor = {}
	self.questButtons = {}
	self.skinID = 0
	self.inWorld = false
	self.inInstance = IsInInstance()
	self.inScenario = C_Scenario.IsInScenario() and not self.IsScenarioHidden()
	self.stopUpdate = true
	self.questStateStopUpdate = false
	self.forceExpand = false
	self.locked = false
	self.initialized = false

	-- Blizzard frame resets
	WatchFrame:Hide()
	WatchFrame.Show = Noop
	OTF.IsUserPlaced = function() return true end
	OTF.KTSetParent = OTF.SetParent
	OTF.SetParent = Noop
	OTF.SetFrameStrata = Noop
	OTF.SetFrameLevel = Noop
	OTF:SetClampedToScreen(false)
	OTF.SetClampedToScreen = Noop
	OTF:EnableMouse(false)
	OTF.EnableMouse = Noop
	OTF:SetMovable(false)
	OTF.SetMovable = Noop
	OTF:ClearAllPoints()
	OTF.ClearAllPoints = Noop
	OTF.SetAllPoints = Noop
	OTF.KTSetPoint = OTF.SetPoint
	OTF.SetPoint = Noop
	OTF:Show()
	OTF.Show = Noop
	OTF.Hide = Noop
	OTF.SetShown = Noop
end

function KT:OnEnable()
	KT.Utils.Log("|cff00ff00Enable|r - "..self:GetName())
	profile = self.db.profile
	dbChar = self.db.char

	self:Alert_ResetIncompatibleProfiles("3.1.0")

	self:InitSubsystems({
		Quests = { dbChar.quests.cache }
	})

	self.initCollapsed = dbChar.collapsed
	self.screenWidth = round(GetScreenWidth())
	self.screenHeight = round(GetScreenHeight())

	SetFrames()
	SetHooks()

	self:RegSignal("OPTIONS_CHANGED", "Update")
	self:RegEvent("PLAYER_ENTERING_WORLD", function(eventID)
		ObjectiveTracker_Initialize(OTF)
		Init()
		self:UnregEvent(eventID)
	end)

	self:EnableModules()

	if self.db.global.version ~= self.VERSION then
		self.db.global.version = self.VERSION
	end

	profile.modulesOrder = self.ReconcileOrder(self.BLIZZARD_MODULES, profile.modulesOrder)
end