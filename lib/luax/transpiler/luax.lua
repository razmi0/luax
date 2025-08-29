--> luax -> hyperscript --> index.html
local function Luax(tag, props, children)
    if type(tag) == "string" then
        local acc = ""
        local acc_props = " "

        for k, v in pairs(props) do
            if type(v) == "function" then v = v() end
            acc_props = acc_props .. string.format("%s=%q ", k, v)
        end

        for _, child in ipairs(children) do
            if type(child) == "table" then
                for _, c in ipairs(child) do
                    if type(c) == "function" then
                        acc = acc .. c()
                    elseif type(c) ~= "boolean" then
                        acc = acc .. c
                    end
                end
            else
                if type(child) == "function" then child = child() end
                acc = acc .. child
            end
        end

        return "<" .. tag .. acc_props:sub(1, #acc_props - 1) .. ">" .. acc .. "</" .. tag .. ">"
    elseif type(tag) == "function" then
        props.children = children
        return tag(props)
    end
end


return Luax
