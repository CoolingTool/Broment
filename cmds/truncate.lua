local truncate = commands 'truncate' '[message] / [file]'
truncate.help = 'shortens message.txt for when you paste something more than 2000'

function truncate:run(param)
    local msg = help.resolveMessage(self, param)

    local url = msg.attachment and msg.attachment.url:find(".txt$") and msg.attachment.url  
    if not url then return nil, 'txt needed' end

    local succ, res, source = pcall(http.request, "GET", url, nil, nil, 10000)
    assert(succ, res)

    if not len(source) then return nil, 'malformed utf8' end

    return help.truncate(
        source,
        2000,
        '...'
    ), {safe = true}
end