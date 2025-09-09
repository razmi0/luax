--
local uv      = require("luv") -- hyperfine : libUv > lib lfs
local watcher = require("lib.luax.watcher.watch")
--

watcher.new({
    paths = { "./", }, --  "./src", "./lib/luax", "./lib/luax/transpiler", "./lib/luax/utils"
    exec = "luajit bundle.lua lib/luax/main.lua lib/luax/bundle.lua",
    ignore = { "./lib/luax/bundle.lua" }
})
    :on("start")
    :on("change")
    :run()

uv.run()
