-- Offline test: runs XPBarNone's Core.lua under Lua 5.1 against a simulated
-- WoW Forever client (12.1 engine, interface 16001, no legacy reputation
-- globals). GetCurrentCombatTextEventInfo starts out missing and is later
-- faked to return secret values. Unknown globals resolve to inert stubs.
-- Run with tests/run_forever_sim.py. Not part of the addon.
local CORE, MODE = ...  -- MODE "fallback": client without COMBATLOG_XPGAIN_* strings
local results, failures = {}, 0
local function check(name, ok, detail)
  results[#results + 1] = (ok and "PASS " or "FAIL ") .. name .. (detail and ("  [" .. detail .. "]") or "")
  if not ok then failures = failures + 1 end
end

-- Inert stub: callable, indexable, returns itself.
local Stub = setmetatable({}, {})
getmetatable(Stub).__index = function() return Stub end
getmetatable(Stub).__call = function() return Stub end

-- Simulated reputation list (C_Reputation, 1-based sort indices).
local factions = {
  { name = "Alliance", isHeader = true, isCollapsed = false, factionID = 469 },
  { name = "Stormwind", isChild = true, factionID = 72, isWatched = false },
  { name = "Other", isHeader = true, isCollapsed = true, factionID = 1169,
    children = { { name = "Booty Bay", isChild = true, factionID = 21 },
                 { name = "Ravenholdt", isChild = true, factionID = 349 } } },
  { name = "Inactive", isHeader = true, isCollapsed = true, factionID = 1, children = {} },
}
local watchedID
local function visible()
  local out = {}
  for _, f in ipairs(factions) do
    out[#out + 1] = f
    if f.isHeader and not f.isCollapsed and f.children then
      for _, c in ipairs(f.children) do out[#out + 1] = c end
    end
  end
  return out
end
local function data(f)
  if not f then return nil end
  return { name = f.name, isHeader = f.isHeader or false, isCollapsed = f.isCollapsed or false,
           isChild = f.isChild or false, factionID = f.factionID, isWatched = (f.factionID == watchedID),
           reaction = 4, currentReactionThreshold = 0, nextReactionThreshold = 3000, currentStanding = 100 }
end
local function setCollapsed(index, value)
  local f = visible()[index]
  if f and f.isHeader then
    if not value and not f.children then f.children = {} end
    f.isCollapsed = value
  end
end

-- Minimal frames: real sizes, scale and a TOPLEFT-to-BOTTOMLEFT position, so
-- layout arithmetic works and the bar's on-screen spot can be measured.
-- Anything else a frame is asked to do is inert.
local frameMT = {}
frameMT.__index = function(f, k)
  local m = rawget(frameMT, k)
  if m then return m end
  return function() return Stub end
end
function frameMT.SetWidth(f, w) f.w = w end
function frameMT.SetHeight(f, h) f.h = h end
-- Fields are read with rawget: unknown keys resolve to inert methods.
function frameMT.GetWidth(f) return rawget(f, "w") or 0 end
function frameMT.GetHeight(f) return rawget(f, "h") or 0 end
function frameMT.SetScale(f, s) f.scale = s end
function frameMT.GetScale(f) return rawget(f, "scale") or 1 end
function frameMT.GetEffectiveScale(f)
  local parent = rawget(f, "parent")
  return (rawget(f, "scale") or 1) * (parent and parent:GetEffectiveScale() or 1)
end
function frameMT.ClearAllPoints(f) f.point = false end
function frameMT.SetPoint(f, p, rel, relp, x, y) f.point = { p, rel, relp, x or 0, y or 0 } end
function frameMT.GetLeft(f) local pt = rawget(f, "point"); return pt and pt[4] or 0 end
function frameMT.GetTop(f) local pt = rawget(f, "point"); return pt and pt[5] or 0 end
function frameMT.GetFrameLevel() return 1 end
local function NewFrame(_, _, parent)
  return setmetatable({ parent = parent }, frameMT)
end
local UIParent = NewFrame(nil, nil, nil)
-- Where the bar's top-left corner is on screen, in screen units.
local function ScreenTopLeft(f)
  local s = f:GetEffectiveScale()
  return f:GetLeft() * s, f:GetTop() * s
end
local function hooksecurefunc(t, name, post)
  local orig = t[name]
  t[name] = function(...) local r = { orig(...) }; post(...); return unpack(r) end
end

local events, handlers = {}, {}
local addon
local env = {
  _G = nil, -- filled below
  CreateFrame = NewFrame, UIParent = UIParent, hooksecurefunc = hooksecurefunc,
  InCombatLockdown = function() return false end,
  GetBuildInfo = function() return "12.1.0", "99999", "Oct 1 2026", 16001 end,
  WOW_PROJECT_ID = 1, WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CLASSIC = 2,
  WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5, WOW_PROJECT_WRATH_CLASSIC = 11,
  -- Removed on the modern engine:
  GetFactionInfo = false, GetNumFactions = false, GetFactionInfoByID = false,
  GetWatchedFactionInfo = false, SetWatchedFactionIndex = false,
  CollapseFactionHeader = false, ExpandFactionHeader = false,
  GetCurrentCombatTextEventInfo = false, MAX_PLAYER_LEVEL_TABLE = false,
  GetMaxLevelForPlayerExpansion = function() return 60 end,
  C_Reputation = {
    GetNumFactions = function() return #visible() end,
    GetFactionDataByIndex = function(i) return data(visible()[i]) end,
    GetFactionDataByID = function(id) for _, f in ipairs(visible()) do if f.factionID == id then return data(f) end end end,
    GetWatchedFactionData = function() return nil end,
    SetWatchedFactionByID = function(id) watchedID = id end,
    ExpandFactionHeader = function(i) setCollapsed(i, false) end,
    CollapseFactionHeader = function(i) setCollapsed(i, true) end,
  },
  FACTION_STANDING_INCREASED = "Your %s reputation has increased by %d.",
  FACTION_STANDING_INCREASED_GENERIC = "Reputation with %s increased.",
  FACTION_STANDING_INCREASED_BONUS = "Your %s reputation has increased by %d. (+%.1f bonus)",
  COMBATLOG_XPGAIN_FIRSTPERSON = "%s dies, you gain %d experience.",
  COMBATLOG_XPGAIN_FIRSTPERSON_GROUP = "%s dies, you gain %d experience. (+%d group bonus)",
  COMBATLOG_XPGAIN_EXHAUSTION1 = "%s dies, you gain %d experience. (%s exp %s bonus)",
  COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED = "You gain %d experience.",
  FACTION_HORDE = "Horde", FACTION_ALLIANCE = "Alliance", GUILD = "Guild",
  issecretvalue = function() return false end,
  UnitXP = function() return env_xp or 0 end, UnitXPMax = function() return 10000 end,
  UnitLevel = function() return 30 end,
  GetXPExhaustion = function() return env_rested end,
  LibStub = setmetatable({
    GetLibrary = function() return Stub end,
  }, { __call = function(_, name)
    if name == "AceAddon-3.0" then
      return { NewAddon = function(_, n)
        addon = setmetatable({
          RegisterEvent = function(self, e, cb) events[e] = true; handlers[e] = cb end,
          UnregisterEvent = function(self, e) events[e] = nil; handlers[e] = nil end,
          RegisterChatCommand = function() end, Print = function() end,
        }, { __index = function(_, k) if type(k) == "string" and k:match("^%u") then return function() end end end })
        return addon
      end }
    elseif name == "AceLocale-3.0" then
      return { GetLocale = function() return setmetatable({}, { __index = function(_, k) return k end }) end }
    elseif name == "AceDB-3.0" then
      return { New = function(_, _, defaults) return { profile = defaults.profile, RegisterCallback = function() end } end }
    end
    return Stub
  end }),
}
env._G = env
if MODE == "fallback" then
  for _, k in ipairs({ "COMBATLOG_XPGAIN_FIRSTPERSON", "COMBATLOG_XPGAIN_FIRSTPERSON_GROUP",
                       "COMBATLOG_XPGAIN_EXHAUSTION1" }) do env[k] = false end
end
local REMOVED = {}
for k, v in pairs(env) do if v == false then REMOVED[k] = true end end
setmetatable(env, { __index = function(_, k)
  if REMOVED[k] then return nil end
  if _G[k] ~= nil and type(_G[k]) ~= "function" or k == "ipairs" or k == "pairs" or k == "select"
     or k == "tonumber" or k == "tostring" or k == "type" or k == "next" or k == "pcall"
     or k == "setmetatable" or k == "getmetatable" or k == "rawget" or k == "unpack" or k == "error" then
    return _G[k]
  end
  return Stub
end })
for k, v in pairs(env) do if v == false then env[k] = nil end end

local chunk = assert(loadfile(CORE))
setfenv(chunk, env)
local okLoad, loadErr = pcall(chunk)
check("Core.lua loads on simulated Forever", okLoad, loadErr and tostring(loadErr))
if not okLoad then print(table.concat(results, "\n")) return end

-- Find a local (upvalue) by name, searching the addon's methods.
local function upvalue(name)
  for _, fn in pairs(rawget(addon, "__methods") or {}) do end
  for k, fn in pairs(addon) do
    if type(fn) == "function" then
      for i = 1, 200 do
        local n, v = debug.getupvalue(fn, i)
        if not n then break end
        if n == name then return v, fn, i end
      end
    end
  end
end

-- db: point it at the defaults profile.
local _, dbFn, dbIdx = upvalue("db")
-- The addon's own defaults profile, so layout code sees real settings.
local function copy(t) local c = {}; for k, v in pairs(t) do c[k] = type(v) == "table" and copy(v) or v end; return c end
local simdb
for i = 1, 200 do
  local n, v = debug.getupvalue(addon.OnInitialize, i)
  if not n then break end
  if n == "defaults" then simdb = copy(v.profile) end
end
simdb = simdb or { rep = {}, general = {}, xp = {} }
simdb.rep.autowatchrep, simdb.rep.autotrackguild = true, false
debug.setupvalue(dbFn, dbIdx, simdb)

-- Fix 1: event registration and chat parsing (no combat-text API on this client).
pcall(addon.ToggleAutoWatch, addon)
check("auto-watch registers CHAT_MSG_COMBAT_FACTION_CHANGE", events.CHAT_MSG_COMBAT_FACTION_CHANGE == true)
check("auto-watch skips COMBAT_TEXT_UPDATE without the API", events.COMBAT_TEXT_UPDATE == nil)
local okCT = pcall(addon.COMBAT_TEXT_UPDATE, addon, "COMBAT_TEXT_UPDATE", "FACTION")
check("COMBAT_TEXT_UPDATE without the API does not error", okCT)

pcall(function() addon:CHAT_MSG_COMBAT_FACTION_CHANGE("CHAT_MSG_COMBAT_FACTION_CHANGE", "Your Stormwind reputation has increased by 25.") end)
check("chat gain watches a visible faction", watchedID == 72, "watched=" .. tostring(watchedID))

-- Fix 4: faction under a collapsed header; header state restored.
pcall(addon.CHAT_MSG_COMBAT_FACTION_CHANGE, addon, "x", "Your Booty Bay reputation has increased by 1,250. (+62.5 bonus)")
check("bonus/comma message watches faction under collapsed header", watchedID == 21, "watched=" .. tostring(watchedID))
check("collapsed headers restored", factions[3].isCollapsed == true and factions[4].isCollapsed == true)
pcall(addon.CHAT_MSG_COMBAT_FACTION_CHANGE, addon, "x", "Reputation with Ravenholdt increased.")
check("generic (no amount) message works", watchedID == 349, "watched=" .. tostring(watchedID))

local before = watchedID
pcall(addon.CHAT_MSG_COMBAT_FACTION_CHANGE, addon, "x", "Your Stormwind reputation has decreased by 25.")
check("reputation loss is ignored", watchedID == before)
pcall(addon.CHAT_MSG_COMBAT_FACTION_CHANGE, addon, "x", "Your Alliance reputation has increased by 10.")
check("Alliance/Horde header gains are ignored", watchedID == before)
pcall(addon.CHAT_MSG_COMBAT_FACTION_CHANGE, addon, "x", "You receive item: [Linen Cloth].")
check("unrelated chat is ignored", watchedID == before)

-- Secret values: the 12.1 engine hides these from addons in restricted states.
do
  local SECRET = setmetatable({}, { __eq = function() error("compared a secret") end,
                                    __tostring = function() error("inspected a secret") end })
  local notSecret = env.issecretvalue
  env.issecretvalue = function(v) return rawequal(v, SECRET) end
  local fn, idx = addon.COMBAT_TEXT_UPDATE
  for i = 1, 60 do
    local n = debug.getupvalue(fn, i)
    if n == "GetCurrentCombatTextEventInfo" then idx = i; break end
  end
  check("COMBAT_TEXT_UPDATE reads the combat-text API", idx ~= nil)
  local saved = select(2, debug.getupvalue(fn, idx))
  debug.setupvalue(fn, idx, function() return SECRET, SECRET end)
  local okS = pcall(addon.COMBAT_TEXT_UPDATE, addon, "COMBAT_TEXT_UPDATE", "FACTION")
  check("secret combat-text values are skipped", okS and watchedID == before)
  debug.setupvalue(fn, idx, function() return "Stormwind", 25 end)
  watchedID = nil
  pcall(addon.COMBAT_TEXT_UPDATE, addon, "COMBAT_TEXT_UPDATE", "FACTION")
  check("readable combat-text values still watch the faction", watchedID == 72, "watched=" .. tostring(watchedID))
  debug.setupvalue(fn, idx, saved)
  watchedID = before
  local okC = pcall(addon.CHAT_MSG_COMBAT_FACTION_CHANGE, addon, "x", SECRET)
  check("secret chat message is skipped", okC and watchedID == before)
  env.issecretvalue = notSecret
end

-- Fixes 2 and 3: [KTL] history.
local GetNumKTL = (function()
  for k, fn in pairs(addon) do
    if type(fn) == "function" then
      for i = 1, 200 do
        local n, v = debug.getupvalue(fn, i)
        if not n then break end
        if n == "GetXPText" then
          for j = 1, 200 do
            local n2, v2 = debug.getupvalue(v, j)
            if not n2 then break end
            if n2 == "GetNumKTL" then return v2 end
          end
        end
      end
    end
  end
end)()
check("GetNumKTL found", GetNumKTL ~= nil)
local lastXPValues
for i = 1, 50 do
  local n, v = debug.getupvalue(GetNumKTL, i)
  if not n then break end
  if n == "lastXPValues" then lastXPValues = v end
end
check("kill history found", type(lastXPValues) == "table")
local redraws = 0
addon.UpdateXPBar = function() redraws = redraws + 1 end
addon.remXP = 1500
local okK, vK = pcall(GetNumKTL)
check("empty history gives 0 (shown as '?')", okK and vK == 0, tostring(vK))
-- Run the real OnEnable (UI calls hit inert stubs) to exercise event registration.
-- A bar saved near the top of the screen, loaded while the UI scale is 0.73.
simdb.general.posx, simdb.general.posy = 500, 700
UIParent:SetScale(0.73)
-- Kill history saved by the previous session.
addon.db = { char = { killXP = { 250 } } }
local okEnable, enableErr = pcall(addon.OnEnable, addon)
check("OnEnable runs", okEnable, enableErr and tostring(enableErr))
for i = 1, 50 do
  local n, v = debug.getupvalue(GetNumKTL, i)
  if not n then break end
  if n == "lastXPValues" then lastXPValues = v end
end
check("kill history kept across /reload", lastXPValues == addon.db.char.killXP and lastXPValues[1] == 250)
for k in pairs(lastXPValues) do lastXPValues[k] = nil end
env_xp = 7000; addon.cXP = nil
addon:UpdateXPData()   -- first update after login
check("first update after login records no kill", #lastXPValues == 0, "#=" .. #lastXPValues)
if MODE == "fallback" then
  check("fallback: CHAT_MSG_COMBAT_XP_GAIN not registered", events.CHAT_MSG_COMBAT_XP_GAIN == nil)
  env_xp = 7300; addon:UpdateXPData()
  env_xp = 7600; addon:UpdateXPData()
  check("fallback: XP bar gains are recorded", #lastXPValues == 2 and lastXPValues[1] == 300, "#=" .. #lastXPValues)
else
  check("CHAT_MSG_COMBAT_XP_GAIN registered", events.CHAT_MSG_COMBAT_XP_GAIN == true)
  env_xp = 7500; addon:UpdateXPData()   -- quest turn-in moves the bar
  pcall(addon.CHAT_MSG_COMBAT_XP_GAIN, addon, "x", "You gain 500 experience.")
  check("quest/exploration XP is not counted as a kill", #lastXPValues == 0, "#=" .. #lastXPValues)
  pcall(addon.CHAT_MSG_COMBAT_XP_GAIN, addon, "x", "Kobold Vermin dies, you gain 300 experience.")
  pcall(addon.CHAT_MSG_COMBAT_XP_GAIN, addon, "x", "Murloc dies, you gain 300 experience. (+30 group bonus)")
  check("plain and group kill messages are recorded", #lastXPValues == 2 and lastXPValues[2] == 300, "#=" .. #lastXPValues)
  local before = redraws
  pcall(addon.CHAT_MSG_COMBAT_XP_GAIN, addon, "x", "Defias Thug dies, you gain 1,200 experience. (+600 exp Rested bonus)")
  check("rested kill records its base XP", lastXPValues[3] == 600, tostring(lastXPValues[3]))
  check("the bar is redrawn after a kill", redraws == before + 1)
  lastXPValues[3] = nil   -- keep the [KTL] check below simple
  local SECRET = setmetatable({}, { __eq = function() error("compared a secret") end })
  env.issecretvalue = function(v) return rawequal(v, SECRET) end
  local okSec = pcall(addon.CHAT_MSG_COMBAT_XP_GAIN, addon, "x", SECRET)
  env.issecretvalue = function() return false end
  check("secret kill message is skipped", okSec and #lastXPValues == 2)
end
-- Fix 5: the bar keeps its saved spot when the UI scale changes after login
-- (EllesmereUI sets UIParent's scale itself, without UI_SCALE_CHANGED).
do
  local function near(a, b) return math.abs(a - b) < 0.01 end
  local frame = addon.frame
  check("bar frame created", frame ~= nil)
  if frame then
    local x, y = ScreenTopLeft(frame)
    check("bar restored at its saved spot", near(x, 500) and near(y, 700), ("%.1f,%.1f"):format(x, y))
    UIParent:SetScale(0.64)
    x, y = ScreenTopLeft(frame)
    check("UIParent:SetScale after login keeps the saved spot", near(x, 500) and near(y, 700), ("%.1f,%.1f"):format(x, y))
    check("UI_SCALE_CHANGED handled", type(handlers.UI_SCALE_CHANGED) == "function")
    frame.scale = 1.2   -- bar scale changed without a restore
    pcall(handlers.UI_SCALE_CHANGED, "UI_SCALE_CHANGED")
    x, y = ScreenTopLeft(frame)
    check("UI_SCALE_CHANGED restores the saved spot", near(x, 500) and near(y, 700), ("%.1f,%.1f"):format(x, y))
    frame.scale = 1
    addon.moving = true
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 10, 20)
    UIParent:SetScale(0.7)
    check("a bar being dragged is left alone", frame:GetLeft() == 10 and frame:GetTop() == 20)
    addon.moving = nil
  end
end

addon.remXP = 2400
local okK2, vK2 = pcall(GetNumKTL)
check("[KTL] uses real kills: 2400 left / 300 = 8", okK2 and vK2 == 8, tostring(vK2))

if MODE ~= "fallback" then
  local function reset() for k in pairs(lastXPValues) do lastXPValues[k] = nil end end
  local function kill(xp) addon:CHAT_MSG_COMBAT_XP_GAIN("x", "Mob dies, you gain " .. xp .. " experience.") end
  local function ktl() local ok, v = pcall(GetNumKTL); return ok and v or tostring(v) end
  addon.remXP = 2400

  reset(); for _, xp in ipairs({ 300, 300, 300, 300, 3000 }) do kill(xp) end
  check("one elite kill doesn't move [KTL] (median)", ktl() == 8, tostring(ktl()))

  reset(); for _ = 1, 12 do kill(300) end
  check("history keeps the last ten kills", #lastXPValues == 10, "#=" .. #lastXPValues)

  reset(); for _ = 1, 5 do kill(300) end; for _ = 1, 3 do kill(1000) end
  check("new area: three kills over 50% higher drop the older ones", #lastXPValues == 3 and lastXPValues[1] == 1000, "#=" .. #lastXPValues)
  check("new area: [KTL] follows the new mobs", ktl() == 3, tostring(ktl()))
  reset(); for _ = 1, 5 do kill(300) end; kill(1000); kill(300)
  check("one odd kill keeps the history", #lastXPValues == 7, "#=" .. #lastXPValues)

  reset(); for _ = 1, 3 do kill(300) end
  env_rested = 600
  check("rested pool smaller than half: (2400 - 600) / 300 = 6", ktl() == 6, tostring(ktl()))
  env_rested = 5000
  check("rested pool covers it: 2400 / 2 / 300 = 4", ktl() == 4, tostring(ktl()))
  env_rested = nil
end

print(table.concat(results, "\n"))
print(failures == 0 and "ALL PASS" or (failures .. " FAILED"))
