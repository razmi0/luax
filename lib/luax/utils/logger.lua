-- logger.lua
local function Logger(config)
    local entries, max_cols = {}, 0

    ---@param node {name : string, path : string, weight : number}
    local function push(node)
        local prefix = "- "
        local suffix = config.suffix or "" -- e.g. ".lua"
        local strip = config.strip or (node.name .. suffix)

        local length = #prefix + #node.path + #suffix + 1
        if length > max_cols then max_cols = length end

        entries[#entries + 1] = function()
            local function trail()
                if node.weight == 0 then return prefix end
                return node.weight .. "K"
            end
            return string.format(
                "%s%s\27[38;5;250m%s\27[0m%s",
                prefix, node.path:gsub(strip, ""),
                node.name .. suffix,
                string.rep(".", max_cols - length) .. " " .. trail()
            )
        end
    end

    local head = function(mods)
        local action = config.action or "Processing"
        local source = config.source and config.source(config, mods) or "unknown"
        print(string.format(
            "%s %s modules %s",
            action,
            mods.count,
            source
        ))
    end

    local body = function()
        local flags = config.flags or {}
        if flags["--verbose"] or flags["--V"] then
            for _, fn in ipairs(entries) do print(fn()) end
        end
    end

    local footer = function(mods)
        print(string.format(
            "%s %sK",
            string.rep(".", max_cols - #tostring(mods.weight)),
            mods.weight
        )
        )
    end
    ---@param type "head"|"body"|"footer"
    local function log(type, mods)
        if type == "head" then
            head(mods)
        elseif type == "body" then
            body()
        elseif type == "footer" then
            footer(mods)
        end
    end

    return {
        push = push,
        log = log,
    }
end

return Logger
