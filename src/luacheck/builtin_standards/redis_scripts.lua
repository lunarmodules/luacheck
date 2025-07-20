local empty = {}

local redis_scripts = {
    fields = {
        ARGV = {
            other_fields = true,
        },
        KEYS = {
            other_fields = true,
        },
        redis = {
            fields = {
                breakpoint = empty,
                debug = empty,
            },
        }
    }
}

return redis_scripts
