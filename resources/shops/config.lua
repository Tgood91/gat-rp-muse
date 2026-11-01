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

Config.Vendors = {
    tanaz0lamAmmo = {
        label = "Tanaz0lam Ammo",
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
        label = "Tanazolam-tummy Express",
        coords = vector3(25.7, -1346.6, 29.5),   -- 24/7 store, Strawberry
        blip = 52,         -- store icon
        blipColour = 2,    -- green
    },
}
