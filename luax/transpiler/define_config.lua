local deep_merge = require("luax.utils.deep_merge")
local sort_aliases = require("luax.utils.sort_aliases")
local normalize_path = require("luax.utils.normalize_path")
local uv = require("luv")

local function resolve_render_path(path)
    local fd = uv.fs_open(path, "r", 438)
    if fd then
        uv.fs_close(fd)
        return path
    end

    local filepath = package.searchpath(path, package.path)
    if filepath then
        return normalize_path(filepath)
    end

    error("render.lua not found. Tried user path '" .. path .. "' and library path.")
end

---@param user_config PartialTranspilerConfig|nil
---@return TranspilerConfig
local function define_config(user_config)
    ---@type TranspilerConfig
    local defaults = {
        base                 = "",
        root                 = "src",
        luax_file_extension  = ".luax",       --
        render_function_name = "__lx__",      --
        render_function_path = "luax/render", --
        headers              = {
            enabled            = true,
            transpiler_version = "0.0.1",
            licence            = "NO LICENCE",
            author             = "razmi0",
            repo_link          = "https://github.com/razmi0/luax",
        }, --


        build   = {
            bundle = true,
            root_file = "main.lua",
            out_file = "_app.lua",
            out_dir = "build",
            no_emit = false,
            target_file_extension = ".lua",
            empty_out_dir = true,
            type = "none"
        },
        plugins = {},
        alias   = {}
    }

    local cfg = deep_merge(defaults, user_config)


    cfg.build.out_dir = cfg.base .. "/" .. cfg.build.out_dir
    cfg.root = cfg.base .. "/" .. cfg.root
    cfg.build.root_file = cfg.build.out_dir .. "/" .. cfg.build.root_file
    cfg.build.out_file = cfg.build.out_dir .. "/" .. cfg.build.out_file


    -- aliases are sorted by specificity (longer aliases)
    -- means more specificity (prevent aliases replacing each other)
    cfg.alias = sort_aliases(cfg)

    cfg.render_function_path = resolve_render_path(cfg.render_function_path)
    --
    return cfg
end

return define_config
