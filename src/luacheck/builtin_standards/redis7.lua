local empty = {}

local redis = {
    fields = {
        redis = {
            REDIS_VERSION = {},
            REDIS_VERSION_NUM = {},
            acl_check_cmd = empty,
            register_function = empty,
        }
    }
}

return redis
