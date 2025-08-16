--[[
    HealPredictionDisplay - SYSTÈME HYBRIDE
    Unit Events pour CAST_START + Combat Log pour nettoyage
    Author: Hutshx
    Date: 2025-08-15
]]

local addon = _G.HealPredictionDisplay
local HealPrediction = addon:NewModule("HealPrediction", "AceEvent-3.0")

-- Variables principales
local healCache = {}
local activeCasts = {}
local playerGUID
local frame = CreateFrame("Frame")

-- Mapping GUID/Unit
local GUID_TO_UNIT = {}
local UNIT_TO_GUID = {}

function HealPrediction:OnEnable()
    print("HealPredictionDisplay: [🔀 HYBRID] === SYSTÈME HYBRIDE ===")
    print("HealPredictionDisplay: [🔀 HYBRID] Unit Events pour START + Combat Log pour nettoyage")
    
    playerGUID = UnitGUID("player")
    print("HealPredictionDisplay: [🔀 HYBRID] Player GUID:", playerGUID)
    
    self:StartHybridDetection()
end

function HealPrediction:StartHybridDetection()
    print("HealPredictionDisplay: [🔀 HYBRID] 🚀 Démarrage détection hybride")
    
    -- Mapping initial
    self:UpdateAllUnitGUIDs()
    
    -- *** UNIT EVENTS pour détecter les CASTS ***
    self:RegisterEvent("UNIT_SPELLCAST_START", "OnUnitCastStart")
    self:RegisterEvent("UNIT_SPELLCAST_STOP", "OnUnitCastStop")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnUnitCastSucceeded")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "OnUnitCastInterrupted")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED", "OnUnitCastFailed")
    
    -- *** COMBAT LOG pour nettoyage et validation ***
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            HealPrediction:OnCombatLogCleanup(...)
        end
    end)
    
    -- Events de mapping
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAllUnitGUIDs")
    self:RegisterEvent("PARTY_MEMBERS_CHANGED", "UpdateAllUnitGUIDs")
    self:RegisterEvent("RAID_ROSTER_UPDATE", "UpdateAllUnitGUIDs")
    self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnTargetChanged")
    self:RegisterEvent("PLAYER_FOCUS_CHANGED", "OnFocusChanged")
    
    -- Timer de nettoyage auto
    C_Timer.NewTicker(2, function()
        self:CleanupExpiredCasts()
    end)
    
    -- Timer de debug
    C_Timer.NewTicker(15, function()
        print("HealPredictionDisplay: [🔀 HYBRID] 📊 STATUT:")
        print("  - Unités trackées:", self:CountTable(GUID_TO_UNIT))
        print("  - Active casts:", self:CountTable(activeCasts))
        print("  - Heal cache:", self:CountTable(healCache))
        
        -- Debug des casts actifs
        for castKey, castData in pairs(activeCasts) do
            local timeLeft = castData.endTime - GetTime()
            print("  - Cast actif:", castData.casterName, "->", castData.targetName, 
                  castData.spellName, "(" .. math.max(0, timeLeft) .. "s restant)")
        end
    end)
    
    print("HealPredictionDisplay: [🔀 HYBRID] ✅ Système hybride activé")
end

-- *** UNIT EVENTS - DÉTECTION DES CASTS ***

function HealPrediction:OnUnitCastStart(event, unit)
    if not unit or not UnitExists(unit) then return end
    
    local spell, rank = UnitCastingInfo(unit)
    if not spell or not self:IsHealSpell(spell) then return end
    
    local casterGUID = UnitGUID(unit)
    local casterName = UnitName(unit)
    
    print("HealPredictionDisplay: [🔀 HYBRID] 🚀 UNIT CAST START:")
    print("  - Unit:", unit, "Caster:", casterName)
    print("  - Spell:", spell, "Rank:", rank)
    print("  - Caster GUID:", casterGUID)
    
    -- Détecter la cible
    local targetGUID, targetName = self:DetectCastTarget(unit, casterGUID, spell)
    
    if targetGUID then
        print("HealPredictionDisplay: [🔀 HYBRID] ✅ Target détectée:", targetName, "GUID:", targetGUID)
        self:RegisterHealCast(casterGUID, casterName, targetGUID, targetName, spell, "unit_event")
    else
        print("HealPredictionDisplay: [🔀 HYBRID] ❌ Impossible de détecter la target")
    end
end

function HealPrediction:OnUnitCastStop(event, unit)
    self:HandleCastEnd(unit, "stopped")
end

function HealPrediction:OnUnitCastSucceeded(event, unit)
    self:HandleCastEnd(unit, "succeeded")
end

function HealPrediction:OnUnitCastInterrupted(event, unit)
    self:HandleCastEnd(unit, "interrupted")
end

function HealPrediction:OnUnitCastFailed(event, unit)
    self:HandleCastEnd(unit, "failed")
end

function HealPrediction:HandleCastEnd(unit, reason)
    if not unit or not UnitExists(unit) then return end
    
    local casterGUID = UnitGUID(unit)
    local casterName = UnitName(unit)
    
    if casterGUID then
        print("HealPredictionDisplay: [🔀 HYBRID] 🛑 UNIT CAST END:", casterName, "(" .. reason .. ")")
        self:UnregisterCasterCasts(casterGUID)
    end
end

-- *** COMBAT LOG - NETTOYAGE ET VALIDATION ***

function HealPrediction:OnCombatLogCleanup(
    timeStamp, subEvent,
    sourceGUID, sourceName, sourceFlags,
    destGUID, destName, destFlags,
    spellID, spellName, spellSchool, ...)
    
    -- Uniquement pour les heals
    if not spellName or not self:IsHealSpell(spellName) then return end
    
    -- Log uniquement les événements importants
    if subEvent == "SPELL_HEAL" then
        local amount = ...
        print("HealPredictionDisplay: [🔀 HYBRID] 💚 Combat Log - HEAL LANDED:")
        print("  - Spell:", spellName, "Amount:", amount)
        print("  - Source:", sourceName, "Dest:", destName)
        
        -- Nettoyer le cast correspondant
        if sourceGUID and destGUID then
            self:UnregisterSpecificCast(sourceGUID, destGUID, spellName)
        end
        
    elseif subEvent == "SPELL_CAST_FAILED" or subEvent == "SPELL_INTERRUPT" then
        print("HealPredictionDisplay: [🔀 HYBRID] ❌ Combat Log - CAST FAILED/INTERRUPTED:")
        print("  - Spell:", spellName, "Source:", sourceName)
        
        if sourceGUID then
            self:UnregisterCasterCasts(sourceGUID)
        end
    end
end

-- *** DÉTECTION DE CIBLE INTELLIGENTE ***

function HealPrediction:DetectCastTarget(casterUnit, casterGUID, spellName)
    print("HealPredictionDisplay: [🔀 HYBRID] 🎯 Détection de cible pour:", casterUnit, spellName)
    
    -- 1. Si c'est le joueur
    if casterGUID == playerGUID then
        print("HealPredictionDisplay: [🔀 HYBRID] 👤 Caster = Player")
        
        if UnitExists("target") and UnitIsFriend("player", "target") then
            local targetGUID = UnitGUID("target")
            local targetName = UnitName("target")
            print("HealPredictionDisplay: [🔀 HYBRID] ✅ Target du player:", targetName)
            return targetGUID, targetName
        else
            print("HealPredictionDisplay: [🔀 HYBRID] ✅ Auto-cast sur player")
            return playerGUID, UnitName("player")
        end
    end
    
    -- 2. Target du caster
    local targetUnit = casterUnit .. "target"
    if UnitExists(targetUnit) then
        local targetGUID = UnitGUID(targetUnit)
        local targetName = UnitName(targetUnit)
        print("HealPredictionDisplay: [🔀 HYBRID] ✅ Target du caster:", targetName)
        return targetGUID, targetName
    end
    
    -- 3. Si pas de target, chercher le membre le plus blessé
    print("HealPredictionDisplay: [🔀 HYBRID] 🔍 Recherche membre le plus blessé")
    return self:FindMostWoundedMember()
end

function HealPredictionDisplay:FindMostWoundedMember()
    local mostWounded = nil
    local lowestHP = 1
    
    -- Chercher dans toutes les unités connues
    local candidates = {"player"}
    
    -- Ajouter groupe/raid
    if UnitInRaid("player") then
        for i = 1, GetNumRaidMembers() do
            table.insert(candidates, "raid" .. i)
        end
    elseif UnitInParty("player") then
        for i = 1, GetNumPartyMembers() do
            table.insert(candidates, "party" .. i)
        end
    end
    
    -- Ajouter target/focus si friendly
    if UnitExists("target") and UnitIsFriend("player", "target") then
        table.insert(candidates, "target")
    end
    
    if UnitExists("focus") and UnitIsFriend("player", "focus") then
        table.insert(candidates, "focus")
    end
    
    for _, unit in ipairs(candidates) do
        if UnitExists(unit) then
            local current = UnitHealth(unit)
            local max = UnitHealthMax(unit)
            
            if max > 0 then
                local percent = current / max
                if percent < lowestHP then
                    lowestHP = percent
                    mostWounded = {UnitGUID(unit), UnitName(unit)}
                end
            end
        end
    end
    
    if mostWounded then
        print("HealPredictionDisplay: [🔀 HYBRID] ✅ Plus blessé:", mostWounded[2], "(" .. math.floor(lowestHP * 100) .. "%)")
        return mostWounded[1], mostWounded[2]
    end
    
    print("HealPredictionDisplay: [🔀 HYBRID] ⚠️ Fallback sur player")
    return playerGUID, UnitName("player")
end

-- *** GESTION DES CASTS ***

function HealPrediction:RegisterHealCast(casterGUID, casterName, targetGUID, targetName, spellName, source)
    local currentTime = GetTime()
    local healAmount = self:EstimateHealAmount(spellName)
    local castTime = self:EstimateCastTime(spellName)
    
    -- Clé unique avec timestamp pour éviter les doublons
    local castKey = casterGUID .. ":" .. targetGUID .. ":" .. spellName .. ":" .. math.floor(currentTime * 1000)
    
    activeCasts[castKey] = {
        casterGUID = casterGUID,
        casterName = casterName,
        targetGUID = targetGUID,
        targetName = targetName,
        spellName = spellName,
        healAmount = healAmount,
        startTime = currentTime,
        endTime = currentTime + castTime,
        source = source
    }
    
    print("HealPredictionDisplay: [🔀 HYBRID] ✅ HEAL ENREGISTRÉ:")
    print("  - Cast key:", castKey)
    print("  - " .. casterName .. " -> " .. targetName)
    print("  - " .. spellName .. " (" .. healAmount .. " HP, " .. castTime .. "s)")
    print("  - Source:", source)
    
    self:UpdateHealCache()
end

function HealPrediction:UnregisterCasterCasts(casterGUID)
    local removed = 0
    local castsToRemove = {}
    
    for castKey, castData in pairs(activeCasts) do
        if castData.casterGUID == casterGUID then
            table.insert(castsToRemove, castKey)
        end
    end
    
    for _, castKey in ipairs(castsToRemove) do
        activeCasts[castKey] = nil
        removed = removed + 1
    end
    
    if removed > 0 then
        print("HealPredictionDisplay: [🔀 HYBRID] ❌", removed, "cast(s) du caster supprimé(s)")
        self:UpdateHealCache()
    end
end

function HealPrediction:UnregisterSpecificCast(casterGUID, targetGUID, spellName)
    local removed = 0
    local castsToRemove = {}
    
    for castKey, castData in pairs(activeCasts) do
        if castData.casterGUID == casterGUID and
           castData.targetGUID == targetGUID and
           castData.spellName == spellName then
            table.insert(castsToRemove, castKey)
        end
    end
    
    for _, castKey in ipairs(castsToRemove) do
        activeCasts[castKey] = nil
        removed = removed + 1
    end
    
    if removed > 0 then
        print("HealPredictionDisplay: [🔀 HYBRID] ❌ Cast spécifique supprimé:", spellName, "(" .. removed .. ")")
        self:UpdateHealCache()
    end
end

function HealPrediction:CleanupExpiredCasts()
    local currentTime = GetTime()
    local castsToRemove = {}
    
    for castKey, castData in pairs(activeCasts) do
        if castData.endTime <= currentTime then
            table.insert(castsToRemove, castKey)
        end
    end
    
    if #castsToRemove > 0 then
        print("HealPredictionDisplay: [🔀 HYBRID] 🧹 Nettoyage auto:", #castsToRemove, "casts expirés")
        for _, castKey in ipairs(castsToRemove) do
            activeCasts[castKey] = nil
        end
        self:UpdateHealCache()
    end
end

function HealPrediction:UpdateHealCache()
    local currentTime = GetTime()
    local guidTotals = {}
    
    -- Calculer totaux pour casts actifs
    for castKey, castData in pairs(activeCasts) do
        if castData.endTime > currentTime then
            local targetGUID = castData.targetGUID
            if targetGUID then
                guidTotals[targetGUID] = (guidTotals[targetGUID] or 0) + castData.healAmount
            end
        end
    end
    
    -- Mettre à jour le cache
    for guid, total in pairs(guidTotals) do
        healCache[guid] = {
            total = total,
            self = (guid == playerGUID) and total or 0,
            others = (guid == playerGUID) and 0 or total,
            lastUpdate = currentTime,
            source = "hybrid"
        }
        
        self:TriggerDisplayUpdate(guid)
    end
    
    -- Nettoyer cache
    for guid, _ in pairs(healCache) do
        if not guidTotals[guid] then
            healCache[guid] = nil
            self:TriggerDisplayUpdate(guid)
        end
    end
end

-- *** MAPPING GUID/UNIT ***

function HealPrediction:UpdateAllUnitGUIDs()
    print("HealPredictionDisplay: [🔀 HYBRID] 🔄 Mise à jour mapping")
    
    wipe(GUID_TO_UNIT)
    wipe(UNIT_TO_GUID)
    
    local units = {"player", "target", "focus", "pet"}
    
    if UnitInRaid("player") then
        for i = 1, GetNumRaidMembers() do
            table.insert(units, "raid" .. i)
        end
    elseif UnitInParty("player") then
        for i = 1, GetNumPartyMembers() do
            table.insert(units, "party" .. i)
        end
    end
    
    for _, unit in ipairs(units) do
        if UnitExists(unit) then
            local guid = UnitGUID(unit)
            if guid then
                GUID_TO_UNIT[guid] = unit
                UNIT_TO_GUID[unit] = guid
            end
        end
    end
    
    print("HealPredictionDisplay: [🔀 HYBRID] ✅ Mapping:", self:CountTable(GUID_TO_UNIT), "unités")
end

function HealPrediction:OnTargetChanged()
    self:UpdateUnitGUID("target")
end

function HealPrediction:OnFocusChanged()
    self:UpdateUnitGUID("focus")
end

function HealPrediction:UpdateUnitGUID(unit)
    if UnitExists(unit) then
        local guid = UnitGUID(unit)
        if guid then
            GUID_TO_UNIT[guid] = unit
            UNIT_TO_GUID[unit] = guid
        end
    end
end

-- *** UTILITAIRES ***

function HealPrediction:IsHealSpell(spellName)
    local heals = {
        "Lesser Heal", "Heal", "Greater Heal", "Flash Heal", "Renew", "Prayer of Healing",
        "Binding Heal", "Power Word: Shield", "Holy Light", "Flash of Light", "Holy Shock",
        "Healing Touch", "Regrowth", "Rejuvenation", "Lifebloom", "Wild Growth", "Nourish",
        "Healing Wave", "Lesser Healing Wave", "Chain Heal", "Riptide"
    }
    
    for _, heal in ipairs(heals) do
        if heal == spellName then return true end
    end
    return false
end

function HealPrediction:EstimateHealAmount(spellName)
    local amounts = {
        ["Lesser Heal"] = 100, ["Heal"] = 200, ["Greater Heal"] = 1200, 
        ["Flash Heal"] = 600, ["Holy Light"] = 1100, ["Flash of Light"] = 500, 
        ["Healing Touch"] = 1000, ["Healing Wave"] = 900, ["Lesser Healing Wave"] = 550,
        ["Renew"] = 300, ["Rejuvenation"] = 250, ["Power Word: Shield"] = 800
    }
    return amounts[spellName] or 800
end

function HealPrediction:EstimateCastTime(spellName)
    local times = {
        ["Lesser Heal"] = 1.5, ["Heal"] = 2.5, ["Greater Heal"] = 3.0, 
        ["Flash Heal"] = 1.5, ["Holy Light"] = 2.5, ["Flash of Light"] = 1.5,
        ["Healing Touch"] = 3.0, ["Healing Wave"] = 3.0, ["Lesser Healing Wave"] = 1.5,
        ["Renew"] = 0, ["Rejuvenation"] = 0, ["Power Word: Shield"] = 0
    }
    return times[spellName] or 2.5
end

function HealPrediction:TriggerDisplayUpdate(guid)
    if addon and addon.unitFrameDisplay and addon.unitFrameDisplay.UpdateUnitFrame then
        addon.unitFrameDisplay:UpdateUnitFrame(guid)
    end
end

function HealPrediction:CountTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- *** API PUBLIQUE ***

function HealPrediction:GetHealData(guid)
    return healCache[guid]
end

function HealPrediction:GetActiveCasts()
    return activeCasts
end

print("HealPredictionDisplay: Système HYBRIDE chargé - Unit Events + Combat Log !")