--- Kaliel's Tracker
--- Copyright (c) 2012-2026, Marouan Sabbagh <mar.sabbagh@gmail.com>
--- All Rights Reserved.
---
--- This file is part of addon Kaliel's Tracker.

---@type KT
local _, KT = ...

function KT.IsClassic()
    return WOW_PROJECT_ID >= WOW_PROJECT_WRATH_CLASSIC
end

function KT.IsClassicEra()
    return WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC or
            WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
end

local Noop = function() end

if KT.IsClassic() then
    -- Classic (MoP)
    if WOW_PROJECT_ID >= WOW_PROJECT_MISTS_CLASSIC then
        WorldStateChallengeMode_CheckTimers = Noop
    end

    -- Classic (Cata)
    if WOW_PROJECT_ID >= WOW_PROJECT_CATACLYSM_CLASSIC then

    end

    -- Classic (WotLK)
    if WOW_PROJECT_ID >= WOW_PROJECT_WRATH_CLASSIC then
        GetSuperTrackedQuestID = function()  -- R ... TODO: Test after every WoW update
            local questID = 0
            if WorldMapFrame and WorldMapFrame:IsShown() then
                questID = QuestMapFrame_GetFocusedQuestID()
            end
            return questID
        end

        if not OpenAchievementFrameToAchievement then
            function OpenAchievementFrameToAchievement(achievementID)
                WatchFrame_OpenAchievementFrame(_, achievementID)
            end
        end
    end
elseif KT.IsClassicEra() then
    -- Classic Era (Vanilla + TBC)
    WatchFrame = QuestWatchFrame
    WatchFrame_Update = QuestWatch_Update

    if not GetQuestLogSpecialItemInfo then
        GetQuestLogSpecialItemInfo = function()
            return nil
        end
    end

    if not IsQuestLogSpecialItemInRange then
        IsQuestLogSpecialItemInRange = function()
            return nil
        end
    end

    if not GetQuestLogSpecialItemCooldown then
        GetQuestLogSpecialItemCooldown = GetActionCooldown
    end

    if not QuestPOI_Initialize then
        QuestPOI_Initialize = Noop
    end

    if not QuestPOI_ResetUsage then
        QuestPOI_ResetUsage = Noop
    end

    if not QuestPOI_SelectButtonByQuestID then
        QuestPOI_SelectButtonByQuestID = Noop
    end

    if not QuestPOI_HideUnusedButtons then
        QuestPOI_HideUnusedButtons = Noop
    end

    if not GetNumAutoQuestPopUps then
        GetNumAutoQuestPopUps = function()
            return 0
        end
    end

    if not GetQuestLogIsAutoComplete then
        GetQuestLogIsAutoComplete = function()
            return false
        end
    end

    -- existing function does not return a number
    GetNumTrackedAchievements = function()
        return 0
    end
end

-- Classic + Classic Era
if not C_QuestLog.GetNumQuestLogEntries then
    C_QuestLog.GetNumQuestLogEntries = GetNumQuestLogEntries
end

if not C_QuestLog.GetInfo then
    C_QuestLog.GetInfo = function(questLogIndex)
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(questLogIndex)
        return {
            title = title,
            questLogIndex = questLogIndex,
            questID = questID,
            campaignID = nil,
            level = level,
            difficultyLevel = 0,
            suggestedGroup = suggestedGroup,
            frequency = frequency,
            isHeader = isHeader,
            useMinimalHeader = false,
            sortAsNormalQuest = true,
            isCollapsed = isCollapsed,
            startEvent = startEvent,
            isTask = isTask,
            isBounty = isBounty,
            isStory = isStory,
            isScaling = isScaling,
            isOnMap = isOnMap,
            hasLocalPOI = hasLocalPOI,
            isHidden = isHidden,
            isAutoComplete = GetQuestLogIsAutoComplete(questLogIndex)
        }
    end
end

if not C_QuestLog.IsComplete then
    C_QuestLog.IsComplete = IsQuestComplete
end

if not QuestMapQuestOptions_AbandonQuest then
    QuestMapQuestOptions_AbandonQuest = function(questID)
        local bckQuestLogSelection = GetQuestLogSelection()  -- backup Quest Log selection
        local questLogIndex = GetQuestLogIndexByID(questID)
        SelectQuestLogEntry(questLogIndex)
        SetAbandonQuest()

        local items = GetAbandonQuestItems()
        local title = GetAbandonQuestName()
        if items then
            StaticPopup_Hide("ABANDON_QUEST")
            StaticPopup_Show("ABANDON_QUEST_WITH_ITEMS", title, items)
        else
            StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS")
            StaticPopup_Show("ABANDON_QUEST", title)
        end

        SelectQuestLogEntry(bckQuestLogSelection)  -- restore Quest Log selection
    end
end

if not IsQuestBounty then
    IsQuestBounty = function()
        return false
    end
end

if not IsQuestTask then
    IsQuestTask = function()
        return false
    end
end