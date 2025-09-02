local uv = require("luv")
local Fs = require("lib.luax.utils.fs")

---@param config TranspilerConfig
---@param on_file fun(file : { name : string, content : string }): (builded_filename: string| nil, emitted: string[]| nil )
local function build(config, on_file)
    local fs = Fs.new(uv)
    assert(fs:has_subdir(config.SRC_PATH), "No source directory found : " .. config.SRC_PATH)
    --
    fs:create_dir(config.BUILD_PATH)
    --
    local function explore(src_path, build_path)
        local dir_list = fs:list(src_path)
        for _, entry in ipairs(dir_list) do
            local new_src_path = src_path .. "/" .. entry.name
            local new_build_path = build_path .. "/" .. entry.name
            --
            if entry.type == "file" then
                --
                local content = fs:read(new_src_path)
                local new_file_name, writable = on_file({ name = entry.name, content = content })
                if writable and new_file_name then
                    fs:write(build_path .. "/" .. new_file_name, writable)
                end
                --
            elseif entry.type == "directory" then
                --
                fs:create_dir(new_build_path)
                explore(new_src_path, new_build_path)
                --
            end
        end
    end

    explore(config.SRC_PATH, config.BUILD_PATH)
end

return build
