--[[
	HealPredictionDisplay - Configuration
	Interface de configuration pour l'addon
]]

local addon = HealPredictionDisplay

-- Commandes slash
SLASH_HEALPREDICTIONDISPLAY1 = "/hpd"
SLASH_HEALPREDICTIONDISPLAY2 = "/healpred"
SLASH_HEALPREDICTIONDISPLAY3 = "/healprediction"

SlashCmdList["HEALPREDICTIONDISPLAY"] = function(msg)
    addon:SlashCommand(msg)
end

-- Gestionnaire de commandes
function addon:SlashCommand(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()
    
    if cmd == "toggle" then
        addon:ToggleAddon()
    elseif cmd == "config" or cmd == "options" then
        addon:OpenConfig()
    elseif cmd == "reload" then
        addon:ReloadFrames()
    elseif cmd == "status" then
        addon:ShowStatus()
    elseif cmd == "reset" then
        addon:ResetConfig()
    elseif cmd == "colors" then
        addon:ShowColorCommands()
    elseif cmd == "mycolor" and arg then
        addon:SetMyHealColorFromString(arg)
    elseif cmd == "othercolor" and arg then
        addon:SetOtherHealColorFromString(arg)
    elseif cmd == "overflow" and arg then
        addon:SetMaxOverflow(tonumber(arg))
    elseif cmd == "rate" and arg then
        addon:SetUpdateRate(tonumber(arg))
    elseif cmd == "units" then
        addon:ShowUnitsConfig()
    elseif cmd == "unit" and arg then
        addon:ToggleUnit(arg)
    else
        addon:ShowHelp()
    end
end

-- Fonctions de commande
function addon:ToggleAddon()
    self.db.profile.enabled = not self.db.profile.enabled
    local status = self.db.profile.enabled and "activé" or "désactivé"
    print("|cff1784d1HealPredictionDisplay:|r " .. status)
    
    if self.db.profile.enabled then
        self:StartUpdateTimer()
    else
        self:StopUpdateTimer()
    end
    
    self:UpdateAllFrames()
end

function addon:OpenConfig()
    -- Interface de configuration simple
    print("|cff1784d1HealPredictionDisplay - Configuration:|r")
    print("  |cffFFD100Enabled:|r " .. (self.db.profile.enabled and "Oui" or "Non"))
    print("  |cffFFD100Show My Heals:|r " .. (self.db.profile.showMyHeals and "Oui" or "Non"))
    print("  |cffFFD100Show Other Heals:|r " .. (self.db.profile.showOtherHeals and "Oui" or "Non"))
    print("  |cffFFD100Max Overflow:|r " .. (self.db.profile.maxOverflow * 100) .. "%")
    print("  |cffFFD100Update Rate:|r " .. self.db.profile.updateRate .. "s")
    
    local myColor = self.db.profile.myHealColor
    local otherColor = self.db.profile.otherHealColor
    print("  |cffFFD100My Heal Color:|r " .. string.format("%.2f, %.2f, %.2f, %.2f", myColor.r, myColor.g, myColor.b, myColor.a))
    print("  |cffFFD100Other Heal Color:|r " .. string.format("%.2f, %.2f, %.2f, %.2f", otherColor.r, otherColor.g, otherColor.b, otherColor.a))
    
    print("|cffffff00Utilisez /hpd help pour voir toutes les commandes|r")
end

function addon:ReloadFrames()
    -- Nettoyer les frames existants
    for frame, data in pairs(self.frames) do
        if data.myHealBar then
            data.myHealBar:Hide()
            data.myHealBar:SetParent(nil)
        end
        if data.otherHealBar then
            data.otherHealBar:Hide()
            data.otherHealBar:SetParent(nil)
        end
    end
    
    -- Vider la liste
    self.frames = {}
    
    -- Rescanner
    self:ScanForFrames()
    print("|cff1784d1HealPredictionDisplay:|r Frames rechargés")
end

function addon:ShowStatus()
    print("|cff1784d1HealPredictionDisplay - Statut:|r")
    print("  |cffFFD100Version:|r " .. self.version)
    print("  |cffFFD100Enabled:|r " .. (self.db.profile.enabled and "Oui" or "Non"))
    print("  |cffFFD100Frames enregistrés:|r " .. self:CountFrames())
    print("  |cffFFD100HealPredict trouvé:|r " .. (HealPredict and "Oui" or "Non"))
    print("  |cffFFD100LibHealComm trouvé:|r " .. (LibStub and LibStub("LibHealComm-4.0", true) and "Oui" or "Non"))
    print("  |cffFFD100ElvUI détecté:|r " .. (ElvUI and "Oui" or "Non"))
    print("  |cffFFD100oUF détecté:|r " .. (oUF and "Oui" or "Non"))
end

function addon:ResetConfig()
    self.db:ResetProfile()
    self:ReloadFrames()
    print("|cff1784d1HealPredictionDisplay:|r Configuration réinitialisée")
end

function addon:ShowHelp()
    print("|cff1784d1HealPredictionDisplay - Commandes:|r")
    print("  |cffFFD100/hpd toggle|r - Activer/désactiver l'addon")
    print("  |cffFFD100/hpd config|r - Afficher la configuration")
    print("  |cffFFD100/hpd reload|r - Recharger les frames")
    print("  |cffFFD100/hpd status|r - Afficher le statut")
    print("  |cffFFD100/hpd reset|r - Réinitialiser la configuration")
    print("  |cffFFD100/hpd colors|r - Commandes de couleurs")
    print("  |cffFFD100/hpd units|r - Configuration des unités")
    print("  |cffFFD100/hpd overflow <nombre>|r - Définir l'overflow max (ex: 1.1)")
    print("  |cffFFD100/hpd rate <nombre>|r - Définir le taux de mise à jour (ex: 0.1)")
    print("  |cffFFD100/hpd help|r - Afficher cette aide")
end

function addon:ShowColorCommands()
    print("|cff1784d1HealPredictionDisplay - Commandes de couleurs:|r")
    print("  |cffFFD100/hpd mycolor <r> <g> <b> [a]|r - Couleur de mes heals (0-1)")
    print("  |cffFFD100/hpd othercolor <r> <g> <b> [a]|r - Couleur des autres heals (0-1)")
    print("  |cffffff00Exemples:|r")
    print("    /hpd mycolor 0 0.8 0.7 - Teal")
    print("    /hpd othercolor 0.8 0.8 0 0.6 - Jaune transparent")
end

function addon:ShowUnitsConfig()
    print("|cff1784d1HealPredictionDisplay - Configuration des unités:|r")
    for unit, enabled in pairs(self.db.profile.units) do
        local status = enabled and "|cff00ff00Activé|r" or "|cffff0000Désactivé|r"
        print("  |cffFFD100" .. unit .. ":|r " .. status)
    end
    print("  |cffffff00Utilisez /hpd unit <nom> pour basculer une unité|r")
end

function addon:ToggleUnit(unitName)
    unitName = unitName:lower()
    if self.db.profile.units[unitName] ~= nil then
        self.db.profile.units[unitName] = not self.db.profile.units[unitName]
        local status = self.db.profile.units[unitName] and "activé" or "désactivé"
        print("|cff1784d1HealPredictionDisplay:|r Unité '" .. unitName .. "' " .. status)
        self:ReloadFrames()
    else
        print("|cffff0000Erreur:|r Unité '" .. unitName .. "' non reconnue")
        print("Unités disponibles: player, target, focus, pet, party, raid")
    end
end

-- Configuration avancée via variables
function addon:SetMyHealColor(r, g, b, a)
    self.db.profile.myHealColor = {r = r, g = g, b = b, a = a or 0.8}
    self:UpdateAllFrameColors()
    print("|cff1784d1HealPredictionDisplay:|r Couleur de mes heals mise à jour")
end

function addon:SetOtherHealColor(r, g, b, a)
    self.db.profile.otherHealColor = {r = r, g = g, b = b, a = a or 0.8}
    self:UpdateAllFrameColors()
    print("|cff1784d1HealPredictionDisplay:|r Couleur des autres heals mise à jour")
end

function addon:SetMyHealColorFromString(argString)
    local r, g, b, a = argString:match("([%d%.]+)%s+([%d%.]+)%s+([%d%.]+)%s*([%d%.]*)") 
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    a = tonumber(a) or 0.8
    
    if r and g and b and r >= 0 and r <= 1 and g >= 0 and g <= 1 and b >= 0 and b <= 1 then
        self:SetMyHealColor(r, g, b, a)
    else
        print("|cffff0000Erreur:|r Format invalide. Utilisez: /hpd mycolor <r> <g> <b> [a] (valeurs entre 0 et 1)")
    end
end

function addon:SetOtherHealColorFromString(argString)
    local r, g, b, a = argString:match("([%d%.]+)%s+([%d%.]+)%s+([%d%.]+)%s*([%d%.]*)") 
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    a = tonumber(a) or 0.8
    
    if r and g and b and r >= 0 and r <= 1 and g >= 0 and g <= 1 and b >= 0 and b <= 1 then
        self:SetOtherHealColor(r, g, b, a)
    else
        print("|cffff0000Erreur:|r Format invalide. Utilisez: /hpd othercolor <r> <g> <b> [a] (valeurs entre 0 et 1)")
    end
end

function addon:SetMaxOverflow(overflow)
    if overflow and overflow >= 1 and overflow <= 2 then
        self.db.profile.maxOverflow = overflow
        print("|cff1784d1HealPredictionDisplay:|r Overflow maximum défini à " .. (overflow * 100) .. "%")
        self:UpdateAllFrames()
    else
        print("|cffff0000Erreur:|r Overflow doit être entre 1.0 et 2.0")
    end
end

function addon:SetUpdateRate(rate)
    if rate and rate >= 0.05 and rate <= 1 then
        self.db.profile.updateRate = rate
        print("|cff1784d1HealPredictionDisplay:|r Taux de mise à jour défini à " .. rate .. "s")
        self:StopUpdateTimer()
        self:StartUpdateTimer()
    else
        print("|cffff0000Erreur:|r Le taux doit être entre 0.05 et 1.0")
    end
end

-- Mettre à jour les couleurs de tous les frames
function addon:UpdateAllFrameColors()
    local myColor = self.db.profile.myHealColor
    local otherColor = self.db.profile.otherHealColor
    
    for frame, data in pairs(self.frames) do
        if data.myHealBar then
            data.myHealBar:SetStatusBarColor(myColor.r, myColor.g, myColor.b, myColor.a)
        end
        if data.otherHealBar then
            data.otherHealBar:SetStatusBarColor(otherColor.r, otherColor.g, otherColor.b, otherColor.a)
        end
    end
end

-- Fonctions de configuration pour d'autres addons
function addon:ToggleMyHeals()
    self.db.profile.showMyHeals = not self.db.profile.showMyHeals
    local status = self.db.profile.showMyHeals and "activé" or "désactivé"
    print("|cff1784d1HealPredictionDisplay:|r Affichage de mes heals " .. status)
    self:UpdateAllFrames()
end

function addon:ToggleOtherHeals()
    self.db.profile.showOtherHeals = not self.db.profile.showOtherHeals
    local status = self.db.profile.showOtherHeals and "activé" or "désactivé"
    print("|cff1784d1HealPredictionDisplay:|r Affichage des autres heals " .. status)
    self:UpdateAllFrames()
end

-- Interface pour les autres addons
HealPredictionDisplayAPI = {
    ToggleAddon = function() return addon:ToggleAddon() end,
    ToggleMyHeals = function() return addon:ToggleMyHeals() end,
    ToggleOtherHeals = function() return addon:ToggleOtherHeals() end,
    SetMyHealColor = function(r, g, b, a) return addon:SetMyHealColor(r, g, b, a) end,
    SetOtherHealColor = function(r, g, b, a) return addon:SetOtherHealColor(r, g, b, a) end,
    SetMaxOverflow = function(overflow) return addon:SetMaxOverflow(overflow) end,
    SetUpdateRate = function(rate) return addon:SetUpdateRate(rate) end,
    ReloadFrames = function() return addon:ReloadFrames() end,
    GetStatus = function() 
        return {
            enabled = addon.db.profile.enabled,
            frames = addon:CountFrames(),
            version = addon.version
        }
    end
}