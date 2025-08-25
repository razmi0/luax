local Fs = {}
Fs.__index = Fs

---@param uv userdata The main libuv instance that'll be run (Fs does not call uv.run())
function Fs.new(uv)
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

-- sync
function Fs:has_subdir(name)
    local handle = self.uv.fs_opendir(self.uv.cwd())
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

-- sync
function Fs:create_dir(name)
    if not self:has_subdir(name) then
        assert(self.uv.fs_mkdir(self.uv.cwd() .. "/" .. name, 493), "Failed creating folder, folder already exist")
    end
end

-- sync
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

return Fs
