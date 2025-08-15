--[[
	HealPredictionDisplay - Affichage sur les unit frames
	Support pour les frames Blizzard et ElvUI
]]

local addon = HealPredictionDisplay

-- Initialisation des frames
function addon:InitializeFrames()
    -- Attendre que les frames soient chargées
    self:ScheduleTimer("ScanForFrames", 2)
end

-- Scanner pour les frames disponibles
function addon:ScanForFrames()
    -- Frames Blizzard standard
    self:RegisterBlizzardFrames()
    
    -- Frames ElvUI si disponible
    if ElvUI then
        self:RegisterElvUIFrames()
    end
    
    -- Frames oUF génériques
    if oUF then
        self:RegisterOUFFrames()
    end
    
    print("|cff1784d1HealPredictionDisplay:|r " .. self:CountFrames() .. " frames enregistrés")
end

-- Enregistrer les frames Blizzard
function addon:RegisterBlizzardFrames()
    local blizzardFrames = {
        {name = "PlayerFrame", unit = "player"},
        {name = "TargetFrame", unit = "target"},
        {name = "FocusFrame", unit = "focus"},
        {name = "PetFrame", unit = "pet"},
    }
    
    for _, frameInfo in ipairs(blizzardFrames) do
        local frame = _G[frameInfo.name]
        if frame and frame:IsVisible() then
            frame.unit = frameInfo.unit
            self:RegisterFrame(frame)
        end
    end
    
    -- Frames de groupe
    for i = 1, 4 do
        local frame = _G["PartyMemberFrame" .. i]
        if frame then
            frame.unit = "party" .. i
            self:RegisterFrame(frame)
        end
    end
    
    -- Frames de raid compact - CORRECTION MAJEURE ICI
    self:RegisterCompactRaidFrames()
end

-- Nouvelle fonction spécialisée pour les frames de raid compact
function addon:RegisterCompactRaidFrames()
    -- Vérifier si le raid manager est disponible
    if not CompactRaidFrameManager then
        if self.db.profile.debug then
            print("[HPD] CompactRaidFrameManager not available")
        end
        return
    end
    
    -- Parcourir tous les groupes de raid
    for groupIndex = 1, 8 do
        local groupFrame = _G["CompactRaidGroup" .. groupIndex]
        if groupFrame then
            -- Parcourir tous les membres du groupe
            for memberIndex = 1, 5 do
                local memberFrame = _G["CompactRaidGroup" .. groupIndex .. "Member" .. memberIndex]
                if memberFrame and memberFrame.unit then
                    if self.db.profile.debug then
                        print("[HPD] Registering CompactRaidFrame:", memberFrame:GetName(), "Unit:", memberFrame.unit)
                    end
                    self:RegisterFrame(memberFrame)
                end
            end
        end
    end
    
    -- Aussi vérifier les frames individuels (fallback)
    for i = 1, 40 do
        local frame = _G["CompactRaidFrame" .. i]
        if frame and frame.unit then
            if self.db.profile.debug then
                print("[HPD] Registering individual CompactRaidFrame:", frame:GetName(), "Unit:", frame.unit)
            end
            self:RegisterFrame(frame)
        end
    end
    
    -- Hook pour détecter les nouveaux CompactRaidFrames qui apparaissent
    if not self.compactRaidHooked then
        self.compactRaidHooked = true
        
        -- Hook la fonction de mise à jour des frames compact
        if CompactUnitFrame_UpdateAll then
            hooksecurefunc("CompactUnitFrame_UpdateAll", function()
                C_Timer.After(0.1, function()
                    addon:RegisterCompactRaidFrames()
                end)
            end)
        end
        
        -- Hook pour CompactRaidFrameContainer
        if CompactRaidFrameContainer then
            CompactRaidFrameContainer:HookScript("OnShow", function()
                C_Timer.After(0.5, function()
                    addon:RegisterCompactRaidFrames()
                end)
            end)
        end
    end
end

-- Enregistrer les frames ElvUI
function addon:RegisterElvUIFrames()
    local ElvUF = ElvUI[1].oUF
    if not ElvUF then return end
    
    -- Scanner tous les frames oUF
    for _, frame in pairs(ElvUF.objects) do
        if frame and frame.unit then
            self:RegisterFrame(frame)
        end
    end
end

-- Enregistrer les frames oUF génériques
function addon:RegisterOUFFrames()
    if not oUF.objects then return end
    
    for _, frame in pairs(oUF.objects) do
        if frame and frame.unit then
            self:RegisterFrame(frame)
        end
    end
end

-- Enregistrer un frame individual
function addon:RegisterFrame(frame)
    if not frame or not frame.unit then return end
    
    -- Vérifier si l'unité est activée
    local unitType = self:GetUnitType(frame.unit)
    if not self.db.profile.units[unitType] then return end
    
    -- Éviter les doublons
    if self.frames[frame] then return end
    
    -- Trouver la barre de santé
    local healthBar = self:FindHealthBar(frame)
    if not healthBar then 
        if self.db.profile.debug then
            print("[HPD] No health bar found for frame:", frame:GetName() or "unnamed", "Unit:", frame.unit)
        end
        return 
    end
    
    -- Créer les barres de prediction
    local myHealBar, otherHealBar = self:CreateHealBars(frame, healthBar)
    if not myHealBar then return end
    
    -- Enregistrer le frame même si otherHealBar n'est pas encore créé
    self.frames[frame] = {
        unit = frame.unit,
        unitName = UnitName(frame.unit),
        healthBar = healthBar,
        myHealBar = myHealBar,
        otherHealBar = otherHealBar, -- Peut être nil temporairement
        lastMyHeals = 0,
        lastOtherHeals = 0,
    }
    
    -- Si otherHealBar n'est pas encore créé, programmer une vérification
    if not otherHealBar then
        C_Timer.After(0.1, function()
            if self.frames[frame] and not self.frames[frame].otherHealBar then
                if self.db.profile.debug then
                    print("[HPD] Retrying otherHealBar creation for", frame:GetName() or "unnamed")
                end
                -- Recréer complètement les barres
                self:ReCreateHealBars(frame)
            end
        end)
    end
    
    if self.db.profile.debug then
        print("[HPD] Successfully registered frame:", frame:GetName() or "unnamed", "Unit:", frame.unit)
    end
    
    -- Mise à jour initiale
    self:UpdateHealPrediction(frame)
end

-- Trouver la barre de santé - VERSION AMÉLIORÉE POUR COMPACTRAIDFRAMES
function addon:FindHealthBar(frame)
    -- ElvUI
    if frame.Health then
        return frame.Health
    end
    
    -- Blizzard standard
    if frame.healthbar then
        return frame.healthbar
    end
    
    -- CompactRaidFrames - CORRECTION MAJEURE ICI
    if frame.healthBar then
        return frame.healthBar
    end
    
    -- oUF générique
    if frame.Health then
        return frame.Health
    end
    
    -- Recherche par nom
    local frameName = frame:GetName()
    if frameName then
        -- Patterns spéciaux pour CompactRaidFrames
        if frameName:match("CompactRaid") then
            -- CompactRaidFrames utilisent .healthBar (pas .healthbar)
            local healthBar = frame.healthBar
            if healthBar and healthBar:IsObjectType("StatusBar") then
                if self.db.profile.debug then
                    print("[HPD] Found CompactRaid healthBar for", frameName)
                end
                return healthBar
            end
            
            -- Fallback : rechercher dans les enfants pour les CompactRaidFrames
            local children = {frame:GetChildren()}
            for _, child in ipairs(children) do
                if child:IsObjectType("StatusBar") then
                    local childName = child:GetName()
                    if childName and (childName:find("Health") or childName:find("health")) then
                        if self.db.profile.debug then
                            print("[HPD] Found CompactRaid health child:", childName, "for", frameName)
                        end
                        return child
                    end
                    -- Parfois la barre de santé n'a pas de nom mais est la première StatusBar
                    if not childName then
                        if self.db.profile.debug then
                            print("[HPD] Found unnamed StatusBar child for", frameName)
                        end
                        return child
                    end
                end
            end
        end
        
        -- Patterns normaux pour autres frames
        local healthBar = _G[frameName .. "HealthBar"] or _G[frameName .. ".healthbar"]
        if healthBar then
            return healthBar
        end
        
        -- Patterns courants
        local patterns = {
            "HealthBar",
            "Health",
            "_HealthBar", 
            "_Health"
        }
        
        for _, pattern in ipairs(patterns) do
            local bar = _G[frameName .. pattern]
            if bar and bar:IsObjectType("StatusBar") then
                return bar
            end
        end
    end
    
    -- Recherche récursive dans les enfants (pour tous les types de frames)
    local children = {frame:GetChildren()}
    for _, child in ipairs(children) do
        if child:IsObjectType("StatusBar") then
            local name = child:GetName()
            if name and (name:find("Health") or name:find("health")) then
                return child
            end
            -- Pour les frames sans nom, vérifier si c'est potentiellement une barre de santé
            if not name then
                -- Vérifier si la StatusBar a des valeurs typiques d'une barre de santé
                local min, max = child:GetMinMaxValues()
                if max > 0 and max <= 1000000 then -- Plage typique de HP
                    return child
                end
            end
        end
    end
    
    return nil
end

-- Créer les barres de prediction (VERSION CORRIGÉE)
function addon:CreateHealBars(frame, healthBar)
    local frameName = frame:GetName()
    local baseFrameName
    
    if frameName then
        -- Créer un nom unique avec timestamp pour éviter les collisions
        local timestamp = math.floor(GetTime() * 1000)
        local frameGUID = tostring(frame):gsub("table: ", ""):gsub("0x", "")
        baseFrameName = "HPD_" .. frameGUID .. "_" .. timestamp
    end
    
    if self.db.profile.debug then
        print("[HPD] Creating heal bars for frame:", frameName or "unnamed")
        print("[HPD] HealthBar parent:", tostring(healthBar))
        print("[HPD] HealthBar children count:", select("#", healthBar:GetChildren()))
    end
    
    -- Fonction helper pour créer une barre avec retry
    local function CreateHealBarWithRetry(barType, parent, attempts)
        attempts = attempts or 3
        
        for i = 1, attempts do
            local barName = nil
            if baseFrameName then
                barName = baseFrameName .. "_" .. barType .. "_" .. i
            end
            
            local healBar = CreateFrame("StatusBar", barName, parent)
            
            if healBar then
                if self.db.profile.debug then
                    print("[HPD] Successfully created", barType, "on attempt", i)
                end
                return healBar
            else
                if self.db.profile.debug then
                    print("[HPD] Failed to create", barType, "on attempt", i)
                end
                
                -- Sur le dernier essai, essayer sans nom
                if i == attempts then
                    healBar = CreateFrame("StatusBar", nil, parent)
                    if healBar and self.db.profile.debug then
                        print("[HPD] Created", barType, "without name as fallback")
                    end
                    return healBar
                end
                
                -- Petit délai entre les tentatives
                C_Timer.After(0.01, function() end)
            end
        end
        
        return nil
    end
    
    -- Créer myHealBar avec retry
    local myHealBar = CreateHealBarWithRetry("MyHeal", healthBar)
    
    if not myHealBar then
        if self.db.profile.debug then
            print("[HPD] CRITICAL: Failed to create myHealBar after all attempts")
        end
        return nil, nil
    end
    
    -- Valider myHealBar avant de continuer
    if not myHealBar:GetParent() or myHealBar:GetParent() ~= healthBar then
        if self.db.profile.debug then
            print("[HPD] CRITICAL: myHealBar parent validation failed")
        end
        myHealBar:SetParent(nil)
        return nil, nil
    end
    
    -- Configuration de myHealBar
    myHealBar:SetFrameLevel(healthBar:GetFrameLevel() + 1)
    
    local healthTexture = healthBar:GetStatusBarTexture()
    if healthTexture then
        myHealBar:SetStatusBarTexture(healthTexture:GetTexture())
    else
        myHealBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    end
    
    local myColor = self.db.profile.myHealColor
    myHealBar:SetStatusBarColor(myColor.r, myColor.g, myColor.b, myColor.a)
    
    -- Créer otherHealBar avec retry (avec un petit délai pour éviter les conflits)
    local otherHealBar
    C_Timer.After(0.001, function()
        otherHealBar = CreateHealBarWithRetry("OtherHeal", healthBar)
        
        if not otherHealBar then
            if self.db.profile.debug then
                print("[HPD] CRITICAL: Failed to create otherHealBar, cleaning up myHealBar")
            end
            myHealBar:SetParent(nil)
            return
        end
        
        -- Configuration d'otherHealBar
        otherHealBar:SetFrameLevel(healthBar:GetFrameLevel() + 1)
        
        if healthTexture then
            otherHealBar:SetStatusBarTexture(healthTexture:GetTexture())
        else
            otherHealBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        end
        
        local otherColor = self.db.profile.otherHealColor
        otherHealBar:SetStatusBarColor(otherColor.r, otherColor.g, otherColor.b, otherColor.a)
        
        -- Positionnement initial
        myHealBar:SetAllPoints(healthBar)
        otherHealBar:SetAllPoints(healthBar)
        
        -- Masquer initialement
        myHealBar:Hide()
        otherHealBar:Hide()
        
        -- Stocker les barres dans les données du frame
        if self.frames[frame] then
            self.frames[frame].otherHealBar = otherHealBar
            
            if self.db.profile.debug then
                print("[HPD] Successfully created both heal bars for", frameName or "unnamed frame")
            end
        end
    end)
    
    -- Positionnement initial de myHealBar
    myHealBar:SetAllPoints(healthBar)
    myHealBar:Hide()
    
    -- Retourner myHealBar immédiatement, otherHealBar sera assigné via le timer
    return myHealBar, otherHealBar
end

-- Recréer les barres de heal pour un frame spécifique
function addon:ReCreateHealBars(frame)
    if not self.frames[frame] then return end
    
    local data = self.frames[frame]
    
    -- Nettoyer les anciennes barres
    if data.myHealBar then
        data.myHealBar:Hide()
        data.myHealBar:SetParent(nil)
    end
    if data.otherHealBar then
        data.otherHealBar:Hide()
        data.otherHealBar:SetParent(nil)
    end
    
    -- Recréer avec une approche synchrone cette fois
    local myHealBar = CreateFrame("StatusBar", nil, data.healthBar)
    local otherHealBar = CreateFrame("StatusBar", nil, data.healthBar)
    
    if myHealBar and otherHealBar then
        -- Configuration myHealBar
        myHealBar:SetFrameLevel(data.healthBar:GetFrameLevel() + 1)
        local healthTexture = data.healthBar:GetStatusBarTexture()
        if healthTexture then
            myHealBar:SetStatusBarTexture(healthTexture:GetTexture())
        else
            myHealBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        end
        local myColor = self.db.profile.myHealColor
        myHealBar:SetStatusBarColor(myColor.r, myColor.g, myColor.b, myColor.a)
        myHealBar:SetAllPoints(data.healthBar)
        myHealBar:Hide()
        
        -- Configuration otherHealBar
        otherHealBar:SetFrameLevel(data.healthBar:GetFrameLevel() + 1)
        if healthTexture then
            otherHealBar:SetStatusBarTexture(healthTexture:GetTexture())
        else
            otherHealBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        end
        local otherColor = self.db.profile.otherHealColor
        otherHealBar:SetStatusBarColor(otherColor.r, otherColor.g, otherColor.b, otherColor.a)
        otherHealBar:SetAllPoints(data.healthBar)
        otherHealBar:Hide()
        
        -- Mettre à jour les données
        data.myHealBar = myHealBar
        data.otherHealBar = otherHealBar
        
        if self.db.profile.debug then
            print("[HPD] Successfully recreated heal bars for", frame:GetName() or "unnamed")
        end
    else
        if self.db.profile.debug then
            print("[HPD] Failed to recreate heal bars, removing frame")
        end
        self.frames[frame] = nil
    end
end

-- Mise à jour de la prediction pour un frame
function addon:UpdateHealPrediction(frame)
    local data = self.frames[frame]
    if not data or not frame.unit then return end
    
    -- Vérifier que les barres existent
    if not data.myHealBar or not data.otherHealBar then
        if self.db.profile.debug then
            print("[HPD] Missing heal bars, attempting recreation for", frame:GetName() or "unnamed")
        end
        self:ReCreateHealBars(frame)
        return
    end
    
    if not self.db.profile.enabled then
        data.myHealBar:Hide()
        data.otherHealBar:Hide()
        return
    end
    
    -- Vérifier si l'unité existe
    if not UnitExists(frame.unit) then
        data.myHealBar:Hide()
        data.otherHealBar:Hide()
        return
    end
    
    -- Obtenir les informations de santé
    local health = UnitHealth(frame.unit)
    local maxHealth = UnitHealthMax(frame.unit)
    
    if maxHealth == 0 or UnitIsDeadOrGhost(frame.unit) then
        data.myHealBar:Hide()
        data.otherHealBar:Hide()
        return
    end
    
    -- Obtenir les heals entrants
    local myHeals, otherHeals = self:GetIncomingHeals(frame.unit)
    
    -- Optimisation : vérifier si une mise à jour est nécessaire
    if not self:ShouldUpdateHealBars(frame, myHeals, otherHeals) then
        return
    end
    
    if myHeals == 0 and otherHeals == 0 then
        data.myHealBar:Hide()
        data.otherHealBar:Hide()
        return
    end
    
    -- Calculer les positions
    local healthPos, myHealWidth, otherHealWidth, totalWidth = 
        self:CalculateHealBarPositions(frame, health, maxHealth, myHeals, otherHeals)
    
    -- Mettre à jour ma barre de heal
    if myHeals > 0 and self.db.profile.showMyHeals then
        self:UpdateHealBar(data.myHealBar, data.healthBar, myHealWidth, myHeals, maxHealth, nil)
    else
        data.myHealBar:Hide()
    end
    
    -- Mettre à jour la barre des autres heals
    if otherHeals > 0 and self.db.profile.showOtherHeals then
        local anchorBar = (myHeals > 0 and self.db.profile.showMyHeals) and data.myHealBar or data.healthBar
        self:UpdateHealBar(data.otherHealBar, data.healthBar, otherHealWidth, otherHeals, maxHealth, anchorBar)
    else
        data.otherHealBar:Hide()
    end
end

-- Mettre à jour une barre de heal individuelle
function addon:UpdateHealBar(healBar, healthBar, width, amount, maxHealth, anchorBar)
    healBar:ClearAllPoints()
    
    if anchorBar and anchorBar ~= healthBar then
        -- Ancrer à la fin de l'autre barre de heal
        healBar:SetPoint("LEFT", anchorBar:GetStatusBarTexture(), "RIGHT", 0, 0)
    else
        -- Ancrer à la fin de la barre de santé
        healBar:SetPoint("LEFT", healthBar:GetStatusBarTexture(), "RIGHT", 0, 0)
    end
    
    healBar:SetPoint("TOP", healthBar, "TOP")
    healBar:SetPoint("BOTTOM", healthBar, "BOTTOM")
    healBar:SetWidth(math.max(1, width))
    healBar:SetMinMaxValues(0, maxHealth)
    healBar:SetValue(amount)
    healBar:Show()
end

-- Fonctions utilitaires
function addon:GetUnitType(unit)
    if unit == "player" then return "player"
    elseif unit == "target" then return "target"
    elseif unit == "focus" then return "focus"
    elseif unit == "pet" then return "pet"
    elseif unit:match("^party") then return "party"
    elseif unit:match("^raid") then return "raid"
    else return "unknown"
    end
end

function addon:GetUnitFrame(unit)
    for frame, data in pairs(self.frames) do
        if data.unit == unit then
            return frame
        end
    end
    return nil
end

function addon:CountFrames()
    local count = 0
    for _ in pairs(self.frames) do
        count = count + 1
    end
    return count
end

-- Nettoyer les frames invalides
function addon:CleanupFrames()
    local toRemove = {}
    
    for frame, data in pairs(self.frames) do
        if not frame:IsVisible() or not frame.unit or not UnitExists(frame.unit) then
            if data.myHealBar then
                data.myHealBar:Hide()
                data.myHealBar:SetParent(nil)
            end
            if data.otherHealBar then
                data.otherHealBar:Hide()
                data.otherHealBar:SetParent(nil)
            end
            table.insert(toRemove, frame)
        end
    end
    
    for _, frame in ipairs(toRemove) do
        self.frames[frame] = nil
    end
end

-- Hook pour détecter les nouveaux frames
local function HookFrameShow(frame)
    if addon and frame.unit then
        addon:RegisterFrame(frame)
    end
end

-- Installer les hooks
hooksecurefunc("UnitFrame_Update", function(frame)
    if addon and frame and frame.unit then
        addon:RegisterFrame(frame)
    end
end)

-- Hook spécifique pour les CompactRaidFrames
if CompactUnitFrame_UpdateUnitSelectionFlash then
    hooksecurefunc("CompactUnitFrame_UpdateUnitSelectionFlash", function(frame)
        if addon and frame and frame.unit then
            C_Timer.After(0.1, function()
                addon:RegisterFrame(frame)
            end)
        end
    end)
end

-- Timer de nettoyage périodique
addon:ScheduleRepeatingTimer("CleanupFrames", 30)

-- Timer de scan périodique pour les CompactRaidFrames
addon:ScheduleRepeatingTimer("RegisterCompactRaidFrames", 10)