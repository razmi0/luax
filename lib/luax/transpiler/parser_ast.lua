local lpeg              = require("lpeg")
--
local P, R, S, V, C, Ct = lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.C, lpeg.Ct
local NAME              = (R("az", "AZ", "09") + S(".")) ^ 1
local ATTRIBUTES        = (R("az", "AZ", "09") + S("-")) ^ 1
local SPACING           = S(" \t\r\n\f") ^ 0
--> Chunk --> Luachunk --> Element --> Element or Exprchunk
local GRAMMAR           = P {
    "Chunk",

    Chunk = Ct((V("LuaChunk") + V("Element")) ^ 0),

    LuaChunk = C((1 - S("<")) ^ 1) /
        function(code)
            return { lua = code }
        end,

    CloseTag = C(NAME),

    Element =
        ( -- allow co-working lua and html code expressions. Start with "<" and allow recursive Element/Expr
            P("<") * SPACING * C(NAME) * Ct(V("Attr") ^ 0) * SPACING * P(">")
            * Ct((V("Element") + V("Expr") + V("Text")) ^ 0)
            * P("</") * SPACING * V("CloseTag") * SPACING * P(">")
            / function(open_tag, attrs, children, close_tag)
                assert(open_tag == close_tag, "mismatched " .. open_tag .. "/" .. close_tag)
                return { tag = open_tag, children = children, attrs = attrs }
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

    LuaChunkExpr = C((1 - S("{}<")) ^ 1) /
        function(code)
            return {
                lua = code
            }
        end,

    Expr =
        P("{")
        * Ct((V("LuaChunkExpr") + V("Element")) ^ 0)
        * P("}") / function(parts)
            return {
                expr = parts
            }
        end,

    Text = C((1 - S("<{")) ^ 1) / function(t)
        return {
            text = t
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
}

local function parse(content)
    local ast = lpeg.match(GRAMMAR, content)
    -- print(require("inspect")(ast))
    return ast
end

return parse
