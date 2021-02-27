local commands = {}

local meta = {__index = {}}
        
function meta.__index:find(query)
    local ret = self[query]

    if ret then return ret end

    for _, cmd in pairs(self) do
        local alias = cmd.alias
        if alias then
            if type(alias) == 'string' then
                ret = alias:lower() == query and cmd
            else
                for _, v in pairs(alias) do
                    ret = v:lower() == query and cmd
                    if ret then break end
                end
            end
            if ret then return ret end
        end
    end
end

local function setParamCmd(cmd, param)
    cmd.param = param
    return cmd
end

function meta:__call(cmd)
    local lower = cmd:lower()
    local tbl = setmetatable({},{__call = setParamCmd})
    self[lower] = tbl
    tbl.name = cmd
    tbl.index = lower
    return tbl
end

setmetatable(commands, meta)

return commands