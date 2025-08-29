--TODO(1) : add metadata for preambles in parser ?
--    (2) : luax embedded attributes in parser ?
--    (3) : add a way to add custom preambles in parser ?
--
local uv                   = require("luv")
local to_ssg               = require("lib.luax.utils.to_ssg")
local transpile            = require("lib.luax.transpiler.transpile")
--
local RENDER_FUNCTION_NAME = "luax"
--

transpile(uv, {
    SRC_PATH             = "src",
    BUILD_PATH           = "build",
    LUAX_FILE_EXTENSION  = ".luax",
    RENDER_FUNCTION_NAME = RENDER_FUNCTION_NAME,
    RENDER_FUNCTION_PATH = "lib.luax.transpiler.luax",
    H_PRAGMA             = "---@transpile " .. RENDER_FUNCTION_NAME,
})

to_ssg({
    entry_path = "build.main",
    out_path = "index.html"
})

uv.run()
