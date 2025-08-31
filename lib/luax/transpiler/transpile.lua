local uv      = require("luv")
local Fs      = require("lib.luax.utils.fs")
local parse   = require("lib.luax.transpiler.parser_ast")
local emit    = require("lib.luax.transpiler.code_gen")
local inspect = require("inspect")
local compose = require("lib.luax.transpiler.compose")

---@class TranspilerConfig
---@field SRC_PATH string
---@field BUILD_PATH string
---@field LUAX_FILE_EXTENSION string
---@field RENDER_FUNCTION_NAME string
---@field RENDER_FUNCTION_PATH string
---@field TARGET_FILE_EXTENSION string



--> luax -> hyperscript --> index.html
---@param config TranspilerConfig
local function transpile(config)
    -- read one time instead of a lot ?
    local fs = Fs.new(uv)
    local x = fs:list_dir("/src/")
    print(inspect(x))
    if not fs:has_subdir(config.SRC_PATH) then return end
    fs:create_dir(config.BUILD_PATH)
    local files = fs:list_files(config.SRC_PATH)
    -- for _, folder in ipairs(folders) do
    for _, file in ipairs(files) do
        if file:sub(-5) == config.LUAX_FILE_EXTENSION then
            local path = config.SRC_PATH .. "/" .. file
            local content = fs:read(path)
            local ast = parse(content)     -- parsing
            local emitted = compose(content, config,
                function(acc)
                    for _, node in ipairs(ast) do
                        acc[#acc + 1] = emit(node, config.RENDER_FUNCTION_NAME)
                    end
                    return acc
                end)
            -- config.TARGET_FILE_EXTENSION
            local target_file_name = file:gsub("%.[^.]*$", config.TARGET_FILE_EXTENSION)
            fs:write(config.BUILD_PATH .. "/" .. target_file_name, emitted)
        end
        -- end
    end
    uv.run()
end


return transpile
