local base = "__base__/graphics/icons/"
local mod = "__TSM_Helper__/graphics/icons/"

data:extend(
    {
        {
            type = "item-subgroup",
            name = "TrainCircuitScheduler",
            group = "signals",
            order = "zTrainCircuitScheduler"
        }
    }
)

data:extend(
    {
        -- {
        --     type = "virtual-signal",
        --     name = "TCS_Remove_Schedule",
        --     icons = {
        --         {icon = mod .. "blank64.png", icon_size = 64},
        --         {icon = mod .. "train-stop.png", icon_size = 64},
        --         {icon = mod .. "minus.png", icon_size = 64, scale = 0.25, shift = {4, 4}}
        --     },
        --     subgroup = "TrainCircuitScheduler",
        --     order = "aa"
        -- },
        -- {
        --     type = "virtual-signal",
        --     name = "TCS_Add_Schedule",
        --     icons = {
        --         {icon = mod .. "blank64.png", icon_size = 64},
        --         {icon = mod .. "train-stop.png", icon_size = 64},
        --         {icon = mod .. "add.png", icon_size = 64, scale = 0.25, shift = {4, 4}}
        --     },
        --     subgroup = "TrainCircuitScheduler",
        --     order = "ab"
        -- },
        -- {
        --     type = "virtual-signal",
        --     name = "TCS_Clear_All_Schedules",
        --     icons = {
        --         {icon = mod .. "blank64.png", icon_size = 64},
        --         {icon = mod .. "train-stop.png", icon_size = 64},
        --         {icon = mod .. "trash-white.png", icon_size = 32, scale = 0.5, shift = {4, 4}}
        --     },
        --     subgroup = "TrainCircuitScheduler",
        --     order = "ac"
        -- },
        {
            type = "virtual-signal",
            name = "TCS_Wait_Until_Empty",
            icons = {
                {icon = mod .. "blank64.png", icon_size = 64},
                {icon = mod .. "train-stop.png", icon_size = 64},
                {icon = mod .. "empty.png", icon_size = 32, scale = 0.5, shift = {4, 4}}
            },
            subgroup = "TrainCircuitScheduler",
            order = "ba"
        },
        {
            type = "virtual-signal",
            name = "TCS_Wait_Until_Full",
            icons = {
                {icon = mod .. "blank64.png", icon_size = 64},
                {icon = mod .. "train-stop.png", icon_size = 64},
                {icon = mod .. "full.png", icon_size = 32, scale = 0.5, shift = {4, 4}}
            },
            subgroup = "TrainCircuitScheduler",
            order = "bb"
        },
        {
            type = "virtual-signal",
            name = "TCS_Inactivity",
            icons = {
                {icon = mod .. "blank64.png", icon_size = 64},
                {icon = mod .. "train-stop.png", icon_size = 64},
                {icon = mod .. "signal_I.png", icon_size = 64, icon_mipmaps = 4, scale = 0.25, shift = {4, 4}}
            },
            subgroup = "TrainCircuitScheduler",
            order = "ca"
        },
        {
            type = "virtual-signal",
            name = "TCS_Wait_Timer",
            icons = {
                {icon = mod .. "blank64.png", icon_size = 64},
                {icon = mod .. "train-stop.png", icon_size = 64},
                {icon = mod .. "signal_W.png", icon_size = 64, icon_mipmaps = 4, scale = 0.25, shift = {4, 4}}
            },
            subgroup = "TrainCircuitScheduler",
            order = "cb"
        },
        -- {
        --     type = "virtual-signal",
        --     name = "TCS_Wait_Circuit",
        --     icons = {
        --         {icon = mod .. "blank64.png", icon_size = 64},
        --         {icon = mod .. "train-stop.png", icon_size = 64},
        --         {icon = mod .. "red-wire.png", icon_size = 64, icon_mipmaps = 4, scale = 0.25, shift = {4, 4}}
        --     },
        --     subgroup = "TrainCircuitScheduler",
        --     order = "cc"
        -- },
        {
            type = "virtual-signal",
            name = "TCS_AND",
            icons = {
                {icon = mod .. "blank64.png", icon_size = 64},
                {icon = mod .. "train-stop.png", icon_size = 64},
                {icon = mod .. "and_white.png", icon_size = 64, scale = 0.5, shift = {4, 4}}
            },
            subgroup = "TrainCircuitScheduler",
            order = "da"
        }
        -- {
        --     type = "virtual-signal",
        --     name = "TCS_or",
        --     icons = {
        --         {icon = mod .. "blank64.png", icon_size = 64},
        --         {icon = mod .. "train-stop.png", icon_size = 64},
        --         {icon = mod .. "or_white.png", icon_size = 64, scale = 0.5, shift = {4, 4}}
        --     },
        --     subgroup = "TrainCircuitScheduler",
        --     order = "db"
        -- }
    }
)
