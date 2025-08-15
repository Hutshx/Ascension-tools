--[[
LibHealComm-4.0 - Système de communication de heal simplifié
Version autonome pour HealPredictionDisplay
]]

local MAJOR, MINOR = "LibHealComm-4.0", 100
local LibHealComm = LibStub:NewLibrary(MAJOR, MINOR)

if not LibHealComm then return end

-- Import des fonctions WoW
local GetTime = GetTime
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitExists = UnitExists
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local SendAddonMessage = SendAddonMessage
local GetNumRaidMembers = GetNumRaidMembers
local GetNumPartyMembers = GetNumPartyMembers or function() return 0 end

-- Constantes
LibHealComm.ALL_HEALS = 0x01
LibHealComm.CASTED_HEALS = 0x02
LibHealComm.CHANNEL_HEALS = 0x04
LibHealComm.HOT_HEALS = 0x08

-- Variables locales
local callbacks = LibStub("CallbackHandler-1.0"):New(LibHealComm)
local playerGUID = nil
local healData = {}
local castData = {}

-- Initialisations
local function Initialize()
    playerGUID = UnitGUID("player")
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        Initialize()
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- Fonctions utilitaires
local function CleanExpiredHeals()
    local currentTime = GetTime()
    for targetGUID, healers in pairs(healData) do
        for healerGUID, heals in pairs(healers) do
            for castID, healInfo in pairs(heals) do
                if healInfo.endTime and healInfo.endTime < currentTime then
                    heals[castID] = nil
                end
            end
            if not next(heals) then
                healers[healerGUID] = nil
            end
        end
        if not next(healers) then
            healData[targetGUID] = nil
        end
    end
end

-- Fonctions API principales
function LibHealComm:GetHealAmount(targetGUID, healFilter, timeLimit)
    if not targetGUID then return 0 end
    
    CleanExpiredHeals()
    
    local totalHealing = 0
    local currentTime = GetTime()
    local maxTime = timeLimit or (currentTime + 10)
    
    if healData[targetGUID] then
        for healerGUID, heals in pairs(healData[targetGUID]) do
            for castID, healInfo in pairs(heals) do
                if healInfo.endTime and healInfo.endTime <= maxTime then
                    if not healFilter or (healFilter == self.ALL_HEALS) then
                        totalHealing = totalHealing + healInfo.amount
                    elseif healFilter == self.CASTED_HEALS and healInfo.type == "cast" then
                        totalHealing = totalHealing + healInfo.amount
                    elseif healFilter == self.CHANNEL_HEALS and healInfo.type == "channel" then
                        totalHealing = totalHealing + healInfo.amount
                    elseif healFilter == self.HOT_HEALS and healInfo.type == "hot" then
                        totalHealing = totalHealing + healInfo.amount
                    end
                end
            end
        end
    end
    
    return totalHealing
end

function LibHealComm:GetCasterHealAmount(healerGUID, healFilter, timeLimit)
    if not healerGUID then return 0 end
    
    CleanExpiredHeals()
    
    local totalHealing = 0
    local currentTime = GetTime()
    local maxTime = timeLimit or (currentTime + 10)
    
    for targetGUID, healers in pairs(healData) do
        if healers[healerGUID] then
            for castID, healInfo in pairs(healers[healerGUID]) do
                if healInfo.endTime and healInfo.endTime <= maxTime then
                    if not healFilter or (healFilter == self.ALL_HEALS) then
                        totalHealing = totalHealing + healInfo.amount
                    elseif healFilter == self.CASTED_HEALS and healInfo.type == "cast" then
                        totalHealing = totalHealing + healInfo.amount
                    elseif healFilter == self.CHANNEL_HEALS and healInfo.type == "channel" then
                        totalHealing = totalHealing + healInfo.amount
                    elseif healFilter == self.HOT_HEALS and healInfo.type == "hot" then
                        totalHealing = totalHealing + healInfo.amount
                    end
                end
            end
        end
    end
    
    return totalHealing
end

-- Gestion des événements de cast
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SENT")

-- Sorts de heal reconnus (liste simplifiée)
local healSpells = {
    -- Prêtre
    [2061] = {amount = 100, type = "cast"},   -- Flash Heal
    [2060] = {amount = 300, type = "cast"},   -- Greater Heal
    [596] = {amount = 400, type = "cast"},    -- Prayer of Healing
    
    -- Paladin
    [19750] = {amount = 200, type = "cast"},  -- Flash of Light
    [635] = {amount = 400, type = "cast"},    -- Holy Light
    
    -- Druide
    [5185] = {amount = 300, type = "cast"},   -- Healing Touch
    [8936] = {amount = 50, type = "hot"},     -- Regrowth
    
    -- Chaman
    [331] = {amount = 250, type = "cast"},    -- Healing Wave
    [8004] = {amount = 150, type = "cast"},   -- Lesser Healing Wave
    [1064] = {amount = 200, type = "cast"},   -- Chain Heal
}

local function GetHealInfo(spellID, spellName)
    local baseInfo = healSpells[spellID]
    if baseInfo then
        return baseInfo.amount, baseInfo.type
    end
    
    -- Estimation basée sur le nom du sort
    if spellName then
        if spellName:find("Flash") or spellName:find("Lesser") then
            return 150, "cast"
        elseif spellName:find("Greater") or spellName:find("Holy") then
            return 350, "cast"
        elseif spellName:find("Chain") or spellName:find("Prayer") then
            return 200, "cast"
        elseif spellName:find("Heal") then
            return 250, "cast"
        end
    end
    
    return 200, "cast" -- Valeur par défaut
end

eventFrame:SetScript("OnEvent", function(self, event, unit, ...)
    if not playerGUID then return end
    
    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        if unit == "player" then
            local spell, _, _, _, startTime, endTime, _, castGUID, spellID
            
            if event == "UNIT_SPELLCAST_START" then
                spell, _, _, _, startTime, endTime, _, castGUID, spellID = UnitCastingInfo(unit)
            else
                spell, _, _, _, startTime, endTime, _, castGUID, spellID = UnitChannelInfo(unit)
            end
            
            if spell and spellID then
                local healAmount, healType = GetHealInfo(spellID, spell)
                
                if healAmount > 0 then
                    -- Déterminer la cible (simplifié - assume target ou player)
                    local targetUnit = "target"
                    if not UnitExists(targetUnit) or not UnitCanAssist("player", targetUnit) then
                        targetUnit = "player"
                    end
                    
                    local targetGUID = UnitGUID(targetUnit)
                    if targetGUID then
                        if not healData[targetGUID] then
                            healData[targetGUID] = {}
                        end
                        if not healData[targetGUID][playerGUID] then
                            healData[targetGUID][playerGUID] = {}
                        end
                        
                        local castID = castGUID or tostring(GetTime())
                        healData[targetGUID][playerGUID][castID] = {
                            amount = healAmount,
                            endTime = endTime and (endTime / 1000) or (GetTime() + 3),
                            type = event == "UNIT_SPELLCAST_START" and "cast" or "channel",
                            spellID = spellID
                        }
                        
                        -- Déclencher les callbacks
                        callbacks:Fire("HealComm_HealStarted", UnitName(targetUnit), UnitName("player"), healAmount)
                    end
                end
            end
        end
        
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or 
           event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        if unit == "player" then
            -- Nettoyer les heals du joueur
            for targetGUID, healers in pairs(healData) do
                if healers[playerGUID] then
                    -- Marquer tous les heals comme expirés
                    for castID, healInfo in pairs(healers[playerGUID]) do
                        healInfo.endTime = GetTime() - 1
                    end
                    callbacks:Fire("HealComm_HealStopped", "", UnitName("player"), 0)
                end
            end
        end
    end
end)

-- Timer de nettoyage
local cleanupTimer = C_Timer.NewTicker(5, function()
    CleanExpiredHeals()
end)

-- Fonctions de callback pour les addons externes
function LibHealComm:RegisterCallback(event, callback, context)
    callbacks:RegisterCallback(event, callback, context)
end

function LibHealComm:UnregisterCallback(event, callback)
    callbacks:UnregisterCallback(event, callback)
end

-- Fonctions utilitaires supplémentaires
function LibHealComm:UnitIncomingHealGet(unit, healFilter)
    local guid = UnitGUID(unit)
    return self:GetHealAmount(guid, healFilter)
end

function LibHealComm:PlayerIncomingHealGet(healFilter)
    return self:UnitIncomingHealGet("player", healFilter)
end