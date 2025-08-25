local function h(tag, props, children)
    if type(tag) == "string" then
        local acc = ""
        local acc_props = " "

        for k, v in pairs(props) do
            if type(v) == "function" then v = v() end
            acc_props = acc_props .. string.format("%s=%q ", k, v)
        end

        for _, child in ipairs(children) do
            if type(child) == "function" then child = child() end
            acc = acc .. child
        end

        return "<" .. tag .. acc_props:sub(1, #acc_props - 1) .. ">" .. acc .. "</" .. tag .. ">"
    end
end


return h
