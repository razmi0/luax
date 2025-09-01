local uv      = require("luv")
local inspect = require("inspect")
local parse   = require("lib.luax.transpiler.parser_ast")
local emit    = require("lib.luax.transpiler.code_gen")
local compose = require("lib.luax.transpiler.compose")
local build   = require("lib.luax.transpiler.build")

---@class TranspilerConfig
---@field SRC_PATH string
---@field BUILD_PATH string
---@field LUAX_FILE_EXTENSION string
---@field RENDER_FUNCTION_NAME string
---@field RENDER_FUNCTION_PATH string
---@field TARGET_FILE_EXTENSION string



---@param config TranspilerConfig
local function transpile(config)
    build(
        config,
        function(file)
            local ext = config.LUAX_FILE_EXTENSION
            if not file.name:sub(- #ext) == ext then return end
            --
            local ast = parse(file.content, config)     -- parsing
            local emitted = compose(                    -- code generation
                file.content,
                config,
                function(acc)
                    for _, node in ipairs(ast) do
                        acc[#acc + 1] = emit(node, config)
                    end
                end)
            --
            return
                file.name:gsub("%.[^.]*$", config.TARGET_FILE_EXTENSION),
                emitted
        end
    )
    uv.run()
end

return transpile
