--    (2) : luax embedded attributes in parser ? (have to)
--    (3) : transpiler plugins
--
local transpiler  = require("lib.luax.transpiler.transpile")
local to_ssg      = require("lib.luax.utils.to_ssg")
local user_config = require("lib.luax.luax-config")


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
---@field plugins TranspilerPlugin[]|nil    -- plugins array

---@class TranspilerPlugin
---@field before_parse fun(ctx : TranspilerContext)|nil
---@field before_emit fun(ctx : TranspilerContext)|nil
---@field after_emit fun(ctx : TranspilerContext)|nil
---@field name string


transpiler(user_config)

to_ssg({
    entry_path = "build.main",
    out_path = "index.html"
})
