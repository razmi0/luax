--
local uv = require("luv") -- hyperfine : lib uv > lfs
local fs = require("lib.fs").new(uv)
local lpeg = require("lpeg")
local inspect = require("inspect")
local P, R, S, V, C, Ct, Cg = lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.C, lpeg.Ct, lpeg.Cg
--
local SRC_PATH = "src"
local BUILD_PATH = "build"
local TRANSPILED_FILE_EXTENSION = ".luax"
--
local function transpile(content)
    local space     = S(" \t\r\n") ^ 0
    local name      = R("az", "AZ", "09") ^ 1
    local lua_chunk = Ct((V("LuaChunk") + V("Element")) ^ 0)

    local G         = P {
        "Chunk",

        Chunk    = lua_chunk,

        LuaChunk = C((1 - P("<")) ^ 1) / function(code)
            return { lua = code }
        end,

        Element  = P("<") * C(name) * P(">")
            * Ct((V("Element") + V("Expr") + V("Text")) ^ 0)
            * P("</") * V("CloseTag") * P(">")
            / function(tag, children, close)
                assert(tag == close, "mismatched " .. tag .. "/" .. close)
                return { tag = tag, children = children }
            end,

        CloseTag = C(name),

        Expr     = P("{") * C((1 - P("}")) ^ 1) * P("}")
            / function(e) return { expr = e } end,

        Text     = C((1 - S("<{")) ^ 1)
            / function(t) return { text = t } end,
    }

    local ast       = lpeg.match(G, content)
    -- element: h("tag", {}, { children })
    local function explore(node)
        if node.tag then
            local children = {}
            for _, child in ipairs(node.children or {}) do
                children[#children + 1] = explore(child)
            end
            return string.format('h("%s", {}, { %s })', node.tag, table.concat(children, ", "))
        elseif node.text then
            local txt = node.text:gsub("[ \n]", "")
            return string.format("%q", txt)
        elseif node.expr then
            return node.expr
        elseif node.lua then
            return node.lua
        end
    end

    local out = {}
    for _, node in ipairs(ast) do
        out[#out + 1] = explore(node)
    end

    -- print(inspect(out))
    print(inspect(out))
    return out
end
--
if not fs:has_subdir(SRC_PATH) then return end
fs:create_dir(BUILD_PATH)
local files = fs:list_files(SRC_PATH)

for _, file in ipairs(files) do
    if file:sub(-5) == TRANSPILED_FILE_EXTENSION then
        local content = fs:read(SRC_PATH .. "/" .. file)
        local target_file_name = file:sub(1, #file - 1)
        local transpiled = transpile(content)
        fs:write(BUILD_PATH .. "/" .. target_file_name, transpiled)
    end
end


uv.run()

-- h(tag,props,children)


-- {
--     {
--         lua = '\nfunction Litteral()\n    local _var = "Hello world"\n    local _var2 = " world"\n    return (\n        '
--     },
--     {
--         tag = "div",
--         children = {
--             {
--                 expr = "_var .. _var2"
--             },
--             {
--                 text = "\n            "
--             },
--             {
--                 children = { {
--                     text = "HOhohO "
--                 },
--                     {
--                         expr = "_var2"
--                     }
--                 },
--                 tag = "div"
--             },
--             {
--                 text = "\n        "
--             }
--         },
--     },
--     {
--         lua = "\n        )\nend\n\n\n\n\n\n\n\n"
--     }
-- }


--#region components
-- function Loop()
--     local _var = {"Hello", "world"}
--     return (
--         <div>{_var.ipairs(function(i,w)
--             return <div>{w}</div>
--          end)}
--         </div>
--     )
-- end

-- function Parent(props)
--     return (
--         <div>{props.children}</div>
--     )
-- end

-- function Composed()
--     return (
--         <Parent>
--             <Litteral />
--             <Loop />
--         </Parent>
--     )
-- end
--#endregion
