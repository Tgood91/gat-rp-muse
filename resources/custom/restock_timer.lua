-- ============================================================
-- LESSON 15: THE RESTOCK TIMER
-- Lesson 14's restock rule needed a human: somebody had to
-- CALL restockAllVendors(80). Lesson 15 fires it on a clock.
--
-- The new ideas:
--   1. A clock made of ticks: runCity(hours) loops, and
--      each pass is one game hour. In FiveM this same loop
--      lives in a thread with a Wait() between passes —
--      the shape doesn't change, only the waiting does.
--   2. Demand: the city buys even when you don't. A rate
--      table (units per hour) drains every shelf a little
--      each tick. math.min makes sure a shelf never sells
--      below zero — you can't sell what you don't have.
--   3. The timer is just a COUNTER. sinceRestock climbs
--      by 1 each hour; when it reaches RESTOCK_EVERY, the
--      restock fires BY ITSELF and the counter resets.
--      Nobody calls it. The clock does.
--
-- Carried from Lesson 14, unchanged: the four vendors,
-- their shelf capacities, and restockAllVendors — which
-- still tops UP TO the percent, never drains down.
-- Demand is a fixed rate, not random, so this demo runs
-- the same every time. Random customers are a TRY IT.
-- ============================================================

-- The shops (labels only — selling lives in Lesson 14).
CustomVendors = {
    glizzysDepot = { label = "Glizzys Depot" },
    tummyExpress = { label = "Tanazolam-tummy Express" },
    bushidoSupply = { label = "Bushido Supply" },
    tanaz0lamAmmo = { label = "Tanaz0lam Ammo" },
}

VendorOrder = { "glizzysDepot", "tummyExpress", "bushidoSupply", "tanaz0lamAmmo" }

-- Shelf capacity per vendor per item (Lesson 14's numbers).
VendorCapacity = {
    glizzysDepot = { fuel = 200, glizzyDog = 20, water = 50 },
    tummyExpress = { beans = 40, energyDrink = 30 },
    bushidoSupply = {
        kevlarVest = 5, ceramicCarrier = 2,
        bushidoCarbine = 2, harborShotgun = 2,
        rounds556 = 200, shells12 = 100,
    },
    tanaz0lamAmmo = {
        ammo = 1000, pistolAmmo = 500,
        rounds556 = 250, shells12 = 100,
    },
}

-- What each vendor HAS right now. Starts empty, as before.
VendorStock = {}

-- How much the city buys per hour, per vendor per item.
-- Gear moves slowly; ammo and fuel move all day.
Demand = {
    glizzysDepot = { fuel = 15, glizzyDog = 3, water = 5 },
    tummyExpress = { beans = 4, energyDrink = 3 },
    bushidoSupply = {
        kevlarVest = 1, ceramicCarrier = 0,
        bushidoCarbine = 0, harborShotgun = 0,
        rounds556 = 20, shells12 = 5,
    },
    tanaz0lamAmmo = {
        ammo = 60, pistolAmmo = 35,
        rounds556 = 15, shells12 = 6,
    },
}

-- The timer's settings. ALL-CAPS = constants: set once,
-- read everywhere, never changed by the code.
RESTOCK_EVERY = 4    -- hours between automatic restocks
RESTOCK_PERCENT = 80 -- Tanner's rule: shelves live at 80%

-- ============================================================
-- RESTOCK ALL — Lesson 14's function, word for word.
-- Tops every shelf UP TO the percent of capacity.
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
        print(vendor.label .. " stocked to " .. percent .. "%.")
    end
end

-- ============================================================
-- CITY BUYS — one hour of demand across every vendor.
-- sold = the smaller of (rate, what's actually there):
-- math.min picks the smaller of two numbers.
-- ============================================================
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
-- RUN CITY — the clock. Each loop pass = one game hour:
-- the city buys, the counter climbs, and when the counter
-- reaches RESTOCK_EVERY the restock fires on its own.
-- The print watches three shelves so you can see the saw-
-- tooth: drain, drain, drain, SNAP back to 80%.
-- ============================================================
function runCity(hours)
    local sinceRestock = 0
    for hour = 1, hours do
        cityBuys()
        sinceRestock = sinceRestock + 1
        print("Hour " .. hour ..
              " | Tanaz0lam pistol: " .. VendorStock.tanaz0lamAmmo.pistolAmmo ..
              " | Bushido 5.56: " .. VendorStock.bushidoSupply.rounds556 ..
              " | Glizzys fuel: " .. VendorStock.glizzysDepot.fuel)
        if sinceRestock >= RESTOCK_EVERY then
            print("-- restock truck rolls (auto) --")
            restockAllVendors(RESTOCK_PERCENT)
            sinceRestock = 0
        end
    end
end

-- The end state of every shelf, vendor by vendor.
function showFinalShelves()
    print("Glizzys Depot: " ..
          VendorStock.glizzysDepot.fuel .. " fuel, " ..
          VendorStock.glizzysDepot.glizzyDog .. " dogs, " ..
          VendorStock.glizzysDepot.water .. " water")
    print("Tanazolam-tummy Express: " ..
          VendorStock.tummyExpress.beans .. " beans, " ..
          VendorStock.tummyExpress.energyDrink .. " energy drinks")
    print("Bushido Supply: " ..
          VendorStock.bushidoSupply.kevlarVest .. " vests, " ..
          VendorStock.bushidoSupply.ceramicCarrier .. " carriers, " ..
          VendorStock.bushidoSupply.bushidoCarbine .. " carbines, " ..
          VendorStock.bushidoSupply.harborShotgun .. " shotguns, " ..
          VendorStock.bushidoSupply.rounds556 .. " x 5.56, " ..
          VendorStock.bushidoSupply.shells12 .. " shells")
    print("Tanaz0lam Ammo: " ..
          VendorStock.tanaz0lamAmmo.ammo .. " AR, " ..
          VendorStock.tanaz0lamAmmo.pistolAmmo .. " pistol, " ..
          VendorStock.tanaz0lamAmmo.rounds556 .. " x 5.56, " ..
          VendorStock.tanaz0lamAmmo.shells12 .. " shells")
end

-- ============================================================
-- TRY IT — watch one full day-shape in 10 hours:
--   1. Opening stock, by hand — Lesson 14's way.
--   2. runCity(10): the timer takes over. Restocks fire
--      after hour 4 and hour 8 with nobody calling them.
--   3. Final shelves = 80% targets minus 2 hours of sales.
--
-- Your turn:
--   * Set RESTOCK_EVERY to 2. Which hours snap back now?
--   * Set Tanaz0lam pistolAmmo demand to 0 for an hour —
--     what happens to its saw-tooth?
--   * Swap a rate for math.random(0, 50) and run it twice.
--     Why can't you predict the final shelves any more?
-- ============================================================
restockAllVendors(RESTOCK_PERCENT)  -- opening stock, by hand
runCity(10)                         -- the timer takes over
showFinalShelves()                  -- where the city leaves it
