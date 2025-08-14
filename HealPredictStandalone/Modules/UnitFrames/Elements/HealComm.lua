--[[
HealPredictStandalone - HealComm Elements
UI element construction and management for heal prediction
]]

local addonName = "HealPredictStandalone"
local HPS = _G[addonName]

-- Element namespace
local HealComm = {}
HPS.HealComm = HealComm

-- Dependencies
local healpredict = _G.HealPredict

local function Debug(msg)
    if HPS.Debug then
        HPS.Debug("HealComm: " .. msg)
    end
end

-- Create heal prediction bars with advanced positioning
function HealComm:CreateBars(parent, healthBar, unit)
    if not parent or not healthBar or not unit then return nil end
    
    Debug("Creating heal bars for unit: " .. unit)
    
    -- Create status bars
    local myBar = CreateFrame("StatusBar", nil, healthBar)
    local otherBar = CreateFrame("StatusBar", nil, healthBar) 
    
    -- Set frame levels above health bar
    local baseLevel = healthBar:GetFrameLevel() or 0
    myBar:SetFrameLevel(baseLevel + 2)
    otherBar:SetFrameLevel(baseLevel + 3)
    
    -- Configure textures
    local texture = healthBar:GetStatusBarTexture()
    if texture then
        local texturePath = texture:GetTexture()
        if texturePath then
            myBar:SetStatusBarTexture(texturePath)
            otherBar:SetStatusBarTexture(texturePath)
        else
            myBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
            otherBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        end
    else
        myBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar") 
        otherBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    end
    
    -- Set colors from config
    local myColor = HPS.db.colors.myHeals
    local otherColor = HPS.db.colors.otherHeals
    
    myBar:SetStatusBarColor(myColor[1], myColor[2], myColor[3], myColor[4])
    otherBar:SetStatusBarColor(otherColor[1], otherColor[2], otherColor[3], otherColor[4])
    
    -- Set initial alpha
    myBar:SetAlpha(0.8)
    otherBar:SetAlpha(0.8)
    
    -- Create element data structure
    local element = {
        myBar = myBar,
        otherBar = otherBar,
        maxOverflow = HPS.db.maxOverflow or 1.05,
        unit = unit,
        parent = parent,
        healthBar = healthBar,
        
        -- State tracking
        isEnabled = false,
        lastUpdate = 0,
        
        -- Methods
        Update = function(self)
            HealComm:UpdateElement(self)
        end,
        
        Enable = function(self)
            HealComm:EnableElement(self)
        end,
        
        Disable = function(self)
            HealComm:DisableElement(self)
        end,
        
        Configure = function(self)
            HealComm:ConfigureElement(self)
        end,
    }
    
    -- Initial configuration
    self:ConfigureElement(element)
    
    return element
end

-- Configure element positioning and sizing
function HealComm:ConfigureElement(element)
    if not element then return end
    
    local healthBar = element.healthBar
    local myBar = element.myBar
    local otherBar = element.otherBar
    
    -- Get health bar dimensions and orientation
    local orientation = "HORIZONTAL"
    if healthBar.GetOrientation then
        orientation = healthBar:GetOrientation()
    end
    
    local width = healthBar:GetWidth()
    local height = healthBar:GetHeight()
    
    -- Set bar orientation
    myBar:SetOrientation(orientation)
    otherBar:SetOrientation(orientation)
    
    if orientation == "HORIZONTAL" then
        -- Position bars to the right of health bar
        myBar:SetPoint("TOPLEFT", healthBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
        myBar:SetPoint("BOTTOMLEFT", healthBar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
        myBar:SetWidth(width * 0.5) -- Allow up to 50% overflow
        
        otherBar:SetPoint("TOPLEFT", myBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
        otherBar:SetPoint("BOTTOMLEFT", myBar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
        otherBar:SetWidth(width * 0.3) -- Allow up to 30% additional overflow
        
    else
        -- Vertical orientation - position bars above health bar
        myBar:SetPoint("BOTTOMLEFT", healthBar:GetStatusBarTexture(), "TOPLEFT", 0, 0)
        myBar:SetPoint("BOTTOMRIGHT", healthBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
        myBar:SetHeight(height * 0.5)
        
        otherBar:SetPoint("BOTTOMLEFT", myBar:GetStatusBarTexture(), "TOPLEFT", 0, 0)
        otherBar:SetPoint("BOTTOMRIGHT", myBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
        otherBar:SetHeight(height * 0.3)
    end
    
    Debug("Configured element for unit: " .. element.unit)
end

-- Update heal prediction values
function HealComm:UpdateElement(element)
    if not element or not element.unit then return end
    
    local unit = element.unit
    local myIncomingHeal = 0
    local allIncomingHeal = 0
    
    -- Get heal predictions
    if healpredict then
        myIncomingHeal = healpredict.UnitGetIncomingHeals(unit, UnitName("player")) or 0
        allIncomingHeal = healpredict.UnitGetIncomingHeals(unit) or 0
    end
    
    -- Get current health values
    local health = UnitHealth(unit) or 0
    local maxHealth = UnitHealthMax(unit) or 1
    local maxOverflowHP = maxHealth * element.maxOverflow
    
    -- Calculate other heals
    local otherIncomingHeal = math.max(0, allIncomingHeal - myIncomingHeal)
    
    -- Apply overflow limits
    if health + allIncomingHeal > maxOverflowHP then
        local excessHeal = (health + allIncomingHeal) - maxOverflowHP
        if myIncomingHeal > excessHeal then
            myIncomingHeal = myIncomingHeal - excessHeal
            allIncomingHeal = maxOverflowHP - health
        else
            otherIncomingHeal = math.max(0, otherIncomingHeal - excessHeal)
            allIncomingHeal = maxOverflowHP - health
            myIncomingHeal = 0
        end
    end
    
    -- Update bars
    if element.myBar then
        element.myBar:SetMinMaxValues(0, maxHealth)
        element.myBar:SetValue(myIncomingHeal)
        
        if myIncomingHeal > 0 then
            element.myBar:Show()
        else
            element.myBar:Hide()
        end
    end
    
    if element.otherBar then
        element.otherBar:SetMinMaxValues(0, maxHealth)
        element.otherBar:SetValue(otherIncomingHeal)
        
        if otherIncomingHeal > 0 then
            element.otherBar:Show()
        else
            element.otherBar:Hide()
        end
    end
    
    element.lastUpdate = GetTime()
end

-- Enable element
function HealComm:EnableElement(element)
    if not element or element.isEnabled then return end
    
    element.isEnabled = true
    
    -- Show bars if they have values
    self:UpdateElement(element)
    
    Debug("Enabled element for unit: " .. element.unit)
end

-- Disable element  
function HealComm:DisableElement(element)
    if not element or not element.isEnabled then return end
    
    element.isEnabled = false
    
    -- Hide bars
    if element.myBar then
        element.myBar:Hide()
    end
    
    if element.otherBar then
        element.otherBar:Hide()
    end
    
    Debug("Disabled element for unit: " .. element.unit)
end

-- Update colors from configuration
function HealComm:UpdateColors()
    Debug("Updating heal prediction colors")
    -- This would be called when colors change in config
end

-- Get element statistics
function HealComm:GetElementStats(element)
    if not element then return nil end
    
    return {
        unit = element.unit,
        isEnabled = element.isEnabled,
        lastUpdate = element.lastUpdate,
        maxOverflow = element.maxOverflow,
    }
end