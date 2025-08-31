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
local function emit(node, RENDER_FUNCTION_NAME)
    local function emit_children(nodes)
        local children = {}
        for _, child in ipairs(nodes or {}) do
            children[#children + 1] = emit(child, RENDER_FUNCTION_NAME)
        end
        return #children > 0 and "{ " .. table.concat(children, ", ") .. " }" or "{}"
    end

    if node.tag then
        local lx_call = RENDER_FUNCTION_NAME
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
            parts[#parts + 1] = emit(part, RENDER_FUNCTION_NAME)
        end
        return table.concat(parts)
    elseif node.lua then
        return node.lua
    elseif node.fragment then
        return string.format(
            "lx(%s, %s, %s)",
            "nil",
            "{}",
            emit_children(node.children)
        )
    else
        print("Unexpected in AST : node is type {}")
    end
end

return emit
