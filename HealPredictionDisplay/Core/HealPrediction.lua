--[[
	HealPredictionDisplay - Système de prédiction de heal
	Intégration avec HealPredict et LibHealComm
]]

local addon = HealPredictionDisplay

-- Fonctions utilitaires pour les heals
function addon:GetIncomingHeals(unit, healer)
    if not unit or not HealPredict then
        return 0, 0
    end
    
    local myHeals = 0
    local otherHeals = 0
    local totalHeals = 0
    
    -- Utiliser HealPredict si disponible
    if HealPredict.UnitGetIncomingHeals then
        totalHeals = HealPredict.UnitGetIncomingHeals(unit) or 0
        myHeals = HealPredict.UnitGetIncomingHeals(unit, UnitName("player")) or 0
        otherHeals = math.max(0, totalHeals - myHeals)
    end
    
    -- Fallback vers LibHealComm si disponible
    if totalHeals == 0 and LibStub then
        local LibHealComm = LibStub("LibHealComm-4.0", true)
        if LibHealComm then
            local unitGUID = UnitGUID(unit)
            if unitGUID then
                totalHeals = LibHealComm:GetHealAmount(unitGUID, LibHealComm.ALL_HEALS, GetTime() + 10) or 0
                myHeals = LibHealComm:GetCasterHealAmount(UnitGUID("player"), LibHealComm.ALL_HEALS, GetTime() + 10) or 0
                otherHeals = math.max(0, totalHeals - myHeals)
            end
        end
    end
    
    return myHeals, otherHeals
end

-- Calculer les positions des barres de heal
function addon:CalculateHealBarPositions(frame, health, maxHealth, myHeals, otherHeals)
    local data = self.frames[frame]
    if not data or not data.healthBar then
        return 0, 0, 0, 0
    end
    
    local healthTexture = data.healthBar:GetStatusBarTexture()
    if not healthTexture then
        return 0, 0, 0, 0
    end
    
    local maxOverflow = self.db.profile.maxOverflow
    local maxOverflowHealth = maxHealth * maxOverflow
    
    -- Limiter les heals au overflow maximum
    local totalHeals = myHeals + otherHeals
    if health + totalHeals > maxOverflowHealth then
        totalHeals = maxOverflowHealth - health
        if totalHeals > 0 then
            local ratio = totalHeals / (myHeals + otherHeals)
            myHeals = myHeals * ratio
            otherHeals = otherHeals * ratio
        else
            myHeals = 0
            otherHeals = 0
        end
    end
    
    -- Calculer les positions
    local healthBarWidth = data.healthBar:GetWidth()
    local healthPercent = health / maxHealth
    local myHealPercent = myHeals / maxHealth
    local otherHealPercent = otherHeals / maxHealth
    
    local healthPos = healthBarWidth * healthPercent
    local myHealWidth = healthBarWidth * myHealPercent
    local otherHealWidth = healthBarWidth * otherHealPercent
    
    return healthPos, myHealWidth, otherHealWidth, healthBarWidth
end

-- Callbacks pour HealPredict
function addon:RegisterHealPredictionCallbacks()
    if HealPredict and HealPredict.RegisterCallback then
        HealPredict.RegisterCallback(self.name, function(...)
            self:OnHealPredictionUpdate(...)
        end)
    end
    
    -- Callback pour LibHealComm si disponible
    if LibStub then
        local LibHealComm = LibStub("LibHealComm-4.0", true)
        if LibHealComm then
            LibHealComm.RegisterCallback(self, "HealComm_HealStarted", "OnHealCommUpdate")
            LibHealComm.RegisterCallback(self, "HealComm_HealStopped", "OnHealCommUpdate")
            LibHealComm.RegisterCallback(self, "HealComm_HealUpdated", "OnHealCommUpdate")
        end
    end
end

function addon:OnHealPredictionUpdate(...)
    local units = {...}
    
    for _, unitName in ipairs(units) do
        -- Trouver le frame correspondant à cette unité
        for frame, data in pairs(self.frames) do
            if data.unitName == unitName then
                self:UpdateHealPrediction(frame)
            end
        end
    end
end

function addon:OnHealCommUpdate(event, ...)
    -- Mettre à jour tous les frames visibles
    self:UpdateAllFrames()
end

-- Calculer la couleur interpolée basée sur la santé
function addon:GetHealthBasedColor(healthPercent)
    local r, g, b
    if healthPercent > 0.5 then
        -- Vert à jaune
        r = (1 - healthPercent) * 2
        g = 1
        b = 0
    else
        -- Jaune à rouge
        r = 1
        g = healthPercent * 2
        b = 0
    end
    return r, g, b
end

-- Optimisation : vérifier si les valeurs ont changé
function addon:ShouldUpdateHealBars(frame, myHeals, otherHeals)
    local data = self.frames[frame]
    if not data then return true end
    
    local lastMyHeals = data.lastMyHeals or -1
    local lastOtherHeals = data.lastOtherHeals or -1
    
    if math.abs(myHeals - lastMyHeals) > 1 or math.abs(otherHeals - lastOtherHeals) > 1 then
        data.lastMyHeals = myHeals
        data.lastOtherHeals = otherHeals
        return true
    end
    
    return false
end