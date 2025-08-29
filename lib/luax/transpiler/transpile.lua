local Fs      = require("lib.luax.utils.fs")
local parse   = require("lib.luax.transpiler.parser_ast")
local emit    = require("lib.luax.transpiler.code_gen")
local inspect = require("inspect")

---@class TranspilerConfig
---@field SRC_PATH string
---@field BUILD_PATH string
---@field LUAX_FILE_EXTENSION string
---@field H_PRAGMA string
---@field H_PREAMBLE string
---@field RENDER_FUNCTION_NAME string
---@field LUAX_MAP_HELPER_PREAMBLE string
---@field LUAX_FILTER_HELPER_PREAMBLE string

--> luax -> hyperscript --> index.html
---@param config TranspilerConfig
local function transpile(uv, config)
    -- read one time instead of a lot ?
    local fs = Fs.new(uv)
    if not fs:has_subdir(config.SRC_PATH) then return end
    fs:create_dir(config.BUILD_PATH)
    local files = fs:list_files(config.SRC_PATH)
    for _, file in ipairs(files) do
        if file:sub(-5) == config.LUAX_FILE_EXTENSION then
            local path = config.SRC_PATH .. "/" .. file
            local content = fs:read(path)
            --parsing
            local ast = parse(content)
            --codegen
            local emitted = {}
            --
            local has_pragma = content:match(config.H_PRAGMA)
            local has_map_helper = content:match(">.-{.-map%(.-%)")
            local has_filter_helper = content:match(">.-{.-filter%(.-%)")
            if has_pragma then
                emitted[#emitted + 1] = config.H_PREAMBLE
            end
            if has_map_helper then
                emitted[#emitted + 1] = config.LUAX_MAP_HELPER_PREAMBLE
            end
            if has_filter_helper then
                emitted[#emitted + 1] = config.LUAX_FILTER_HELPER_PREAMBLE
            end
            --
            for _, node in ipairs(ast) do
                emitted[#emitted + 1] = emit(node, config.RENDER_FUNCTION_NAME)
            end
            local target_file_name = file:sub(1, #file - 1)
            fs:write(config.BUILD_PATH .. "/" .. target_file_name, emitted)
        end
    end
end

return transpile
