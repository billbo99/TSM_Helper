data:extend({
    -- Map Setting
    -- { name = "TH_verbose_station_names", type = "bool-setting", default_value = "true", setting_type = "runtime-global", order = "0100" },
    {
        type = "string-setting",
        name = "TH-train-stop",
        setting_type = "runtime-global",
        allow_blank = true,
        default_value = "Load @1 @2 (@3)",
        order = "za"
    },
    {
        type = "string-setting",
        name = "TH-subscriber-train-stop",
        setting_type = "runtime-global",
        allow_blank = true,
        default_value = "Supply @1 @2 (@3)",
        order = "zb"
    },
    {
        type = "string-setting",
        name = "TH-publisher-train-stop",
        setting_type = "runtime-global",
        allow_blank = true,
        default_value = "Request @1 @2 (@3)",
        order = "zc"
    },
    {
        type = "string-setting",
        name = "TH-outpost-train-stop",
        setting_type = "runtime-global",
        allow_blank = true,
        default_value = "Outpost @1 @2 (@3)",
        order = "zd"
    },
})
