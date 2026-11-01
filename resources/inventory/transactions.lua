-- ============================================================
-- LUA INVENTORY TRANSACTIONS — worked examples
-- Every transaction follows the same recipe:
--   1. CHECK  (enough gold? enough stock?)
--   2. MOVE   (one slot down, one slot up)
--   3. REPORT (print what happened)
-- Run order matters: each snippet builds on the numbers above it.
-- ============================================================

-- ---------- SETUP: the inventory ----------
playerName = "Tanner"
gold = 600
bandages = 3
repairKits = 1
ar1Five = 1
ammo = 60

-- ---------- SETUP: the shop's price list ----------
bandagePrice = 25
repairKitPrice = 40
ar1FivePrice = 500
ammoPrice = 2          -- per round
bandageSellPrice = 10  -- shops buy back cheaper than they sell

-- ---------- NEW TOOL: a function ----------
-- A function is a saved block of code you can run by name.
-- Instead of re-typing all the print lines after every trade,
-- we wrap them once and call showInventory() whenever we want.
function showInventory()
    print("--- " .. playerName .. "'s Inventory ---")
    print("Gold: " .. gold)
    print("Bandages: " .. bandages)
    print("Repair kits: " .. repairKits)
    print("AR-15s: " .. ar1Five)
    print("Ammo: " .. ammo)
end

print("=== STARTING INVENTORY ===")
showInventory()

-- ============================================================
-- SNIPPET 1 — Buy 1 bandage (25 gold)
-- ============================================================
print("\n=== Buy 1 bandage ===")
if gold >= bandagePrice then
    gold = gold - bandagePrice
    bandages = bandages + 1
    print("Bought a bandage for " .. bandagePrice .. " gold.")
else
    print("Not enough gold for a bandage.")
end
showInventory()
-- Result: gold 600 -> 575, bandages 3 -> 4

-- ============================================================
-- SNIPPET 2 — Buy 1 repair kit (40 gold)
-- ============================================================
print("\n=== Buy 1 repair kit ===")
if gold >= repairKitPrice then
    gold = gold - repairKitPrice
    repairKits = repairKits + 1
    print("Bought a repair kit for " .. repairKitPrice .. " gold.")
else
    print("Not enough gold for a repair kit.")
end
showInventory()
-- Result: gold 575 -> 535, repair kits 1 -> 2

-- ============================================================
-- SNIPPET 3 — Buy in bulk: 30 rounds of ammo (2 gold each)
-- The new idea: total cost = price x amount
-- ============================================================
print("\n=== Buy 30 ammo ===")
amount = 30
totalCost = ammoPrice * amount
if gold >= totalCost then
    gold = gold - totalCost
    ammo = ammo + amount
    print("Bought " .. amount .. " ammo for " .. totalCost .. " gold.")
else
    print("Not enough gold. Need " .. totalCost .. ", have " .. gold)
end
showInventory()
-- Result: gold 535 -> 475, ammo 60 -> 90

-- ============================================================
-- SNIPPET 4 — The big one: buy 1 AR-15 (500 gold)
-- Watch what happens: at 475 gold this trade REFUSES.
-- The guard from the lesson, doing its job.
-- ============================================================
print("\n=== Buy 1 AR-15 ===")
if gold >= ar1FivePrice then
    gold = gold - ar1FivePrice
    ar1Five = ar1Five + 1
    print("Bought an AR-15 for " .. ar1FivePrice .. " gold.")
else
    print("Not enough gold. Need " .. ar1FivePrice .. ", have " .. gold)
end
showInventory()
-- Result: REFUSED. gold stays 475, AR-15s stay 1

-- ============================================================
-- SNIPPET 5 — Sell 2 bandages back to the shop (10 gold each)
-- Selling checks STOCK instead of gold.
-- ============================================================
print("\n=== Sell 2 bandages ===")
amount = 2
if bandages >= amount then
    bandages = bandages - amount
    gold = gold + (bandageSellPrice * amount)
    print("Sold " .. amount .. " bandages for " .. (bandageSellPrice * amount) .. " gold.")
else
    print("Not enough bandages to sell.")
end
showInventory()
-- Result: bandages 4 -> 2, gold 475 -> 495

-- ============================================================
-- SNIPPET 6 — Use a bandage (heal)
-- Using checks stock too, and adds an effect (health).
-- ============================================================
print("\n=== Use a bandage ===")
health = 60
if bandages > 0 then
    bandages = bandages - 1
    health = health + 25
    if health > 100 then health = 100 end  -- health can't pass 100
    print("Used a bandage. Health now " .. health .. ".")
else
    print("No bandages left!")
end
showInventory()
-- Result: bandages 2 -> 1, health 60 -> 85

-- ============================================================
-- SNIPPET 7 — Use a repair kit
-- ============================================================
print("\n=== Use a repair kit ===")
if repairKits > 0 then
    repairKits = repairKits - 1
    print("Used a repair kit.")
else
    print("No repair kits left!")
end
showInventory()
-- Result: repair kits 2 -> 1

-- ============================================================
-- SNIPPET 8 — Player-to-player trade
-- Tanner buys the AR-15 from another player, "Maya", for 500.
-- A real trade moves FOUR slots: both sides of both players.
-- It also needs TWO checks: buyer can pay AND seller has stock.
-- ============================================================
print("\n=== Player trade: Tanner buys Maya's AR-15 ===")

-- Maya's inventory (her own separate slots)
mayaGold = 120
mayaAr1Five = 1

tradePrice = 500

if gold >= tradePrice and mayaAr1Five > 0 then
    -- Tanner's side
    gold = gold - tradePrice
    ar1Five = ar1Five + 1
    -- Maya's side
    mayaGold = mayaGold + tradePrice
    mayaAr1Five = mayaAr1Five - 1
    print("Trade done! Tanner paid Maya " .. tradePrice .. " gold for an AR-15.")
elseif gold < tradePrice then
    print("Trade refused: Tanner can't cover " .. tradePrice .. " gold.")
else
    print("Trade refused: Maya has no AR-15 to sell.")
end

print("Tanner — Gold: " .. gold .. " | AR-15s: " .. ar1Five)
print("Maya   — Gold: " .. mayaGold .. " | AR-15s: " .. mayaAr1Five)
-- Tanner has 495 gold at this point (see snippets above),
-- so this one REFUSES too — by 5 gold. Sell one more bandage
-- (Snippet 5) first and it goes through: that's game economy.

print("\n=== FINAL INVENTORY ===")
showInventory()
