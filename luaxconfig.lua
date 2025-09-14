---@type PartialTranspilerConfig
return {
    headers = {
        enabled = false
    },
    build = {
        bundle = true,
        root = "dist/main.lua",
        out_file = "dist/_app.lua",
        out_dir = "dist",
    },
    alias = {
        ["@:"] = "dist/"
    }

}
