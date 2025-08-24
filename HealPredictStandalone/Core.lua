--[[
HealPredictStandalone - Core System
Main initialization and coordination system
]]

local addonName = "HealPredictStandalone"
local HPS = {}
_G[addonName] = HPS

-- Saved variables
HPS.db = nil
HPS.chardb = nil

-- Modules
HPS.UnitFrames = {}
HPS.Config = {}

-- Constants
local ADDON_VERSION = "1.0.0"
local INTERFACE_VERSION = 30300

-- Event frame
local eventFrame = CreateFrame("Frame")

-- Initialization flags
local isInitialized = false
local hasEnteredWorld = false

-- Debug function
local function Debug(msg)
    if HPS.db and HPS.db.debug then
        print("|cff1784d1HealPredict|r: " .. tostring(msg))
    end
end

-- Default database values
local defaultDB = {
    debug = false,
    enabled = true,
    colors = {
        myHeals = {0.0, 1.0, 0.125, 0.25},
        otherHeals = {0.0, 1.0, 0.0, 0.25},
    },
    maxOverflow = 1.05,
    unitFrames = {
        detectBlizzard = true,
        detectOther = true,
    }
}

local defaultCharDB = {
    firstRun = true,
}

-- Database initialization
local function InitializeDatabase()
    if not HealPredictStandaloneDB then
        HealPredictStandaloneDB = {}
    end
    
    if not HealPredictStandaloneCharDB then
        HealPredictStandaloneCharDB = {}
    end
    
    -- Copy defaults
    for k, v in pairs(defaultDB) do
        if HealPredictStandaloneDB[k] == nil then
            if type(v) == "table" then
                HealPredictStandaloneDB[k] = {}
                for k2, v2 in pairs(v) do
                    if type(v2) == "table" then
                        HealPredictStandaloneDB[k][k2] = {}
                        for k3, v3 in pairs(v2) do
                            HealPredictStandaloneDB[k][k2][k3] = v3
                        end
                    else
                        HealPredictStandaloneDB[k][k2] = v2
                    end
                end
            else
                HealPredictStandaloneDB[k] = v
            end
        end
    end
    
    for k, v in pairs(defaultCharDB) do
        if HealPredictStandaloneCharDB[k] == nil then
            HealPredictStandaloneCharDB[k] = v
        end
    end
    
    HPS.db = HealPredictStandaloneDB
    HPS.chardb = HealPredictStandaloneCharDB
end

-- Main initialization
local function Initialize()
    if isInitialized then return end
    
    InitializeDatabase()
    
    -- Initialize modules
    if HPS.UnitFrames.Initialize then
        HPS.UnitFrames:Initialize()
    end
    
    if HPS.Config.Initialize then
        HPS.Config:Initialize()
    end
    
    isInitialized = true
    Debug("Initialized successfully")
    
    -- Show first run message
    if HPS.chardb.firstRun then
        print("|cff1784d1HealPredictStandalone|r version " .. ADDON_VERSION .. " loaded!")
        print("Use |cff1784d1/healpredict config|r to open settings")
        HPS.chardb.firstRun = false
    end
end

-- Event handling
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            Initialize()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not hasEnteredWorld then
            hasEnteredWorld = true
            -- Delayed unit frame detection
            if HPS.UnitFrames.DetectFrames then
                local delayFrame = CreateFrame("Frame")
                local elapsed = 0
                delayFrame:SetScript("OnUpdate", function(self, delta)
                    elapsed = elapsed + delta
                    if elapsed >= 2 then
                        self:SetScript("OnUpdate", nil)
                        HPS.UnitFrames:DetectFrames()
                    end
                end)
            end
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat
        Debug("Entering combat")
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat
        Debug("Leaving combat")
    end
end

-- Register events
eventFrame:SetScript("OnEvent", OnEvent)
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

-- Slash command
SLASH_HEALPREDICT1 = "/healpredict"
SLASH_HEALPREDICT2 = "/hps"
SlashCmdList["HEALPREDICT"] = function(msg)
    local cmd = string.lower((string.gsub(msg or "", "^%s*(.-)%s*$", "%1")))
    
    if cmd == "config" or cmd == "options" then
        if HPS.Config.ShowConfig then
            HPS.Config:ShowConfig()
        else
            print("|cff1784d1HealPredict|r: Config not yet implemented")
        end
    elseif cmd == "debug" then
        HPS.db.debug = not HPS.db.debug
        print("|cff1784d1HealPredict|r: Debug " .. (HPS.db.debug and "enabled" or "disabled"))
    elseif cmd == "status" then
        print("|cff1784d1HealPredictStandalone|r Status:")
        print("Version: " .. ADDON_VERSION)
        print("Enabled: " .. tostring(HPS.db.enabled))
        print("Debug: " .. tostring(HPS.db.debug))
        if HPS.UnitFrames.GetStatus then
            local status = HPS.UnitFrames:GetStatus()
            print("Frames detected: " .. (status.frameCount or 0))
        end
    else
        print("|cff1784d1HealPredictStandalone|r Commands:")
        print("/healpredict config - Open configuration")
        print("/healpredict debug - Toggle debug mode")
        print("/healpredict status - Show addon status")
    end
end

-- Public API
HPS.Debug = Debug
HPS.GetVersion = function() return ADDON_VERSION end
HPS.IsInitialized = function() return isInitialized end