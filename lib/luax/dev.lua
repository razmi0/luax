--
local uv              = require("luv") -- hyperfine : libUv > lib lfs
local watcher         = require("watch")
--

local bundle_path     = "luajit lib/luax/bundle.lua"
local not_bundle_path = "luajit lib/luax/main.lua"

watcher.new({
    paths = { "./src" },
    recursive = true,
    exec = bundle_path,
    -- ignore = { "index.html" },
})
    :on("start")
    :on("change")
    :run()

uv.run()
