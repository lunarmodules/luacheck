local empty = {}

local redis = {
    fields = {
        redis = {
            fields = {
                call = empty,
                pcall = empty,
                error_reply = empty,
                status_reply = empty,
                sha1hex = empty,
                log = empty,
                set_repl = empty,
                replicate_commands = empty,
            },
        },

        cjson = {
            fields = {
                decode = empty,
                encode = empty,
            },
        },

        struct = {
            fields = {
                pack = empty,
                unpack = empty,
                size = empty,
            }
        },

        cmsgpack = {
            fields = {
                pack = empty,
                unpack = empty,
            }
        },

        bit = {
            fields = {
                tobit = empty,
                tohex = empty,
                bnot = empty,
                bor = empty,
                band = empty,
                bxor = empty,
                lshift = empty,
                rshift = empty,
                arshift = empty,
                rol = empty,
                ror = empty,
                bswap = empty,
            }
        }
    }
}

return redis
