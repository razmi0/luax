local uv      = require("luv")
local inspect = require("inspect")
local Fs      = require("lib.luax.utils.fs")
local parse   = require("lib.luax.transpiler.parser_ast")
local emit    = require("lib.luax.transpiler.code_gen")
local compose = require("lib.luax.transpiler.compose")

---@class TranspilerConfig
---@field SRC_PATH string
---@field BUILD_PATH string
---@field LUAX_FILE_EXTENSION string
---@field RENDER_FUNCTION_NAME string
---@field RENDER_FUNCTION_PATH string
---@field TARGET_FILE_EXTENSION string

---@param config TranspilerConfig
local function generate_build(config, on_file)
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
                local writable, new_file_name = on_file(entry.name, content)
                fs:write(build_path .. "/" .. new_file_name, writable)
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

---@param config TranspilerConfig
local function transpile(config)
    generate_build(config,
        function(filename, content)
            local ext = config.LUAX_FILE_EXTENSION
            if filename:sub(- #ext) == ext then
                --
                local ast = parse(content, config) -- parsing
                local emitted = compose(           -- code generation
                    content,
                    config,
                    function(acc)
                        for _, node in ipairs(ast) do
                            acc[#acc + 1] = emit(node, config)
                        end
                        return acc
                    end
                )
                --
                local builded_filename = filename:gsub("%.[^.]*$", config.TARGET_FILE_EXTENSION)
                return emitted, builded_filename
            end
        end
    )
    uv.run()
end


return transpile
