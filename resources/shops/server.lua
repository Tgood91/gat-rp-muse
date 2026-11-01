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
--
-- LESSON 19 ADDITION: Bushido Supply gets its own proper
-- counter. buyArmour + /buyarmor sell its three armour
-- tiers (low / medium / max) — armour-only, as decided
-- in the name cleanup. Same recipe as buyAmmo; the
-- range check is now shared by both counters.
--
-- LESSON 25 NOTE: every gold read/move below goes
-- through the framework bridge (Fw, framework.lua) —
-- standalone it lands in these wallets; with ESX or
-- QBCore selected in config.lua, the framework's cash
-- is the truth and our gold field sits unused.
--
-- LESSON 26 ADDITION: NEEDS. Hunger + thirst per player
-- (Lesson 8's vitals, server-owned), draining on the
-- city timer, an empty stat taxing health, and eating
-- that spends the food Lesson 24 sells. Details at
-- NEEDS below.
--
-- LESSON 20 ADDITION: a real MENU (NUI). The server
-- builds each shop's menu (items, prices, live stock,
-- the asker's gold) and the client's web page just draws
-- it. Menu buys arrive as 'shops:buyItem' and land in
-- the SAME buyAmmo/buyArmour checks — new front door,
-- same counters. See menuFor below.
--
-- LESSON 24 ADDITION: FOOD COUNTERS. Glizzys Depot and
-- Tanaz-tummy Express finally sell: a FoodCatalog (the
-- Lesson 1 prices, with Lesson 8's hunger/thirst values
-- riding along as data) plus buyFood — the same recipe
-- a third time. Their menus open for real now.
-- ============================================================

-- ---------- The shops (Lesson 14) ----------
CustomVendors = {
    glizzysDepot = {
        label = "Glizzys Depot", place = "g2g1",
        sells = { "food" },  -- Lesson 24: category form, like ammo/armour (fuel has no counter yet — a later lesson)
    },
    tummyExpress = {
        label = "Tanaz-tummy Express", place = "tummy2",
        sells = { "food" },  -- Lesson 24: category form, like ammo/armour
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

-- Bushido Supply's armour ladder (Lesson 19): three
-- tiers, priced by protection. Flat prices — a vest is
-- bought whole, not by the round.
ArmourCatalog = {
    lowArmor = { label = "Low Armour Vest", price = 200, protection = 25 },
    mediumArmor = { label = "Medium Armour Vest", price = 450, protection = 50 },
    maxArmor = { label = "Max Armour Vest", price = 800, protection = 100 },
}
ARMOUR_ORDER = { "lowArmor", "mediumArmor", "maxArmor" }

-- The food catalog (Lesson 24). Prices are Lesson 1's;
-- hunger/thirst are Lesson 8's eat/drink values, kept
-- as DATA for now — a needs system can spend them later.
-- Each food shop stocks only its own slice (see
-- VendorCapacity): Glizzys = dogs + water, Tummy
-- Express = beans + energy drinks, as in Lesson 9.
-- Keys match this resource's stock tables (water, beans
-- — the short names the shelves already use).
FoodCatalog = {
    glizzyDog = { label = "Glizzy Dog", price = 50, hunger = 40 },
    water = { label = "Water Bottle", price = 10, thirst = 50 },
    beans = { label = "Canned Beans", price = 15, hunger = 25 },
    energyDrink = { label = "Energy Drink", price = 20, thirst = 30 },
}
FOOD_ORDER = { "glizzyDog", "water", "beans", "energyDrink" }

VendorOrder = { "glizzysDepot", "tummyExpress", "bushidoSupply", "tanazAmmo" }

VendorCapacity = {
    glizzysDepot = { fuel = 200, glizzyDog = 20, water = 50 },
    tummyExpress = { beans = 40, energyDrink = 30 },
    bushidoSupply = {  -- armour ONLY: no phantom gear/ammo shelves
        lowArmor = 5, mediumArmor = 3, maxArmor = 2,
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
    bushidoSupply = { lowArmor = 1, mediumArmor = 0, maxArmor = 0 },
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

-- Lesson 26: which seat (source) each known player is
-- in right now, so the needs tick can reach ONLINE
-- players. Offline hunger simply waits.
PlayerSources = {}

function playerKey(playerId)
    local key = GetPlayerIdentifierByType(playerId, 'license')
        or ("session:" .. playerId)  -- fallback: never crash
    PlayerSources[key] = playerId
    return key
end

function getWallet(playerId)
    local key = playerKey(playerId)
    if PlayerWallets[key] == nil then
        PlayerWallets[key] = {
            gold = 6000, owned = {}, ownedArmour = {}, ownedFood = {},
        }
    end
    if PlayerWallets[key].ownedArmour == nil then
        PlayerWallets[key].ownedArmour = {}  -- pre-Lesson-19 save
    end
    if PlayerWallets[key].ownedFood == nil then
        PlayerWallets[key].ownedFood = {}  -- pre-Lesson-21 save
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

-- ============================================================
-- STANDALONE MONEY (Lesson 25) — the bridge's home room.
-- framework.lua's Fw calls these when Config.Framework
-- is "standalone". Under esx/qbcore they're never
-- called: the framework's cash is the money.
-- ============================================================
StandaloneMoney = {
    Get = function(playerId)
        return getWallet(playerId).gold
    end,
    Remove = function(playerId, amount)
        local wallet = getWallet(playerId)
        if wallet.gold < amount then
            return false
        end
        wallet.gold = wallet.gold - amount
        return true
    end,
    Add = function(playerId, amount)
        local wallet = getWallet(playerId)
        wallet.gold = wallet.gold + amount
        return true
    end,
}

-- The one gold question every counter asks.
function playerGold(playerId)
    return Fw.GetMoney(playerId)
end

function saveData()
    local walletsToSave = PlayerWallets
    if Fw.Mode ~= "standalone" then
        -- The framework owns the money: save ITEMS only,
        -- so a restart can never resurrect stale gold.
        walletsToSave = {}
        for key, wallet in pairs(PlayerWallets) do
            walletsToSave[key] = {
                owned = wallet.owned,
                ownedArmour = wallet.ownedArmour,
                ownedFood = wallet.ownedFood,
            }
        end
    end
    local payload = json.encode({
        wallets = walletsToSave,
        stock = VendorStock,
        needs = PlayerNeeds,  -- Lesson 26: saved in EVERY mode
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
            if Fw.Mode == "standalone" then
                wallet.gold = math.floor(wallet.gold or 6000)
            else
                wallet.gold = nil  -- framework mode: never restore our gold
            end
            for ammoKey, count in pairs(wallet.owned or {}) do
                wallet.owned[ammoKey] = math.floor(count)
            end
            for armourKey, count in pairs(wallet.ownedArmour or {}) do
                wallet.ownedArmour[armourKey] = math.floor(count)
            end
            for foodKey, count in pairs(wallet.ownedFood or {}) do
                wallet.ownedFood[foodKey] = math.floor(count)
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
    if data.needs ~= nil then
        PlayerNeeds = data.needs
        for key, needs in pairs(PlayerNeeds) do
            -- Floored (JSON decimals) and clamped to 0-100.
            needs.hunger = math.max(0, math.min(100,
                math.floor(needs.hunger or 100)))
            needs.thirst = math.max(0, math.min(100,
                math.floor(needs.thirst or 100)))
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
-- NEEDS (Lesson 26) — hunger + thirst, server-owned.
-- Lesson 8's vitals as a real system: 100 = full, and
-- each city hour drains them at Lesson 8's rates. A
-- stat at zero taxes health: EMPTY_TAX per hour, PER
-- empty stat (both empty = double tax, as in Lesson 8).
-- Eating spends ownedFood — the FoodCatalog's hunger/
-- thirst values, idle since Lesson 24, finally move.
-- ============================================================
PlayerNeeds = {}

HUNGER_DRAIN = 10  -- per city hour (Lesson 8)
THIRST_DRAIN = 15  -- per city hour (Lesson 8)
EMPTY_TAX = 5      -- health per city hour, per empty stat

function getNeeds(playerId)
    local key = playerKey(playerId)
    if PlayerNeeds[key] == nil then
        PlayerNeeds[key] = { hunger = 100, thirst = 100 }
    end
    return PlayerNeeds[key]
end

function needsLine(needs)
    return "Hunger: " .. needs.hunger ..
           " | Thirst: " .. needs.thirst
end

-- One city hour of being alive, called by the timer
-- thread. Only ONLINE players drain (PlayerSources
-- knows their seats). The server DECIDES the health
-- tax and sends the new levels; the client APPLIES the
-- tax, because a ped's health lives on the player's
-- own machine — the same split as everything else.
function needsTick()
    for key, needs in pairs(PlayerNeeds) do
        local src = PlayerSources[key]
        if src ~= nil then
            needs.hunger = math.max(0, needs.hunger - HUNGER_DRAIN)
            needs.thirst = math.max(0, needs.thirst - THIRST_DRAIN)
            local tax = 0
            if needs.hunger <= 0 then tax = tax + EMPTY_TAX end
            if needs.thirst <= 0 then tax = tax + EMPTY_TAX end
            TriggerClientEvent('shops:needs', src, {
                hunger = needs.hunger, thirst = needs.thirst,
                healthTax = tax,
            })
        end
    end
end

-- Eat or drink one owned food item: the wallet says
-- whether you have one, the catalog says what it
-- restores (capped at 100, like Lesson 8).
function useFood(playerId, foodKey)
    local wallet = getWallet(playerId)
    local item = FoodCatalog[foodKey]
    if item == nil then
        return false, "No such food: " .. tostring(foodKey)
    end
    local have = wallet.ownedFood[foodKey] or 0
    if have < 1 then
        return false, "You have no " .. item.label .. "."
    end
    wallet.ownedFood[foodKey] = have - 1
    local needs = getNeeds(playerId)
    needs.hunger = math.min(100, needs.hunger + (item.hunger or 0))
    needs.thirst = math.min(100, needs.thirst + (item.thirst or 0))
    saveData()
    local verb = "Ate"
    if item.hunger == nil then verb = "Drank" end
    return true, verb .. " 1 x " .. item.label .. ". " ..
           needsLine(needs), needs
end

-- ============================================================
-- RANGE CHECK — Lesson 17's "be there" rule, shared by
-- every counter since Lesson 19. #(a - b) is the distance
-- between two points: vector math does Lesson 7's sqrt
-- for you. Returns true, or false + the refusal message.
-- ============================================================
function rangeCheck(vendorKey, vendor, playerCoords)
    local spot = Config.Vendors[vendorKey]
    if spot == nil then
        return false, "No shop spot set for: " .. tostring(vendorKey)
    elseif #(playerCoords - spot.coords) > Config.BuyRange then
        return false, "You need to be at " .. vendor.label ..
               " to buy from it."
    end
    return true, nil
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

    -- The Lesson 17 check, shared since Lesson 19:
    -- standing at the shop?
    local inRange, rangeMsg = rangeCheck(vendorKey, vendor, playerCoords)
    if not inRange then
        return false, rangeMsg
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
    elseif playerGold(playerId) < cost then
        return false, "Not enough gold: " .. amount .. " x " ..
               item.label .. " costs " .. cost .. "."
    else
        Fw.RemoveMoney(playerId, cost)
        shelf[ammoKey] = inStock - amount
        wallet.owned[ammoKey] = (wallet.owned[ammoKey] or 0) + amount
        saveData()  -- money moved: save NOW, not later
        return true, "Bought " .. amount .. " x " .. item.label ..
               " for " .. cost .. " gold at " .. vendor.label ..
               ". Gold: " .. playerGold(playerId)
    end
end

-- Does this vendor's sells list include a CATEGORY?
-- (vendorSellsAmmo above is the ammo-only version of
-- this question, kept from Lesson 16.)
function vendorSellsCategory(vendor, category)
    for i = 1, #vendor.sells do
        if vendor.sells[i] == category then
            return true
        end
    end
    return false
end

-- ============================================================
-- BUY ARMOUR (Lesson 19) — Bushido Supply's counter.
-- Same recipe as buyAmmo, three differences: the catalog
-- is ArmourCatalog, the price is FLAT (item.price, not
-- per-round), and purchases land in ownedArmour.
-- The vendor must sell the "armour" category — since
-- the name cleanup, Bushido Supply is the ONLY armour
-- seller, and Tanaz Ammo refuses armour the way Bushido
-- refuses ammo. One counter, one job.
-- ============================================================
function buyArmour(playerId, vendorKey, armourKey, amount, playerCoords)
    local wallet = getWallet(playerId)
    local vendor = CustomVendors[vendorKey]
    local item = ArmourCatalog[armourKey]
    amount = math.floor(tonumber(amount) or 0)

    if vendor == nil then
        return false, "No such vendor: " .. tostring(vendorKey)
    elseif item == nil then
        return false, "No such armour: " .. tostring(armourKey)
    elseif not vendorSellsCategory(vendor, "armour") then
        return false, vendor.label .. " doesn't sell armour."
    elseif amount < 1 then
        return false, "Amount must be 1 or more."
    end

    local inRange, rangeMsg = rangeCheck(vendorKey, vendor, playerCoords)
    if not inRange then
        return false, rangeMsg
    end

    local shelf = VendorStock[vendorKey]
    local inStock = 0
    if shelf ~= nil and shelf[armourKey] ~= nil then
        inStock = shelf[armourKey]
    end
    local cost = item.price * amount

    if inStock < amount then
        return false, vendor.label .. " has " .. inStock ..
               " x " .. item.label .. " - not enough."
    elseif playerGold(playerId) < cost then
        return false, "Not enough gold: " .. amount .. " x " ..
               item.label .. " costs " .. cost .. "."
    else
        Fw.RemoveMoney(playerId, cost)
        shelf[armourKey] = inStock - amount
        wallet.ownedArmour[armourKey] =
            (wallet.ownedArmour[armourKey] or 0) + amount
        saveData()  -- money moved: save NOW, not later
        return true, "Bought " .. amount .. " x " .. item.label ..
               " (" .. item.protection .. " protection) for " ..
               cost .. " gold at " .. vendor.label ..
               ". Gold: " .. playerGold(playerId)
    end
end

-- ============================================================
-- BUY FOOD (Lesson 24) — Glizzys + Tummy Express.
-- The same recipe a third time: catalog lookup, the
-- vendor must sell the "food" category, range, shelf,
-- gold — then move and save. Purchases land in
-- ownedFood. Eating them (Lesson 8's needs) is a later
-- lesson; today the counters SELL.
-- ============================================================
function buyFood(playerId, vendorKey, foodKey, amount, playerCoords)
    local wallet = getWallet(playerId)
    local vendor = CustomVendors[vendorKey]
    local item = FoodCatalog[foodKey]
    amount = math.floor(tonumber(amount) or 0)

    if vendor == nil then
        return false, "No such vendor: " .. tostring(vendorKey)
    elseif item == nil then
        return false, "No such food: " .. tostring(foodKey)
    elseif not vendorSellsCategory(vendor, "food") then
        return false, vendor.label .. " doesn't sell food."
    elseif amount < 1 then
        return false, "Amount must be 1 or more."
    end

    local inRange, rangeMsg = rangeCheck(vendorKey, vendor, playerCoords)
    if not inRange then
        return false, rangeMsg
    end

    local shelf = VendorStock[vendorKey]
    local inStock = 0
    if shelf ~= nil and shelf[foodKey] ~= nil then
        inStock = shelf[foodKey]
    end
    local cost = item.price * amount

    if inStock < amount then
        return false, vendor.label .. " has " .. inStock ..
               " x " .. item.label .. " - not enough."
    elseif playerGold(playerId) < cost then
        return false, "Not enough gold: " .. amount .. " x " ..
               item.label .. " costs " .. cost .. "."
    else
        Fw.RemoveMoney(playerId, cost)
        shelf[foodKey] = inStock - amount
        wallet.ownedFood[foodKey] =
            (wallet.ownedFood[foodKey] or 0) + amount
        saveData()  -- money moved: save NOW, not later
        return true, "Bought " .. amount .. " x " .. item.label ..
               " for " .. cost .. " gold at " .. vendor.label ..
               ". Gold: " .. playerGold(playerId)
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
    local armourParts = {}
    for i = 1, #ARMOUR_ORDER do
        local key = ARMOUR_ORDER[i]
        armourParts[#armourParts + 1] =
            (wallet.ownedArmour[key] or 0) .. " " ..
            ArmourCatalog[key].label
    end
    local foodParts = {}
    for i = 1, #FOOD_ORDER do
        local key = FOOD_ORDER[i]
        foodParts[#foodParts + 1] =
            (wallet.ownedFood[key] or 0) .. " " ..
            FoodCatalog[key].label
    end
    return "Gold: " .. playerGold(playerId) .. " | Ammo: " ..
           table.concat(parts, ", ") .. " | Armour: " ..
           table.concat(armourParts, ", ") .. " | Food: " ..
           table.concat(foodParts, ", ")
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

RegisterNetEvent('shops:buyArmour')
AddEventHandler('shops:buyArmour', function(armourKey, amount)
    local playerId = source
    local coords = GetEntityCoords(GetPlayerPed(playerId))
    -- This counter is Bushido Supply: armour only.
    local ok, message = buyArmour(playerId, "bushidoSupply",
                                  armourKey, amount, coords)
    TriggerClientEvent('shops:result', playerId, message)
end)

-- ============================================================
-- THE MENU (Lesson 20) — the server builds it, the page
-- just draws it. A menu is a snapshot: this vendor's
-- buyable items, their prices, the LIVE shelf counts,
-- and the asking player's gold. A vendor with nothing
-- buyable returns nil — the client tells the player
-- instead of opening an empty window.
-- ============================================================
function menuFor(playerId, vendorKey)
    local vendor = CustomVendors[vendorKey]
    if vendor == nil then
        return nil
    end
    local wallet = getWallet(playerId)
    local shelf = VendorStock[vendorKey] or {}
    local items = {}

    if vendorSellsCategory(vendor, "ammo") then
        for i = 1, #AMMO_ORDER do
            local key = AMMO_ORDER[i]
            local item = AmmoCatalog[key]
            items[#items + 1] = {
                kind = "ammo", key = key, label = item.label,
                detail = item.pricePerRound .. " gold / round",
                price = item.pricePerRound,
                stock = shelf[key] or 0,
            }
        end
    end
    if vendorSellsCategory(vendor, "armour") then
        for i = 1, #ARMOUR_ORDER do
            local key = ARMOUR_ORDER[i]
            local item = ArmourCatalog[key]
            items[#items + 1] = {
                kind = "armour", key = key, label = item.label,
                detail = item.protection .. " protection",
                price = item.price,
                stock = shelf[key] or 0,
            }
        end
    end

    if vendorSellsCategory(vendor, "food") then
        -- A food menu lists only what THIS shop stocks:
        -- its VendorCapacity entry is the carrying list
        -- (Lesson 9's rule — one chain, one menu).
        local cap = VendorCapacity[vendorKey] or {}
        for i = 1, #FOOD_ORDER do
            local key = FOOD_ORDER[i]
            local item = FoodCatalog[key]
            if cap[key] ~= nil then
                local detail
                if item.hunger ~= nil then
                    detail = "+" .. item.hunger .. " hunger"
                else
                    detail = "+" .. item.thirst .. " thirst"
                end
                items[#items + 1] = {
                    kind = "food", key = key, label = item.label,
                    detail = detail,
                    price = item.price,
                    stock = shelf[key] or 0,
                }
            end
        end
    end

    if #items == 0 then
        return nil
    end
    return {
        vendorKey = vendorKey, vendor = vendor.label,
        gold = playerGold(playerId), items = items,
    }
end

RegisterNetEvent('shops:getMenu')
AddEventHandler('shops:getMenu', function(vendorKey)
    local playerId = source
    local menu = menuFor(playerId, vendorKey)
    if menu == nil then
        local vendor = CustomVendors[vendorKey]
        local label = "That shop"
        if vendor ~= nil then
            label = vendor.label
        end
        TriggerClientEvent('shops:result', playerId, label ..
            " has no counter yet - coming in a later lesson.")
    else
        TriggerClientEvent('shops:menu', playerId, menu)
    end
end)

-- A menu click. The page names a vendor — but the
-- server trusts NOTHING about that: buyAmmo/buyArmour
-- re-check the vendor, its sells list, the range (from
-- the player's real position), the shelf, and the gold.
-- A forged menu request fails exactly like a forged
-- chat command. After the buy, a FRESH menu goes back
-- so the open window shows the new gold + stock.
RegisterNetEvent('shops:buyItem')
AddEventHandler('shops:buyItem', function(vendorKey, kind, key, amount)
    local playerId = source
    local coords = GetEntityCoords(GetPlayerPed(playerId))
    local ok, message
    if kind == "ammo" then
        ok, message = buyAmmo(playerId, vendorKey, key, amount, coords)
    elseif kind == "armour" then
        ok, message = buyArmour(playerId, vendorKey, key, amount, coords)
    elseif kind == "food" then
        ok, message = buyFood(playerId, vendorKey, key, amount, coords)
    else
        ok, message = false, "Unknown item kind: " .. tostring(kind)
    end
    TriggerClientEvent('shops:result', playerId, message)
    local menu = menuFor(playerId, vendorKey)
    if menu ~= nil then
        TriggerClientEvent('shops:menu', playerId, menu)
    end
end)

RegisterNetEvent('shops:useFood')
AddEventHandler('shops:useFood', function(foodKey)
    local playerId = source
    local ok, message, needs = useFood(playerId, foodKey)
    TriggerClientEvent('shops:result', playerId, message)
    if needs ~= nil then
        TriggerClientEvent('shops:needs', playerId, {
            hunger = needs.hunger, thirst = needs.thirst,
            healthTax = 0,
        })
    end
end)

RegisterNetEvent('shops:getNeeds')
AddEventHandler('shops:getNeeds', function()
    local playerId = source
    local needs = getNeeds(playerId)
    TriggerClientEvent('shops:result', playerId, needsLine(needs))
    TriggerClientEvent('shops:needs', playerId, {
        hunger = needs.hunger, thirst = needs.thirst,
        healthTax = 0,
    })
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
    local key = playerKey(source)
    PlayerSources[key] = nil  -- seat's empty: stop ticking them
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
        needsTick()  -- Lesson 26: the city gets hungry too
        sinceRestock = sinceRestock + 1
        if sinceRestock >= RESTOCK_EVERY then
            print("[shops] auto-restock (timer):")
            restockAllVendors(RESTOCK_PERCENT)
            sinceRestock = 0
        end
    end
end)
