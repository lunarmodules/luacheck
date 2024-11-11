-- Luanti Lua API standard
-- API reference: https://github.com/minetest/minetest/blob/master/doc/lua_api.md
-- Changelog: https://dev.minetest.net/Changelog
-- Current version of this standard: 5.10.0
local standards = require "luacheck.standards"

local empty = {}
local read_write = {read_only = false}
local open_table = {read_only = false, other_fields = true}

-- main namespace
local core = {
    fields = {
        -- Utilities
        get_current_modname = empty,
        get_modpath = empty,
        get_modnames = empty,
        get_game_info = empty,
        get_worldpath = empty,
        is_singleplayer = empty,
        is_valid_player_name = empty,
        features = open_table,
        has_feature = empty,
        get_player_information = empty,
        get_player_window_information = empty,
        mkdir = empty,
        rmdir = empty,
        cpdir = empty,
        mvdir = empty,
        get_dir_list = empty,
        safe_file_write = empty,
        get_version = empty,
        sha1 = empty,
        colorspec_to_colorstring = empty,
        colorspec_to_bytes = empty,
        colorspec_to_table = empty,
        encode_png = empty,
        urlencode = empty,
        time_to_day_night_ratio = empty,

        -- Logging
        debug = empty,
        log = empty,

        -- Environment
        register_node = empty,
        register_craftitem = empty,
        register_tool = empty,
        override_item = empty,
        unregister_item = empty,
        register_entity = empty,
        register_abm = empty,
        register_lbm = empty,
        register_alias = empty,
        register_alias_force = empty,
        register_ore = empty,
        register_biome = empty,
        unregister_biome = empty,
        register_decoration = empty,
        register_schematic = empty,
        clear_registered_biomes = empty,
        clear_registered_decorations = empty,
        clear_registered_ores = empty,
        clear_registered_schematics = empty,

        -- Gameplay
        register_craft = empty,
        clear_craft = empty,
        register_chatcommand = empty,
        override_chatcommand = empty,
        unregister_chatcommand = empty,
        register_privilege = empty,
        register_authentication_handler = empty,

        -- Global callback registration functions
        register_globalstep = empty,
        register_on_mods_loaded = empty,
        register_on_shutdown = empty,
        register_on_placenode = empty,
        register_on_dignode = empty,
        register_on_punchnode = empty,
        register_on_generated = empty,
        register_on_newplayer = empty,
        register_on_punchplayer = empty,
        register_on_rightclickplayer = empty,
        register_on_player_hpchange = empty,
        register_on_dieplayer = empty,
        register_on_respawnplayer = empty,
        register_on_prejoinplayer = empty,
        register_on_joinplayer = empty,
        register_on_leaveplayer = empty,
        register_on_authplayer = empty,
        register_on_auth_fail = empty,
        register_on_cheat = empty,
        register_on_chat_message = empty,
        register_on_chatcommand = empty,
        register_on_player_receive_fields = empty,
        register_on_craft = empty,
        register_craft_predict = empty,
        register_allow_player_inventory_action = empty,
        register_on_player_inventory_action = empty,
        register_on_protection_violation = empty,
        register_on_item_eat = empty,
        register_on_item_pickup = empty,
        register_on_priv_grant = empty,
        register_on_priv_revoke = empty,
        register_can_bypass_userlimit = empty,
        register_on_modchannel_message = empty,
        register_on_liquid_transformed = empty,
        register_on_mapblocks_changed = empty,
        -- ... and corresponding callback tables
        registered_on_chat_messages = open_table,
        registered_on_chatcommands = open_table,
        registered_globalsteps = open_table,
        registered_on_mods_loaded = open_table,
        registered_on_shutdown = open_table,
        registered_on_punchnodes = open_table,
        registered_on_placenodes = open_table,
        registered_on_dignodes = open_table,
        registered_on_generateds = open_table,
        registered_on_newplayers = open_table,
        registered_on_dieplayers = open_table,
        registered_on_respawnplayers = open_table,
        registered_on_prejoinplayers = open_table,
        registered_on_joinplayers = open_table,
        registered_on_leaveplayers = open_table,
        registered_on_player_receive_fields = open_table,
        registered_on_cheats = open_table,
        registered_on_crafts = open_table,
        registered_craft_predicts = open_table,
        registered_on_protection_violation = open_table,
        registered_on_item_eats = open_table,
        registered_on_item_pickups = open_table,
        registered_on_punchplayers = open_table,
        registered_on_priv_grant = open_table,
        registered_on_priv_revoke = open_table,
        registered_on_authplayers = open_table,
        registered_can_bypass_userlimit = open_table,
        registered_on_modchannel_message = open_table,
        registered_on_player_inventory_actions = open_table,
        registered_allow_player_inventory_actions = open_table,
        registered_on_rightclickplayers = open_table,
        registered_on_liquid_transformed = open_table,
        registered_on_mapblocks_changed = open_table,

        -- Setting-related
        settings = standards.def_fields("get", "get_bool", "get_np_group", "get_flags", "set", "set_bool",
            "set_np_group", "remove", "get_names", "has", "write", "to_table"),
        setting_get_pos = empty,

        -- Authentication
        string_to_privs = empty,
        privs_to_string = empty,
        get_player_privs = empty,
        check_player_privs = empty,
        check_password_entry = empty,
        get_password_hash = empty,
        get_player_ip = empty,
        get_auth_handler = empty,
        notify_authentication_modified = empty,
        set_player_password = empty,
        set_player_privs = empty,
        change_player_privs = empty,
        auth_reload = empty,

        -- Chat
        chat_send_all = empty,
        chat_send_player = empty,
        format_chat_message = empty,

        -- Environment access
        set_node = empty,
        add_node = empty,
        bulk_set_node = empty,
        bulk_swap_node = empty,
        swap_node = empty,
        remove_node = empty,
        get_node = empty,
        get_node_or_nil = empty,
        get_node_light = empty,
        get_natural_light = empty,
        get_artificial_light = empty,
        place_node = empty,
        dig_node = empty,
        punch_node = empty,
        spawn_falling_node = empty,
        find_nodes_with_meta = empty,
        get_meta = empty,
        get_node_timer = empty,
        add_entity = empty,
        add_item = empty,
        get_player_by_name = empty,
        get_objects_inside_radius = empty,
        get_objects_in_area = empty,
        set_timeofday = empty,
        get_timeofday = empty,
        get_gametime = empty,
        get_day_count = empty,
        find_node_near = empty,
        find_nodes_in_area = empty,
        find_nodes_in_area_under_air = empty,
        get_perlin = empty,
        get_voxel_manip = empty,
        set_gen_notify = empty,
        get_gen_notify = empty,
        get_decoration_id = empty,
        get_mapgen_object = empty,
        get_heat = empty,
        get_humidity = empty,
        get_biome_data = empty,
        get_biome_id = empty,
        get_biome_name = empty,
        get_mapgen_params = empty,
        set_mapgen_params = empty,
        get_mapgen_edges = empty,
        get_mapgen_setting = empty,
        get_mapgen_setting_noiseparams = empty,
        set_mapgen_setting = empty,
        set_mapgen_setting_noiseparams = empty,
        set_noiseparams = empty,
        get_noiseparams = empty,
        generate_ores = empty,
        generate_decorations = empty,
        clear_objects = empty,
        load_area = empty,
        emerge_area = empty,
        delete_area = empty,
        line_of_sight = empty,
        raycast = empty,
        find_path = empty,
        spawn_tree = empty,
        transforming_liquid_add = empty,
        get_node_max_level = empty,
        get_node_level = empty,
        set_node_level = empty,
        add_node_level = empty,
        get_node_boxes = empty,
        fix_light = empty,
        check_single_for_falling = empty,
        check_for_falling = empty,
        get_spawn_level = empty,

        -- Mod channels
        mod_channel_join = empty,

        -- Inventory
        get_inventory = empty,
        create_detached_inventory = empty,
        remove_detached_inventory = empty,
        do_item_eat = empty,

        -- Formspec
        show_formspec = empty,
        close_formspec = empty,
        formspec_escape = empty,
        explode_table_event = empty,
        explode_textlist_event = empty,
        explode_scrollbar_event = empty,

        -- Item handling
        inventorycube = empty,
        get_pointed_thing_position = empty,
        dir_to_facedir = empty,
        facedir_to_dir = empty,
        dir_to_fourdir = empty,
        fourdir_to_dir = empty,
        dir_to_wallmounted = empty,
        wallmounted_to_dir = empty,
        dir_to_yaw = empty,
        yaw_to_dir = empty,
        is_colored_paramtype = empty,
        strip_param2_color = empty,
        get_node_drops = empty,
        get_craft_result = empty,
        get_craft_recipe = empty,
        get_all_craft_recipes = empty,
        handle_node_drops = empty,
        itemstring_with_palette = empty,
        itemstring_with_color = empty,

        -- Rollback
        rollback_get_node_actions = empty,
        rollback_revert_actions_by = empty,

        -- Defaults for the on_place and on_drop item definition functions
        item_place_node = empty,
        item_place_object = empty,
        item_place = empty,
        item_pickup = empty,
        item_drop = empty,
        item_eat = empty,

        -- Defaults for the on_punch and on_dig node definition callbacks
        node_punch = empty,
        node_dig = empty,

        -- Sounds
        sound_play = empty,
        sound_stop = empty,
        sound_fade = empty,

        -- Timing
        after = empty,

        -- Async environment
        handle_async = empty,
        register_async_dofile = empty,

        -- Server
        request_shutdown = empty,
        cancel_shutdown_requests = empty,
        get_server_status = empty,
        get_server_uptime = empty,
        get_server_max_lag = empty,
        remove_player = empty,
        remove_player_auth = empty,
        dynamic_add_media = empty,

        -- Bans
        get_ban_list = empty,
        get_ban_description = empty,
        ban_player = empty,
        unban_player_or_ip = empty,
        kick_player = empty,
        disconnect_player = empty,

        -- Particles
        add_particle = empty,
        add_particlespawner = empty,
        delete_particlespawner = empty,

        -- Schematics
        create_schematic = empty,
        place_schematic = empty,
        place_schematic_on_vmanip = empty,
        serialize_schematic = empty,
        read_schematic = empty,

        -- HTTP Requests
        request_http_api = empty,

        -- Storage API
        get_mod_storage = empty,

        -- Misc
        get_connected_players = empty,
        is_player = empty,
        player_exists = empty,
        hud_replace_builtin = empty,
        parse_relative_number = empty,
        send_join_message = empty,
        send_leave_message = empty,
        hash_node_position = empty,
        get_position_from_hash = empty,
        get_item_group = empty,
        get_node_group = empty,
        raillike_group = empty,
        get_content_id = empty,
        get_name_from_content_id = empty,
        parse_json = empty,
        write_json = empty,
        serialize = empty,
        deserialize = empty,
        compress = empty,
        decompress = empty,
        rgba = empty,
        encode_base64 = empty,
        decode_base64 = empty,
        is_protected = read_write,
        record_protection_violation = empty,
        is_creative_enabled = empty,
        is_area_protected = empty,
        rotate_and_place = empty,
        rotate_node = empty,
        calculate_knockback = empty,
        forceload_block = empty,
        forceload_free_block = empty,
        compare_block_status = empty,
        request_insecure_environment = empty,
        global_exists = empty,

        -- Error Handling
        error_handler = read_write,

        -- Helper functions
        wrap_text = empty,
        pos_to_string = empty,
        string_to_pos = empty,
        string_to_area = empty,
        is_yes = empty,
        is_nan = empty,
        get_us_time = empty,
        pointed_thing_to_face_pos = empty,
        get_tool_wear_after_use = empty,
        get_dig_params = empty,
        get_hit_params = empty,
        colorize = empty,

        -- Translations
        get_translator = empty,
        get_translated_string = empty,
        translate = empty,

        -- IPC
        ipc_set = empty,
        ipc_get = empty,
        ipc_cas = empty,
        ipc_poll = empty,

        -- Global tables
        registered_items = open_table,
        registered_nodes = open_table,
        registered_craftitems = open_table,
        registered_tools = open_table,
        registered_entities = open_table,
        object_refs = open_table,
        luaentities = open_table,
        registered_abms = open_table,
        registered_lbms = open_table,
        registered_aliases = open_table,
        registered_ores = open_table,
        registered_biomes = open_table,
        registered_decorations = open_table,
        registered_schematics = open_table,
        registered_chatcommands = open_table,
        registered_privileges = open_table,

        -- Constants (see: https://github.com/minetest/minetest/blob/master/builtin/game/constants.lua)
        CONTENT_UNKNOWN = empty,
        CONTENT_AIR = empty,
        CONTENT_IGNORE = empty,
        EMERGE_CANCELLED = empty,
        EMERGE_ERRORED = empty,
        EMERGE_FROM_MEMORY = empty,
        EMERGE_FROM_DISK = empty,
        EMERGE_GENERATED = empty,
        MAP_BLOCKSIZE = empty,
        PLAYER_MAX_HP_DEFAULT = empty,
        PLAYER_MAX_BREATH_DEFAULT = empty,
        LIGHT_MAX = empty
    }
}

-- Table additions
local table = standards.def_fields("copy", "indexof", "insert_all", "key_value_swap", "shuffle", "keyof")

-- String additions
local string = standards.def_fields("split", "trim")

-- Math additions
local math = standards.def_fields("hypot", "sign", "factorial", "round")

-- Bit library
local bit = standards.def_fields("tobit","tohex","bnot","band","bor","bxor","lshift","rshift","arshift","rol","ror",
    "bswap")

-- vector util
local vector = standards.def_fields("new", "zero", "copy", "from_string", "to_string", "direction", "distance",
    "length", "normalize", "floor", "round", "apply", "combine", "equals", "sort", "angle", "dot", "cross", "offset",
    "check", "in_area", "add", "subtract", "multiply", "divide", "rotate", "rotate_around_axis", "dir_to_rotation",
    "ceil", "sign", "abs", "random_in_area", "random_direction")

return {
    read_globals = {
        -- main namespace
        core = core,
        -- compatibility alias
        minetest = core,

        -- extensions
        table = table,
        math = math,
        bit = bit,
        string = string,

        -- Helper functions
        vector = vector,
        dump = empty,
        dump2 = empty,

        -- classes
        AreaStore = empty,
        ItemStack = empty,
        PerlinNoise = empty,
        PerlinNoiseMap = empty,
        PseudoRandom = empty,
        PcgRandom = empty,
        SecureRandom = empty,
        VoxelArea = open_table,
        VoxelManip = empty,
        Raycast = empty,
        Settings = empty,
    }
}
