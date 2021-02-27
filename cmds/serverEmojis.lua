local serverEmojis = commands 'serverEmojis' '[server/category]*'
serverEmojis.help = 'lists emojis in server\n'..
    'or in a default emoji category'
serverEmojis.flags = {
    {'tone',
    'changes skin tone for some emojis', 'NUMBER'},
    {'raw',
    'shows unicode emoji as they look on your system'}
}
serverEmojis.alias = {'serverEmoji', 'server-emojis', 'server-emoji', 'server_emoji', 'server_emojis'}

function serverEmojis:run(param, perms)
    local param, args = help.dashParse(param)
    param = param and param:lower()

    local tone = tonumber(args.t) and
        string.format('%x', 0x1F3FA + args.t)

    local guild = param and 
        (client:getGuild(param) or 
        help.shortcode.main[param == 'activities' and
        'activity' or param]) or self.guild

    if not perms.bot:has'embedLinks' then return nil, 'i need embed perms' end
    if not guild then return nil, 'guild needed' end

    local obj = class.isObject(guild)

    local nmax, vmax = 256, 1024
    local s = utf8.char(0x200B)

    local emojis
    if obj then
        emojis = table.copy(guild.emojis:toArray())
        table.sort(emojis, function(a,b)
            return help.alphasort(b.name:lower(), a.name:lower())
        end)
    else
        emojis = {}
        for i, e in pairs(guild) do 
            local diversity
            if e.hasDiversity and tone then
                for i, e in pairs(e.diversityChildren) do
                    if e.diversity[1] == tone then
                        table.insert(emojis, e.surrogates)
                        diversity = true
                        break
                    end
                end
            end
            if not diversity then
                table.insert(emojis, e.surrogates)
            end
        end
    end if #emojis == 0 then
        emojis[1] = e.zero
    end

    local per = 9
    local sep = ' '
    local rows = {}
    for i, e in pairs(emojis) do
        local n = math.floor((i - 1) / per) + 1

        if not rows[n] then
            rows[n] = ''
        end

        rows[n] = rows[n] .. 
        ((class.isObject(e) and
        "<%s:%s:%s>"%
        {e.animated and 'a' or '', '__', e.id}) or
        (tostring(e)))
        
        if (((i - 1) % per) + 1) ~= per then
            rows[n] = rows[n] .. sep
        end
    end

    local fields = {}

    local function generate(field, v, max)
        local raw = rows[1] and args.r and not obj
        local i = len(s) + (raw and 2 or 0)
        field[v] = {}
        while rows[1] do
            if ((#field[v]+1) <= math.floor(190 / per)) and
            (((i+len(rows[1]))+(#field[v])) <= max) then
                i = i+len(rows[1])
                table.insert(field[v], rows[1])
                table.remove(rows, 1)
            else
                break
            end
        end
        field[v] = string.format(raw and '`%s`' or '%s',
            table.concat(field[v], "\n")..s
        ) 
    end

    while rows[1] do
        local field = {}
        fields[#fields+1] = field

        generate(field, 'name', nmax)
        generate(field, 'value', vmax)
    end

    return help.embed(nil, {
        author = {
            name = obj and guild.name or 
            param:gsub('^.', string.upper), 
            icon_url = guild.iconURL
        },
        fields = fields,
    })
end