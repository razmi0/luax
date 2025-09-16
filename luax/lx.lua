local __modules, __cache = {}, {} local function __require(name)     if __cache[name] then         return __cache[name]     end     local fn = __modules[name]     if not fn then         local ok, external_fn = pcall(require, name)         if not ok then             error("[38;5;196m[Error]External library not found[0m : " .. name)         end         __cache[name] = external_fn         return external_fn     end     local res = fn()     __cache[name] = res     return res end
__modules["luax/transpiler/parser"] = function()
local lpeg = __require("lpeg")
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
        ( -- fragment
            P("<") * SPACING * P(">") *
            Ct((V("Element") + V("Expr") + V("Text")) ^ 0) *
            P("<") * SPACING * P("/") * SPACING * P(">")
            / function(children)
                return { fragment = true, children = children, attrs = {} }
            end
        )
        +
        ( -- allow co-working lua and html code expressions. Start with "<" and allow recursive Element/Expr like jsx
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
                return { tag = tag, children = {}, attrs = attrs }
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


--- Parser
---@param ctx TranspilerContext
local function parse(ctx)
    ---@type LuaxAstNode[]
    local ast = lpeg.match(GRAMMAR, ctx.file.content)
    ctx.ast = ast
end

return parse

end
__modules["luax/transpiler/luax_helpers"] = function()
---@param fn_name "map"|"filter"
local function luax_helpers(fn_name)
    if fn_name == "map" then
        return [[
        local function map(tbl, func)
    local newTbl = {}
    for i, v in ipairs(tbl) do
        table.insert(newTbl, func(v, i, tbl))
    end
    return table.concat(newTbl)
end
        ]]
    elseif fn_name == "filter" then
        return [[
        local function filter(tbl, func)
        local newTbl = {}
        for i, v in ipairs(tbl) do
            if func(v, i, tbl) then
                table.insert(newTbl, v)
            end
        end
        return table.concat(newTbl)
    end
        ]]
    end
end

return luax_helpers

end
__modules["luax/utils/format_header"] = function()
local function format_header(comments)
    local acc = {}
    for _, comment in ipairs(comments) do
        acc[#acc + 1] = "-- " .. comment
    end
    acc[#acc + 1] = "\n"
    return table.concat(acc, "\n")
end

return format_header

end
__modules["luax/transpiler/emit"] = function()
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

end
__modules["luax/transpiler/emitter"] = function()
local luax_helpers = __require("luax/transpiler/luax_helpers")
local format_header = __require("luax/utils/format_header")
local emit = __require("luax/transpiler/emit")



--- Assign ctx.emitted to the composition of preambles, headers, luax functions
--- and transpiled content together in a string[]
---@param ctx TranspilerContext
local function emitter(ctx)
    local config, content, emitted = ctx.config, ctx.file.content, ctx.emitted

    if config.headers.enabled then
        emitted[#emitted + 1] = format_header({
            "THIS CODE IS GENERATED BY LUAX TRANSPILER",
            "GENERATED AT: " .. tostring(os.date("%Y-%m-%d %H:%M:%S")),
            "TRANSPILER VERSION: " .. config.headers.transpiler_version,
            "AUTHOR: " .. config.headers.author,
            "LICENCE: " .. config.headers.licence,
            "REPO: " .. config.headers.repo_link,
        })
    end

    -- render function reference in module
    emitted[#emitted + 1] =
        ("local %s = require(%q)\n"):format(config.render_function_name, config.render_function_path)

    for _, fn in ipairs { "map", "filter" } do
        if content:match(">.-{.-" .. fn .. "%(.-%)") then
            emitted[#emitted + 1] = luax_helpers(fn)
        end
    end
    --
    for _, node in ipairs(ctx.ast) do
        emitted[#emitted + 1] = emit(node, ctx.config)
    end
    --
    local function replace_aliases(path)
        for _, entry in ipairs(config.alias) do
            local alias = entry.alias:gsub("([^%w])", "%%%1")
            path = path:gsub("^" .. alias, entry.path)
        end
        return path
    end

    for i = 1, #emitted do
        emitted[i] = emitted[i]:gsub(
            'require%s*%(%s*"(.-)"%s*%)',
            function(inner)
                return 'require("' .. replace_aliases(inner) .. '")'
            end
        )
    end
end

return emitter

end
__modules["luax/utils/fs"] = function()
local uv = __require("luv")
local Fs = {}
Fs.__index = Fs

function Fs.new()
    return setmetatable({
        uv = uv
    }, Fs)
end

function Fs:list_files(path)
    local handle = self.uv.fs_opendir(path)
    if not handle then return {} end
    local files = {}
    while true do
        local batch = self.uv.fs_readdir(handle)
        if not batch then break end
        for _, e in ipairs(batch) do
            if e.type == "file" then
                files[#files + 1] = e.name
            end
        end
    end
    self.uv.fs_closedir(handle)
    return files
end

function Fs:list(path)
    local handle = self.uv.fs_opendir(path)
    if not handle then return {} end
    local elements = {}
    while true do
        local batch = self.uv.fs_readdir(handle)
        if not batch then break end
        for _, e in ipairs(batch) do
            elements[#elements + 1] = e
        end
    end
    self.uv.fs_closedir(handle)
    return elements
end

function Fs:clear(root)
    if not root then return end
    root = uv.cwd() .. "/" .. root

    --
    local dirs = {}
    local files = {}
    --
    local function explore(path)
        local handle = uv.fs_opendir(path) -- uv.cwd() .. "dist"
        if not handle then return end
        while true do
            local batch = uv.fs_readdir(handle)
            if not batch then
                uv.fs_closedir(handle)
                return
            end
            for _, e in ipairs(batch) do
                local new_path = path .. "/" .. e.name
                if e.type == "directory" then
                    table.insert(dirs, 1, new_path)
                    explore(new_path)
                elseif e.type == "file" then
                    files[#files + 1] = new_path
                end
            end
        end
    end
    --
    explore(root)
    --
    for _, path in ipairs(files) do
        local ok = uv.fs_unlink(path)
        if not ok then
            print("Could not delete file")
        end
    end
    for _, path in ipairs(dirs) do
        local ok = uv.fs_rmdir(path)
        if not ok then
            print("Could not delete folder")
        end
    end
end

-- sync
function Fs:has_subdir(path)
    path = path:gsub("/$", "")
    local up_path, name = path:match("^(.*)/([^/]+)$")
    if not up_path then
        up_path = "."
        name = path
    elseif up_path == "" then
        up_path = "/"
    end
    if name == "" then return false end
    local handle = self.uv.fs_opendir(up_path)
    if not handle then return false end
    while true do
        local batch = self.uv.fs_readdir(handle)
        if not batch then
            self.uv.fs_closedir(handle)
            return false
        end
        for _, e in ipairs(batch) do
            if e.name == name and e.type == "directory" then
                self.uv.fs_closedir(handle)
                return true
            end
        end
    end
end

function Fs:list_dir(path)
    local handle = self.uv.fs_opendir(self.uv.cwd() .. path)
    if not handle then return false end
    local dirs = {}
    while true do
        local batch = self.uv.fs_readdir(handle)
        if not batch then
            self.uv.fs_closedir(handle)
            return dirs
        end
        for _, e in ipairs(batch) do
            if e.type == "directory" then
                dirs[#dirs + 1] = e.name
            end
        end
    end
end

-- sync
function Fs:create_dir(path)
    if not self:has_subdir(path) then
        assert(self.uv.fs_mkdir(path, 493), "Failed creating folder, folder already exist")
    end
end

-- sync
---@return string
function Fs:read(path)
    local fd = assert(self.uv.fs_open(path, "r", 438))
    local stat = assert(self.uv.fs_fstat(fd))
    local content = assert(self.uv.fs_read(fd, stat.size, 0))
    assert(self.uv.fs_close(fd))
    return content
end

-- sync
function Fs:write(path, content)
    local fd = assert(self.uv.fs_open(path, "w", 420))
    assert(self.uv.fs_write(fd, content))
    assert(self.uv.fs_close(fd))
end

function Fs:find_in(path, string)
    local content = self:read(path)
    if content:match(string) then return true end
end

uv.run()

return Fs

end
__modules["luax/utils/normalize_path"] = function()
local function normalize_path(_p)
    local tmp_path = _p:match("^(.-)%.?l?u?a?$")
    return tmp_path:gsub("%.", "/"):gsub("^%/+", "")
end

return normalize_path

end
__modules["luax/utils/logger"] = function()
-- logger.lua
local function Logger(config)
    local entries, max_cols = {}, 0
    local verbose = false

    for _, str in ipairs(arg) do
        if str == "--verbose" or str == "-V" then
            verbose = true
        end
    end

    ---@param node {name : string, path : string, weight : number}
    local function push(node)
        local prefix = "- "
        local suffix = config.suffix or "" -- e.g. ".lua"
        local strip = config.strip or (node.name .. suffix)

        local length = #prefix + #node.path + #suffix + 1
        if length > max_cols then max_cols = length end

        entries[#entries + 1] = function()
            local function trail()
                if node.weight == 0 then return prefix end
                return node.weight .. "K"
            end
            return string.format(
                "%s%s\27[38;5;250m%s\27[0m%s",
                prefix, node.path:gsub(strip, ""),
                node.name .. suffix,
                string.rep(".", max_cols - length) .. " " .. trail()
            )
        end
    end

    local head = function(mods)
        local action = config.action or "Processing"
        local source = config.source and config.source(config, mods) or "unknown"
        print(string.format(
            "%s %s modules %s",
            action,
            mods.count,
            source
        ))
    end

    local body = function()
        for _, fn in ipairs(entries) do print(fn()) end
    end

    local footer = function(mods)
        print(string.format(
            "%s %sK",
            string.rep(".", max_cols - #tostring(mods.weight)),
            mods.weight
        )
        )
    end

    ---@param type "head"|"body"|"footer"
    local function log(type, mods)
        if type == "head" then
            head(mods)
        elseif type == "body" and verbose then
            body()
        elseif type == "footer" and verbose then
            footer(mods)
        end
    end

    return {
        push = push,
        log = log,
    }
end

return Logger

end
__modules["luax/bundle"] = function()
--
local uv = __require("luv")
local inspect = __require("inspect")
local normalize_path = __require("luax/utils/normalize_path")
local Logger = __require("luax/utils/logger")
--

local _              = Logger({
    suffix = ".lua",
    strip = nil, -- defaults to node.name..suffix
    action = "Bundling",
    source = function(_, mods) return "at : " .. (mods.meta.target or "unknown") end,
})



local function require_interceptor()
    return table.concat({
        "local __modules, __cache = {}, {}",
        "local function __require(name)",
        "    if __cache[name] then",
        "        return __cache[name]",
        "    end",
        "    local fn = __modules[name]",
        "    if not fn then",
        "        local ok, external_fn = pcall(require, name)",
        "        if not ok then",
        "            error(\"\27[38;5;196m[Error]External library not found\27[0m : \" .. name)",
        "        end",
        "        __cache[name] = external_fn",
        "        return external_fn",
        "    end",
        "    local res = fn()",
        "    __cache[name] = res",
        "    return res",
        "end"
    }, " ")
end
--

local function get_requires(_content)
    local lines = {}
    local all_matches = {}

    local function read_require(line)
        return line:match("^%s*local%s+([%w_]+)%s*=%s*require%s*%([\"\'](.+)[\"\']%)%s*$")
    end

    local function add_match(_path)
        _path = _path:gsub("%.", "/")
        _path = _path .. ".lua"
        all_matches[#all_matches + 1] = _path
    end

    for line in _content:gmatch("[^\r\n]+") do
        local forbid = false
        lines[#lines + 1] = line
        local name, path = read_require(line)
        if path and name then
            add_match(path)
        end
    end
    return all_matches
end

---@return string
local function isolate_module(path, content)
    -- wrapping code and indexing module in table __modules
    -- avec / et .lua => normalized
    content = "\n__modules[\"" .. normalize_path(path) .. "\"] = function()\n" .. content .. "\nend"
    -- replacing require by __module reference
    content = content:gsub("%s*local%s+([%w_]+)%s*=%s*require%s*%(?['\"]([%w%._/-]+)['\"]%)?",
        function(var, p)
            return "\nlocal " .. var .. " = __require(\"" .. normalize_path(p) .. "\")"
        end
    )

    return content
end

-- serialize modules
---@param root Module
---@param cbs { visit_node:(fun(node:Module):Module), visit_end:fun(contents:string[]):contents:string[] }
---@return string[]
local function serialize(root, cbs)
    local contents = {}
    local function populate_buffer(node)
        if not node then return end
        node = cbs.visit_node(node)
        if node.imports then
            for _, child in ipairs(node.imports) do
                populate_buffer(child)
                contents[#contents + 1] = child.content
            end
        end
    end
    populate_buffer(root)
    contents[#contents + 1] = root.content
    cbs.visit_end(contents)
    return contents
end

local function default_reader(path)
    local fd = uv.fs_open(path, "r", 438)
    if not fd then
        print("\27[38;5;208mNot found : \27[0m" .. path)
        return
    end
    local stat = assert(uv.fs_fstat(fd))
    local content = assert(uv.fs_read(fd, stat.size, 0))
    assert(uv.fs_close(fd))
    return content, stat.size
end

local function default_writer(content, mode, output)
    local fd = assert(uv.fs_open(output, mode, 420))
    assert(uv.fs_write(fd, content))
    assert(uv.fs_close(fd))
end

---@params config TranspilerConfig["build"]
---@params injection Injection|nil
local function bundle(config, injection)
    --
    --
    --

    injection = injection or {}
    injection.reader = (injection and injection.reader) or default_reader
    injection.writer = (injection and injection.writer) or default_writer
    --
    --
    --
    ---@return Modules
    local function create_modules()
        --
        local module_paths, modules_counter, modules_weight, to_K = {}, 0, 0, function(a) return a / 1000 end

        ---@return Module
        local function create_module(n, p, ctn, weight, imports)
            local w = weight or 0
            modules_counter = modules_counter + 1
            modules_weight = modules_weight + w
            return {
                name = n,                -- underlying var
                path = p,                -- underlying path
                content = ctn or "",     -- file content
                weight = to_K(w),        -- xxx ko
                imports = imports or nil -- childs
            }
        end
        --
        local function step(path)
            -- avoid duplication
            if module_paths[path] then return nil end
            module_paths[path] = true

            local content, weight = injection.reader(path)
            local name = path:match("/?([^./]+).lua$")
            if not content then return create_module(name, path) end
            local child_paths = get_requires(content)

            content = isolate_module(path, content)

            if #child_paths == 0 then
                return create_module(name, path, content, weight)
            end

            local imports = {}
            for _, modulepath in ipairs(child_paths) do
                imports[#imports + 1] = step(modulepath)
            end

            return create_module(name, path, content, weight, imports)
        end

        return {
            root = step(config.root_file) or {},
            count = modules_counter,
            weight = to_K(modules_weight),
            meta = {
                paths = {
                    locals = module_paths,
                }
            },
        }
    end
    --
    --
    --
    local module_launcher = "\nreturn __modules[\"" .. normalize_path(config.root_file) .. "\"]()()"
    if config.type == "module" then module_launcher = module_launcher:gsub("%(%)$", "") end
    local modules          = create_modules()
    local module_buffer    = serialize(modules.root, {
        visit_node = function(node)
            _.push(node)
            return node
        end,
        visit_end = function(buffer)
            table.insert(buffer, module_launcher)
            table.insert(buffer, 1, require_interceptor())
            return buffer
        end
    })
    --
    --
    modules.meta["target"] = config.out_file
    --
    --
    _.log("head", modules)
    _.log("body")
    _.log("footer", modules)
    --

    injection.writer(table.concat(module_buffer, ""), "w", config.out_file)
    uv.run()
end

return bundle

end
__modules["luax/transpiler/build"] = function()
local Fs = __require("luax/utils/fs")
local bundle = __require("luax/bundle")
local normalize_path = __require("luax/utils/normalize_path")
local Logger = __require("luax/utils/logger")

--- Handle the build process of luax files
--- You can deactivate building step with config.build.no_emit in luaxconfig
--- The callback "on_source_file" is called when a file of interest is found ( see config.luax_file_extension ).
--- If the bundler flag (config.build.bundle) is false, source files are emitted in the defined out_dir ( see config.build.out_dir ).
---@param config TranspilerConfig
---@param on_source_file fun(file : File): emitted: string[]| nil
local function build(config, on_source_file)
    if config.build.no_emit then return end
    local file_count, files_weight, fs, transpiled, to_K = 0, 0, Fs.new(), {}, function(a) return a / 1000 end
    if config.build.empty_out_dir then
        fs:clear(config.build.out_dir)
    end

    --
    local _ = Logger({
        suffix = "",
        strip = nil, -- defaults to node.name
        action = "Transpiling",
        source = function() return "from : " .. (config.root or "unknown") end,
    })
    --

    local function update_stats(file)
        file_count = file_count + 1
        files_weight = files_weight + file.weight
        _.push(file)
    end

    local start_bundling = function()
        local path_as_module = normalize_path(config.render_function_path)
        local path_as_file = path_as_module
        if not path_as_module:match("%.lua$") then
            path_as_file = path_as_module .. ".lua"
        end
        local render_function_content = fs:read(path_as_file)
        if not render_function_content then
            print("\27[38;5;196m[Error]No render function found\27[0m : " .. path_as_file)
        end
        transpiled[path_as_module] = render_function_content

        bundle(config.build, {
            reader = function(path)
                if not transpiled[path] then return end
                return transpiled[path], (#transpiled[path])
            end
        })
    end
    --
    if not fs:has_subdir(config.root) then
        print("\27[38;5;208m[Warn]No source directory found\27[0m : " .. config.root)
        return
    end
    fs:create_dir(config.build.out_dir)
    --
    local function explore(root, out_dir)
        local dir_list = fs:list(root)
        for __, entry in ipairs(dir_list) do
            local src_path = root .. "/" .. entry.name

            local file_of_interest = function()
                local ext = config.luax_file_extension
                if entry.name:sub(- #ext) == ext then return true end
            end

            local create_file = function(n, p, c, w)
                if not c then c = fs:read(p) end
                if type(c) == "table" then c = table.concat(c, "\n") end
                return {
                    name = n,
                    path = p,
                    content = c,
                    weight = w or to_K(#c),
                }
            end

            local create_target_name = function()
                return entry.name:gsub("%.[^.]*$", config.build.target_file_extension)
            end

            local on_dir = function()
                local build_dir = out_dir .. "/" .. entry.name
                if not config.build.bundle then
                    fs:create_dir(build_dir)
                end
                explore(src_path, build_dir)
            end
            --
            if entry.type == "file" then
                if file_of_interest() then
                    local new_name = create_target_name()
                    local new_path = out_dir .. "/" .. new_name
                    --
                    local source_file = create_file(entry.name, src_path)
                    local transpiled_file = create_file(new_name, new_path, on_source_file(source_file))
                    if not transpiled_file.content then return end
                    update_stats(source_file)
                    if config.build.bundle then
                        transpiled[transpiled_file.path] = transpiled_file
                            .content                                            -- store file in transpiled for later use
                    else
                        fs:write(transpiled_file.path, transpiled_file.content) -- create file in out_dir
                    end
                end
                --
            elseif entry.type == "directory" then
                on_dir()
            end
        end
    end

    explore(config.root, config.build.out_dir)

    _.log("head", { count = file_count })
    _.log("body")
    _.log("footer", { weight = files_weight })

    if config.build.bundle then start_bundling() end
end

return build

end
__modules["luax/transpiler/transpile"] = function()
local uv = __require("luv")
local inspect = __require("inspect")
local parser = __require("luax/transpiler/parser")
local emitter = __require("luax/transpiler/emitter")
local build = __require("luax/transpiler/build")




---@param step "before_parse"|"before_emit"|"after_emit"
local function run_plugins(step, ctx, plugins)
    if not plugins then return end
    for _, plugin in ipairs(plugins) do
        if plugin[step] then
            plugin[step](ctx)
        end
    end
end

--- Luax transpiler main function
---@param config TranspilerConfig
local function transpile(config)
    build(
        config,
        function(file)
            --
            ---@type TranspilerContext
            local ctx = { file = file, config = config, emitted = {}, ast = {} }
            --
            run_plugins("before_parse", ctx, config.plugins)
            parser(ctx) -- parsing (ctx.ast mutation)
            --
            run_plugins("before_emit", ctx, config.plugins)
            emitter(ctx) -- code gen (ctx.emitted mutation)
            --
            run_plugins("after_emit", ctx, config.plugins)
            --
            return ctx.emitted
        end
    )
    uv.run()
end

return transpile

end
__modules["luax/utils/deep_merge"] = function()
local function deep_merge(partial, extended)
    local merged = {}
    for k, v in pairs(partial) do
        merged[k] = v
    end
    for k, v in pairs(extended) do
        if type(v) == "table" and type(merged[k]) == "table" then
            merged[k] = deep_merge(merged[k], v)
        else
            merged[k] = v
        end
    end
    return merged
end

return deep_merge

end
__modules["luax/utils/sort_aliases"] = function()
---@param config TranspilerConfig
local function sort_aliases(config)
    local ordered_aliases = {}
    for alias, path in pairs(config.alias) do
        ordered_aliases[#ordered_aliases + 1] = { alias = alias, path = path }
    end
    table.sort(ordered_aliases, function(a, b)
        return #a.alias > #b.alias
    end)
    return ordered_aliases
end

return sort_aliases

end
__modules["luax/transpiler/define_config"] = function()
local deep_merge = __require("luax/utils/deep_merge")
local sort_aliases = __require("luax/utils/sort_aliases")
local normalize_path = __require("luax/utils/normalize_path")
local uv = __require("luv")

local function resolve_render_path(path)
    local fd = uv.fs_open(path, "r", 438)
    if fd then
        uv.fs_close(fd)
        return path
    end

    local filepath = package.searchpath(path, package.path)
    if filepath then
        return normalize_path(filepath)
    end

    error("render.lua not found. Tried user path '" .. path .. "' and library path.")
end

---@param user_config PartialTranspilerConfig|nil
---@return TranspilerConfig
local function define_config(user_config)
    ---@type TranspilerConfig
    local defaults = {
        base                 = "",
        root                 = "src",
        luax_file_extension  = ".luax",       --
        render_function_name = "__lx__",      --
        render_function_path = "luax/render", --
        headers              = {
            enabled            = true,
            transpiler_version = "0.0.1",
            licence            = "NO LICENCE",
            author             = "razmi0",
            repo_link          = "https://github.com/razmi0/luax",
        }, --


        build   = {
            bundle = true,
            root_file = "main.lua",
            out_file = "_app.lua",
            out_dir = "build",
            no_emit = false,
            target_file_extension = ".lua",
            empty_out_dir = true,
            type = "none"
        },
        plugins = {},
        alias   = {}
    }

    local cfg = deep_merge(defaults, user_config)


    cfg.build.out_dir = cfg.base .. "/" .. cfg.build.out_dir
    cfg.root = cfg.base .. "/" .. cfg.root
    cfg.build.root_file = cfg.build.out_dir .. "/" .. cfg.build.root_file
    cfg.build.out_file = cfg.build.out_dir .. "/" .. cfg.build.out_file


    -- aliases are sorted by specificity (longer aliases)
    -- means more specificity (prevent aliases replacing each other)
    cfg.alias = sort_aliases(cfg)

    cfg.render_function_path = resolve_render_path(cfg.render_function_path)
    --
    return cfg
end

return define_config

end
__modules["luax/main"] = function()
--    (2) : luax embedded attributes in parser ? (have to)
--    (3) : allow comments in luax ( do not strip them ? feature in config ?)
--    (4) : allow literal array expressions in parser
--    (5) : add line/col information if parser crash
--    (6) : implement path alias ( done)
--    (7) : no config first (done)

--
local transpile = __require("luax/transpiler/transpile")
local define_config = __require("luax/transpiler/define_config")
--

---@return PartialTranspilerConfig
local function load_config()
    local ok, cfg = pcall(require, "luaxconfig")
    if ok then
        return cfg
    end
    print("\27[38;5;208m[Warn] No configuration file found\27[0m: luaxconfig.lua")
    return {}
end

local main = function()
    transpile(define_config(load_config()))
end

return main

end
return __modules["luax/main"]()()