--(1) : cli arguments (entry point, target file)
--
local uv                                 = require("luv")
local inspect                            = require("inspect")
--
local ENTRY_POINT, OUT_POINT, SRC_REMOVE = arg[1], uv.cwd() .. "/" .. arg[2], arg[3]
local module_launcher                    = "\nreturn __modules[\"" .. ENTRY_POINT .. "\"]()"
local FORBIDDEN_REQUIRES                 = { "luv", "uv", "inspect", "lpeg" }
local top_level_requires                 = {}
local log_length_max                     = 0
local log_buffer                         = {}
local top_level_requires_cache           = {}
local module_cache                       = {}
--

local function require_interceptor()
    return table.concat({
        "local __modules = {}",
        "local __cache   = {}",
        "local globals = " .. inspect(FORBIDDEN_REQUIRES),
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

---@param position "top"|"bottom"
local function inject_in_buffer(position, buffer, str)
    -- table.insert(buffer, 1, table.concat(top_level_requires, "\n"))
    if position == "top" then
        table.insert(buffer, 1, str)
    else
        buffer[#buffer + 1] = str
    end
end

--

local function log_title(modules_counter)
    print("Bundling " .. modules_counter .. " modules at : " .. "/" .. arg[2])
end

---@param module {name : string, path : string, weight : number}
local function log_add_entry(module)
    local lenght = #("--") + #module.path + #(".lua")
    if lenght > log_length_max then log_length_max = lenght end
    log_buffer[#log_buffer + 1] = function()
        return
            "--" ..
            module.path:gsub(module.name .. ".lua", "") ..
            "\27[38;5;250m" .. module.name .. ".lua" .. "\27[0m" ..
            string.rep(".", log_length_max - lenght) ..
            " " .. module.weight .. "ko"
    end
end

local function log_entries(modules_weight)
    for _, fn in ipairs(log_buffer) do
        print(fn())
    end
    print("." .. string.rep(".", log_length_max - (#(tostring(modules_weight)))) .. " " .. modules_weight .. "ko")
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

    local function evaluate_require(_path, _name)
        for _, lib in ipairs(FORBIDDEN_REQUIRES) do
            if _path == lib then
                if not top_level_requires_cache[_name] then
                    top_level_requires[#top_level_requires + 1] = "local " ..
                        _name .. " = require(\"" .. _path .. "\")"
                    top_level_requires_cache[_name] = true
                end
                return true
            end
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

    local function find(arr, n)
        for _, v in ipairs(arr) do
            if v == n then
                return true
            end
        end
        return false
    end

    content = "\n__modules[\"" .. path .. "\"] = function()\n" -- avec / et .lua
        .. content ..
        "\nend"

    content = content:gsub(
        "%s*local%s+([%w_]+)%s*=%s*require%s*%(?['\"]([%w%._/-]+)['\"]%)?",
        function(var, p)
            if find(FORBIDDEN_REQUIRES, p) then
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
local function create_node(n, p, c, w, imports)
    return {
        name = n,
        path = p,
        content = c,
        weight = w,
        imports = imports
    }
end


---@return Module
local function import_map(root_path, on_step)
    local function step(path)
        -- avoid duplication
        if module_cache[path] then return nil end
        module_cache[path] = true

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

    return step(root_path) or {}
end

---@param module Module
local function bundle(module, on_entry)
    local module_content_buffer = {}
    local function populate_buffer(node)
        if not node then return end
        on_entry(node)
        if node.imports then
            for _, child in ipairs(node.imports) do
                populate_buffer(child)
                module_content_buffer[#module_content_buffer + 1] = child.content
            end
        end
    end
    populate_buffer(module)
    module_content_buffer[#module_content_buffer + 1] = module.content
    return module_content_buffer
end

local function main()
    ---@class Module
    ---@field name string
    ---@field path string
    ---@field content string
    ---@field weight integer
    ---@field imports Module[]|nil

    local modules_counter = 0
    local modules_weight = 0
    ---@type Module
    local modules = import_map(ENTRY_POINT,
        function(node)
            modules_counter = modules_counter + 1
            modules_weight = modules_weight + node.weight
        end
    )
    local module_buffer = bundle(modules, function(node) log_add_entry(node) end)
    inject_in_buffer("bottom", module_buffer, module_launcher)
    inject_in_buffer("top", module_buffer, require_interceptor())
    log_title(modules_counter)
    log_entries(modules_weight)
    if SRC_REMOVE == "--src-remove" then
        print(inspect(module_cache))
        -- uv.fs_unlink(path, [callback])
    end
    write(table.concat(module_buffer, ""), "w")
end

main()
