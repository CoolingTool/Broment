local stats = commands 'stats'
stats.flags = {help.textFlag}
stats.alias = {'ping', 'uptime', 'memory'}
stats.help = 'shows some statistics about da bot'

function stats:run(param, perms)
    local param, args = help.dashParse(param)
    local uname = uv.os_uname()

    local msg = self:reply('Calculating Latency....')

    local latency = math.round(date.fromSeconds(date.parseSnowflake(msg.id) - date.parseSnowflake(self.id)):toMilliseconds())

    local fields = help.style.multiLine..help.style.groupFormat{
        {   name = 'Memory Usage',
            help = '%.2f MB'%{collectgarbage('count')/1024}},
        {   name = 'Uptime',
            help = time.fromSeconds(os.clock()):toString()},
        {   name = 'Host',
            help = '%s %s (%s)'%{uname.sysname, uname.release, jit.arch}},
        {   name = 'Library',
            help = 'Discordia %s'%{discordia.package.version}},
        {   name = 'Luvit Version',
            help = require('bundle://package').version},
        {   name = 'Latency',
            help = latency..'ms'},
        {   name = 'API Latency',
            help = math.round(apiPing)..'ms'},
    }

    if args.t or not perms.bot:has'embedLinks' then
        assert(msg:update{content = help.textEmbed("Statistics", fields)})
    else
        assert(msg:update(help.embed("Statistics", {description = fields})))
    end
end