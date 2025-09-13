local Fs = require("lib.luax.utils.fs")

---@class ToSSGConfig
---@field entry_path string
---@field out_path string|nil

---@param config ToSSGConfig
local function to_ssg(config)
    local fs = Fs.new()
    local luax_app = require(config.entry_path) -- App
    local rendered =
        "<!DOCTYPE html>" .. luax_app()
    if config.out_path then
        fs:write(config.out_path, rendered)
    end
    return rendered
end



return to_ssg
