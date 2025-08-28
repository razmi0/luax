--
local uv      = require("luv") -- hyperfine : libUv > lib lfs
local watcher = require("lib.luax.watcher.watch")
--

watcher.new({
    paths = { "./", "./src" },
    exec = "luajit lib/luax/main.lua",
    ignore = { "index.html" },
})
    :on("start")
    :on("change")
    :run()

uv.run()
