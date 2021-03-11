local reverse = commands 'reverse' '[text/message]'
reverse.help = 'reverses order of words'
reverse.flags = {
    {'char',
    'reverse by each character instead'},
}

local pattern = '[%a%\']+'

function reverse:run(param)
    local param, args = help.dashParse(param)

    local message = help.resolveMessage(self, param, true)
    if message then
        param = message.content
    end

    if args.c then
        if not param then return '........dedeen txet tub yug yrros' end

        local chars = {}
        for p, c in utf8.codes(param) do
            table.insert(chars, utf8.char(c))
        end
        table.reverse(chars)

        return table.concat(chars), {safe = true}
    else
        if not param then return 'needed text but guy sorry........' end

        local words = {}
        for w in param:gmatch(pattern) do
            table.insert(words, w)
        end
        table.reverse(words)
    
        return param:gsub(pattern, function()
            return table.remove(words, 1)
        end), {safe = true}
    end
end