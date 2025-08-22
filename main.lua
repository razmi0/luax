--
local uv = require("luv") -- hyperfine : lib uv > lfs
local fs = require("lib.fs").new(uv)
local lpeg = require("lpeg")
local inspect = require("inspect")
--
local SRC_PATH = "src"
local BUILD_PATH = "build"
local TRANSPILED_FILE_EXTENSION = ".luax"
--
local function transpile(content)

end
--
if not fs:has_subdir(SRC_PATH) then return end
fs:create_dir(BUILD_PATH)
local files = fs:list_files(SRC_PATH)

for _, file in ipairs(files) do
    if file:sub(-5) == TRANSPILED_FILE_EXTENSION then
        local content = fs:read(SRC_PATH .. "/" .. file)
        local target_file_name = file:sub(1, #file - 1)
        local transpiled = transpile(content)
        fs:write(BUILD_PATH .. "/" .. target_file_name, content)
    end
end


uv.run()


--#region components
-- function Loop()
--     local _var = {"Hello", "world"}
--     return (
--         <div>{_var.ipairs(function(i,w)
--             return <div>{w}</div>
--          end)}
--         </div>
--     )
-- end

-- function Parent(props)
--     return (
--         <div>{props.children}</div>
--     )
-- end

-- function Composed()
--     return (
--         <Parent>
--             <Litteral />
--             <Loop />
--         </Parent>
--     )
-- end
--#endregion
