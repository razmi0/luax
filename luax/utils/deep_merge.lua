local function deep_merge(partial, extended)
    local merged = {}
    for k, v in pairs(partial) do
        merged[k] = v
    end
    for k, v in pairs(extended) do
        if type(v) == "table" and type(merged[k]) == "table" then
            merged[k] = deep_merge(merged[k], v)
        else
            merged[k] = v
        end
    end
    return merged
end

return deep_merge
