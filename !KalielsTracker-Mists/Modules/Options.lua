--- Kaliel's Tracker
--- Copyright (c) 2012-2026, Marouan Sabbagh <mar.sabbagh@gmail.com>
--- All Rights Reserved.
---
--- This file is part of addon Kaliel's Tracker.

local addonName, addon = ...
---@class KT
local KT = addon

---@class Options
local OptionModule = KT:NewModule("Options")
KT.Options = OptionModule

local ACD = LibStub("MSA-AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local WidgetLists = AceGUIWidgetLSMlists

-- Lua API
local gsub = string.gsub
local ipairs = ipairs
local pairs = pairs
local strsplit = string.split
local strsub = string.sub

local profile

local anchors = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }
---@type Direction[]
local DIR_OPTIONS = { "Up", "Down", "Left", "Right" }

local SCREEN_HEIGHT = math.floor(GetScreenHeight())
local SCREEN_WIDTH = math.floor(GetScreenWidth())

local strata = { "LOW", "MEDIUM", "HIGH" }
local flags = { [""] = "None", ["OUTLINE"] = "Outline", ["OUTLINE, MONOCHROME"] = "Outline Monochrome" }
local textures = { "None", "Default (Blizzard)", "One line", "Two lines" }
local modifiers = { [""] = "None", ["ALT"] = "Alt", ["CTRL"] = "Ctrl", ["ALT-CTRL"] = "Alt + Ctrl" }
local ICON_HEART = "|T"..KT.MEDIA_PATH.."Help\\help_patreon:14:14:0:0:256:32:174:190:0:16|t"

local cTitle = " "..NORMAL_FONT_COLOR_CODE
local cBold = "|cff00ffe3"
local cWarning = "|cffff7f00"
local warning = cWarning.."Warning:|r UI will be re-loaded!"

local KTF = KT.frame
local OTF = KT_ObjectiveTrackerFrame

local trackerMaxHeightGizmo
local overlayShown = false

local _, numQuests = GetNumQuestLogEntries()

local OverlayFrameUpdate, OverlayFrameHide, GetModulesOptionsTable, MoveModule, SetSharedColor	-- functions

---@class KT.Profile
local defaultProfile = {
	anchorPoint = "TOPRIGHT",
	xOffset = -115,
	yOffset = -280,
	maxHeight = 400,
	frameScrollbar = true,
	frameStrata = "LOW",

	bgr = "Solid",
	bgrColor = { r = 0, g = 0, b = 0, a = 0.7 },
	border = "None",
	borderColor = { r = 1, g = 0.82, b = 0 },
	classBorder = false,
	borderAlpha = 1,
	borderThickness = 16,
	bgrInset = 4,
	progressBar = "Blizzard",

	font = LSM:GetDefault("font"),
	fontSize = 12,
	fontFlag = "",
	fontShadow = 1,
	colorDifficulty = false,
	textWordWrap = false,

	headerBgr = 2,
	headerBgrColor = { r = 1, g = 0.82, b = 0 },
	headerBgrColorShare = false,
	headerTxtColor = { r = 1, g = 0.82, b = 0 },
	headerTxtColorShare = false,
	headerBtnColor = { r = 1, g = 0.82, b = 0 },
	headerBtnColorShare = false,
	headerCollapsedTxt = 3,
	headerOtherButtons = true,
	keyBindMinimize = "",

	enableQuestBarBackground = false,
	anchorQuestBar = true,
	buttonBarDirection = "Down",
	questBarXOffset = -5,
	questBarYOffset = 0,

	hideEmptyTracker = false,
	collapseInInstance = false,
	expandTrackerAfterTrack = true,
	menuWowheadURL = true,
	menuWowheadURLModifier = "ALT",

	messageQuest = true,
	messageAchievement = true,
	sink20OutputSink = "UIErrorsFrame",
	sink20Sticky = false,
	soundQuest = true,
	soundQuestComplete = "KT - Default",
	useSoundKit = false,
	useRandomSoundKit = true,
	selectedSoundKits = {},

	questsHeaderTitleAppend = true,
	questsShowLevels = true,
	questsShowTags = true,
	questsShowZones = true,
	questsObjectiveNumSwitch = true,

	achievementsHeaderTitleAppend = true,

	tooltipShow = true,
	tooltipShowRewards = true,
	tooltipShowID = true,

	pettrackerHeaderTitleAppend = true,

	modulesOrder = KT.BLIZZARD_MODULES,

	addonQuestie = false,
	addonPetTracker = false,
}

---@class DEFAULT_OPTIONS
local defaults = {
	profile = defaultProfile,
	char = {
		collapsed = false,
		quests = {
			cache = {}
		},
	}
}

local options = {
	name = "|T"..KT.MEDIA_PATH.."KT_logo:22:22:-1:7|t"..KT.TITLE,
	type = "group",
	get = function(info) return profile[info[#info]] end,
	args = {
		general = {
			name = "Options",
			type = "group",
			args = {
				infoSection = {
					name = "Info",
					type = "group",
					inline = true,
					order = 0,
					args = {
						version = {
							name = " |cffffd100Version:|r  "..KT.VERSION,
							type = "description",
							width = "normal",
							fontSize = "medium",
							order = 0.11,
						},
						build = {
							name = " |cffffd100Build:|r  "..KT.BUILD_NAME,
							type = "description",
							width = "normal",
							fontSize = "medium",
							order = 0.12,
						},
						slashCmd = {
							name = cBold.." /kt|r  |cff808080...............|r  Toggle (expand/collapse) the tracker\n"..
									cBold.." /kt config|r  |cff808080...|r  Show this config window\n",
							type = "description",
							width = "double",
							order = 0.3,
						},
						news = {
							name = "What's New",
							type = "execute",
							disabled = function()
								return not KT.Help:IsEnabled()
							end,
							func = function()
								KT.Help:ShowHelp(true)
							end,
							order = 0.2,
						},
						help = {
							name = "Help",
							type = "execute",
							disabled = function()
								return not KT.Help:IsEnabled()
							end,
							func = function()
								KT.Help:ShowHelp()
							end,
							order = 0.4,
						},
						about = {
							name = " Made with "..ICON_HEART.." since 2012\n"..
									" |cff999999by "..KT.AUTHOR,
							type = "description",
							width = "normal",
							order = 0.51,
						},
						supportersLabel = {
							name = "                   |cff00ff00Become a Patron",
							type = "description",
							width = "normal",
							fontSize = "medium",
							order = 0.52,
						},
						supporters = {
							name = "Supporters",
							type = "execute",
							disabled = function()
								return not KT.Help:IsEnabled()
							end,
							func = function()
								KT.Help:ShowSupporters()
							end,
							order = 0.53,
						},
					},
				},
				positionSection = {
					name = "Position / Size",
					type = "group",
					inline = true,
					order = 1,
					args = {
						anchorPoint = {
							name = "Anchor point",
							desc = "- Default: "..defaults.profile.anchorPoint,
							type = "select",
							values = anchors,
							get = function()
								for k, v in ipairs(anchors) do
									if profile.anchorPoint == v then
										return k
									end
								end
							end,
							set = function(_, value)
								profile.anchorPoint = anchors[value]
								profile.xOffset = 0
								profile.yOffset = 0
								KT:MoveTracker()
								OverlayFrameUpdate()
							end,
							order = 1.1,
						},
						xOffset = {
							name = "X offset",
							desc = "- Default: "..defaults.profile.xOffset.."\n- Step: 1",
							type = "range",
							min = 0,
							max = 0,
							step = 1,
							set = function(_, value)
								profile.xOffset = value
								KT:MoveTracker()
							end,
							order = 1.2,
						},
						yOffset = {
							name = "Y offset",
							desc = "- Default: "..defaults.profile.yOffset.."\n- Step: 2",
							type = "range",
							min = 0,
							max = 0,
							step = 2,
							set = function(_, value)
								profile.yOffset = value
								KT:MoveTracker()
								KT:SetSize()
								OverlayFrameUpdate()
							end,
							order = 1.3,
						},
						maxHeight = {
							name = "Max. height",
							desc = "- Default: "..defaults.profile.maxHeight.."\n- Step: 2",
							type = "range",
							min = 100,
							max = 100,
							step = 2,
							set = function(_, value)
								profile.maxHeight = value
								KT:SetSize()
								OverlayFrameUpdate()
							end,
							order = 1.4,
						},
						maxHeightShowOverlay = {
							name = "Show Max. height overlay",
							desc = "Show overlay, for better visualisation Max. height value.",
							type = "toggle",
							width = 1.3,
							get = function() return overlayShown end,
							set = function()
								overlayShown = not overlayShown
								if overlayShown and not trackerMaxHeightGizmo then
									trackerMaxHeightGizmo = CreateFrame("Frame", KTF:GetName().."Overlay", KTF)
									trackerMaxHeightGizmo:SetFrameLevel(KTF:GetFrameLevel() + 11)
									trackerMaxHeightGizmo.texture = trackerMaxHeightGizmo:CreateTexture(nil, "BACKGROUND")
									trackerMaxHeightGizmo.texture:SetAllPoints()
									trackerMaxHeightGizmo.texture:SetColorTexture(0, 1, 0, 0.3)
									OverlayFrameUpdate()
								end
								trackerMaxHeightGizmo:SetShown(overlayShown)
							end,
							order = 1.5,
						},
						maxHeightNote = {
							name = cBold.."\n Max. height is related with value Y offset.\n"..
								" Content is lesser ... tracker height is automatically increases.\n"..
								" Content is greater ... tracker enables scrolling.",
							type = "description",
							order = 1.6,
						},
						frameScrollbar = {
							name = "Show scroll indicator",
							desc = "Show scroll indicator when srolling is enabled. Color is shared with border.",
							type = "toggle",
							set = function()
								profile.frameScrollbar = not profile.frameScrollbar
								KTF.Bar:SetShown(profile.frameScrollbar)
								KT:SetSize()
							end,
							order = 1.7,
						},
						frameStrata = {
							name = "Strata",
							desc = "- Default: "..defaults.profile.frameStrata,
							type = "select",
							values = strata,
							get = function()
								for k, v in ipairs(strata) do
									if profile.frameStrata == v then
										return k
									end
								end
							end,
							set = function(_, value)
								profile.frameStrata = strata[value]
								KTF:SetFrameStrata(strata[value])
								KTF.QuestButtonBar:SetFrameStrata(strata[value])
							end,
							order = 1.8,
						},
					},
				},
				backgroundSection = {
					name = "Background / Border",
					type = "group",
					inline = true,
					order = 2,
					args = {
						bgr = {
							name = "Background texture",
							type = "select",
							dialogControl = "LSM30_Background",
							values = WidgetLists.background,
							set = function(_, value)
								profile.bgr = value
								KT:SetBackground()
							end,
							order = 2.1,
						},
						bgrColor = {
							name = "Background color",
							type = "color",
							hasAlpha = true,
							get = function()
								return profile.bgrColor.r, profile.bgrColor.g, profile.bgrColor.b, profile.bgrColor.a
							end,
							set = function(_, r, g, b, a)
								profile.bgrColor.r = r
								profile.bgrColor.g = g
								profile.bgrColor.b = b
								profile.bgrColor.a = a
								KT:SetBackground()
							end,
							order = 2.2,
						},
						bgrNote = {
							name = cBold.." For a custom background\n texture set white color.",
							type = "description",
							width = "normal",
							order = 2.21,
						},
						border = {
							name = "Border texture",
							type = "select",
							dialogControl = "LSM30_Border",
							values = WidgetLists.border,
							set = function(_, value)
								profile.border = value
								KT:SetBackground()
								KT:AnchorQuestButtonBar()
							end,
							order = 2.3,
						},
						borderColor = {
							name = "Border color",
							type = "color",
							disabled = function()
								return profile.classBorder
							end,
							get = function()
								if not profile.classBorder then
									SetSharedColor(profile.borderColor)
								end
								return profile.borderColor.r, profile.borderColor.g, profile.borderColor.b
							end,
							set = function(_, r, g, b)
								profile.borderColor.r = r
								profile.borderColor.g = g
								profile.borderColor.b = b
								KT:SetBackground()
								KT:SetText()
								SetSharedColor(profile.borderColor)
							end,
							order = 2.4,
						},
						classBorder = {
							name = "Border color by |cff%sClass|r",
							type = "toggle",
							get = function(info)
								if profile[info[#info]] then
									SetSharedColor(KT.classColor)
								end
								return profile[info[#info]]
							end,
							set = function()
								profile.classBorder = not profile.classBorder
								KT:SetBackground()
								KT:SetText()
							end,
							order = 2.5,
						},
						borderAlpha = {
							name = "Border transparency",
							desc = "- Default: "..defaults.profile.borderAlpha.."\n- Step: 0.05",
							type = "range",
							min = 0.1,
							max = 1,
							step = 0.05,
							set = function(_, value)
								profile.borderAlpha = value
								KT:SetBackground()
							end,
							order = 2.6,
						},
						borderThickness = {
							name = "Border thickness",
							desc = "- Default: "..defaults.profile.borderThickness.."\n- Step: 0.5",
							type = "range",
							min = 1,
							max = 24,
							step = 0.5,
							set = function(_, value)
								profile.borderThickness = value
								KT:SetBackground()
							end,
							order = 2.7,
						},
						bgrInset = {
							name = "Background inset",
							desc = "- Default: "..defaults.profile.bgrInset.."\n- Step: 0.5",
							type = "range",
							min = 0,
							max = 10,
							step = 0.5,
							set = function(_, value)
								profile.bgrInset = value
								KT:SetBackground()
								KT:AnchorQuestButtonBar()
							end,
							order = 2.8,
						},
						progressBar = {
							name = "Progress bar texture",
							type = "select",
							dialogControl = "LSM30_Statusbar",
							values = WidgetLists.statusbar,
							set = function(_, value)
								profile.progressBar = value
								KT:SendSignal("OPTIONS_CHANGED", true)
							end,
							order = 2.9,
						},
					},
				},
				textSection = {
					name = "Texts",
					type = "group",
					inline = true,
					order = 3,
					args = {
						font = {
							name = "Font",
							type = "select",
							dialogControl = "LSM30_Font",
							values = WidgetLists.font,
							set = function(_, value)
								profile.font = value
								KT:SetText(true)
								KT:SendSignal("OPTIONS_CHANGED")
							end,
							order = 3.1,
						},
						fontSize = {
							name = "Font size",
							type = "range",
							min = 8,
							max = 24,
							step = 1,
							set = function(_, value)
								profile.fontSize = value
								KT:SetText(true)
								KT:SendSignal("OPTIONS_CHANGED")
							end,
							order = 3.2,
						},
						fontFlag = {
							name = "Font flag",
							type = "select",
							values = flags,
							get = function()
								for k, v in pairs(flags) do
									if profile.fontFlag == k then
										return k
									end
								end
							end,
							set = function(_, value)
								profile.fontFlag = value
								KT:SetText(true)
								KT:SendSignal("OPTIONS_CHANGED")
							end,
							order = 3.3,
						},
						fontShadow = {
							name = "Font shadow",
							desc = warning,
							type = "toggle",
							confirm = true,
							confirmText = warning,
							get = function()
								return (profile.fontShadow == 1)
							end,
							set = function(_, value)
								profile.fontShadow = value and 1 or 0
								ReloadUI()	-- WTF
							end,
							order = 3.4,
						},
						colorDifficulty = {
							name = "Color by difficulty",
							desc = "Quest titles color by difficulty.",
							type = "toggle",
							set = function()
								profile.colorDifficulty = not profile.colorDifficulty
								ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.SETTINGS_CHANGED)
							end,
							order = 3.5,
						},
						textWordWrap = {
							name = "Wrap long texts",
							desc = "Long texts shows on two lines or on one line with ellipsis (...).",
							type = "toggle",
							set = function()
								profile.textWordWrap = not profile.textWordWrap
								KT:SendSignal("OPTIONS_CHANGED", true)
								KT:SendSignal("OPTIONS_CHANGED")
							end,
							order = 3.6,
						},
					},
				},
				headerSection = {
					name = "Headers",
					type = "group",
					inline = true,
					order = 4,
					args = {
						headerBgrLabel = {
							name = " Texture",
							type = "description",
							width = "half",
							fontSize = "medium",
							order = 4.1,
						},
						headerBgr = {
							name = "",
							type = "select",
							values = textures,
							get = function()
								for k, v in ipairs(textures) do
									if profile.headerBgr == k then
										return k
									end
								end
							end,
							set = function(_, value)
								profile.headerBgr = value
								KT:SetBackground()
							end,
							order = 4.11,
						},
						headerBgrColor = {
							name = "Color",
							desc = "Sets the color to texture of the header.",
							type = "color",
							width = "half",
							disabled = function()
								return (profile.headerBgr < 3 or profile.headerBgrColorShare)
							end,
							get = function()
								return profile.headerBgrColor.r, profile.headerBgrColor.g, profile.headerBgrColor.b
							end,
							set = function(_, r, g, b)
								profile.headerBgrColor.r = r
								profile.headerBgrColor.g = g
								profile.headerBgrColor.b = b
								KT:SetBackground()
							end,
							order = 4.12,
						},
						headerBgrColorShare = {
							name = "Use border color",
							desc = "The color of texture is shared with the border color.",
							type = "toggle",
							disabled = function()
								return (profile.headerBgr < 3)
							end,
							set = function()
								profile.headerBgrColorShare = not profile.headerBgrColorShare
								KT:SetBackground()
							end,
							order = 4.13,
						},
						headerTxtLabel = {
							name = "Text",
							type = "description",
							width = "half",
							fontSize = "medium",
							order = 4.2,
						},
						headerTxtColor = {
							name = "Color",
							desc = "Sets the color to header texts.",
							type = "color",
							width = "half",
							disabled = function()
								KT:SetText()
								return (profile.headerBgr == 2 or profile.headerTxtColorShare)
							end,
							get = function()
								return profile.headerTxtColor.r, profile.headerTxtColor.g, profile.headerTxtColor.b
							end,
							set = function(_, r, g, b)
								profile.headerTxtColor.r = r
								profile.headerTxtColor.g = g
								profile.headerTxtColor.b = b
								KT:SetText()
							end,
							order = 4.21,
						},
						headerTxtColorShare = {
							name = "Use border color",
							desc = "The color of header texts is shared with the border color.",
							type = "toggle",
							disabled = function()
								return (profile.headerBgr == 2)
							end,
							set = function()
								profile.headerTxtColorShare = not profile.headerTxtColorShare
								KT:SetText()
							end,
							order = 4.22,
						},
						headerTxtSpacer = {
							name = " ",
							type = "description",
							width = "normal",
							order = 4.23,
						},
						headerBtnLabel = {
							name = " Buttons",
							type = "description",
							width = "half",
							fontSize = "medium",
							order = 4.3,
						},
						headerBtnColor = {
							name = "Color",
							desc = "Sets the color to all header buttons.",
							type = "color",
							width = "half",
							disabled = function()
								return profile.headerBtnColorShare
							end,
							get = function()
								return profile.headerBtnColor.r, profile.headerBtnColor.g, profile.headerBtnColor.b
							end,
							set = function(_, r, g, b)
								profile.headerBtnColor.r = r
								profile.headerBtnColor.g = g
								profile.headerBtnColor.b = b
								KT:SetBackground()
							end,
							order = 4.31,
						},
						headerBtnColorShare = {
							name = "Use border color",
							desc = "The color of all header buttons is shared with the border color.",
							type = "toggle",
							set = function()
								profile.headerBtnColorShare = not profile.headerBtnColorShare
								KT:SetBackground()
							end,
							order = 4.32,
						},
						headerBtnSpacer = {
							name = " ",
							type = "description",
							width = "normal",
							order = 4.33,
						},
						sec4SpacerMid1 = {
							name = " ",
							type = "description",
							order = 4.34,
						},
						headerCollapsedTxtLabel = {
							name = " Collapsed tracker text",
							type = "description",
							width = "normal",
							fontSize = "medium",
							order = 4.4,
						},
						headerCollapsedTxt1 = {
							name = "None",
							desc = "Reduces the tracker width when minimized.",
							type = "toggle",
							width = "half",
							get = function()
								return (profile.headerCollapsedTxt == 1)
							end,
							set = function()
								profile.headerCollapsedTxt = 1
								ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.SETTINGS_CHANGED)
							end,
							order = 4.41,
						},
						headerCollapsedTxt2 = {
							name = ("%d/%d"):format(numQuests, MAX_QUESTLOG_QUESTS),
							type = "toggle",
							width = "half",
							get = function()
								return (profile.headerCollapsedTxt == 2)
							end,
							set = function()
								profile.headerCollapsedTxt = 2
								ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.SETTINGS_CHANGED)
							end,
							order = 4.42,
						},
						headerCollapsedTxt3 = {
							name = ("%d/%d Quests"):format(numQuests, MAX_QUESTLOG_QUESTS),
							type = "toggle",
							get = function()
								return (profile.headerCollapsedTxt == 3)
							end,
							set = function()
								profile.headerCollapsedTxt = 3
								ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.SETTINGS_CHANGED)
							end,
							order = 4.43,
						},
						headerOtherButtons = {
							name = "Show "..(WOW_PROJECT_ID >= WOW_PROJECT_WRATH_CLASSIC and "Quest Log and Achievements buttons" or "Quest Log button"),
							type = "toggle",
							width = "double",
							set = function()
								profile.headerOtherButtons = not profile.headerOtherButtons
								KT:ToggleOtherButtons()
								KT:SetBackground()
								ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.SETTINGS_CHANGED)
							end,
							order = 4.5,
						},
						keyBindMinimize = {
							name = "Key - Minimize button",
							type = "keybinding",
							set = function(_, value)
								SetOverrideBinding(KTF, false, profile.keyBindMinimize, nil)
								if value ~= "" then
									local key = GetBindingKey("EXTRAACTIONBUTTON1")
									if key == value then
										SetBinding(key)
										SaveBindings(GetCurrentBindingSet())
									end
									SetOverrideBindingClick(KTF, false, value, KTF.MinimizeButton:GetName())
								end
								profile.keyBindMinimize = value
							end,
							order = 4.6,
						},
					},
				},
				questItemSection = {
					name = "Quest item buttons",
					type = "group",
					inline = true,
					order = 5,
					args = {
						anchorToggle = {
							name = "Anchor to tracker",
							desc = "Anchor the quest button bar to the quest tracker",
							type = "toggle",
							get = function () return profile.anchorQuestBar end,
							set = function()
								profile.anchorQuestBar = not profile.anchorQuestBar
								profile.questBarXOffset = 0
								profile.questBarYOffset = 0
								KT:AnchorQuestButtonBar()
								OverlayFrameUpdate()
								end,
							order = 1.2,
						},
						buttonBarDirectionSelect = {
							name = "Button bar direction",
							desc = "Define toward which direction the button bar will expand.",
							type = "select",
							values = DIR_OPTIONS,
							get = function()
								for key, dir in pairs(DIR_OPTIONS) do
									if profile.buttonBarDirection == dir then
										return key
									end
								end
							end,
							set = function(_, key)
								profile.buttonBarDirection = DIR_OPTIONS[key]
								KT:AnchorQuestButtonBar()
								KTF.QuestButtonBar.shouldRefresh = true
								RefreshQuestBar()
								OverlayFrameUpdate()
							end,
							order = 1.1,
						},

						space_1 = {
							name = " ",
							type = "description",
							width = "full",
							order = 2,
						},

						xOffsetRange = {
							name = "X offset",
							type = "range",
							min = -SCREEN_WIDTH,
							max = SCREEN_WIDTH,
							step = 1,
							get = function()
								return profile.questBarXOffset
							end,
							set = function(_, value)
								profile.questBarXOffset = value
								KT:AnchorQuestButtonBar()
							end,
							order = 2.1,
						},
						yOffsetRange = {
							name = "Y offset",
							type = "range",
							min = -SCREEN_HEIGHT,
							max = SCREEN_HEIGHT,
							step = 1,
							get = function()
								return profile.questBarYOffset
							end,
							set = function(_, value)
								profile.questBarYOffset = value
								KT:AnchorQuestButtonBar()
							end,
							order = 2.2,
						},

						space_2 = {
							name = " ",
							type = "description",
							width = "full",
							order = 3,
						},

						borderBackgroundBarToggle = {
							name = "Show buttons bar border and background",
							type = "toggle",
							width = "full",
							get = function() return profile.enableQuestBarBackground end,
							set = function()
								profile.enableQuestBarBackground = not profile.enableQuestBarBackground
								KT:SetBackground()
								KT:AnchorQuestButtonBar()
							end,
							order = 3,
						},
					},
				},
				otherSection = {
					name = "Other options",
					type = "group",
					inline = true,
					order = 6,
					args = {
						trackerTitle = {
							name = cTitle.."Tracker",
							type = "description",
							fontSize = "medium",
							order = 6.1,
						},
						hideEmptyTracker = {
							name = "Hide empty tracker",
							type = "toggle",
							set = function()
								profile.hideEmptyTracker = not profile.hideEmptyTracker
								KT:ToggleEmptyTracker()
							end,
							order = 6.11,
						},
						collapseInInstance = {
							name = "Collapse in instance",
							desc = "Collapses the tracker when entering an instance. Note: Enabled Auto filtering can expand the tracker.",
							type = "toggle",
							set = function()
								profile.collapseInInstance = not profile.collapseInInstance
							end,
							order = 6.12,
						},
						expandTrackerAfterTrack = {
							name = "Expand after track",
							desc = "The tracker will expand when it starts watching something new (Quest, Achievement, etc.).",
							type = "toggle",
							set = function()
								profile.expandTrackerAfterTrack = not profile.expandTrackerAfterTrack
							end,
							order = 6.13,
						},
						menuTitle = {
							name = "\n"..cTitle.."Menu items",
							type = "description",
							fontSize = "medium",
							order = 6.3,
						},
                        menuWowheadURL = {
							name = "Wowhead URL",
							desc = "Show Wowhead URL menu item inside the tracker.",
							type = "toggle",
							set = function()
								profile.menuWowheadURL = not profile.menuWowheadURL
							end,
							order = 6.31,
						},
                        menuWowheadURLModifier = {
							name = "Wowhead URL click modifier",
							type = "select",
							values = modifiers,
							get = function()
								for k, v in pairs(modifiers) do
									if profile.menuWowheadURLModifier == k then
										return k
									end
								end
							end,
							set = function(_, value)
								profile.menuWowheadURLModifier = value
							end,
							order = 6.32,
						},
					},
				},
				notificationMessageSection = {
					name = "Notification messages",
					type = "group",
					inline = true,
					order = 7,
					args = {
						messageQuest = {
							name = "Quest messages",
							type = "toggle",
							set = function()
								profile.messageQuest = not profile.messageQuest
							end,
							order = 7.1,
						},
						messageAchievement = {
							name = "Achievement messages",
							width = 1.1,
							type = "toggle",
							set = function()
								profile.messageAchievement = not profile.messageAchievement
							end,
							order = 7.2,
						},
					},
				},
				notificationSoundSection = {
					name = "Notification sounds",
					type = "group",
					inline = true,
					order = 8,
					args = {
						soundQuest = {
							name = "Quest sound",
							desc = "Play a sound on quest completion",
							type = "toggle",
							set = function()
								profile.soundQuest = not profile.soundQuest
							end,
							order = 8.1,
						},
						soundQuestComplete = {
							name = "Complete Sound",
							desc = "Addon sounds are prefixed \"KT - \".",
							type = "select",
							disabled = function()
								return not profile.soundQuest or profile.useSoundKit
							end,
							dialogControl = "LSM30_Sound",
							values = WidgetLists.sound,
							set = function(_, value)
								profile.soundQuestComplete = value
							end,
							order = 8.11,
						}
					},
				},
			},
		},
		content = {
			name = "Content",
			type = "group",
			args = {
				sec1 = {
					name = "Quests",
					type = "group",
					inline = true,
					order = 1,
					args = {
						questsHeaderTitleAppend = {
							name = "Show number of Quests",
							desc = "Show number of Quests inside the Quests module header.",
							type = "toggle",
							set = function()
								profile.questsHeaderTitleAppend = not profile.questsHeaderTitleAppend
								KT:SetQuestsHeaderText(true)
							end,
							order = 1.1,
						},
						questsAutoTrack = {
							name = "Auto Quest tracking",
							desc = "Quests are automatically watched when accepted. Uses Blizzard's value \"autoQuestWatch\".",
							type = "toggle",
							get = function()
								return (GetCVar("autoQuestWatch") == "1")
							end,
							set = function(_, value)
								SetCVar("autoQuestWatch", value)
							end,
							order = 1.2,
						},
						questsShowLevels = {
							name = "Show Quest Levels",
							desc = "Show / Hide Quest levels inside the tracker.",
							type = "toggle",
							set = function()
								profile.questsShowLevels = not profile.questsShowLevels
								ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.SETTINGS_CHANGED)
							end,
							order = 1.3,
						},
						questsShowTags = {
							name = "Show Quest Tags",
							desc = "Show / Hide Quest tags (type, frequency) inside the tracker.",
							type = "toggle",
							set = function()
								profile.questsShowTags = not profile.questsShowTags
								ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.SETTINGS_CHANGED)
							end,
							order = 1.4,
						},
						questsShowZones = {
							name = "Show Quest Zones",
							desc = "Show / Hide Quest Zones inside the tracker.",
							type = "toggle",
							set = function()
								profile.questsShowZones = not profile.questsShowZones
								ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.SETTINGS_CHANGED)
							end,
							order = 1.5,
						},
						questsObjectiveNumSwitch = {
							name = "Objective numbers at the beginning of a line",
							desc = "Toggling position of objective numbers, between begin / end of objective line.\n\n"..
									cBold.."- 0/10 Scarlet Zealot slain\n"..
									"- Scarlet Zealot slain: 0/10|r ... Blizzard default",
							descStyle = "inline",
							type = "toggle",
							width = "full",
							set = function()
								profile.questsObjectiveNumSwitch = not profile.questsObjectiveNumSwitch
								ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.SETTINGS_CHANGED)
							end,
							order = 1.6,
						},
					},
				},
				sec2 = {
					name = "Achievements",
					type = "group",
					inline = true,
					order = 2,
					args = {
						achievementsHeaderTitleAppend = {
							name = "Show Achievement points",
							desc = "Show Achievement points inside the Achievements module header.",
							type = "toggle",
							width = "normal+half",
							set = function()
								profile.achievementsHeaderTitleAppend = not profile.achievementsHeaderTitleAppend
								KT:SetAchievementsHeaderText(true)
							end,
							order = 2.1,
						},
					},
				},
				sec3 = {
					name = "Tooltips",
					type = "group",
					inline = true,
					order = 3,
					args = {
						tooltipShow = {
							name = "Show tooltips",
							desc = "Show Quest / Achievement tooltips.",
							type = "toggle",
							set = function()
								profile.tooltipShow = not profile.tooltipShow
							end,
							order = 3.1,
						},
						tooltipShowRewards = {
							name = "Show Rewards",
							desc = "Show Quest Rewards inside tooltips - Artifact Power, Order Resources, Money, Equipment etc.",
							type = "toggle",
							disabled = function()
								return not profile.tooltipShow
							end,
							set = function()
								profile.tooltipShowRewards = not profile.tooltipShowRewards
							end,
							order = 3.2,
						},
						tooltipShowID = {
							name = "Show ID",
							desc = "Show Quest / Achievement ID inside tooltips.",
							type = "toggle",
							disabled = function()
								return not profile.tooltipShow
							end,
							set = function()
								profile.tooltipShowID = not profile.tooltipShowID
							end,
							order = 3.3,
						},
					},
				},
				sec4 = {
					name = "Addon - PetTracker",
					type = "group",
					inline = true,
					order = 4,
					args = {
						pettrackerHeaderTitleAppend = {
							name = "Show number of owned Pets",
							desc = "Show number of owned Pets inside the PetTracker header.",
							type = "toggle",
							width = "normal+half",
							disabled = function()
								return not KT.AddonPetTracker.isAvailable
							end,
							set = function()
								profile.pettrackerHeaderTitleAppend = not profile.pettrackerHeaderTitleAppend
								KT.AddonPetTracker:SetPetsHeaderText(true)
							end,
							order = 4.1,
						},
					},
				},
			},
		},
		modules = {
			name = "Modules",
			type = "group",
			args = {
				sec1 = {
					name = "Order of Modules",
					type = "group",
					inline = true,
					order = 1,
				},
			},
		},
		addons = {
			name = "Supported addons",
			type = "group",
			args = {
				desc = {
					name = "|cff00d200Green|r - compatible version - this version was tested and support is inserted.\n"..
							"|cffff0000Red|r - incompatible version - this version wasn't tested, maybe will need some code changes.\n"..
							"Please report all problems.",
					type = "description",
					order = 0,
				},
				sec1 = {
					name = "Addons",
					type = "group",
					inline = true,
					order = 1,
					args = {
						addonQuestie = {
							name = "Questie",
							desc = "Version: %s",
							descStyle = "inline",
							type = "toggle",
							width = 1.05,
							confirm = true,
							confirmText = warning,
							disabled = function()
								return not C_AddOns.IsAddOnLoaded("Questie")
							end,
							set = function()
								profile.addonQuestie = not profile.addonQuestie
								ReloadUI()
							end,
							order = 1.11,
						},
						addonQuestieDesc = {
							name = "Enables "..cBold.."Show on Map|r and "..cBold.."Set TomTom Waypoint|r options in the "..
									"Quest context menu, and adds Quest Item buttons for quests with usable items.",
							type = "description",
							width = "double",
							order = 1.12,
						},
						addonPetTracker = {
							name = "PetTracker",
							desc = "Version: %s",
							descStyle = "inline",
							type = "toggle",
							width = 1.05,
							confirm = true,
							confirmText = warning,
							disabled = function()
								return not C_AddOns.IsAddOnLoaded("PetTracker")
							end,
							set = function()
								profile.addonPetTracker = not profile.addonPetTracker
								if PetTracker.sets then
									PetTracker.sets.zoneTracker = profile.addonPetTracker
								end
								ReloadUI()
							end,
							order = 1.21,
						},
						addonPetTrackerDesc = {
							name = "Enables display of zone pet tracking inside the tracker and fixes some visual issues.",
							type = "description",
							width = "double",
							order = 1.22,
						},
					},
				},
				sec2 = {
					name = "User Interfaces",
					type = "group",
					inline = true,
					order = 2,
					args = {
						elvui = {
							name = "ElvUI",
							type = "toggle",
							disabled = true,
							order = 2.1,
						},
						tukui = {
							name = "Tukui",
							type = "toggle",
							disabled = true,
							order = 2.2,
						},
					},
				},
			},
		},
	},
}

local general = options.args.general.args
local content = options.args.content.args
local modules = options.args.modules.args
local addons = options.args.addons.args

function KT:CheckAddOn(addon, version, isUI)
	local name = strsplit("_", addon)
	local ver = isUI and "" or "---"
	local result = false
	local path
	if C_AddOns.IsAddOnLoaded(addon) then
		local actualVersion = C_AddOns.GetAddOnMetadata(addon, "Version") or "unknown"
		actualVersion = gsub(actualVersion, "(.*%S)%s+", "%1")
		ver = isUI and "  -  " or ""
		ver = (ver.."|cff%s"..actualVersion.."|r"):format(actualVersion == version and "00d200" or "ff0000")
		result = true
	end
	if not isUI then
		path =  addons.sec1.args["addon"..name]
		path.desc = path.desc:format(ver)
	else
		local path =  addons.sec2.args[strlower(name)]
		path.name = path.name..ver
		path.disabled = not result
		path.get = function() return result end
	end
	return result
end

function KT:OpenOptions()
	if self.optionsFrame then
		Settings.OpenToCategory(self.optionsFrame.general.name, true)
	end
end

function KT:InitProfile(event, database, profile)
	ReloadUI()
end

SettingsPanel:HookScript("OnHide", function(self)
	OverlayFrameHide()
end)

function OverlayFrameUpdate()
	if trackerMaxHeightGizmo then
		trackerMaxHeightGizmo:SetSize(280, profile.maxHeight)
		trackerMaxHeightGizmo:ClearAllPoints()
		trackerMaxHeightGizmo:SetPoint(profile.anchorPoint, 0, 0)
	end
end

function OverlayFrameHide()
	if overlayShown then
		trackerMaxHeightGizmo:Hide()
		overlayShown = false
	end
end

function GetModulesOptionsTable()
	local numModules = #profile.modulesOrder
	local text
	local defaultModule, defaultText
	local args = {
		descCurOrder = {
			name = cTitle.."Current Order",
			type = "description",
			width = "double",
			fontSize = "medium",
			order = 0.1,
		},
		descDefOrder = {
			name = "|T:1:20|t"..cTitle.."Default Order",
			type = "description",
			width = "normal",
			fontSize = "medium",
			order = 0.2,
		},
	}
	if WOW_PROJECT_ID >= WOW_PROJECT_MISTS_CLASSIC then
		args.descModules = {
			name = "\n * "..TRACKER_HEADER_SCENARIO.." / "..CHALLENGE_MODE.." / |cffff0000"..TRACKER_HEADER_PROVINGGROUNDS.." (not supported)\n",
			type = "description",
			order = 20,
		}
	end

	for i, module in ipairs(profile.modulesOrder) do
		text = _G[module].Header.Text:GetText()
		if module == "SCENARIO_CONTENT_TRACKER_MODULE" then
			text = text.." *"
		end

		defaultModule = OTF.MODULES[i]
		defaultText = defaultModule.Header.Text:GetText()
		if defaultModule == SCENARIO_CONTENT_TRACKER_MODULE then
			defaultText = defaultText.." *"
		end

		args["pos"..i] = {
			name = " "..text,
			type = "description",
			width = "normal",
			fontSize = "medium",
			order = i,
		}
		args["pos"..i.."up"] = {
			name = (i > 1) and "Up" or " ",
			desc = text,
			type = (i > 1) and "execute" or "description",
			width = "half",
			func = function()
				MoveModule(i, "up")
			end,
			order = i + 0.1,
		}
		args["pos"..i.."down"] = {
			name = (i < numModules) and "Down" or " ",
			desc = text,
			type = (i < numModules) and "execute" or "description",
			width = "half",
			func = function()
				MoveModule(i)
			end,
			order = i + 0.2,
		}
		args["pos"..i.."default"] = {
			name = "|T:1:24|t|cff808080"..defaultText,
			type = "description",
			width = "normal",
			fontSize = "medium",
			order = i + 0.3,
		}
	end
	return args
end

function MoveModule(idx, direction)
	local text = strsub(modules.sec1.args["pos"..idx].name, 2)
	local tmpIdx = (direction == "up") and idx-1 or idx+1
	local tmpText = strsub(modules.sec1.args["pos"..tmpIdx].name, 2)
	modules.sec1.args["pos"..tmpIdx].name = " "..text
	modules.sec1.args["pos"..tmpIdx.."up"].desc = text
	modules.sec1.args["pos"..tmpIdx.."down"].desc = text
	modules.sec1.args["pos"..idx].name = " "..tmpText
	modules.sec1.args["pos"..idx.."up"].desc = tmpText
	modules.sec1.args["pos"..idx.."down"].desc = tmpText

	local module = tremove(profile.modulesOrder, idx)
	tinsert(profile.modulesOrder, tmpIdx, module)

	module = tremove(OTF.MODULES_UI_ORDER, idx)
	tinsert(OTF.MODULES_UI_ORDER, tmpIdx, module)
	ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.SETTINGS_CHANGED)
end

function SetSharedColor(color)
	local name = "Use border |cff"..KT.RgbToHex(color).."color|r"
	local sec4 = general.headerSection.args
	sec4.headerBgrColorShare.name = name
	sec4.headerTxtColorShare.name = name
	sec4.headerBtnColorShare.name = name
end

function IsSpecialLocale()
	return (KT.LOCALE == "deDE" or
			KT.LOCALE == "esES" or
			KT.LOCALE == "frFR" or
			KT.LOCALE == "ruRU")
end

local function Init()
	KT.db = LibStub("AceDB-3.0"):New(strsub(addonName, 2).."DB", defaults, true)
	KT.options = options
	profile = KT.db.profile
	dbChar = KT.db.char
end

local function SetupOptionsMenu()
	KT.Utils.Log("Setup options menu")

	KT.SoundKits.AppendOptions(general.notificationSoundSection, profile)

	general.backgroundSection.args.classBorder.name = general.backgroundSection.args.classBorder.name:format(KT.RgbToHex(KT.classColor))

	general.notificationMessageSection.args.messageOutput = KT:GetSinkAce3OptionsDataTable()
	general.notificationMessageSection.args.messageOutput.inline = true
	general.notificationMessageSection.args.messageOutput.disabled = function() return not (profile.messageQuest or profile.messageAchievement) end
	KT:SetSinkStorage(profile)

	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(KT.db)
	options.args.profiles.confirm = true
	options.args.profiles.args.reset.confirmText = warning
	options.args.profiles.args.new.confirmText = warning
	options.args.profiles.args.choose.confirmText = warning
	options.args.profiles.args.copyfrom.confirmText = warning
	if not options.args.profiles.plugins then
		options.args.profiles.plugins = {}
	end
	options.args.profiles.plugins[addonName] = {
		clearTrackerDataDesc1 = {
			name = "Clear the data (no settings) of the tracked content (Quests, Achievements etc.) for current character.",
			type = "description",
			order = 0.1,
		},
		clearTrackerData = {
			name = "Clear Tracker Data",
			desc = "Clear the data of the tracked content.",
			type = "execute",
			confirm = true,
			confirmText = "Clear Tracker Data - "..cBold..KT.playerName,
			func = function()
				KT.stopUpdate = true
				local numEntries = GetNumQuestLogEntries()
				for i = 1, numEntries do
					local _, _, _, isHeader = GetQuestLogTitle(i)
					if not isHeader then
						RemoveQuestWatch(i)
					end
				end
				local trackedAchievements = { GetTrackedAchievements() }
				for i = 1, #trackedAchievements do
					RemoveTrackedAchievement(trackedAchievements[i])
				end
				for i = 1, #profile.filterAuto do
					profile.filterAuto[i] = nil
				end
				if WOW_PROJECT_ID >= WOW_PROJECT_MISTS_CLASSIC then
					if KT.AddonPetTracker.isAvailable then
						if PetTracker.sets.zoneTracker then
							PetTracker.ToggleOption("zoneTracker")
						end
					end
				end
				KT:SetBackground()
				KT.QuestsCache_Rebuild(true, true)
				KT.stopUpdate = false
				ObjectiveTracker_Update(DEBUG_UPDATE_REASONS.SETTINGS_CHANGED)
			end,
			order = 0.2,
		},
		clearTrackerDataDesc2 = {
			name = "Current character: "..cBold..KT.playerName,
			type = "description",
			width = "double",
			order = 0.3,
		},
		clearTrackerDataDesc4 = {
			name = " ",
			type = "description",
			order = 0.4,
		}
	}

	ACR:RegisterOptionsTable(addonName, options, nil)

	KT.optionsFrame = {}
	KT.optionsFrame.general = ACD:AddToBlizOptions(addonName, KT.TITLE, nil, "general")
	KT.optionsFrame.content = ACD:AddToBlizOptions(addonName, options.args.content.name, KT.TITLE, "content")
	KT.optionsFrame.modules = ACD:AddToBlizOptions(addonName, options.args.modules.name, KT.TITLE, "modules")
	KT.optionsFrame.addons = ACD:AddToBlizOptions(addonName, options.args.addons.name, KT.TITLE, "addons")
	KT.optionsFrame.profiles = ACD:AddToBlizOptions(addonName, options.args.profiles.name, KT.TITLE, "profiles")

	KT.db.RegisterCallback(KT, "OnProfileChanged", "InitProfile")
	KT.db.RegisterCallback(KT, "OnProfileCopied", "InitProfile")
	KT.db.RegisterCallback(KT, "OnProfileReset", "InitProfile")

	-- Resets and hides some options
	if WOW_PROJECT_ID < WOW_PROJECT_MISTS_CLASSIC then
		content.sec4 = nil
		profile.pettrackerHeaderTitleAppend = false
		addons.sec1.args.addonPetTracker = nil
		addons.sec1.args.addonPetTrackerDesc = nil
	end
	if WOW_PROJECT_ID < WOW_PROJECT_WRATH_CLASSIC then
		general.notificationMessageSection.args.messageAchievement = nil
		profile.messageAchievement = false
		content.sec2 = nil
		profile.achievementsHeaderTitleAppend = false
	end
end

local function SetupModules()
	modules.sec1.args = GetModulesOptionsTable()
end

function OptionModule:OnInitialize()
	KT.Utils.Log("|cffffff00Init|r - "..self:GetName())
	Init()
    self.isAvailable = true
end

function OptionModule:OnEnable()
	KT.Utils.Log("|cff00ff00Enable|r - "..self:GetName())
	SetupOptionsMenu()

	KT:RegEvent("PLAYER_ENTERING_WORLD", function(eventID)
		SetupModules()
		KT:UnregEvent(eventID)
	end, self)
end