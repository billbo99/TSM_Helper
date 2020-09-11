local Func = require("func")
local event = require("__flib__.event")
local translation = require("__flib__.translation")
local player_data = require("raiguard.player-data")
local global_data = require("raiguard.global-data")
local on_tick = require("raiguard.on-tick")

local function count_table(table_to_count)
    local count = 0
    for _ in pairs(table_to_count) do
        count = count + 1
    end
    return count
end

local function parse_signal_to_rich_text(signal_data)
    local text_type = signal_data.type
    if text_type == "virtual" then
        text_type = "virtual-signal"
    end

    return string.format("[img=%s/%s]", text_type, signal_data.name)
end

local function InitState()
    global.TrainStaionCounters = global.TrainStaionCounters or {}
    global.Queue = global.Queue or {}
    global.Trains = global.Trains or {}
    global.Stations = global.Stations or {}
    global.TrainStaions = global.TrainStaions or {}
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

local function ScheduleFutureJob(action)
    if global.Queue[game.tick + 10] == nil then
        global.Queue[game.tick + 10] = {}
    end
    table.insert(global.Queue[game.tick + 10], action)
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

local function RegisterEntity(entity)
    local vtype = nil
    if type(entity) == "table" then
        if type(rawget(entity, "__self")) == "userdata" and getmetatable(entity) == "private" then
            vtype = entity.object_name
        end
    end

    local rsp = {entity = entity}

    if vtype ~= "LuaTrain" and entity.backer_name then
        rsp.backer_name = entity.backer_name
    end

    return rsp
end

local function rescan(e, table_to_update, entity_type, entity_name)
    for _, surface in pairs(game.surfaces) do
        if entity_type == "train" then
            for _, train in pairs(surface.get_trains()) do
                table_to_update[train.id] = RegisterEntity(train)
            end
        else
            for _, entity in pairs(surface.find_entities_filtered({type = entity_type, name = entity_name})) do
                table_to_update[entity.unit_number] = RegisterEntity(entity)
            end
        end
    end
end

local function UpdateTrainStation(station)
    local updated_stations = {}
    local next = next
    if not global.Stations[station.backer_name] then
        global.Stations[station.backer_name] = {entities = {}, trains_using_station = {}}
    end
    global.Stations[station.backer_name].entities[station.unit_number] = station
    -- if next(global.Stations[station.backer_name].trains_using_station) == nil then
    if updated_stations[station.backer_name] == nil then
        updated_stations[station.backer_name] = true
        for _, train in pairs(station.get_train_stop_trains()) do
            global.Stations[station.backer_name].trains_using_station[train.id] = train
        end
        for idx, train in pairs(global.Stations[station.backer_name].trains_using_station) do
            if not train.valid then
                global.Stations[station.backer_name].trains_using_station[idx] = nil
            end
        end
    end
end

local function RescanTrainStations(e)
    rescan(e, global.TrainStaions, "train-stop")
    for _, row in pairs(global.TrainStaions) do
        for _, station in pairs(global.Stations) do
            for idx, entity in pairs(station.entities) do
                if not entity.valid then
                    station.entities[idx] = nil
                end
            end
        end
        UpdateTrainStation(row.entity)
    end
end

local function RescanTrains(e)
    rescan(e, global.Trains, "train")
end

local function UpdateTrainStaionCounter(entity)
    entity.operable = false
    for _, ccd in pairs(entity.circuit_connection_definitions) do
        if ccd.target_entity and ccd.target_entity.type == "train-stop" then
            local station_name = ccd.target_entity.backer_name
            local station = global.Stations[station_name]
            local cb = entity.get_control_behavior()
            global.TrainStaionCounters[entity.unit_number].signals = {
                {signal = {type = "virtual", name = "TH_TrainStaionCount"}, count = count_table(station.entities)},
                {signal = {type = "virtual", name = "TH_TrainCount"}, count = count_table(station.trains_using_station)}
            }

            -- No of stations with this name
            cb.set_signal(1, global.TrainStaionCounters[entity.unit_number].signals[1])
            -- No of trains using this station
            cb.set_signal(2, global.TrainStaionCounters[entity.unit_number].signals[2])
        end
    end
end

local function RescanTrainStaionCounters(e)
    rescan(e, global.TrainStaionCounters, "constant-combinator", "train-staion-counter")
    for _, row in pairs(global.TrainStaionCounters) do
        UpdateTrainStaionCounter(row.entity)
    end
end

local function perform_rescan(e)
    -- keep in order
    RescanTrainStations(e)
    RescanTrains(e)
    RescanTrainStaionCounters(e)
end

local function entity_built(entity, table_to_update)
    if entity and entity.valid then
        if entity.object_name == "LuaTrain" then
            table_to_update[entity.id] = RegisterEntity(entity)
        else
            table_to_update[entity.unit_number] = RegisterEntity(entity)
        end
    end
end

local function entity_removed(entity, table_to_update)
    if entity and entity.valid then
        if entity.object_name == "LuaTrain" and table_to_update[entity.id] then
            table_to_update[entity.id] = nil
        elseif table_to_update[entity.unit_number] then
            table_to_update[entity.unit_number] = nil
        end
    end
end

local function OnEntityRemoved(e)
    local flag = false
    local entity = e.created_entity or e.entity or e.destination or nil
    if entity and entity.valid then
        if entity.type == "train-stop" then
            entity_removed(entity, global.TrainStaions)
            flag = true
        elseif entity.type == "locomotive" or entity.type == "cargo-wagon" or entity.type == "fluid-wagon" or entity.type == "artillery-wagon" then
            if count_table(entity.train.carriages) == 1 and entity.train.carriages[1] == entity then
                -- last part of train
                entity_removed(entity.train, global.Trains)
                flag = true
            end
        elseif entity.type == "constant-combinator" and entity.name == "train-staion-counter" then
            entity_removed(entity, global.TrainStaionCounters)
            flag = true
        else
            log(entity.type)
        end
    end
    if flag then
        ScheduleFutureJob("perform_rescan")
    end
end

local function OnBuiltEntity(e)
    local flag = false
    local entity = e.created_entity or e.entity or e.destination or nil
    if entity and entity.valid then
        if entity.type == "train-stop" then
            entity_built(entity, global.TrainStaions)
            flag = true
        elseif entity.type == "locomotive" or entity.type == "cargo-wagon" or entity.type == "fluid-wagon" or entity.type == "artillery-wagon" then
            entity_built(entity.train, global.Trains)
            flag = true
        elseif entity.type == "constant-combinator" and entity.name == "train-staion-counter" then
            entity.operable = false
            entity_built(entity, global.TrainStaionCounters)
            flag = true
        else
            log(entity.type)
        end
    end
    if flag then
        perform_rescan(e)
    end
end

local function OnTrainScheduleChanged(e)
    for _, record in pairs(e.train.schedule.records) do
        if record.station and global.Stations[record.station] then
            for _, station in pairs(global.Stations[record.station].entities) do
                UpdateTrainStation(station)
            end
        end
    end
    RescanTrainStaionCounters(e)
end

local function OnStationPollPeriod(e)
    if global.TrainStaionCounters then
        for idx, row in pairs(global.TrainStaionCounters) do
            if row.entity.valid then
                if row.signals == nil then
                    UpdateTrainStaionCounter(row.entity)
                end
            else
                global.TrainStaionCounters[idx] = nil
            end
        end
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

        local station_prefix
        if station.name == "subscriber-train-stop" then
            station_prefix = "Supply"
        else
            station_prefix = "Load"
        end

        local station_backer_name
        if (green_icon and (red_icon == green_icon or not red_icon)) or (red_icon and (red_icon == green_icon or not green_icon)) then
            local text = green_text or red_text or nil
            local icon = green_icon or red_icon
            if text then
                station_backer_name = station_prefix .. " " .. icon .. " (" .. text .. ")"
            else
                station_backer_name = station_prefix .. " " .. icon
            end
        elseif green_icon and red_icon and red_icon ~= green_icon then
            if green_text then
                station_backer_name = station_prefix .. " " .. green_icon .. red_icon .. " (" .. green_text .. ")"
            else
                station_backer_name = station_prefix .. " " .. green_icon .. red_icon
            end
        end

        if station.name == "train-stop" then
            local station_names = {}
            local stations = station.surface.find_entities_filtered({name = "train-stop"})
            for _, train_stop in pairs(stations) do
                station_names[train_stop.backer_name] = true
            end

            local index = 1
            while station_names[station_backer_name .. " " .. tostring(index)] do
                index = index + 1
            end
            station_backer_name = station_backer_name .. " " .. tostring(index)
        end

        station.backer_name = station_backer_name

        if station and station.valid and station.name == "subscriber-train-stop" and (green_name or red_name) then
            AddStationToPriorities(station, green_name, red_name)
        end
    end
end

local function CheckForWork(e)
    for scheduled_tick, jobs in pairs(global.Queue) do
        if scheduled_tick < e.tick then
            for _, job in pairs(jobs) do
                if job == "perform_rescan" then
                    perform_rescan(e)
                end
            end
            global.Queue[scheduled_tick] = nil
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

local function OnConfigurationChanged(e)
    InitState()
    translation.init()
    on_tick.update()
    perform_rescan()

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
    if (e.entity.name ~= "subscriber-train-stop" and e.entity.name ~= "train-stop") or e.by_script then
        return
    end

    ScheduleFutureJob("perform_rescan")

    local player = nil
    if e.player_index then
        player = game.players[e.player_index]
    end
    RenameStation(e.entity, player)
end

local function OnPlayerRotatedEntity(e)
    if e.entity and (e.entity.name == "subscriber-train-stop" or e.entity.name == "train-stop") then
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
    if e.player_index then
        if translation.is_translating(e.player_index) then
            translation.cancel(e.player_index)
        end
    end
end

event.on_init(OnStartup)
event.on_load(OnLoad)
event.on_nth_tick(20, CheckForWork)
event.on_nth_tick(settings.startup["TH_station_poll_period"].value, OnStationPollPeriod)
event.on_configuration_changed(OnConfigurationChanged)
event.on_string_translated(OnStringTranslated)
event.on_entity_renamed(OnEntityRenamed)
event.on_player_joined_game(OnPlayerJoinedGame)
event.on_player_left_game(OnPlayerLeftGame)
event.on_player_created(OnPlayerCreated)
event.on_player_rotated_entity(OnPlayerRotatedEntity)

local filters = {
    {filter = "type", type = "constant-combinator", name = "train-staion-counter"},
    {filter = "type", type = "locomotive"},
    {filter = "type", type = "cargo-wagon"},
    {filter = "type", type = "fluid-wagon"},
    {filter = "type", type = "artillery-wagon"},
    {filter = "type", type = "train-stop"}
}

script.on_event(defines.events.on_built_entity, OnBuiltEntity, filters)
script.on_event(defines.events.on_entity_cloned, OnBuiltEntity, filters)
script.on_event(defines.events.on_robot_built_entity, OnBuiltEntity, filters)
script.on_event(defines.events.script_raised_built, OnBuiltEntity, filters)
script.on_event(defines.events.script_raised_revive, OnBuiltEntity, filters)
script.on_event(defines.events.on_entity_died, OnEntityRemoved, filters)
script.on_event(defines.events.on_player_mined_entity, OnEntityRemoved, filters)
script.on_event(defines.events.on_robot_mined_entity, OnEntityRemoved, filters)
script.on_event(defines.events.script_raised_destroy, OnEntityRemoved, filters)

script.on_event(defines.events.on_chunk_deleted, perform_rescan)
script.on_event(defines.events.on_surface_cleared, perform_rescan)
script.on_event(defines.events.on_surface_deleted, perform_rescan)

-- script.on_event(defines.events.on_train_created, OnTrainCreated)
script.on_event(defines.events.on_train_schedule_changed, OnTrainScheduleChanged)

commands.add_command("th_rescan", "Forces a rescan of enties TSM Helper is monitoring", perform_rescan)
