--
local watcher = require("luax.watcher.watch")
--
local cfg = {
    paths = { "./test", "./luaxconfig.lua" },
    recursive = true,
    exec = "luajit luax/lx.lua --verbose",
    ignore = { "_app.lua" }
}

watcher.new(cfg)
    :on("start", function()
        print(require("test.build._app"))
    end)
    :on("change", function()
        print(require("test.build._app"))
    end)
    :run()
