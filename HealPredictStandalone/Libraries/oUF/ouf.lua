--[[
Minimal oUF Framework for HealPredictStandalone
Based on oUF but simplified for standalone use
]]

local addonName, ns = ...
local oUF = {}
ns.oUF = oUF

-- Private namespace
local Private = {}
oUF.Private = Private

-- Element management
local elements = {}
local callbacks = {}

-- Frame registry
local objects = {}
local activeElements = {}

-- Utility functions
local function argcheck(value, num, ...)
    if type(num) == 'number' then
        if select('#', ...) == 1 then
            return type(value) == select(1, ...)
        else
            for i = 1, select('#', ...) do
                if type(value) == select(i, ...) then
                    return true
                end
            end
        end
    end
end

local function error(...)
    return _G.error(...)
end

local function unitExists(unit)
    return UnitExists(unit) or string.match(unit, '^%w+target$') or string.match(unit, '^%w+pet$')
end

Private.argcheck = argcheck
Private.error = error
Private.unitExists = unitExists

-- Event handling
function oUF:RegisterEvent(event, func)
    if not self:IsEventRegistered(event) then
        self:RegisterEvent(event)
    end
    
    if func then
        callbacks[event] = func
    end
end

function oUF:UnregisterEvent(event, func)
    if self:IsEventRegistered(event) then
        self:UnregisterEvent(event)
    end
    
    callbacks[event] = nil
end

-- Element management
function oUF:AddElement(name, update, enable, disable)
    if not name then return end
    
    elements[name] = {
        update = update,
        enable = enable,
        disable = disable,
    }
end

function oUF:EnableElement(name)
    local element = elements[name]
    if element and element.enable then
        element.enable(self)
        activeElements[name] = true
        return true
    end
end

function oUF:DisableElement(name)
    local element = elements[name]
    if element and element.disable then
        element.disable(self)
        activeElements[name] = nil
        return true
    end
end

function oUF:IsElementEnabled(name)
    return activeElements[name] ~= nil
end

function oUF:UpdateElement(name)
    local element = elements[name]
    if element and element.update and activeElements[name] then
        return element.update(self)
    end
end

function oUF:UpdateAllElements(event)
    for name in pairs(activeElements) do
        self:UpdateElement(name)
    end
end

-- Frame creation
function oUF:Spawn(unit, name)
    local frame = CreateFrame('Button', name, UIParent, 'SecureUnitButtonTemplate')
    frame:SetAttribute('unit', unit)
    frame.unit = unit
    
    -- Add oUF methods to frame
    for key, value in pairs(self) do
        if type(value) == 'function' and key ~= 'Spawn' then
            frame[key] = value
        end
    end
    
    -- Initialize frame
    frame:SetScript('OnEvent', function(self, event, ...)
        if callbacks[event] then
            callbacks[event](self, event, ...)
        end
    end)
    
    -- Register frame
    objects[#objects + 1] = frame
    
    return frame
end

-- Global registration
_G.oUF = oUF