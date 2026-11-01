# Implementing the Shops Resource in a FiveM Server

Step-by-step for putting this repo's one live resource — `resources/shops/`
(Lessons 16–17: Tanaz Ammo, Bushido Supply, Glizzys Depot, Tanaz-tummy
Express, the 80% restock timer) — into a local FiveM server on Windows,
so you can walk up and buy in-game.

> Everything else in this repo is plain-Lua lessons. They are the learning
> trail, **not** server resources — only the `shops` folder gets installed.

## 1. Get FXServer (the server program)

1. Download the latest recommended Windows server build from the
   FiveM artifacts page (`runtime.fivem.net/artifacts/fivem/build_server_windows/master/`).
2. Extract it to a folder with no spaces, e.g. `C:\FXServer\server`.
   That folder should now contain `FXServer.exe`.
3. Double-click `FXServer.exe` once. It starts **txAdmin**, the built-in
   admin panel, and prints a PIN/link for your browser. Open it and
   finish the setup: it creates a server-data folder for you (default
   resources included — the shop's chat messages need the default
   `chat` resource, and txAdmin's setup guarantees it's there) and asks
   for a server name and a Cfx.re license key (free from the FiveM
   keymaster, tied to your Cfx account).

When txAdmin is done you'll have something like:

```
C:\FXServer\server\        <- the program (FXServer.exe)
C:\FXServer\server-data\   <- YOUR server: server.cfg + resources\
```

## 2. Install the resource

1. Copy this repo's `resources/shops` folder into the server's
   resources folder:

   ```
   server-data\resources\shops\
       fxmanifest.lua
       config.lua
       server.lua
       client.lua
   ```

   The folder name **is** the resource name: it must stay `shops`.
2. Open `server-data\server.cfg` and add one line with the other
   `ensure` lines:

   ```
   ensure shops
   ```

   (txAdmin's recipe already has `ensure chat` etc. — leave those.)

## 3. Start it and read the console

Start the server from txAdmin (or run `FXServer.exe` in the server
folder). A healthy start prints, in the server console:

```
[shops] Glizzys Depot stocked to 80%.
[shops] Tanaz-tummy Express stocked to 80%.
[shops] Bushido Supply stocked to 80%.
[shops] Tanaz Ammo stocked to 80%.
[shops] started. One city hour = 60s; auto-restock every 4 city hours.
```

No `[shops]` lines = the resource didn't start (see Troubleshooting).
While the server runs, the server console also accepts: `restocknow`
(force the 80% restock) and `restart shops` (reload the resource
after editing a file — no full server restart needed).

## 4. Connect and test

1. Launch FiveM (the game client), press **F8**, type
   `connect localhost:30120`, Enter.
2. Run the checklist — each step proves one system:

   | Step | Command / action | Expected |
   |---|---|---|
   | Far buy refused | `/buyammo pistolAmmo 20` right after spawning | "You need to be at Tanaz Ammo to buy from it." |
   | Locate | `/whereami` | names the nearest shop + distance |
   | Travel | drive to the **Tanaz Ammo** blip (orange gun icon, Ammu-Nation, east LS) | blip is on your map from `config.lua` |
   | Confirm arrival | `/whereami` | "You are at Tanaz Ammo." |
   | Real buy | `/buyammo pistolAmmo 20` | "Bought 20 x Pistol Rounds for 20 gold at Tanaz Ammo. Gold: 5980" |
   | Wallet | `/wallet` | gold + owned ammo counts |
   | Armour counter | drive to the **Bushido Supply** blip (Little Seoul Ammu-Nation), `/buyarmor lowArmor` | "Bought 1 x Low Armour Vest (25 protection) for 200 gold at Bushido Supply. Gold: 5780" |
   | **The menu** | stand at the Tanaz blip, press **E** (or `/shop`) | a shop window opens — prices, live stock, your gold. Buy 20 pistol rounds *in the window*: gold and stock update in the window itself. Esc closes it |
   | Food counters | drive to **Glizzys Depot**, press **E**, buy 2 Glizzy Dogs in the window (or `/buyfood glizzyDog 2`) | gold −100; `/wallet` shows them under Food. Tummy Express sells beans + energy drinks the same way |
   | Timer | wait ~4 minutes, watch the server console | auto-restock fires on its own |

Every new player starts with a 6000-gold wallet. Since Lesson 18,
wallets and stock are saved to `data.json` inside the `shops`
resource folder and reload at boot — restarts no longer wipe the
world. (First ever boot prints `[shops] no save file yet - fresh
start.`; later boots print `[shops] save loaded: ...`. Deleting
`data.json` resets the world to day one.)

## 5. Make it yours (the knobs)

| What | Where | Notes |
|---|---|---|
| Shop locations | `resources/shops/config.lua` → `Config.Vendors` | Stand in-game where a shop should be, run `/coords`, paste the numbers in. Blip, `/whereami`, and the server's range check all follow. |
| Buy range | `config.lua` → `Config.BuyRange` | 5.0 metres. Bigger = more forgiving doorways. |
| Tick speed | `server.lua` → `TICK_MS` | 60000 = one city hour per real minute, set short so you can watch demand + restock work. A live server wants much longer. |
| Restock rule | `server.lua` → `RESTOCK_PERCENT` / `RESTOCK_EVERY` | 80%, every 4 city hours. |
| Stock sizes | `server.lua` → `VendorCapacity` | Per vendor, per item shelf capacity. |
| City demand | `server.lua` → `Demand` | Units sold per city hour per item. |
| Starting gold | `server.lua` → `getWallet` | 6000. |

After editing a file: `restart shops` in the server console.

## 6. Troubleshooting

- **Resource not found / no `[shops]` lines** — the folder isn't at
  `server-data\resources\shops`, the folder got renamed, or the
  `ensure shops` line is missing from `server.cfg`.
- **Script error mentioning `fxmanifest`** — a typo in a file name
  inside `fxmanifest.lua`; the manifest's script lists must match
  the real files exactly (`config.lua`, `server.lua`, `client.lua`).
- **Buys work but no chat messages appear** — the default `chat`
  resource isn't running. `ensure chat` in `server.cfg` (txAdmin
  setups include it by default).
- **"You need to be at..." while standing in the shop** — you're
  outside the 5m range of the config coords, or the shop moved.
  Check with `/whereami`, adjust coords with `/coords`, or widen
  `Config.BuyRange`.
- **Lua version errors (`//`, integer division)** — the manifest
  sets `lua54 'yes'`; if you copy files into another resource,
  keep that line.

## Scope & safety notes

- This is a **local test server** setup. Wallets and stock persist
  in a plain `data.json` file (Lesson 18); there is no database
  yet, and a hard crash can lose the last few minutes of changes.
- Don't port-forward or advertise the server publicly at this stage:
  no framework (ESX/QBCore), no persistence, no admin hardening yet.
  Those are the next lessons, in that order.
