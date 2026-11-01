-- ============================================================
-- needs.lua — Lesson 8: health, hunger + thirst
-- Built after inventory (1), cars (2), jobs (3), weapons (4),
-- vendors (5), repairs (6), maps (7). Plain Lua, no deps.
--
-- NEW IDEAS IN THIS LESSON
--   1. Vitals: numbers that describe YOU — health, hunger,
--      thirst — the same slot idea as carHealth, on a person.
--   2. Drain: time pushes back. Playing costs hunger and
--      thirst whether you eat or not.
--   3. Clamp BOTH ends: stats cap at 100 (Lesson 6) AND
--      floor at 0. Nothing goes negative, nothing overflows.
--   4. Systems chain: an empty stat bills the next one —
--      hunger or thirst at 0 starts taxing your health.
--
-- This file stands alone so you can run it by itself.
-- Starting values come from Lesson 1: health 85, and the
-- food in your pack — glizzyDog 2, beans 2, water 4,
-- energyDrink 1.
-- ============================================================

-- Your vitals: 100 = full, 0 = empty (health: 0 = dead)
health = 85         -- from inventory.lua
hunger = 45         -- you start peckish
thirst = 35         -- and thirsty

-- Your food and drink (from inventory.lua)
glizzyDog = 2
beans = 2
water = 4
energyDrink = 1

-- ============================================================
-- EAT — spend a food item, hunger goes up, capped at 100
-- ============================================================
function eat(foodName)
    if foodName == "glizzyDog" then
        if glizzyDog < 1 then
            print("No glizzy dogs left.")
        else
            glizzyDog = glizzyDog - 1
            hunger = hunger + 40
            if hunger > 100 then hunger = 100 end
            print("Ate a glizzy dog. Hunger: " .. hunger ..
                  " | Dogs left: " .. glizzyDog)
        end
    elseif foodName == "beans" then
        if beans < 1 then
            print("No beans left.")
        else
            beans = beans - 1
            hunger = hunger + 25
            if hunger > 100 then hunger = 100 end
            print("Ate some beans. Hunger: " .. hunger ..
                  " | Beans left: " .. beans)
        end
    else
        print("You can't eat: " .. foodName)
    end
end

-- ============================================================
-- DRINK — the same recipe, pointed at thirst
-- ============================================================
function drink(drinkName)
    if drinkName == "water" then
        if water < 1 then
            print("No water left.")
        else
            water = water - 1
            thirst = thirst + 50
            if thirst > 100 then thirst = 100 end
            print("Drank water. Thirst: " .. thirst ..
                  " | Water left: " .. water)
        end
    elseif drinkName == "energyDrink" then
        if energyDrink < 1 then
            print("No energy drinks left.")
        else
            energyDrink = energyDrink - 1
            thirst = thirst + 30
            if thirst > 100 then thirst = 100 end
            print("Drank an energy drink. Thirst: " .. thirst ..
                  " | Energy drinks left: " .. energyDrink)
        end
    else
        print("You can't drink: " .. drinkName)
    end
end

-- ============================================================
-- PLAY — time passes, vitals drain, empties bill your health
-- Hunger -10/hour, thirst -15/hour (you dry out faster)
-- ============================================================
function play(hours)
    hunger = hunger - (hours * 10)
    thirst = thirst - (hours * 15)
    if hunger < 0 then hunger = 0 end
    if thirst < 0 then thirst = 0 end
    print(hours .. " hours pass. Hunger: " .. hunger ..
          " | Thirst: " .. thirst)
    if hunger == 0 then
        health = health - 5
        print("You're starving — health drops to " .. health ..
              ". Eat something.")
    end
    if thirst == 0 then
        health = health - 5
        print("You're dehydrated — health drops to " .. health ..
              ". Drink something.")
    end
end

-- ============================================================
-- DISPLAY — your vitals and your pack, in one place
-- ============================================================
function showStatus()
    print("Health: " .. health .. " | Hunger: " .. hunger ..
          " | Thirst: " .. thirst ..
          " | Pack: " .. glizzyDog .. " dogs, " .. beans ..
          " beans, " .. water .. " water, " .. energyDrink ..
          " energy drinks")
end

-- ============================================================
-- TRY IT — eat, drink, burn it off, pay for ignoring thirst
-- ============================================================
showStatus()          -- health 85, hunger 45, thirst 35
eat("glizzyDog")      -- dogs 1, hunger 85
drink("water")        -- water 3, thirst 85
play(3)               -- hunger 55, thirst 40
play(4)               -- hunger 15, thirst 0 -> health 80
eat("beans")          -- beans 1, hunger 40
drink("energyDrink")  -- drinks 0, thirst 30
eat("beans")          -- beans 0, hunger 65
eat("beans")          -- refused: none left
showStatus()          -- the end state, all in one place
