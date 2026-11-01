-- ============================================================
-- inventory.lua — player inventory + shop price list
-- Built in lessons with Tanner. Plain Lua, no dependencies.
--
-- HOW THIS FILE IS ORGANIZED
--   1. INVENTORY   — one variable per item (the "slots")
--   2. BUY PRICES  — what the shop charges
--   3. SELL PRICES — what the shop pays back (~40% of buy)
--   4. DISPLAY     — showInventory() prints everything
--
-- ADDING A NEW ITEM = add 1 line to section 1, 1 line to
-- section 2, 1 line to section 3, and 1 mention in section 4.
-- Every transaction snippet (buy / sell / use / combined cart)
-- works on a new item with no other changes.
-- ============================================================

playerName = "Tanner"

-- ============================================================
-- 1. INVENTORY — what the player owns
-- ============================================================
gold = 600
health = 85

-- Medical
bandages = 3
medkit = 1

-- Food & drink
glizzyDog = 2
waterBottle = 4
cannedBeans = 2
energyDrink = 1

-- Weapons & ammo
ar1Five = 1
pistol = 1
ammo = 90          -- AR rounds
pistolAmmo = 24    -- pistol rounds

-- Tools & gear
repairKits = 1
lockpick = 2
flashlight = 1
backpack = 1
fuelCan = 1        -- full; used by the car system
carKey = 1         -- key to the player's car; not buyable

-- ============================================================
-- 2. BUY PRICES — what the shop charges
-- ============================================================
bandagePrice = 25
medkitPrice = 120

glizzyDogPrice = 50
waterBottlePrice = 10
cannedBeansPrice = 15
energyDrinkPrice = 20

ar1FivePrice = 500
pistolPrice = 250
ammoPrice = 2          -- per round
pistolAmmoPrice = 1    -- per round

repairKitPrice = 40
lockpickPrice = 35
flashlightPrice = 30
backpackPrice = 150
fuelCanPrice = 60
carKeyPrice = 0        -- no price: a key is cut for one car only

-- ============================================================
-- 3. SELL PRICES — what the shop pays the player
-- ============================================================
bandageSellPrice = 10
medkitSellPrice = 50

glizzyDogSellPrice = 20
waterBottleSellPrice = 4
cannedBeansSellPrice = 6
energyDrinkSellPrice = 8

ar1FiveSellPrice = 200
pistolSellPrice = 100

repairKitSellPrice = 16
lockpickSellPrice = 14
flashlightSellPrice = 12
backpackSellPrice = 60
fuelCanSellPrice = 24

-- ============================================================
-- 4. DISPLAY — print the whole inventory
-- ============================================================
function showInventory()
    print("--- " .. playerName .. "'s Inventory ---")
    print("Gold: " .. gold .. " | Health: " .. health)
    print("Bandages: " .. bandages .. " | Medkits: " .. medkit)
    print("Glizzy dogs: " .. glizzyDog .. " | Water: " .. waterBottle ..
          " | Beans: " .. cannedBeans .. " | Energy drinks: " .. energyDrink)
    print("AR-15s: " .. ar1Five .. " | Pistols: " .. pistol ..
          " | Ammo: " .. ammo .. " | Pistol ammo: " .. pistolAmmo)
    print("Repair kits: " .. repairKits .. " | Lockpicks: " .. lockpick ..
          " | Flashlights: " .. flashlight .. " | Backpacks: " .. backpack)
    print("Fuel cans: " .. fuelCan .. " | Car keys: " .. carKey)
end

-- Show the starting inventory when the file runs.
showInventory()
