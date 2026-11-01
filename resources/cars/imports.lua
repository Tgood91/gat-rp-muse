-- ============================================================
-- imports.lua — Lesson 11: importing specialized cars
-- Built after cars (2), jobs (3), maps tables (9), and the
-- tabled inventory (10). New file alongside cars.lua, which
-- is NOT modified. Plain Lua, no game-engine functions.
--
-- "Specialized" = built for one purpose: a taxi cab, a
-- delivery van, an armored SUV, an electric sports car.
-- You don't buy these off a lot — you IMPORT them: pay the
-- price plus an import fee, and the car joins your garage.
--
-- NEW IDEAS IN THIS LESSON
--   1. A catalog table: every importable car is data —
--      price, top speed, tank, health, and a special trait.
--   2. Percentage math: the fee is 15% of the price, so
--      total = price + (price * 15 // 100). The // is
--      integer division — it drops the decimal, so gold
--      stays in whole numbers (no 920.0 gold).
--   3. LIST tables: the garage is numbered slots (1, 2, 3),
--      not named ones. #garage counts it, and a numeric
--      for loop (for i = 1, #garage) walks or searches it.
--   4. Owning vs driving: the garage holds your cars; ONE
--      of them is currentCar — setCar() swaps which.
--
-- Starting values: gold 3000 (a lot of Lesson 3 shifts),
-- your garage holds just the Sedan from Lesson 2.
-- ============================================================

gold = 3000
importFeePercent = 15

-- The import catalog: key -> the car's data
imports = {
    taxiCab = {
        name = "Taxi Cab", price = 800, topSpeed = 110,
        tank = 60, health = 100, jobBonus = 20,
        special = "Taxi shifts pay +20 gold",
    },
    deliveryVan = {
        name = "Delivery Van", price = 1200, topSpeed = 100,
        tank = 80, health = 100, jobBonus = 30,
        special = "Delivery shifts pay +30 gold",
    },
    armoredSUV = {
        name = "Armored SUV", price = 2500, topSpeed = 130,
        tank = 90, health = 200, jobBonus = 0,
        special = "Armored body: 200 health instead of 100",
    },
    zipzap = {
        name = "ZipZap", price = 2000, topSpeed = 180,
        tank = 50, health = 100, jobBonus = 0,
        special = "Electric: near-silent, fastest thing you own",
    },
}

-- The garage: a LIST of car names you own
garage = { "Sedan" }

-- The car you're in right now (starts as the Sedan)
currentCarKey = "sedan"
currentCar = { name = "Sedan", topSpeed = 120, tank = 100,
               fuel = 80, health = 100, special = "Your first car" }

-- ============================================================
-- OWNERSHIP — search the list for a name
-- ============================================================
function ownsCar(carName)
    for i = 1, #garage do
        if garage[i] == carName then
            return true
        end
    end
    return false
end

-- ============================================================
-- IMPORT — check (listed? owned? gold?) -> move -> report
-- total = price + fee, and the fee is a percentage
-- ============================================================
function importCar(carKey)
    local car = imports[carKey]
    if car == nil then
        print("The importer can't get a: " .. carKey)
    elseif ownsCar(car.name) then
        print("You already own a " .. car.name .. ".")
    else
        local fee = car.price * importFeePercent // 100
        local total = car.price + fee
        if gold < total then
            print("Not enough gold: " .. car.name .. " is " .. car.price ..
                  " + " .. fee .. " import fee = " .. total .. ".")
        else
            gold = gold - total
            garage[#garage + 1] = car.name
            print("Imported! " .. car.name .. " for " .. total ..
                  " gold (" .. fee .. " fee). Gold: " .. gold)
            print("Special: " .. car.special)
        end
    end
end

-- ============================================================
-- SET CAR — swap which owned car you're driving.
-- A fresh import arrives with a full tank.
-- ============================================================
function setCar(carKey)
    local car = imports[carKey]
    if carKey == "sedan" then
        currentCarKey = "sedan"
        currentCar = { name = "Sedan", topSpeed = 120, tank = 100,
                       fuel = 80, health = 100,
                       special = "Your first car" }
        print("You're in the Sedan.")
    elseif car == nil then
        print("No such car: " .. carKey)
    elseif not ownsCar(car.name) then
        print("You don't own the " .. car.name .. ". Import it first.")
    else
        currentCarKey = carKey
        currentCar = { name = car.name, topSpeed = car.topSpeed,
                       tank = car.tank, fuel = car.tank,
                       health = car.health, special = car.special }
        print("You're in the " .. car.name .. ". Fuel: " ..
              currentCar.fuel .. " | Health: " .. currentCar.health)
    end
end

-- ============================================================
-- DISPLAY — the garage list, numbered
-- ============================================================
function showGarage()
    print("Garage (" .. #garage .. " cars) | Gold: " .. gold)
    for i = 1, #garage do
        print(i .. ". " .. garage[i])
    end
    print("Current car: " .. currentCar.name ..
          " | Top speed: " .. currentCar.topSpeed ..
          " | Special: " .. currentCar.special)
end

-- ============================================================
-- TRY IT — import the job cars, get refused on the SUV
-- ============================================================
showGarage()              -- 1 car: the Sedan
importCar("taxiCab")      -- 800 + 120 fee = 920 -> gold 2080
importCar("taxiCab")      -- refused: already in the garage
importCar("armoredSUV")   -- refused: 2875 total, you have 2080
importCar("deliveryVan")  -- 1200 + 180 fee = 1380 -> gold 700
importCar("hoverboard")   -- refused: the importer can't get one
setCar("deliveryVan")     -- full tank 80, ready to work
setCar("armoredSUV")      -- refused: you don't own it
showGarage()              -- 3 cars, current: Delivery Van
