local uv      = require("luv")
local inspect = require("inspect")
local parser  = require("lib.luax.transpiler.parser")
local emitter = require("lib.luax.transpiler.emitter")
local emit    = require("lib.luax.transpiler.emit")
local build   = require("lib.luax.transpiler.build")




---@param step "before_parse"|"before_emit"|"after_emit"
local function run_plugins(step, ctx, plugins)
    if not plugins then return end
    for _, plugin in ipairs(plugins) do
        if plugin[step] then
            plugin[step](ctx)
        end
    end
end

--- Luax transpiler main function
---@param config TranspilerConfig
local function transpile(config)
    build(
        config,
        function(file)
            --
            ---@type TranspilerContext
            local ctx = {
                file = file,
                config = config,
                emitted = {},
                ast = {}
            }
            --
            run_plugins("before_parse", ctx, config.plugins)
            parser(ctx) -- parsing (ctx.ast mutation)
            --
            run_plugins("before_emit", ctx, config.plugins)
            emitter(ctx, function(_ctx) -- code generation (ctx.emitted mutation)
                local emitted = _ctx.emitted
                for _, node in ipairs(ctx.ast) do
                    emitted[#emitted + 1] = emit(node, ctx.config)
                end
            end)
            --
            run_plugins("after_emit", ctx, config.plugins)
            --
            return ctx.emitted
        end
    )
    uv.run()
end

return transpile
