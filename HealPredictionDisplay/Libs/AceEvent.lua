--[[
AceEvent-3.0 - Standalone version for HealPredictionDisplay
]]

local MAJOR, MINOR = "AceEvent-3.0", 4
local AceEvent, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceEvent then return end

AceEvent.frame = AceEvent.frame or CreateFrame("Frame", "AceEvent30Frame")
AceEvent.embeds = AceEvent.embeds or {}

local tinsert = table.insert
local tremove = table.remove

local mixins = {
	"RegisterEvent", "UnregisterEvent", "UnregisterAllEvents", "IsEventRegistered"
}

local events = setmetatable({}, {__index=function(t,k) 
	local reg = {} 
	rawset(t,k,reg) 
	return reg 
end})

function AceEvent:RegisterEvent(event, method, oneshot)
	if type(event) ~= "string" then
		error("Usage: RegisterEvent(event, [method], [oneshot]): 'event' - string expected.", 2)
	end
	
	method = method or event
	
	local first = not next(events[event])
	events[event][self] = method
	
	if first then
		AceEvent.frame:RegisterEvent(event)
	end
	
	return true
end

function AceEvent:UnregisterEvent(event)
	if type(event) ~= "string" then
		error("Usage: UnregisterEvent(event): 'event' - string expected.", 2)
	end
	
	if not rawget(events, event) or not events[event][self] then
		return false
	end
	
	events[event][self] = nil
	
	if not next(events[event]) then
		AceEvent.frame:UnregisterEvent(event)
	end
	
	return true
end

function AceEvent:UnregisterAllEvents()
	for event in pairs(events) do
		if events[event][self] then
			self:UnregisterEvent(event)
		end
	end
end

function AceEvent:IsEventRegistered(event)
	if type(event) ~= "string" then
		error("Usage: IsEventRegistered(event): 'event' - string expected.", 2)
	end
	
	return rawget(events, event) and events[event][self] and true or false
end

AceEvent.frame:SetScript("OnEvent", function(frame, event, ...)
	for obj, method in pairs(events[event]) do
		if type(method) == "string" then
			if type(obj[method]) == "function" then
				obj[method](obj, event, ...)
			end
		elseif type(method) == "function" then
			method(obj, event, ...)
		end
	end
end)

for i = 1, #mixins do
	AceEvent[mixins[i]] = AceEvent[mixins[i]]
end

function AceEvent:Embed(target)
	for i = 1, #mixins do
		target[mixins[i]] = self[mixins[i]]
	end
	self.embeds[target] = true
	return target
end