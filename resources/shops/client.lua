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
-- TRY IT in game (server running, resource ensured):
--   Right after spawning, far from any shop:
--   /buyammo pistolAmmo 20   -> refused: not AT the shop
--   /whereami                -> names the nearest one
--   Drive to the Tanaz Ammo blip (Ammu-Nation icon):
--   /whereami                -> "You are at Tanaz Ammo."
--   /buyammo pistolAmmo 20   -> bought, gold 5980
--   /wallet                  -> your gold + ammo counts
--   /coords                  -> your exact position:
--   stand in a doorway, run it, move the shop there
--   in config.lua, restart the resource, stand on
--   your new spot and buy again.
--   Wait ~4 minutes: the server console shows the timer
--   firing the 80% restock on its own. Or type
--   "restocknow" in the SERVER console to force it.
-- ============================================================
