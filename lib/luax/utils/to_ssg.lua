local uv = require("luv")
local fs = require("lib.luax.utils.fs").new(uv)

---@class ToSSGConfig
---@field entry_path string
---@field out_path string|nil

---@param config ToSSGConfig
local function to_ssg(config)
    local luax_app = require(config.entry_path) -- App
    local rendered = [[
    <!DOCTYPE html>
        <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Document</title>
            </head>
            <body>
        ]]
        .. luax_app() ..
        [[
            </body>
        </html>
        ]]
    if config.out_path then
        fs:write(config.out_path, rendered)
    end
    return rendered
end

uv.run("once")

return to_ssg
