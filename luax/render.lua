local function eval(v)
    return type(v) == "function" and v() or v
end

local function render_props(props)
    if not props then return "" end
    local acc = {}
    for k, v in pairs(props) do
        v = eval(v)
        acc[#acc + 1] = string.format('%s=%q', k, v)
    end
    return #acc > 0 and (" " .. table.concat(acc, " ")) or ""
end

local function render_children(children)
    if not children then return "" end
    local acc = {}
    for _, child in ipairs(children) do
        if type(child) == "table" then
            -- flatten nested arrays
            for _, c in ipairs(child) do
                c = eval(c)
                if c ~= nil and c ~= false then
                    acc[#acc + 1] = tostring(c)
                end
            end
        else
            child = eval(child)
            if child ~= nil and child ~= false then
                acc[#acc + 1] = tostring(child)
            end
        end
    end
    return table.concat(acc)
end

local function __Luax(tag, props, children)
    if type(tag) == "string" then
        local props_str = render_props(props)
        local children_str = render_children(children)
        return string.format("<%s%s>%s</%s>", tag, props_str, children_str, tag)
    elseif type(tag) == "function" then
        props = props or {}
        props.children = children
        return tag(props)
    else
        -- fragment (tag is nil)
        local children_str = render_children(children)
        return string.format("%s", children_str)
    end
end

return __Luax
