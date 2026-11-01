-- ============================================================
-- LESSON 22: framework.lua — THE BRIDGE.
-- Server-side only; the manifest loads it BEFORE
-- server.lua.
--
-- The problem it solves: our buy functions need money —
-- check it, take it. Whose money? Ours (standalone),
-- ESX's, or QBCore's? If buy code called ESX directly,
-- switching frameworks would mean rewriting every
-- counter. So the counters call ONE door — Fw — and
-- this file knows the three rooms behind it:
--
--   standalone  our own wallets (server.lua fills in
--               StandaloneMoney below; it loads after
--               us, which is fine — these functions run
--               at buy time, not at load time)
--   esx         exports['es_extended'] shared object:
--               player.getMoney() / removeMoney() /
--               addMoney() — the player's CASH
--   qbcore      exports['qb-core'] core object:
--               Player.Functions.GetMoney('cash') /
--               RemoveMoney('cash', n, reason) / ...
--
-- Pick the room in config.lua: Config.Framework.
-- Money is this lesson's whole scope: ITEMS still live
-- in our wallets under every mode (bridging framework
-- inventories is a lesson of its own — framework items
-- must also be defined in the framework's item list).
-- ============================================================
Fw = {}
Fw.Mode = (Config and Config.Framework) or "standalone"

-- Framework objects are fetched LAZILY, on first use:
-- at load time the framework resource may not have
-- answered yet, and in standalone they never exist.
local ESX, QBCore = nil, nil

local function esx()
    if ESX == nil then
        ESX = exports['es_extended']:getSharedObject()
    end
    return ESX
end

local function qb()
    if QBCore == nil then
        QBCore = exports['qb-core']:GetCoreObject()
    end
    return QBCore
end

function Fw.GetMoney(playerId)
    if Fw.Mode == "esx" then
        local player = esx().GetPlayerFromId(playerId)
        if player == nil then return 0 end
        return player.getMoney()
    elseif Fw.Mode == "qbcore" then
        local player = qb().Functions.GetPlayer(playerId)
        if player == nil then return 0 end
        return player.Functions.GetMoney('cash')
    end
    if StandaloneMoney == nil then return 0 end
    return StandaloneMoney.Get(playerId)
end

-- Returns true when the money actually moved. The buy
-- functions check the balance first (for a friendly
-- refusal message), so a false here means the money
-- system itself said no — believe it and stop.
function Fw.RemoveMoney(playerId, amount)
    if Fw.Mode == "esx" then
        local player = esx().GetPlayerFromId(playerId)
        if player == nil then return false end
        player.removeMoney(amount)
        return true
    elseif Fw.Mode == "qbcore" then
        local player = qb().Functions.GetPlayer(playerId)
        if player == nil then return false end
        return player.Functions.RemoveMoney('cash', amount, 'shops') == true
    end
    if StandaloneMoney == nil then return false end
    return StandaloneMoney.Remove(playerId, amount)
end

function Fw.AddMoney(playerId, amount)
    if Fw.Mode == "esx" then
        local player = esx().GetPlayerFromId(playerId)
        if player == nil then return false end
        player.addMoney(amount)
        return true
    elseif Fw.Mode == "qbcore" then
        local player = qb().Functions.GetPlayer(playerId)
        if player == nil then return false end
        return player.Functions.AddMoney('cash', amount, 'shops') == true
    end
    if StandaloneMoney == nil then return false end
    return StandaloneMoney.Add(playerId, amount)
end

print('[shops] framework mode: ' .. Fw.Mode ..
      (Fw.Mode == 'standalone'
        and ' (our own wallets)' or ' (money owned by the framework)'))
