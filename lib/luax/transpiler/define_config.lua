---@class TranspilerConfig
---@field headers HeaderTranspilerConfig
---@field luax_file_extension string
---@field build { out_dir : string, no_emit : boolean, target_file_extension : string }
---@field root string                       -- path to luax files
---@field render_function_name string       -- the render function name
---@field render_function_path string       -- path to the render function
---@field plugins TranspilerPlugin[]|nil    -- plugins array

---@class PartialTranspilerConfig
---@field root string|nil
---@field build { out_dir : string|nil, no_emit : boolean|nil, target_file_extension : string|nil }| nil -- path to transpiled directory
---@field render_function_name string|nil
---@field render_function_path string|nil
---@field plugins TranspilerPlugin[]|nil

---@class HeaderTranspilerConfig
---@field transpiler_version string
---@field licence string
---@field author string
---@field repo_link string

---@class TranspilerPlugin
---@field before_parse fun(ctx : TranspilerContext)|nil
---@field before_emit fun(ctx : TranspilerContext)|nil
---@field after_emit fun(ctx : TranspilerContext)|nil
---@field name string

local function deep_merge(partial, extended)
    local merged = {}
    for k, v in pairs(partial) do
        merged[k] = v
    end
    for k, v in pairs(extended) do
        if type(v) == "table" and type(merged[k]) == "table" then
            merged[k] = deep_merge(merged[k], v)
        else
            merged[k] = v
        end
    end
    return merged
end


---@param user_config PartialTranspilerConfig
---@return TranspilerConfig
return function(user_config)
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
        render_function_path = "lib.luax.transpiler.luax",
        root                 = "src",
        build                = {
            out_dir = "build",
            no_emit = false,
            target_file_extension = ".lua",
        },
        plugins              = {}
    }

    local defined_config = deep_merge(defaults, user_config)
    -- print(require("inspect")(defined_config))
    return defined_config
end
