local Fs = require("lib.luax.utils.fs")
local bundle = require("lib.bundler.bundle")
local normalize_path = require("lib.luax.utils.normalize_path")



--- Handle the build process of a luax project.
--- The callback "on_file" is called when a file is found.
--- If the callback returns a string[], the file is written to the build directory.
---@param config TranspilerConfig
---@param on_file fun(file : File): emitted: string[]| nil
local function build(config, on_file)
    if config.build.no_emit then return end
    local fs = Fs.new()
    local transpiled = {}
    --
    assert(fs:has_subdir(config.root), "No source directory found : " .. config.root)
    fs:create_dir(config.build.out_dir)
    --
    local function explore(root, out_dir)
        local dir_list = fs:list(root)
        for _, entry in ipairs(dir_list) do
            local new_src_path = root .. "/" .. entry.name
            local new_build_path = out_dir .. "/" .. entry.name
            --
            if entry.type == "file" then
                --
                local source_content = fs:read(new_src_path)
                local ext = config.luax_file_extension
                local new_file_name = entry.name:gsub("%.[^.]*$", config.build.target_file_extension)
                if entry.name:sub(- #ext) == ext then
                    local writable = on_file({ name = entry.name, content = source_content })
                    if writable then
                        if not config.build.bundle then
                            fs:write(out_dir .. "/" .. new_file_name, writable)
                        else
                            transpiled[out_dir .. "/" .. new_file_name] = table.concat(writable, "\n")
                        end
                    end
                end
                --
            elseif entry.type == "directory" then
                --
                if not config.build.bundle then
                    fs:create_dir(new_build_path)
                end
                explore(new_src_path, new_build_path)
                --
            end
        end
    end

    explore(config.root, config.build.out_dir)

    if not config.build.bundle then return end

    local render_function_path = normalize_path(config.render_function_path)
    local render_function_content = fs:read(render_function_path)
    transpiled[render_function_path] = render_function_content

    bundle(config.build, {
        reader = function(path)
            return transpiled[path], (#transpiled[path] / 1000)
        end
    })
end

return build
