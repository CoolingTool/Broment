local calc = commands 'math' '[equation]'
calc.help = 'runs equation using lua'
calc.alias = {'calc', 'calculator'}

function calc:run(param)
    if not param then return nil, 'equation needed' end
    if param:find("function") then return nil, 'no' end

    local sandbox = setmetatable({
        math = math, bit = bit, F = F,
        utf8 = utf8, string = string,
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
                ret[i] = pp.dump(ret[i], nil, true)
            end

            return table.concat(ret, ', '), {safe = true}
        end
    end

end