-- ============================================================
-- maps.lua — Lesson 7: maps + locations
-- Built after inventory (1), cars (2), jobs (3), weapons (4),
-- vendors (5), repairs (6). Plain Lua, no dependencies.
--
-- NEW IDEAS IN THIS LESSON
--   1. A place is slots too: a name plus coordinates (x, y).
--      GTA really uses x, y, z — z is height; we start with 2.
--   2. Distance comes from coordinates: the ^ sign raises to
--      a power, math.sqrt takes the square root. Fuel cost
--      for a trip = the distance.
--   3. Location gates the other systems: a vendor only opens
--      when you're standing at its place. Travel first,
--      then shop — Lessons 5 and 6 click into the map.
--   4. A fuel vendor: Glizzys Gas (added by Tanner) sells
--      fuel by the unit — and the tank cap from Lesson 2
--      turns into a check: no overfilling.
--
-- This file stands alone so you can run it by itself.
-- Starting values: the Sedan from Lesson 2, fuel 40,
-- carHealth 100 (freshly repaired in Lesson 6), gold 70
-- (what Lesson 6 left in your pocket).
-- ============================================================

-- Your wallet
gold = 70

-- The car (from cars.lua + repairs.lua)
carModel = "Sedan"
carFuel = 40
carHealth = 100

-- Where you are: a name, plus your coordinates
currentLocation = "home"
posX = 0
posY = 0

-- Glizzys Gas: fuel price per unit
fuelPrice = 2

-- The places (name -> x, y). Clean distances on purpose:
-- home (0,0) -> gunStore (3,4) = 5, gunStore -> mechanic (6,8) = 5,
-- mechanic -> home = 10. Glizzys Gas (6,0): 6 from home,
-- 5 from the gun store, 8 from the mechanic. 3-4-5 triangles.
-- ============================================================
-- TRAVEL — check (already there? fuel?) -> move -> report
-- ============================================================
function travelTo(placeName)
    local targetX, targetY

    if placeName == "home" then
        targetX, targetY = 0, 0
    elseif placeName == "gunStore" then
        targetX, targetY = 3, 4
    elseif placeName == "mechanicShop" then
        targetX, targetY = 6, 8
    elseif placeName == "glizzysGas" then
        targetX, targetY = 6, 0
    else
        print("No such place: " .. placeName)
        return
    end

    if placeName == currentLocation then
        print("You're already at " .. placeName .. ".")
        return
    end

    local dx = targetX - posX
    local dy = targetY - posY
    local distance = math.sqrt(dx ^ 2 + dy ^ 2)

    if carFuel < distance then
        print("Not enough fuel: " .. distance .. " away, " ..
              carFuel .. " in the tank.")
    else
        carFuel = carFuel - distance
        posX, posY = targetX, targetY
        currentLocation = placeName
        print("Drove to " .. placeName .. " (" .. distance ..
              " away). Fuel left: " .. carFuel)
    end
end

-- ============================================================
-- VISIT A VENDOR — Lesson 5's door, now locked to the map
-- ============================================================
function visitVendor(vendorName)
    if vendorName == "gunStore" and currentLocation == "gunStore" then
        print("You walk into the gun store.")
    elseif vendorName == "mechanicShop" and currentLocation == "mechanicShop" then
        print("You roll into the mechanic shop.")
    elseif vendorName == "glizzysGas" and currentLocation == "glizzysGas" then
        print("You pull in at Glizzys Gas.")
    elseif vendorName == "gunStore" or vendorName == "mechanicShop"
        or vendorName == "glizzysGas" then
        print("The " .. vendorName .. " isn't here — travel to it first.")
    else
        print("No such vendor: " .. vendorName)
    end
end

-- ============================================================
-- BUY FUEL — only at Glizzys Gas, and never past a full tank
-- check (there? tank space? gold?) -> move x2 -> report
-- ============================================================
function buyFuel(amount)
    if currentLocation ~= "glizzysGas" then
        print("Fuel is sold at Glizzys Gas. You're not there.")
    else
        local cost = amount * fuelPrice
        if carFuel + amount > 100 then
            print("That would overfill the tank — space for " ..
                  (100 - carFuel) .. ".")
        elseif gold < cost then
            print("Not enough gold: " .. amount .. " fuel costs " ..
                  cost .. ".")
        else
            gold = gold - cost
            carFuel = carFuel + amount
            print("Filled " .. amount .. " fuel for " .. cost ..
                  " gold. Fuel: " .. carFuel .. " | Gold: " .. gold)
        end
    end
end

-- ============================================================
-- DISPLAY — where you are, and the map
-- ============================================================
function whereAmI()
    print("You are at " .. currentLocation ..
          " (" .. posX .. ", " .. posY .. ")" ..
          " | Car: " .. carModel .. " | Fuel: " .. carFuel ..
          " | Health: " .. carHealth .. " | Gold: " .. gold)
end

function showMap()
    print("Map: home (0, 0) | gunStore (3, 4) | mechanicShop (6, 8) | Glizzys Gas (6, 0)")
end

-- ============================================================
-- TRY IT — the map locks the vendors until you travel,
-- then Glizzys Gas sells you the fuel to get home
-- ============================================================
whereAmI()                  -- home, fuel 40, gold 70
visitVendor("gunStore")     -- refused: it's not here
travelTo("gunStore")        -- 5 away -> fuel 35
visitVendor("gunStore")     -- works: you're standing there
travelTo("mechanicShop")    -- 5 away -> fuel 30
visitVendor("mechanicShop") -- works
travelTo("mechanicShop")    -- refused: already there
travelTo("home")            -- 10 away -> fuel 20
travelTo("glizzysGas")      -- 6 away -> fuel 14
visitVendor("glizzysGas")   -- you pull in at Glizzys Gas
buyFuel(30)                 -- 30 x 2 = 60 gold -> fuel 44, gold 10
buyFuel(100)                -- refused: only room for 56 more
travelTo("home")            -- 6 away -> fuel 38
whereAmI()                  -- the end state, all in one place
