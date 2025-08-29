-- ScreenshotBuddyOptions.lua
local f = CreateFrame("Frame", "ScreenshotBuddyOptions", InterfaceOptionsFramePanelContainer)
f.name = "Screenshot Buddy"

-- When panel is opened
f:SetScript("OnShow", function(self)
    if self.initialized then return end
    self.initialized = true

    local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Screenshot Buddy")

    local function makeCheckbox(label, optionKey, yOffset, tooltip)
        local cb = CreateFrame("CheckButton", nil, self, "InterfaceOptionsCheckButtonTemplate")
        cb.Text:SetText(label)
        cb:SetPoint("TOPLEFT", 16, yOffset)
        cb.tooltipText = tooltip

        cb:SetScript("OnClick", function(box)
            ScreenshotBuddyDB.enabled[optionKey] = box:GetChecked()
            if optionKey == "timed" then
                -- restart ticker
                if ScreenshotBuddyDB.enabled.timed then
                    ScreenshotBuddy.startTicker()
                else
                    ScreenshotBuddy.stopTicker()
                end
            end
        end)

        cb:SetChecked(ScreenshotBuddyDB.enabled[optionKey])
        return cb
    end

    -- Checkboxes
    local y = -48
    local boxes = {}
    local options = {
        { "Level Up", "levelup", "Screenshot when you level up." },
        { "Skill Up", "skillup", "Screenshot when a skill increases." },
        { "Death", "death", "Screenshot when you die." },
        { "Login", "login", "Screenshot when you log in." },
        { "Logout", "logout", "Screenshot when you log out." },
        { "Timed", "timed", "Take screenshots on a timer." },
    }
    for i,opt in ipairs(options) do
        boxes[#boxes+1] = makeCheckbox(opt[1], opt[2], y, opt[3])
        y = y - 32
    end

    -- Interval slider
    local slider = CreateFrame("Slider", "ScreenshotBuddyIntervalSlider", self, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 16, y - 16)
    slider:SetMinMaxValues(10, 3600)
    slider:SetValueStep(10)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(250)
    _G[slider:GetName() .. "Low"]:SetText("10s")
    _G[slider:GetName() .. "High"]:SetText("3600s")
    _G[slider:GetName() .. "Text"]:SetText("Interval (timed)")
    slider:SetScript("OnValueChanged", function(self, value)
        ScreenshotBuddyDB.interval = math.floor(value)
        if ScreenshotBuddyDB.enabled.timed then
            ScreenshotBuddy.startTicker()
        end
    end)
    slider:SetValue(ScreenshotBuddyDB.interval or 900)

    -- Delay slider
    local delaySlider = CreateFrame("Slider", "ScreenshotBuddyDelaySlider", self, "OptionsSliderTemplate")
    delaySlider:SetPoint("TOPLEFT", 16, y - 80)
    delaySlider:SetMinMaxValues(0, 5)
    delaySlider:SetValueStep(0.1)
    delaySlider:SetObeyStepOnDrag(true)
    delaySlider:SetWidth(250)
    _G[delaySlider:GetName() .. "Low"]:SetText("0s")
    _G[delaySlider:GetName() .. "High"]:SetText("5s")
    _G[delaySlider:GetName() .. "Text"]:SetText("Delay before screenshot")
    delaySlider:SetScript("OnValueChanged", function(self, value)
        ScreenshotBuddyDB.delay = tonumber(string.format("%.1f", value))
    end)
    delaySlider:SetValue(ScreenshotBuddyDB.delay or 1.0)

    -- Verbose checkbox
    local verboseCB = makeCheckbox("Verbose chat messages", "verbose", y - 140, "Show messages when screenshots are taken.")
    verboseCB:SetChecked(ScreenshotBuddyDB.verbose)
    verboseCB:SetScript("OnClick", function(box)
        ScreenshotBuddyDB.verbose = box:GetChecked()
    end)

    -- Test button
    local btn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    btn:SetSize(120, 22)
    btn:SetPoint("TOPLEFT", 16, y - 190)
    btn:SetText("Test Screenshot")
    btn:SetScript("OnClick", function() ScreenshotBuddy.TakeShot("Test") end)
end)

InterfaceOptions_AddCategory(f)
