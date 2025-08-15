--[[
AceTimer-3.0 - Standalone version for HealPredictionDisplay
]]

local MAJOR, MINOR = "AceTimer-3.0", 17
local AceTimer, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceTimer then return end

AceTimer.frame = AceTimer.frame or CreateFrame("Frame", "AceTimer30Frame")
AceTimer.embeds = AceTimer.embeds or {}

local GetTime = GetTime
local type = type
local tostring = tostring
local error = error
local select = select
local pairs = pairs
local next = next

local mixins = {
	"ScheduleTimer", "ScheduleRepeatingTimer", 
	"CancelTimer", "CancelAllTimers"
}

local activeTimers = setmetatable({}, {__mode = "k"})
local timerFrame = AceTimer.frame

local function OnUpdate(this, elapsed)
	local total = 0
	for object, timers in pairs(activeTimers) do
		if next(timers) then
			for handle, timer in pairs(timers) do
				timer.remaining = timer.remaining - elapsed
				
				if timer.remaining <= 0 then
					if timer.looping then
						timer.func(object, timer.arg)
						timer.remaining = timer.delay
					else
						local callback = timer.func
						local arg = timer.arg
						timers[handle] = nil
						if not next(timers) then
							activeTimers[object] = nil
						end
						callback(object, arg)
					end
				end
			end
			total = total + 1
		else
			activeTimers[object] = nil
		end
	end
	
	if total == 0 then
		this:Hide()
	end
end

timerFrame:SetScript("OnUpdate", OnUpdate)
timerFrame:Hide()

local function validateFunc(func, err)
	if type(func) == "string" then
		return func
	elseif type(func) == "function" then
		return func
	else
		error(err, 3)
	end
end

function AceTimer:ScheduleTimer(func, delay, arg)
	if type(delay) ~= "number" or delay < 0 then
		error("Usage: ScheduleTimer(callback, delay, [arg]): 'delay' - number expected.", 2)
	end
	
	func = validateFunc(func, "Usage: ScheduleTimer(callback, delay, [arg]): 'callback' - function or method name expected.")
	
	if not activeTimers[self] then
		activeTimers[self] = {}
	end
	
	local handle = {}
	local timer = {
		func = func,
		delay = delay,
		remaining = delay,
		arg = arg,
		looping = false,
	}
	
	activeTimers[self][handle] = timer
	timerFrame:Show()
	
	return handle
end

function AceTimer:ScheduleRepeatingTimer(func, delay, arg)
	if type(delay) ~= "number" or delay < 0 then
		error("Usage: ScheduleRepeatingTimer(callback, delay, [arg]): 'delay' - number expected.", 2)
	end
	
	func = validateFunc(func, "Usage: ScheduleRepeatingTimer(callback, delay, [arg]): 'callback' - function or method name expected.")
	
	if not activeTimers[self] then
		activeTimers[self] = {}
	end
	
	local handle = {}
	local timer = {
		func = func,
		delay = delay,
		remaining = delay,
		arg = arg,
		looping = true,
	}
	
	activeTimers[self][handle] = timer
	timerFrame:Show()
	
	return handle
end

function AceTimer:CancelTimer(handle, silent)
	if not handle then return end
	
	if activeTimers[self] and activeTimers[self][handle] then
		activeTimers[self][handle] = nil
		if not next(activeTimers[self]) then
			activeTimers[self] = nil
		end
		return true
	end
	
	if not silent then
		return false
	end
end

function AceTimer:CancelAllTimers()
	if activeTimers[self] then
		for handle in pairs(activeTimers[self]) do
			activeTimers[self][handle] = nil
		end
		activeTimers[self] = nil
	end
end

for i = 1, #mixins do
	AceTimer[mixins[i]] = AceTimer[mixins[i]]
end

function AceTimer:Embed(target)
	for i = 1, #mixins do
		target[mixins[i]] = self[mixins[i]]
	end
	self.embeds[target] = true
	return target
end