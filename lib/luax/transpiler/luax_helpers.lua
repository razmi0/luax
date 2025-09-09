---@param fn_name "map"|"filter"
local function get_helper(fn_name)
    if fn_name == "map" then
        return [[
        local function map(tbl, func)
    local newTbl = {}
    for i, v in ipairs(tbl) do
        table.insert(newTbl, func(v, i, tbl))
    end
    return table.concat(newTbl)
end
        ]]
    elseif fn_name == "filter" then
        return [[
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
    end
end

return get_helper
