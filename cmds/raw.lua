local raw = commands 'raw' '[message]*'
raw.help = 'gets the raw JSON of a message'

function raw:run(param)
    local message = help.resolveMessage(self, param)

    local data, err = help.APIget(message.channel, message.id)

    return help.code(data and json.encode(data, {indent = true}) or err, 'json'),
    {safe = true}
end