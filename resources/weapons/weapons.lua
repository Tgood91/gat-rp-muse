-- ============================================================
-- weapons.lua — Lesson 4: weapons
-- Built after inventory (1), cars (2), and jobs (3).
-- Plain Lua, no game-engine functions, no dependencies.
--
-- NEW IDEAS IN THIS LESSON
--   1. One action, different slot: shoot() spends ammo from
--      a DIFFERENT pool depending on which weapon is equipped
--      — the elseif chain picks which slot moves.
--   2. A bigger move: the AR fires a 3-round burst, so one
--      shot moves ammo by 3, not 1 — and the check has to
--      ask for 3, not 1.
--
-- This file stands alone so you can run it by itself. It
-- reuses four things from inventory.lua with the same
-- starting values: ar1Five = 1, pistol = 1, ammo = 90,
-- pistolAmmo = 24.
-- ============================================================

-- From inventory.lua
ar1Five = 1         -- AR-15s owned
pistol = 1          -- pistols owned
ammo = 90           -- AR rounds
pistolAmmo = 24     -- pistol rounds

-- The equipped weapon: one slot, holds a word
equipped = "none"   -- "none", "pistol", or "ar1Five"

-- ============================================================
-- EQUIP — you can only hold what you own
-- ============================================================
function equipWeapon(weaponName)
    if weaponName == "pistol" then
        if pistol < 1 then
            print("You don't own a pistol.")
        else
            equipped = "pistol"
            print("Pistol equipped.")
        end
    elseif weaponName == "ar1Five" then
        if ar1Five < 1 then
            print("You don't own an AR-15.")
        else
            equipped = "ar1Five"
            print("AR-15 equipped.")
        end
    else
        print("No such weapon: " .. weaponName)
    end
end

-- ============================================================
-- SHOOT — check -> move -> report, per weapon
-- Pistol: 1 round per shot. AR: 3-round burst.
-- ============================================================
function shoot()
    if equipped == "none" then
        print("No weapon equipped. Equip one first.")
    elseif equipped == "pistol" then
        if pistolAmmo < 1 then
            print("Click. Pistol is out of ammo.")
        else
            pistolAmmo = pistolAmmo - 1
            print("Bang! Pistol ammo: " .. pistolAmmo)
        end
    elseif equipped == "ar1Five" then
        if ammo < 3 then
            print("Click. Not enough ammo for a burst (needs 3).")
        else
            ammo = ammo - 3
            print("Burst! AR ammo: " .. ammo)
        end
    end
end

-- ============================================================
-- DISPLAY — print the weapon state
-- ============================================================
function showWeapons()
    print("Equipped: " .. equipped ..
          " | AR-15s: " .. ar1Five .. " (ammo: " .. ammo .. ")" ..
          " | Pistols: " .. pistol .. " (ammo: " .. pistolAmmo .. ")")
end

-- ============================================================
-- TRY IT — equip, shoot, switch, shoot again
-- ============================================================
showWeapons()          -- nothing equipped, ammo 90 / 24
shoot()                -- refused: no weapon equipped
equipWeapon("pistol")  -- own it -> equipped
shoot()                -- pistol ammo 23
shoot()                -- pistol ammo 22
equipWeapon("ar1Five") -- switch to the AR
shoot()                -- burst: AR ammo 87
shoot()                -- burst: AR ammo 84
showWeapons()          -- the end state, all in one place
