--[[
	HealPredictionDisplay - Addon principal
	Système d'affichage des prédictions de heal pour WoW Ascension
]]

local ADDON_NAME, HPD = ...

-- Namespace global
HealPredictionDisplay = LibStub("AceAddon-3.0"):NewAddon("HealPredictionDisplay", "AceEvent-3.0", "AceTimer-3.0")
local addon = HealPredictionDisplay

-- Variables globales
addon.version = "1.0"
addon.name = ADDON_NAME
addon.namespace = HPD

-- Base de données par défaut
local defaults = {
    profile = {
        enabled = true,
        showMyHeals = true,
        showOtherHeals = true,
        myHealColor = {r = 0.0, g = 0.827, b = 0.765, a = 0.8},
        otherHealColor = {r = 0.0, g = 0.631, b = 0.557, a = 0.8},
        maxOverflow = 1.05,
        updateRate = 0.1,
        units = {
            player = true,
            target = true,
            focus = true,
            pet = true,
            party = true,
            raid = true,
        }
    }
}

-- Initialisation
function addon:OnInitialize()
    -- Initialiser la base de données
    self.db = LibStub("AceDB-3.0"):New("HealPredictionDisplayDB", defaults, true)
    
    -- Variables locales
    self.frames = {}
    self.updateTimer = nil
    
    print("|cff1784d1HealPredictionDisplay|r v" .. self.version .. " chargé!")
end

function addon:OnEnable()
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("UNIT_HEALTH")
    
    -- Vérifier les dépendances
    self:CheckDependencies()
    
    -- Démarrer les mises à jour
    self:StartUpdateTimer()
end

function addon:OnDisable()
    self:StopUpdateTimer()
end

-- Vérification des dépendances
function addon:CheckDependencies()
    -- Vérifier HealPredict
    if not HealPredict then
        print("|cffff0000Erreur:|r HealPredict library non trouvée!")
        return false
    end
    
    -- Vérifier oUF si ElvUI est présent
    if ElvUI and not oUF then
        print("|cffffff00Attention:|r oUF non trouvé avec ElvUI!")
    end
    
    return true
end

-- Timer de mise à jour
function addon:StartUpdateTimer()
    if self.updateTimer then
        self:CancelTimer(self.updateTimer)
    end
    
    self.updateTimer = self:ScheduleRepeatingTimer("UpdateAllFrames", self.db.profile.updateRate)
end

function addon:StopUpdateTimer()
    if self.updateTimer then
        self:CancelTimer(self.updateTimer)
        self.updateTimer = nil
    end
end

-- Mise à jour de tous les frames
function addon:UpdateAllFrames()
    if not self.db.profile.enabled then return end
    
    for frame, _ in pairs(self.frames) do
        if frame:IsVisible() and frame.unit then
            self:UpdateHealPrediction(frame)
        end
    end
end

-- Events
function addon:ADDON_LOADED(event, addonName)
    if addonName == ADDON_NAME then
        self:InitializeFrames()
    end
end

function addon:PLAYER_LOGIN()
    self:RegisterHealPredictionCallbacks()
    self:ScanForFrames()
end

function addon:GROUP_ROSTER_UPDATE()
    self:ScheduleTimer("ScanForFrames", 1)
end

function addon:UNIT_HEALTH(event, unit)
    local frame = self:GetUnitFrame(unit)
    if frame then
        self:UpdateHealPrediction(frame)
    end
end