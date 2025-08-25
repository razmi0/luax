local watch = require("lib.watch")

---@type WatcherConfig
local config = {
    paths = { "./", "./src" },
    exec = "luajit main.lua",
}

watch.new(config)
    :on("start")
    :on("error")
    :on("change")
    :run()
