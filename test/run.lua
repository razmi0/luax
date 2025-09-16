--
local watcher = require("luax.watcher.watch")
local to_ssg = require("luax.utils.to_ssg")
--
local cfg = {
    paths = { "./test", "./luaxconfig.lua" },
    recursive = true,
    exec = "luajit luax/lx.lua --verbose",
    ignore = { "_app.lua" }
}

local html = function()
    print(require("test.build._app")())
end
watcher.new(cfg):on("start", html):on("change", html):run()
