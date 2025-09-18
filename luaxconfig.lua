---@type PartialTranspilerConfig

return {
    base = "test",
    root = "src",
    headers = {
        enabled = false
    },
    build = {
        root_file = "main.lua",
        out_file = "_app.lua",
        out_dir = "build",
    },
    alias = {
        ["@"] = "test/build"
    }

}
