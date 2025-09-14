--> luax -> hyperscript --> index.html

local function emit_props(attrs)
    if not attrs or #attrs == 0 then
        return "{}"
    end

    local parts = {}
    for _, attr in ipairs(attrs) do
        for k, v in pairs(attr) do
            if k:match("-") then k = string.format("[%q]", k) end
            if v.kind == "string" then
                parts[#parts + 1] = string.format('%s = %q', k, v.value)
            elseif v.kind == "expr" then
                parts[#parts + 1] = string.format('%s = %s', k, v.value)
            elseif v.kind == "bool" then
                parts[#parts + 1] = string.format('%q', k)
            end
        end
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
end

--- take the ast and translate to lx functions stringified ready to be writed somewhere
--- element: h("tag", {...props...}, { ...children... })
---@param config TranspilerConfig
local function emit(node, config)
    local render_f_name = config.render_function_name

    local function emit_children(nodes)
        local children = {}
        for _, child in ipairs(nodes or {}) do
            children[#children + 1] = emit(child, config)
        end
        return #children > 0 and "{ " .. table.concat(children, ", ") .. " }" or "{}"
    end

    if node.tag then
        local lx_call = render_f_name
        if node.tag:match("^[A-Z]") then        -- Uppercase or not ?
            lx_call = lx_call .. '(%s, %s, %s)' -- function
        else
            lx_call = lx_call .. '(%q, %s, %s)' -- string
        end
        return string.format(
            lx_call,
            node.tag,
            emit_props(node.attrs),
            emit_children(node.children)
        )
    elseif node.text then
        --
        local txt = node.text:gsub("[\n\t\b]", ""):gsub("^%s*(.-)%s*$", "%1") -- trim
        return string.format("%q", txt)
    elseif node.expr then
        -- node.expr is a list of nodes (lua/text/element)
        local parts = {}
        for _, part in ipairs(node.expr) do
            parts[#parts + 1] = emit(part, config)
        end
        return table.concat(parts)
    elseif node.lua then
        return node.lua
    elseif node.fragment then
        return string.format(
            render_f_name .. "(%s, %s, %s)",
            "nil",
            "{}",
            emit_children(node.children)
        )
    end
end

return emit
