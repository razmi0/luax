local Fs = require("luax.utils.fs")
local bundle = require("luax.bundle")
local normalize_path = require("luax.utils.normalize_path")
local Logger = require("luax.utils.logger")

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
        fs:clear("/" .. config.build.out_dir)
    end

    --
    local _ = Logger({
        suffix = "",
        strip = nil, -- defaults to node.name
        action = "Transpiling",
        source = function() return "from : " .. (config.root or "unknown") end,
        flags = config.cmd.flags,
    })
    --

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
