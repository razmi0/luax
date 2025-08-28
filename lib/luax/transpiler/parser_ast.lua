local lpeg              = require("lpeg")
--
local P, R, S, V, C, Ct = lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.C, lpeg.Ct
local NAME              = R("az", "AZ", "09") ^ 1
local ATTRIBUTES        = (R("az", "AZ", "09") + S("-")) ^ 1
local SPACING           = S(" \t\r\n\f") ^ 0
local GRAMMAR           = P {
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

    Expr =
        P("{") * C((1 - P("}")) ^ 1) * P("}") / function(e)
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

local function parse(content)
    local ast = lpeg.match(GRAMMAR, content)
    -- print(require("inspect")(ast))
    return ast
end

return parse
