local calc = commands 'math' '[equation]'
calc.help = 'runs equation using lua'
calc.alias = {'calc', 'calculator'}

function calc:run(param)
    if not param then return nil, 'equation needed' end
    
    self.channel:broadcastTyping()

    local data = help.fapi('rex', {
        text = F[[
            math.randomseed(os.time())
            setmetatable(math, {__index = bit})
            setmetatable(_G, {__index = math}) 
            print(${param})
        ]],
        language = 'lua'
     })
     data = (data:match("^[^:]+:[^:]+:[^:]+: ([^\n]+)") or data):trim()

    return help.truncate(data, 2000, '...'), {safe = true}
end