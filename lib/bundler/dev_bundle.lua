--
local uv = require("luv") -- hyperfine : libUv > lib lfs
--


require("lib.watcher.watch").new({
    paths = { "./build" }, --  "./src", "./lib/luax", "./lib/luax/transpiler", "./lib/luax/utils"
    exec =
        "luajit lib/bundler/bundle.lua " ..
        "build/main.lua build/_bundle.lua " ..
        "--verbose",
    ignore = { "_bundle.lua" }
})
    :on("start")
    :on("change")
    :run()


uv.run()
