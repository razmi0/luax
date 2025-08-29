local Fs      = require("lib.luax.utils.fs")
local parse   = require("lib.luax.transpiler.parser_ast")
local emit    = require("lib.luax.transpiler.code_gen")
local inspect = require("inspect")
local compose = require("lib.luax.transpiler.compose")

---@class TranspilerConfig
---@field SRC_PATH string
---@field BUILD_PATH string
---@field LUAX_FILE_EXTENSION string
---@field H_PRAGMA string
---@field RENDER_FUNCTION_NAME string
---@field RENDER_FUNCTION_PATH string

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
            local ast = parse(content) -- parsing
            local emitted = compose(
                config.RENDER_FUNCTION_NAME,
                config.RENDER_FUNCTION_PATH,
                { -- store preambles/emitted and return it
                    has_pragma = content:match(config.H_PRAGMA),
                    has_map_helper = content:match(">.-{.-map%(.-%)"),
                    has_filter_helper = content:match(">.-{.-filter%(.-%)")
                },
                function(accumulated)
                    for _, node in ipairs(ast) do
                        accumulated[#accumulated + 1] = emit(node, config.RENDER_FUNCTION_NAME)
                    end
                end)
            --
            local target_file_name = file:sub(1, #file - 1)
            fs:write(config.BUILD_PATH .. "/" .. target_file_name, emitted)
        end
    end
end

return transpile
