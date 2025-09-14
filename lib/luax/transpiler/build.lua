local Fs = require("lib.luax.utils.fs")
local bundle = require("lib.bundler.bundle")
local normalize_path = require("lib.luax.utils.normalize_path")

local function logger(config)
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
                node.path:gsub(node.name, "") ..
                "\27[38;5;250m" .. node.name .. "\27[0m" .. string.rep(".", max_cols - length) .. " " .. trail()
        end
    end

    ---@param type "head"|"body"|"footer"
    local function log(type, mods)
        if type == "head" then
            print("Transpiling " .. mods.count .. " modules from : " .. (config.root or "unknown"))
        elseif type == "body" and (config.cmd.flags["--verbose"] or config.cmd.flags["--V"]) then
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


--- Handle the build process of a luax project.
--- The callback "on_file" is called when a file is found.
--- If the callback returns a string[], the file is written to the build directory.
---@param config TranspilerConfig
---@param on_source_file fun(file : File): emitted: string[]| nil
local function build(config, on_source_file)
    if config.build.no_emit then return end
    local _ = logger(config)
    local file_count, files_weight, fs, transpiled, to_K = 0, 0, Fs.new(), {}, function(a) return a / 1000 end
    local function update_stats(file)
        file_count = file_count + 1
        files_weight = files_weight + file.weight
        _.push(file)
    end

    local start_bundling = function()
        local render_function_path = normalize_path(config.render_function_path)
        local render_function_content = fs:read(render_function_path)
        transpiled[render_function_path] = render_function_content

        bundle(config.build, {
            reader = function(path)
                if not transpiled[path] then return end
                return transpiled[path], (#transpiled[path])
            end
        })
    end
    --
    assert(fs:has_subdir(config.root), "No source directory found : " .. config.root)
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
                if not file_of_interest() then return end
                --
                local new_name = create_target_name()
                local new_path = out_dir .. "/" .. new_name
                --
                local source_file = create_file(entry.name, src_path)
                local transpiled_file = create_file(new_name, new_path, on_source_file(source_file))
                if not transpiled_file.content then return end
                update_stats(source_file)
                if config.build.bundle then
                    transpiled[transpiled_file.path] = transpiled_file.content -- store file in transpiled for later use
                else
                    fs:write(transpiled_file.path, transpiled_file.content)    -- create file in out_dir
                end
            elseif entry.type == "directory" then
                on_dir()
            end
        end
    end

    explore(config.root, config.build.out_dir)

    _.log("head", { count = file_count })
    _.log("body")
    _.log("footer", { weight = to_K(files_weight) })

    if config.build.bundle then start_bundling() end
end

return build
