--
local uv                       = require("luv")
local inspect                  = require("inspect")
local normalize_path           = require("lib.luax.utils.normalize_path")
--

local flags, globals, rm_paths = (function()
    local flag_map, globals, rm_paths = {}, {}, {}
    local on_flag_args = function(start, str, callback)
        local targets = {
            global = function(s)
                return s:match("^%-%-globals?") or s:match("^%-%-G")
            end,
            rm_src = function(s)
                return s:match("^%-%-remove%-source") or s:match("^%-%-R")
            end
        }
        for k, fn in pairs(targets) do
            if fn(str) then
                for j = start + 1, #arg do
                    if not arg[j] then return j end
                    if arg[j]:match("^%-%-") then return j end
                    callback(k, arg[j])
                end
            end
        end
    end
    for i = 1, #arg do
        if arg[i]:match("^%-%-.-") then
            flag_map[arg[i]] = true
        end
        on_flag_args(i, arg[i], function(type, _arg)
            if type == "global" then
                globals[_arg] = true
            elseif type == "rm_src" then
                rm_paths[#rm_paths + 1] = _arg
            end
        end)
    end
    return flag_map, globals, rm_paths
end)()

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
---@field meta { paths : { locals : table<string, true>, globals : table<string, true> } }

local function require_interceptor()
    local keys = {}
    for k, _ in pairs(globals) do
        keys[#keys + 1] = k
    end
    return table.concat({
        "local __modules, __cache, globals  = {}, {}," .. inspect(keys),
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
    }, " ")
end
--

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

---@return string
local function isolate_module(path, content)
    -- wrapping code and indexing module in table __modules
    -- avec / et .lua => normalized
    content = "\n__modules[\"" .. normalize_path(path) .. "\"] = function()\n" .. content .. "\nend"
    -- replacing require by __module reference
    content = content:gsub("%s*local%s+([%w_]+)%s*=%s*require%s*%(?['\"]([%w%._/-]+)['\"]%)?",
        function(var, p)
            if globals[p] then
                -- external lib ( out of __modules : require)
                return "\nlocal " .. var .. " = require(\"" .. p .. "\")" -- sans .lua
            end
            -- local lib ( out of __modules : __require)
            return "\nlocal " .. var .. " = __require(\"" .. normalize_path(p) .. "\")" -- avec . sans .lua
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

local function remove_src_files(modules)
    for path, _ in pairs(modules.meta.paths.locals) do
        for _, pattern in ipairs(rm_paths) do
            if path:match(pattern) then
                local fd = uv.fs_unlink(path)
                if not fd then return end
                uv.fs_unlink(path)
            end
        end
    end
end

local function logger()
    local entries, max_cols = {}, 0

    ---@param node {name : string, path : string, weight : number}
    local function push(node)
        local prefix = "- "
        local length = #prefix + #node.path + #(".lua") + 1
        if length > max_cols then max_cols = length end
        entries[#entries + 1] = function()
            local function trail()
                if node.weight == 0 then return prefix end
                return node.weight .. "K"
            end
            return
                prefix ..
                node.path:gsub(node.name .. ".lua", "") ..
                "\27[38;5;250m" .. node.name .. ".lua" .. "\27[0m" ..
                string.rep(".", max_cols - length) .. " " .. trail()
        end
    end

    ---@param type "head"|"body"|"footer"
    local function log(type, mods)
        if type == "head" then
            print("Bundling " .. mods.count .. " modules at : " .. (mods.meta.target or "unknown"))
        elseif type == "body" and (flags["--verbose"] or flags["--V"]) then
            for _, fn in ipairs(entries) do
                print(fn())
            end
        elseif type == "footer" then
            print(string.rep(".", max_cols - (#tostring(mods.weight))) .. " " .. mods.weight .. "K")
        end
    end

    return {
        push = push,
        log = log,
    }
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
    return content, stat.size / 1000
end

local function default_writer(content, mode, output)
    local fd = assert(uv.fs_open(output, mode, 420))
    assert(uv.fs_write(fd, content))
    assert(uv.fs_close(fd))
end

---@alias Reader fun(path: string): string
---@alias Writer fun(content: string, mode: "a"|"w", path: string): nil

---@class Injection
---@field reader Reader|nil
---@field writer Writer|nil

---@class BundlerConfig
---@field in_file string
---@field out_file string

---@params config TranspilerConfig["build"]
---@params injection Injection|nil
---@params root_path string
---@params out_path string
local function bundle(config, injection)
    --
    --
    --

    injection.reader = (injection and injection.reader) or default_reader
    injection.writer = (injection and injection.writer) or default_writer
    --
    --
    --
    ---@return Modules
    local function create_modules()
        --
        local module_paths    = {}
        local modules_counter = 0
        local modules_weight  = 0
        ---@return Module
        local function create_module(n, p, ctn, weight, imports)
            local w = weight or 0
            modules_counter = modules_counter + 1
            modules_weight = modules_weight + w
            return {
                name = n,                -- underlying var
                path = p,                -- underlying path
                content = ctn or "",     -- file content
                weight = w,              -- xxx ko
                imports = imports or nil -- childs
            }
        end
        --
        local function step(path)
            -- avoid duplication
            if module_paths[path] then return nil end
            module_paths[path] = true

            local content, weight = injection.reader((path))
            local name = path:match("/([^./]+).lua$")
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
            root = step(config.root) or {},
            count = modules_counter,
            weight = modules_weight,
            meta = {
                paths = { locals = module_paths, globals = globals }
            },
        }
    end
    --
    --
    --
    local module_launcher  = "\nreturn __modules[\"" .. config.root .. "\"]()"
    local _, modules       = logger(), create_modules()
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
    --
    if flags["--remove-source"] or flags["--R"] then
        remove_src_files(modules)
    end

    injection.writer(table.concat(module_buffer, ""), "w", config.out_file)
    uv.run()
end

return bundle
