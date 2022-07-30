local event = require("__flib__.event")
local dictionary = require("__flib__.dictionary")
local migration = require("__flib__.migration")
local Smarts = require("smarts")

---@alias Player_dictionaries table<int, Item_types>
---@alias Item_types table<string, Item_names>
---@alias Item_names table<string, string>

local function init_globals()
    global.player_dictionaries = global.player_dictionaries or {} ---@type Player_dictionaries
end

local function create_dictionaries()
    for _, type in pairs { "entity", "fluid", "item", "recipe", "technology", "tile", "virtual_signal" } do
        -- If the object's name doesn't have a translation, use its internal name as the translation
        local Names = dictionary.new(type, true)
        for name, prototype in pairs(game[type .. "_prototypes"]) do
            Names:add(name, prototype.localised_name)
        end
    end
end

local function OnInit()
    init_globals()
    dictionary.init()
    create_dictionaries()
end

---@param e ConfigurationChangedData
local function OnConfigurationChanged(e)
    init_globals()
    if migration.on_config_changed(e, {}) then
        -- Reset the module to effectively cancel all ongoing translations and wipe all dictionaries
        dictionary.init()
        create_dictionaries()

        -- Request translations for all connected players
        for _, player in pairs(game.players) do
            if player.connected then
                dictionary.translate(player)
            end
        end
    end
end

---@param e EventData.on_player_created
local function OnPlayerCreated(e)
    local player = game.get_player(e.player_index)
    -- Only translate if they're connected - if they're not, then it will not work!
    if player.connected then
        dictionary.translate(player)
    end
end

---@param e EventData.on_player_joined_game
local function OnPlayerJoinedGame(e)
    dictionary.translate(game.get_player(e.player_index))
end

---@param e EventData.on_player_left_game
local function OnPlayerLeftGame(e)
    dictionary.cancel_translation(e.player_index)
end

---@param e EventData.on_string_translated
local function on_string_translated(e)
    local language_data = dictionary.process_translation(e)
    if language_data then
        for _, player_index in pairs(language_data.players) do
            global.player_dictionaries[player_index] = language_data.dictionaries
        end
    end
end

event.on_init(OnInit)
event.on_configuration_changed(OnConfigurationChanged)

event.on_player_joined_game(OnPlayerJoinedGame)
event.on_player_left_game(OnPlayerLeftGame)
event.on_player_created(OnPlayerCreated)
event.on_string_translated(on_string_translated)

event.register(defines.events.on_entity_renamed, Smarts.OnEntityRenamed)
event.register(defines.events.on_player_rotated_entity, Smarts.OnPlayerRotatedEntity)
