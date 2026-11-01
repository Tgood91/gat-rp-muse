# gta-rp

Tanner's GTA RP project, built lesson by lesson in plain Lua.

## Structure

```
resources/
  inventory/   player inventory + shop prices (Lesson 1)
  cars/        car system — key, fuel, engine, driving (Lesson 2)
  jobs/        jobs that pay gold (Lesson 3)
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
  - `jobs.lua` — earning instead of spending: two jobs (mechanic, taxi driver) picked with an `elseif` chain, `workShift()` pays gold into the same wallet the shop spends from. The taxi job needs the car from Lesson 2.

## Notes

- Plain Lua only — no game-engine calls yet. Engine/framework wiring comes later, once the target is picked.
- Adding an inventory item = 4 touches: the slot, the buy price, the sell price, and one mention in `showInventory()`.
