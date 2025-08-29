--TODO(1) : add metadata for preambles in parser ?
--    (2) : luax embedded attributes in parser ?
--    (3) : add a way to add custom preambles in parser ?
--    (3) : explore /src/ recursively ?
--
local to_ssg    = require("lib.luax.utils.to_ssg")
local transpile = require("lib.luax.transpiler.transpile")
--
transpile({
    SRC_PATH              = "src",                      -- path to luax files
    BUILD_PATH            = "build",                    -- path to transpiled directory
    LUAX_FILE_EXTENSION   = ".luax",                    -- extension use to detect luax files
    TARGET_FILE_EXTENSION = ".lua",                     -- extension for transpiled files
    RENDER_FUNCTION_NAME  = "lx",                       -- the render function name
    RENDER_FUNCTION_PATH  = "lib.luax.transpiler.luax", -- path to the render function
})

to_ssg({
    entry_path = "build.main",
    out_path = "index.html"
})
