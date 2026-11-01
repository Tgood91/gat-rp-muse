-- ============================================================
-- repairs.lua — Lesson 6: vehicle repairs
-- Built after inventory (1), cars (2), jobs (3), weapons (4),
-- vendors (5). Plain Lua, no engine functions, no dependencies.
--
-- NEW IDEAS IN THIS LESSON
--   1. The car gets a health slot: carHealth runs 0-100,
--      same idea as YOUR health (85) from Lesson 1.
--   2. Buy here, use anywhere: the mechanic shop SELLS the
--      kit, your inventory HOLDS it, the car TAKES the fix.
--      Three piles, one chain: buy -> hold -> use.
--   3. The cap again: repairs stop at 100, exactly like the
--      fuel cap in Lesson 2. Never past full.
--
-- This file stands alone so you can run it by itself.
-- Starting values: gold = 520 (where Lesson 5 ended), the
-- Sedan from Lesson 2 (fuel 40), worn down to carHealth 55.
-- Prices are the Lesson 1 shop prices: repair kit 200,
-- fuel can 25.
-- ============================================================

-- Your wallet and supplies
gold = 520
repairKits = 0      -- in your inventory (Lesson 1: repairKit)
fuelCans = 1        -- in your inventory (Lesson 1: fuelCan)

-- The car (Lesson 2 slots, plus the new one)
carModel = "Sedan"
carFuel = 40
carHealth = 55      -- NEW: 0 = wrecked, 100 = perfect

-- Prices (from inventory.lua)
repairKitPrice = 200
fuelCanPrice = 25

-- The vendor: the mechanic shop, with its own stock slots
atVendor = "none"       -- "none", "gunStore", or "mechanicShop"
shopRepairKits = 5      -- kits on the shelf
shopFuelCans = 10       -- cans on the shelf

-- ============================================================
-- GO TO A VENDOR — same function as Lesson 5, one more branch
-- ============================================================
function visitVendor(vendorName)
    if vendorName == "gunStore" then
        atVendor = "gunStore"
        print("You walk into the gun store.")
    elseif vendorName == "mechanicShop" then
        atVendor = "mechanicShop"
        print("You roll into the mechanic shop.")
    else
        print("No such vendor: " .. vendorName)
    end
end

function leaveVendor()
    atVendor = "none"
    print("You leave.")
end

-- ============================================================
-- BUY A PART — Lesson 5's counter, at the mechanic shop
-- check (there? shelf? gold?) -> move x3 -> report
-- ============================================================
function buyPart(partName, amount)
    if atVendor ~= "mechanicShop" then
        print("Parts are sold at the mechanic shop. You're not there.")
    elseif partName == "repairKit" then
        local cost = amount * repairKitPrice
        if shopRepairKits < amount then
            print("The shop only has " .. shopRepairKits .. " repair kits.")
        elseif gold < cost then
            print("Not enough gold: " .. amount .. " kits cost " .. cost .. ".")
        else
            gold = gold - cost
            repairKits = repairKits + amount
            shopRepairKits = shopRepairKits - amount
            print("Bought " .. amount .. " repair kit(s) for " .. cost ..
                  " gold. Kits: " .. repairKits .. " | Gold: " .. gold)
        end
    elseif partName == "fuelCan" then
        local cost = amount * fuelCanPrice
        if shopFuelCans < amount then
            print("The shop only has " .. shopFuelCans .. " fuel cans.")
        elseif gold < cost then
            print("Not enough gold: " .. amount .. " cans cost " .. cost .. ".")
        else
            gold = gold - cost
            fuelCans = fuelCans + amount
            shopFuelCans = shopFuelCans - amount
            print("Bought " .. amount .. " fuel can(s) for " .. cost ..
                  " gold. Cans: " .. fuelCans .. " | Gold: " .. gold)
        end
    else
        print("The shop doesn't sell: " .. partName)
    end
end

-- ============================================================
-- USE A REPAIR KIT — the use() pattern from Lesson 1,
-- pointed at the car. Works anywhere; the kit is yours.
-- ============================================================
function useRepairKit()
    if repairKits < 1 then
        print("No repair kits. The mechanic shop sells them.")
    elseif carHealth >= 100 then
        print("The car is already at full health. Save the kit.")
    else
        repairKits = repairKits - 1
        carHealth = carHealth + 30
        if carHealth > 100 then
            carHealth = 100
        end
        print("Kit used. Car health: " .. carHealth ..
              " | Kits left: " .. repairKits)
    end
end

-- ============================================================
-- DISPLAY — the car, all its slots in one place
-- ============================================================
function showCar()
    print("Car: " .. carModel .. " | Fuel: " .. carFuel ..
          " | Health: " .. carHealth ..
          " | Kits: " .. repairKits .. " | Cans: " .. fuelCans ..
          " | Gold: " .. gold)
end

-- ============================================================
-- TRY IT — no kit, go buy some, fix the car
-- ============================================================
showCar()                    -- health 55, kits 0, gold 520
useRepairKit()               -- refused: no kits
buyPart("repairKit", 2)      -- refused: not at the shop
visitVendor("mechanicShop")  -- roll in
buyPart("repairKit", 2)      -- 2 x 200 = 400 -> gold 120, kits 2, shelf 3
buyPart("fuelCan", 2)        -- 2 x 25 = 50 -> gold 70, cans 3, shelf 8
buyPart("repairKit", 1)      -- refused: 200 gold, you have 70
leaveVendor()                -- roll out
useRepairKit()               -- kits 1, car health 85
useRepairKit()               -- kits 0, car health 100 (capped from 115)
useRepairKit()               -- refused: no kits left
showCar()                    -- the end state, all in one place
