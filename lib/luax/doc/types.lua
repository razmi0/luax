---@class TranspilerConfig
---@field headers HeaderTranspilerConfig
---@field luax_file_extension string
---@field build { out_dir : string, no_emit : boolean, target_file_extension : string }
---@field root string                       -- path to luax files
---@field render_function_name string       -- the render function name
---@field render_function_path string       -- path to the render function
---@field plugins TranspilerPlugin[]|nil    -- plugins array
---@field alias { [string] : string }| nil  -- require("<alias>...") across luax files

---@class PartialTranspilerConfig
---@field root string|nil
---@field build { out_dir : string|nil, no_emit : boolean|nil, target_file_extension : string|nil }| nil -- path to transpiled directory
---@field render_function_name string|nil
---@field render_function_path string|nil
---@field plugins TranspilerPlugin[]|nil

---@class HeaderTranspilerConfig
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
