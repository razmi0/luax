--
local watcher = require("luax.watcher.watch")
--
local cfg = {
    paths = { "./luax", "./luaxconfig.lua" },
    recursive = true,
    exec = "luajit build-project.lua",
    ignore = { "lx.lua" }
}
watcher.new(cfg):on("start"):on("change"):run()
