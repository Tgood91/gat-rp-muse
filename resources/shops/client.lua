-- ============================================================
-- LESSON 16: client.lua — THE CLIENT ONLY ASKS.
-- This file runs on EVERY player's own machine. It holds
-- no gold, no stock, no prices — a player can open and
-- edit their client files, so anything stored here could
-- be cheated. The client's whole job:
--   1. take the player's command,
--   2. send the ask to the server (TriggerServerEvent),
--   3. print whatever the server answers.
-- Check -> move -> report still happens — on the server.
-- ============================================================

-- Print a line in the chat box (the built-in chat
-- resource listens for this event). "[Shops]" is just
-- the name tag on the message.
function say(text)
    TriggerEvent('chat:addMessage', {
        args = { "[Shops]", text },
    })
end

-- ============================================================
-- LESSON 17: BLIPS + POSITION TOOLS.
-- One map blip per vendor, straight from the shared
-- config — change a spot in config.lua and the blip,
-- the /whereami answer, and the server's range check
-- all move together. One source, three readers.
-- ============================================================
for vendorKey, spot in pairs(Config.Vendors) do
    local blip = AddBlipForCoord(spot.coords.x, spot.coords.y, spot.coords.z)
    SetBlipSprite(blip, spot.blip)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, spot.blipColour)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(spot.label)
    EndTextCommandSetBlipName(blip)
end

-- Lesson 28: job spots get blips too — same recipe,
-- second table. A blip is just a signpost; the server
-- still decides whether you're really at work.
for jobKey, job in pairs(Config.Jobs) do
    local blip = AddBlipForCoord(job.coords.x, job.coords.y, job.coords.z)
    SetBlipSprite(blip, job.blip)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, job.blipColour)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(job.place)
    EndTextCommandSetBlipName(blip)
end

-- /whereami — the nearest shop, and whether you're in
-- range of it. Same distance math the server uses; here
-- it's just information, there it's the law.
RegisterCommand('whereami', function(source, args, raw)
    local me = GetEntityCoords(PlayerPedId())
    local nearestSpot, nearestDist = nil, nil
    for vendorKey, spot in pairs(Config.Vendors) do
        local dist = #(me - spot.coords)
        if nearestDist == nil or dist < nearestDist then
            nearestSpot, nearestDist = spot, dist
        end
    end
    if nearestDist <= Config.BuyRange then
        say("You are at " .. nearestSpot.label .. ".")
    else
        say("Nearest shop: " .. nearestSpot.label .. ", " ..
            string.format("%.0f", nearestDist) .. "m away.")
    end
end, false)

-- /coords — a dev tool: stand where a shop SHOULD be,
-- run this, and paste the numbers into config.lua.
RegisterCommand('coords', function(source, args, raw)
    local me = GetEntityCoords(PlayerPedId())
    say(string.format("Your coords: %.1f, %.1f, %.1f",
                      me.x, me.y, me.z))
end, false)

-- /buyammo pistolAmmo 20
-- Sends the RAW ask — item key and amount, nothing else.
-- Notice the client does NOT check gold or stock. It
-- can't know them, and if it "checked" and trusted the
-- result, a modded client would just always say yes.
-- Basic manners only: if the player typed nonsense,
-- show the usage line instead of bothering the server.
RegisterCommand('buyammo', function(source, args, raw)
    local ammoKey = args[1]
    local amount = tonumber(args[2])
    if ammoKey == nil or amount == nil then
        say("Usage: /buyammo <ammoKey> <amount>  e.g. /buyammo pistolAmmo 20")
    else
        TriggerServerEvent('shops:buyAmmo', ammoKey, amount)
    end
end, false)

-- /buyarmor lowArmor   (amount optional, default 1)
-- Bushido Supply's counter (Lesson 19). Same deal as
-- /buyammo: the client sends the raw ask — tier key and
-- amount — and the server checks the tier, the shelf,
-- your gold, and whether you're standing at Bushido.
RegisterCommand('buyarmor', function(source, args, raw)
    local armourKey = args[1]
    local amount = tonumber(args[2]) or 1
    if armourKey == nil then
        say("Usage: /buyarmor <lowArmor|mediumArmor|maxArmor> [amount]")
    else
        TriggerServerEvent('shops:buyArmour', armourKey, amount)
    end
end, false)

-- /wallet — ask the server what you've got.
RegisterCommand('wallet', function(source, args, raw)
    TriggerServerEvent('shops:getWallet')
end, false)

-- The server's answers land here. Whatever text arrives
-- is what the player sees — the server wrote it, after
-- doing the real checks and moves.
RegisterNetEvent('shops:result')
AddEventHandler('shops:result', function(message)
    say(message)
end)

RegisterNetEvent('shops:wallet')
AddEventHandler('shops:wallet', function(summary)
    say(summary)
end)

-- ============================================================
-- LESSON 20: THE MENU — a real shop window (NUI).
-- Stand at a shop, press E (or /shop): the client asks
-- the server for that shop's menu, the server builds it
-- (items, prices, live stock, YOUR gold — it owns all
-- of that), and the page in html/index.html draws it.
-- Clicks come back through RegisterNUICallback and are
-- forwarded as 'shops:buyItem' — landing in the SAME
-- server checks as the chat commands. The menu replaced
-- the typing; it did not replace the counters.
-- ============================================================
local menuOpen = false

RegisterNetEvent('shops:menu')
AddEventHandler('shops:menu', function(menu)
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', menu = menu })
end)

-- The page's Buy button lands here. The page sends what
-- was clicked; the client forwards it untouched — the
-- server will re-check every bit of it anyway.
RegisterNUICallback('buy', function(data, cb)
    if data.kind == 'fuel' then
        -- Fuel isn't bagged, it's pumped: the fuel flow
        -- (Lesson 27, below) reads the tank first.
        askFuel(tonumber(data.amount) or 1)
    else
        TriggerServerEvent('shops:buyItem', data.vendorKey,
                           data.kind, data.key, data.amount)
    end
    cb('ok')
end)

RegisterNUICallback('close', function(data, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- The shop you're standing at, if any. (Client-side
-- convenience only — the server re-checks for real.)
function nearestShopInRange()
    local me = GetEntityCoords(PlayerPedId())
    for vendorKey, spot in pairs(Config.Vendors) do
        if #(me - spot.coords) <= Config.BuyRange then
            return vendorKey, spot
        end
    end
    return nil, nil
end

function openShopMenu()
    local vendorKey = nearestShopInRange()
    if vendorKey == nil then
        say("No shop in range - stand at a shop blip.")
    else
        TriggerServerEvent('shops:getMenu', vendorKey)
    end
end

-- /shop — the command form of pressing E.
RegisterCommand('shop', function(source, args, raw)
    openShopMenu()
end, false)

-- /buyfood glizzyDog 2 — the chat form of the food
-- counters (Lesson 24). It buys from the shop you're
-- STANDING at, through the same shops:buyItem door as
-- the menu — the server re-checks that shop's sells
-- list, shelf, range, and your gold.
RegisterCommand('buyfood', function(source, args, raw)
    local foodKey = args[1]
    local amount = tonumber(args[2]) or 1
    if foodKey == nil then
        say("Usage: /buyfood <foodKey> [amount]  e.g. /buyfood glizzyDog 2")
        return
    end
    local vendorKey = nearestShopInRange()
    if vendorKey == nil then
        say("No shop in range - stand at a shop blip.")
    else
        TriggerServerEvent('shops:buyItem', vendorKey,
                           'food', foodKey, amount)
    end
end, false)

-- The E key: this thread watches where you stand. Near
-- a shop it shows the prompt, and E asks for the menu.
CreateThread(function()
    while true do
        Wait(0)
        if not menuOpen then
            local vendorKey, spot = nearestShopInRange()
            if spot ~= nil then
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName(
                    "Press E to open " .. spot.label)
                EndTextCommandDisplayHelp(0, false, true, -1)
                if IsControlJustReleased(0, 38) then  -- 38 = E
                    openShopMenu()
                end
            end
        end
    end
end)

-- ============================================================
-- LESSON 27: FUEL — ask, approval, THEN pour.
-- The tank lives here (only the client can read a
-- vehicle's fuel), so the ask carries the reading. The
-- server bounds it, checks the shelf and the gold, and
-- only on approval sends 'shops:fuelUp' — and only
-- THEN does this side pour. A modded client can lie
-- about its tank, but it can't pour unpaid fuel: the
-- pouring is gated on the server's yes.
-- ============================================================
function askFuel(amount)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        say("You need to be in a vehicle at the pumps.")
        return
    end
    local tank = math.floor(GetVehicleFuelLevel(veh))
    TriggerServerEvent('shops:buyFuel', amount, tank)
end

-- /buyfuel 30 — pump 30 units at Glizzys Depot.
RegisterCommand('buyfuel', function(source, args, raw)
    local amount = tonumber(args[1])
    if amount == nil then
        say("Usage: /buyfuel <amount>  e.g. /buyfuel 30")
    else
        askFuel(amount)
    end
end, false)

RegisterNetEvent('shops:fuelUp')
AddEventHandler('shops:fuelUp', function(amount)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        say("Paid for fuel but you're out of the vehicle - it's gone.")
        return
    end
    -- Re-read OUR tank and add what was bought, capped.
    local now = GetVehicleFuelLevel(veh)
    SetVehicleFuelLevel(veh, math.min(100.0, now + amount))
end)

-- ============================================================
-- LESSON 26: NEEDS — the client wears the body.
-- The server owns hunger/thirst and DECIDES any health
-- tax; this side APPLIES it, because your ped's health
-- lives on your machine. The latest levels also draw
-- as a small HUD line so you can watch yourself drain.
-- ============================================================
local lastNeeds = nil

RegisterNetEvent('shops:needs')
AddEventHandler('shops:needs', function(needs)
    lastNeeds = needs
    if needs.healthTax ~= nil and needs.healthTax > 0 then
        local ped = PlayerPedId()
        local hp = GetEntityHealth(ped)
        -- Floored at 101: hunger alone brings you to
        -- the brink, it doesn't finish you.
        SetEntityHealth(ped, math.max(101, hp - needs.healthTax))
    end
end)

-- /eat glizzyDog / /drink water — one event, the server
-- sorts out which verb it was.
RegisterCommand('eat', function(source, args, raw)
    if args[1] == nil then
        say("Usage: /eat <foodKey>  e.g. /eat glizzyDog")
    else
        TriggerServerEvent('shops:useFood', args[1])
    end
end, false)

RegisterCommand('drink', function(source, args, raw)
    if args[1] == nil then
        say("Usage: /drink <foodKey>  e.g. /drink water")
    else
        TriggerServerEvent('shops:useFood', args[1])
    end
end, false)

-- /needs — ask the server how you're doing.
RegisterCommand('needs', function(source, args, raw)
    TriggerServerEvent('shops:getNeeds')
end, false)

-- The HUD line: redrawn every frame once the server
-- has sent levels (after /needs, eating, or a tick).
CreateThread(function()
    while true do
        Wait(0)
        if lastNeeds ~= nil then
            SetTextFont(4)
            SetTextScale(0.42, 0.42)
            SetTextColour(232, 228, 216, 255)
            SetTextEntry('STRING')
            AddTextComponentString("Hunger: " .. lastNeeds.hunger ..
                                   "   Thirst: " .. lastNeeds.thirst)
            DrawText(0.015, 0.94)
        end
    end
end)

-- ============================================================
-- LESSON 28: JOBS — the client asks to work; the server
-- keeps the clock. /work mechanic at the LS Customs
-- blip starts a shift; /collect pays once it has run.
-- The client holds no timer and no pay it can spend —
-- the pay in Config.Jobs is sign-on-the-door data, and
-- the server re-reads its own copy when money moves.
-- ============================================================
RegisterCommand('work', function(source, args, raw)
    if args[1] == nil then
        say("Usage: /work <mechanic|taxi|delivery|policeOfficer|signSpinner|techMogul>")
    else
        TriggerServerEvent('shops:work', args[1])
    end
end, false)

RegisterCommand('collect', function(source, args, raw)
    TriggerServerEvent('shops:collect')
end, false)

-- ============================================================
-- TRY IT in game (server running, resource ensured):
--   THE MENU (Lesson 20): stand at any shop blip and
--   press E (or type /shop) — a window opens with the
--   shop's prices, live stock, and your gold. Buy from
--   the window and watch the numbers update in place.
--   Glizzys + Tummy Express sell FOOD (Lesson 24):
--   dogs + water at Glizzys, beans + energy drinks at
--   Tummy Express — in the menu, or /buyfood glizzyDog 2.
--   FUEL (Lesson 27): drive INTO Glizzys Depot in a
--   car and /buyfuel 30 (or use the menu's Fuel row) —
--   the sale approves, then the tank actually fills.
--   JOBS (Lesson 28): /work mechanic at the LS Customs
--   blip, wait out the shift, /collect there — +80
--   gold. Try /collect early: the server knows.
--   NEEDS (Lesson 26): /needs shows hunger + thirst;
--   they drain every city hour and a HUD line appears.
--   /eat glizzyDog / /drink water spend your pack —
--   and if a stat sits at zero, your health pays.
--   Right after spawning, far from any shop:
--   /buyammo pistolAmmo 20   -> refused: not AT the shop
--   /whereami                -> names the nearest one
--   Drive to the Tanaz Ammo blip (Ammu-Nation icon):
--   /whereami                -> "You are at Tanaz Ammo."
--   /buyammo pistolAmmo 20   -> bought, gold 5980
--   Drive to the Bushido Supply blip (Little Seoul):
--   /buyarmor lowArmor       -> Low Armour Vest, gold -200
--   /buyarmor maxArmor       -> the 100-protection vest
--   /buyarmor lowArmor       -> ...from Tanaz's doorstep
--      it refuses: wrong shop, you have to BE at Bushido
--   /wallet                  -> gold + ammo + armour
--   /coords                  -> your exact position:
--   stand in a doorway, run it, move the shop there
--   in config.lua, restart the resource, stand on
--   your new spot and buy again.
--   Wait ~4 minutes: the server console shows the timer
--   firing the 80% restock on its own. Or type
--   "restocknow" in the SERVER console to force it.
-- ============================================================
