-- Screenshot Buddy (Classic version)
-- Events: level up, skill up, timer, death, login, logout

local ADDON = ...
local optionsPanel
local function dprint(...) if ScreenshotBuddyDB and ScreenshotBuddyDB.verbose then print("|cff4bf5ff[SB]|r", ...) end end

--------------------------------------------------
-- Defaults
--------------------------------------------------
local DEFAULTS = {
  enabled = { levelup=true, skillup=true, timed=false, death=true, login=true, logout=true },
  interval = 900,
  delay = 1.0,
  verbose = true,
  prefix = "",
}

local function ensureDefaults()
  ScreenshotBuddyDB = ScreenshotBuddyDB or {}
  ScreenshotBuddyDB.enabled = ScreenshotBuddyDB.enabled or {}
  for k,v in pairs(DEFAULTS.enabled) do
    if ScreenshotBuddyDB.enabled[k] == nil then ScreenshotBuddyDB.enabled[k] = v end
  end
  if ScreenshotBuddyDB.interval == nil then ScreenshotBuddyDB.interval = DEFAULTS.interval end
  if ScreenshotBuddyDB.delay == nil then ScreenshotBuddyDB.delay = DEFAULTS.delay end
  if ScreenshotBuddyDB.verbose == nil then ScreenshotBuddyDB.verbose = DEFAULTS.verbose end
  if ScreenshotBuddyDB.prefix == nil then
    ScreenshotBuddyDB.prefix = DEFAULTS.prefix end
end

--------------------------------------------------
-- Screenshot helper
--------------------------------------------------
local function TakeShot(reason)
  local delay = ScreenshotBuddyDB and ScreenshotBuddyDB.delay or DEFAULTS.delay
  if reason then dprint("Screenshot queued:", reason, string.format("(in %.1fs)", delay)) end
  C_Timer.After(delay, function()
    if ScreenshotBuddyDB.prefix and ScreenshotBuddyDB.prefix ~= "" then
      Screenshot(ScreenshotBuddyDB.prefix .. "_") -- WoW appends timestamp automatically
  else 
    Screenshot()
  end  
    if reason then dprint("Screenshot taken:", reason) end
  end)
end

--------------------------------------------------
-- Timed ticker
--------------------------------------------------
local ticker
local function startTicker()
  if not ScreenshotBuddyDB.enabled.timed then return end
  local interval = ScreenshotBuddyDB.interval or DEFAULTS.interval
  if interval < 10 then interval = 10 end
  if ticker then ticker:Cancel() end
  ticker = C_Timer.NewTicker(interval, function() TakeShot("Timed") end)
  dprint("Timed screenshots enabled every", interval, "seconds.")
end
local function stopTicker() if ticker then ticker:Cancel() ticker=nil dprint("Timed screenshots disabled.") end end
local function refreshTicker() if ScreenshotBuddyDB.enabled.timed then startTicker() else stopTicker() end end

--------------------------------------------------
-- Event handler
--------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("CHAT_MSG_SYSTEM")
f:RegisterEvent("PLAYER_DEAD")

f:SetScript("OnEvent", function(self, event, ...)
  if event == "ADDON_LOADED" then
    if ... == ADDON then
      ensureDefaults()
      dprint("Loaded. Use /sb for options.")
    end

  elseif event == "PLAYER_LOGIN" then
    if ScreenshotBuddyDB.enabled.login then TakeShot("Login") end
    refreshTicker()

  elseif event == "PLAYER_LOGOUT" then
    if ScreenshotBuddyDB.enabled.logout then TakeShot("Logout") end
    stopTicker()

  elseif event == "PLAYER_LEVEL_UP" then
    if ScreenshotBuddyDB.enabled.levelup then
      local newLevel = ...
      TakeShot("Level Up -> " .. tostring(newLevel))
    end

  elseif event == "CHAT_MSG_SYSTEM" then
    if ScreenshotBuddyDB.enabled.skillup then
      local msg = ...
      if msg and msg:find("Your skill in") then
        TakeShot("Skill Up")
        dprint(msg)
      end
    end

  elseif event == "PLAYER_DEAD" then
    if ScreenshotBuddyDB.enabled.death then TakeShot("Death") end
  end
end)


--------------------------------------------------
-- Interface Options Panel
--------------------------------------------------
local optionsPanel = CreateFrame("Frame", ADDON.."OptionsPanel", InterfaceOptionsFramePanelContainer)
optionsPanel.name = "Screenshot Buddy"

-- Register panel with options
-- Old: InterfaceOptions_AddCategory(panel)
local category = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name)
Settings.RegisterAddOnCategory(category)

--Show Options Panel
optionsPanel:Hide()
optionsPanel:SetScript("OnShow", function(self)
  if self.inited then return end
  self.inited = true

  local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Screenshot Buddy (Classic)")

  local subtitle = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  subtitle:SetText("Automatically take screenshots for various events.")

  --------------------------------------------------
  -- Helper to make checkboxes
  --------------------------------------------------
  local function CreateCheck(label, key, yOff)
    local cb = CreateFrame("CheckButton", ADDON.."CB"..key, self, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, yOff)
    cb.Text:SetText(label)
    cb:SetScript("OnClick", function(self)
      ScreenshotBuddyDB.enabled[key] = self:GetChecked()
      if key == "timed" then refreshTicker() end
    end)
    cb:SetChecked(ScreenshotBuddyDB.enabled[key])
    return cb
  end

  local y = -8
  CreateCheck("Level Up", "levelup", y);   y = y - 24
  CreateCheck("Skill Up", "skillup", y);   y = y - 24
  CreateCheck("Death", "death", y);        y = y - 24
  CreateCheck("Login", "login", y);        y = y - 24
  CreateCheck("Logout", "logout", y);      y = y - 24
  CreateCheck("Timed Screenshots", "timed", y); y = y - 32

  --------------------------------------------------
  -- Interval slider
  --------------------------------------------------
  local intervalSlider = CreateFrame("Slider", ADDON.."IntervalSlider", self, "OptionsSliderTemplate")
  intervalSlider:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 200, -20)
  intervalSlider:SetMinMaxValues(10, 3600)
  intervalSlider:SetValueStep(10)
  intervalSlider:SetObeyStepOnDrag(true)
  intervalSlider:SetWidth(200)
  _G[intervalSlider:GetName().."Low"]:SetText("10s")
  _G[intervalSlider:GetName().."High"]:SetText("3600s")
  _G[intervalSlider:GetName().."Text"]:SetText("Timed Interval (sec)")
  intervalSlider:SetScript("OnValueChanged", function(self, value)
    ScreenshotBuddyDB.interval = math.floor(value)
    refreshTicker()
  end)
  intervalSlider:SetValue(ScreenshotBuddyDB.interval)

  --------------------------------------------------
  -- Delay slider
  --------------------------------------------------
  local delaySlider = CreateFrame("Slider", ADDON.."DelaySlider", self, "OptionsSliderTemplate")
  delaySlider:SetPoint("TOPLEFT", intervalSlider, "BOTTOMLEFT", 0, -40)
  delaySlider:SetMinMaxValues(0, 5)
  delaySlider:SetValueStep(0.1)
  delaySlider:SetObeyStepOnDrag(true)
  delaySlider:SetWidth(200)
  _G[delaySlider:GetName().."Low"]:SetText("0s")
  _G[delaySlider:GetName().."High"]:SetText("5s")
  _G[delaySlider:GetName().."Text"]:SetText("Screenshot Delay (sec)")
  delaySlider:SetScript("OnValueChanged", function(self, value)
    ScreenshotBuddyDB.delay = tonumber(string.format("%.1f", value))
  end)
  delaySlider:SetValue(ScreenshotBuddyDB.delay)

  --------------------------------------------------
  -- Verbose toggle
  --------------------------------------------------
  local verboseCB = CreateFrame("CheckButton", ADDON.."VerboseCB", self, "InterfaceOptionsCheckButtonTemplate")
  verboseCB:SetPoint("TOPLEFT", delaySlider, "BOTTOMLEFT", 0, -30)
  verboseCB.Text:SetText("Verbose Mode (chat feedback)")
  verboseCB:SetScript("OnClick", function(self)
    ScreenshotBuddyDB.verbose = self:GetChecked()
  end)
  verboseCB:SetChecked(ScreenshotBuddyDB.verbose)
  
  local prefixLabel = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  prefixLabel:SetPoint("TOPLEFT", verboseCB, "BOTTOMLEFT", -200, -25)
  prefixLabel:SetText("Screenshot Prefix:")


  local prefixBox = CreateFrame("EditBox", ADDON.."SB_PrefixBox", self, "InputBoxTemplate")
  prefixBox:SetSize(200, 20)
  prefixBox:SetPoint("TOPLEFT", verboseCB, "BOTTOMLEFT", 20, -405)
  prefixBox:SetAutoFocus(false)
  prefixBox:SetText("")ß
  prefixBox:SetMaxLetters(50)
  prefixBox:SetScript("OnTextChanged", function(self)
    ScreenshotBuddyDB.prefix = self:GetText()

end)
end)
--------------------------------------------------
-- Slash commands (/sb)
--------------------------------------------------
SLASH_SCREENSHOTBUDDY1 = "/screenshotbuddy"
SLASH_SCREENSHOTBUDDY2 = "/sb"

SlashCmdList.SCREENSHOTBUDDY = function(msg)
  msg = msg and msg:lower() or ""
  local args = {}
  for w in msg:gmatch("%S+") do table.insert(args, w) end

  local function help()
    print("|cff4bf5ffScreenshot Buddy (Classic) commands:|r")
    print(" /sb on <event> / off <event>  (levelup, skillup, timed, death, login, logout)")
    print(" /sb interval <sec>            set timed interval")
    print(" /sb delay <sec>               set screenshot delay")
    print(" /sb verbose <on|off>")
    print(" /sb now                       take a screenshot")
    print(" /sb status")
  end

  local function status()
    local e=ScreenshotBuddyDB.enabled
    print("Status: levelup",e.levelup,"skillup",e.skillup,"death",e.death)
    print("        login",e.login,"logout",e.logout,"timed",e.timed)
    print("Interval",ScreenshotBuddyDB.interval," Delay",ScreenshotBuddyDB.delay," Verbose",ScreenshotBuddyDB.verbose)
  end

  if #args==0 then help() return end
  if args[1]=="now" then TakeShot("Manual") return end
  if args[1]=="status" then status() return end
  if args[1]=="interval" and tonumber(args[2]) then ScreenshotBuddyDB.interval=math.max(10,tonumber(args[2])) refreshTicker() return end
  if args[1]=="delay" and tonumber(args[2]) then ScreenshotBuddyDB.delay=math.max(0,tonumber(args[2])) return end
  if args[1]=="verbose" and (args[2]=="on" or args[2]=="off") then ScreenshotBuddyDB.verbose=(args[2]=="on") return end

  local valid={levelup=true,skillup=true,timed=true,death=true,login=true,logout=true}
  if (args[1]=="on" or args[1]=="off") and args[2] and valid[args[2]] then
    ScreenshotBuddyDB.enabled[args[2]]=(args[1]=="on")
    if args[2]=="timed" then refreshTicker() end
    print(args[2],args[1]=="on" and "enabled" or "disabled")
    return
  end
  if args[1]=="panel" then
    Settings.OpenToCategory(optionsPanel.name)
    Settings.OpenToCategory(optionsPanel.name)

    return
  end
  help()
end