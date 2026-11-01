# gta-rp

Tanner's GTA RP project, built lesson by lesson in plain Lua.

## Structure

```
resources/
  inventory/   player inventory + shop prices (Lesson 1)
  cars/        car system — key, fuel, engine, driving (Lesson 2)
  jobs/        jobs that pay gold (Lesson 3)
  weapons/     equip + shoot, per-weapon ammo (Lesson 4)
  vendors/     vendors + buying ammo (Lesson 5)
  repairs/     the mechanic shop + car health (Lesson 6)
  maps/        locations, coordinates, travel (Lesson 7)
  needs/       health, hunger + thirst (Lesson 8)
  custom/      custom content registries + wiring (Lessons 13–14)
```

Coming later: maps. Rule of the repo: a folder is only created when its
lesson has real code — no empty lessons.

## Lessons so far

- **Lesson 1 — Inventory** (`resources/inventory/`)
  - `inventory.lua` — the main inventory: 18 items in 4 sections (what you own / buy prices / sell prices / `showInventory()`), plus the transaction recipe: **check → move → report**.
  - `transactions.lua` — 8 worked transaction snippets on one shared inventory: buy, sell, use (with the health cap), bulk ammo, a combined all-or-nothing cart, and a player-to-player trade.
- **Lesson 2 — Cars** (`resources/cars/`)
  - `cars.lua` — a car as slots (model, speed, fuel) with a boolean `engineOn`. `startCar()` checks key first, then fuel; `drive()` costs fuel; `refuel()` spends a fuel can from the inventory and caps the tank at 100. Borrows `carKey` and `fuelCan` from Lesson 1.
- **Lesson 3 — Jobs** (`resources/jobs/`)
  - `jobs.lua` — earning instead of spending: three jobs (mechanic 80, taxi 40, delivery 100) picked with an `elseif` chain, `workShift()` pays gold into the same wallet the shop spends from. Taxi and delivery need the car key from Lesson 1.
- **Lesson 4 — Weapons** (`resources/weapons/`)
  - `weapons.lua` — equip what you own (`equipWeapon`), `shoot()` spends from the equipped weapon's own ammo pool: pistol 1 round per shot, AR-15 a 3-round burst with a 3-round check.
- **Lesson 5 — Vendors** (`resources/vendors/`)
  - `vendors.lua` — a vendor is a place: you can only buy while you're there. `buyAmmo()` runs the full counter: cost = price × amount, checks vendor stock *and* your gold, then moves all three — gold down, your ammo up, shelf stock down. Buys at Lesson 1 prices (AR 2/round, pistol 1/round).
- **Lesson 6 — Vehicle repairs** (`resources/repairs/`)
  - `repairs.lua` — the car gets a `carHealth` slot (0–100). The mechanic shop is the second vendor: `buyPart()` sells repair kits (200) and fuel cans (25), `useRepairKit()` spends a kit to heal the car +30, capped at 100. Buy → hold → use, across three systems.
- **Lesson 7 — Maps** (`resources/maps/`)
  - `maps.lua` — places as name + (x, y) coordinates. `travelTo()` computes distance with `math.sqrt`, charges 1 fuel per unit, and moves you; vendors only open when you're standing at their location, so the map locks Lessons 5–6 together. Includes Glizzys Gas, a fuel vendor at (6, 0) selling fuel at 2 gold/unit with a tank-cap check.
- **Lesson 8 — Needs** (`resources/needs/`)
  - `needs.lua` — player vitals: health, hunger, thirst. `eat()`/`drink()` spend pack items to refill a stat (capped at 100), `play(hours)` drains hunger −10/hr and thirst −15/hr (floored at 0), and an empty stat taxes health −5. Uses Lesson 1's health 85 and food counts.
- **Lesson 9 — Tables + vendor chains** (`resources/maps/`)
  - `chains.lua` — the map becomes one `locations` table (16 places), and lookup replaces the elseif chain (`nil` = no such place). Adds Tanner's two chains: **Glizzys-2-Go** ×8 (dogs + water, no pumps) and **Tanaz-tummy** ×4 (beans + energy drinks), each with a vendor tag, a menu, and a shared chain stock pool. Distances rounded to 1 decimal.
- **Lesson 10 — The inventory, tabled** (`resources/inventory/`)
  - `inventory_tables.lua` — Lesson 1 rebuilt on tables (original untouched): 48 loose variables become 3 tables (`player`, `items`, nested `prices{item={buy,sell}}`). One generic `buy()`/`sell()` handles every item via lookup; nil covers both unknown items and unsellable ones (ammo, car key); a `pairs` loop prints the whole inventory.
- **Lesson 11 — Importing specialized cars** (`resources/cars/`)
  - `imports.lua` — an import catalog table (Taxi Cab, Delivery Van, Armored SUV, ZipZap) where each car is data: price, top speed, tank, health, a special trait, and a job bonus. `importCar()` charges price + 15% import fee (integer division `//` keeps gold whole), the garage is a numbered LIST table searched with a numeric `for` loop, and `setCar()` swaps your current car.
- **Lesson 12 — Wired jobs** (`resources/jobs/`)
  - `shifts.lua` — jobs become a table too (pay, key requirement, specialized car, bonus), and `workShift()` reads `currentCarKey`: the Lesson 11 bonuses go live as pairings (Taxi Cab +20 on taxi only, Delivery Van +30 on delivery only), with `job.bonus or 0` defaulting unpaired jobs to no bonus.
- **Lesson 13 — Custom content** (`resources/custom/`)
  - `custom_content.lua` — one registry table per category (vendors, vehicles, armour, ammo, firearms) and one gatekeeper add function per category: label + required field + unused key, or the entry is refused. Firearms are cross-checked against real ammo types (base or custom) before they can register; labeled registries are counted with a `pairs` loop. Includes Tanaz Ammo, whose sells list is the whole `ammo` category — ALL ammo.
- **Lesson 14 — Wired custom content** (`resources/custom/`)
  - `wired_systems.lua` — the older systems read the registries: a category map (`Registries`) lets one `buyFromVendor()` sell armour, firearms, and ammo; `VendorStock` tracks what each vendor actually has (separate from what it *can* sell); `stockCustomAmmo()` restocks vendor shelves; and Lesson 11's importer reads `CustomVehicles` via `importCustomVehicle()`. Adds Bushido Supply (a gear vendor at the gun store) and Tanaz Ammo (all ammo: base types merged with the custom ones in one `AmmoCatalog`), plus `restockAllVendors(80)` — every vendor's shelves topped UP TO 80% of capacity (fills only, never drains).
- **Lesson 15 — Restock timer** (`resources/custom/`)
  - `restock_timer.lua` — the 80% rule on a clock: a tick loop (`runCity`) where each pass is one game hour, a `Demand` rate table drains every shelf (the city buys too; `math.min` keeps a shelf from selling below zero), and a counter fires `restockAllVendors(80)` by itself every 4 hours — no human call. Shelves saw-tooth: drain, drain, drain, snap back to 80%.
- **Lesson 16 — First FiveM resource** (`resources/shops/`)
  - `fxmanifest.lua`, `server.lua`, `client.lua` — the vendor system as a real FiveM resource: the server owns vendors, stock, per-player wallets, and the restock timer (a `CreateThread` loop; 1 city hour = 60s so you can watch it); the client only asks. `/buyammo pistolAmmo 20` sends an event, the server re-checks everything (a modded client can't be trusted) and replies with the result; `/wallet` reports gold + owned ammo; `restocknow` in the server console forces the 80% restock.
- **Lesson 17 — You have to be there** (`resources/shops/`)
  - Adds `config.lua` (a shared script: loads on server AND clients — public data only) holding each vendor's real Los Santos location (Ammu-Nations, a gas station, a 24/7) and a 5m buy range. The server now reads the buyer's position from their ped and refuses buys from out of range — coords never come from the client. Client gains one map blip per vendor, `/whereami` (nearest shop + distance), and `/coords` (a dev tool for placing shops: stand somewhere, capture the numbers, paste them into the config).

## Notes

- Lessons 1–15 are plain Lua. Lessons 16–17 are a real FiveM resource (`resources/shops/`) — the only part of this repo that installs into a server. Framework (ESX/QBCore) wiring comes later.
- **Running it in a FiveM server:** see [FIVEM_SERVER_SETUP.md](FIVEM_SERVER_SETUP.md) — FXServer install, where the resource goes, the `server.cfg` line, and the in-game test checklist.
- Adding an inventory item = 4 touches: the slot, the buy price, the sell price, and one mention in `showInventory()`.
