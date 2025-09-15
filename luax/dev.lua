--
local watcher = require("luax.watcher.watch")
--
local cfg = {
    paths = { "./src", "./lib", "./luaxconfig.lua" },
    recursive = true,
    exec = "luajit luax/main.lua --verbose",
    ignore = { "./dist/_app.lua" }
}
watcher.new(cfg):on("start"):on("change"):run()
