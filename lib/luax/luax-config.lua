---@type TranspilerConfig
return {
    TRANSPILER_VERSION    = "0.0.1",
    LICENCE               = "NO LICENCE",
    AUTHOR                = "razmi0",
    REPO_LINK             = "https://github.com/razmi0/luax",
    DATE                  = tostring(os.date("%Y-%m-%d %H:%M:%S")),
    SRC_PATH              = "src",
    BUILD_PATH            = "build",
    LUAX_FILE_EXTENSION   = ".luax",
    TARGET_FILE_EXTENSION = ".lua",
    RENDER_FUNCTION_NAME  = "lx",
    RENDER_FUNCTION_PATH  = "lib.luax.transpiler.luax",
    --
    -- plugins               = {
    --     {
    --         name = "test_plugin_1",
    --         before_parse = function(ctx)
    --             print("from plugin : before_parse_1 " .. ctx.file.name)
    --         end,
    --         before_emit = function(ctx)
    --             print("from plugin : before_emit_1" .. ctx.file.name)
    --         end,
    --         after_emit = function(ctx)
    --             print("from plugin : after_emit_1" .. ctx.file.name)
    --         end,
    --     },
    --     {
    --         name = "test_plugin_2",
    --         before_parse = function(ctx)
    --             print("from plugin : before_parse_2" .. ctx.file.name)
    --         end,
    --         before_emit = function(ctx)
    --             print("from plugin : before_emit_2" .. ctx.file.name)
    --         end,
    --         after_emit = function(ctx)
    --             print("from plugin : after_emit_2" .. ctx.file.name)
    --         end,
    --     }
    -- }
}
