-- ============================================================
-- vendors.lua — Lesson 5: vendors + buying ammo
-- Built after inventory (1), cars (2), jobs (3), weapons (4).
-- Plain Lua, no game-engine functions, no dependencies.
--
-- NEW IDEAS IN THIS LESSON
--   1. A vendor is a place: you can only buy while you're
--      THERE. atVendor is one more slot the check looks at.
--   2. Both sides of the counter move: your gold goes down
--      and your ammo goes up — and the vendor's stock goes
--      down. A buy is THREE moves, not two.
--   3. Cost is price x amount: buying in bulk multiplies
--      first, then the gold check uses the total.
--
-- This file stands alone so you can run it by itself. It
-- picks up where Lesson 4 ended: gold = 600 (Lesson 1),
-- ammo = 84 and pistolAmmo = 22 (after the Lesson 4 demo).
-- Prices are the Lesson 1 shop prices: AR ammo 2 gold a
-- round, pistol ammo 1 gold a round.
-- ============================================================

-- Your side of the counter
gold = 600
ammo = 84           -- AR rounds (Lesson 4 ended here)
pistolAmmo = 22     -- pistol rounds (Lesson 4 ended here)

-- Prices (from inventory.lua)
ammoPrice = 2           -- per AR round
pistolAmmoPrice = 1     -- per pistol round

-- The vendor: the gun store, with its own stock slots
atVendor = "none"       -- "none" or "gunStore"
gunStoreArAmmo = 200    -- AR rounds on the shelf
gunStorePistolAmmo = 100

-- ============================================================
-- GO TO A VENDOR — buying only works while you're there
-- ============================================================
function visitVendor(vendorName)
    if vendorName == "gunStore" then
        atVendor = "gunStore"
        print("You walk into the gun store.")
    else
        print("No such vendor: " .. vendorName)
    end
end

function leaveVendor()
    atVendor = "none"
    print("You leave the store.")
end

-- ============================================================
-- BUY AMMO — check (there? stock? gold?) -> move x3 -> report
-- ============================================================
function buyAmmo(kind, amount)
    if atVendor == "none" then
        print("You're not at a vendor. Nobody here sells ammo.")
    elseif kind == "ammo" then
        local cost = amount * ammoPrice
        if gunStoreArAmmo < amount then
            print("The store only has " .. gunStoreArAmmo .. " AR rounds.")
        elseif gold < cost then
            print("Not enough gold: " .. amount .. " rounds cost " .. cost .. ".")
        else
            gold = gold - cost
            ammo = ammo + amount
            gunStoreArAmmo = gunStoreArAmmo - amount
            print("Bought " .. amount .. " AR rounds for " .. cost ..
                  " gold. Ammo: " .. ammo .. " | Gold: " .. gold)
        end
    elseif kind == "pistolAmmo" then
        local cost = amount * pistolAmmoPrice
        if gunStorePistolAmmo < amount then
            print("The store only has " .. gunStorePistolAmmo .. " pistol rounds.")
        elseif gold < cost then
            print("Not enough gold: " .. amount .. " rounds cost " .. cost .. ".")
        else
            gold = gold - cost
            pistolAmmo = pistolAmmo + amount
            gunStorePistolAmmo = gunStorePistolAmmo - amount
            print("Bought " .. amount .. " pistol rounds for " .. cost ..
                  " gold. Pistol ammo: " .. pistolAmmo .. " | Gold: " .. gold)
        end
    else
        print("The store doesn't sell: " .. kind)
    end
end

-- ============================================================
-- DISPLAY — both sides of the counter
-- ============================================================
function showVendor()
    print("At vendor: " .. atVendor ..
          " | Store stock — AR rounds: " .. gunStoreArAmmo ..
          ", pistol rounds: " .. gunStorePistolAmmo ..
          " | Your gold: " .. gold ..
          " | Your ammo: " .. ammo .. " / " .. pistolAmmo)
end

-- ============================================================
-- TRY IT — try to buy from nowhere, then go shopping
-- ============================================================
buyAmmo("ammo", 10)        -- refused: not at a vendor
visitVendor("gunStore")    -- walk in
showVendor()               -- stock 200 / 100, your gold 600
buyAmmo("ammo", 30)        -- 30 x 2 = 60 gold -> gold 540, ammo 114, shelf 170
buyAmmo("pistolAmmo", 20)  -- 20 x 1 = 20 gold -> gold 520, pistolAmmo 42, shelf 80
buyAmmo("pistolAmmo", 500) -- refused: only 80 on the shelf
leaveVendor()              -- walk out
showVendor()               -- the end state, both sides
