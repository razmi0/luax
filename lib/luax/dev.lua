--
local watcher         = require("lib.watcher.watch")
--
local bundle_path     = "luajit lib/luax/_bundle.lua"
local not_bundle_path = "luajit lib/luax/transpiler/main.lua --verbose"

watcher.new({
    paths = { "./src", "./lib/luax" },
    recursive = true,
    exec = not_bundle_path,
    ignore = { "./lib/luax/_bundle.lua" }
})
    :on("start")
    :on("change")
    :run()
