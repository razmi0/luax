--
local watcher = require("lib.watcher.watch")
--
local cfg = {
    paths = { "./src", "./lib", "./luaxconfig.lua" },
    recursive = true,
    exec = "luajit lib/luax/transpiler/main.lua --verbose",
    ignore = { "./dist/_app.lua" }
}
watcher.new(cfg):on("start"):on("change"):run()

print("hello")
