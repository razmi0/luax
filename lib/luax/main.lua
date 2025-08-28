--
local uv        = require("luv") -- hyperfine : libUv > lib lfs
local to_ssg    = require("lib.luax.utils.to_ssg")
local transpile = require("lib.luax.transpiler.transpile")
--

transpile(uv, { --> luax -> hyperscript
    SRC_PATH             = "src",
    BUILD_PATH           = "build",
    LUAX_FILE_EXTENSION  = ".luax",
    RENDER_FUNCTION_NAME = "luax",
    H_PRAGMA             = "---@transpile " .. "luax",
    H_PREAMBLE           = "local " .. "luax" .. " = require(\"lib.luax.transpiler.luax\")\n",
})

to_ssg({ --> hyperscript -> index.html
    entry_path = "build.main",
    out_path = "index.html"
})

uv.run()
