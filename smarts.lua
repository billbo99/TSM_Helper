local lib = require("lib")
local Smarts = {} ---@class Smarts

Smarts.valid_train_stops = { "outpost-train-stop", "publisher-train-stop", "subscriber-train-stop", "train-stop" }

---@param station LuaEntity
function Smarts.AddStationToPriorities(station, green_name, red_name)
    local tsm_priorities = nil -- remote.call("TSM-API", "list_priorities", station.surface.name)
    if pcall(
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
                remote.call("TSM-API", "append_station", green_name, red_name, { station.backer_name }, station.surface.name)
                station.force.print(string.format("%s was automatically added to TSM priority", station.backer_name))
            end
        end
    elseif not tsm_priorities[green_name] or (tsm_priorities[green_name] and not tsm_priorities[green_name][red_name]) then
        remote.call("TSM-API", "define_new_priority", green_name, red_name, { station.backer_name }, station.surface.name)
        station.force.print(string.format("%s was automatically created as a new TSM priority", station.backer_name))
    end

    local TCS_table = { rb_or = true, inc_ef = true, empty = true, full = false, inactivity = true, inact_int = 5, wait_timer = false, wait_int = 30 }
    local TCS_flag = false
    local signals = station.get_merged_signals()
    for _, row in pairs(signals) do
        local count = row.count ---@cast count uint
        if row.signal and row.signal.type == "virtual" and lib.starts_with(row.signal.name, "TCS_") then
            local sn = row.signal.name
            if sn == "TCS_StationLimit" and count > 0 then
                station.trains_limit = count
            end
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
        remote.call("TSM-API", "update_wc", green_name, red_name, TCS_table, station.surface.name)
    end
end

---@param station LuaEntity
function Smarts.RenameStation(station)
    local red_signal, green_signal, red_icon, green_icon, green_text, red_text, red_name, green_name

    local cb = station.get_or_create_control_behavior()
    if cb.get_circuit_network(defines.wire_type.red) then
        local red_wire = cb.get_circuit_network(defines.wire_type.red).signals
        if red_wire then
            for _, cell in pairs(red_wire) do
                if cell.signal and cell.signal.name == "TCS_StationLimit" and cell.count > 0 then
                    station.trains_limit = cell.count
                end
                if cell.signal and (not lib.starts_with(cell.signal.name, "TCS_")) then
                    red_signal = cell.signal
                    red_name = red_signal.name
                    red_icon = lib.parse_signal_to_rich_text(red_signal)
                    red_text = lib.find_name_in_flib_dictonary(red_signal.name, red_signal.type) or red_name
                end
            end
        end
    end
    if cb.get_circuit_network(defines.wire_type.green) then
        local green_wire = cb.get_circuit_network(defines.wire_type.green).signals
        if green_wire then
            for _, cell in pairs(green_wire) do
                if cell.signal and cell.signal.name == "TCS_StationLimit" and cell.count > 0 then
                    station.trains_limit = cell.count
                end
                if cell.signal and (not lib.starts_with(cell.signal.name, "TCS_")) then
                    green_signal = cell.signal
                    green_name = green_signal.name
                    green_icon = lib.parse_signal_to_rich_text(green_signal)
                    green_text = lib.find_name_in_flib_dictonary(green_signal.name, green_signal.type) or green_name
                end
            end
        end
    end

    if green_icon or red_icon then
        if settings.global["TH_verbose_station_names"].value == false then
            green_text = nil
            red_text = nil
        end

        local station_prefix
        if station.name == "subscriber-train-stop" then
            station_prefix = "Supply"
        elseif station.name == "publisher-train-stop" then
            station_prefix = "Request"
        elseif station.name == "outpost-train-stop" then
            station_prefix = "Outpost"
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

        if station.name == "train-stop" or station.name == "publisher-train-stop" or station.name == "outpost-train-stop" then
            local station_names = {}
            local stations = station.surface.find_entities_filtered({ name = { "train-stop", "publisher-train-stop", "outpost-train-stop" } })
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
            Smarts.AddStationToPriorities(station, green_name, red_name)
        end
    end
end

---@param event EventData.on_entity_renamed
function Smarts.OnEntityRenamed(event)
    if event.by_script then return end
    if event.entity and event.entity.valid then
        local name = event.entity.name
        if lib.contains(Smarts.valid_train_stops, name) then
            Smarts.RenameStation(event.entity)
        end
    end
end

---@param event EventData.on_player_rotated_entity
function Smarts.OnPlayerRotatedEntity(event)
    if event.entity and event.entity.valid then
        local name = event.entity.name
        if lib.contains(Smarts.valid_train_stops, name) then
            Smarts.RenameStation(event.entity)
        end
    end
end

return Smarts
