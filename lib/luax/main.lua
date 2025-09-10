--    (2) : luax embedded attributes in parser ? (have to)
--    (3) : allow comments in luax ( do not strip them ? feature in config ?)
--    (4) : allow literal array expressions in parser
--    (5) : add line/col information if parser crash
--    (6) : implement path alias ( done)
--    (7) : no config first (done)

--
local transpile          = require("lib.luax.transpiler.transpile")
local define_config      = require("lib.luax.transpiler.define_config")
--
local CONFIG_MODULE_PATH = "lib.luax.luax-config"
local _,
---@type PartialTranspilerConfig
user_config              = xpcall(function()
    return require(CONFIG_MODULE_PATH)
end, function()
    print("\27[38;5;208mNo configuration file found : \27[0m" .. CONFIG_MODULE_PATH)
end)
transpile(define_config(user_config or {}))
--
