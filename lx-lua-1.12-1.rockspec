package = "lx-lua"
version = "1.12-1"
source = {
   url = "git+https://github.com/razmi0/luax.git",
   branch = "main"
}
description = {
   summary = "jsx in lua transpiler",
   detailed = "dev",
   homepage = "https://github.com/razmi0/luax",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1",
   "luv",
   "inspect",
   "lpeg"
   }
build = {
   type = "builtin",
   modules = {
      ["luax.render"] = "luax/render.lua",
      ["luax.utils.to_ssg"] = "luax/utils/to_ssg.lua",
      ["luax.watcher.watch"] = "luax/watcher/watch.lua",
      ["luax.lx"] = "luax/lx.lua"
   }
}
