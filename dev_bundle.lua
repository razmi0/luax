--
local uv = require("luv") -- hyperfine : libUv > lib lfs
--


require("watch").new({
    paths = { "./src" }, --  "./src", "./lib/luax", "./lib/luax/transpiler", "./lib/luax/utils"
    exec = "luajit bundle.lua build/main.lua build/_bundle.lua",
    ignore = { "./lib/luax/bundle.lua", "index.html" }
})
    :on("start")
    :on("change")
    :run()


uv.run()
