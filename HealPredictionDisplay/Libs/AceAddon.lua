--[[
AceAddon-3.0 - Standalone version for HealPredictionDisplay
]]

local MAJOR, MINOR = "AceAddon-3.0", 12
local AceAddon, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceAddon then return end

AceAddon.frame = AceAddon.frame or CreateFrame("Frame", "AceAddon30Frame")
AceAddon.addons = AceAddon.addons or {}
AceAddon.statuses = AceAddon.statuses or {}
AceAddon.initializequeue = AceAddon.initializequeue or {}
AceAddon.enablequeue = AceAddon.enablequeue or {}
AceAddon.embeds = AceAddon.embeds or setmetatable({}, {__index = function(tbl, key) tbl[key] = {} return tbl[key] end})

local tinsert, tremove = table.insert, table.remove
local fmt = string.format
local tostring, select = tostring, select
local type, next, pairs, ipairs = type, next, pairs, ipairs
local error, loadstring, assert = error, loadstring, assert

local function IsAddOnLoadOnDemand(addon)
	return false -- Simplified for 3.3.5
end

local mixins = {
	"NewModule", "GetModule", "Enable", "Disable", "IsEnabled",
	"SetDefaultModuleState", "SetDefaultModuleLibraries",
	"SetEnabledState", "SetDefaultModulePrototype",
}

local function Printf(self, fmt, ...)
	if fmt then
		if self.Print then
			self:Print(fmt:format(...))
		else
			print(fmt:format(...))
		end
	end
end

function AceAddon:NewAddon(objName, ...)
	if type(objName) ~= "string" then 
		error("Usage: NewAddon(name, [lib, lib, lib, ...]): 'name' - string expected.", 2) 
	end
	if self.addons[objName] then 
		error("Usage: NewAddon(name, [lib, lib, lib, ...]): 'name' - Addon '"..objName.."' already exists.", 2) 
	end

	local addon = {}
	
	local libs = {...}
	for i = 1, select('#', ...) do
		local lib = libs[i]
		if type(lib) == "string" then
			local libObj = LibStub(lib, true)
			if libObj then
				LibStub(lib):Embed(addon)
			end
		elseif type(lib) == "table" then
			for k, v in pairs(lib) do
				addon[k] = v
			end
		end
	end
	
	addon.name = objName
	addon.moduleName = objName
	addon.modules = {}
	addon.orderedModules = {}
	addon.defaultModuleState = true
	addon.enabledState = true
	addon.Printf = Printf
	
	self.addons[objName] = addon
	self.statuses[objName] = "Loaded"
	tinsert(self.initializequeue, addon)
	
	return addon
end

function AceAddon:GetAddon(name)
	return self.addons[name]
end

local function Enable(self, silent)
	self:SetEnabledState(true)
	if type(self.OnEnable) == "function" then
		self:OnEnable()
	else
		self.OnEnable = nil
	end
	
	for _, module in pairs(self.modules) do
		if module.enabledState then
			module:Enable(silent)
		end
	end
end

local function Disable(self, silent)
	self:SetEnabledState(false)
	if type(self.OnDisable) == "function" then
		self:OnDisable()
	else
		self.OnDisable = nil
	end
	
	for _, module in pairs(self.modules) do
		module:Disable(silent)
	end
end

local function SetEnabledState(self, state)
	self.enabledState = state
end

local function IsEnabled(self)
	return self.enabledState
end

local function NewModule(self, moduleName, ...)
	if type(moduleName) ~= "string" then
		error("Usage: NewModule(name, [prototype, [lib, lib, lib, ...]]): 'name' - string expected.", 2)
	end
	if self.modules[moduleName] then
		error("Usage: NewModule(name, [prototype, [lib, lib, lib, ...]]): 'name' - Module '"..moduleName.."' already exists.", 2)
	end
	
	local module = {}
	module.moduleName = moduleName
	module.enabledState = self.defaultModuleState
	module.name = fmt("%s_%s", self.name or tostring(self), moduleName)
	
	local libs = {...}
	for i = 1, select('#', ...) do
		local lib = libs[i]
		if type(lib) == "string" then
			local libObj = LibStub(lib, true)
			if libObj then
				LibStub(lib):Embed(module)
			end
		elseif type(lib) == "table" then
			for k, v in pairs(lib) do
				module[k] = v
			end
		end
	end
	
	self.modules[moduleName] = module
	tinsert(self.orderedModules, module)
	
	return module
end

local function GetModule(self, moduleName)
	if not self.modules[moduleName] then
		error("Usage: GetModule(name): 'name' - Module '"..tostring(moduleName).."' does not exist.", 2)
	end
	return self.modules[moduleName]
end

local function SetDefaultModuleState(self, state)
	self.defaultModuleState = state
end

local addonmeta = {
	__tostring = function(self) return self.name end
}

local function addontostring( self ) return self.name end

for addon in pairs(AceAddon.addons) do
	AceAddon.embeds[addon] = {}
end

for i = 1, #mixins do
	local mixin = mixins[i]
	AceAddon[mixin] = AceAddon[mixin] or function(self, ...)
		if mixin == "NewModule" then
			return NewModule(self, ...)
		elseif mixin == "GetModule" then
			return GetModule(self, ...)
		elseif mixin == "Enable" then
			return Enable(self, ...)
		elseif mixin == "Disable" then
			return Disable(self, ...)
		elseif mixin == "IsEnabled" then
			return IsEnabled(self, ...)
		elseif mixin == "SetEnabledState" then
			return SetEnabledState(self, ...)
		elseif mixin == "SetDefaultModuleState" then
			return SetDefaultModuleState(self, ...)
		end
	end
end

function AceAddon:Embed(target)
	for i = 1, #mixins do
		target[mixins[i]] = self[mixins[i]]
	end
	self.embeds[target] = true
	return target
end

local function handleAddonLoad()
	for i = #AceAddon.initializequeue, 1, -1 do
		local addon = AceAddon.initializequeue[i]
		if type(addon.OnInitialize) == "function" then
			addon:OnInitialize()
		end
		addon.OnInitialize = nil
		tremove(AceAddon.initializequeue, i)
		tinsert(AceAddon.enablequeue, addon)
	end
	
	for i = #AceAddon.enablequeue, 1, -1 do
		local addon = AceAddon.enablequeue[i]
		if addon.enabledState then
			addon:Enable()
		end
		tremove(AceAddon.enablequeue, i)
	end
end

AceAddon.frame:SetScript("OnEvent", function(this, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "HealPredictionDisplay" then
		handleAddonLoad()
	elseif event == "PLAYER_LOGIN" then
		handleAddonLoad()
	end
end)

AceAddon.frame:RegisterEvent("ADDON_LOADED")
AceAddon.frame:RegisterEvent("PLAYER_LOGIN")