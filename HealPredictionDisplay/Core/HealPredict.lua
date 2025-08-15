--[[
HealPredict - Système de prédiction de heal intégré
Basé sur le système HealPredict existant mais autonome
]]

local ADDON_NAME = "HealPredictionDisplay_HealPredict"

-- API WoW
local CheckInteractDistance = CheckInteractDistance
local CreateFrame = CreateFrame
local GetInventoryItemLink = GetInventoryItemLink
local GetLocale = GetLocale
local GetNumRaidMembers = GetNumRaidMembers
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local SendAddonMessage = SendAddonMessage
local strjoin = strjoin
local strsplit = strsplit
local UIParent = UIParent
local UnitBuff = UnitBuff
local UnitCanAssist = UnitCanAssist
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitInRaid = UnitInRaid
local UnitName = UnitName
local UnitIsDeadOrGhost = UnitIsDeadOrGhost

-- Constantes de message
local HEALSTOP = "HealStop"
local HEALDELAY = "HealDelay"
local HEAL = "Heal"
local SEP = "/"

-- Localisation des sorts
local BEACON_OF_LIGHT
do
  local locales = {
    deDE = "Flamme des Glaubens",
    enUS = "Beacon of Light",
    esES = "Señal de la Luz",
    esMX = "Señal de la Luz",
    frFR = "Guide de lumière",
    itIT = "Faro di Luce",
    koKR = "빛의 봉화",
    ptBR = "Sinalizador da Luz",
    ruRU = "Светоч веры",
    zhCN = "圣光信标",
    zhTW = "聖光信標",
  }
  BEACON_OF_LIGHT = locales[GetLocale()] or locales.enUS
end

local CHAIN_HEAL
do
  local locales = {
    deDE = "Kettenheilung",
    enUS = "Chain Heal",
    esES = "Sanación en cadena",
    esMX = "Sanación en cadena",
    frFR = "Salve de chaîne",
    itIT = "Catena di Cura",
    koKR = "연쇄 치유",
    ptBR = "Cura em Corrente",
    ruRU = "Исцеление цепью",
    zhCN = "治疗链",
    zhTW = "治療鍊",
  }
  CHAIN_HEAL = locales[GetLocale()] or locales.enUS
end

local PRAYER_OF_HEALING
do
  local locales = {
    deDE = "Gebet der Heilung",
    enUS = "Prayer of Healing",
    esES = "Plegaria de curación",
    esMX = "Plegaria de curación",
    frFR = "Prière de soins",
    itIT = "Preghiera di Cura",
    koKR = "치유의 기원",
    ptBR = "Prece de Cura",
    ruRU = "Молитва исцеления",
    zhCN = "治疗祷言",
    zhTW = "治療禱言",
  }
  PRAYER_OF_HEALING = locales[GetLocale()] or locales.enUS
end

local PRAYER_OF_PRESERVATION = "Prayer of Preservation"

local TRANQUILITY
do
  local locales = {
    deDE = "Gelassenheit",
    enUS = "Tranquility",
    esES = "Tranquilidad",
    esMX = "Tranquilidad",
    frFR = "Tranquillité",
    itIT = "Tranquillità",
    koKR = "평온",
    ptBR = "Tranquilidade",
    ruRU = "Спокойствие",
    zhCN = "宁静",
    zhTW = "寧靜",
  }
  TRANQUILITY = locales[GetLocale()] or locales.enUS
end

local SMART_HEALS = {}
SMART_HEALS[TRANQUILITY] = 5
SMART_HEALS[PRAYER_OF_PRESERVATION] = 5
SMART_HEALS[CHAIN_HEAL] = 3

-- Variables locales de l'addon
local player = UnitName("player")
local heals, callbacks, cache, gear_string = {}, {}, {}, ""
local is_healing, beacon_info, current_target

-- Fonctions API
local healpredict = CreateFrame("Frame")

function healpredict.UnitGetIncomingHeals(unit, healer)
  if UnitIsDeadOrGhost(unit) then return 0 end

  local name = UnitName(unit)
  if not heals[name] then
    return 0
  end

  local sumheal, time = 0, GetTime()
  for sender, amount in pairs(heals[name]) do
    if amount[2] <= time then
      heals[name][sender] = nil
    elseif not healer or sender == healer then
      sumheal = sumheal + amount[1]
    end
  end

  return sumheal
end

function healpredict.RegisterCallback(addon, callback)
  callbacks[addon] = callback
end

function healpredict.UnregisterCallback(addon)
  callbacks[addon] = nil
end

-- Fonctions privées
local function UpdateCache(spell, heal)
  local heal = tonumber(heal)
  if not cache[spell] then
    cache[spell] = {heal, 1}
  else
    cache[spell][1] = cache[spell][1] + heal
    cache[spell][2] = cache[spell][2] + 1
  end
end

local function handleCallbacks(...)
  for _, v in pairs(callbacks) do
    if type(v) == "function" then
      v(...)
    end
  end
end

local function Heal(sender, target, amount, duration)
  heals[target] = heals[target] or {}
  heals[target][sender] = {amount, GetTime() + duration / 1000}
  handleCallbacks(target)
end

local function HealStop(sender)
  local affected = {}
  for target, _ in pairs(heals) do
    for tsender in pairs(heals[target]) do
      if sender == tsender then
        heals[target][tsender] = nil
        table.insert(affected, target)
      end
    end
  end
  handleCallbacks(unpack(affected))
end

local function HealDelay(sender, delay)
  if type(delay) ~= "string" then
    local delay = delay / 1000
    local affected = {}
    for target, _ in pairs(heals) do
      for tsender, amount in pairs(heals[target]) do
        if sender == tsender then
          amount[2] = amount[2] + delay
          table.insert(affected, target)
        end
      end
    end
    handleCallbacks(unpack(affected))
  end
end

local function SendHealMsg(msg)
  if GetNumRaidMembers() > 0 then
    SendAddonMessage(ADDON_NAME, msg, "RAID")
  else
    SendAddonMessage(ADDON_NAME, msg, "PARTY")
  end
end

local function BeaconTarget()
  if beacon_info then
    local name, endtime = unpack(beacon_info)
    if endtime > GetTime() then
      return name
    else
      beacon_info = nil
    end
  end
  return nil
end

local function GroupHeal(amount, casttime)
  if UnitInRaid("player") then
    for i = 1, GetNumRaidMembers() do
      local unit = "raid"..i
      if not UnitIsDeadOrGhost(unit) and CheckInteractDistance(unit, 4) then
        local name = UnitName(unit)
        Heal(player, name, amount, casttime)
        SendHealMsg(strjoin(SEP, HEAL, name, amount, casttime))
      end
    end
  else
    -- Groupe
    for i = 1, 4 do
      local unit = "party"..i
      if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and CheckInteractDistance(unit, 4) then
        local name = UnitName(unit)
        Heal(player, name, amount, casttime)
        SendHealMsg(strjoin(SEP, HEAL, name, amount, casttime))
      end
    end
    
    -- Joueur
    Heal(player, player, amount, casttime)
    SendHealMsg(strjoin(SEP, HEAL, player, amount, casttime))
  end
end

local function SmartHeal(amount, casttime, n)
  if not UnitInRaid("player") then
    return GroupHeal(amount, casttime)
  end

  local beacon_target = BeaconTarget()
  local healthpct, currentmax
  local pcts = {}
  local raidN, raidname

  -- Calculer les pourcentages de santé
  for i = 1, GetNumRaidMembers() do
    raidN = "raid"..i
    if not UnitIsDeadOrGhost(raidN) and CheckInteractDistance(raidN, 4) then
      raidname = UnitName(raidN)
      healthpct = UnitHealth(raidN) / UnitHealthMax(raidN)
      pcts[raidname] = 1 - healthpct
    end
  end

  -- Trier et prendre les n plus bas
  local targets = {}
  for i = 1, n do
    local lowest = nil
    local lowestPct = -1
    for name, pct in pairs(pcts) do
      if pct > lowestPct then
        lowestPct = pct
        lowest = name
      end
    end
    if lowest then
      table.insert(targets, lowest)
      pcts[lowest] = nil
    end
  end

  -- Appliquer les heals
  for _, target in ipairs(targets) do
    Heal(player, target, amount, casttime)
    SendHealMsg(strjoin(SEP, HEAL, target, amount, casttime))
  end

  -- Beacon si applicable
  if beacon_target then
    local beacon_found = false
    for _, target in ipairs(targets) do
      if target == beacon_target then
        beacon_found = true
        break
      end
    end
    
    if not beacon_found then
      Heal(player, beacon_target, amount * 0.4, casttime)
      SendHealMsg(strjoin(SEP, HEAL, beacon_target, amount * 0.4, casttime))
    end
  end
end

local function UnitByName(name)
  if name == player then
    return "player"
  end

  local unit
  if UnitInRaid("player") then
    for i = 1, GetNumRaidMembers() do
      unit = "raid"..i
      if UnitName(unit) == name then
        return unit
      end
    end
  end

  for i = 1, 4 do
    unit = "party"..i
    if UnitExists(unit) and UnitName(unit) == name then
      return unit
    end
  end
end

-- Gestion des messages
healpredict:RegisterEvent("CHAT_MSG_ADDON")
healpredict:SetScript("OnEvent", function(_, _, prefix, msg, _, sender)
  if prefix == ADDON_NAME and sender ~= player then
    local command, target_or_delay, amount, casttime = strsplit(SEP, msg)
    if command == HEALSTOP then
      HealStop(sender)
    elseif command == HEAL then
      Heal(sender, target_or_delay, amount, casttime)
    elseif command == HEALDELAY then
      HealDelay(sender, target_or_delay)
    end
  end
end)

-- Réinitialisation du cache
local resetcache = CreateFrame("Frame")
resetcache:RegisterEvent("SKILL_LINES_CHANGED")
resetcache:RegisterEvent("UNIT_INVENTORY_CHANGED")
resetcache:SetScript("OnEvent", function(_, event, playerUnit)
  if playerUnit ~= "player" then
    return
  end

  if event == "UNIT_INVENTORY_CHANGED" then
    local gear = ""
    for id = 1, 18 do
      gear = gear .. (GetInventoryItemLink("player", id) or "")
    end

    if gear == gear_string then
      return
    end
    gear_string = gear
  end

  cache = {}
end)

-- Gestion des événements
local eventhandler = CreateFrame("Frame", ADDON_NAME .. "EventHandler", UIParent)

eventhandler:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
function eventhandler.COMBAT_LOG_EVENT_UNFILTERED(_, subevent, _, sourcename, _, _, destname, _, spellid, spellname, _, amount)
  if sourcename ~= player then return end

  if subevent == "SPELL_HEAL" then
    local _, rank = GetSpellInfo(spellid)
    local spellrank = spellname..(rank or "")
    UpdateCache(spellrank, amount)

    if spellname == TRANQUILITY then
      HealStop(player)
      SendHealMsg(HEALSTOP)

      local _, _, _, _, starttime, endtime = UnitChannelInfo("player")
      if starttime and endtime then
        local casttime = endtime - starttime
        local total, casts = unpack(cache[spellrank])
        local amount = total / casts
        SmartHeal(amount, casttime, 5)
        is_healing = true
      end
    end
  elseif spellname == BEACON_OF_LIGHT then
    if subevent == "SPELL_AURA_APPLIED" then
      local unit = UnitByName(destname)
      if unit then
        for i = 1, 40 do
          local buff, _, _, _, _, endtime = UnitBuff(unit, i)
          if buff == BEACON_OF_LIGHT then
            beacon_info = {destname, endtime}
            break
          end
        end
      end
    elseif subevent == "SPELL_AURA_REMOVED" then
      beacon_info = nil
    end
  end
end

eventhandler:RegisterEvent("UNIT_SPELLCAST_SENT")
function eventhandler.UNIT_SPELLCAST_SENT(unit, _, _, target)
  if unit == "player" then
    if target == "" then
      current_target = UnitCanAssist("player", "target") and UnitName("target") or player
    else
      current_target = target
    end
  end
end

eventhandler:RegisterEvent("UNIT_SPELLCAST_START")
function eventhandler.UNIT_SPELLCAST_START(unit)
  if unit ~= "player" then return end

  local spell, rank, _, _, starttime, endtime = UnitCastingInfo("player")
  if not spell then
    spell, rank, _, _, starttime, endtime = UnitChannelInfo("player")
  end
  
  if not spell then return end
  
  local casttime = endtime - starttime
  local spellrank = spell..(rank or "")

  if cache[spellrank] then
    local total, casts = unpack(cache[spellrank])
    local amount = total / casts

    if spell == PRAYER_OF_HEALING then
      GroupHeal(amount, casttime)
    elseif SMART_HEALS[spell] then
      SmartHeal(amount, casttime, SMART_HEALS[spell])
    else
      local beacon_target = BeaconTarget()

      if beacon_target then
        if beacon_target ~= current_target then
          Heal(player, current_target, amount, casttime)
          SendHealMsg(strjoin(SEP, HEAL, current_target, amount, casttime))

          Heal(player, beacon_target, amount * 0.4, casttime)
          SendHealMsg(strjoin(SEP, HEAL, beacon_target, amount * 0.4, casttime))
        else
          Heal(player, beacon_target, amount * 1.4, casttime)
          SendHealMsg(strjoin(SEP, HEAL, beacon_target, amount * 1.4, casttime))
        end
      else
        Heal(player, current_target, amount, casttime)
        SendHealMsg(strjoin(SEP, HEAL, current_target, amount, casttime))
      end
    end

    is_healing = true
  end
end

eventhandler:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
eventhandler.UNIT_SPELLCAST_CHANNEL_START = eventhandler.UNIT_SPELLCAST_START

eventhandler:RegisterEvent("UNIT_SPELLCAST_FAILED")
function eventhandler.UNIT_SPELLCAST_FAILED(unit)
  if is_healing and unit == "player" then
    HealStop(player)
    SendHealMsg(HEALSTOP)
    is_healing = nil
  end
end

eventhandler:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
eventhandler.UNIT_SPELLCAST_INTERRUPTED = eventhandler.UNIT_SPELLCAST_FAILED

eventhandler:RegisterEvent("UNIT_SPELLCAST_STOP")
eventhandler.UNIT_SPELLCAST_STOP = eventhandler.UNIT_SPELLCAST_FAILED

eventhandler:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
eventhandler.UNIT_SPELLCAST_CHANNEL_STOP = eventhandler.UNIT_SPELLCAST_FAILED

eventhandler:RegisterEvent("UNIT_SPELLCAST_DELAYED")
function eventhandler.UNIT_SPELLCAST_DELAYED(unit, delay)
  if is_healing and unit == "player" then
    HealDelay(player, delay)
    SendHealMsg(strjoin(SEP, HEALDELAY, delay))
  end
end

eventhandler:SetScript("OnEvent", function(_, event, ...)
  local handler = eventhandler[event]
  if handler then
    handler(...)
  end
end)

-- Exposer l'API globalement
_G.HealPredict = healpredict