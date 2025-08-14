--[[
	HealPredictionAddon - Core Heal Prediction API
	Adapted from !!!ClassicAPI/Util/HealPrediction.lua and UnitFrameLayers/UnitFrame.lua
	
	This module provides the core heal prediction functionality using LibHealComm-4.0
	Compatible with WoW Ascension API
]]

local LibStub = LibStub
local GetTime = GetTime
local UnitGUID = UnitGUID
local UnitName = UnitName

-- Initialize LibHealComm-4.0
local HealComm = LibStub:GetLibrary("LibHealComm-4.0")
local HEALCOMM = HealComm

--[[
	CORE API FUNCTIONS
]]

-- Get incoming heals for a unit
function UnitGetIncomingHeals(unit, healer)
	if not (unit and HEALCOMM) then
		return 0
	end

	local unitGUID = UnitGUID(unit)
	if not unitGUID then
		return 0
	end

	if healer then
		local healerGUID = UnitGUID(healer)
		if not healerGUID then
			return 0
		end
		-- Get heals from a specific healer
		return HEALCOMM:GetCasterHealAmount(healerGUID, HEALCOMM.CASTED_HEALS, GetTime() + 10) or 0
	else
		-- Get all incoming heals for the unit
		return HEALCOMM:GetHealAmount(unitGUID, HEALCOMM.ALL_HEALS, GetTime() + 10) or 0
	end
end

-- Stub functions for absorb functionality (not available in WotLK/Ascension)
function UnitGetTotalAbsorbs(unit)
	return 0
end

function UnitGetTotalHealAbsorbs(unit)
	return 0
end

-- Missing API function stubs for Ascension compatibility
-- These functions are missing from Ascension but may be referenced
function UnitIsControlled(unit)
	-- Stub implementation - assume not controlled if function doesn't exist
	return false
end

function UnitIsDisarmed(unit)
	-- Stub implementation - assume not disarmed if function doesn't exist  
	return false
end

-- Export API functions globally for compatibility
_G.UnitGetIncomingHeals = UnitGetIncomingHeals
_G.UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
_G.UnitGetTotalHealAbsorbs = UnitGetTotalHealAbsorbs

-- Export missing function stubs
if not _G.UnitIsControlled then
	_G.UnitIsControlled = UnitIsControlled
end
if not _G.UnitIsDisarmed then
	_G.UnitIsDisarmed = UnitIsDisarmed
end