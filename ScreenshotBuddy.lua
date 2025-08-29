-- Screenshot Buddy (Classic version)
-- Events: level up, skill up, timer, death, login, logout

local ADDON = ...
local function dprint(...) if ScreenshotBuddyDB and ScreenshotBuddyDB.verbose then print("|cff4bf5ff[SB]|r", ...) end end

--------------------------------------------------
-- Defaults
--------------------------------------------------
local DEFAULTS = {
  enabled = { levelup=true, skillup=true, timed=false, death=true, login=true, logout=true },
  interval = 900,
  delay = 1.0,
  verbose = true,
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
end

--------------------------------------------------
-- Screenshot helper
--------------------------------------------------
local function TakeShot(reason)
  local delay = ScreenshotBuddyDB and ScreenshotBuddyDB.delay or DEFAULTS.delay
  if reason then dprint("Screenshot queued:", reason, string.format("(in %.1fs)", delay)) end
  C_Timer.After(delay, function()
    Screenshot()
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

  help()
end

