data:extend(
    {
        -- runtime-per-user
        {name = "TH_verbose_station_names", type = "bool-setting", default_value = "true", setting_type = "runtime-per-user", order = "0100"},
        -- startup
        {name = "TH_station_poll_period", type = "int-setting", minimum_value = 60, default_value = 125, setting_type = "startup", order = "0100"}
    }
)
