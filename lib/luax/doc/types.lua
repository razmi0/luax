---@class TranspilerConfig
---@field headers HeaderTranspilerConfig
---@field luax_file_extension string
---@field build BuildOptions
---@field root string                       -- path to luax files
---@field render_function_name string       -- the render function name
---@field render_function_path string       -- path to the render function
---@field plugins TranspilerPlugin[]|nil    -- plugins array
---@field alias { [string] : string }| nil  -- require("<alias>...") across luax files
---@field cmd CmdOptions

---@class CmdOptions
---@field flags { [string] : boolean }
---@field globals string[]
---@field rm_paths string[]

---@class PartialCmdOptions
---@field flags { [string] : boolean }|nil
---@field globals string[]|nil
---@field rm_paths string[]|nil

---@class PartialTranspilerConfig
---@field root string|nil
---@field build PartialBuildOptions
---@field render_function_name string|nil
---@field render_function_path string|nil
---@field plugins TranspilerPlugin[]|nil
---@field alias { [string] : string }|nil
---@field cmd PartialCmdOptions|nil

---@class HeaderTranspilerConfig
---@field enabled boolean
---@field transpiler_version string
---@field licence string
---@field author string
---@field repo_link string

---@class TranspilerPlugin
---@field before_parse fun(ctx : TranspilerContext)|nil
---@field before_emit fun(ctx : TranspilerContext)|nil
---@field after_emit fun(ctx : TranspilerContext)|nil
---@field name string

--- Context is an object holding the transpiler information per file.
--- parse and emitter method should mutate it.
---@class TranspilerContext
---@field file File
---@field config TranspilerConfig
---@field ast LuaxAstNode[]
---@field emitted string[]

---@class File
---@field name string
---@field content string

---@class LuaxAstNode
---@field lua string|nil
---@field fragment true|nil
---@field tag string|nil
---@field attrs table<{ [string] : { kind : "string"|"expr"|"bool", value : string } }>|nil
---@field text string|nil
---@field expr LuaxAstNode[]|nil
---@field children LuaxAstNode[]|nil

---@class BuildOptions
---@field bundle boolean
---@field root string
---@field out_dir string
---@field out_file string
---@field no_emit boolean
---@field target_file_extension string

---@class PartialBuildOptions
---@field bundle boolean|nil
---@field root string|nil
---@field out_file string|nil
---@field out_dir string|nil
---@field no_emit boolean|nil
---@field target_file_extension string|nil
