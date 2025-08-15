--[[
AceDB-3.0 - Standalone version for HealPredictionDisplay
]]

local MAJOR, MINOR = "AceDB-3.0", 26
local AceDB, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceDB then return end

local type, pairs, next, error = type, pairs, next, error
local setmetatable, getmetatable, rawset, rawget = setmetatable, getmetatable, rawset, rawget

local function copyDefaults(dest, src)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if not rawget(dest, k) then rawset(dest, k, {}) end
			if type(dest[k]) == "table" then
				copyDefaults(dest[k], v)
			end
		else
			if rawget(dest, k) == nil then
				rawset(dest, k, v)
			end
		end
	end
end

local function removeDefaults(db, defaults, blocker)
	if not db or not defaults then return end
	blocker = blocker or {}
	if blocker[db] then return end
	blocker[db] = true
	
	for k,v in pairs(defaults) do
		if type(v) == "table" and type(db[k]) == "table" then
			removeDefaults(db[k], v, blocker)
			if not next(db[k]) then
				rawset(db, k, nil)
			end
		elseif db[k] == defaults[k] then
			rawset(db, k, nil)
		end
	end
end

local DBObjectLib = {}

function DBObjectLib:RegisterDefaults(defaults)
	if defaults and type(defaults) == "table" then
		if defaults.profile and type(defaults.profile) == "table" then
			copyDefaults(self.profile, defaults.profile)
		end
		if defaults.global and type(defaults.global) == "table" then
			copyDefaults(self.sv.global, defaults.global)
		end
	end
end

function DBObjectLib:ResetProfile(noChildren, noCallbacks)
	local sv = rawget(self, "sv")
	for k,v in pairs(self.profile) do
		self.profile[k] = nil
	end
	
	if sv.profiles[self.keys.profile] then
		sv.profiles[self.keys.profile] = nil
	end
	
	if self.defaults and self.defaults.profile then
		copyDefaults(self.profile, self.defaults.profile)
	end
end

function DBObjectLib:ResetDB(noCallbacks)
	local sv = rawget(self, "sv")
	for k,v in pairs(sv) do
		sv[k] = nil
	end
	
	local parent = rawget(self, "parent")
	if parent then
		parent.children[self] = nil
		parent:RegisterDefaults(parent.defaults)
		parent:SetProfile(parent:GetCurrentProfile())
	else
		if self.defaults then
			copyDefaults(sv, self.defaults)
		end
	end
end

function DBObjectLib:GetCurrentProfile()
	return self.keys.profile
end

function DBObjectLib:SetProfile(name)
	if type(name) ~= "string" then
		error("Usage: SetProfile(name): 'name' - string expected.", 2)
	end
	
	if not rawget(self.sv.profiles, name) then
		rawset(self.sv.profiles, name, {})
	end
	
	self.keys.profile = name
	rawset(self, "profile", self.sv.profiles[name])
	
	if self.defaults and self.defaults.profile then
		copyDefaults(self.profile, self.defaults.profile)
	end
end

function DBObjectLib:GetProfiles(t)
	if not t then t = {} end
	
	local i = 0
	for profileName in pairs(self.sv.profiles) do
		i = i + 1
		t[i] = profileName
	end
	
	return t, i
end

function DBObjectLib:DeleteProfile(name)
	if type(name) ~= "string" then
		error("Usage: DeleteProfile(name): 'name' - string expected.", 2)
	end
	
	if self.keys.profile == name then
		error("Cannot delete the currently active profile", 2)
	end
	
	if not rawget(self.sv.profiles, name) and name ~= "Default" then
		return false
	end
	
	self.sv.profiles[name] = nil
	return true
end

function DBObjectLib:CopyProfile(name, silent)
	if type(name) ~= "string" then
		error("Usage: CopyProfile(name, [silent]): 'name' - string expected.", 2)
	end
	
	if not rawget(self.sv.profiles, name) and name ~= "Default" then
		if not silent then
			error("Cannot copy profile '"..name.."'. It does not exist.", 2)
		end
		return
	end
	
	-- Clear current profile
	for k,v in pairs(self.profile) do
		self.profile[k] = nil
	end
	
	local source = rawget(self.sv.profiles, name) or {}
	copyDefaults(self.profile, source)
	if self.defaults and self.defaults.profile then
		copyDefaults(self.profile, self.defaults.profile)
	end
end

local mt = {
	__index = DBObjectLib
}

function AceDB:New(tbl, defaults, defaultProfile)
	if type(tbl) == "string" then
		local name = tbl
		tbl = _G[name]
		if not tbl then
			tbl = {}
			_G[name] = tbl
		end
	end
	
	if not tbl then
		tbl = {}
	end
	
	if not tbl.profiles then tbl.profiles = {} end
	if not tbl.global then tbl.global = {} end
	
	local profileKey = defaultProfile or "Default"
	local profileName = profileKey
	
	if not rawget(tbl.profiles, profileName) then
		rawset(tbl.profiles, profileName, {})
	end
	
	local obj = {
		sv = tbl,
		defaults = defaults,
		keys = {
			profile = profileName,
		}
	}
	
	rawset(obj, "profile", tbl.profiles[profileName])
	
	if defaults then
		if defaults.global and type(defaults.global) == "table" then
			copyDefaults(obj.sv.global, defaults.global)
		end
		if defaults.profile and type(defaults.profile) == "table" then
			copyDefaults(obj.profile, defaults.profile)
		end
	end
	
	setmetatable(obj, mt)
	
	return obj
end

local function logPrefix(cb, db, profileKey)
	return cb and cb(db, profileKey) or ""
end

function AceDB:RegisterNamespace(name, defaults)
	if type(name) ~= "string" then
		error("Usage: RegisterNamespace(name, defaults): 'name' - string expected.", 2)
	end
	if defaults and type(defaults) ~= "table" then
		error("Usage: RegisterNamespace(name, defaults): 'defaults' - table expected or nil.", 2)
	end
	if self.children and self.children[name] then
		error("Usage: RegisterNamespace(name, defaults): 'name' - a namespace with that name already exists.", 2)
	end

	local sv = rawget(self, "sv")
	if not sv[name] then
		sv[name] = {}
	end
	
	local newDB = AceDB:New(sv[name], defaults, self.keys.profile)
	
	if not rawget(self, "children") then
		rawset(self, "children", {})
	end
	self.children[name] = newDB
	rawset(newDB, "parent", self)
	
	return newDB
end

function AceDB:GetNamespace(name, silent)
	if type(name) ~= "string" then
		error("Usage: GetNamespace(name): 'name' - string expected.", 2)
	end
	if not silent and not (self.children and self.children[name]) then
		error("Usage: GetNamespace(name): 'name' - namespace does not exist.", 2)
	end
	if not self.children then self.children = {} end
	return self.children[name]
end