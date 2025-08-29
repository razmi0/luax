local uv = require("luv")
local fs = require("lib.luax.utils.fs").new(uv)

local function renderer(render_function)
    return [[
    <!DOCTYPE html>
        <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Document</title>
            </head>
            <body>
        ]]
        .. render_function() ..
        [[
            </body>
        </html>
        ]]
end

---@class ToSSGConfig
---@field entry_path string
---@field out_path string

---@param config ToSSGConfig
local function to_ssg(config)
    local luax_app = require(config.entry_path) -- App
    local page = renderer(luax_app)
    fs:write(config.out_path or "index.html", page)
    uv.run("once")
end

return to_ssg
