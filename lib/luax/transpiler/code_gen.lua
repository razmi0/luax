--> luax -> hyperscript --> index.html
local function emit(node, RENDER_FUNCTION_NAME)
    -- element: h("tag", {...props...}, { ...children... })
    local function emit_children(nodes)
        local children = {}
        for _, child in ipairs(nodes or {}) do
            children[#children + 1] = emit(child, RENDER_FUNCTION_NAME)
        end
        return #children > 0 and "{ " .. table.concat(children, ", ") .. " }" or "{}"
    end

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

    if node.tag then
        local tag = RENDER_FUNCTION_NAME
        if node.tag:match("^[A-Z]") then                 -- Uppercase or not ?
            tag = RENDER_FUNCTION_NAME .. '(%s, %s, %s)' -- node.tag .. "()"
        else
            tag = RENDER_FUNCTION_NAME .. '(%q, %s, %s)'
        end
        return string.format(
            tag,
            node.tag,
            emit_props(node.attrs),
            emit_children(node.children)
        )
    elseif node.text then
        --
        local txt = node.text:gsub("[\n\t\b]", ""):gsub("^%s*(.-)%s*$", "%1") -- trim
        return string.format("%q", txt)
    elseif node.expr then
        -- node.expr is now a list of nodes (lua/text/element)
        local parts = {}
        for _, part in ipairs(node.expr) do
            parts[#parts + 1] = emit(part, RENDER_FUNCTION_NAME)
        end
        return table.concat(parts)
    elseif node.lua then
        --
        return node.lua
    end
end

return emit
