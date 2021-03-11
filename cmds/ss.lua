local ss = commands 'ss' '[url]'
ss.help = 'screenshot a site for when notsobot is down'
ss.alias = 'screenshot'

function ss:run(param, perms)
    if not param then return nil, 'site needed' end
    if not perms.bot:has'attachFiles' then return nil, 'i need image perms' end

    local wait = self:reply('please wait...')
    self.channel:broadcastTyping()

    return {file = {'ss.png', help.fapi('screenshot', param)}}, {remove = wait}
end