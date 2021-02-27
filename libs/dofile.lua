local path = require('path')
local fs = require('fs')
local makeModule = require('require')
local join = path.join
local resolve = path.resolve

return function(path, env)
    path = resolve(path)

    path = fs.lstatSync(path).type == 'directory'
           and join(path,'init.lua') or path

    local fn, err = loadfile(path)
    if not fn then error(err, 0) end

    local require, module = makeModule(path)

    env = env or {}
    env.module = module; env.require = require

    local sandbox = setmetatable(
        env,
        {__index = _G}
    )
    setfenv(fn, sandbox)
            
    local t = table.pack(pcall(fn))
    if not t[1] then error(t[2], 0) end

    return select(2, table.unpack(t))
end