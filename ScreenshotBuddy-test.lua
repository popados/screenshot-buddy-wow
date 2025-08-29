--------------------------------------------------
-- Screenshot Buddy (Classic WoW)
--------------------------------------------------

local SB = CreateFrame("Frame", "ScreenshotBuddyFrame")
SB:RegisterEvent("PLAYER_LEVEL_UP")
SB:RegisterEvent("CHAT_MSG_SKILL")
SB:RegisterEvent("PLAYER_DEAD")
SB:RegisterEvent("PLAYER_ENTERING_WORLD")
SB:RegisterEvent("PLAYER_LEAVING_WORLD")

local defaults = {
    enabled = {
        levelup = true,
        skillup = true,
        death   = true,
        login   = true,
        logout  = true,
        timed   = false,
    },
    interval = 600, -- seconds
    delay    = 2,   -- seconds
}

ScreenshotBuddyDB = ScreenshotBuddyDB or {}
local ticker = nil

--------------------------------------------------
-- Utility
--------------------------------------------------
local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff4bf5ff[SB]|r " .. msg)
end

local function TakeShot(reason)
    C_Timer.After(ScreenshotBuddyDB.delay or defaults.delay, function()
        Screenshot()
        Print("Screenshot taken (" .. reason .. ")")
    end)
end

local function refreshTicker()
    if ticker then ticker:Cancel() end
    if ScreenshotBuddyDB.enabled.timed then
        ticker = C_Timer.NewTicker(ScreenshotBuddyDB.interval, function()
            TakeShot("Timed")
        end)
    end
end

--------------------------------------------------
-- Event Handler
--------------------------------------------------
SB:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LEVEL_UP" and ScreenshotBuddyDB.enabled.levelup then
        TakeShot("Level Up")
    elseif event == "CHAT_MSG_SKILL" and ScreenshotBuddyDB.enabled.skillup then
        TakeShot("Skill Up")
    elseif event == "PLAYER_DEAD" and ScreenshotBuddyDB.enabled.death then
        TakeShot("Death")
    elseif event == "PLAYER_ENTERING_WORLD" and ScreenshotBuddyDB.enabled.login then
        TakeShot("Login")
    elseif event == "PLAYER_LEAVING_WORLD" and ScreenshotBuddyDB.enabled.logout then
        TakeShot("Logout")
    end
end)

--------------------------------------------------
-- On Load
--------------------------------------------------
local init = CreateFrame("Frame")
init:RegisterEvent("ADDON_LOADED")
init:SetScript("OnEvent", function(self, event, addon)
    if addon ~= "ScreenshotBuddy" then return end

    -- Load DB
    if not ScreenshotBuddyDB.enabled then
        ScreenshotBuddyDB.enabled = {}
    end
    for k,v in pairs(defaults.enabled) do
        if ScreenshotBuddyDB.enabled[k] == nil then
            ScreenshotBuddyDB.enabled[k] = v
        end
    end
    if not ScreenshotBuddyDB.interval then
        ScreenshotBuddyDB.interval = defaults.interval
    end
    if not ScreenshotBuddyDB.delay then
        ScreenshotBuddyDB.delay = defaults.delay
    end

    refreshTicker()
    Print("Loaded! Use /sb to open options.")
end)

--------------------------------------------------
-- Options Panel
--------------------------------------------------
local optionsPanel = CreateFrame("Frame", "ScreenshotBuddyOptionsPanel", InterfaceOptionsFramePanelContainer)
optionsPanel.name = "Screenshot Buddy"

local title = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Screenshot Buddy")

local desc = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
desc:SetWidth(400)
desc:SetJustifyH("LEFT")
desc:SetText("Automatically takes screenshots on level ups, skill ups, deaths, logins, logouts, or at timed intervals.")

-- Checkbox helper
local function CreateCheckbox(name, label, tooltip, settingKey, yOffset)
    local cb = CreateFrame("CheckButton", name, optionsPanel, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, yOffset)
    cb.Text:SetText(label)
    cb.tooltipText = tooltip

    cb:SetScript("OnClick", function(self)
        ScreenshotBuddyDB.enabled[settingKey] = self:GetChecked()
        if settingKey == "timed" then
            refreshTicker()
        end
    end)

    cb:SetScript("OnShow", function(self)
        self:SetChecked(ScreenshotBuddyDB.enabled[settingKey])
    end)

    return cb
end

-- Add checkboxes
CreateCheckbox("SB_Levelup", "Level Up", "Take screenshot when you level up", "levelup", -20)
CreateCheckbox("SB_Skillup", "Skill Up", "Take screenshot when you gain a skill point", "skillup", -45)
CreateCheckbox("SB_Death", "Death", "Take screenshot when you die", "death", -70)
CreateCheckbox("SB_Login", "Login", "Take screenshot when you log in", "login", -95)
CreateCheckbox("SB_Logout", "Logout", "Take screenshot when you log out", "logout", -120)
CreateCheckbox("SB_Timed", "Timed", "Take screenshot at regular intervals", "timed", -145)

-- Add panel
InterfaceOptions_AddCategory(optionsPanel)

--------------------------------------------------
-- Slash Command
--------------------------------------------------

-- Command handler
local function ScreenshotBuddy_SlashHandler(msg)
  msg = (msg or ""):lower():trim()

  if msg == "" or msg == "panel" then
      InterfaceOptionsFrame_OpenToCategory(optionsPanel)
      InterfaceOptionsFrame_OpenToCategory(optionsPanel) -- called twice to fix Blizzard bug
      return
  elseif msg == "now" then
      TakeShot("Manual")
      return
  elseif msg == "status" then
      Print("Current status:")
      for k, v in pairs(ScreenshotBuddyDB.enabled) do
          Print(string.format("  %s: %s", k, v and "ON" or "OFF"))
      end
      return
  else
      Print("ScreenshotBuddy commands:")
      Print("  /sb or /screenshotbuddy or /sb panel  - Open options panel")
      Print("  /sb now      - Take screenshot immediately")
      Print("  /sb status   - Show which events are enabled")
  end
end

-- Register slash commands
SlashCmdList["SCREENSHOTBUDDY"] = ScreenshotBuddy_SlashHandler
SLASH_SCREENSHOTBUDDY1 = "/screenshotbuddy"
SLASH_SCREENSHOTBUDDY2 = "/sb"
