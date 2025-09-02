--    (2) : luax embedded attributes in parser ? (have to)
--    (3) : tranpiler plugins
--
local to_ssg  = require("lib.luax.utils.to_ssg")
local plugins = require("lib.luax.transpiler.plugins")

---@class TranspilerConfig
---@field TRANSPILER_VERSION string
---@field LICENCE string
---@field AUTHOR string
---@field REPO_LINK string
---@field DATE string                   -- transpile time
---@field SRC_PATH string               -- path to luax files
---@field BUILD_PATH string             -- path to transpiled directory
---@field LUAX_FILE_EXTENSION string    -- extension use to detect luax files
---@field RENDER_FUNCTION_NAME string   -- the render function name
---@field RENDER_FUNCTION_PATH string   -- path to the render function
---@field TARGET_FILE_EXTENSION string  -- extension for transpiled files

require("lib.luax.transpiler.transpile")({
    TRANSPILER_VERSION    = "0.0.1",
    LICENCE               = "NO LICENCE",
    AUTHOR                = "razmi0",
    REPO_LINK             = "https://github.com/razmi0/luax",
    DATE                  = tostring(os.date("%Y-%m-%d %H:%M:%S")),
    SRC_PATH              = "src",
    BUILD_PATH            = "build",
    LUAX_FILE_EXTENSION   = ".luax",
    TARGET_FILE_EXTENSION = ".lua",
    RENDER_FUNCTION_NAME  = "lx",
    RENDER_FUNCTION_PATH  = "lib.luax.transpiler.luax",
})

to_ssg({
    entry_path = "build.main",
    out_path = "index.html"
})
