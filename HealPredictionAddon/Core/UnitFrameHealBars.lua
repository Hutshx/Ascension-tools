--[[
	HealPredictionAddon - Unit Frame Heal Bars Logic
	Adapted from UnitFrameLayers/UnitFrame.lua (heal prediction parts only)
	
	This module handles the visual display of heal prediction bars on unit frames
]]

local MAX_INCOMING_HEAL_OVERFLOW = 1.0

-- Event handling for heal prediction updates  
-- Callback handler that gets called for each registered frame
local function LibEventCallback(self, event, ...)
	local arg1, arg2, arg3, arg4, arg5 = ...
	if ( not self.unit) then
		return
	end

	-- Handle HealComm events (arg5 is the target GUID for heal events)
	if ( arg5 == UnitGUID(self.unit) ) then
		if ( event == "HealComm_HealUpdated" ) then
			UnitFrameHealPredictionBars_Update(self)
		elseif ( event == "HealComm_HealStarted" ) then
			UnitFrameHealPredictionBars_Update(self)
		elseif ( event == "HealComm_HealDelayed" ) then
			UnitFrameHealPredictionBars_Update(self)
		elseif ( event == "HealComm_HealStopped" ) then
			UnitFrameHealPredictionBars_Update(self)
		elseif ( event == "HealComm_ModifierChanged" ) then
			UnitFrameHealPredictionBars_Update(self)
		elseif ( event == "HealComm_GUIDDisappeared" ) then
			UnitFrameHealPredictionBars_Update(self)
		end
	end
end

-- Register a frame to receive heal prediction callbacks
local function UnitFrame_RegisterHealCallback(self)
	-- We need to access the HealComm library
	local HealComm = LibStub:GetLibrary("LibHealComm-4.0")
	if HealComm then
		HealComm.RegisterCallback(self, "HealComm_HealStarted", LibEventCallback, self)
		HealComm.RegisterCallback(self, "HealComm_HealUpdated", LibEventCallback, self)
		HealComm.RegisterCallback(self, "HealComm_HealDelayed", LibEventCallback, self)
		HealComm.RegisterCallback(self, "HealComm_HealStopped", LibEventCallback, self)
		HealComm.RegisterCallback(self, "HealComm_ModifierChanged", LibEventCallback, self)
		HealComm.RegisterCallback(self, "HealComm_GUIDDisappeared", LibEventCallback, self)
	end
end

-- Update fill bar utility function (heal prediction only)
local function UnitFrameUtil_UpdateFillBarBase(frame, realbar, previousTexture, bar, amount, barOffsetXPercent)
	if ( amount == 0 ) then
		bar:Hide()
		if ( bar.overlay ) then
			bar.overlay:Hide()
		end
		return previousTexture
	end
	
	local barOffsetX = 0
	if ( barOffsetXPercent ) then
		local realbarSizeX = realbar:GetWidth()
		barOffsetX = realbarSizeX * barOffsetXPercent
	end
	
	bar:SetPoint("TOPLEFT", previousTexture, "TOPRIGHT", barOffsetX, 0)
	bar:SetPoint("BOTTOMLEFT", previousTexture, "BOTTOMRIGHT", barOffsetX, 0)
	local totalWidth, totalHeight = realbar:GetSize()
	local _, totalMax = realbar:GetMinMaxValues()
	local barSize = (amount / totalMax) * totalWidth
	bar:SetWidth(barSize)
	bar:Show()

	if ( bar.overlay ) then
		bar.overlay:SetTexCoord(0, barSize / bar.overlay.tileSize, 0, totalHeight / bar.overlay.tileSize)
		bar.overlay:Show()
	end
	return bar
end

-- Update fill bar for health bar
local function UnitFrameUtil_UpdateFillBar(frame, previousTexture, bar, amount, barOffsetXPercent)
	return UnitFrameUtil_UpdateFillBarBase(frame, frame.healthbar, previousTexture, bar, amount, barOffsetXPercent)
end

-- Main heal prediction update function (absorb functionality removed)
function UnitFrameHealPredictionBars_Update(frame)
	if ( not frame.myHealPredictionBar ) then
		return
	end
	
	local _, maxHealth = frame.healthbar:GetMinMaxValues()
	local health = frame.healthbar:GetValue()
	if ( maxHealth <= 0 ) then
		return
	end
	
	local myIncomingHeal = UnitGetIncomingHeals(frame.unit, "player") or 0
	local allIncomingHeal = UnitGetIncomingHeals(frame.unit) or 0

	-- See how far we're going over the health bar and make sure we don't go too far out of the frame
	if ( health + allIncomingHeal > maxHealth * MAX_INCOMING_HEAL_OVERFLOW ) then
		allIncomingHeal = maxHealth * MAX_INCOMING_HEAL_OVERFLOW - health
	end
	
	local otherIncomingHeal = 0
	-- Split up incoming heals
	if ( allIncomingHeal >= myIncomingHeal ) then
		otherIncomingHeal = allIncomingHeal - myIncomingHeal
	else
		myIncomingHeal = allIncomingHeal
	end
	
	local healthTexture = frame.healthbar:GetStatusBarTexture()
	
	-- Show myIncomingHeal on the health bar
	local incomingHealTexture = UnitFrameUtil_UpdateFillBar(frame, healthTexture, frame.myHealPredictionBar, myIncomingHeal)
	
	-- Append otherIncomingHeal on the health bar
	if (myIncomingHeal > 0) then
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
	if ( not self.myHealPredictionBar ) then
		return
	end
	UnitFrameHealPredictionBars_Update(self)
end

-- Hook health bar updates to trigger heal prediction updates
hooksecurefunc("UnitFrameHealthBar_Update", function(statusbar, unit)
	local frame = statusbar:GetParent()
	if frame and frame.myHealPredictionBar then
		UnitFrameHealPredictionBars_Update(frame)
	end
end)

-- Hook unit frame updates
hooksecurefunc("UnitFrame_Update", function(self, isParty)
	if self.myHealPredictionBar then
		UnitFrameHealPredictionBars_UpdateMax(self)
		UnitFrameHealPredictionBars_Update(self)
	end
end)

-- Hook unit frame events to initialize heal prediction bars when needed
hooksecurefunc("UnitFrame_OnEvent", function(self, event, ...)
	-- Only initialize if we don't already have heal prediction bars
	if ( not self.myHealPredictionBar ) then
		-- Create heal prediction frame from template
		CreateFrame("Frame", nil, self, "HealPredictionTemplate")
		local thisName = self:GetName()
		
		-- Initialize with the created bars
		if thisName then
			local myBar = _G[thisName.."FrameMyHealPredictionBar"]
			local otherBar = _G[thisName.."FrameOtherHealPredictionBar"]
			
			if myBar and otherBar then
				UnitFrameHealPrediction_Initialize(self, myBar, otherBar)
			end
		end
	end
	
	-- Update heal prediction bars
	if self.myHealPredictionBar then
		UnitFrameHealPredictionBars_Update(self)
	end
end)