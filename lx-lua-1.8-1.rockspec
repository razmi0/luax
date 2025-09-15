package = "lx-lua"
version = "1.8-1"
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
      ["luax.bundle"] = "luax/bundle.lua",
      ["luax.dev"] = "luax/dev.lua",
      ["luax.doc.types"] = "luax/doc/types.lua",
      ["luax.transpiler.build"] = "luax/transpiler/build.lua",
      ["luax.transpiler.define_config"] = "luax/transpiler/define_config.lua",
      ["luax.transpiler.emit"] = "luax/transpiler/emit.lua",
      ["luax.transpiler.emitter"] = "luax/transpiler/emitter.lua",
      ["luax.transpiler.luax_helpers"] = "luax/transpiler/luax_helpers.lua",
      ["luax.main"] = "luax/main.lua",
      ["luax.transpiler.parser"] = "luax/transpiler/parser.lua",
      ["luax.render"] = "luax/render.lua",
      ["luax.transpiler.transpile"] = "luax/transpiler/transpile.lua",
      ["luax.utils.deep_merge"] = "luax/utils/deep_merge.lua",
      ["luax.utils.format_header"] = "luax/utils/format_header.lua",
      ["luax.utils.fs"] = "luax/utils/fs.lua",
      ["luax.utils.logger"] = "luax/utils/logger.lua",
      ["luax.utils.normalize_path"] = "luax/utils/normalize_path.lua",
      ["luax.utils.sort_aliases"] = "luax/utils/sort_aliases.lua",
      ["luax.utils.to_ssg"] = "luax/utils/to_ssg.lua",
      ["luax.watcher.watch"] = "luax/watcher/watch.lua"
   }
}
