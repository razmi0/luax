local deep_merge = require("lib.luax.utils.deep_merge")
local sort_aliases = require("lib.luax.utils.sort_aliases")

---@param user_config PartialTranspilerConfig|nil
---@return TranspilerConfig
local function define_config(user_config)
    ---@type TranspilerConfig
    local defaults = {
        headers              = {
            transpiler_version = "0.0.1",
            licence            = "NO LICENCE",
            author             = "razmi0",
            repo_link          = "https://github.com/razmi0/luax",
        },
        luax_file_extension  = ".luax",
        render_function_name = "lx",
        render_function_path = "lib.luax.render",
        root                 = "src",
        build                = {
            out_dir = "build",
            no_emit = false,
            target_file_extension = ".lua",
        },
        plugins              = {},
        alias                = {}
    }

    local defined_config = deep_merge(defaults, user_config)
    -- aliases are sorted by specificity, a longer aliases
    -- means more specificity (avoid replacement overlap)
    defined_config.alias = sort_aliases(defined_config)
    return defined_config
end

return define_config
