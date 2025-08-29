--
local uv                   = require("luv") -- hyperfine : libUv > lib lfs
local to_ssg               = require("lib.luax.utils.to_ssg")
local transpile            = require("lib.luax.transpiler.transpile")
local RENDER_FUNCTION_NAME = "luax"
--
--> luax -> hyperscript --> index.html

transpile(uv, {
    SRC_PATH                    = "src",
    BUILD_PATH                  = "build",
    LUAX_FILE_EXTENSION         = ".luax",
    RENDER_FUNCTION_NAME        = RENDER_FUNCTION_NAME,
    H_PRAGMA                    = "---@transpile " .. RENDER_FUNCTION_NAME,
    H_PREAMBLE                  = "local " .. RENDER_FUNCTION_NAME .. " = require(\"lib.luax.transpiler.luax\")\n",
    --
    LUAX_MAP_HELPER_PREAMBLE    = [[
local function map(tbl, func)
    local newTbl = {}
    for i, v in ipairs(tbl) do
        table.insert(newTbl, func(v, i, tbl))
    end
    return table.concat(newTbl)
end
]],
    LUAX_FILTER_HELPER_PREAMBLE = [[
local function filter(tbl, func)
    local newTbl = {}
    for i, v in ipairs(tbl) do
        if func(v, i, tbl) then
        table.insert(newTbl, v)
        end
    end
    return table.concat(newTbl)
end
]]
})

to_ssg({
    entry_path = "build.main",
    out_path = "index.html"
})

uv.run()
