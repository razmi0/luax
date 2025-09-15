--    (2) : luax embedded attributes in parser ? (have to)
--    (3) : allow comments in luax ( do not strip them ? feature in config ?)
--    (4) : allow literal array expressions in parser
--    (5) : add line/col information if parser crash
--    (6) : implement path alias ( done)
--    (7) : no config first (done)

--
local transpile     = require("luax.transpiler.transpile")
local define_config = require("luax.transpiler.define_config")
--

---@return PartialTranspilerConfig
local function load_config()
    local ok, cfg = pcall(require, "luaxconfig")
    if ok then
        return cfg
    end
    print("\27[38;5;208m[Warn] No configuration file found\27[0m: luaxconfig.lua")
    return {}
end

transpile(define_config(load_config()))
