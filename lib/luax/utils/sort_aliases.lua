---@param config TranspilerConfig
local function sort_aliases(config)
    local ordered_aliases = {}
    for alias, path in pairs(config.alias) do
        ordered_aliases[#ordered_aliases + 1] = { alias = alias, path = path }
    end
    table.sort(ordered_aliases, function(a, b)
        return #a.alias > #b.alias
    end)
    return ordered_aliases
end

return sort_aliases
