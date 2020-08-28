local global_data = {}

local constants = require("raiguard.constants")

function global_data.init()
    global.flags = {}
    global.players = {}

    global_data.build_prototypes()
end

function global_data.build_prototypes()
    local item_data = {}
    local fluid_data = {}
    local virtual_signal_data = {}
    local translation_data = {}
    for name, prototype in pairs(game.item_prototypes) do
        if not constants.ignored_item_types[prototype.type] then
            item_data[name] = {
                hidden = prototype.has_flag("hidden"),
                localised_name = prototype.localised_name,
                place_result = prototype.place_result or prototype.place_as_tile_result,
                stack_size = prototype.stack_size
            }
            translation_data[#translation_data + 1] = {dictionary = "items", localised = prototype.localised_name, internal = prototype.name}
        end
    end
    for name, prototype in pairs(game.fluid_prototypes) do
        fluid_data[name] = {
            hidden = prototype.hidden,
            localised_name = prototype.localised_name
        }
        translation_data[#translation_data + 1] = {dictionary = "fluids", localised = prototype.localised_name, internal = prototype.name}
    end
    for name, prototype in pairs(game.virtual_signal_prototypes) do
        virtual_signal_data[name] = {
            localised_name = prototype.localised_name
        }
        translation_data[#translation_data + 1] = {dictionary = "virtual_signals", localised = prototype.localised_name, internal = prototype.name}
    end
    global.item_data = item_data
    global.fluid_data = fluid_data
    global.virtual_signal_data = virtual_signal_data
    global.translation_data = translation_data
end

return global_data
