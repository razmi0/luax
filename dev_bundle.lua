--
local uv = require("luv") -- hyperfine : libUv > lib lfs
--


require("watch").new({
    paths = { "./build" }, --  "./src", "./lib/luax", "./lib/luax/transpiler", "./lib/luax/utils"
    exec = "luajit bundle.lua build/main.lua build/_bundle.lua --rm-source --verbose",
    ignore = { "_bundle.lua" }
})
    :on("start")
    :on("change")
    :run()


uv.run()
