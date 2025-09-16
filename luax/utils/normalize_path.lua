local function normalize_path(_p)
    local tmp_path = _p:match("^(.-)%.?l?u?a?$")
    return tmp_path:gsub("%.", "/"):gsub("^%/+", "")
end

return normalize_path
