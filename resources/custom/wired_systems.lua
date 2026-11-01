-- ============================================================
-- wired_systems.lua — Lesson 14: wiring custom content in
-- Built after custom content (13). New file alongside
-- custom_content.lua, which is NOT modified. Plain Lua.
--
-- THE IDEA: a registry nobody reads is just a list.
-- In this lesson the older systems READ Lesson 13's
-- registries:
--   - the shop sells custom armour and firearms
--   - the importer imports custom vehicles
--   - vendors stock (and sell) custom ammo
--
-- NEW IDEAS IN THIS LESSON
--   1. A category map: Registries links a category name
--      ("armour") to its registry table, so ONE buy
--      function serves armour, firearms, and ammo.
--   2. Vendor stock is its own table: what a vendor CAN
--      sell (its sells list) and what it HAS (stock) are
--      two different questions, checked separately.
--   3. A vendor sells a category ("ammo") or one specific
--      key ("rounds556") — either entry on its sells list
--      opens that door.
--   4. Prices come from the content itself: gear uses
--      data.price, ammo uses data.pricePerRound. The buy
--      function reads whichever slot exists.
--   5. A stocking rule (Tanner's): every vendor has shelf
--      CAPACITIES, and restockAllVendors(80) tops every
--      shelf UP TO 80% of capacity. Fills only — a shelf
--      above 80% is left alone, never drained down.
--
-- This file stands alone: it carries Lesson 13's seed
-- content in compact form, plus two vendors the wiring
-- needed — Bushido Supply (gear: no Lesson 13 vendor sold
-- armour or firearms) and Tanaz0lam Ammo, which carries
-- ALL ammo: its sells list holds the category "ammo",
-- and the AmmoCatalog below merges base + custom types.
-- Starting gold: 6000. The garage starts with the Sedan.
-- ============================================================

-- Player state
gold = 6000
Owned = {}              -- custom gear/ammo you own: key -> count
Garage = { "Sedan" }    -- car labels, as in Lesson 11
importFeePercent = 15   -- Lesson 11's fee, unchanged

-- ============================================================
-- THE REGISTRIES (Lesson 13's content, compact form)
-- ============================================================
CustomVendors = {
    glizzysDepot = {
        label = "Glizzys Depot", place = "glizzysGas",
        sells = { "fuel", "glizzyDog", "water" },
    },
    tummyExpress = {
        label = "Tanazolam-tummy Express", place = "tummy2",
        sells = { "beans", "energyDrink" },
    },
    bushidoSupply = {
        label = "Bushido Supply", place = "gunStore",
        sells = { "armour", "firearms", "ammo" },
    },
    tanaz0lamAmmo = {
        label = "Tanaz0lam Ammo", place = "gunStore",
        sells = { "ammo" },  -- the category: EVERY ammo type
    },
}

CustomVehicles = {
    zipzapGT = {
        label = "ZipZap GT", price = 3200, topSpeed = 195,
        tank = 50, health = 100,
        special = "The ZipZap's big sibling: silent and faster",
    },
    tummyTruck = {
        label = "Tanazolam Tummy Truck", price = 1600,
        topSpeed = 95, tank = 90, health = 120,
        special = "Food runs pay +25 gold",
    },
}

CustomArmour = {
    kevlarVest = { label = "Kevlar Vest", price = 350, protection = 50 },
    ceramicCarrier = { label = "Ceramic Plate Carrier", price = 650, protection = 80 },
}

CustomAmmo = {
    rounds556 = { label = "5.56 Rounds", pricePerRound = 3 },
    shells12 = { label = "12 Gauge Shells", pricePerRound = 5 },
}

CustomFirearms = {
    bushidoCarbine = {
        label = "Bushido Carbine", price = 900,
        ammoType = "rounds556", damage = 34,
    },
    harborShotgun = {
        label = "Harbor Shotgun", price = 700,
        ammoType = "shells12", damage = 70,
    },
}

-- ALL ammo in one catalog: the two base types from
-- Lesson 1 (with their prices) plus the custom types,
-- referenced straight from CustomAmmo. "All ammo" is a
-- data merge — Tanaz0lam Ammo needs no special case.
AmmoCatalog = {
    ammo = { label = "AR Rounds", pricePerRound = 2 },
    pistolAmmo = { label = "Pistol Rounds", pricePerRound = 1 },
    rounds556 = CustomAmmo.rounds556,
    shells12 = CustomAmmo.shells12,
}

-- Category name -> registry. The buy function's phone book.
Registries = {
    armour = CustomArmour,
    firearms = CustomFirearms,
    ammo = AmmoCatalog,
}

-- Shelf CAPACITY per vendor per item: the most a shelf
-- holds. The 80% rule stocks toward these numbers.
VendorOrder = { "glizzysDepot", "tummyExpress", "bushidoSupply", "tanaz0lamAmmo" }
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

-- What each vendor actually HAS right now. Shelves start
-- empty — restockAllVendors(80) fills them in the demo.
VendorStock = {}

-- ============================================================
-- VENDOR CHECKS — can this vendor sell that at all?
-- True if its sells list names the category OR the key.
-- ============================================================
local function vendorSells(vendor, category, key)
    for i = 1, #vendor.sells do
        if vendor.sells[i] == category or vendor.sells[i] == key then
            return true
        end
    end
    return false
end

-- ============================================================
-- RESTOCK ALL — Tanner's standing rule: every vendor's
-- shelves topped UP TO the given percent of capacity.
-- target = capacity * percent // 100 (whole items only).
-- A shelf already above target is left exactly as is.
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
-- STOCK AMMO — the vendor side of the counter.
-- Restocking is a system move: shelf count goes up,
-- but only if the vendor sells that ammo at all.
-- Looks in the ALL-ammo catalog: base types count too.
-- ============================================================
function stockCustomAmmo(vendorKey, ammoKey, amount)
    local vendor = CustomVendors[vendorKey]
    local ammo = Registries.ammo[ammoKey]
    if vendor == nil then
        print("No such vendor: " .. vendorKey)
    elseif ammo == nil then
        print("No such ammo: " .. ammoKey)
    elseif not vendorSells(vendor, "ammo", ammoKey) then
        print(vendor.label .. " doesn't stock " .. ammo.label .. ".")
    else
        if VendorStock[vendorKey] == nil then
            VendorStock[vendorKey] = {}
        end
        local shelf = VendorStock[vendorKey]
        shelf[ammoKey] = (shelf[ammoKey] or 0) + amount
        print(vendor.label .. " stocked +" .. amount .. " " ..
              ammo.label .. ". Shelf: " .. shelf[ammoKey])
    end
end

-- ============================================================
-- BUY FROM A VENDOR — one function, three categories.
-- check (vendor? sells it? item? shelf? gold?)
--   -> move (gold down, shelf down, owned up) -> report
-- ============================================================
function buyFromVendor(vendorKey, category, key, amount)
    local vendor = CustomVendors[vendorKey]
    local registry = Registries[category]
    if vendor == nil then
        print("No such vendor: " .. vendorKey)
        return
    elseif registry == nil then
        print("No shop system sells category: " .. category)
        return
    end

    local item = registry[key]
    if item == nil then
        print("No custom " .. category .. " called: " .. key)
    elseif not vendorSells(vendor, category, key) then
        print(vendor.label .. " doesn't sell " .. category .. ".")
    else
        local shelf = VendorStock[vendorKey]
        local inStock = 0
        if shelf ~= nil and shelf[key] ~= nil then
            inStock = shelf[key]
        end
        local unitPrice = item.price or item.pricePerRound
        local cost = unitPrice * amount
        if inStock < amount then
            print(vendor.label .. " has " .. inStock .. " x " ..
                  item.label .. " — not enough.")
        elseif gold < cost then
            print("Not enough gold: " .. amount .. " x " ..
                  item.label .. " costs " .. cost .. ".")
        else
            gold = gold - cost
            shelf[key] = inStock - amount
            Owned[key] = (Owned[key] or 0) + amount
            print("Bought " .. amount .. " x " .. item.label ..
                  " for " .. cost .. " gold at " .. vendor.label ..
                  ". Gold: " .. gold)
        end
    end
end

-- ============================================================
-- IMPORT A CUSTOM VEHICLE — Lesson 11's importer, reading
-- the Lesson 13 registry instead of its own catalog.
-- ============================================================
local function ownsCarLabel(carLabel)
    for i = 1, #Garage do
        if Garage[i] == carLabel then
            return true
        end
    end
    return false
end

function importCustomVehicle(vehicleKey)
    local car = CustomVehicles[vehicleKey]
    if car == nil then
        print("The importer can't get a: " .. vehicleKey)
    elseif ownsCarLabel(car.label) then
        print("You already own the " .. car.label .. ".")
    else
        local fee = car.price * importFeePercent // 100
        local total = car.price + fee
        if gold < total then
            print("Not enough gold: " .. car.label .. " is " ..
                  car.price .. " + " .. fee .. " fee = " .. total .. ".")
        else
            gold = gold - total
            Garage[#Garage + 1] = car.label
            print("Imported! " .. car.label .. " for " .. total ..
                  " gold (" .. fee .. " fee). Gold: " .. gold)
            print("Special: " .. car.special)
        end
    end
end

-- ============================================================
-- DISPLAY — the wired world in one look
-- ============================================================
function showWiredSummary()
    print("Gold: " .. gold .. " | Garage: " .. #Garage .. " cars")
    print("Owned: " .. (Owned.kevlarVest or 0) .. " Kevlar Vest, " ..
          (Owned.bushidoCarbine or 0) .. " Bushido Carbine, " ..
          (Owned.rounds556 or 0) .. " x 5.56 Rounds")
    print("Bushido Supply shelf: " ..
          VendorStock.bushidoSupply.kevlarVest .. " vests, " ..
          VendorStock.bushidoSupply.bushidoCarbine .. " carbines, " ..
          VendorStock.bushidoSupply.rounds556 .. " x 5.56")
    print("Owned ammo: " .. (Owned.ammo or 0) .. " AR, " ..
          (Owned.pistolAmmo or 0) .. " pistol, " ..
          (Owned.shells12 or 0) .. " shells")
    print("Tanaz0lam Ammo shelf: " ..
          VendorStock.tanaz0lamAmmo.ammo .. " AR, " ..
          VendorStock.tanaz0lamAmmo.pistolAmmo .. " pistol, " ..
          VendorStock.tanaz0lamAmmo.rounds556 .. " x 5.56, " ..
          VendorStock.tanaz0lamAmmo.shells12 .. " shells")
end

-- ============================================================
-- TRY IT — restock, buy gear, hit the refusals, import
-- ============================================================
restockAllVendors(80)             -- the standing rule: all vendors to 80%
stockCustomAmmo("glizzysDepot", "rounds556", 50)  -- refused: no ammo there
stockCustomAmmo("bushidoSupply", "rounds556", 60) -- shelf 160 -> 220
buyFromVendor("bushidoSupply", "armour", "kevlarVest", 1)     -- 350 -> gold 5650
buyFromVendor("bushidoSupply", "firearms", "bushidoCarbine", 1) -- 900 -> gold 4750
buyFromVendor("bushidoSupply", "firearms", "bushidoCarbine", 1) -- refused: shelf empty
buyFromVendor("bushidoSupply", "ammo", "rounds556", 30)       -- 90 -> gold 4660
buyFromVendor("tummyExpress", "ammo", "rounds556", 10)        -- refused: food vendor
importCustomVehicle("zipzapGT")   -- 3200 + 480 fee = 3680 -> gold 980
importCustomVehicle("tummyTruck") -- refused: 1840 total, you have 980
importCustomVehicle("zipzapGT")   -- refused: already in the garage
stockCustomAmmo("tanaz0lamAmmo", "pistolAmmo", 50)  -- base ammo too: 400 -> 450
buyFromVendor("tanaz0lamAmmo", "ammo", "pistolAmmo", 20)  -- 20 -> gold 960
buyFromVendor("tanaz0lamAmmo", "ammo", "shells12", 10)    -- 50 -> gold 910
showWiredSummary()                -- the end state, all wired together
