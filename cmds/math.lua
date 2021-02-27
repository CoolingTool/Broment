local calc = commands 'math' '[equation]'
calc.help = 'runs equation using lua'
calc.alias = {'calc', 'calculator'}

function calc:run(param)
    if not param then return nil, 'equation needed' end
    if param:find("function") then return nil, 'no' end

    local sandbox = setmetatable({},{__index = function(t, i)
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
                ret[i] = help.truncate(pp.dump(ret[i], nil, true), 20, '...')
            end

            return '>>> '..
            help.code(' '..table.concat(ret, ' | ')..' ', 'py'),
            {safe = true}
        end
    end

end