--[[
    HealPredictionDisplay - Init Principal COMPLET
    Initialisation de l'addon avec toutes les commandes et diagnostics
    Author: Hutshx
    Date: 2025-08-15
]]

local addonName, addonTable = ...

-- *** DÉCLARATION GLOBALE IMMÉDIATE ***
_G.HealPredictionDisplay = LibStub("AceAddon-3.0"):NewAddon("HealPredictionDisplay", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local addon = _G.HealPredictionDisplay

print("HealPredictionDisplay: === ACTIVATION ADDON ===")

-- Configuration par défaut
addon.defaults = {
    profile = {
        enabled = true,
        showSelfHeals = true,
        showOtherHeals = true,
        opacity = 0.8,
        barHeight = 16,
        testMode = false,
        debug = false
    }
}

function addon:OnInitialize()
    print("HealPredictionDisplay: Addon principal initialisé")
    
    -- Initialiser la base de données
    self.db = LibStub("AceDB-3.0"):New("HealPredictionDisplayDB", self.defaults)
    print("HealPredictionDisplay: Base de données initialisée")
end

function addon:OnEnable()
    print("HealPredictionDisplay: Addon chargé, démarrage des modules...")
    
    -- Les modules se chargeront automatiquement
    self:RegisterChatCommand("healpred", "SlashCommand")
    
    print("HealPredictionDisplay: Addon activé")
end

function addon:SlashCommand(input)
    if input == "toggle" then
        self.db.profile.enabled = not self.db.profile.enabled
        print("HealPredictionDisplay:", self.db.profile.enabled and "Activé" or "Désactivé")
    elseif input == "config" then
        print("HealPredictionDisplay: Configuration : /healpred toggle")
    else
        print("HealPredictionDisplay: Commandes disponibles :")
        print("  /healpred toggle - Activer/Désactiver")
        print("  /healpred config - Configuration")
    end
end

-- ========== COMMANDES DE TEST ==========

local testHealCache = {}
addon.testHealCache = testHealCache

SLASH_HEALPREDTEST1 = "/healpredtest"
SlashCmdList["HEALPREDTEST"] = function()
    print("HealPredictionDisplay: [🧪 TEST] === TEST HEAL JOUEUR (FINAL) ===")
    
    local guid = UnitGUID("player")
    if not guid then
        print("HealPredictionDisplay: [🧪 TEST] ❌ Pas de GUID joueur")
        return
    end
    
    local currentHP = UnitHealth("player")
    local maxHP = UnitHealthMax("player")
    local missingHP = maxHP - currentHP
    local healAmount = math.max(800, missingHP * 0.5)
    
    print("HealPredictionDisplay: [🧪 TEST] GUID joueur:", guid)
    print("HealPredictionDisplay: [🧪 TEST] ✅ Heal test créé:", healAmount, "HP (HP manquants:", missingHP .. ")")
    
    testHealCache[guid] = {
        total = healAmount,
        self = healAmount,
        lastUpdate = GetTime(),
        source = "test_final"
    }
    
    if addon.unitFrameDisplay and addon.unitFrameDisplay.UpdateUnitFrame then
        addon.unitFrameDisplay:UpdateUnitFrame(guid)
    end
    
    -- Auto-supprimer après 5 secondes
    if addon.ScheduleTimer then
        addon:ScheduleTimer(function()
            testHealCache[guid] = nil
            if addon.unitFrameDisplay and addon.unitFrameDisplay.UpdateUnitFrame then
                addon.unitFrameDisplay:UpdateUnitFrame(guid)
            end
            print("HealPredictionDisplay: [🧪 TEST] Test expiré")
        end, 5)
    end
end

SLASH_HEALPREDTESTTARGET1 = "/healpredtesttarget"
SlashCmdList["HEALPREDTESTTARGET"] = function()
    if not UnitExists("target") then
        print("HealPredictionDisplay: [🧪 TEST] ❌ Aucune cible sélectionnée")
        return
    end
    
    local guid = UnitGUID("target")
    local name = UnitName("target")
    
    if not guid then
        print("HealPredictionDisplay: [🧪 TEST] ❌ Pas de GUID pour la cible")
        return
    end
    
    print("HealPredictionDisplay: [🧪 TEST] === TEST HEAL CIBLE ===")
    print("HealPredictionDisplay: [🧪 TEST] Cible:", name, "GUID:", guid)
    
    local healAmount = 1200
    testHealCache[guid] = {
        total = healAmount,
        self = 0,
        lastUpdate = GetTime(),
        source = "test_target"
    }
    
    print("HealPredictionDisplay: [🧪 TEST] ✅ Heal test créé pour", name, "Amount:", healAmount)
    
    if addon.unitFrameDisplay and addon.unitFrameDisplay.UpdateUnitFrame then
        addon.unitFrameDisplay:UpdateUnitFrame(guid)
    end
    
    -- Auto-supprimer après 5 secondes
    if addon.ScheduleTimer then
        addon:ScheduleTimer(function()
            testHealCache[guid] = nil
            if addon.unitFrameDisplay and addon.unitFrameDisplay.UpdateUnitFrame then
                addon.unitFrameDisplay:UpdateUnitFrame(guid)
            end
            print("HealPredictionDisplay: [🧪 TEST] Test cible expiré")
        end, 5)
    end
end

-- ========== COMMANDES SYSTÈME EN TEMPS RÉEL ==========

SLASH_HEALPREDLIVEON1 = "/healpredliveon"
SlashCmdList["HEALPREDLIVEON"] = function()
    print("HealPredictionDisplay: [🔥 LIVE] === ACTIVATION SYSTÈME RÉEL ===")
    
    local healPredModule = addon:GetModule("HealPrediction", true)
    if healPredModule then
        healPredModule:StartCombatLogTracking()
        print("HealPredictionDisplay: [🔥 LIVE] ✅ Système réel activé")
        print("HealPredictionDisplay: [🔥 LIVE] Les heals en cours seront détectés automatiquement")
    else
        print("HealPredictionDisplay: [🔥 LIVE] ❌ Module HealPrediction non trouvé")
    end
end

SLASH_HEALPREDLIVEOFF1 = "/healpredliveoff"
SlashCmdList["HEALPREDLIVEOFF"] = function()
    print("HealPredictionDisplay: [🔥 LIVE] === DÉSACTIVATION SYSTÈME RÉEL ===")
    
    local healPredModule = addon:GetModule("HealPrediction", true)
    if healPredModule then
        healPredModule:StopCombatLogTracking()
        print("HealPredictionDisplay: [🔥 LIVE] ✅ Système réel désactivé")
    else
        print("HealPredictionDisplay: [🔥 LIVE] ❌ Module HealPrediction non trouvé")
    end
end

-- ========== COMMANDES DEBUG AVANCÉES ==========

SLASH_HEALPREDFLASH1 = "/healpredflash"
SlashCmdList["HEALPREDFLASH"] = function()
    print("HealPredictionDisplay: [⚡ FLASH] Clignotement des barres...")
    
    if addon.unitFrameDisplay and addon.unitFrameDisplay.FlashBars then
        addon.unitFrameDisplay:FlashBars()
    else
        print("HealPredictionDisplay: [⚡ FLASH] ❌ UnitFrameDisplay non disponible")
    end
end

SLASH_HEALPREDFORCE1 = "/healpredforce"
SlashCmdList["HEALPREDFORCE"] = function()
    print("HealPredictionDisplay: [🔥 FORCE] Affichage forcé de toutes les barres...")
    
    if addon.unitFrameDisplay and addon.unitFrameDisplay.ForceVisibleTest then
        addon.unitFrameDisplay:ForceVisibleTest()
    else
        print("HealPredictionDisplay: [🔥 FORCE] ❌ UnitFrameDisplay non disponible")
    end
end

SLASH_HEALPREDREFRESH1 = "/healpredrefresh"
SlashCmdList["HEALPREDREFRESH"] = function()
    print("HealPredictionDisplay: [🔄 REFRESH] Rafraîchissement complet...")
    
    if addon.unitFrameDisplay and addon.unitFrameDisplay.RefreshAllBars then
        addon.unitFrameDisplay:RefreshAllBars()
        print("HealPredictionDisplay: [🔄 REFRESH] ✅ Rafraîchissement terminé")
    else
        print("HealPredictionDisplay: [🔄 REFRESH] ❌ UnitFrameDisplay non disponible")
    end
end

-- ========== DIAGNOSTIC SYSTÈME ==========

SLASH_HEALPREDDIAGCAST1 = "/healpreddiagcast"
SlashCmdList["HEALPREDDIAGCAST"] = function()
    print("HealPredictionDisplay: [🔍 DIAG] === DIAGNOSTIC CAST EVENTS ===")
    
    local addon = _G.HealPredictionDisplay
    if not addon then
        print("HealPredictionDisplay: [🔍 DIAG] ❌ Addon non trouvé")
        return
    end
    
    local healPred = addon:GetModule("HealPrediction", true)
    if not healPred then
        print("HealPredictionDisplay: [🔍 DIAG] ❌ Module HealPrediction non trouvé")
        return
    end
    
    print("HealPredictionDisplay: [🔍 DIAG] === ÉTAT SYSTÈME ===")
    print("HealPredictionDisplay: [🔍 DIAG] Combat Log actif:", healPred:IsCombatLogActive())
    
    local watchedUnits = healPred:GetWatchedUnits()
    print("HealPredictionDisplay: [🔍 DIAG] Unités surveillées:", healPred:CountTable(watchedUnits))
    for unit, guid in pairs(watchedUnits) do
        local name = UnitName(unit) or "Unknown"
        print("HealPredictionDisplay: [🔍 DIAG]   -", unit, "->", name, "GUID:", guid)
    end
    
    local guidMappings = healPred:GetGUIDMappings()
    print("HealPredictionDisplay: [🔍 DIAG] Mappings GUID:", healPred:CountTable(guidMappings))
    for guid, unit in pairs(guidMappings) do
        local name = UnitName(unit) or "Unknown"
        print("HealPredictionDisplay: [🔍 DIAG]   -", guid, "->", unit, "(" .. name .. ")")
    end
    
    local activeCasts = healPred:GetActiveCasts()
    print("HealPredictionDisplay: [🔍 DIAG] Casts actifs:", healPred:CountTable(activeCasts))
    for castKey, castData in pairs(activeCasts) do
        print("HealPredictionDisplay: [🔍 DIAG]   -", castKey, "Caster:", castData.casterName, "Target:", castData.targetName, "Amount:", castData.healAmount)
    end
    
    print("HealPredictionDisplay: [🔍 DIAG] === TEST ÉVÉNEMENTS ===")
    print("HealPredictionDisplay: [🔍 DIAG] Demandez à quelqu'un de vous healer maintenant...")
end

-- *** ACTIVATION FORCE BRUTE ***

SLASH_HEALPREDFORCESTART1 = "/healpredforcestart"
SlashCmdList["HEALPREDFORCESTART"] = function()
    print("HealPredictionDisplay: [🚀 FORCE] === ACTIVATION FORCE BRUTE ===")
    
    local addon = _G.HealPredictionDisplay
    if not addon then
        print("HealPredictionDisplay: [🚀 FORCE] ❌ Addon non trouvé")
        return
    end
    
    local healPred = addon:GetModule("HealPrediction", true)
    if not healPred then
        print("HealPredictionDisplay: [🚀 FORCE] ❌ Module HealPrediction non trouvé")
        return
    end
    
    -- Forcer l'arrêt puis redémarrage
    print("HealPredictionDisplay: [🚀 FORCE] Arrêt forcé...")
    healPred:StopCombatLogTracking()
    
    -- Attendre un peu
    C_Timer.NewTimer(1, function()
        print("HealPredictionDisplay: [🚀 FORCE] Redémarrage forcé...")
        
        -- Remettre à jour tout
        healPred:UpdateAllUnitGUIDs()
        healPred:BuildWatchedUnitsList()
        
        -- Redémarrer le Combat Log
        healPred:StartCombatLogTracking()
        
        print("HealPredictionDisplay: [🚀 FORCE] ✅ Système redémarré avec force brute")
        print("HealPredictionDisplay: [🚀 FORCE] Demandez maintenant à quelqu'un de vous healer !")
    end)
end

-- *** TEST SIMPLE *** : Heal immédiat sur le joueur

SLASH_HEALPREDQUICKTEST1 = "/healpredquicktest"
SlashCmdList["HEALPREDQUICKTEST"] = function()
    print("HealPredictionDisplay: [⚡ QUICK] === TEST RAPIDE ===")
    
    local addon = _G.HealPredictionDisplay
    if not addon then
        print("HealPredictionDisplay: [⚡ QUICK] ❌ Addon non trouvé")
        return
    end
    
    local guid = UnitGUID("player")
    if not guid then
        print("HealPredictionDisplay: [⚡ QUICK] ❌ Pas de GUID joueur")
        return
    end
    
    print("HealPredictionDisplay: [⚡ QUICK] GUID joueur:", guid)
    print("HealPredictionDisplay: [⚡ QUICK] HP actuels:", UnitHealth("player") .. "/" .. UnitHealthMax("player"))
    
    -- *** CRÉER CACHE TEST IMMÉDIATEMENT ***
    addon.testHealCache = addon.testHealCache or {}
    
    addon.testHealCache[guid] = {
        total = 2000,  -- Gros heal visible
        self = 2000,
        lastUpdate = GetTime(),
        source = "quick_test"
    }
    
    print("HealPredictionDisplay: [⚡ QUICK] ✅ Cache test créé - Total: 2000 HP")
    print("HealPredictionDisplay: [⚡ QUICK] Cache:", addon.testHealCache[guid])
    
    -- *** FORCER MISE À JOUR ***
    if addon.unitFrameDisplay then
        print("HealPredictionDisplay: [⚡ QUICK] unitFrameDisplay trouvé")
        
        if addon.unitFrameDisplay.UpdateUnitFrame then
            print("HealPredictionDisplay: [⚡ QUICK] 🚀 FORÇAGE UpdateUnitFrame...")
            addon.unitFrameDisplay:UpdateUnitFrame(guid)
        else
            print("HealPredictionDisplay: [⚡ QUICK] ❌ UpdateUnitFrame manquant")
        end
    else
        print("HealPredictionDisplay: [⚡ QUICK] ❌ unitFrameDisplay manquant")
    end
    
    -- Auto-supprimer après 3 secondes
    if addon.ScheduleTimer then
        addon:ScheduleTimer(function()
            if addon.testHealCache and addon.testHealCache[guid] then
                addon.testHealCache[guid] = nil
                addon.unitFrameDisplay:UpdateUnitFrame(guid)
                print("HealPredictionDisplay: [⚡ QUICK] Test expiré")
            end
        end, 3)
    end
end

-- *** DIAGNOSTIC COMPLET ***

SLASH_HEALPREDDIAG1 = "/healpreddiag"
SlashCmdList["HEALPREDDIAG"] = function()
    print("HealPredictionDisplay: [🔍 DIAG] === DIAGNOSTIC COMPLET ===")
    
    local addon = _G.HealPredictionDisplay
    
    print("HealPredictionDisplay: [🔍 DIAG] 1. Addon global:", addon and "✅" or "❌")
    
    if addon then
        print("HealPredictionDisplay: [🔍 DIAG] 2. Modules:")
        local healPred = addon:GetModule("HealPrediction", true)
        print("  - HealPrediction:", healPred and "✅" or "❌")
        print("  - unitFrameDisplay:", addon.unitFrameDisplay and "✅" or "❌")
        
        print("HealPredictionDisplay: [🔍 DIAG] 3. Cache test:")
        if addon.testHealCache then
            local count = 0
            for guid, data in pairs(addon.testHealCache) do
                count = count + 1
                print("  -", guid, "Total:", data.total)
            end
            print("  Total entrées:", count)
        else
            print("  ❌ Cache test inexistant")
        end
        
        print("HealPredictionDisplay: [🔍 DIAG] 4. État HealPrediction:")
        if healPred then
            local activeCasts = healPred:GetActiveCasts()
            local watchedUnits = healPred:GetWatchedUnits()
            local isActive = healPred:IsCombatLogActive()
            
            print("  - Combat Log actif:", isActive and "✅" or "❌")
            print("  - Casts actifs:", activeCasts and healPred:CountTable(activeCasts) or 0)
            print("  - Unités surveillées:", watchedUnits and healPred:CountTable(watchedUnits) or 0)
            
            if watchedUnits then
                for unit, guid in pairs(watchedUnits) do
                    local name = UnitName(unit) or "Unknown"
                    print("    *", unit, "->", name, guid)
                end
            end
        end
        
        print("HealPredictionDisplay: [🔍 DIAG] 5. État UnitFrameDisplay:")
        if addon.unitFrameDisplay then
            local healBars = _G.HealPredictionDisplay_HealBars
            if healBars then
                local count = 0
                for unit, _ in pairs(healBars) do
                    count = count + 1
                    print("  - Barre:", unit)
                end
                print("  Total barres:", count)
            else
                print("  ❌ Aucune barre trouvée")
            end
        end
    end
    
    print("HealPredictionDisplay: [🔍 DIAG] === FIN DIAGNOSTIC ===")
end

print("HealPredictionDisplay: Commandes finales ajoutées")
print("HealPredictionDisplay: Commandes de diagnostic avancées ajoutées")