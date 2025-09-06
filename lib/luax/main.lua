--    (2) : luax embedded attributes in parser ? (have to)
--    (3) : allow comments in luax
--
local transpiler  = require("lib.luax.transpiler.transpile")
local to_ssg      = require("lib.luax.utils.to_ssg")
local user_config = require("lib.luax.luax-config")

transpiler(user_config)

to_ssg({
    entry_path = "build.main",
    out_path = "index.html"
})
