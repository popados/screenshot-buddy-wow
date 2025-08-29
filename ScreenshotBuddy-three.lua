-- ScreenshotBuddy.lua
-- World of Warcraft Classic AddOn

local ADDON = ...
local f = CreateFrame("Frame")
local optionsPanel
local timers = {}

--------------------------------------------------
-- Defaults
--------------------------------------------------
local defaults = {
    enabled = {
        levelup = true,
        skillup = true,
        death   = true,
        login   = true,
        logout  = true,
        timed   = false,
    },
    interval = 600,   -- seconds for timed screenshots
    delay    = 2,     -- delay before screenshot
    prefix   = nil,   -- will be set to character name if unset
}

--------------------------------------------------
-- Utils
--------------------------------------------------
local function Print(msg, ...)
    DEFAULT_CHAT_FRAME:AddMessage("|cff4bf5ff[SB]|r " .. string.format(msg, ...))
end

local function TakeShot(reason)
    C_Timer.After(ScreenshotBuddyDB.delay or defaults.delay, function()
        local prefix = ScreenshotBuddyDB.prefix
        if not prefix or prefix == "" then
            prefix = UnitName("player") or "Screenshot"
        end
        Screenshot(prefix .. "_")
        Print("Screenshot taken (%s)", reason)
    end)
end

--------------------------------------------------
-- Timed Screenshots
--------------------------------------------------
local function StartTimer()
    if ScreenshotBuddyDB.enabled.timed then
        local interval = ScreenshotBuddyDB.interval or defaults.interval
        if timers.screenshot then timers.screenshot:Cancel() end
        timers.screenshot = C_Timer.NewTicker(interval, function()
            TakeShot("Timed")
        end)
        Print("Timed screenshots every %d seconds", interval)
    else
        if timers.screenshot then timers.screenshot:Cancel() end
        timers.screenshot = nil
    end
end

--------------------------------------------------
-- Events
--------------------------------------------------
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("CHAT_MSG_SKILL")
f:RegisterEvent("PLAYER_DEAD")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == ADDON then
            if not ScreenshotBuddyDB then ScreenshotBuddyDB = {} end

            -- copy defaults
            for k,v in pairs(defaults) do
                if ScreenshotBuddyDB[k] == nil then
                    ScreenshotBuddyDB[k] = v
                end
            end
            for k,v in pairs(defaults.enabled) do
                if ScreenshotBuddyDB.enabled[k] == nil then
                    ScreenshotBuddyDB.enabled[k] = v
                end
            end

            -- set default prefix to character name if not set
            if not ScreenshotBuddyDB.prefix or ScreenshotBuddyDB.prefix == "" then
                ScreenshotBuddyDB.prefix = UnitName("player") or "Screenshot"
            end

            StartTimer()
        end
    elseif event == "PLAYER_LOGIN" then
        if ScreenshotBuddyDB.enabled.login then
            TakeShot("Login")
        end
    elseif event == "PLAYER_LOGOUT" then
        if ScreenshotBuddyDB.enabled.logout then
            TakeShot("Logout")
        end
    elseif event == "PLAYER_LEVEL_UP" then
        if ScreenshotBuddyDB.enabled.levelup then
            TakeShot("Level Up")
        end
    elseif event == "CHAT_MSG_SKILL" then
        if ScreenshotBuddyDB.enabled.skillup then
            TakeShot("Skill Up")
        end
    elseif event == "PLAYER_DEAD" then
        if ScreenshotBuddyDB.enabled.death then
            TakeShot("Death")
        end
    end
end)

--------------------------------------------------
-- Interface Options Panel
--------------------------------------------------
optionsPanel = CreateFrame("Frame", "ScreenshotBuddyOptionsPanel", InterfaceOptionsFramePanelContainer)
optionsPanel.name = "Screenshot Buddy"

optionsPanel:Hide()
optionsPanel:SetScript("OnShow", function(panel)
    if panel.initialized then return end
    panel.initialized = true

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Screenshot Buddy")

    -- checkboxes
    local function CreateCheckbox(name, label, tooltip, key)
        local cb = CreateFrame("CheckButton", name, panel, "InterfaceOptionsCheckButtonTemplate")
        cb.Text:SetText(label)
        cb.tooltipText = tooltip
        cb:SetChecked(ScreenshotBuddyDB.enabled[key])
        cb:SetScript("OnClick", function(self)
            ScreenshotBuddyDB.enabled[key] = self:GetChecked()
            if key == "timed" then
                StartTimer()
            end
        end)
        return cb
    end

    local cb1 = CreateCheckbox("SB_Levelup", "Level Up", "Take screenshot on level up", "levelup")
    cb1:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)

    local cb2 = CreateCheckbox("SB_Skillup", "Skill Up", "Take screenshot on skill up", "skillup")
    cb2:SetPoint("TOPLEFT", cb1, "BOTTOMLEFT", 0, -4)

    local cb3 = CreateCheckbox("SB_Death", "Death", "Take screenshot on death", "death")
    cb3:SetPoint("TOPLEFT", cb2, "BOTTOMLEFT", 0, -4)

    local cb4 = CreateCheckbox("SB_Login", "Login", "Take screenshot on login", "login")
    cb4:SetPoint("TOPLEFT", cb3, "BOTTOMLEFT", 0, -4)

    local cb5 = CreateCheckbox("SB_Logout", "Logout", "Take screenshot on logout", "logout")
    cb5:SetPoint("TOPLEFT", cb4, "BOTTOMLEFT", 0, -4)

    local cb6 = CreateCheckbox("SB_Timed", "Timed", "Take screenshots every interval", "timed")
    cb6:SetPoint("TOPLEFT", cb5, "BOTTOMLEFT", 0, -4)

    -- Prefix Label
    local prefixLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    prefixLabel:SetPoint("TOPLEFT", cb6, "BOTTOMLEFT", 0, -20)
    prefixLabel:SetText("Screenshot Prefix:")

    -- Prefix EditBox
    local prefixBox = CreateFrame("EditBox", "SB_PrefixBox", panel, "InputBoxTemplate")
    prefixBox:SetSize(200, 20)
    prefixBox:SetPoint("TOPLEFT", prefixLabel, "BOTTOMLEFT", 0, -5)
    prefixBox:SetAutoFocus(false)
    prefixBox:SetMaxLetters(50)
    prefixBox:SetText(ScreenshotBuddyDB.prefix or UnitName("player"))
    prefixBox:SetCursorPosition(0)

    prefixBox:SetScript("OnTextChanged", function(self)
        ScreenshotBuddyDB.prefix = self:GetText()
    end)

    InterfaceOptions_AddCategory(panel)
end)

--------------------------------------------------
-- Slash Command
--------------------------------------------------
SLASH_SCREENSHOTBUDDY1 = "/screenshotbuddy"
SLASH_SCREENSHOTBUDDY2 = "/sb"

SlashCmdList["SCREENSHOTBUDDY"] = function(msg)
    msg = msg and msg:lower() or ""

    if msg == "" or msg == "panel" then
        InterfaceOptionsFrame_OpenToCategory(optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(optionsPanel) -- double call needed in Classic
        return
    elseif msg == "now" then
        TakeShot("Manual")
        return
    elseif msg == "status" then
        Print("Status:")
        for k,v in pairs(ScreenshotBuddyDB.enabled) do
            Print(" %s: %s", k, v and "ON" or "OFF")
        end
        Print(" Prefix: %s", ScreenshotBuddyDB.prefix or UnitName("player"))
        return
    end

    Print("Commands:")
    Print(" /sb or /sb panel → open options panel")
    Print(" /sb now → take screenshot immediately")
    Print(" /sb status → list enabled events")
end

