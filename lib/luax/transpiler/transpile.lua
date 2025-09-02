local uv         = require("luv")
local inspect    = require("inspect")
local parse      = require("lib.luax.transpiler.parser_ast")
local emitter    = require("lib.luax.transpiler.emitter")
local emit       = require("lib.luax.transpiler.code_gen")
local build_file = require("lib.luax.transpiler.build")


--- Context is an object holding the transpiler information per file.
--- parse and emitter method mutate it.
---@class TranspilerContext
---@field file File
---@field config TranspilerConfig
---@field ast LuaxAstNode[]
---@field emitted string[]

--- Luax transpiler main function
---@param config TranspilerConfig
local function transpile(config, plugins)
    build_file(
        config,
        function(file)
            --
            local ext = config.LUAX_FILE_EXTENSION
            local target_ext = file.name:gsub("%.[^.]*$", config.TARGET_FILE_EXTENSION)
            if not file.name:sub(- #ext) == ext then return end

            ---@type TranspilerContext
            local ctx = {
                file = file,
                config = config,
                emitted = {},
                ast = {}
            }
            --
            parse(ctx)                  -- parsing (ctx.ast mutation)
            emitter(ctx, function(_ctx) -- code generation (ctx.emitted mutation)
                local emitted = _ctx.emitted
                for _, node in ipairs(ctx.ast) do
                    emitted[#emitted + 1] = emit(node, ctx.config)
                end
            end)
            --
            return target_ext, ctx.emitted
        end)
    uv.run()
end

return transpile
