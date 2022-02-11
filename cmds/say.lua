local say = commands 'say' '[text]*'
say.alias = {'echo', 'reply'}
say.help = 'replies back with the text you put in'

function say:run(param)
    return param or '', {safe = true}
end