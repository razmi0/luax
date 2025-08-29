local INTRO                       = "-- THIS CODE IS INJECTED BY LUAX TRANSPILER --\n"
local OUTRO                       = "-- THIS CODE IS INJECTED BY LUAX TRANSPILER --\n"

local LUAX_MAP_HELPER_PREAMBLE    = [[
local function map(tbl, func)
    local newTbl = {}
    for i, v in ipairs(tbl) do
        table.insert(newTbl, func(v, i, tbl))
    end
    return table.concat(newTbl)
end
]]

local LUAX_FILTER_HELPER_PREAMBLE = [[
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

local function render_function_preamble(RENDER_FUNCTION_NAME, RENDER_FUNCTION_PATH)
    return "local " .. RENDER_FUNCTION_NAME .. "= require(\"" .. RENDER_FUNCTION_PATH .. "\")\n"
end

---@class PreambleConfig
---@field has_map_helper boolean
---@field has_filter_helper boolean
---@field has_pragma boolean

---@param preambles PreambleConfig
local function compose(RENDER_FUNCTION_NAME, RENDER_FUNCTION_PATH, preambles, callback)
    local injected = { INTRO }
    if preambles.has_pragma then
        injected[#injected + 1] = render_function_preamble(RENDER_FUNCTION_NAME, RENDER_FUNCTION_PATH)
    end
    if preambles.has_map_helper then
        injected[#injected + 1] = LUAX_MAP_HELPER_PREAMBLE
    end
    if preambles.has_filter_helper then
        injected[#injected + 1] = LUAX_FILTER_HELPER_PREAMBLE
    end
    injected[#injected + 1] = OUTRO
    callback(injected)
    return injected
end

return compose
