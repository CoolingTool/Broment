local blue = commands 'blue' '[text]'
blue.help = 'turns text into blue using xml syntax highlighting'
blue.alias = 'twvm'

function blue:run(param)
    local message = help.resolveMessage(self, param, true)
    if message then
        param = message.content
    end

    return '>>> '..
        help.style.code(help.style.name(
        (param or 'sorry guy but text expected........')
    )), {safe = true}
end