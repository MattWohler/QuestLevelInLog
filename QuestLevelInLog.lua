-- QuestLevelInLog
-- Version 1.1.0
-- Target: World of Warcraft: Burning Crusade Classic Anniversary 2.5.6
-- TOC Interface: 20506
--
-- Purpose:
--   Change visible quest log rows from:
--       Tiger Mastery
--   to:
--       [34] Tiger Mastery
--
-- This addon does NOT replace GetQuestLogTitle() and does NOT modify
-- ElvUI or Eltruism files. It changes only the text displayed on the
-- Blizzard QuestLogTitle buttons.

local ADDON_NAME = ...

local PREFIX = "|cff35c5ffQuestLevelInLog:|r "

local state = {
    initialized = false,
    updateQueued = false,
    questLogHooked = false,
    frameHooked = false,
}

local function Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. tostring(message))
    end
end

local function InitializeDatabase()
    if type(QuestLevelInLogDB) ~= "table" then
        QuestLevelInLogDB = {}
    end

    if QuestLevelInLogDB.enabled == nil then
        QuestLevelInLogDB.enabled = true
    end

    state.initialized = true
end

local function IsEnabled()
    return QuestLevelInLogDB and QuestLevelInLogDB.enabled ~= false
end

local function GetQuestData(index)
    if not index or index < 1 or type(GetQuestLogTitle) ~= "function" then
        return nil
    end

    -- TBC Anniversary 2.5.6 exposes the legacy GetQuestLogTitle API:
    -- title, level, suggestedGroup, isHeader, isCollapsed, isComplete,
    -- frequency, questID, ...
    local title, level, suggestedGroup, isHeader, isCollapsed, isComplete,
        frequency, questID = GetQuestLogTitle(index)

    if not title then
        return nil
    end

    return {
        title = title,
        level = tonumber(level) or 0,
        isHeader = isHeader and true or false,
        questID = questID,
    }
end

local function GetScrollOffset()
    -- Eltruism 5.1.4 uses QuestLogListScrollFrame on its TBC quest-log skin.
    if QuestLogListScrollFrame and type(FauxScrollFrame_GetOffset) == "function" then
        return FauxScrollFrame_GetOffset(QuestLogListScrollFrame) or 0
    end

    -- Fallback for clients/layouts using a hybrid scroll frame.
    if QuestLogScrollFrame and type(HybridScrollFrame_GetOffset) == "function" then
        return HybridScrollFrame_GetOffset(QuestLogScrollFrame) or 0
    end

    return 0
end

local function ResolveQuestIndex(button, rowNumber)
    -- Blizzard normally sets each visible QuestLogTitle button's ID to the
    -- actual quest-log index. Prefer that because it remains correct while
    -- scrolling and with expanded/collapsed headers.
    local id = button and button.GetID and button:GetID()
    if type(id) == "number" and id > 0 then
        local data = GetQuestData(id)
        if data then
            return id, data
        end
    end

    -- Fallback for layouts that leave button IDs as row numbers.
    local index = rowNumber + GetScrollOffset()
    return index, GetQuestData(index)
end

local function FormatQuestTitle(data)
    if not data or data.isHeader then
        return nil
    end

    if data.level and data.level > 0 then
        return ("[%d] %s"):format(data.level, data.title)
    end

    return data.title
end

local function ApplyToButton(button, rowNumber)
    if not button or not button:IsShown() then
        return false
    end

    local _, data = ResolveQuestIndex(button, rowNumber)
    if not data or data.isHeader then
        return false
    end

    local wanted = FormatQuestTitle(data)
    if not wanted then
        return false
    end

    -- Do not call SetText unless the value actually changed. Apart from
    -- avoiding needless redraws, this also makes us safe if another addon
    -- hooks SetText on the same button.
    if button:GetText() ~= wanted then
        button:SetText(wanted)
    end

    return true
end

local function UpdateVisibleQuestRows()
    if not state.initialized then
        InitializeDatabase()
    end

    if not IsEnabled() then
        return
    end

    if not QuestLogFrame or not QuestLogFrame:IsShown() then
        return
    end

    local changed = 0

    -- Eltruism 5.1.4 expands the TBC quest log to 24 QuestLogTitle buttons.
    -- We scan farther so this addon does not depend on that exact row count.
    for row = 1, 40 do
        local button = _G["QuestLogTitle" .. row]
        if button then
            if ApplyToButton(button, row) then
                changed = changed + 1
            end
        elseif row > 24 then
            -- No need to keep scanning once we are beyond Eltruism's known
            -- 24-row layout and encounter the first missing button.
            break
        end
    end

    return changed
end

local function QueueUpdate()
    if state.updateQueued then
        return
    end

    state.updateQueued = true

    C_Timer.After(0, function()
        state.updateQueued = false
        UpdateVisibleQuestRows()
    end)
end

local function RefreshFromBlizzard()
    -- When disabling the addon, ask Blizzard/Eltruism to repaint the quest
    -- list using its normal unmodified titles.
    if QuestLogFrame and QuestLogFrame:IsShown() and type(QuestLog_Update) == "function" then
        QuestLog_Update()
    end
end

local function InstallHooks()
    -- QuestLog_Update is the authoritative repaint for the classic/TBC log.
    -- The post-hook means Blizzard/Eltruism writes first, then we add levels.
    if not state.questLogHooked and type(QuestLog_Update) == "function" then
        hooksecurefunc("QuestLog_Update", QueueUpdate)
        state.questLogHooked = true
    end

    if not state.frameHooked and QuestLogFrame and QuestLogFrame.HookScript then
        QuestLogFrame:HookScript("OnShow", QueueUpdate)
        state.frameHooked = true
    end

    -- Selection changes can cause a repaint without a QUEST_LOG_UPDATE event.
    if type(QuestLog_SetSelection) == "function" and not state.selectionHooked then
        hooksecurefunc("QuestLog_SetSelection", QueueUpdate)
        state.selectionHooked = true
    end
end

local function SetEnabled(enabled)
    QuestLevelInLogDB.enabled = enabled and true or false

    if QuestLevelInLogDB.enabled then
        InstallHooks()
        QueueUpdate()
        Print("enabled.")
    else
        RefreshFromBlizzard()
        Print("disabled.")
    end
end

local function PrintDebug()
    local version, build, date, toc = GetBuildInfo()
    local visible = 0
    local existing = 0

    for row = 1, 40 do
        local button = _G["QuestLogTitle" .. row]
        if button then
            existing = existing + 1
            if button:IsShown() then
                visible = visible + 1
            end
        end
    end

    Print(("addon=%s, enabled=%s"):format(ADDON_NAME or "?", tostring(IsEnabled())))
    Print(("client=%s build=%s toc=%s"):format(tostring(version), tostring(build), tostring(toc)))
    Print(("QuestLogFrame=%s, QuestLog_Update=%s"):format(
        QuestLogFrame and "yes" or "no",
        type(QuestLog_Update)
    ))
    Print(("QuestLogTitle buttons: %d existing, %d visible"):format(existing, visible))
    Print(("hooks: update=%s frame=%s selection=%s"):format(
        tostring(state.questLogHooked),
        tostring(state.frameHooked),
        tostring(state.selectionHooked)
    ))

    if QuestLogFrame and QuestLogFrame:IsShown() then
        local changed = UpdateVisibleQuestRows() or 0
        Print(("debug refresh touched %d quest row(s)."):format(changed))
    else
        Print("open the Quest Log and run /qlvl debug again for row diagnostics.")
    end
end

SLASH_QUESTLEVELINLOG1 = "/qlvl"
SLASH_QUESTLEVELINLOG2 = "/questlevelinlog"

SlashCmdList.QUESTLEVELINLOG = function(message)
    if not state.initialized then
        InitializeDatabase()
    end

    local command = (message or ""):lower():match("^%s*(.-)%s*$")

    if command == "on" then
        SetEnabled(true)
    elseif command == "off" then
        SetEnabled(false)
    elseif command == "status" then
        Print(IsEnabled() and "enabled." or "disabled.")
    elseif command == "debug" then
        PrintDebug()
    elseif command == "" then
        SetEnabled(not IsEnabled())
    else
        Print("commands: /qlvl, /qlvl on, /qlvl off, /qlvl status, /qlvl debug")
    end
end

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            InitializeDatabase()
            InstallHooks()
        elseif arg1 == "ElvUI_EltreumUI" or arg1 == "ElvUI" then
            -- Eltruism creates additional QuestLogTitle rows during its setup.
            -- Re-run hook discovery after either dependency loads.
            InstallHooks()
            QueueUpdate()
        end
    elseif event == "PLAYER_LOGIN" then
        if not state.initialized then
            InitializeDatabase()
        end

        InstallHooks()

        -- A second pass one frame later catches UI changes made by Eltruism
        -- during PLAYER_LOGIN.
        QueueUpdate()
        C_Timer.After(0.25, function()
            InstallHooks()
            QueueUpdate()
        end)
    elseif event == "QUEST_LOG_UPDATE" then
        InstallHooks()
        QueueUpdate()
    end
end)
