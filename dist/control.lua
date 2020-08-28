local Func = require("func")
local event = require("__flib__.event")
local translation = require("__flib__.translation")
local player_data = require("raiguard.player-data")
local global_data = require("raiguard.global-data")
local on_tick = require("raiguard.on-tick")

local function parse_signal_to_rich_text(signal_data)
    local text_type = signal_data.type
    if text_type == "virtual" then
        text_type = "virtual-signal"
    end

    return string.format("[img=%s/%s]", text_type, signal_data.name)
end

local function InitState()
    global.SupplyStations = global.SupplyStations or {}
    global.entityTranslations = global.entityTranslations or {}

    for _, surface in pairs(game.surfaces) do
        local stations = surface.find_entities_filtered({name = "subscriber-train-stop"})
        for _, station in pairs(stations) do
            if not global.SupplyStations[station.unit_number] then
                global.SupplyStations[station.unit_number] = {entity = station, renamed = false}
            end
        end
    end
end

local function OnStringTranslated(e)
    local names, finished = translation.process_result(e)
    if names then
        local player_table = global.players[e.player_index]
        local translations = player_table.translations
        local internal_names
        if names.items then
            internal_names = names.items
        elseif names.fluids then
            internal_names = names.fluids
        elseif names.virtual_signals then
            internal_names = names.virtual_signals
        end

        for i = 1, #internal_names do
            local internal_name = internal_names[i]
            translations[internal_name] = e.translated and e.result or internal_name
            global.entityTranslations[internal_name] = e.translated and e.result or internal_name
        end
    end
    if finished then
        local player_table = global.players[e.player_index]
        player_table.flags.translate_on_join = false
        player_table.flags.show_message_after_translation = false
    end
end

local function AddStationToPriorities(station, green_name, red_name)
    local tsm_priorities = nil -- remote.call("TSM-API", "list_priorities", station.surface.name)
    if
        pcall(
            function()
                remote.call("TSM-API", "list_priorities", station.surface.name)
            end
        )
     then
        tsm_priorities = remote.call("TSM-API", "list_priorities", station.surface.name)
    else
        tsm_priorities = {}
    end

    if green_name and not red_name then
        red_name = green_name
    elseif red_name and not green_name then
        green_name = red_name
    elseif not green_name and not red_name then
        return
    end

    if tsm_priorities[green_name] and tsm_priorities[green_name][red_name] then
        if tsm_priorities[green_name][red_name]["station"] then
            local flag = false
            for _, station_data in pairs(tsm_priorities[green_name][red_name]["station"]) do
                for _, v in pairs(station_data) do
                    if v == station.backer_name then
                        flag = true
                    end
                end
            end
            if not flag then
                remote.call("TSM-API", "append_station", green_name, red_name, {station.backer_name}, station.surface.name)
                station.force.print(string.format("%s was automatically added to TSM priority", station.backer_name))
            end
        end
    elseif not tsm_priorities[green_name] or (tsm_priorities[green_name] and not tsm_priorities[green_name][red_name]) then
        remote.call("TSM-API", "define_new_priority", green_name, red_name, {station.backer_name}, station.surface.name)
        station.force.print(string.format("%s was automatically created as a new TSM priority", station.backer_name))
    end

    local TCS_table = {rb_or = true, inc_ef = true, empty = true, full = false, inactivity = true, inact_int = 5, wait_timer = false, wait_int = 30}
    local TCS_flag = false
    local signals = station.get_merged_signals()
    for _, row in pairs(signals) do
        local count = row.count
        if row.signal and row.signal.type == "virtual" and Func.starts_with(row.signal.name, "TCS_") then
            local sn = row.signal.name
            if sn == "TCS_AND" and count > 0 then
                TCS_table["rb_and"] = true
                TCS_table["rb_or"] = nil
                TCS_flag = true
            end
            if sn == "TCS_Wait_Until_Full" and count > 0 then
                TCS_table["full"] = true
                TCS_table["empty"] = false
                TCS_flag = true
            elseif sn == "TCS_Wait_Until_Full" and count < 0 then
                TCS_table["full"] = false
                TCS_flag = true
            end
            if sn == "TCS_Wait_Until_Empty" and count < 0 then
                TCS_table["empty"] = false
                TCS_flag = true
            end

            if sn == "TCS_Inactivity" and count > 0 then
                TCS_table["inactivity"] = true
                TCS_table["inact_int"] = count
                TCS_flag = true
            end
            if sn == "TCS_Wait_Timer" and count > 0 then
                TCS_table["wait_timer"] = true
                TCS_table["wait_int"] = count
                TCS_flag = true
            end
        end
        if not TCS_table["full"] and not TCS_table["empty"] then
            TCS_table["inc_ef"] = false
            TCS_flag = true
        end
    end
    if TCS_flag then
        station.force.print(serpent.block(TCS_table))
        remote.call("TSM-API", "update_wc", green_name, red_name, TCS_table, station.surface.name)
    end
end

local function RenameStation(station, player)
    local red_signal, green_signal, red_icon, green_icon, green_text, red_text, red_name, green_name

    local cb = station.get_or_create_control_behavior()
    if cb.get_circuit_network(defines.wire_type.red) then
        local red_wire = cb.get_circuit_network(defines.wire_type.red).signals
        if red_wire then
            for _, cell in pairs(red_wire) do
                if cell.signal and not Func.starts_with(cell.signal.name, "TCS_") then
                    red_signal = cell.signal
                    red_name = red_signal.name
                    red_icon = parse_signal_to_rich_text(red_signal)
                    red_text = global.entityTranslations[red_name] or red_name
                end
            end
        end
    end
    if cb.get_circuit_network(defines.wire_type.green) then
        local green_wire = cb.get_circuit_network(defines.wire_type.green).signals
        if green_wire then
            for _, cell in pairs(green_wire) do
                if cell.signal and not Func.starts_with(cell.signal.name, "TCS_") then
                    green_signal = cell.signal
                    green_name = green_signal.name
                    green_icon = parse_signal_to_rich_text(green_signal)
                    green_text = global.entityTranslations[green_name] or green_name
                end
            end
        end
    end

    if green_icon or red_icon then
        if player and not settings.get_player_settings(player)["TH_verbose_station_names"].value then
            green_text = nil
            red_text = nil
        end

        if (green_icon and (red_icon == green_icon or not red_icon)) or (red_icon and (red_icon == green_icon or not green_icon)) then
            local text = green_text or red_text or nil
            local icon = green_icon or red_icon
            if text then
                station.backer_name = "Supply " .. icon .. " (" .. text .. ")"
            else
                station.backer_name = "Supply " .. icon
            end
        elseif green_icon and red_icon and red_icon ~= green_icon then
            station.backer_name = "Supply " .. green_icon .. red_icon .. " (" .. green_text .. ")"
        end

        if station and station.valid and (green_name or red_name) then
            AddStationToPriorities(station, green_name, red_name)
        end
    end
end

local function OnStartup()
    translation.init()
    global_data.init()
    for i in pairs(game.players) do
        player_data.init(i)
    end
    InitState()
end

local function OnConfigurationChanged()
    InitState()
    translation.init()
    on_tick.update()

    global_data.build_prototypes()

    if game.players then
        if not global.players then
            global.players = {}
            for i, _ in pairs(game.players) do
                player_data.init(i, true)
            end
        end
        for i, player in pairs(game.players) do
            local player_table = global.players[i]
            player_data.refresh(player, player_table)
        end
    end
end

local function OnEntityRenamed(e)
    if e.entity.name ~= "subscriber-train-stop" or e.by_script then
        return
    end
    local player = nil
    if e.player_index then
        player = game.players[e.player_index]
    end
    RenameStation(e.entity, player)
end

local function OnPlayerRotatedEntity(e)
    if e.entity and e.entity.name == "subscriber-train-stop" then
        local player = nil
        if e.player_index then
            player = game.players[e.player_index]
        end
        RenameStation(e.entity, player)
    end
end

local function OnLoad()
    on_tick.update()
end

local function OnPlayerCreated(e)
    player_data.init(e.player_index)
end

local function OnPlayerJoinedGame(e)
    local player_table = global.players[e.player_index]
    if player_table.flags.translate_on_join then
        player_table.flags.translate_on_join = false
        player_data.start_translations(e.player_index)
    end
end

local function OnPlayerLeftGame(e)
    if translation.is_translating(e.player_index) then
        translation.cancel(event.player_index)
    end
end

event.on_init(OnStartup)
event.on_load(OnLoad)
-- event.on_nth_tick(60 * 60, OnNthTick)
event.on_configuration_changed(OnConfigurationChanged)
event.on_string_translated(OnStringTranslated)
event.on_entity_renamed(OnEntityRenamed)
event.on_player_joined_game(OnPlayerJoinedGame)
event.on_player_left_game(OnPlayerLeftGame)
event.on_player_created(OnPlayerCreated)
event.on_player_rotated_entity(OnPlayerRotatedEntity)
