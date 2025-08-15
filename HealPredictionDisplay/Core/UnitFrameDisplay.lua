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
    
    -- Frames de raid compact
    for i = 1, 40 do
        local frame = _G["CompactRaidFrame" .. i]
        if frame then
            frame.unit = "raid" .. i
            self:RegisterFrame(frame)
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
    if not healthBar then return end
    
    -- Créer les barres de prediction
    local myHealBar, otherHealBar = self:CreateHealBars(frame, healthBar)
    if not myHealBar or not otherHealBar then return end
    
    -- Enregistrer le frame
    self.frames[frame] = {
        unit = frame.unit,
        unitName = UnitName(frame.unit),
        healthBar = healthBar,
        myHealBar = myHealBar,
        otherHealBar = otherHealBar,
        lastMyHeals = 0,
        lastOtherHeals = 0,
    }
    
    -- Mise à jour initiale
    self:UpdateHealPrediction(frame)
end

-- Trouver la barre de santé
function addon:FindHealthBar(frame)
    -- ElvUI
    if frame.Health then
        return frame.Health
    end
    
    -- Blizzard standard
    if frame.healthbar then
        return frame.healthbar
    end
    
    -- oUF générique
    if frame.Health then
        return frame.Health
    end
    
    -- Recherche par nom
    local frameName = frame:GetName()
    if frameName then
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
    
    -- Recherche récursive dans les enfants
    local children = {frame:GetChildren()}
    for _, child in ipairs(children) do
        if child:IsObjectType("StatusBar") then
            local name = child:GetName()
            if name and (name:find("Health") or name:find("health")) then
                return child
            end
        end
    end
    
    return nil
end

-- Créer les barres de prediction
function addon:CreateHealBars(frame, healthBar)
    local frameName = frame:GetName() or ("HealPredFrame" .. tostring(math.random(1000000)))
    
    -- Barre des mes heals
    local myHealBar = CreateFrame("StatusBar", frameName .. "_MyHealBar", healthBar)
    myHealBar:SetFrameLevel(healthBar:GetFrameLevel() + 1)
    
    -- Copier la texture de la barre de santé
    local healthTexture = healthBar:GetStatusBarTexture()
    if healthTexture then
        myHealBar:SetStatusBarTexture(healthTexture:GetTexture())
    else
        myHealBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    end
    
    local myColor = self.db.profile.myHealColor
    myHealBar:SetStatusBarColor(myColor.r, myColor.g, myColor.b, myColor.a)
    
    -- Barre des autres heals
    local otherHealBar = CreateFrame("StatusBar", frameName .. "_OtherHealBar", healthBar)
    otherHealBar:SetFrameLevel(healthBar:GetFrameLevel() + 1)
    
    if healthTexture then
        otherHealBar:SetStatusBarTexture(healthTexture:GetTexture())
    else
        otherHealBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    end
    
    local otherColor = self.db.profile.otherHealColor
    otherHealBar:SetStatusBarColor(otherColor.r, otherColor.g, otherColor.b, otherColor.a)
    
    -- Positionnement initial (sera mis à jour)
    myHealBar:SetAllPoints(healthBar)
    otherHealBar:SetAllPoints(healthBar)
    
    -- Masquer initialement
    myHealBar:Hide()
    otherHealBar:Hide()
    
    return myHealBar, otherHealBar
end

-- Mise à jour de la prediction pour un frame
function addon:UpdateHealPrediction(frame)
    local data = self.frames[frame]
    if not data or not frame.unit then return end
    
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

-- Timer de nettoyage périodique
addon:ScheduleRepeatingTimer("CleanupFrames", 30)