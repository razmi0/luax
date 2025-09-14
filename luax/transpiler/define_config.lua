local deep_merge = require("luax.utils.deep_merge")
local sort_aliases = require("luax.utils.sort_aliases")




---@param user_config PartialTranspilerConfig|nil
---@return TranspilerConfig
local function define_config(user_config)
    local flags, globals, rm_paths = (function()
        local flag_map, globals, rm_paths = {}, {}, {}
        local on_flag_args = function(start, str, callback)
            local targets = {
                global = function(s)
                    return s:match("^%-%-globals?") or s:match("^%-%-G")
                end,
                rm_src = function(s)
                    return s:match("^%-%-remove%-source") or s:match("^%-%-R")
                end
            }
            for k, fn in pairs(targets) do
                if fn(str) then
                    for j = start + 1, #arg do
                        if not arg[j] then return j end
                        if arg[j]:match("^%-%-") then return j end
                        callback(k, arg[j])
                    end
                end
            end
        end
        for i = 1, #arg do
            if arg[i]:match("^%-%-.-") then
                flag_map[arg[i]] = true
            end
            on_flag_args(i, arg[i], function(type, _arg)
                if type == "global" then
                    globals[_arg] = true
                elseif type == "rm_src" then
                    rm_paths[#rm_paths + 1] = _arg
                end
            end)
        end
        return flag_map, globals, rm_paths
    end)()

    ---@type TranspilerConfig
    local defaults = {
        headers              = {
            enabled            = true,
            transpiler_version = "0.0.1",
            licence            = "NO LICENCE",
            author             = "razmi0",
            repo_link          = "https://github.com/razmi0/luax",
        },
        cmd                  = {
            flags = flags,
            globals = globals,
            rm_paths = rm_paths
        },
        luax_file_extension  = ".luax",
        render_function_name = "__lx__",
        render_function_path = "luax/transpiler/render",
        root                 = "src",
        build                = {
            bundle = true,
            root = "build/main.lua",
            out_file = "build/_app.lua",
            out_dir = "build",
            no_emit = false,
            target_file_extension = ".lua",
            empty_out_dir = true
        },
        plugins              = {},
        alias                = {}
    }

    local defined_config = deep_merge(defaults, user_config)

    -- aliases are sorted by specificity (longer aliases)
    -- means more specificity (prevent aliases replacing each other)
    defined_config.alias = sort_aliases(defined_config)
    return defined_config
end

return define_config
