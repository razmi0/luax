--(1) : cli arguments (entry point, target file)
--
local uv                     = require("luv")
local inspect                = require("inspect")
--
local ENTRY_POINT, OUT_POINT = arg[1], uv.cwd() .. "/" .. arg[2]
local flags                  = (function()
    local x = {}
    for i = 3, #arg do
        if arg[i]:match("^%-%-") then
            x[arg[i]] = true
        end
    end
    return x
end)()
-- temp : libs need to be inputed from cli
local globals                = { luv = true, uv = true, inspect = true, lpeg = true }


---@class Module
---@field name string
---@field path string
---@field content string
---@field weight integer
---@field imports Module[]|nil

---@class Modules
---@field root Module
---@field count integer
---@field weight integer
---@field paths { locals : table<string, true>, globals : table<string, true> }

local function require_interceptor()
    local keys = {}
    for k, _ in pairs(globals) do
        keys[#keys + 1] = k
    end
    return table.concat({
        "local __modules = {}",
        "local __cache   = {}",
        "local globals = " .. inspect(keys),
        "local function __require(name)",
        "if __cache[name] then",
        "return __cache[name]",
        "end",
        "local found = false",
        "local fn = __modules[name]",
        "   if not fn then",
        "       found = false",
        "       for _, fruit in ipairs(globals) do ",
        "           if fruit == name then",
        "               found = true",
        "print('true')",
        "               break",
        "           end",
        "       end",
        "if found == true then fn = require(name) else ",
        "error(\"Module not found: \" .. name )",
        "end",
        "end",
        "local res = fn()",
        "__cache[name] = res",
        "return res",
        "end "
    }, "\n")
end
--
local c = { entries = {}, max_cols = 0 }
---@param type "head"|"body"|"footer"
function c:log(type, xx)
    if type == "head" then
        print("Bundling " .. xx .. " modules at : " .. "/" .. arg[2])
    elseif type == "body" and flags["--verbose"] then
        for _, fn in ipairs(self.entries) do
            print(fn())
        end
    elseif type == "footer" then
        print("." .. string.rep(".", self.max_cols - (#(tostring(xx)))) .. " " .. xx .. "ko")
    end
end

---@param node {name : string, path : string, weight : number}
function c:push(node)
    local lenght = #("--") + #node.path + #(".lua")
    if lenght > self.max_cols then self.max_cols = lenght end
    self.entries[#self.entries + 1] = function()
        return
            "--" ..
            node.path:gsub(node.name .. ".lua", "") ..
            "\27[38;5;250m" .. node.name .. ".lua" .. "\27[0m" ..
            string.rep(".", self.max_cols - lenght) ..
            " " .. node.weight .. "ko"
    end
end

local function read(path)
    local fd = assert(uv.fs_open(path, "r", 438))
    local stat = assert(uv.fs_fstat(fd))
    local content = assert(uv.fs_read(fd, stat.size, 0))
    assert(uv.fs_close(fd))
    return content, stat.size / 1000
end

local function write(content, mode)
    local fd = assert(uv.fs_open(OUT_POINT, mode, 420))
    assert(uv.fs_write(fd, content))
    assert(uv.fs_close(fd))
end

local function get_requires(_content)
    local lines = {}
    local all_matches = {}

    local function get_info(line)
        return line:match("^%s*local%s+([%w_]+)%s*=%s*require%s*%([\"\'](.+)[\"\']%)%s*$")
    end

    local top_level_requires       = {}
    local top_level_requires_cache = {}
    local function evaluate_require(_path, _name)
        if globals[_path] then
            if not top_level_requires_cache[_name] then
                top_level_requires[#top_level_requires + 1] = "local " ..
                    _name .. " = require(\"" .. _path .. "\")"
                top_level_requires_cache[_name] = true
            end
            return true
        end
    end

    local function add_match(_path)
        _path = _path:gsub("%.", "/")
        _path = _path .. ".lua"
        all_matches[#all_matches + 1] = _path
    end

    for line in _content:gmatch("[^\r\n]+") do
        local forbid = false
        lines[#lines + 1] = line
        local name, path = get_info(line)
        if path then
            forbid = evaluate_require(path, name)
            if not forbid then
                add_match(path)
            end
        end
    end
    return all_matches
end

local function isolate_module(path, content)
    -- wrap the module inside a function
    -- name = name:gsub("%.", "/")
    content = "\n__modules[\"" .. path .. "\"] = function()\n" -- avec / et .lua
        .. content ..
        "\nend"

    content = content:gsub(
        "%s*local%s+([%w_]+)%s*=%s*require%s*%(?['\"]([%w%._/-]+)['\"]%)?",
        function(var, p)
            if globals[p] then
                return "\nlocal " .. var .. " = require(\"" .. p .. "\")" -- avec .lua
            end

            -- path = path:gsub("%.", "/")
            -- path = path:gsub("[./]lua%s*$", "")
            return "\nlocal " .. var .. " = __require(\"" .. p:gsub("%.", "/") .. ".lua" .. "\")" -- avec . sans .lua
        end
    )



    return content
end

---@return Module
local function create_node(n, p, ctn, w, imports)
    return {
        name = n,
        path = p,
        content = ctn,
        weight = w,
        imports = imports
    }
end


---@return Modules
local function create_modules(root_path)
    --
    local module_paths    = {}
    local modules_counter = 0
    local modules_weight  = 0
    local function on_step(node)
        modules_counter = modules_counter + 1
        modules_weight = modules_weight + node.weight
    end
    --
    local function step(path)
        -- avoid duplication
        if module_paths[path] then return nil end
        module_paths[path] = true

        local content, weight = read(path)
        local name = path:match("/([^./]+).lua$")
        local file_modulespath = get_requires(content)

        -- clean module content
        content = isolate_module(path, content)

        if #file_modulespath == 0 then
            local node = create_node(name, path, content, weight, nil)
            if node then on_step(node) end
            return node
        end

        local imports = {}
        for _, modulepath in ipairs(file_modulespath) do
            imports[#imports + 1] = step(modulepath)
        end

        local node = create_node(name, path, content, weight, imports)
        if node then on_step(node) end
        return node
    end

    return {
        root = step(root_path) or {},
        count = modules_counter,
        weight = modules_weight,
        paths = { locals = module_paths, globals = globals }
    }
end

---@param root Module
---@param cbs { visit_node:fun(node:Module), visit_end:fun(contents:string[]) }
---@return string[]
local function bundle(root, cbs)
    local contents = {}
    local function populate_buffer(node)
        if not node then return end
        cbs.visit_node(node)
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

local function main()
    local module_launcher = "\nreturn __modules[\"" .. ENTRY_POINT .. "\"]()"
    local modules         = create_modules(ENTRY_POINT)
    local module_buffer   = bundle(modules.root, {
        visit_node = function(node) c:push(node) end,
        visit_end = function(buffer)
            table.insert(buffer, module_launcher)
            table.insert(buffer, 1, require_interceptor())
        end
    })
    --
    c:log("head", modules.count)
    c:log("body")
    c:log("footer", modules.weight)
    --
    if flags["--rm-source"] then
        -- print(inspect(modules.paths))
    end
    write(table.concat(module_buffer, ""), "w")
end

--
--
--
--
--
--
--
--
--
--
--
--
--

main()
