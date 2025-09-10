--
local uv              = require("luv") -- hyperfine : libUv > lib lfs
local watcher         = require("lib.watcher.watch")
--

local bundle_path     = "luajit lib/luax/_bundle.lua"
local not_bundle_path = "luajit lib/luax/transpiler/main.lua"

watcher.new({
    paths = { "./src" },
    recursive = true,
    exec = bundle_path,
})
    :on("start")
    :on("change")
    :run()

uv.run()
