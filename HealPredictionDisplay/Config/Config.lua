--[[
	HealPredictionDisplay - Configuration
]]

local addon = HealPredictionDisplay

-- Configuration par défaut
addon.defaults = {
    profile = {
        enabled = true,
        debug = false, -- OPTION DEBUG AJOUTÉE
        
        -- Couleurs
        myHealColor = { r = 0, g = 1, b = 0, a = 0.6 },      -- Vert pour mes heals
        otherHealColor = { r = 0, g = 0.8, b = 1, a = 0.4 }, -- Bleu pour les autres heals
        
        -- Types d'unités à suivre
        units = {
            player = true,
            target = true,
            focus = true,
            pet = true,
            party = true,
            raid = true,
        },
        
        -- Types de heals à afficher
        showMyHeals = true,
        showOtherHeals = true,
        
        -- Options d'affichage
        showOverheals = true,
        maxHealWidth = 200,
        minHealAmount = 1,
        
        -- Performance
        updateFrequency = 0.1,
        maxFrames = 100,
    }
}

-- Interface de configuration
function addon:SetupConfig()
    local AceConfig = LibStub("AceConfig-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    
    local options = {
        name = "HealPredictionDisplay",
        handler = addon,
        type = "group",
        args = {
            general = {
                type = "group",
                name = "Général",
                order = 1,
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Activé",
                        desc = "Active ou désactive l'addon",
                        get = "GetEnabled",
                        set = "SetEnabled",
                        order = 1,
                    },
                    debug = {
                        type = "toggle",
                        name = "Mode Debug",
                        desc = "Active les messages de debug dans le chat",
                        get = "GetDebug",
                        set = "SetDebug",
                        order = 2,
                    },
                    separator1 = {
                        type = "header",
                        name = "Types de heals",
                        order = 10,
                    },
                    showMyHeals = {
                        type = "toggle",
                        name = "Afficher mes heals",
                        desc = "Affiche la prediction de vos propres heals",
                        get = "GetShowMyHeals",
                        set = "SetShowMyHeals",
                        order = 11,
                    },
                    showOtherHeals = {
                        type = "toggle",
                        name = "Afficher les heals des autres",
                        desc = "Affiche la prediction des heals des autres joueurs",
                        get = "GetShowOtherHeals",
                        set = "SetShowOtherHeals",
                        order = 12,
                    },
                }
            },
            colors = {
                type = "group",
                name = "Couleurs",
                order = 2,
                args = {
                    myHealColor = {
                        type = "color",
                        name = "Couleur de mes heals",
                        desc = "Couleur pour la prediction de vos heals",
                        hasAlpha = true,
                        get = "GetMyHealColor",
                        set = "SetMyHealColor",
                        order = 1,
                    },
                    otherHealColor = {
                        type = "color",
                        name = "Couleur des heals des autres",
                        desc = "Couleur pour la prediction des heals des autres",
                        hasAlpha = true,
                        get = "GetOtherHealColor",
                        set = "SetOtherHealColor",
                        order = 2,
                    },
                }
            },
            units = {
                type = "group",
                name = "Unités",
                order = 3,
                args = {
                    player = {
                        type = "toggle",
                        name = "Joueur",
                        desc = "Afficher sur le frame du joueur",
                        get = function() return addon.db.profile.units.player end,
                        set = function(_, val) addon.db.profile.units.player = val end,
                        order = 1,
                    },
                    target = {
                        type = "toggle",
                        name = "Cible",
                        desc = "Afficher sur le frame de la cible",
                        get = function() return addon.db.profile.units.target end,
                        set = function(_, val) addon.db.profile.units.target = val end,
                        order = 2,
                    },
                    focus = {
                        type = "toggle",
                        name = "Focus",
                        desc = "Afficher sur le frame de focus",
                        get = function() return addon.db.profile.units.focus end,
                        set = function(_, val) addon.db.profile.units.focus = val end,
                        order = 3,
                    },
                    pet = {
                        type = "toggle",
                        name = "Familier",
                        desc = "Afficher sur le frame du familier",
                        get = function() return addon.db.profile.units.pet end,
                        set = function(_, val) addon.db.profile.units.pet = val end,
                        order = 4,
                    },
                    party = {
                        type = "toggle",
                        name = "Groupe",
                        desc = "Afficher sur les frames de groupe",
                        get = function() return addon.db.profile.units.party end,
                        set = function(_, val) addon.db.profile.units.party = val end,
                        order = 5,
                    },
                    raid = {
                        type = "toggle",
                        name = "Raid",
                        desc = "Afficher sur les frames de raid",
                        get = function() return addon.db.profile.units.raid end,
                        set = function(_, val) addon.db.profile.units.raid = val end,
                        order = 6,
                    },
                }
            },
        }
    }
    
    AceConfig:RegisterOptionsTable("HealPredictionDisplay", options)
    AceConfigDialog:AddToBlizOptions("HealPredictionDisplay", "HealPredictionDisplay")
    
    -- Commande slash
    self:RegisterChatCommand("hpd", "SlashCommand")
    self:RegisterChatCommand("healprediction", "SlashCommand")
end

-- Fonctions get/set pour les options
function addon:GetEnabled()
    return self.db.profile.enabled
end

function addon:SetEnabled(_, value)
    self.db.profile.enabled = value
    if value then
        self:Enable()
    else
        self:Disable()
    end
end

function addon:GetDebug()
    return self.db.profile.debug
end

function addon:SetDebug(_, value)
    self.db.profile.debug = value
    print("|cff1784d1HealPredictionDisplay:|r Mode debug " .. (value and "activé" or "désactivé"))
end

function addon:GetShowMyHeals()
    return self.db.profile.showMyHeals
end

function addon:SetShowMyHeals(_, value)
    self.db.profile.showMyHeals = value
end

function addon:GetShowOtherHeals()
    return self.db.profile.showOtherHeals
end

function addon:SetShowOtherHeals(_, value)
    self.db.profile.showOtherHeals = value
end

function addon:GetMyHealColor()
    local color = self.db.profile.myHealColor
    return color.r, color.g, color.b, color.a
end

function addon:SetMyHealColor(_, r, g, b, a)
    local color = self.db.profile.myHealColor
    color.r, color.g, color.b, color.a = r, g, b, a
end

function addon:GetOtherHealColor()
    local color = self.db.profile.otherHealColor
    return color.r, color.g, color.b, color.a
end

function addon:SetOtherHealColor(_, r, g, b, a)
    local color = self.db.profile.otherHealColor
    color.r, color.g, color.b, color.a = r, g, b, a
end

-- Commande slash
function addon:SlashCommand(input)
    if input == "" then
        LibStub("AceConfigDialog-3.0"):Open("HealPredictionDisplay")
    elseif input == "debug" then
        self.db.profile.debug = not self.db.profile.debug
        print("|cff1784d1HealPredictionDisplay:|r Mode debug " .. (self.db.profile.debug and "activé" or "désactivé"))
    elseif input == "scan" then
        self:ScanForFrames()
    elseif input == "count" then
        print("|cff1784d1HealPredictionDisplay:|r " .. self:CountFrames() .. " frames enregistrés")
    else
        print("|cff1784d1HealPredictionDisplay:|r Commandes disponibles:")
        print("  /hpd - Ouvre les options")
        print("  /hpd debug - Active/désactive le debug")
        print("  /hpd scan - Rescanne les frames")
        print("  /hpd count - Affiche le nombre de frames")
    end
end