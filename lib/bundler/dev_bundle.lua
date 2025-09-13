require("lib.watcher.watch").new({
    paths = { "./build" },
    recursive = true,
    exec =
        "luajit lib/bundler/bundle.lua " ..    -- runtime rerunning file
        "build/main.lua build/_bundle.lua " .. -- entry point  out point
        "--V --R build",                       --verbose remove source
    ignore = { "_bundle.lua" }
})
    :on("error", function(err, filename)
        print(err, filename)
    end)
    :on("start")
    :on("change")
    :run()
