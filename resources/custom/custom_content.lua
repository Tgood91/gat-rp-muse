-- ============================================================
-- custom_content.lua — Lesson 13: adding custom content
-- Built after tables (9, 10), imports (11), wired jobs (12).
-- Plain Lua, no game-engine functions, no dependencies.
--
-- THE PATTERN: custom content is DATA in a registry.
-- A registry is one labeled table per category:
--
--   CustomVendors   CustomVehicles   CustomArmour
--   CustomAmmo      CustomFirearms
--
-- NEW IDEAS IN THIS LESSON
--   1. Registration functions are gatekeepers: an entry
--      only lands in a registry if it has a label, the
--      category's required field, and a key nobody used.
--   2. Cross-links get checked: a firearm cannot register
--      unless its ammo type already exists — either one of
--      the base ammo types or a custom ammo entry.
--   3. Labeled tables need a pairs loop to count them.
--      The # operator from Lesson 11 only counts LISTS.
--   4. Adding content never touches game logic. The shop,
--      garage, and weapon systems look content UP later —
--      exactly how the Lesson 10 prices table worked.
--
-- In a real FiveM resource, these keys are the names the
-- engine side will load models, items, and weapons for.
-- This lesson builds the data layer those systems read.
-- ============================================================

-- The five registries: empty boxes, ready to fill
CustomVendors = {}
CustomVehicles = {}
CustomArmour = {}
CustomAmmo = {}
CustomFirearms = {}

-- Ammo types that already exist from Lesson 1 / Lesson 4.
-- A custom firearm may use one of these OR a custom type.
BaseAmmoTypes = { ammo = true, pistolAmmo = true }

-- ============================================================
-- COUNT — walk a labeled table with pairs and tally it
-- ============================================================
local function countEntries(registry)
    local count = 0
    for _key in pairs(registry) do
        count = count + 1
    end
    return count
end

-- ============================================================
-- THE GATEKEEPER — one helper every category shares.
-- Checks: data exists, label exists, required field
-- exists, key is not already taken. Then the entry lands.
-- ============================================================
local function addToRegistry(registry, kindName, key, data, requiredField)
    if data == nil then
        print("No data given for custom " .. kindName .. ": " .. key)
        return false
    elseif data.label == nil then
        print("Custom " .. kindName .. " " .. key .. " needs a label.")
        return false
    elseif data[requiredField] == nil then
        print("Custom " .. kindName .. " " .. key .. " is missing: " ..
              requiredField)
        return false
    elseif registry[key] ~= nil then
        print("Custom " .. kindName .. " key already used: " .. key)
        return false
    else
        registry[key] = data
        print("Added " .. kindName .. ": " .. data.label ..
              " [" .. key .. "]")
        return true
    end
end

-- ============================================================
-- THE FIVE DOORS — one add function per category.
-- Each door names the field that category cannot live
-- without. Everything else about the entry is your data.
-- ============================================================
function addVendor(key, data)
    -- a vendor must say what it sells
    return addToRegistry(CustomVendors, "vendor", key, data, "sells")
end

function addVehicle(key, data)
    -- a vehicle must have a price
    return addToRegistry(CustomVehicles, "vehicle", key, data, "price")
end

function addArmour(key, data)
    -- armour must say how much it protects
    return addToRegistry(CustomArmour, "armour", key, data, "protection")
end

function addAmmo(key, data)
    -- ammo must have a per-round price
    return addToRegistry(CustomAmmo, "ammo", key, data, "pricePerRound")
end

function addFirearm(key, data)
    -- a firearm must name a REAL ammo type before the
    -- gatekeeper even sees it: base ammo or custom ammo
    if data == nil or data.ammoType == nil then
        print("Custom firearm " .. key .. " is missing: ammoType")
        return false
    elseif CustomAmmo[data.ammoType] == nil
       and BaseAmmoTypes[data.ammoType] == nil then
        print("Custom firearm " .. key .. " wants unknown ammo: " ..
              data.ammoType)
        return false
    else
        return addToRegistry(CustomFirearms, "firearm", key, data, "damage")
    end
end

-- ============================================================
-- LOOK ONE UP — the same nil check as always
-- ============================================================
function showOne(registry, kindName, key)
    local data = registry[key]
    if data == nil then
        print("No custom " .. kindName .. " called: " .. key)
    else
        print(kindName .. " [" .. key .. "]: " .. data.label)
    end
end

-- ============================================================
-- DISPLAY — how much custom content the world has
-- ============================================================
function showCustomSummary()
    print("Custom content: " ..
          countEntries(CustomVendors) .. " vendors, " ..
          countEntries(CustomVehicles) .. " vehicles, " ..
          countEntries(CustomArmour) .. " armour, " ..
          countEntries(CustomAmmo) .. " ammo, " ..
          countEntries(CustomFirearms) .. " firearms")
end

-- ============================================================
-- THE CONTENT PACK — this is the part you edit to grow
-- the world. One call per custom thing. Ammo goes in
-- BEFORE firearms, because firearms look their ammo up.
-- ============================================================

-- Custom vendors
addVendor("glizzysDepot", {
    label = "Glizzys Depot", type = "fuel + snacks",
    place = "glizzysGas", sells = { "fuel", "glizzyDog", "water" },
})
addVendor("tummyExpress", {
    label = "Tanazolam-tummy Express", type = "food",
    place = "tummy2", sells = { "beans", "energyDrink" },
})
-- sells = { "ammo" } is a CATEGORY entry: every ammo type,
-- base or custom — this vendor carries ALL ammo.
addVendor("tanaz0lamAmmo", {
    label = "Tanaz0lam Ammo", type = "all ammo",
    place = "gunStore", sells = { "ammo" },
})

-- Custom vehicles
addVehicle("zipzapGT", {
    label = "ZipZap GT", class = "electric sports",
    price = 3200, topSpeed = 195, tank = 50, health = 100,
    special = "The ZipZap's big sibling: silent and faster",
})
addVehicle("tummyTruck", {
    label = "Tanazolam Tummy Truck", class = "food truck",
    price = 1600, topSpeed = 95, tank = 90, health = 120,
    special = "Food runs pay +25 gold",
})

-- Custom armour
addArmour("kevlarVest", {
    label = "Kevlar Vest", price = 350,
    protection = 50, durability = 100, weight = 6,
})
addArmour("ceramicCarrier", {
    label = "Ceramic Plate Carrier", price = 650,
    protection = 80, durability = 140, weight = 11,
})

-- Custom ammo (before firearms — they look these up)
addAmmo("rounds556", {
    label = "5.56 Rounds", caliber = "5.56", pricePerRound = 3,
})
addAmmo("shells12", {
    label = "12 Gauge Shells", caliber = "12 gauge", pricePerRound = 5,
})

-- Custom firearms
addFirearm("bushidoCarbine", {
    label = "Bushido Carbine", price = 900,
    ammoType = "rounds556", damage = 34, fireMode = "burst",
})
addFirearm("harborShotgun", {
    label = "Harbor Shotgun", price = 700,
    ammoType = "shells12", damage = 70, fireMode = "pump",
})

-- ============================================================
-- TRY IT — look content up, watch the gatekeeper refuse,
-- then add one more vehicle live
-- ============================================================
showCustomSummary()       -- 3 vendors, 2 vehicles, 2 armour, 2 ammo, 2 firearms
showOne(CustomVehicles, "vehicle", "zipzapGT")
showOne(CustomFirearms, "firearm", "bushidoCarbine")
addVendor("glizzysDepot", {
    label = "Glizzys Depot 2", type = "fuel + snacks",
    place = "g2g5", sells = { "fuel" },
})                        -- refused: key already used
addFirearm("laserGun", {
    label = "Laser Gun", price = 9999, damage = 99,
})                        -- refused: missing ammoType
addFirearm("railGun", {
    label = "Rail Gun", price = 5000, ammoType = "plasmaCell",
    damage = 120, fireMode = "single",
})                        -- refused: plasmaCell is not a real ammo type
addVehicle("nightRunner", {
    label = "Night Runner", class = "muscle",
    price = 1800, topSpeed = 165, tank = 70, health = 100,
    special = "Blacked out: built to not be seen",
})                        -- added live: vehicles are now 3
showCustomSummary()       -- the end state, counted for you
