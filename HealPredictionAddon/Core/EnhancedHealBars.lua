--[[
	HealPredictionAddon - Enhanced Unit Frame Heal Bars
	Adapted from ElvUI HealComm implementation
	
	This module provides enhanced heal prediction integration for unit frames using the element system
]]

local addon_name = "HealPredictionAddon"
local HealPredictionAddon = _G[addon_name] or {}

-- WoW API
local CreateFrame = CreateFrame
local UnitExists = UnitExists
local unpack = unpack

--[[
	ENHANCED UNIT FRAME INTEGRATION
]]

-- Create heal prediction bars for a frame using ElvUI-style approach
function HealPredictionAddon:ConstructHealComm(frame)
	if not frame then return end
	
	local health = frame.healthbar or frame.healthBar
	if not health then
		-- Try to find health bar by common names
		health = frame.Health or frame.health or frame:GetChildren()
		if not health or not health.GetStatusBarTexture then
			return
		end
	end
	
	-- Create parent frame for bars (similar to ElvUI's ClipFrame)
	local parent = health
	
	-- Create status bars
	local myBar = CreateFrame("StatusBar", nil, parent)
	local otherBar = CreateFrame("StatusBar", nil, parent)
	
	-- Set frame levels to appear over health bar
	myBar:SetFrameLevel((health:GetFrameLevel() or 1) + 1)
	otherBar:SetFrameLevel((health:GetFrameLevel() or 1) + 1)
	
	-- Set default textures and colors
	local texture = health:GetStatusBarTexture() and health:GetStatusBarTexture():GetTexture() or "Interface\\TargetingFrame\\UI-StatusBar"
	myBar:SetStatusBarTexture(texture)
	otherBar:SetStatusBarTexture(texture)
	
	-- Apply colors from config
	local c = HealPredictionAddon.config.colors.healPrediction
	myBar:SetStatusBarColor(c.personal.r, c.personal.g, c.personal.b, c.personal.a)
	otherBar:SetStatusBarColor(c.others.r, c.others.g, c.others.b, c.others.a)
	
	-- Create the element table
	local healPrediction = {
		myBar = myBar,
		otherBar = otherBar,
		PostUpdate = self.UpdateHealComm,
		maxOverflow = 1 + (c.maxOverflow or 0),
		health = health,
		parent = parent,
		frame = frame
	}
	
	-- Initially hide bars
	myBar:Hide()
	otherBar:Hide()
	
	return healPrediction
end

-- Configure heal prediction bars (adapted from ElvUI)
function HealPredictionAddon:ConfigureHealComm(frame, enabled)
	if not frame then return end
	
	if enabled then
		local healPrediction = frame.HealCommBar
		if not healPrediction then
			-- Create the heal prediction element
			healPrediction = self:ConstructHealComm(frame)
			if not healPrediction then return end
			frame.HealCommBar = healPrediction
		end
		
		local myBar = healPrediction.myBar
		local otherBar = healPrediction.otherBar
		local health = healPrediction.health
		
		-- Update configuration
		local c = self.config.colors.healPrediction
		healPrediction.maxOverflow = 1 + (c.maxOverflow or 0)
		
		-- Set orientation and positioning
		local orientation = "HORIZONTAL" -- Default to horizontal
		if health.GetOrientation and health:GetOrientation then
			orientation = health:GetOrientation()
		end
		
		if orientation == "HORIZONTAL" then
			local width = health:GetWidth()
			width = (width > 0 and width) or 200 -- fallback width
			local healthTexture = health:GetStatusBarTexture()
			
			myBar:SetSize(width, health:GetHeight())
			myBar:ClearAllPoints()
			myBar:SetPoint("TOPLEFT", healthTexture, "TOPRIGHT")
			myBar:SetPoint("BOTTOMLEFT", healthTexture, "BOTTOMRIGHT")
			
			otherBar:SetSize(width, health:GetHeight())
			otherBar:ClearAllPoints()
			otherBar:SetPoint("TOPLEFT", myBar:GetStatusBarTexture(), "TOPRIGHT")
			otherBar:SetPoint("BOTTOMLEFT", myBar:GetStatusBarTexture(), "BOTTOMRIGHT")
		else
			-- Vertical orientation
			local height = health:GetHeight()
			height = (height > 0 and height) or 100 -- fallback height
			local healthTexture = health:GetStatusBarTexture()
			
			myBar:SetSize(health:GetWidth(), height)
			myBar:ClearAllPoints()
			myBar:SetPoint("BOTTOMLEFT", healthTexture, "TOPLEFT")
			myBar:SetPoint("BOTTOMRIGHT", healthTexture, "TOPRIGHT")
			
			otherBar:SetSize(health:GetWidth(), height)
			otherBar:ClearAllPoints()
			otherBar:SetPoint("BOTTOMLEFT", myBar:GetStatusBarTexture(), "TOPLEFT")
			otherBar:SetPoint("BOTTOMRIGHT", myBar:GetStatusBarTexture(), "TOPRIGHT")
		end
		
		-- Enable the element
		if not self:IsHealComm4Enabled(frame) then
			self:EnableHealComm4(frame)
		end
	else
		-- Disable heal prediction
		if self:IsHealComm4Enabled(frame) then
			self:DisableHealComm4(frame)
		end
	end
end

-- Check if HealComm4 is enabled on a frame
function HealPredictionAddon:IsHealComm4Enabled(frame)
	return frame and frame.HealCommBar and HealPredictionAddon.enabledFrames and HealPredictionAddon.enabledFrames[frame]
end

-- Update heal prediction bars (PostUpdate callback)
function HealPredictionAddon.UpdateHealComm(element, unit, myIncomingHeal, otherIncomingHeal)
	if not (element and element.health) then return end
	
	local health = element.health
	local myBar = element.myBar
	local otherBar = element.otherBar
	
	-- Update positioning based on current health bar texture
	local healthTexture = health:GetStatusBarTexture()
	if not healthTexture then return end
	
	-- Position myBar next to health texture
	if myIncomingHeal and myIncomingHeal > 0 then
		myBar:ClearAllPoints()
		myBar:SetPoint("TOPLEFT", healthTexture, "TOPRIGHT")
		myBar:SetPoint("BOTTOMLEFT", healthTexture, "BOTTOMRIGHT")
		
		-- Position otherBar next to myBar
		if otherIncomingHeal and otherIncomingHeal > 0 then
			otherBar:ClearAllPoints()
			otherBar:SetPoint("TOPLEFT", myBar:GetStatusBarTexture(), "TOPRIGHT")
			otherBar:SetPoint("BOTTOMLEFT", myBar:GetStatusBarTexture(), "BOTTOMRIGHT")
		end
	elseif otherIncomingHeal and otherIncomingHeal > 0 then
		-- Only other heals, position otherBar directly next to health
		otherBar:ClearAllPoints()
		otherBar:SetPoint("TOPLEFT", healthTexture, "TOPRIGHT")
		otherBar:SetPoint("BOTTOMLEFT", healthTexture, "BOTTOMRIGHT")
	end
end

--[[
	AUTO-DETECTION AND INTEGRATION
]]

-- Auto-detect and setup heal prediction on common unit frames
function HealPredictionAddon:AutoSetupUnitFrame(frame)
	if not frame or frame.HealCommBar then return end
	
	-- Check if frame has a unit and health bar
	local hasUnit = frame.unit or frame.Unit
	local hasHealth = frame.healthbar or frame.healthBar or frame.Health or frame.health
	
	if hasUnit and hasHealth then
		-- Set up heal prediction
		self:ConfigureHealComm(frame, true)
		
		-- Hook frame events if available
		if frame.RegisterEvent then
			local originalOnEvent = frame:GetScript("OnEvent")
			frame:SetScript("OnEvent", function(self, event, ...)
				if originalOnEvent then
					originalOnEvent(self, event, ...)
				end
				
				-- Update heal prediction on relevant events
				if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
					local arg1 = ...
					if arg1 == self.unit or arg1 == self.Unit then
						local element = self.HealCommBar
						if element and element.ForceUpdate then
							element.ForceUpdate()
						end
					end
				end
			end)
		end
	end
end

-- Hook into common unit frame creation
local function HookUnitFrameCreation()
	-- Hook PlayerFrame
	if PlayerFrame and not PlayerFrame.HealCommBar then
		HealPredictionAddon:AutoSetupUnitFrame(PlayerFrame)
	end
	
	-- Hook TargetFrame  
	if TargetFrame and not TargetFrame.HealCommBar then
		HealPredictionAddon:AutoSetupUnitFrame(TargetFrame)
	end
	
	-- Hook FocusFrame
	if FocusFrame and not FocusFrame.HealCommBar then
		HealPredictionAddon:AutoSetupUnitFrame(FocusFrame)
	end
	
	-- Hook party frames
	for i = 1, 4 do
		local frame = _G["PartyMemberFrame" .. i]
		if frame and not frame.HealCommBar then
			HealPredictionAddon:AutoSetupUnitFrame(frame)
		end
	end
end

-- Set up hooks when addon loads
local setupFrame = CreateFrame("Frame")
setupFrame:RegisterEvent("ADDON_LOADED")
setupFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
setupFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName == addon_name then
			-- Schedule setup for next frame to ensure frames exist
			local function DelayedSetup()
				HookUnitFrameCreation()
			end
			-- Simple timer since C_Timer may not be available
			local timer = CreateFrame("Frame")
			local elapsed = 0
			timer:SetScript("OnUpdate", function(self, delta)
				elapsed = elapsed + delta
				if elapsed >= 0.1 then
					DelayedSetup()
					timer:SetScript("OnUpdate", nil)
				end
			end)
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		-- Setup again in case some frames weren't ready
		HookUnitFrameCreation()
	end
end)