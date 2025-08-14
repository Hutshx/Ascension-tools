--[[
	HealPredictionAddon - Core Heal Prediction API
	Adapted from !!!ClassicAPI/Util/HealPrediction.lua and UnitFrameLayers/UnitFrame.lua
	
	This module provides the core heal prediction functionality using LibHealComm-4.0
]]

local LibStub = LibStub
local GetTime = GetTime
local UnitGUID = UnitGUID
local UnitName = UnitName

-- Initialize LibHealComm-4.0
local HealComm = LibStub:GetLibrary("LibHealComm-4.0")
local HEALCOMM = HealComm
local HEALCOMM_PLAYER_GUID

--[[
	CORE API FUNCTIONS
]]

-- Get incoming heals for a unit
function UnitGetIncomingHeals(unit, healer)
	if not ( unit and HEALCOMM ) then
		return
	end

	if ( healer ) then
		return HEALCOMM:GetCasterHealAmount(UnitGUID(healer), HEALCOMM.CASTED_HEALS, GetTime() + 5)
	else
		return HEALCOMM:GetHealAmount(UnitGUID(unit), HEALCOMM.ALL_HEALS, GetTime() + 5)
	end
end

-- Stub functions for absorb functionality (not used in heal prediction)
function UnitGetTotalAbsorbs(Unit)
	return 0
end

function UnitGetTotalHealAbsorbs(Unit)
	return 0
end