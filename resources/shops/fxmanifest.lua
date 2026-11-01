-- ============================================================
-- LESSON 16: fxmanifest.lua — the resource's ID card.
-- FiveM reads THIS file first. No manifest, no resource:
-- the folder is invisible to the server. It declares what
-- the resource is and which scripts run where.
-- ============================================================
fx_version 'cerulean'
game 'gta5'

-- The lessons are written in Lua 5.4. This line turns 5.4
-- on for this resource (things like // integer division).
lua54 'yes'

author 'Tanner'
description 'Lessons 16-19: vendor shops as a FiveM resource — server-owned stock and wallets, Tanaz Ammo buys by command, 80% restock on a timer, real shop locations you must stand at, wallets + stock saved across restarts, Bushido Supply armour counter (low/medium/max).'
version '1.3.0'

-- Shared scripts load on BOTH sides: public data only
-- (Lesson 17's config.lua — shop locations live there).
shared_scripts {
    'config.lua',
}

-- Server scripts run ONCE, on the server, and own the
-- truth. Client scripts run on EVERY player's machine
-- and may only ask. That split is the whole lesson.
server_scripts {
    'server.lua',
}

client_scripts {
    'client.lua',
}
