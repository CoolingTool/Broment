local sonic = commands 'sonic' '[text]'
sonic.help = 'says thing as sonic'

function sonic:run(param, perms)
    if not param then return nil, 'text needed' end
    if not perms.bot:has'attachFiles' then return nil, 'i need image perms' end

    local wait = help.wait(self, 'please wait...')

    return {file = {'sonic.jpeg', help.fapi('sonic', param)}}, {remove = wait}
end