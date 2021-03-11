local sort = commands 'sort' '[text/message]'
sort.help = 'sorts text'

local pattern = '[%a%\']+'

function sort:run(param)
    local message = help.resolveMessage(self, param, true)
    if message then
        param = message.content
    end

    if not param then return 'but guy needed sorry text........' end

    local words = {}
    for w in param:gmatch(pattern) do
        table.insert(words, w)
    end
    table.sort(words, function(a, b) return help.alphasort(a:upper(), b:upper()) end)

    return param:gsub(pattern, function()
        return table.remove(words, 1)
    end), {safe = true}
end