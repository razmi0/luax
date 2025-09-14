local uv = require("luv")
local Fs = {}
Fs.__index = Fs

function Fs.new()
    return setmetatable({
        uv = uv
    }, Fs)
end

function Fs:list_files(path)
    local handle = self.uv.fs_opendir(path)
    if not handle then return {} end
    local files = {}
    while true do
        local batch = self.uv.fs_readdir(handle)
        if not batch then break end
        for _, e in ipairs(batch) do
            if e.type == "file" then
                files[#files + 1] = e.name
            end
        end
    end
    self.uv.fs_closedir(handle)
    return files
end

function Fs:list(path)
    local handle = self.uv.fs_opendir(path)
    if not handle then return {} end
    local elements = {}
    while true do
        local batch = self.uv.fs_readdir(handle)
        if not batch then break end
        for _, e in ipairs(batch) do
            elements[#elements + 1] = e
        end
    end
    self.uv.fs_closedir(handle)
    return elements
end

function Fs:clear(root)
    if not root then return end
    root = uv.cwd() .. "/" .. root

    --
    local dirs = {}
    local files = {}
    --
    local function explore(path)
        local handle = uv.fs_opendir(path) -- uv.cwd() .. "dist"
        if not handle then return end
        while true do
            local batch = uv.fs_readdir(handle)
            if not batch then
                uv.fs_closedir(handle)
                return
            end
            for _, e in ipairs(batch) do
                local new_path = path .. "/" .. e.name
                if e.type == "directory" then
                    table.insert(dirs, 1, new_path)
                    explore(new_path)
                elseif e.type == "file" then
                    files[#files + 1] = new_path
                end
            end
        end
    end
    --
    explore(root)
    --
    for _, path in ipairs(files) do
        local ok = uv.fs_unlink(path)
        if not ok then
            print("Could not delete file")
        end
    end
    for _, path in ipairs(dirs) do
        local ok = uv.fs_rmdir(path)
        if not ok then
            print("Could not delete folder")
        end
    end
end

-- sync
function Fs:has_subdir(path)
    path = path:gsub("/$", "")
    local up_path, name = path:match("^(.*)/([^/]+)$")
    if not up_path then
        up_path = "."
        name = path
    elseif up_path == "" then
        up_path = "/"
    end
    if name == "" then return false end
    local handle = self.uv.fs_opendir(up_path)
    if not handle then return false end
    while true do
        local batch = self.uv.fs_readdir(handle)
        if not batch then
            self.uv.fs_closedir(handle)
            return false
        end
        for _, e in ipairs(batch) do
            if e.name == name and e.type == "directory" then
                self.uv.fs_closedir(handle)
                return true
            end
        end
    end
end

function Fs:list_dir(path)
    local handle = self.uv.fs_opendir(self.uv.cwd() .. path)
    if not handle then return false end
    local dirs = {}
    while true do
        local batch = self.uv.fs_readdir(handle)
        if not batch then
            self.uv.fs_closedir(handle)
            return dirs
        end
        for _, e in ipairs(batch) do
            if e.type == "directory" then
                dirs[#dirs + 1] = e.name
            end
        end
    end
end

-- sync
function Fs:create_dir(path)
    if not self:has_subdir(path) then
        assert(self.uv.fs_mkdir(path, 493), "Failed creating folder, folder already exist")
    end
end

-- sync
---@return string
function Fs:read(path)
    local fd = assert(self.uv.fs_open(path, "r", 438))
    local stat = assert(self.uv.fs_fstat(fd))
    local content = assert(self.uv.fs_read(fd, stat.size, 0))
    assert(self.uv.fs_close(fd))
    return content
end

-- sync
function Fs:write(path, content)
    local fd = assert(self.uv.fs_open(path, "w", 420))
    assert(self.uv.fs_write(fd, content))
    assert(self.uv.fs_close(fd))
end

function Fs:find_in(path, string)
    local content = self:read(path)
    if content:match(string) then return true end
end

uv.run()

return Fs
