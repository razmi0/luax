--
local uv             = require("luv")
local inspect        = require("inspect")
local normalize_path = require("luax.utils.normalize_path")
local Logger         = require("luax.utils.logger")
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
