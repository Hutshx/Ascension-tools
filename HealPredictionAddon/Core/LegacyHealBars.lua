--[[
	HealPredictionAddon - Unit Frame Heal Bars Logic (Legacy Compatibility)
	Adapted from UnitFrameLayers/UnitFrame.lua (heal prediction parts only)
	
	This module provides fallback heal prediction for frames that don't use the element system
]]

local MAX_INCOMING_HEAL_OVERFLOW = 1.0

-- Event handling for heal prediction updates  
-- Callback handler that gets called for each registered frame
local function LibEventCallback(self, event, ...)
	local arg1, arg2, arg3, arg4, arg5 = ...
	if not self.unit then
		return
	end

	-- Handle HealComm events (arg5 is the target GUID for heal events)
	local unitGUID = UnitGUID(self.unit)
	if unitGUID and (arg5 == unitGUID or arg1 == UnitName(self.unit)) then
		if event == "HealComm_HealUpdated" or
		   event == "HealComm_HealStarted" or
		   event == "HealComm_HealDelayed" or
		   event == "HealComm_HealStopped" or
		   event == "HealComm_ModifierChanged" or
		   event == "HealComm_GUIDDisappeared" then
			UnitFrameHealPredictionBars_Update(self)
		end
	end
end

-- Register a frame to receive heal prediction callbacks
local function UnitFrame_RegisterHealCallback(self)
	-- We need to access the HealComm library
	local HealComm = LibStub:GetLibrary("LibHealComm-4.0")
	if HealComm then
		HealComm.RegisterCallback(self, "HealComm_HealStarted", LibEventCallback)
		HealComm.RegisterCallback(self, "HealComm_HealUpdated", LibEventCallback)
		HealComm.RegisterCallback(self, "HealComm_HealDelayed", LibEventCallback)
		HealComm.RegisterCallback(self, "HealComm_HealStopped", LibEventCallback)
		HealComm.RegisterCallback(self, "HealComm_ModifierChanged", LibEventCallback)
		HealComm.RegisterCallback(self, "HealComm_GUIDDisappeared", LibEventCallback)
	end
end

-- Update fill bar utility function (heal prediction only)
local function UnitFrameUtil_UpdateFillBarBase(frame, realbar, previousTexture, bar, amount, barOffsetXPercent)
	if amount == 0 then
		bar:Hide()
		if bar.overlay then
			bar.overlay:Hide()
		end
		return previousTexture
	end
	
	local barOffsetX = 0
	if barOffsetXPercent then
		local realbarSizeX = realbar:GetWidth()
		barOffsetX = realbarSizeX * barOffsetXPercent
	end
	
	bar:SetPoint("TOPLEFT", previousTexture, "TOPRIGHT", barOffsetX, 0)
	bar:SetPoint("BOTTOMLEFT", previousTexture, "BOTTOMRIGHT", barOffsetX, 0)
	local totalWidth, totalHeight = realbar:GetSize()
	local _, totalMax = realbar:GetMinMaxValues()
	
	if totalMax > 0 then
		local barSize = (amount / totalMax) * totalWidth
		bar:SetWidth(barSize)
		bar:Show()

		if bar.overlay then
			bar.overlay:SetTexCoord(0, barSize / bar.overlay.tileSize, 0, totalHeight / bar.overlay.tileSize)
			bar.overlay:Show()
		end
	else
		bar:Hide()
	end
	return bar
end

-- Update fill bar for health bar
local function UnitFrameUtil_UpdateFillBar(frame, previousTexture, bar, amount, barOffsetXPercent)
	local healthbar = frame.healthbar or frame.healthBar or frame.Health or frame.health
	if healthbar then
		return UnitFrameUtil_UpdateFillBarBase(frame, healthbar, previousTexture, bar, amount, barOffsetXPercent)
	end
	return previousTexture
end

-- Main heal prediction update function (absorb functionality removed)
function UnitFrameHealPredictionBars_Update(frame)
	if not frame.myHealPredictionBar then
		return
	end
	
	local healthbar = frame.healthbar or frame.healthBar or frame.Health or frame.health
	if not healthbar then
		return
	end
	
	local _, maxHealth = healthbar:GetMinMaxValues()
	local health = healthbar:GetValue()
	if maxHealth <= 0 then
		return
	end
	
	local myIncomingHeal = UnitGetIncomingHeals(frame.unit, "player") or 0
	local allIncomingHeal = UnitGetIncomingHeals(frame.unit) or 0
	local otherIncomingHeal = 0

	-- Apply overflow limitations
	local maxOverflow = frame.healPredictionMaxOverflow or MAX_INCOMING_HEAL_OVERFLOW
	if health + allIncomingHeal > maxHealth * (1 + maxOverflow) then
		allIncomingHeal = (maxHealth * (1 + maxOverflow)) - health
	end

	if allIncomingHeal < myIncomingHeal then
		myIncomingHeal = allIncomingHeal
		otherIncomingHeal = 0
	else
		otherIncomingHeal = allIncomingHeal - myIncomingHeal
	end
	
	local healthTexture = healthbar:GetStatusBarTexture()
	if not healthTexture then
		return
	end
	
	-- Append myIncomingHeal on the health bar
	local incomingHealTexture = UnitFrameUtil_UpdateFillBar(frame, healthTexture, frame.myHealPredictionBar, myIncomingHeal)
	
	-- Append otherIncomingHeal on the health bar
	if myIncomingHeal > 0 then
		UnitFrameUtil_UpdateFillBar(frame, incomingHealTexture, frame.otherHealPredictionBar, otherIncomingHeal)
	else
		UnitFrameUtil_UpdateFillBar(frame, healthTexture, frame.otherHealPredictionBar, otherIncomingHeal)
	end
end

-- Initialize heal prediction bars for a frame
local function UnitFrameHealPrediction_Initialize(self, myHealPredictionBar, otherHealPredictionBar)
	self.myHealPredictionBar = myHealPredictionBar
	self.otherHealPredictionBar = otherHealPredictionBar
	
	-- Clear all points for positioning
	self.myHealPredictionBar:ClearAllPoints()
	self.otherHealPredictionBar:ClearAllPoints()
	
	-- Register this frame for heal prediction callbacks
	UnitFrame_RegisterHealCallback(self)
	
	-- Initial update
	UnitFrameHealPredictionBars_Update(self)
end

-- Hook into Blizzard's unit frame system
local function UnitFrameHealPredictionBars_UpdateMax(self)
	if not self.myHealPredictionBar then
		return
	end
	UnitFrameHealPredictionBars_Update(self)
end

-- Hook health bar updates to trigger heal prediction updates
local function HookHealthBarUpdate()
	if UnitFrameHealthBar_Update then
		hooksecurefunc("UnitFrameHealthBar_Update", function(statusbar, unit)
			local frame = statusbar:GetParent()
			if frame and frame.myHealPredictionBar then
				UnitFrameHealPredictionBars_Update(frame)
			end
		end)
	end
end

-- Hook unit frame updates
local function HookUnitFrameUpdate()
	if UnitFrame_Update then
		hooksecurefunc("UnitFrame_Update", function(self, isParty)
			if self.myHealPredictionBar then
				UnitFrameHealPredictionBars_UpdateMax(self)
				UnitFrameHealPredictionBars_Update(self)
			end
		end)
	end
end

-- Hook unit frame events to initialize heal prediction bars when needed
local function HookUnitFrameOnEvent()
	if UnitFrame_OnEvent then
		hooksecurefunc("UnitFrame_OnEvent", function(self, event, ...)
			-- Only initialize if we don't already have heal prediction bars
			if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
				if self.myHealPredictionBar then
					UnitFrameHealPredictionBars_Update(self)
				end
			end
		end)
	end
end

-- Set up the hooks
local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("ADDON_LOADED")
hookFrame:SetScript("OnEvent", function(self, event, ...)
	local addonName = ...
	if event == "ADDON_LOADED" and addonName == "HealPredictionAddon" then
		-- Set up hooks with a delay to ensure Blizzard functions exist
		local timer = CreateFrame("Frame")
		local elapsed = 0
		timer:SetScript("OnUpdate", function(self, delta)
			elapsed = elapsed + delta
			if elapsed >= 1.0 then -- Wait 1 second for UI to load
				HookHealthBarUpdate()
				HookUnitFrameUpdate() 
				HookUnitFrameOnEvent()
				timer:SetScript("OnUpdate", nil)
			end
		end)
	end
end)

-- Export functions
_G.UnitFrameHealPredictionBars_Update = UnitFrameHealPredictionBars_Update
_G.UnitFrameHealPrediction_Initialize = UnitFrameHealPrediction_Initialize