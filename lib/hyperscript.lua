local function h(tag, props, children)
    if type(tag) == "string" then
        local acc = ""
        local acc_props = ""

        for k, v in pairs(props) do
            if type(v) == "function" then
                v = v()
            end
            acc_props = acc_props .. string.format("%s=%q ", k, v)
        end

        for _, child in ipairs(children) do
            if type(child) == "function" then
                acc = acc .. child()
            else
                acc = acc .. child
            end
        end

        return "<" .. tag .. " " .. acc_props .. ">" .. acc .. "</" .. tag .. ">"
    end
end


return h
