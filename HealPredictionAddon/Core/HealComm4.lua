--[[
	HealPredictionAddon - HealComm4 Element
	Adapted from ElvUI oUF_HealComm4 plugin and ElvUI HealComm implementation
	
	This implements a proper HealComm4 element for oUF-style unit frames
]]

local addon_name = "HealPredictionAddon"
local HealPredictionAddon = _G[addon_name] or {}
_G[addon_name] = HealPredictionAddon

-- Get LibHealComm-4.0
local HealComm = LibStub:GetLibrary("LibHealComm-4.0")
if not HealComm then
	error(addon_name .. ": LibHealComm-4.0 not found")
	return
end

-- WoW API
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitGUID = UnitGUID
local GetTime = GetTime
local CreateFrame = CreateFrame

-- Configuration
local config = {
	colors = {
		healPrediction = {
			personal = {r = 0, g = 0.827, b = 0.765, a = 0.25}, -- Teal for personal heals
			others = {r = 0, g = 0.631, b = 0.557, a = 0.25},   -- Darker teal for other heals
			maxOverflow = 0 -- No overflow by default
		}
	}
}

-- Store enabled frames
local enabledFrames = {}
local callbacksRegistered = false

-- Update function for a single frame
local function UpdateHealPrediction(frame)
	local unit = frame.unit
	if not unit then return end
	
	local element = frame.HealCommBar
	if not element then return end
	
	-- Pre-update callback
	if element.PreUpdate then
		element:PreUpdate(unit)
	end
	
	-- Get heal amounts using our API
	local myIncomingHeal = UnitGetIncomingHeals(unit, "player") or 0
	local allIncomingHeal = UnitGetIncomingHeals(unit) or 0
	local health = UnitHealth(unit)
	local maxHealth = UnitHealthMax(unit)
	
	if maxHealth <= 0 then
		-- Hide bars if no max health
		if element.myBar then element.myBar:Hide() end
		if element.otherBar then element.otherBar:Hide() end
		return
	end
	
	-- Calculate overflow and other incoming heals
	local maxOverflowHP = maxHealth * element.maxOverflow
	local otherIncomingHeal = 0
	
	-- Apply overflow limit
	if health + allIncomingHeal > maxOverflowHP then
		allIncomingHeal = maxOverflowHP - health
	end
	
	-- Calculate split between my heals and others
	if allIncomingHeal < myIncomingHeal then
		myIncomingHeal = allIncomingHeal
	else
		otherIncomingHeal = allIncomingHeal - myIncomingHeal
	end
	
	-- Update my heal bar
	if element.myBar then
		if myIncomingHeal > 0 then
			element.myBar:SetMinMaxValues(0, maxHealth)
			element.myBar:SetValue(myIncomingHeal)
			element.myBar:Show()
		else
			element.myBar:Hide()
		end
	end
	
	-- Update other heal bar  
	if element.otherBar then
		if otherIncomingHeal > 0 then
			element.otherBar:SetMinMaxValues(0, maxHealth)
			element.otherBar:SetValue(otherIncomingHeal)
			element.otherBar:Show()
		else
			element.otherBar:Hide()
		end
	end
	
	-- Post-update callback
	if element.PostUpdate then
		element:PostUpdate(unit, myIncomingHeal, otherIncomingHeal)
	end
end

-- LibHealComm callback function
local function OnHealCommUpdate(...)
	local updatedUnits = {...}
	local units = {}
	
	-- Create lookup table of updated unit names
	for _, unitName in pairs(updatedUnits) do
		units[unitName] = true
	end
	
	-- Update all enabled frames for matching units
	for frame in pairs(enabledFrames) do
		if frame.unit and frame:IsVisible() then
			-- Check if this unit was updated by matching unit name
			local unitName = UnitName(frame.unit)
			if unitName and units[unitName] then
				UpdateHealPrediction(frame)
			end
		end
	end
end

-- Enable HealComm4 element on a frame
local function EnableHealComm4(frame)
	local element = frame.HealCommBar
	if not element then return end
	
	-- Set default values
	element.maxOverflow = element.maxOverflow or (1 + (config.colors.healPrediction.maxOverflow or 0))
	element.__owner = frame
	
	-- Set default textures if none set
	if element.myBar and element.myBar:IsObjectType("StatusBar") and not element.myBar:GetStatusBarTexture() then
		element.myBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	end
	
	if element.otherBar and element.otherBar:IsObjectType("StatusBar") and not element.otherBar:GetStatusBarTexture() then
		element.otherBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	end
	
	-- Set colors
	local c = config.colors.healPrediction
	if element.myBar then
		element.myBar:SetStatusBarColor(c.personal.r, c.personal.g, c.personal.b, c.personal.a)
	end
	if element.otherBar then
		element.otherBar:SetStatusBarColor(c.others.r, c.others.g, c.others.b, c.others.a)
	end
	
	-- Register frame for updates
	enabledFrames[frame] = true
	
	-- Register callbacks if this is the first frame
	if not callbacksRegistered and HealComm then
		HealComm.RegisterCallback(addon_name, "HealComm_HealStarted", OnHealCommUpdate)
		HealComm.RegisterCallback(addon_name, "HealComm_HealUpdated", OnHealCommUpdate)  
		HealComm.RegisterCallback(addon_name, "HealComm_HealDelayed", OnHealCommUpdate)
		HealComm.RegisterCallback(addon_name, "HealComm_HealStopped", OnHealCommUpdate)
		HealComm.RegisterCallback(addon_name, "HealComm_ModifierChanged", OnHealCommUpdate)
		HealComm.RegisterCallback(addon_name, "HealComm_GUIDDisappeared", OnHealCommUpdate)
		callbacksRegistered = true
	end
	
	-- Add ForceUpdate function to element
	element.ForceUpdate = function()
		UpdateHealPrediction(frame)
	end
	
	-- Register for unit events
	if frame.RegisterEvent then
		frame:RegisterEvent("UNIT_HEALTH")
		frame:RegisterEvent("UNIT_MAXHEALTH")
	end
	
	return true
end

-- Disable HealComm4 element on a frame
local function DisableHealComm4(frame)
	local element = frame.HealCommBar
	if not element then return end
	
	-- Hide bars
	if element.myBar then element.myBar:Hide() end
	if element.otherBar then element.otherBar:Hide() end
	
	-- Unregister frame
	enabledFrames[frame] = nil
	
	-- Unregister callbacks if no more frames
	if callbacksRegistered and not next(enabledFrames) and HealComm then
		HealComm.UnregisterCallback(addon_name, "HealComm_HealStarted")
		HealComm.UnregisterCallback(addon_name, "HealComm_HealUpdated")
		HealComm.UnregisterCallback(addon_name, "HealComm_HealDelayed") 
		HealComm.UnregisterCallback(addon_name, "HealComm_HealStopped")
		HealComm.UnregisterCallback(addon_name, "HealComm_ModifierChanged")
		HealComm.UnregisterCallback(addon_name, "HealComm_GUIDDisappeared")
		callbacksRegistered = false
	end
	
	-- Unregister events
	if frame.UnregisterEvent then
		frame:UnregisterEvent("UNIT_HEALTH")
		frame:UnregisterEvent("UNIT_MAXHEALTH")
	end
end

-- Public API functions
HealPredictionAddon.EnableHealComm4 = EnableHealComm4
HealPredictionAddon.DisableHealComm4 = DisableHealComm4
HealPredictionAddon.UpdateHealPrediction = UpdateHealPrediction
HealPredictionAddon.config = config

-- Export enabledFrames for access from other modules
HealPredictionAddon.enabledFrames = enabledFrames