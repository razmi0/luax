--(1) : cli arguments (entry point, target file)
--
local uv                     = require("luv")
local inspect                = require("inspect")
--
local ENTRY_POINT, OUT_POINT = arg[1], uv.cwd() .. "/" .. arg[2]
local FORBIDDEN_REQUIRES     = { "luv", "inspect", "lpeg" }
local top_level_requires     = {}
local log_length_max         = 0
local log_buffer             = {}
--

local function log_title(modules_counter)
    print("Bundling " .. modules_counter .. " modules at : " .. "/" .. arg[2])
end

---@param module Module
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

local function remove_last_return(src)
    local patt_ret = "%f[%w]return%f[%W]"
    local patt_end = "%f[%w]end%f[%W]"

    -- find last 'return' occurrence
    local last_s, last_e
    local i = 1
    while true do
        local s, e = src:find(patt_ret, i)
        if not s then break end
        last_s, last_e = s, e
        i = e + 1
    end

    if not last_s then
        return src
    end

    -- if there's any `end` keyword after that return, don't remove (it's inside a block)
    local after = src:sub(last_e + 1)
    if after:find(patt_end) then
        return src
    end

    -- remove from that 'return' to EOF and trim trailing whitespace/newlines
    local cleaned = src:sub(1, last_s - 1)
    return cleaned
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

local top_level_requires_cache = {}
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

local function isolate_module(content)
    local ctn = remove_last_return(content)
    ctn = ctn:gsub("%s*local%s+[%w_]+%s*=%s*require%s*%(?['\"][%w%._/-]+['\"]%)?", "")
    return ctn
end

---@return Module
local function import_map(path, on_step)
    local module_cache = {}

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


    local function step(_path)
        -- avoid duplication
        if module_cache[_path] then return nil end
        module_cache[_path] = true

        local content, weight = read(_path)
        local name = _path:match("/([^./]+).lua$")
        local file_modules_path = get_requires(content)

        -- clean module content
        content = isolate_module(content)

        if #file_modules_path == 0 then
            local node = create_node(name, _path, content, weight, nil)
            if node then on_step(node) end
            return node
        end

        local imports = {}
        for _, module_path in ipairs(file_modules_path) do
            imports[#imports + 1] = step(module_path)
        end

        local node = create_node(name, _path, content, weight, imports)
        if node then on_step(node) end
        return node
    end

    return step(path) or {}
end


---@param module Module
local function bundle(module, on_entry)
    local module_content_buffer = {}
    --
    local function populate_buffer(node)
        if not node then return end
        --
        on_entry(node)
        --
        if node.imports then
            for _, child in ipairs(node.imports) do
                populate_buffer(child)
                module_content_buffer[#module_content_buffer + 1] = child.content
            end
        end
    end
    --
    populate_buffer(module)
    module_content_buffer[#module_content_buffer + 1] = module.content
    return module_content_buffer
end

local function wrap_module(module_content)

end



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
--
local module_buffer = bundle(modules,
    function(node)
        log_add_entry(node)
    end
)
table.insert(module_buffer, 1, table.concat(top_level_requires, "\n"))
--
log_title(modules_counter)
log_entries(modules_weight)
--
write(
    (table.concat(module_buffer, ""))
    , "w"
)
