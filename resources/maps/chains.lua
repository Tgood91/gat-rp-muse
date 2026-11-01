-- ============================================================
-- chains.lua — Lesson 9: tables + vendor chains
-- Built after inventory (1), cars (2), jobs (3), weapons (4),
-- vendors (5), repairs (6), maps (7), needs (8).
-- Plain Lua, no game-engine functions, no dependencies.
--
-- THE PROBLEM: Tanner adds two chains — Glizzys-2-Go with
-- 8 locations and Tanazolam-tummy with 4. Twelve new places
-- would mean twelve more elseif branches in travelTo.
-- Too many. Time for the big one:
--
-- NEW IDEAS IN THIS LESSON
--   1. A TABLE is a box of labeled slots: one variable,
--      `locations`, holds the whole map. Each place is its
--      own little table: { name=..., x=..., y=..., vendor=... }
--   2. Lookup replaces the chain: locations[placeName]
--      finds a place by name. A miss gives nil — Lua's word
--      for "nothing there" — and nil IS the error check.
--   3. Places carry a vendor TAG: eight Glizzys-2-Go stores
--      share one tag, one menu, one stock pool. (Real
--      servers track stock per store; one pool per chain
--      keeps this lesson readable.)
--   4. Menus differ by chain: Glizzys sells fuel + dogs +
--      water, 2-Go sells dogs + water (no pumps!),
--      Tanazolam-tummy sells beans + energy drinks.
--
-- Prices are the Lesson 1 list: dog 50, water 10,
-- beans 15, energy drink 20, fuel 2 per unit.
-- ============================================================

-- Your state
gold = 200              -- payday from Lesson 3 shifts
carFuel = 60
carHealth = 100
glizzyDog = 1           -- your pack
water = 3
beans = 0
energyDrink = 0
fuelPrice = 2

-- Chain stock pools (one shelf count per chain)
gasDogs = 8             -- Glizzys Gas warmer
gasWater = 24           -- Glizzys Gas cooler
twoGoDogs = 12          -- Glizzys-2-Go, all 8 stores
twoGoWater = 30
tummyBeans = 15         -- Tanazolam-tummy, all 4 stores
tummyDrinks = 10

-- ============================================================
-- THE MAP — one table, sixteen places
-- ============================================================
locations = {
    home         = { name = "Home",                    x = 0,  y = 0,  vendor = "none" },
    gunStore     = { name = "Gun Store",               x = 3,  y = 4,  vendor = "gunStore" },
    mechanicShop = { name = "Mechanic Shop",           x = 6,  y = 8,  vendor = "mechanicShop" },
    glizzysGas   = { name = "Glizzys Gas",             x = 6,  y = 0,  vendor = "glizzysGas" },

    g2g1 = { name = "Glizzys-2-Go (Westside)",  x = -6, y = 2,  vendor = "glizzys2go" },
    g2g2 = { name = "Glizzys-2-Go (North)",     x = 0,  y = 10, vendor = "glizzys2go" },
    g2g3 = { name = "Glizzys-2-Go (Airport)",   x = 12, y = 10, vendor = "glizzys2go" },
    g2g4 = { name = "Glizzys-2-Go (South)",     x = 4,  y = -6, vendor = "glizzys2go" },
    g2g5 = { name = "Glizzys-2-Go (East)",      x = 14, y = 2,  vendor = "glizzys2go" },
    g2g6 = { name = "Glizzys-2-Go (Downtown)",  x = 2,  y = 6,  vendor = "glizzys2go" },
    g2g7 = { name = "Glizzys-2-Go (Riverside)", x = -3, y = -5, vendor = "glizzys2go" },
    g2g8 = { name = "Glizzys-2-Go (Highway)",   x = 10, y = 14, vendor = "glizzys2go" },

    tummy1 = { name = "Tanazolam-tummy (Original)", x = 1,  y = 3,  vendor = "tanazolam" },
    tummy2 = { name = "Tanazolam-tummy (Mall)",     x = 8,  y = 5,  vendor = "tanazolam" },
    tummy3 = { name = "Tanazolam-tummy (Campus)",   x = -4, y = 8,  vendor = "tanazolam" },
    tummy4 = { name = "Tanazolam-tummy (Harbor)",   x = 12, y = -3, vendor = "tanazolam" },
}

-- Where you are
currentLocation = "home"
posX = 0
posY = 0

-- ============================================================
-- TRAVEL — the table version. No elseif chain: one lookup.
-- ============================================================
function travelTo(placeName)
    local place = locations[placeName]
    if place == nil then
        print("No such place: " .. placeName)
        return
    end
    if placeName == currentLocation then
        print("You're already at " .. place.name .. ".")
        return
    end
    local dx = place.x - posX
    local dy = place.y - posY
    local distance = math.sqrt(dx ^ 2 + dy ^ 2)
    distance = math.floor(distance * 10 + 0.5) / 10  -- round to 1 decimal
    if carFuel < distance then
        print("Not enough fuel: " .. place.name .. " is " ..
              distance .. " away, " .. carFuel .. " in the tank.")
    else
        carFuel = carFuel - distance
        posX, posY = place.x, place.y
        currentLocation = placeName
        print("Drove to " .. place.name .. ". Fuel left: " .. carFuel)
    end
end

-- ============================================================
-- BUY FUEL — only where the vendor tag says glizzysGas
-- ============================================================
function buyFuel(amount)
    local place = locations[currentLocation]
    if place.vendor ~= "glizzysGas" then
        print("No pumps here. Fuel is sold at Glizzys Gas.")
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
-- BUY A SNACK — the menu depends on the vendor tag
-- glizzysGas / glizzys2go: dogs + water
-- tanazolam: beans + energy drinks
-- anywhere else: no snacks
-- ============================================================
function buySnack(kind, amount)
    local place = locations[currentLocation]
    local vendor = place.vendor

    if kind == "glizzyDog" or kind == "water" then
        if vendor ~= "glizzysGas" and vendor ~= "glizzys2go" then
            print(place.name .. " doesn't sell " .. kind .. ".")
            return
        end
    elseif kind == "beans" or kind == "energyDrink" then
        if vendor ~= "tanazolam" then
            print(place.name .. " doesn't sell " .. kind .. ".")
            return
        end
    else
        print("No vendor here sells: " .. kind)
        return
    end

    -- The right shelf: which chain are you standing in?
    if kind == "glizzyDog" then
        local cost = amount * 50
        if vendor == "glizzysGas" and gasDogs < amount then
            print("The warmer only has " .. gasDogs .. " dogs left.")
        elseif vendor == "glizzys2go" and twoGoDogs < amount then
            print("The chain only has " .. twoGoDogs .. " dogs left.")
        elseif gold < cost then
            print("Not enough gold: " .. amount .. " dog(s) cost " .. cost .. ".")
        else
            gold = gold - cost
            glizzyDog = glizzyDog + amount
            if vendor == "glizzysGas" then gasDogs = gasDogs - amount
            else twoGoDogs = twoGoDogs - amount end
            print("Bought " .. amount .. " glizzy dog(s) for " .. cost ..
                  " gold. Dogs in pack: " .. glizzyDog .. " | Gold: " .. gold)
        end
    elseif kind == "water" then
        local cost = amount * 10
        if vendor == "glizzysGas" and gasWater < amount then
            print("The cooler only has " .. gasWater .. " bottles left.")
        elseif vendor == "glizzys2go" and twoGoWater < amount then
            print("The chain only has " .. twoGoWater .. " bottles left.")
        elseif gold < cost then
            print("Not enough gold: " .. amount .. " water cost " .. cost .. ".")
        else
            gold = gold - cost
            water = water + amount
            if vendor == "glizzysGas" then gasWater = gasWater - amount
            else twoGoWater = twoGoWater - amount end
            print("Bought " .. amount .. " water for " .. cost ..
                  " gold. Water in pack: " .. water .. " | Gold: " .. gold)
        end
    elseif kind == "beans" then
        local cost = amount * 15
        if tummyBeans < amount then
            print("Tanazolam-tummy only has " .. tummyBeans .. " beans left.")
        elseif gold < cost then
            print("Not enough gold: " .. amount .. " beans cost " .. cost .. ".")
        else
            gold = gold - cost
            beans = beans + amount
            tummyBeans = tummyBeans - amount
            print("Bought " .. amount .. " beans for " .. cost ..
                  " gold. Beans in pack: " .. beans .. " | Gold: " .. gold)
        end
    elseif kind == "energyDrink" then
        local cost = amount * 20
        if tummyDrinks < amount then
            print("Tanazolam-tummy only has " .. tummyDrinks .. " energy drinks left.")
        elseif gold < cost then
            print("Not enough gold: " .. amount .. " energy drinks cost " .. cost .. ".")
        else
            gold = gold - cost
            energyDrink = energyDrink + amount
            tummyDrinks = tummyDrinks - amount
            print("Bought " .. amount .. " energy drink(s) for " .. cost ..
                  " gold. Energy drinks in pack: " .. energyDrink ..
                  " | Gold: " .. gold)
        end
    end
end

-- ============================================================
-- DISPLAY — where you are in the bigger world
-- ============================================================
function whereAmI()
    local place = locations[currentLocation]
    print("You are at " .. place.name ..
          " (" .. posX .. ", " .. posY .. ")" ..
          " | Fuel: " .. carFuel .. " | Gold: " .. gold ..
          " | Pack: " .. glizzyDog .. " dogs, " .. water ..
          " water, " .. beans .. " beans, " .. energyDrink ..
          " energy drinks")
end

-- ============================================================
-- TRY IT — one chain feeds you, the other refuses politely
-- ============================================================
whereAmI()                  -- home, gold 200
travelTo("tummy1")          -- the original Tanazolam-tummy
buySnack("beans", 2)        -- 2 x 15 = 30 -> gold 170, beans 2
buySnack("glizzyDog", 1)    -- refused: wrong chain's menu
travelTo("g2g5")            -- Glizzys-2-Go (East)
buySnack("glizzyDog", 1)    -- 50 -> gold 120, dogs 2
buyFuel(10)                 -- refused: 2-Go has no pumps
travelTo("nowhere")         -- refused: nil — no such place
travelTo("glizzysGas")      -- the one true pump
buyFuel(10)                 -- 10 x 2 = 20 -> gold 100, tank topped up
whereAmI()                  -- the end state, all in one place
