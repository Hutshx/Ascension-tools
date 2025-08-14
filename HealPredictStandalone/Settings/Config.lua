--[[
HealPredictStandalone - Configuration System
Basic configuration interface and settings management
]]

local addonName = "HealPredictStandalone"
local HPS = _G[addonName]
local Config = HPS.Config

-- Configuration frame
local configFrame = nil
local isConfigInitialized = false

local function Debug(msg)
    if HPS.Debug then
        HPS.Debug("Config: " .. msg)
    end
end

-- Create configuration frame
local function CreateConfigFrame()
    if configFrame then return configFrame end
    
    configFrame = CreateFrame("Frame", addonName .. "ConfigFrame", UIParent)
    configFrame:SetSize(400, 500)
    configFrame:SetPoint("CENTER")
    configFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    configFrame:SetBackdropColor(0, 0, 0, 1)
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
    configFrame:SetFrameStrata("DIALOG")
    configFrame:Hide()
    
    -- Title
    local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("HealPredict Standalone Settings")
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() configFrame:Hide() end)
    
    -- Enable checkbox
    local enableCheck = CreateFrame("CheckButton", nil, configFrame, "OptionsCheckButtonTemplate")
    enableCheck:SetPoint("TOPLEFT", 30, -60)
    enableCheck.Text:SetText("Enable Heal Prediction")
    enableCheck:SetChecked(HPS.db.enabled)
    enableCheck:SetScript("OnClick", function()
        HPS.db.enabled = enableCheck:GetChecked()
        Debug("Heal prediction " .. (HPS.db.enabled and "enabled" or "disabled"))
    end)
    
    -- Debug checkbox
    local debugCheck = CreateFrame("CheckButton", nil, configFrame, "OptionsCheckButtonTemplate")
    debugCheck:SetPoint("TOPLEFT", 30, -90)
    debugCheck.Text:SetText("Enable Debug Mode")
    debugCheck:SetChecked(HPS.db.debug)
    debugCheck:SetScript("OnClick", function()
        HPS.db.debug = debugCheck:GetChecked()
        Debug("Debug mode " .. (HPS.db.debug and "enabled" or "disabled"))
    end)
    
    -- Detect Blizzard frames checkbox
    local blizzardCheck = CreateFrame("CheckButton", nil, configFrame, "OptionsCheckButtonTemplate")
    blizzardCheck:SetPoint("TOPLEFT", 30, -120)
    blizzardCheck.Text:SetText("Detect Blizzard Unit Frames")
    blizzardCheck:SetChecked(HPS.db.unitFrames.detectBlizzard)
    blizzardCheck:SetScript("OnClick", function()
        HPS.db.unitFrames.detectBlizzard = blizzardCheck:GetChecked()
        Debug("Blizzard frame detection " .. (HPS.db.unitFrames.detectBlizzard and "enabled" or "disabled"))
    end)
    
    -- Detect other addon frames checkbox
    local otherCheck = CreateFrame("CheckButton", nil, configFrame, "OptionsCheckButtonTemplate")
    otherCheck:SetPoint("TOPLEFT", 30, -150)
    otherCheck.Text:SetText("Detect Other Addon Frames")
    otherCheck:SetChecked(HPS.db.unitFrames.detectOther)
    otherCheck:SetScript("OnClick", function()
        HPS.db.unitFrames.detectOther = otherCheck:GetChecked()
        Debug("Other addon frame detection " .. (HPS.db.unitFrames.detectOther and "enabled" or "disabled"))
    end)
    
    -- Max overflow slider
    local overflowLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    overflowLabel:SetPoint("TOPLEFT", 30, -190)
    overflowLabel:SetText("Max Overflow:")
    
    local overflowSlider = CreateFrame("Slider", nil, configFrame, "OptionsSliderTemplate")
    overflowSlider:SetPoint("TOPLEFT", 30, -210)
    overflowSlider:SetSize(200, 20)
    overflowSlider:SetMinMaxValues(1.0, 2.0)
    overflowSlider:SetValue(HPS.db.maxOverflow or 1.05)
    overflowSlider:SetValueStep(0.05)
    overflowSlider.Low:SetText("1.0")
    overflowSlider.High:SetText("2.0")
    overflowSlider.Text:SetText(string.format("%.2f", overflowSlider:GetValue()))
    overflowSlider:SetScript("OnValueChanged", function(self, value)
        HPS.db.maxOverflow = value
        self.Text:SetText(string.format("%.2f", value))
        Debug("Max overflow set to: " .. value)
    end)
    
    -- Color settings section
    local colorLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colorLabel:SetPoint("TOPLEFT", 30, -250)
    colorLabel:SetText("My Heals Color:")
    
    -- My heals color button
    local myColorButton = CreateFrame("Button", nil, configFrame)
    myColorButton:SetPoint("LEFT", colorLabel, "RIGHT", 10, 0)
    myColorButton:SetSize(30, 20)
    myColorButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    local myColor = HPS.db.colors.myHeals
    myColorButton:SetBackdropColor(myColor[1], myColor[2], myColor[3], myColor[4])
    myColorButton:SetScript("OnClick", function()
        print("Color picker not implemented yet")
    end)
    
    -- Other heals color
    local otherColorLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    otherColorLabel:SetPoint("TOPLEFT", 30, -280)
    otherColorLabel:SetText("Other Heals Color:")
    
    local otherColorButton = CreateFrame("Button", nil, configFrame)
    otherColorButton:SetPoint("LEFT", otherColorLabel, "RIGHT", 10, 0)
    otherColorButton:SetSize(30, 20)
    otherColorButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    local otherColor = HPS.db.colors.otherHeals
    otherColorButton:SetBackdropColor(otherColor[1], otherColor[2], otherColor[3], otherColor[4])
    otherColorButton:SetScript("OnClick", function()
        print("Color picker not implemented yet")
    end)
    
    -- Refresh frames button
    local refreshButton = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    refreshButton:SetPoint("TOPLEFT", 30, -320)
    refreshButton:SetSize(120, 25)
    refreshButton:SetText("Refresh Frames")
    refreshButton:SetScript("OnClick", function()
        if HPS.UnitFrames.DetectFrames then
            local count = HPS.UnitFrames:DetectFrames()
            print("|cff1784d1HealPredict|r: Detected " .. count .. " frames")
        end
    end)
    
    -- Status info
    local statusText = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("TOPLEFT", 30, -360)
    statusText:SetText("Status: Ready")
    
    -- Update status text
    local function UpdateStatus()
        if HPS.UnitFrames.GetStatus then
            local status = HPS.UnitFrames:GetStatus()
            statusText:SetText("Frames Hooked: " .. (status.frameCount or 0))
        end
    end
    
    -- Update status every 2 seconds when frame is visible
    local statusTimer = nil
    local function StartStatusTimer()
        if statusTimer then return end
        statusTimer = CreateFrame("Frame")
        local elapsed = 0
        statusTimer:SetScript("OnUpdate", function(self, delta)
            elapsed = elapsed + delta
            if elapsed >= 2 then
                elapsed = 0
                UpdateStatus()
            end
        end)
    end
    
    local function StopStatusTimer()
        if statusTimer then
            statusTimer:SetScript("OnUpdate", nil)
            statusTimer = nil
        end
    end
    
    configFrame:SetScript("OnHide", StopStatusTimer)
    configFrame:SetScript("OnShow", function() 
        UpdateStatus()
        StartStatusTimer()
    end)
    
    return configFrame
end

-- Show configuration
function Config:ShowConfig()
    if not isConfigInitialized then
        CreateConfigFrame()
        isConfigInitialized = true
    end
    
    if configFrame then
        configFrame:Show()
        Debug("Configuration window opened")
    end
end

-- Hide configuration
function Config:HideConfig()
    if configFrame then
        configFrame:Hide()
        Debug("Configuration window closed")
    end
end

-- Initialize configuration system
function Config:Initialize()
    Debug("Configuration system initialized")
    isConfigInitialized = false -- Will be created on first use
end

-- Reset to defaults
function Config:ResetToDefaults()
    Debug("Resetting configuration to defaults")
    -- This would reset HPS.db to defaults
    -- Implementation would go here
end