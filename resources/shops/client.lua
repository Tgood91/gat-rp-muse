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
--   /buyammo pistolAmmo 20   -> bought, gold 5980
--   /wallet                  -> your gold + ammo counts
--   /buyammo plasmaCell 5    -> "No such ammo"
--   /buyammo shells12 9999   -> shelf refuses you
--   Wait ~4 minutes: the server console shows the timer
--   firing the 80% restock on its own. Or type
--   "restocknow" in the SERVER console to force it.
-- ============================================================
