local on_tick = {}

local event = require("__flib__.event")
local translation = require("__flib__.translation")

local function handler(e)
    if translation.translating_players_count() > 0 then
        translation.iterate_batch(e)
    else
        event.on_tick(nil)
    end
end

function on_tick.update()
    if global.__flib and translation.translating_players_count() > 0 then
        event.on_tick(handler)
    else
        event.on_tick(nil)
    end
end

return on_tick
