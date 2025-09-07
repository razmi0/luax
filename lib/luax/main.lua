--    (2) : luax embedded attributes in parser ? (have to)
--    (3) : allow comments in luax ( do not strip them ? feature in config ?)
--    (4) : allow literal array expressions in parser
--    (5) : add line/col information if parser crash
--    (6) : implement path alias ( done)
--    (7) : no config first

--
local transpiler  = require("lib.luax.transpiler.transpile")
local to_ssg      = require("lib.luax.utils.to_ssg")
local user_config = require("lib.luax.luax-config")

transpiler(user_config)

to_ssg({
    entry_path = "build.main",
    out_path = "index.html"
})
