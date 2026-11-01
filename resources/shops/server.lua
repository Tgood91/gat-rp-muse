-- ============================================================
-- LESSON 16: server.lua — THE SERVER OWNS THE TRUTH.
-- This file runs once, on the server. Gold, stock, and the
-- restock timer live here and NOWHERE else.
--
-- Why: a client is the player's own PC. A modded client
-- can send ANY event with ANY numbers in it. So the
-- client never decides anything — it asks, and this file
-- re-checks everything: Lessons 13–15's check -> move ->
-- report, with a network in the middle.
--
-- The data is Lessons 14/15 carried over: the vendors,
-- the all-ammo catalog, capacities, demand, and the 80%
-- restock rule. The new parts are wallets (one per
-- player), net events (the ask/reply), and a real thread
-- for the timer instead of runCity().
--
-- LESSON 17 ADDITION: you have to BE there. Each vendor
-- now has a real spot on the map (config.lua, shared).
-- buyAmmo also checks where the player is standing —
-- and the coords are read here, from the player's ped
-- on the server. A client is never asked "where are
-- you?": a modded client would just answer "at the
-- shop" from across the map.
--
-- LESSON 18 ADDITION: it survives a restart. Wallets and
-- stock are saved to a file (data.json) and loaded back
-- at boot — and wallets are keyed by the player's license
-- identifier, because `source` is a seat number that
-- changes every session. Details at PERSISTENCE below.
-- ============================================================

-- ---------- The shops (Lesson 14) ----------
CustomVendors = {
    glizzysDepot = {
        label = "Glizzys Depot", place = "g2g1",
        sells = { "fuel", "glizzyDog", "water" },
    },
    tummyExpress = {
        label = "Tanaz-tummy Express", place = "tummy2",
        sells = { "beans", "energyDrink" },
    },
    bushidoSupply = {
        label = "Bushido Supply", place = "gunStore",
        sells = { "armour" },  -- armour ONLY: ammo is Tanaz Ammo's
                               -- whole job (name cleanup, per Tanner)
    },
    tanazAmmo = {
        label = "Tanaz Ammo", place = "gunStore",
        sells = { "ammo" },  -- the category: EVERY ammo type
    },
}

-- ALL ammo in one catalog: base types + custom (Lesson 14).
AmmoCatalog = {
    ammo = { label = "AR Rounds", pricePerRound = 2 },
    pistolAmmo = { label = "Pistol Rounds", pricePerRound = 1 },
    rounds556 = { label = "5.56 Rounds", pricePerRound = 3 },
    shells12 = { label = "12 Gauge Shells", pricePerRound = 5 },
}
AMMO_ORDER = { "ammo", "pistolAmmo", "rounds556", "shells12" }

VendorOrder = { "glizzysDepot", "tummyExpress", "bushidoSupply", "tanazAmmo" }

VendorCapacity = {
    glizzysDepot = { fuel = 200, glizzyDog = 20, water = 50 },
    tummyExpress = { beans = 40, energyDrink = 30 },
    bushidoSupply = {
        kevlarVest = 5, ceramicCarrier = 2,
        bushidoCarbine = 2, harborShotgun = 2,
        rounds556 = 200, shells12 = 100,
    },
    tanazAmmo = {
        ammo = 1000, pistolAmmo = 500,
        rounds556 = 250, shells12 = 100,
    },
}

VendorStock = {}  -- filled by the restock at boot, below

-- The city still buys while nobody is shopping (Lesson 15).
Demand = {
    glizzysDepot = { fuel = 15, glizzyDog = 3, water = 5 },
    tummyExpress = { beans = 4, energyDrink = 3 },
    bushidoSupply = {
        kevlarVest = 1, ceramicCarrier = 0,
        bushidoCarbine = 0, harborShotgun = 0,
        rounds556 = 20, shells12 = 5,
    },
    tanazAmmo = {
        ammo = 60, pistolAmmo = 35,
        rounds556 = 15, shells12 = 6,
    },
}

RESTOCK_EVERY = 4     -- city hours between auto restocks
RESTOCK_PERCENT = 80  -- Tanner's rule
TICK_MS = 60000       -- one city hour = 60 real seconds,
                      -- short so you can WATCH it work.
                      -- A live server would use far longer.

-- ============================================================
-- RESTOCK + DEMAND — Lessons 14/15, word for word.
-- ============================================================
function restockAllVendors(percent)
    for i = 1, #VendorOrder do
        local vendorKey = VendorOrder[i]
        local vendor = CustomVendors[vendorKey]
        local caps = VendorCapacity[vendorKey]
        if VendorStock[vendorKey] == nil then
            VendorStock[vendorKey] = {}
        end
        local shelf = VendorStock[vendorKey]
        for itemKey, cap in pairs(caps) do
            local target = cap * percent // 100
            if (shelf[itemKey] or 0) < target then
                shelf[itemKey] = target
            end
        end
        print("[shops] " .. vendor.label .. " stocked to " .. percent .. "%.")
    end
end

function cityBuys()
    for i = 1, #VendorOrder do
        local vendorKey = VendorOrder[i]
        local shelf = VendorStock[vendorKey]
        local demand = Demand[vendorKey]
        if shelf ~= nil and demand ~= nil then
            for itemKey, rate in pairs(demand) do
                local onShelf = shelf[itemKey] or 0
                local sold = math.min(rate, onShelf)
                shelf[itemKey] = onShelf - sold
            end
        end
    end
end

-- ============================================================
-- WALLETS — one per player. LESSON 18 CHANGE: keyed by
-- the player's LICENSE identifier, not their source.
-- source is a seat number: it changes every time they
-- connect, so a wallet keyed by source would belong to
-- whoever sits down next. An identifier follows the
-- player — and a saved wallet can only be found again
-- after a restart if its key survives the restart too.
-- Created on first use: 6000 gold, no ammo.
-- Later this is where a framework (ESX/QBCore) plugs in.
-- ============================================================
PlayerWallets = {}

function playerKey(playerId)
    return GetPlayerIdentifierByType(playerId, 'license')
        or ("session:" .. playerId)  -- fallback: never crash
end

function getWallet(playerId)
    local key = playerKey(playerId)
    if PlayerWallets[key] == nil then
        PlayerWallets[key] = { gold = 6000, owned = {} }
    end
    return PlayerWallets[key]
end

-- ============================================================
-- PERSISTENCE (Lesson 18) — memory dies on restart; a
-- file doesn't. All state (wallets + stock) is packed
-- into ONE table, turned into JSON text, and written to
-- data.json inside this resource's own folder with
-- SaveResourceFile. At boot, LoadResourceFile reads it
-- back and json.decode unpacks it.
--
-- Save WHEN:
--   * the moment money moves (a successful buy),
--   * when a player leaves (playerDropped),
--   * when the resource stops (onResourceStop).
-- A hard crash can still lose the last few minutes —
-- that's the honest limit of file saves, and why busy
-- servers grow into databases later.
--
-- JSON trap: numbers come back as DECIMALS (5980.0), so
-- every count is floored back to a whole number on load.
-- ============================================================
local RESOURCE_NAME = GetCurrentResourceName()
local DATA_FILE = "data.json"

function saveData()
    local payload = json.encode({
        wallets = PlayerWallets,
        stock = VendorStock,
    })
    SaveResourceFile(RESOURCE_NAME, DATA_FILE, payload, -1)
end

function loadData()
    local raw = LoadResourceFile(RESOURCE_NAME, DATA_FILE)
    if raw == nil then
        print("[shops] no save file yet - fresh start.")
        return
    end
    local data = json.decode(raw)
    if data == nil then
        print("[shops] save file unreadable - fresh start.")
        return
    end
    if data.wallets ~= nil then
        PlayerWallets = data.wallets
        for key, wallet in pairs(PlayerWallets) do
            wallet.gold = math.floor(wallet.gold or 6000)
            for ammoKey, count in pairs(wallet.owned or {}) do
                wallet.owned[ammoKey] = math.floor(count)
            end
        end
    end
    if data.stock ~= nil then
        VendorStock = data.stock
        for vendorKey, shelf in pairs(VendorStock) do
            for itemKey, count in pairs(shelf) do
                shelf[itemKey] = math.floor(count)
            end
        end
    end
    print("[shops] save loaded: wallets + stock restored.")
end

-- Does this vendor's sells list open the door for an ammo
-- buy? The category entry "ammo" covers every ammo key.
function vendorSellsAmmo(vendor)
    for i = 1, #vendor.sells do
        if vendor.sells[i] == "ammo" then
            return true
        end
    end
    return false
end

-- ============================================================
-- BUY AMMO — check -> move -> report, server-side.
-- Returns true/false plus the message for the player.
-- Every check is redone HERE even if a client also checks:
-- a modified client can lie, this function can't be
-- reached around. Amount is treated as hostile input:
-- forced through tonumber and floored before any math.
-- This resource's buy flow sells ammo only, from Tanaz
-- Ammo. Bushido Supply is armour-only, and gear buying
-- gets its own event in a later lesson.
-- ============================================================
function buyAmmo(playerId, vendorKey, ammoKey, amount, playerCoords)
    local wallet = getWallet(playerId)
    local vendor = CustomVendors[vendorKey]
    local item = AmmoCatalog[ammoKey]
    amount = math.floor(tonumber(amount) or 0)

    if vendor == nil then
        return false, "No such vendor: " .. tostring(vendorKey)
    elseif item == nil then
        return false, "No such ammo: " .. tostring(ammoKey)
    elseif not vendorSellsAmmo(vendor) then
        return false, vendor.label .. " doesn't sell ammo."
    elseif amount < 1 then
        return false, "Amount must be 1 or more."
    end

    -- The Lesson 17 check: standing at the shop?
    -- #(a - b) is the distance between two points —
    -- vector math does the Lesson 7 sqrt for you.
    local spot = Config.Vendors[vendorKey]
    if spot == nil then
        return false, "No shop spot set for: " .. tostring(vendorKey)
    elseif #(playerCoords - spot.coords) > Config.BuyRange then
        return false, "You need to be at " .. vendor.label ..
               " to buy from it."
    end

    local shelf = VendorStock[vendorKey]
    local inStock = 0
    if shelf ~= nil and shelf[ammoKey] ~= nil then
        inStock = shelf[ammoKey]
    end
    local cost = item.pricePerRound * amount

    if inStock < amount then
        return false, vendor.label .. " has " .. inStock ..
               " x " .. item.label .. " - not enough."
    elseif wallet.gold < cost then
        return false, "Not enough gold: " .. amount .. " x " ..
               item.label .. " costs " .. cost .. "."
    else
        wallet.gold = wallet.gold - cost
        shelf[ammoKey] = inStock - amount
        wallet.owned[ammoKey] = (wallet.owned[ammoKey] or 0) + amount
        saveData()  -- money moved: save NOW, not later
        return true, "Bought " .. amount .. " x " .. item.label ..
               " for " .. cost .. " gold at " .. vendor.label ..
               ". Gold: " .. wallet.gold
    end
end

-- A wallet readout as one line, built here so the client
-- stays dumb: it just prints what the server sends.
function walletSummary(playerId)
    local wallet = getWallet(playerId)
    local parts = {}
    for i = 1, #AMMO_ORDER do
        local key = AMMO_ORDER[i]
        parts[#parts + 1] = (wallet.owned[key] or 0) .. " " ..
                            AmmoCatalog[key].label
    end
    return "Gold: " .. wallet.gold .. " | Ammo: " ..
           table.concat(parts, ", ")
end

-- ============================================================
-- THE EVENTS — the network in the middle.
-- RegisterNetEvent says "clients may call this name."
-- Inside the handler, the global `source` is WHO asked:
-- FiveM sets it per event, and the client cannot fake
-- another player's id. Replies go back to that source
-- only: TriggerClientEvent(name, target, ...).
-- ============================================================
RegisterNetEvent('shops:buyAmmo')
AddEventHandler('shops:buyAmmo', function(ammoKey, amount)
    local playerId = source
    -- Where is this player REALLY standing? Read it here,
    -- from their ped (their in-game body), never from the
    -- event: event data comes from the client, coords
    -- from the ped come from the game itself.
    local coords = GetEntityCoords(GetPlayerPed(playerId))
    -- This lesson's counter is Tanaz Ammo: ALL ammo.
    local ok, message = buyAmmo(playerId, "tanazAmmo",
                                ammoKey, amount, coords)
    TriggerClientEvent('shops:result', playerId, message)
end)

RegisterNetEvent('shops:getWallet')
AddEventHandler('shops:getWallet', function()
    TriggerClientEvent('shops:wallet', source,
                       walletSummary(source))
end)

-- Server console command: restock right now.
-- source 0 is the console itself — players who try this
-- in-game get told no. (Type it in the server console.)
RegisterCommand('restocknow', function(src, args, raw)
    if src == 0 then
        restockAllVendors(RESTOCK_PERCENT)
    else
        print("[shops] restocknow is console-only.")
    end
end, false)

-- The other two save points: a player leaving, and the
-- resource shutting down cleanly. (playerDropped fires
-- on the server when someone disconnects.)
AddEventHandler('playerDropped', function(reason)
    saveData()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == RESOURCE_NAME then
        saveData()
        print("[shops] saved on shutdown.")
    end
end)

-- ============================================================
-- BOOT + THE TIMER THREAD.
-- CreateThread starts a loop that runs alongside the
-- game. Wait(TICK_MS) parks it — other code keeps
-- running. This is Lesson 15's runCity(), grown up:
-- each pass is one city hour; every RESTOCK_EVERY hours
-- the 80% restock fires on its own.
-- ============================================================
loadData()  -- Lesson 18: yesterday's world first...
restockAllVendors(RESTOCK_PERCENT)  -- ...then the 80% rule tops up (never drains)
print("[shops] started. One city hour = " ..
      (TICK_MS // 1000) .. "s; auto-restock every " ..
      RESTOCK_EVERY .. " city hours.")

CreateThread(function()
    local sinceRestock = 0
    while true do
        Wait(TICK_MS)
        cityBuys()
        sinceRestock = sinceRestock + 1
        if sinceRestock >= RESTOCK_EVERY then
            print("[shops] auto-restock (timer):")
            restockAllVendors(RESTOCK_PERCENT)
            sinceRestock = 0
        end
    end
end)
