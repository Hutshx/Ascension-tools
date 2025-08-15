--[[
CallbackHandler-1.0 - Standalone version for HealPredictionDisplay
]]

local MAJOR, MINOR = "CallbackHandler-1.0", 6
local CallbackHandler = LibStub:NewLibrary(MAJOR, MINOR)

if not CallbackHandler then return end

local meta = {__index = function(tbl, key) tbl[key] = {} return tbl[key] end}

local type = type
local pcall = pcall
local pairs = pairs
local assert = assert
local concat = table.concat
local loadstring = loadstring
local next = next
local select = select
local type = type
local xpcall = xpcall

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function CreateDispatcher(argCount)
	local code = [[
	local next, xpcall, eh = ...
	
	local function call(obj, method, ...)
		if type(method) == "function" then
			return xpcall(method, eh, obj, ...)
		else
			return xpcall(obj[method], eh, obj, ...)
		end
	end
	
	local function dispatch(handlers, ...)
		local index
		index, handlers[0] = 0, next(handlers)
		for i = 1, %d do
			local handler = handlers[index]
			if handler then
				call(handler, i, ...)
			end
			index = next(handlers, index)
		end
		handlers[0] = nil
	end
	return dispatch
	]]
	
	local arg_list = {}
	for i = 1, argCount do arg_list[i] = "arg"..i end
	code = code:format(argCount, concat(arg_list, ", "), concat(arg_list, ", "))
	return assert(loadstring(code, "safecall Dispatcher["..argCount.."]"))(next, xpcall, errorhandler)
end

local Dispatchers = setmetatable({}, {__index=function(self, argCount)
	local dispatcher = CreateDispatcher(argCount)
	rawset(self, argCount, dispatcher)
	return dispatcher
end})

function CallbackHandler:New(target, RegisterName, UnregisterName, UnregisterAllName)
	RegisterName = RegisterName or "RegisterCallback"
	UnregisterName = UnregisterName or "UnregisterCallback"
	UnregisterAllName = UnregisterAllName or "UnregisterAllCallbacks"

	local events = setmetatable({}, meta)
	local registry = setmetatable({}, meta)

	local function RegisterCallback(self, eventname, method, ... --[[actually just a method]])
		if type(eventname) ~= "string" then
			error("Usage: "..RegisterName.."(eventname, method[, arg, arg, ...]): 'eventname' - string expected.", 2)
		end
		
		method = method or eventname
		
		local first = not rawget(events, eventname) or not next(events[eventname])
		local regfunc = registry[eventname]
		if first and regfunc then
			regfunc(self, eventname)
		end
		
		events[eventname][self] = method
	end
	
	local function UnregisterCallback(self, eventname)
		if not events[eventname] or not events[eventname][self] then
			return false
		end
		events[eventname][self] = nil
		
		if not next(events[eventname]) then
			local regfunc = registry[eventname]
			if regfunc then
				regfunc(self, eventname)
			end
		end
		return true
	end
	
	local function UnregisterAllCallbacks(self)
		assert(registry[self], "Usage: "..UnregisterAllName.."(): 'self' - must be a registry name, not an object.")
		registry[self] = nil
		for eventname, callbacks in pairs(events) do
			if callbacks[self] then
				callbacks[self] = nil
				if not next(callbacks) then
					local regfunc = registry[eventname]
					if regfunc then
						regfunc(self, eventname)
					end
				end
			end
		end
	end

	target[RegisterName] = RegisterCallback
	target[UnregisterName] = UnregisterCallback	
	target[UnregisterAllName] = UnregisterAllCallbacks
	
	function target:Fire(eventname, ...)
		if not rawget(events, eventname) or not next(events[eventname]) then return end
		local dispatcher = Dispatchers[select('#', ...) + 1]
		dispatcher(events[eventname], eventname, ...)
	end

	target.events = events
	target.registry = registry
	
	return target
end

function CallbackHandler:Embed(target)
	return CallbackHandler:New(target)
end

CallbackHandler = CallbackHandler:Embed(CallbackHandler)