-- ============================================================
-- LESSON 17: config.lua — SHARED data.
-- The manifest lists this as a shared_script, so it loads
-- on the server AND on every client: the same table in
-- both worlds. That only works for data that is safe to
-- be public — and a shop's LOCATION is public. It stands
-- on the street; anyone can walk up to it.
--
-- Gold, stock, and prices did NOT move here. Those stay
-- server-only (Lesson 16's rule). Shared = safe to see.
--
-- The coords are real Los Santos spots: the two gun
-- vendors live at Ammu-Nations, Glizzys at a gas station,
-- Tummy Express at a 24/7. They're starting points: stand
-- where YOU want a shop, run /coords in game, and paste
-- your numbers over these.
-- ============================================================
Config = {}

-- How close (in metres) counts as "at the shop".
Config.BuyRange = 5.0

-- Lesson 25: whose money runs the tills.
--   "standalone"  this resource's own wallets (default —
--                 no framework needed, everything as
--                 Lessons 16-24 built it)
--   "esx"         ESX cash (es_extended must be started
--                 BEFORE shops in server.cfg)
--   "qbcore"      QBCore cash (qb-core started first)
-- Under esx/qbcore the framework owns the money: our
-- gold is neither saved nor restored — items only.
Config.Framework = "standalone"

Config.Vendors = {
    tanazAmmo = {
        label = "Tanaz Ammo",
        coords = vector3(842.4, -1033.4, 28.2),  -- Ammu-Nation, east LS
        blip = 110,        -- Ammu-Nation gun icon
        blipColour = 17,   -- orange
    },
    bushidoSupply = {
        label = "Bushido Supply",
        coords = vector3(-662.2, -935.4, 21.8),  -- Ammu-Nation, Little Seoul
        blip = 110,
        blipColour = 17,
    },
    glizzysDepot = {
        label = "Glizzys Depot",
        coords = vector3(-526.5, -1211.4, 18.2), -- LTD gas station, Little Seoul
        blip = 361,        -- gas station icon
        blipColour = 5,    -- yellow
    },
    tummyExpress = {
        label = "Tanaz-tummy Express",
        coords = vector3(25.7, -1346.6, 29.5),   -- 24/7 store, Strawberry
        blip = 52,         -- store icon
        blipColour = 2,    -- green
    },
}

-- Lesson 28: JOBS — where honest work happens. The spots
-- and the pay (Lesson 3's numbers, unchanged) are public —
-- the signs stand on the street — so they live here with
-- the vendors. Who is mid-shift and how long a shift runs
-- stay server-only (server.lua): anyone can read the sign
-- on the door; the foreman's clipboard is another matter.
Config.Jobs = {
    mechanic = {
        label = "Mechanic",
        place = "LS Customs",
        coords = vector3(-337.2, -136.4, 39.0),  -- LS Customs, Burton
        blip = 446,        -- wrench icon
        blipColour = 17,   -- orange
        pay = 80,
    },
    taxi = {
        label = "Taxi Driver",
        place = "Downtown Cab Co.",
        coords = vector3(894.8, -179.2, 74.7),   -- Downtown Cab Co., east LS
        blip = 198,        -- taxi icon
        blipColour = 5,    -- yellow
        pay = 40,
    },
    delivery = {
        label = "Delivery Driver",
        place = "Post OP Depot",
        coords = vector3(-424.2, -2789.6, 6.0),  -- Post OP depot, port side
        blip = 478,        -- parcel icon
        blipColour = 2,    -- green
        pay = 100,
    },
}
