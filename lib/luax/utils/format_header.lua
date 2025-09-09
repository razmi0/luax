local function format_header(comments)
    local acc = {}
    for _, comment in ipairs(comments) do
        acc[#acc + 1] = "-- " .. comment
    end
    acc[#acc + 1] = "\n"
    return table.concat(acc, "\n")
end

return format_header
