/*
 * This file is part of Renewed Village Growth, a GameScript for OpenTTD.
 * Credits keoz (Renewed City Growth), Sylf (City Growth Limiter), Firrel (Renewed Village Growth)
 *
 * It's free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the
 * Free Software Foundation, version 2 of the License.
 *
 */


require("version.nut");

class MainClass extends GSInfo
    {
    function GetAuthor()                { return "CallumClarke65"; }
    function GetName()                  { return "Growth Requires Networking"; }
    function GetShortName()             { return "GRNF"; }
    function GetDescription()           { return "Towns require various cargo deliveries to grow. Required cargos can be randomized. Town growth is limited by percentage of transported specific cargos. Supporting most Industry NewGRF sets."; }
    function GetURL()                   { return ""; }
    function GetVersion()               { return SELF_VERSION; }
    function GetDate()                  { return SELF_DATE; }
    function GetAPIVersion()            { return "15"; }
    function MinVersionToLoad()         { return SELF_MINLOADVERSION; }
    function CreateInstance()           { return "MainClass"; }
    function GetSettings() {

        AddSetting({ name = "town_info_mode",
                description = "Town info display mode",
                easy_value = 1,
                medium_value = 1,
                hard_value = 1,
                custom_value = 1,
                flags = CONFIG_INGAME, min_value = 1, max_value = 5 });
        AddLabels("town_info_mode", {
                    _1 = "Automatic",
                    _2 = "Category deliveries",
                    _3 = "Cargo list",
                    _4 = "Combined",
                    _5 = "Full cargo list" });

        AddSetting({ name = "goal_scale_factor",
                description = "Difficulty level (easy = 60, normal = 100, hard = 140)",
                easy_value = 60,
                medium_value = 100,
                hard_value = 140,
                custom_value = 100,
                flags = CONFIG_INGAME, min_value = 1, max_value = 50000, step_size = 20 });

        AddSetting({ name = "goal_per_thousand_pop",
                description = "Monthly cargo goal per thousand population (easy = 100, normal = 200, hard = 300)",
                easy_value = 100,
                medium_value = 200,
                hard_value = 300,
                custom_value = 200,
                flags = CONFIG_INGAME, min_value = 1, max_value = 50000, step_size = 20 });

        AddSetting({ name = "growth_rate",
                description = "Days between town growth cycles when growing is enabled (easy = 10, normal = 20, hard = 30)",
                easy_value = 10,
                medium_value = 20,
                hard_value = 30,
                custom_value = 20,
                flags = CONFIG_INGAME, min_value = 10, max_value = 30, step_size = 2 });

        AddSetting({ name = "growth_limit_0_cargos",
                description = "Max population allowed with 0 final product cargo types supplied (easy = 1000, normal = 500, hard = 250)",
                easy_value = 1000,
                medium_value = 500,
                hard_value = 250,
                custom_value = 500,
                flags = CONFIG_INGAME, min_value = -1, max_value = 50000, step_size = 100 });

        AddSetting({ name = "growth_limit_1_cargos",
                description = "Max population allowed with 1 final product cargo type supplied (easy = 1500, normal = 1000, hard = 500)",
                easy_value = 1500,
                medium_value = 1000,
                hard_value = 500,
                custom_value = 1000,
                flags = CONFIG_INGAME, min_value = -1, max_value = 50000, step_size = 100 });

        AddSetting({ name = "growth_limit_2_cargos",
                description = "Max population allowed with 2 final product cargo types supplied (easy = 3000, normal = 2000, hard = 800)",
                easy_value = 3000,
                medium_value = 2000,
                hard_value = 800,
                custom_value = 2000,
                flags = CONFIG_INGAME, min_value = -1, max_value = 50000, step_size = 100 });

        AddSetting({ name = "growth_limit_3_cargos",
                description = "Max population allowed with 3 final product cargo types supplied (easy = 10000, normal = 5000, hard = 2000)",
                easy_value = 10000,
                medium_value = 5000,
                hard_value = 2000,
                custom_value = 5000,
                flags = CONFIG_INGAME, min_value = -1, max_value = 50000, step_size = 100 });

        AddSetting({ name = "growth_limit_4_cargos",
                description = "Max population allowed with 4 final product cargo types supplied (easy = 20000, normal = 10000, hard = 5000, no limit = -1)",
                easy_value = 20000,
                medium_value = 10000,
                hard_value = 5000,
                custom_value = 10000,
                flags = CONFIG_INGAME, min_value = -1, max_value = 50000, step_size = 100 });

        AddSetting({ name = "use_town_sign",
                description = "Show growth rate text under town names",
                easy_value = 1,
                medium_value = 1,
                hard_value = 1,
                custom_value = 1,
                flags = CONFIG_BOOLEAN | CONFIG_INGAME });

        AddSetting({ name = "eternal_love",
                description = "Eternal love from towns",
                easy_value = 1,
                medium_value = 3,
                hard_value = 0,
                custom_value = 0,
                flags = CONFIG_INGAME, min_value = 0, max_value = 3 });
        AddLabels("eternal_love", { _0 = "Off",
                    _1 = "Outstanding",
                    _2 = "Good",
                    _3 = "Poor" });

        AddSetting({
            name = "limit_min_transport",
            description = "Limit Growth: Minimum percentage of transported cargo from town",
            easy_value = 40,
            medium_value = 50,
            hard_value = 65,
            custom_value = 50,
            flags = CONFIG_INGAME, min_value = 0, max_value = 100, step_size = 5});

        AddSetting({
            name = "town_size_threshold",
            description = "Limit Growth: Minimum size of town before the limit rules kicks in",
            easy_value = 800,
            medium_value = 550,
            hard_value = 350,
            custom_value = 350,
            flags = CONFIG_INGAME, min_value = 0, max_value = 50000, step_size = 25});

        AddSetting({
            name = "limiter_delay",
            description = "Limit Growth: Stop growth after set amount of months",
            easy_value = 3,
            medium_value = 1,
            hard_value = 0,
            custom_value = 1,
            flags = CONFIG_INGAME, min_value = 0, max_value = 12, step_size = 1});

        AddSetting({
            name = "subsidies_type",
            description = "Subsidies: Create subsidies for contributed towns",
            easy_value = 1,
            medium_value = 1,
            hard_value = 1,
            custom_value = 1,
            flags = CONFIG_INGAME, min_value = 0, max_value = 3});
        AddLabels("subsidies_type", {
                _0 = "None",
                _1 = "All",
                _2 = "Passenger",
                _3 = "Cargo"});

        AddSetting({
            name = "category_1_min_pop",
            description = "Category 1: Minimum population demand (-1 = default)",
            easy_value = -1,
            medium_value = -1,
            hard_value = -1,
            custom_value = -1,
            flags = CONFIG_INGAME, min_value = -1, max_value = 100000, step_size = 100});

        AddSetting({
            name = "category_2_min_pop",
            description = "Category 2: Minimum population demand (-1 = default)",
            easy_value = -1,
            medium_value = -1,
            hard_value = -1,
            custom_value = -1,
            flags = CONFIG_INGAME, min_value = -1, max_value = 100000, step_size = 100});

        AddSetting({
            name = "category_3_min_pop",
            description = "Category 3: Minimum population demand (-1 = default)",
            easy_value = -1,
            medium_value = -1,
            hard_value = -1,
            custom_value = -1,
            flags = CONFIG_INGAME, min_value = -1, max_value = 100000, step_size = 100});

        AddSetting({
            name = "category_4_min_pop",
            description = "Category 4: Minimum population demand (-1 = default)",
            easy_value = -1,
            medium_value = -1,
            hard_value = -1,
            custom_value = -1,
            flags = CONFIG_INGAME, min_value = -1, max_value = 100000, step_size = 100});

        AddSetting({
            name = "category_5_min_pop",
            description = "Category 5: Minimum population demand (-1 = default)",
            easy_value = -1,
            medium_value = -1,
            hard_value = -1,
            custom_value = -1,
            flags = CONFIG_INGAME, min_value = -1, max_value = 100000, step_size = 100});

        AddSetting({
            name = "category_6_min_pop",
            description = "Category 6: Minimum population demand (-1 = default)",
            easy_value = -1,
            medium_value = -1,
            hard_value = -1,
            custom_value = -1,
            flags = CONFIG_INGAME, min_value = -1, max_value = 100000, step_size = 100});

        AddSetting({ name = "town_growth_factor",
                description = "Expert: town growth factor",
                easy_value = 50,
                medium_value = 100,
                hard_value = 200,
                custom_value = 100,
                flags = CONFIG_INGAME, min_value = 20, max_value = 50000, step_size = 20 });

        AddSetting({ name = "supply_impacting_part",
                description = "Expert: minimum fulfilled percentage for TGR growth",
                easy_value = 30,
                medium_value = 50,
                hard_value = 70,
                custom_value = 50,
                flags = CONFIG_INGAME, min_value = 0, max_value = 100, step_size = 5 });

        AddSetting({ name = "exponentiality_factor",
                description = "Expert: TGR growth exponentiality factor",
                easy_value = 3,
                medium_value = 3,
                hard_value = 3,
                custom_value = 3,
                flags = CONFIG_INGAME, min_value = 1, max_value = 5 });

        AddSetting({ name = "lowest_town_growth_rate",
                description = "Expert: slowest TGR if requirements are not met",
                easy_value = 365,
                medium_value = 550,
                hard_value = 880,
                custom_value = 550,
                flags = CONFIG_INGAME, min_value = 0, max_value = 880, step_size = 10 });

        AddSetting({ name = "allow_0_days_growth",
                description = "Expert: allow 0 days growth",
                easy_value = 0,
                medium_value = 0,
                hard_value = 0,
                custom_value = 0,
                flags = CONFIG_BOOLEAN | CONFIG_INGAME});

        AddSetting({ name = "log_level",
                description = "Debug: Log level (higher = print more)",
                easy_value = 1,
                medium_value = 1,
                hard_value = 1,
                custom_value = 1,
                flags = CONFIG_INGAME, min_value = 1, max_value = 3 });
        AddLabels("log_level", { _1 = "1: Info", _2 = "2: Cargo", _3 = "3: Debug" });
    }
}

RegisterGS(MainClass());
