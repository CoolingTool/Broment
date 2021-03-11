local calc = commands 'math' '[equation]'
calc.help = 'runs equation using lua'
calc.alias = {'calc', 'calculator'}

local blacklist = {'"', "'", "[[", "]]", "{", "}", "function"}

function calc:run(param)
    if not param then return nil, 'equation needed' end
    
    local wait = help.wait(self, 'calculating...')

    return help.truncate(help.fapi('rex', {
        text = F[[print( ${param} )]],
        language = 'lua'
     }), 2000, '...'), {safe = true, remove = wait}
end