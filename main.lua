--
local uv                   = require("luv") -- hyperfine : libUv > lib lfs
local fs                   = require("lib.fs").new(uv)
local lpeg                 = require("lpeg")
local inspect              = require("inspect")
--
local SRC_PATH             = "src"
local BUILD_PATH           = "build"
local LUAX_FILE_EXTENSION  = ".luax"
local HYPERSCRIPT_PREAMBLE = "local h = require(\"lib.hyperscript\")\n"
--
local P, R, S, V, C, Ct    = lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.C, lpeg.Ct
local NAME                 = R("az", "AZ", "09") ^ 1
local ATTRIBUTES           = (R("az", "AZ", "09") + S("-")) ^ 1
local SPACING              = S(" \t\r\n\f") ^ 0
local GRAMMAR              = P {
    "Chunk",

    Chunk = Ct((V("LuaChunk") + V("Element")) ^ 0),

    LuaChunk = C((1 - P("<")) ^ 1) /
        function(code)
            return {
                lua = code
            }
        end,

    Attr =
        ( -- string values
            SPACING * C(ATTRIBUTES) * SPACING * P("=") *
            SPACING * P("\"") * C((1 - P("\"")) ^ 0) * P("\"") /
            function(key, value)
                return {
                    [key] = {
                        kind = "string",
                        value = value
                    }
                }
            end
        )
        +
        ( -- expressions values
            SPACING * C(ATTRIBUTES) * SPACING * P("=") *
            SPACING * P("{") * SPACING * C((1 - P("}")) ^ 1) * SPACING * P("}") /
            function(key, expr)
                return {
                    [key] = {
                        kind = "expr",
                        value = expr
                    }
                }
            end
        )
        +
        ( -- boolean values
            SPACING * C(ATTRIBUTES) /
            function(value)
                return {
                    [value] = {
                        kind = "bool"
                    }
                }
            end
        ),

    Element =
        ( -- regular tags
            P("<") * SPACING * C(NAME) * Ct(V("Attr") ^ 0) * SPACING * P(">") *
            Ct((V("Element") + V("Expr") + V("Text")) ^ 0) *
            P("</") * SPACING * V("CloseTag") * SPACING * P(">") /
            function(open_tag, attrs, children, close_tag)
                assert(open_tag == close_tag, "mismatched " .. open_tag .. "/" .. close_tag)
                return {
                    tag = open_tag,
                    children = children,
                    attrs = attrs
                }
            end
        )
        +
        ( -- self-closing tags
            P("<") * SPACING * C(NAME) * Ct(V("Attr") ^ 0) * SPACING * P("/>") /
            function(tag, attrs)
                return {
                    tag = tag,
                    children = {},
                    attrs = attrs
                }
            end
        ),

    CloseTag = C(NAME),

    Expr = P("{") * C((1 - P("}")) ^ 1) * P("}") / function(e)
        return {
            expr = e
        }
    end,

    Text = C((1 - S("<{")) ^ 1) / function(t)
        return {
            text = t
        }
    end
}
--

local function emit_hyperscript(node)
    -- element: h("tag", {...props...}, { ...children... })
    local function emit_children(nodes)
        local children = {}
        for _, child in ipairs(nodes or {}) do
            children[#children + 1] = emit_hyperscript(child)
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
                if k:match("-") then
                    k = string.format("[%q]", k)
                end
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
        return string.format('h("%s", %s, %s)', node.tag, emit_props(node.attrs), emit_children(node.children))
    elseif node.text then
        local txt = node.text:gsub("[ \n\t\b]", "")
        return string.format("%q", txt)
    elseif node.expr then
        return node.expr
    elseif node.lua then
        return node.lua
    end
end

--
--
if not fs:has_subdir(SRC_PATH) then return end
fs:create_dir(BUILD_PATH)
local files = fs:list_files(SRC_PATH)
for _, file in ipairs(files) do
    if file:sub(-5) == LUAX_FILE_EXTENSION then
        local content = fs:read(SRC_PATH .. "/" .. file)
        local target_file_name = file:sub(1, #file - 1)
        local ast = lpeg.match(GRAMMAR, content)
        local emitted = { HYPERSCRIPT_PREAMBLE }
        for _, node in ipairs(ast) do
            emitted[#emitted + 1] = emit_hyperscript(node)
        end
        print(inspect(emitted))
        fs:write(BUILD_PATH .. "/" .. target_file_name, emitted)
    end
end
--
--
uv.run()
