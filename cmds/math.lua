local calc = commands 'math' '[equation]'
calc.help = 'runs equation using lua'
calc.alias = {'calc', 'calculator'}

local blacklist = {'"', "'", "[[", "]]", "{", "}", "function"}

function calc:run(param)
    if not param then return nil, 'equation needed' end
    local blacklisted = false
    for i, b in pairs(blacklist) do blacklisted = param:find(b, 1, true)
    if blacklisted then break end end
    if blacklisted then return nil, 'no' end

    local param = param:find("^9%s*+%s*10$") and '21' or param

    local sandbox = setmetatable({
        math = math, bit = bit, π = math.pi,
    },{__index = function(t, i)
        local ret = math[i] or bit[i]
        if not ret then
            return nil
        else
            return ret
        end 
    end})

    local f, err = load("return "..param, "math", 't', sandbox)

    if err then
        error(err, 0)
    else
        local ret = table.pack(f())

        if ret == 0 then 
            return nil, "no result"
        else
            for i = 1, ret.n do
                ret[i] = tostring(ret[i])
            end

            return help.code(table.concat(ret, ', '), 'py'), {safe = true}
        end
    end

end