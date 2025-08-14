--[[
HealPredictStandalone - UnitFrames Core
Unit frame detection and management system
]]

local addonName = "HealPredictStandalone"
local HPS = _G[addonName]
local UF = HPS.UnitFrames

-- Dependencies
local healpredict = _G.HealPredict
local oUF = _G.oUF

-- Frame registry
local detectedFrames = {}
local hookedFrames = {}
local enabledFrames = {}

-- Detection patterns for different unit frame addons
local detectionPatterns = {
    -- Blizzard frames
    blizzard = {
        "PlayerFrame",
        "TargetFrame", 
        "FocusFrame",
        "PartyMemberFrame1",
        "PartyMemberFrame2", 
        "PartyMemberFrame3",
        "PartyMemberFrame4",
        "CompactRaidFrame",
    },
    -- Common addon patterns
    elvui = {"ElvUF_Player", "ElvUF_Target", "ElvUF_Focus"},
    shadowed = {"ShadowedUnitFrames"},
    pitbull = {"PitBull"},
    xperl = {"XPerl"},
    grid = {"Grid"},
    vuhdo = {"VuhDo"},
    healbot = {"HealBot"},
}

-- Unit detection
local unitDetectionMap = {
    ["PlayerFrame"] = "player",
    ["TargetFrame"] = "target",
    ["FocusFrame"] = "focus",
    ["PartyMemberFrame1"] = "party1",
    ["PartyMemberFrame2"] = "party2", 
    ["PartyMemberFrame3"] = "party3",
    ["PartyMemberFrame4"] = "party4",
}

local function Debug(msg)
    if HPS.Debug then
        HPS.Debug("UF: " .. msg)
    end
end

-- Get unit from frame
local function GetFrameUnit(frame)
    if not frame then return nil end
    
    -- Direct unit attribute
    if frame.unit then
        return frame.unit
    end
    
    -- GetAttribute for secure frames
    if frame.GetAttribute then
        local unit = frame:GetAttribute("unit")
        if unit then return unit end
    end
    
    -- Name-based detection
    local name = frame:GetName()
    if name and unitDetectionMap[name] then
        return unitDetectionMap[name]
    end
    
    -- Pattern matching for raid/party frames
    if name then
        local party = string.match(name, "party(%d)")
        if party then
            return "party" .. party
        end
        
        local raid = string.match(name, "raid(%d+)")
        if raid then
            return "raid" .. raid
        end
    end
    
    return nil
end

-- Check if frame has health bar
local function HasHealthBar(frame)
    if not frame then return false end
    
    -- Common health bar names
    local healthBarNames = {
        "healthbar", "healthBar", "HealthBar", "health", "Health",
        "StatusBar", "statusbar", "statusBar"
    }
    
    for _, name in pairs(healthBarNames) do
        local healthBar = frame[name]
        if healthBar and healthBar.SetValue then
            return healthBar
        end
    end
    
    -- Check children for health bars
    local children = {frame:GetChildren()}
    for _, child in pairs(children) do
        if child.SetValue and child.GetValue then
            -- Likely a status bar
            return child
        end
    end
    
    return nil
end

-- Create heal prediction bars for a frame
local function CreateHealPredictionBars(frame, healthBar)
    if not frame or not healthBar then return nil end
    
    local unit = GetFrameUnit(frame)
    if not unit then return nil end
    
    Debug("Creating heal prediction bars for " .. unit)
    
    -- Create prediction bars
    local myBar = CreateFrame("StatusBar", nil, healthBar)
    local otherBar = CreateFrame("StatusBar", nil, healthBar)
    
    -- Configure bars
    myBar:SetFrameLevel(healthBar:GetFrameLevel() + 1)
    otherBar:SetFrameLevel(healthBar:GetFrameLevel() + 1)
    
    -- Set textures
    local texture = healthBar:GetStatusBarTexture() or "Interface\\TargetingFrame\\UI-StatusBar"
    myBar:SetStatusBarTexture(texture)
    otherBar:SetStatusBarTexture(texture)
    
    -- Set colors
    local myColor = HPS.db.colors.myHeals
    local otherColor = HPS.db.colors.otherHeals
    myBar:SetStatusBarColor(myColor[1], myColor[2], myColor[3], myColor[4])
    otherBar:SetStatusBarColor(otherColor[1], otherColor[2], otherColor[3], otherColor[4])
    
    -- Position bars
    local orientation = healthBar:GetOrientation and healthBar:GetOrientation() or "HORIZONTAL"
    
    myBar:SetOrientation(orientation)
    otherBar:SetOrientation(orientation)
    
    if orientation == "HORIZONTAL" then
        myBar:SetPoint("TOPLEFT", healthBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
        myBar:SetPoint("BOTTOMLEFT", healthBar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
        
        otherBar:SetPoint("TOPLEFT", myBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
        otherBar:SetPoint("BOTTOMLEFT", myBar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
    else
        myBar:SetPoint("BOTTOMLEFT", healthBar:GetStatusBarTexture(), "TOPLEFT", 0, 0)
        myBar:SetPoint("BOTTOMRIGHT", healthBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
        
        otherBar:SetPoint("BOTTOMLEFT", myBar:GetStatusBarTexture(), "TOPLEFT", 0, 0)
        otherBar:SetPoint("BOTTOMRIGHT", myBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
    end
    
    -- Set initial size
    myBar:SetWidth(100)
    myBar:SetHeight(healthBar:GetHeight())
    otherBar:SetWidth(100) 
    otherBar:SetHeight(healthBar:GetHeight())
    
    -- Create element structure
    local element = {
        myBar = myBar,
        otherBar = otherBar,
        maxOverflow = HPS.db.maxOverflow or 1.05,
        unit = unit,
        frame = frame,
        healthBar = healthBar,
    }
    
    return element
end

-- Update heal prediction for a frame
local function UpdateHealPrediction(element)
    if not element or not element.unit then return end
    
    local unit = element.unit
    local myIncomingHeal = healpredict.UnitGetIncomingHeals(unit, UnitName("player")) or 0
    local allIncomingHeal = healpredict.UnitGetIncomingHeals(unit) or 0
    local health = UnitHealth(unit) or 0
    local maxHealth = UnitHealthMax(unit) or 1
    local maxOverflowHP = maxHealth * element.maxOverflow
    local otherIncomingHeal = 0
    
    if health + allIncomingHeal > maxOverflowHP then
        allIncomingHeal = maxOverflowHP - health
    end
    
    if allIncomingHeal < myIncomingHeal then
        myIncomingHeal = allIncomingHeal
    else
        otherIncomingHeal = allIncomingHeal - myIncomingHeal
    end
    
    if element.myBar then
        element.myBar:SetMinMaxValues(0, maxHealth)
        element.myBar:SetValue(myIncomingHeal)
        element.myBar:Show()
    end
    
    if element.otherBar then
        element.otherBar:SetMinMaxValues(0, maxHealth)
        element.otherBar:SetValue(otherIncomingHeal)  
        element.otherBar:Show()
    end
end

-- Hook a frame for heal prediction
local function HookFrame(frame)
    if not frame or hookedFrames[frame] then return false end
    
    local unit = GetFrameUnit(frame)
    local healthBar = HasHealthBar(frame)
    
    if not unit or not healthBar then
        return false
    end
    
    local element = CreateHealPredictionBars(frame, healthBar)
    if not element then return false end
    
    -- Store references
    hookedFrames[frame] = element
    enabledFrames[unit] = element
    
    Debug("Hooked frame for unit: " .. unit)
    return true
end

-- Detect all available unit frames
function UF:DetectFrames()
    Debug("Starting frame detection...")
    
    local frameCount = 0
    
    if HPS.db.unitFrames.detectBlizzard then
        -- Detect Blizzard frames
        for _, frameName in pairs(detectionPatterns.blizzard) do
            local frame = _G[frameName]
            if frame and frame:IsVisible() then
                if HookFrame(frame) then
                    frameCount = frameCount + 1
                end
            end
        end
    end
    
    if HPS.db.unitFrames.detectOther then
        -- Detect other addon frames
        for addonName, patterns in pairs(detectionPatterns) do
            if addonName ~= "blizzard" then
                for _, pattern in pairs(patterns) do
                    -- Find frames matching pattern
                    for i = 1, 100 do
                        local frameName = pattern .. i
                        local frame = _G[frameName]
                        if frame and frame:IsVisible() then
                            if HookFrame(frame) then
                                frameCount = frameCount + 1
                            end
                        else
                            break
                        end
                    end
                    
                    -- Also check direct name
                    local frame = _G[pattern]
                    if frame and frame:IsVisible() then
                        if HookFrame(frame) then
                            frameCount = frameCount + 1
                        end
                    end
                end
            end
        end
    end
    
    Debug("Frame detection complete. Hooked " .. frameCount .. " frames")
    
    -- Register heal prediction callback
    if frameCount > 0 and healpredict then
        healpredict.RegisterCallback("HealPredictStandalone", function(...)
            local units = {...}
            for _, unit in pairs(units) do
                local element = enabledFrames[unit]
                if element then
                    UpdateHealPrediction(element)
                end
            end
        end)
        Debug("Registered heal prediction callback")
    end
    
    return frameCount
end

-- Get status information
function UF:GetStatus()
    local hookedCount = 0
    local enabledCount = 0
    
    for _ in pairs(hookedFrames) do
        hookedCount = hookedCount + 1
    end
    
    for _ in pairs(enabledFrames) do
        enabledCount = enabledCount + 1
    end
    
    return {
        frameCount = hookedCount,
        enabledCount = enabledCount,
        detectedFrames = detectedFrames,
    }
end

-- Initialize
function UF:Initialize()
    Debug("UnitFrames module initialized")
end

-- Clean up
function UF:Disable()
    if healpredict then
        healpredict.UnregisterCallback("HealPredictStandalone")
    end
    
    for frame, element in pairs(hookedFrames) do
        if element.myBar then
            element.myBar:Hide()
        end
        if element.otherBar then
            element.otherBar:Hide()
        end
    end
    
    hookedFrames = {}
    enabledFrames = {}
    
    Debug("UnitFrames module disabled")
end