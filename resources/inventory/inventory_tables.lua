-- ============================================================
-- inventory_tables.lua — Lesson 10: the inventory, tabled
-- A new file alongside inventory.lua (Lesson 1), which is
-- NOT modified. Same data, new shape. Plain Lua, no deps.
--
-- WHAT LESSON 10 DOES TO LESSON 1
-- Lesson 1 stored the inventory as 48 loose variables:
-- 16 items + 16 buy prices + 13 sell prices + name/gold/
-- health. Adding an item meant editing 4 places.
--
-- NEW IDEAS IN THIS LESSON
--   1. Three tables hold everything: player, items, prices.
--      Prices are tables inside the table (nested) — one
--      slot per item carrying BOTH its prices: {buy=, sell=}
--   2. ONE buy() and ONE sell() work for EVERY item, via
--      lookup. A new item = 1 line in items + 1 line in
--      prices. Zero new code.
--   3. nil does double duty: an unknown item has no prices
--      entry (nil), and ammo has no sell price (nil) — two
--      different refusals from the same check.
--   4. Dot access for table slots: player.gold, and the
--      pairs loop prints the whole inventory in 3 lines.
-- ============================================================

-- The player: name, gold, health in one box
player = { name = "Tanner", gold = 600, health = 85 }

-- What you own: item name -> count (Lesson 1's exact counts)
items = {
    bandages = 3,   medkit = 1,
    glizzyDog = 2,  waterBottle = 4,  cannedBeans = 2, energyDrink = 1,
    ar1Five = 1,    pistol = 1,       ammo = 90,       pistolAmmo = 24,
    repairKits = 1, lockpick = 2,     flashlight = 1,  backpack = 1,
    fuelCan = 1,    carKey = 1,
}

-- What the shop charges and pays: item name -> {buy, sell}
-- No sell slot = the shop won't buy it (ammo, car key).
-- buy = 0 = not for sale at any price (the car key).
prices = {
    bandages = { buy = 25,  sell = 10 },
    medkit = { buy = 120, sell = 50 },
    glizzyDog = { buy = 50,  sell = 20 },
    waterBottle = { buy = 10,  sell = 4 },
    cannedBeans = { buy = 15,  sell = 6 },
    energyDrink = { buy = 20,  sell = 8 },
    ar1Five = { buy = 500, sell = 200 },
    pistol = { buy = 250, sell = 100 },
    ammo = { buy = 2 },
    pistolAmmo = { buy = 1 },
    repairKits = { buy = 40,  sell = 16 },
    lockpick = { buy = 35,  sell = 14 },
    flashlight = { buy = 30,  sell = 12 },
    backpack = { buy = 150, sell = 60 },
    fuelCan = { buy = 60,  sell = 24 },
    carKey = { buy = 0 },
}

-- ============================================================
-- BUY — one function, every item
-- check (known? for sale? gold?) -> move x2 -> report
-- ============================================================
function buy(itemName, amount)
    local p = prices[itemName]
    if p == nil then
        print("Unknown item: " .. itemName)
    elseif p.buy == 0 then
        print("The " .. itemName .. " is not for sale.")
    else
        local cost = amount * p.buy
        if player.gold < cost then
            print("Not enough gold: " .. amount .. " x " .. itemName ..
                  " costs " .. cost .. ".")
        else
            player.gold = player.gold - cost
            items[itemName] = items[itemName] + amount
            print("Bought " .. amount .. " x " .. itemName .. " for " ..
                  cost .. " gold. Gold: " .. player.gold)
        end
    end
end

-- ============================================================
-- SELL — the mirror: check (known? sellable? have enough?)
-- ============================================================
function sell(itemName, amount)
    local p = prices[itemName]
    if p == nil then
        print("Unknown item: " .. itemName)
    elseif p.sell == nil then
        print("The shop won't buy " .. itemName .. ".")
    elseif items[itemName] < amount then
        print("You only have " .. items[itemName] .. " x " .. itemName .. ".")
    else
        local earned = amount * p.sell
        items[itemName] = items[itemName] - amount
        player.gold = player.gold + earned
        print("Sold " .. amount .. " x " .. itemName .. " for " ..
              earned .. " gold. Gold: " .. player.gold)
    end
end

-- ============================================================
-- DISPLAY — the pairs loop walks the whole table.
-- Note: pairs order is NOT promised — the table doesn't
-- remember the order you wrote the lines in.
-- ============================================================
function showInventory()
    print("--- " .. player.name .. "'s Inventory ---")
    print("Gold: " .. player.gold .. " | Health: " .. player.health)
    for itemName, count in pairs(items) do
        print(itemName .. ": " .. count)
    end
end

-- ============================================================
-- TRY IT — the Lesson 1 shop, run by two functions
-- ============================================================
buy("bandages", 2)     -- 2 x 25 = 50 -> gold 550, bandages 5
buy("carKey", 1)       -- refused: not for sale
buy("ar1Five", 1)      -- 500 -> gold 50, ARs 2
buy("medkit", 1)       -- refused: 120 gold, you have 50
sell("ar1Five", 1)     -- +200 -> gold 250, ARs back to 1
sell("ammo", 10)       -- refused: the shop won't buy ammo
sell("bandages", 99)   -- refused: you only have 5
buy("rocketLauncher", 1) -- refused: unknown item (nil)
showInventory()        -- everything, via the loop
