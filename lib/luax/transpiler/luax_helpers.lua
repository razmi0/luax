local uv = require("luv")
local fs = require("lib.luax.utils.fs").new(uv)
local this_file_path = "/lib/luax/transpiler/luax_helpers.lua"


local function map(tbl, func)
    local newTbl = {}
    for i, v in ipairs(tbl) do
        table.insert(newTbl, func(v, i, tbl))
    end
    return table.concat(newTbl)
end

local function filter(tbl, func)
    local newTbl = {}
    for i, v in ipairs(tbl) do
        if func(v, i, tbl) then
            table.insert(newTbl, v)
        end
    end
    return table.concat(newTbl)
end

local this_content = fs:read(uv.cwd() .. this_file_path)

---@param fn_name "map"|"filter"
local function get_helper(fn_name)
    return this_content:match(
        "(function.-" ..
        fn_name ..
        ".-return.-end%s)"
    )
end

return get_helper
