--[[
	HealPredictionAddon - Configuration
	
	This module provides configuration options for heal prediction
]]

local addon_name = "HealPredictionAddon"
local HealPredictionAddon = _G[addon_name] or {}

-- Default configuration
local defaultConfig = {
	colors = {
		healPrediction = {
			-- Colors adapted from ElvUI but adjusted for better visibility
			personal = {r = 0, g = 0.827, b = 0.765, a = 0.5}, -- Teal for personal heals
			others = {r = 0, g = 0.631, b = 0.557, a = 0.4},   -- Darker teal for other heals
			maxOverflow = 0 -- No overflow by default
		}
	},
	enabled = true,
	autoSetup = true -- Automatically set up on common unit frames
}

-- Configuration access functions
function HealPredictionAddon:GetConfig()
	return self.config or defaultConfig
end

function HealPredictionAddon:SetConfig(newConfig)
	self.config = newConfig or defaultConfig
end

function HealPredictionAddon:ResetConfig()
	self.config = defaultConfig
end

-- Initialize config
HealPredictionAddon:SetConfig(defaultConfig)

-- Export for backward compatibility
_G[addon_name .. "_Config"] = HealPredictionAddon:GetConfig()