--[[
    UnitFrameDisplay - VERSION FIX ANCRAGE DYNAMIQUE + TARGET/FOCUS
    Fix de l'ancrage pour combler le vide de HP + détection target/focus
    Author: Hutshx
    Date: 2025-08-15
]]

-- *** FIX *** : Récupérer l'addon via la variable globale
local addon = _G.HealPredictionDisplay
if not addon then
    print("HealPredictionDisplay UnitFrameDisplay: ❌ Addon global non trouvé - attente...")
    local waitTimer
    waitTimer = C_Timer.NewTimer(1, function()
        addon = _G.HealPredictionDisplay
        if addon then
            print("HealPredictionDisplay UnitFrameDisplay: ✅ Addon global trouvé après attente")
        else
            print("HealPredictionDisplay UnitFrameDisplay: ❌ Addon global toujours introuvable")
        end
    end)
    addon = addon or {}
end

local UnitFrameDisplay = {}
UnitFrameDisplay.__index = UnitFrameDisplay

local healBars = {}

function UnitFrameDisplay:new()
    local obj = setmetatable({}, UnitFrameDisplay)
    return obj
end

function UnitFrameDisplay:Initialize()
    print("HealPredictionDisplay: [🚀 INIT] UnitFrameDisplay Initialize appelé")
    self:ScanAllFrames()
    print("HealPredictionDisplay: UnitFrameDisplay activé avec support étendu")
end

-- ========== SCAN AMÉLIORÉ AVEC DÉTECTION FORCÉE ==========

function UnitFrameDisplay:ScanAllFrames()
    print("HealPredictionDisplay: [🔍 SCAN] === SCAN COMPLET AVEC DÉTECTION FORCÉE ===")
    
    local scannedCount = 0
    
    scannedCount = scannedCount + self:ScanPlayerFrame()
    scannedCount = scannedCount + self:ScanTargetFrame()
    scannedCount = scannedCount + self:ScanFocusFrame()
    scannedCount = scannedCount + self:ScanPetFrame()
    scannedCount = scannedCount + self:ScanCompactRaidFrames()
    
    print("HealPredictionDisplay: [🔍 SCAN] Total barres créées:", scannedCount)
    print("HealPredictionDisplay: [🔍 SCAN] Total barres finales:", self:CountTable(healBars))
    
    -- *** LISTE DÉTAILLÉE ***
    print("HealPredictionDisplay: [🔍 SCAN] === BARRES DÉTAILLÉES ===")
    for barKey, barData in pairs(healBars) do
        local parentName = "Unknown"
        if barData.healthBar and barData.healthBar:GetParent() then
            parentName = barData.healthBar:GetParent():GetName() or "Anonymous"
        end
        print("HealPredictionDisplay: [🔍 SCAN] *", barKey, "- Unit:", barData.unit, "Type:", barData.frameType, "Parent:", parentName)
    end
end

function UnitFrameDisplay:ScanPlayerFrame()
    local count = 0
    
    if PlayerFrame and PlayerFrameHealthBar then
        print("HealPredictionDisplay: [🔍 PLAYER] PlayerFrame détectée - Visible:", PlayerFrame:IsVisible())
        print("HealPredictionDisplay: [🔍 PLAYER] HealthBar:", PlayerFrameHealthBar:GetName())
        
        local healBar = self:CreateHealBar(PlayerFrameHealthBar, "BlizzardParty", "PlayerFrame")
        if healBar then
            healBars["player_blizzard"] = {
                healBar = healBar,
                healthBar = PlayerFrameHealthBar,
                unit = "player",
                frameType = "BlizzardParty",
                parentFrame = PlayerFrame
            }
            print("HealPredictionDisplay: [🔍 PLAYER] ✅ Barre créée pour player_blizzard")
            count = 1
        end
    else
        print("HealPredictionDisplay: [🔍 PLAYER] ❌ PlayerFrame ou HealthBar manquant")
    end
    
    return count
end

function UnitFrameDisplay:ScanTargetFrame()
    local count = 0
    
    -- *** FIX TARGET *** : Détecter même si pas visible
    if TargetFrame and TargetFrameHealthBar then
        print("HealPredictionDisplay: [🔍 TARGET] TargetFrame détectée - Visible:", TargetFrame:IsVisible())
        print("HealPredictionDisplay: [🔍 TARGET] HealthBar:", TargetFrameHealthBar:GetName())
        print("HealPredictionDisplay: [🔍 TARGET] Target exists:", UnitExists("target"))
        
        if UnitExists("target") then
            local targetName = UnitName("target")
            local targetGUID = UnitGUID("target")
            print("HealPredictionDisplay: [🔍 TARGET] Target actuel:", targetName, "GUID:", targetGUID)
        end
        
        local healBar = self:CreateHealBar(TargetFrameHealthBar, "BlizzardParty", "TargetFrame")
        if healBar then
            healBars["target_blizzard"] = {
                healBar = healBar,
                healthBar = TargetFrameHealthBar,
                unit = "target",
                frameType = "BlizzardParty",
                parentFrame = TargetFrame
            }
            print("HealPredictionDisplay: [🔍 TARGET] ✅ Barre créée pour target_blizzard")
            count = 1
        end
    else
        print("HealPredictionDisplay: [🔍 TARGET] ❌ TargetFrame ou HealthBar manquant")
        print("HealPredictionDisplay: [🔍 TARGET] TargetFrame:", TargetFrame and "OK" or "NIL")
        print("HealPredictionDisplay: [🔍 TARGET] TargetFrameHealthBar:", TargetFrameHealthBar and "OK" or "NIL")
    end
    
    return count
end

function UnitFrameDisplay:ScanFocusFrame()
    local count = 0
    
    -- *** FIX FOCUS *** : Détecter même si pas visible
    if FocusFrame and FocusFrameHealthBar then
        print("HealPredictionDisplay: [🔍 FOCUS] FocusFrame détectée - Visible:", FocusFrame:IsVisible())
        print("HealPredictionDisplay: [🔍 FOCUS] HealthBar:", FocusFrameHealthBar:GetName())
        print("HealPredictionDisplay: [🔍 FOCUS] Focus exists:", UnitExists("focus"))
        
        if UnitExists("focus") then
            local focusName = UnitName("focus")
            local focusGUID = UnitGUID("focus")
            print("HealPredictionDisplay: [🔍 FOCUS] Focus actuel:", focusName, "GUID:", focusGUID)
        end
        
        local healBar = self:CreateHealBar(FocusFrameHealthBar, "BlizzardParty", "FocusFrame")
        if healBar then
            healBars["focus_blizzard"] = {
                healBar = healBar,
                healthBar = FocusFrameHealthBar,
                unit = "focus",
                frameType = "BlizzardParty",
                parentFrame = FocusFrame
            }
            print("HealPredictionDisplay: [🔍 FOCUS] ✅ Barre créée pour focus_blizzard")
            count = 1
        end
    else
        print("HealPredictionDisplay: [🔍 FOCUS] ❌ FocusFrame ou HealthBar manquant")
        print("HealPredictionDisplay: [🔍 FOCUS] FocusFrame:", FocusFrame and "OK" or "NIL")
        print("HealPredictionDisplay: [🔍 FOCUS] FocusFrameHealthBar:", FocusFrameHealthBar and "OK" or "NIL")
    end
    
    return count
end

function UnitFrameDisplay:ScanPetFrame()
    local count = 0
    
    if PetFrame and PetFrameHealthBar then
        print("HealPredictionDisplay: [🔍 PET] PetFrame détectée - Visible:", PetFrame:IsVisible())
        
        local healBar = self:CreateHealBar(PetFrameHealthBar, "BlizzardParty", "PetFrame")
        if healBar then
            healBars["pet_blizzard"] = {
                healBar = healBar,
                healthBar = PetFrameHealthBar,
                unit = "pet",
                frameType = "BlizzardParty",
                parentFrame = PetFrame
            }
            print("HealPredictionDisplay: [🔍 PET] ✅ Barre créée pour pet_blizzard")
            count = 1
        end
    end
    
    return count
end

function UnitFrameDisplay:ScanCompactRaidFrames()
    local count = 0
    
    if CompactRaidFrameContainer then
        print("HealPredictionDisplay: [🔍 COMPACT] CompactRaidFrameContainer - Visible:", CompactRaidFrameContainer:IsVisible())
        
        for i = 1, 40 do
            local frameName = "CompactRaidFrame" .. i
            local frame = _G[frameName]
            
            if frame and frame:IsVisible() and frame.unit then
                local unit = frame.unit
                local healthBar = frame.healthBar or frame.HealthBar
                
                if healthBar then
                    print("HealPredictionDisplay: [🔍 COMPACT] Frame trouvée:", frameName, "Unit:", unit)
                    
                    local healBar = self:CreateHealBar(healthBar, "CompactRaid", frameName)
                    if healBar then
                        local uniqueKey = unit .. "_compact"
                        healBars[uniqueKey] = {
                            healBar = healBar,
                            healthBar = healthBar,
                            unit = unit,
                            frameType = "CompactRaid",
                            frame = frame,
                            parentFrame = frame
                        }
                        print("HealPredictionDisplay: [🔍 COMPACT] ✅ Barre créée pour", uniqueKey)
                        count = count + 1
                    end
                end
            end
        end
    end
    
    return count
end

-- ========== CRÉATION DE BARRE AMÉLIORÉE ==========

function UnitFrameDisplay:CreateHealBar(healthBar, frameType, frameName)
    if not healthBar then
        print("HealPredictionDisplay: ❌ HealthBar nil pour", frameName)
        return nil
    end
    
    local healBar = CreateFrame("StatusBar", nil, healthBar:GetParent())
    
    -- *** ANCRAGE DYNAMIQUE *** : Position initiale correcte
    healBar:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)
    healBar:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
    healBar:SetWidth(0)
    
    -- Style par défaut
    healBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    healBar:SetStatusBarColor(0, 1, 0, 0.7)
    
    -- Background
    local bg = healBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(healBar)
    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bg:SetVertexColor(0, 1, 0, 0.3)
    healBar.background = bg
    
    -- Métadonnées
    healBar.frameType = frameType
    healBar.frameName = frameName
    healBar.createdTime = GetTime()
    healBar.originalHealthBar = healthBar
    
    -- Initialement caché
    healBar:Hide()
    
    print("HealPredictionDisplay: [🔧 CREATE] Barre créée pour", frameName)
    
    return healBar
end

-- ========== MISE À JOUR AVEC ANCRAGE DYNAMIQUE ==========

function UnitFrameDisplay:UpdateUnitFrame(guid)
    print("HealPredictionDisplay: [🖥️ UPDATE] === UPDATE AVEC ANCRAGE DYNAMIQUE ===")
    print("HealPredictionDisplay: [🖥️ UPDATE] GUID:", guid)
    
    if not guid then
        print("HealPredictionDisplay: [🖥️ UPDATE] ❌ GUID nil")
        return
    end
    
    -- *** AMÉLIORATION *** : Tester plus d'unités incluant raid
    local unitsToTest = {"player", "target", "focus", "pet", "party1", "party2", "party3", "party4"}
    
    -- Ajouter les unités de raid
    if UnitInRaid("player") then
        for i = 1, GetNumRaidMembers() do
            table.insert(unitsToTest, "raid" .. i)
        end
    end
    
    local matchingUnits = {}
    
    for _, unit in ipairs(unitsToTest) do
        if UnitExists(unit) then
            local unitGUID = UnitGUID(unit)
            if unitGUID == guid then
                table.insert(matchingUnits, unit)
                print("HealPredictionDisplay: [🖥️ UPDATE] ✅ Unité trouvée:", unit, "GUID:", unitGUID)
            end
        end
    end
    
    print("HealPredictionDisplay: [🖥️ UPDATE] Unités correspondantes:", #matchingUnits)
    
    if #matchingUnits == 0 then
        print("HealPredictionDisplay: [🖥️ UPDATE] ❌ Aucune unité trouvée")
        return
    end
    
    -- Récupération des données de heal
    local healData = nil
    
    if addon and addon.testHealCache and addon.testHealCache[guid] then
        healData = addon.testHealCache[guid]
        print("HealPredictionDisplay: [🖥️ UPDATE] ✅ Cache test - Total:", healData.total)
    else
        local healPredModule = addon:GetModule("HealPrediction", true)
        if healPredModule then
            healData = healPredModule:GetHealData(guid)
            if healData then
                print("HealPredictionDisplay: [🖥️ UPDATE] ✅ Cache réel - Total:", healData.total)
            end
        end
        
        if not healData then
            print("HealPredictionDisplay: [🖥️ UPDATE] ❌ Aucune donnée de heal")
            self:HideAllBarsForUnits(matchingUnits)
            return
        end
    end
    
    -- *** MISE À JOUR AVEC ANCRAGE DYNAMIQUE ***
    local updatedCount = 0
    
    for _, unit in ipairs(matchingUnits) do
        print("HealPredictionDisplay: [🖥️ UPDATE] 🔄 Traitement unité:", unit)
        
        for barKey, barData in pairs(healBars) do
            if barData.unit == unit then
                print("HealPredictionDisplay: [🖥️ UPDATE] ✅ Barre trouvée:", barKey)
                
                if self:UpdateSingleBarWithDynamicAnchor(barData, unit, healData) then
                    updatedCount = updatedCount + 1
                    print("HealPredictionDisplay: [🖥️ UPDATE] ✅ Barre", barKey, "mise à jour avec ancrage dynamique")
                end
            end
        end
    end
    
    print("HealPredictionDisplay: [🖥️ UPDATE] ✅", updatedCount, "barre(s) mises à jour")
end

function UnitFrameDisplay:UpdateSingleBarWithDynamicAnchor(healBarData, unit, healData)
    local healBar = healBarData.healBar
    local healthBar = healBarData.healthBar
    
    print("HealPredictionDisplay: [🔧 ANCHOR] === ANCRAGE DYNAMIQUE ===")
    print("HealPredictionDisplay: [🔧 ANCHOR] Unit:", unit, "Type:", healBarData.frameType)
    
    if not healData or healData.total <= 0 then
        healBar:Hide()
        print("HealPredictionDisplay: [🔧 ANCHOR] Barre cachée (pas de heal)")
        return true
    end
    
    -- Obtenir les stats de l'unité
    local currentHP = UnitHealth(unit) or 0
    local maxHP = UnitHealthMax(unit) or 1
    local incomingHeal = healData.total
    
    print("HealPredictionDisplay: [🔧 ANCHOR] Stats:", currentHP .. "/" .. maxHP, "Heal:", incomingHeal)
    
    -- *** CALCUL D'ANCRAGE DYNAMIQUE ***
    local healthPercent = currentHP / maxHP
    local missingHP = maxHP - currentHP
    local healthBarWidth = healthBar:GetWidth()
    
    print("HealPredictionDisplay: [🔧 ANCHOR] HealthBar largeur:", healthBarWidth)
    print("HealPredictionDisplay: [🔧 ANCHOR] HP percent:", string.format("%.2f", healthPercent))
    
    -- *** POSITION DE DÉPART *** : Où la barre de vie se termine
    local healthBarEndX = healthBarWidth * healthPercent
    
    -- *** LARGEUR DE LA PRÉDICTION ***
    local healAmount = math.min(incomingHeal, missingHP)  -- Ne pas dépasser le max HP
    local healPercent = healAmount / maxHP
    local healBarWidth = healthBarWidth * healPercent
    
    -- Si pas de HP manquant, afficher quand même (overflow)
    if missingHP <= 0 then
        healAmount = incomingHeal
        healPercent = math.min(healAmount / maxHP, 0.3)  -- Max 30% de overflow
        healBarWidth = healthBarWidth * healPercent
        healthBarEndX = healthBarWidth  -- Commencer à la fin de la barre
    end
    
    print("HealPredictionDisplay: [🔧 ANCHOR] *** CALCULS FINAUX ***")
    print("HealPredictionDisplay: [🔧 ANCHOR] Heal amount effectif:", healAmount)
    print("HealPredictionDisplay: [🔧 ANCHOR] Heal percent:", string.format("%.2f", healPercent))
    print("HealPredictionDisplay: [🔧 ANCHOR] Position start X:", healthBarEndX)
    print("HealPredictionDisplay: [🔧 ANCHOR] Largeur heal:", healBarWidth)
    
    -- Taille minimum
    if healBarWidth < 3 then
        healBar:Hide()
        print("HealPredictionDisplay: [🔧 ANCHOR] Barre trop petite")
        return true
    end
    
    -- *** ANCRAGE DYNAMIQUE *** : Positionner la barre à la fin des HP actuels
    healBar:ClearAllPoints()
    
    if missingHP > 0 then
        -- *** MODE NORMAL *** : Combler le vide des HP
        healBar:SetPoint("LEFT", healthBar, "LEFT", healthBarEndX, 0)
        healBar:SetPoint("TOP", healthBar, "TOP", 0, 0)
        healBar:SetPoint("BOTTOM", healthBar, "BOTTOM", 0, 0)
        healBar:SetWidth(healBarWidth)
        
        -- Couleur selon le type
        if healData.self and healData.self > 0 then
            healBar:SetStatusBarColor(0.2, 0.6, 1, 0.8)  -- Bleu
        else
            healBar:SetStatusBarColor(0.2, 1, 0.2, 0.8)  -- Vert
        end
        
        print("HealPredictionDisplay: [🔧 ANCHOR] ✅ MODE NORMAL - Comble le vide HP")
        
    else
        -- *** MODE OVERFLOW *** : Afficher à droite de la barre pleine
        healBar:SetPoint("LEFT", healthBar, "RIGHT", 0, 0)
        healBar:SetPoint("TOP", healthBar, "TOP", 0, 0)
        healBar:SetPoint("BOTTOM", healthBar, "BOTTOM", 0, 0)
        healBar:SetWidth(healBarWidth)
        
        -- Couleur overflow (plus transparente)
        if healData.self and healData.self > 0 then
            healBar:SetStatusBarColor(0.4, 0.8, 1, 0.6)  -- Bleu transparent
        else
            healBar:SetStatusBarColor(0.4, 1, 0.4, 0.6)  -- Vert transparent
        end
        
        print("HealPredictionDisplay: [🔧 ANCHOR] ✅ MODE OVERFLOW - À droite de la barre")
    end
    
    -- Configuration finale
    healBar:SetMinMaxValues(0, 1)
    healBar:SetValue(1)
    healBar:Show()
    healBar:SetAlpha(1)
    
    print("HealPredictionDisplay: [🔧 ANCHOR] *** BARRE ANCRÉE DYNAMIQUEMENT ! ***")
    print("HealPredictionDisplay: [🔧 ANCHOR] Position finale - Left offset:", healthBarEndX)
    print("HealPredictionDisplay: [🔧 ANCHOR] Largeur finale:", healBarWidth)
    print("HealPredictionDisplay: [🔧 ANCHOR] Mode:", missingHP > 0 and "NORMAL" or "OVERFLOW")
    
    return true
end

function UnitFrameDisplay:HideAllBarsForUnits(units)
    for _, unit in ipairs(units) do
        for barKey, barData in pairs(healBars) do
            if barData.unit == unit then
                barData.healBar:Hide()
                print("HealPredictionDisplay: [🖥️ UPDATE] Barre", barKey, "cachée")
            end
        end
    end
end

-- ========== MÉTHODES DE DEBUG ==========

_G.HealPredictionDisplay_HealBars = healBars

function UnitFrameDisplay:ForceVisibleTest(guid)
    print("HealPredictionDisplay: [🔥 FORCE] Forçage visibilité pour GUID:", guid)
    
    for barKey, barData in pairs(healBars) do
        local healBar = barData.healBar
        
        healBar:Show()
        healBar:SetAlpha(1)
        healBar:SetWidth(50)
        healBar:SetStatusBarColor(1, 0, 1, 1)  -- Magenta
        
        healBar:ClearAllPoints()
        healBar:SetPoint("LEFT", barData.healthBar, "RIGHT", 5, 0)
        healBar:SetPoint("TOP", barData.healthBar, "TOP", 0, 0)
        healBar:SetPoint("BOTTOM", barData.healthBar, "BOTTOM", 0, 0)
        
        print("HealPredictionDisplay: [🔥 FORCE] ✅ Barre", barKey, "forcée visible")
    end
end

function UnitFrameDisplay:FlashBars()
    print("HealPredictionDisplay: [⚡ FLASH] Clignotement...")
    
    local flashCount = 0
    local maxFlashes = 4
    
    local function doFlash()
        flashCount = flashCount + 1
        
        for barKey, barData in pairs(healBars) do
            local healBar = barData.healBar
            
            if flashCount % 2 == 1 then
                healBar:Show()
                healBar:SetStatusBarColor(1, 0, 0, 1)  -- Rouge
                healBar:SetWidth(60)
                healBar:ClearAllPoints()
                healBar:SetPoint("LEFT", barData.healthBar, "RIGHT", 2, 0)
                healBar:SetPoint("TOP", barData.healthBar, "TOP", 0, 0)
                healBar:SetPoint("BOTTOM", barData.healthBar, "BOTTOM", 0, 0)
            else
                healBar:SetStatusBarColor(0, 1, 0, 1)  -- Vert
                healBar:SetAlpha(0.5)
            end
        end
        
        if flashCount < maxFlashes then
            if addon and addon.ScheduleTimer then
                addon:ScheduleTimer(doFlash, 0.4)
            else
                C_Timer.NewTimer(0.4, doFlash)
            end
        else
            print("HealPredictionDisplay: [⚡ FLASH] Fin du clignotement")
        end
    end
    
    doFlash()
end

-- ========== UTILITAIRES ==========

function UnitFrameDisplay:CountTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function UnitFrameDisplay:RefreshAllBars()
    print("HealPredictionDisplay: [🔄 REFRESH] Rafraîchissement forcé")
    self:ScanAllFrames()
end

-- ========== INITIALISATION ==========

if addon then
    addon.unitFrameDisplay = UnitFrameDisplay:new()
    
    if addon.ScheduleTimer then
        addon:ScheduleTimer(function()
            if addon.unitFrameDisplay and addon.unitFrameDisplay.Initialize then
                addon.unitFrameDisplay:Initialize()
            end
        end, 2)
    else
        C_Timer.NewTimer(2, function()
            if addon.unitFrameDisplay and addon.unitFrameDisplay.Initialize then
                addon.unitFrameDisplay:Initialize()
            end
        end)
    end
end

print("HealPredictionDisplay: UnitFrameDisplay COMPLET avec ancrage dynamique et fix target/focus")