--[[ variables ]]
    local discordia = require('discordia')
    local client = discordia.Client{cacheAllMembers = true, logFile = '', logLevel = 0}
    local time = discordia.Time
    local date = discordia.Date
    local class = discordia.class
    local classes = class.classes
    local color = discordia.Color
    local API = client._api
    local enum = discordia.enums
    local logger = discordia.Logger(enum.logLevel.debug, '%F %T', '')
    local log = function(...)
        logger:log(...)
    end

    local requireDiscordia = require('require')(select(2, module:resolve('discordia')))
    local resolver = requireDiscordia('client/Resolver')
    
    discordia.extensions()
    require('%{format}')()

    local http = require('coro-http')
    local fs = require('fs')
    local path = require('path')
    local url = require('url')    
    local json = require('json')
    local timer = require('timer')
    local pp = require('pretty-print')
    local uv = require('uv')
    local spawn = require('coro-spawn')
    local lpeg = require('lpeg')
    local lip = require('LIP')
    local dofile = require('dofile')
    local len = utf8.len

    local defaultColor = color.fromRGB(38, 101, 144)
    local config = lip.load('config.ini')

    for i, p in pairs(config.paths) do
        local new = p:gsub("%%([^%%]+)%%", process.env)
        config.paths[i] = path.resolve(new)
    end

    local games = {}

    for g in io.lines('misc/games.txt') do
        table.insert(games, g)
    end

    local variables = { -- update when new variable added -- }
        requireDiscordia = requireDiscordia, module = module,
        resolver = resolver, time = time, class = class, color = color,
        path = path, lpeg = lpeg, timer = timer, json = json,
        fs = fs, http = http, url = url, API = API, pp = pp,
        client = client, uv = uv, date = date, enum = enum, dofile = dofile,
        discordia = discordia, classes = classes, len = len,
        defaultColor = defaultColor, require = require, lip = lip,
        logger = logger, log = log, config = config, spawn = spawn,
        games = games,} variables.variables = variables 

    local help = dofile('libs/help.lua', variables)
    variables.help = help
    local e = variables.e

    local bot, prefixes, custom, appInfo, commands, apiPing
    client:once('ready', function()
        bot = client.user
        prefixes = {
            '<@%s>'%{bot.id},
            '<@!%s>'%{bot.id},
        }
        apiPing = 0/0
        custom = {}
        config.discord.emoji_server_id = config.discord.emoji_server_id:match'^"(.-)"$'
        local emojiServer = client:getGuild(config.discord.emoji_server_id)
        if emojiServer then
            for i, e in pairs(emojiServer.emojis) do
                custom[e.name] = e
            end
        end
        appInfo = client:getApplicationInformation()
        variables.custom = custom; variables.bot = bot; variables.apiPing = apiPing
        variables.prefixes = prefixes; variables.appInfo = appInfo

        log(enum.logLevel.info,
            "Successfully started with %s users in %s servers.",
            table.count(client._users), table.count(client.guilds)
        )

        timer.setInterval(10000, function()
            coroutine.wrap(client.setGame)(client, games[math.random(#games)])
        end)
    end)
--[[ commands ]]
    commands = {} do
    variables.commands = commands
    --[[ meta (not a command) ]]
        local meta = {__index = {}}
        
        function meta.__index:find(query)
            local ret = self[query]

            if ret then return ret end

            for _, cmd in pairs(self) do
                local alias = cmd.alias
                if alias then
                    if type(alias) == 'string' then
                        ret = alias:lower() == query and cmd
                    else
                        for _, v in pairs(alias) do
                            ret = v:lower() == query and cmd
                            if ret then break end
                        end
                    end
                    if ret then return ret end
                end
            end
        end

        local function setParamCmd(cmd, param)
            cmd.param = param
            return cmd
        end

        function meta:__call(cmd)
            local lower = cmd:lower()
            local tbl = setmetatable({},{__call = setParamCmd})
            self[lower] = tbl
            tbl.name = cmd
            tbl.index = lower
            return tbl
        end

        setmetatable(commands, meta)
    --[[ say ]]
        local say = commands 'say' '[text]*'
        say.alias = {'echo', 'reply'}
        say.help = 'replies back with the text you put in'

        function say:run(param)
            return help.boolNil(param or ''), 
                help.boolNil(param and {safe = true})
        end
    --[[ exec ]]
        local Exec = commands 'exec'
        Exec.alias = 'eval'
        Exec.hidden = true

        function Exec:run(param)
            if self.author.id ~= client.owner.id then
                return nil, 'you can\'t use this command'
            end

            if not param then return nil, 'need code' end

            param = param:match('^```.-\n(.+)\n?```$') or param 

            local out = ''

            local sandbox = table.copy(variables)

            sandbox.self = self
            sandbox.param = param
            sandbox.io = table.copy(io)

            function sandbox.print(...) out = out .. help.printLine(...) end
            function sandbox.p(...) out = out .. help.prettyLine(...) end
            function sandbox.io.write(...) out = out .. table.concat{...} end
                
            setmetatable(sandbox,{__index=_G})

            local f, err = load(param, "exec", 't', sandbox)

            local stored
            if err then
                error(err, 0)
            else
                stored = table.pack(f())
            end

            out = out:gsub(' *\n','\n')

            if #out > 0 then
                local form = '>>> `%s`'
                local msgLimit = 2000 - (len(form) - 2)
                local rep = math.ceil(len(out) / msgLimit)
                for i = 1, rep do 
                    assert(help.APIsend(self.channel, {content = form%{help.codeEsc(out:sub(msgLimit * (i - 1) + 1, msgLimit * i))}, allowed_mentions = {parse = {}}}))
                end
            end

            return table.unpack(stored)
        end
    --[[ error ]]
        local Error = commands 'error' '[command]*; [error]*'
        Error.help = "you talk a lotta big game for someone with such a small truck"
        Error.hidden = true

        function Error:run(param)
            local cmd, err = help.split(param)
            return string.format(
                'sorry guy there was a error when running command `%s`\n%s',
                cmd, help.code(help.concat"\n"(err, debug.traceback()),'rs')
            ), {safe = true}
        end
    --[[ sorry ]]
        local Sorry = commands 'sorry' '[text]*'
        Sorry.help = "stupid horse, i just fell out of the porsche"
        Sorry.hidden = true

        function Sorry:run(param)
            return string.format(
                'sorry guy but %s........',
                param
            ), {safe = true}
        end
    --[[ o ]]
        local O = commands 'o' '[o] [o]'
        O.alias = {}
        for _o = 1, 32 do
            table.insert(O.alias, 'o')
        end
        O.help = 'o'
        O.hidden = true

        local list = {'.', '!', '?', ',', ''}

        function O:run(param)
            return 'o' .. list[math.random(#list)], {safe = true}
        end
    --[[ lavadrop ]]
        local Lavadrop = commands 'lavadrop'
        Lavadrop.superDuperHidden = true

        function Lavadrop:run(param, perms)
            if perms.bot:has'embedLinks' then
                return {
                    embed = {
                        title = "__**Incorrect usage**__",
                        color = 0xff0056,
                        fields = {{
                            name = "Correct Usage:",
                            value = "lava help <command>(optional)"
                        }},
                        description = "**That's not a valid command**"
                    }
                }
            end
        end
    --[[ stats ]]
        local Stats = commands 'stats'
        Stats.flags = {help.textFlag}
        Stats.alias = {'ping', 'uptime', 'memory'}
        Stats.help = 'shows some statistics about da bot'

        function Stats:run(param, perms)
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
                    help = '%s %s (%s)'%{uname.version, uname.release, jit.arch}},
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
    --[[ raw ]]
        local Raw = commands 'raw' '[message]*'
        Raw.help = 'gets the raw JSON of a message'

        function Raw:run(param)
            local message = help.resolveMessage(self, param)

            local data, err = help.APIget(message.channel, message.id)

            return help.code(data and json.encode(data, {indent = true}) or err, 'json'),
            {safe = true}
        end
    --[[ sticker ]]
        local Sticker = commands 'sticker' '[message]'
        Sticker.alias = {'stealSticker', 'stickerSteal', 'getSticker', 's'}
        Sticker.help = 'gets sticker and converts it to gif'

        local format = {
            --type 1 is just a normal png but link is unknown
            [2] = {'https://media.discordapp.net/stickers/','.png', help.apng2gif},
            [3] = {'https://discord.com/stickers/','.json', help.lottie2gif}
        }

        function Sticker:run(param, perms)
            local message = help.resolveMessage(self, param, true)
            if not message then
                return nil, 'need a valid message to steal sticker'
            end
            if not perms.bot:has'attachFiles' then return nil, 'i need image perms' end
            
            local data = help.APIget(message.channel, message.id)
            local stickers = data.stickers

            if stickers then
                local wait = self:reply("this might take a minute")
                self.channel:broadcastTyping()
                local sticker = select(2, next(stickers))
                local known = format[sticker.format_type]
                if known then
                    local link = known[1]..help.concat"/"(sticker.id, sticker.asset)..known[2]
                    
                    local succ, res, source = pcall(http.request, 'GET', link)

                    local result = known[3](source)
                    wait:delete()
                    
                    return {
                        content = '<'..link..'>',
                        file = {'%s.gif'%{sticker.name}, result}
                    }
                else
                    return nil, 'i don\'t know how to get the link of this sticker'
                end
            else
                return nil, 'that message doesn\'t contain a sticker'
            end
        end
    --[[ help ]]
        local Help = commands 'help' '[command]*'
        Help.flags = {help.textFlag}
        Help.alias = {'commands', 'cmd', 'command', 'cmds', 'h', 'helper'}
        Help.help = 'gets a list of commands'
        
        local ignore = {
            name = true, run = true, help = true,
            param = true, alias = true, index = true
        }

        function Help:run(param, perms)
            local param, args = help.dashParse(param)

            if math.random(1,100) <= 1 then
                return "Your BotGhost premium trial has expired! Please visit https://www.botghost.com/ for more information"
            end

            local tip, list, list2, rows
            local title, title2
            if param then --get command
                local param = param:lower()
                local cmd = commands:find(param)
                if (not cmd) or cmd.superDuperHidden then return param..' is not a command', {safe = true} end

                local aliases = {}
                if type(cmd.alias) == 'string' then
                    aliases[1] = cmd.alias
                elseif cmd.alias then
                    for i, a in pairs(cmd.alias) do
                        table.insert(aliases, a)
                    end
                else
                    aliases[1] = 'None'
                end
                table.sort(aliases)

                rows = help.rowConcat"> <"(aliases)

                tip = help.style.format(cmd)

                title =  '<!--Aliases-->\n'
                list =  help.style.name(table.concat(rows, "\n", 1, math.ceil(#rows / 2)))
                title2 = '<!--       -->\n'
                list2 = help.style.name(table.concat(rows, "\n", math.ceil(#rows / 2) + 1, #rows))
            else --get commands
                local main = {}
                for i, c in pairs(commands) do
                    if (not c.hidden) and (not c.superDuperHidden) then
                        table.insert(main, c.name)
                    end
                end
                table.sort(main)

                rows = help.rowConcat("> <")(main)
                
                tip = help.style.help('Get info on a command\n'..
                    'by running help [cmd]')

                title =  '<!--Commands-->\n'
                list = help.style.name(table.concat(rows, "\n", 1, math.ceil(#rows / 2)))
                title2 = '<!--        -->\n'
                list2 = help.style.name(table.concat(rows, "\n", math.ceil(#rows / 2) + 1, #rows))
            end

            if args.t or not perms.bot:has'embedLinks' then
                return help.textEmbed("Commands",
                    help.style.line..'\n'..
                    help.style.code(
                        tip..'\n\n'..

                        title..list..'\n'..list2
                    )
                ), {safe = true}
            else
                return help.embed("Commands", {
                    description = help.style.multiLine..help.style.code(tip),
                    fields = {
                        {name = help.style.multiLine, value = help.style.code(title..list), inline = true},
                        {name = help.style.multiLine, value = help.style.code(title2..help.linePad(list2, math.ceil(#rows / 2))), inline = true},
                    }
                })
            end
        end
    --[[ emote ]]
        local Emote = commands 'emote' '[emoji]'
        Emote.alias = {'enlarge', 'emoji', 'e', 'em', 'hugeemoji', 'hugemoji'}
        Emote.help = 'posts the image of the emoji you put in'

        function Emote:run(param, perms)
            if not param then return nil, 'emoji needed' end
            if not perms.bot:has'attachFiles'then return nil, 'i need image perms' end

            local query = param

            self.channel:broadcastTyping()

            local a, custom, id = query:match'^<(a?):(.+):(%d+)>$'

            id = tonumber(query) and query or id

            local filename, source, link, show
            if id then
                local ext = a == '' and '.png' or '.gif'
                
                if not a then
                    local success, res, ret = pcall(http.request, 'HEAD', 'https://cdn.discordapp.com/emojis/%s.gif'%{id})

                    if res.reason ~= "OK" then 
                        local success, res, ret = pcall(http.request, 'HEAD', 'https://cdn.discordapp.com/emojis/%s.png'%{id})
                    
                        if not success then return nil, 'had an oopsie' end
                        if res.reason ~= "OK" then return nil, 'not an emoji' end
                    end

                    custom, ext = id, res.reason ~= "OK" and ".png" or ".gif"
                end

                link = 'https://cdn.discordapp.com/emojis/%s%s'%{id, ext}
            else
                local success, res, svgSource
                for i = 1, 2 do
                    if i == 2 then 
                        query = e[query]
                        if not query then return nil, 'not an emoji' end 
                    end
                    link = help.twemoji(query, {size = 'svg', ext = '.svg'})

                    success, res, svgSource = pcall(http.request, 'GET', link)

                    if not success then return nil, 'had an oopsie' end
                    if res.code == 200 then break end
                end
                
                filename, source = 'emoji.png', help.svg2png(svgSource, 512, 512)
            end
            return {
                content = (filename and '<'..link..'>' or link)..' _ _',
                file = help.boolNil(filename and {filename, source})
            }
        end
    --[[ math ]]
        local Math = commands 'math' '[equation]'
        Math.help = 'runs equation using lua'
        Math.alias = {'calc', 'calculator'}
        
        function Math:run(param)
            if not param then return nil, 'equation needed' end
            if param:find("function") then return nil, 'no' end

            local sandbox = setmetatable({},{__index = function(t, i)
                local ret = math[i] or bit[i]
                if not ret then
                    return nil
                else
                    return ret
                end 
            end})

            local f, err = load("return "..param, "math", 't', sandbox)

            if err then
                error(err, 0)
            else
                local ret = table.pack(f())

                if ret == 0 then 
                    return nil, "no result"
                else
                    for i = 1, ret.n do
                        ret[i] = help.truncate(pp.dump(ret[i], nil, true), 20, '...')
                    end

                    return '>>> '..
                    help.code(' '..table.concat(ret, ' | ')..' ', 'py'),
                    {safe = true}
                end
            end

        end
    --[[ boyfriend ]]
        local Boyfriend = commands 'boyfriend' '[text]'
        Boyfriend.help = "aa-ba bop skda baap-aa skde be-bap baap-bop-bep\n"..
            "(converts text to friday night funkin gibberish)"
            Boyfriend.alias = {'bf', 'fnf', 'funkin'}

        local dialog = {
            "ee", "oo", "aa",
            "be", "bo", "ba",
            "de", "do", "da",
            "pe", "po", "pa",
            "bep", "bop", "bap",
            "beep", "boop", "baap",
            "skde", "skdo", "skda",
        }

        function Boyfriend:run(param)
            if not param then
                return "aa-bap skde aa beep skda-bep........ (sorry guy but text needed........)"
            end

            return string.gsub(param, "%a+", function(word)
                local word = word:lower()

                local syll = help.countSyllables(word)

                if syll > 0 then
                    local n = help.text2decimal(word)

                    math.randomseed(n)

                    local ret = {}
                    for i = 1, syll do
                        ret[#ret+1] = dialog[math.random(#dialog)]
                    end

                    return table.concat(ret, "-")
                else
                    return word
                end
            end)
        end
    --[[ serverEmojis ]]
        local ServerEmojis = commands 'serverEmojis' '[server/category]*'
        ServerEmojis.help = 'lists emojis in server\n'..
            'or in a default emoji category'
        ServerEmojis.flags = {
            {'tone',
            'changes skin tone for some emojis', 'NUMBER'},
            {'raw',
            'shows unicode emoji as they look on your system'}
        }
        ServerEmojis.alias = {'serverEmoji', 'server-emojis', 'server-emoji', 'server_emoji', 'server_emojis'}

        function ServerEmojis:run(param, perms)
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
    --[[ truncate ]]
        local Truncate = commands 'truncate' '[message] / [file]'
        Truncate.help = 'shortens message.txt for when you paste something more than 2000'

        function Truncate:run(param)
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
    --[[ bro ]]
        local Bro = commands 'bro' '[p1]; [p2]'
        Bro.help = 'tests how much of bros two people are'
        Bro.flags = {
            help.textFlag
        }
        Bro.alias = 'bromometer'

        local icons = {
            e.bust_in_silhouette,
            e.speaking_head,
            e.busts_in_silhouette,
            e.people_hugging,
        }

        function Bro:run(param, perms)
            local param, args = help.dashParse(param)
            local p1, p2 = help.split(param)

            if (not p1) then p1 = self.author.id end
            if (not p2) and self.guild then p2 = 'random' end 

            if not p2 then
                return nil, '`[p2]` expected'
            end

            p1 = help.resolveUser(self, p1, true, .75) or p1
            p2 = help.resolveUser(self, p2, true, .75) or p2

            math.randomseed(
                (class.isObject(p1) and p1.id or help.text2decimal(p1:lower()))
                +
                (class.isObject(p2) and p2.id or help.text2decimal(p2:lower()))
                +
                (os.date('%H'))
            )

            math.random(); math.random(); math.random(); 

            local n = math.random(100)
            local p = math.round(n / 10)

            local title =
                e.people_hugging..
                ' **BROMOMETER** '..
                e.people_hugging..'\n'..

                e.small_blue_diamond..
                (class.isObject(p1) and help.getNick(p1, self.channel) or p1)..'\n'..
                e.small_blue_diamond..
                (class.isObject(p2) and help.getNick(p2, self.channel) or p2)

            local desc = 
                '**'..n..'%'..'** '..
                e.blue_square:rep(p)..
                e.black_large_square:rep(10 - p)

            local icon = icons[math.ceil(n / 25)]

            if args.t or not perms.bot:has'embedLinks' then
                return '>>> '..title..'\n'..desc..' '..icon,
                {safe = true}
            else
                return help.embed(nil, {
                    title = title,
                    description = desc,
                    thumbnail = {url = help.twemoji(icon)},
                    author = {},
                })
            end
        end
    --[[ avatar ]]
        local Avatar = commands 'avatar' '[user]*'
        Avatar.help = 'fetches users avatar link for you'
        Avatar.alias = {'avater', 'pfp', 'profilePicture', 'profile-picture', 'profile_picture', 'icon'}
        Avatar.flags = {
            {'default',
            'shows default avatar'},
            {'size',
            'changes image size (16 - 4096)', 'NUMBER'}
        }

        function Avatar:run(...)
            local param, args = help.dashParse(...)

            local user = help.resolveUser(self, param)

            local size = tonumber(args.s) and 
                math.clamp(
                    math.pow(2, math.ceil(math.log(args.s)/math.log(2))),
                    16, 4096
                ) or 1024

            return (args.d and 
                user:getDefaultAvatarURL(size) or
                user:getAvatarURL(size))
                ..' _ _',
                {safe = true}
        end
    --[[ blue ]]
        local Blue = commands 'blue' '[text]'
        Blue.help = 'turns text into blue using xml syntax highlighting'
        Blue.alias = 'twvm'

        function Blue:run(param)
            return '>>> '..
                help.style.code(help.style.name(
                (param or 'sorry guy but text expected........')
            )), {safe = true}
        end
    --[[ ytRNG ]]
        local ytRNG = commands 'ytRNG'
        ytRNG.help = 'scrapes random youtube video from petittube.com'
        ytRNG.alias = {'petittube', 'yt-rng', 'yt_rng'}

        function ytRNG:run()
            self.channel:broadcastTyping()
            
            local succ, body, res = pcall(http.request, "GET", "https://petittube.com/" )

            return 'http://youtu.be/'..
            res:match("https://www%.youtube%.com/embed/([^?]+)?")
        end
    --[[ saxophone ]]
        local Saxophone = commands 'saxophone' '[emoji]*'
        Saxophone.help = 'puts an animal infront of a '..e.saxophone
        Saxophone.alias = {'sax', 'saxo'}

        local list = {
            e.monkey, e.bird, e.baby_chick,
            e.duck, e.dodo, e.eagel, e.bug,
            e.snail, e.ant, e.cricket, e.snake,
            e.lizard, e.shrimp, e.blowfish,
            e.seal, e.dolphin, e.shark, e.bison,
            e.dromedary_camel, e.camel, e.giraffe,
            e.kangaroo, e.water_buffalo, e.ox,
            e.cow2, e.racehorse, e.pig2, e.ram,
            e.llama, e.goat, e.dog2, e.poodle,
            e.guide_dog, e.service_dog, e.cat2
        }

        function Saxophone:run(param)
            local em
            if param then
                em = e[param]
                local c = param:find'^<a?:.+:%d+>$'
                if c then
                    em = param
                end
                if not em then
                    local l = help.twemoji(param)

                    local s, r = pcall(http.request, 'HEAD', l)
                    if s and (r.code == 200) then
                        em = param
                    end
                end
            end
            em = em or list[math.random(#list)]

            return e.saxophone..em
        end
    --[[ top ]]
        local Top = commands 'top'
        Top.help = 'replies to the first message in the channel'
        Top.alias = 'first' 

        function Top:run()
            return {
                content = e.rocket,
                message_reference = {
                    message_id = self.channel:getFirstMessage().id
                }
            }, {safe = true}
        end
    --[[ invite ]]
        local Invite = commands 'invite'
        Invite.help = 'invite broment to your own server!'

        function Invite:run()
            return
            "<https://discord.com/api/oauth2/authorize?client_id="..
                appInfo.id..
                "&permissions=2147483639&scope=applications.commands%20bot>"
        end
    --[[ user ]]
        local User = commands 'user' '[user]*'
        User.help = 'get a users public info'
        User.alias = {'userInfo', 'user-info', 'user_info'}

        local statuses = {
            online = {'Online', 0x43b581},
            idle = {'Idle', 0xfaa61a},
            dnd = {'Do Not Disturb', 0xf04747},
            offline = {'Offline', 0x747f8d},
            streaming = {'Streaming', 0x593695},
            unknown = {nil, 0x747f8d},
        }

        local badges = {
            {'staff_badge', 0},
            {'partner_badge',1},
            {'hypesquad_badge',2},
            {'bravery_badge',6},
            {'brilliance_badge',7},
            {'balance_badge',8},
            {'bug_hunter_badge',3},
            {'bug_hunter_badge_2',14},
            {'verified_developer_badge',17},
            {'early_supporter_badge',9},
        }

        local boost = {0.5,2,3,6,9,12,15,18,24}

        local old = classes.User.getAvatarURL
        function classes.User:getAvatarURL(size, ext)
            if self._avatar_url then
                return self._avatar_url
            else
                return old(self, size, ext)
            end
        end

        client._users:_insert({
            id = "1",
            username = "Clyde",
            discriminator = "0000",
            avatar_url = "https://discord.com/assets/f78426a064bc9dd24847519259bc42af.png",
            bot = true,
            public_flags = bit.lshift(1, 16),
        })

        function User:run(param, perms)
            if not perms.bot:has'embedLinks' then return nil, 'i need embed perms' end

            local u = help.resolveUser(self, param)
            local localM = self.guild and self.guild._members:get(u.id)
            local m = (localM or help.getMemberFromUser(u)) or {}
            local a = m.activity or {}

            local status = statuses[a.type == 1 and
                'streaming' or m.status or 'unknown']
            local platform = (m.mobileStatus and m.mobileStatus ~= 'offline' and
                e.calling or e.desktop) .. ' '

            local type = help.getTypeOfUser(u)

            local fields = {
                {name = 'User ID', value = u.id},
            }

            if status[1] then
                table.insert(fields,
                {name = 'Status', value = platform..status[1], inline = true})
            end
            if type ~= 'User' then
                table.insert(fields,
                {name = 'Type', value = type, inline = true})
            end
            if localM then
                if m.nickname then
                    table.insert(fields,
                    {name = 'Nickname', value = m.nickname, inline = true})
                end
            end

            if perms.bot:has'useExternalEmojis' then
                local out = {}
                for i, b in pairs(badges) do
                    if custom[b[1]] and help.userFlag(u, b[2]) then
                        table.insert(out, custom[b[1]].mentionString)
                    end
                end
                if localM and m.premiumSince then
                    local months = math.ceil(
                        (date():toSeconds() - date.fromISO(m.premiumSince):toSeconds())
                        / 2.628e+6
                    )

                    for i, m in pairs(boost) do
                        if months <= m then
                            local exists = boost[i-1] and custom['boosting_icons_'..math.ceil(boost[i-1])]
                            if exists then
                                table.insert(out, exists.mentionString)
                            end
                            break
                        end
                    end
                end

                out = table.concat(out, ' ')
                if #out > 0 then
                    table.insert(fields,
                    {name = 'Badges', value = out, inline = true})
                end
            end

            if localM then
                if m.premiumSince then
                    table.insert(fields,
                    {name = 'Boosting Since', value = date.fromISO(m.premiumSince):toHeader()})
                end
                if m.joinedAt then
                    table.insert(fields,
                    {name = 'Server Join Date', value = date.fromISO(m.joinedAt):toHeader()})
                end
            end

            table.insert(fields, 
            {name = 'Discord Join Date', value = date.fromSnowflake(u.id):toHeader()})

            local footer
            if a and a.name == 'Custom Status' then
                footer = {text = utf8.char(0x200B)}
                if a.emojiHash then
                    footer.icon_url = a.emojiURL or help.twemoji(a.emojiHash)
                end
                if a.state then
                    footer.text = footer.text .. a.state
                end
            end

            return {
                embed = {
                    url = u.avatarURL..'?size=1024',
                    title = u.tag,
                    thumbnail = {url = u.avatarURL},
                    fields = fields,
                    color = status[2],
                    footer = footer
                }
            }, {safe = true}
        end
    --[[ suppress ]]
        local Suppress = commands 'suppress' '[message]'
        Suppress.help = 'hide/show the embeds of a message'
        Suppress.alias = {
            'supress',
            'hideEmbeds', 'hide-embeds', 'hide_embeds',
            'hideEmbed', 'hide-embed', 'hide_embed',
            'showEmbeds', 'show-embeds', 'show_embeds',
            'showEmbed', 'show-embed', 'show_embed',
        }

        function Suppress:run(param, perms)
            local msg = help.resolveMessage(self, param, true)

            if not msg then return nil, 'message needed' end
            if not perms.user:has'manageMessages' then
                return nil, 'you must have the manage messages permission'
            end
            if not perms.bot:has'manageMessages' then
                return nil, 'i must have the manage messages permission'
            end

            local flag = msg:hasFlag(enum.messageFlag.suppressEmbeds)

            local done = e.ballot_box_with_check

            if flag then msg:showEmbeds() else msg:hideEmbeds() end

            if perms.bot:has'addReactions' then
                self:addReaction(done)
            else
                return done
            end
        end
    --[[ Base64image ]]
        local Base64image = commands 'base64ToImage' '[base64]'
        Base64image.help = 'turn a base64 image to its original form'
        Base64image.alias = {'base64img', 'b64image', 'b64img'}

        function Base64image:run(param, perms)
            if not perms.bot:has'attachFiles' then 
                return nil, 'need image perms'
            end
            
            local url = self.attachment and self.attachment.url:find(".txt$") and self.attachment.url  
            if url then
                local succ, res, source = pcall(http.request, "GET", url, nil, nil, 10000)
                assert(succ, res)

                param = source
            end

            if not param then return nil, 'base64 expected' end

            local ext, data = param:match"^data:image/(%a+);base64,([%w%//%+%=]+)$"

            if ext then 
                return {
                    file = {table.concat({self.id,ext},'.'),require "openssl".base64(data,false)}
                }
            else
                return nil, '`data:image/{ext};base64,{base64}}` expected'
            end
        end
    end--of commands 
--[[ events ]]
    client:on('messageCreate', function(msg)
        local author, channel, guild = msg.author, msg.channel, msg.guild

        local role = ((guild and help.getBotRole(guild)) or {})
        local botRole = role.mentionString

        local semiMention = '@'..(help.getNick(bot, channel))
        local semiRoleMention = botRole and '@'..(role.name)
        
        local hasCumber = msg.content:find(e.cucumber) or
            msg.content:lower():find'c?u?%-?cumb[ae]r?'

        local cmdQuery, param = help.cmdParse(msg, {
            ';',
            botRole,
            bot.name,
            semiMention,
            semiRoleMention,
            e.people_hugging,
            channel.type == enum.channelType.private and '',
        })

        if hasCumber or cmdQuery then
            local perms
            local botPerm = help.perm(bot, channel)

            local isCmd
            local canSend = help.canReply(msg) and botPerm:has'sendMessages'

            if hasCumber and botPerm:has'addReactions' then
                if custom.cucumba and botPerm:has"useExternalEmojis" then
                    msg:addReaction(custom.cucumba)
                else msg:addReaction(e.cucumber) end
            end

            if canSend and cmdQuery then
                perms = {bot = botPerm, user = help.perm(author, channel)}
                local cmd = commands:find(cmdQuery)
                if cmd then
                    isCmd = true
                    
                    help.runCmd(cmd, msg, param, perms)
                end
            end

            if canSend and (not isCmd)
            and help.cmdParse(msg, {botRole, semiMention, semiRoleMention}) == '' then
                msg:reply("prefix is ; mention work tooooo hahahhahaha")
            end
        end
    end)

    client:on('messageUpdate',function(msg)
        if msg.author == bot
        and msg:hasFlag(enum.messageFlag.suppressEmbeds)
        and not msg._keepEmbedHidden  then
            msg:showEmbeds()
        end
    end)

    client:on('heartbeat', function(_, ping)
        apiPing = ping
        variables.apiPing = apiPing
    end)

    function client._events.INTERACTION_CREATE(d, client)
        if d.type == 2 then
            function d:reply(responseType, data)
                local endpoint = "/interactions/"..self.id.."/"..self.token.."/callback"

                if type(data) == 'string' then data = {content = data} end

                return API:request('POST', endpoint, {
                    type = responseType,
                    data = data
                })
            end

            return client:emit('commandTriggered', d)
        end
    end

    client:on('commandTriggered', function(interaction)
        interaction:reply(5)
    end)

    client:on('info', function(message)
        log(enum.logLevel.info, message)
    end)

    client:on('error', function(message)
        log(enum.logLevel.error, message)
    end)

    client:run((config.discord.bot and 'Bot ' or '') .. config.discord.token) 

    --to prevent me from accidentally leaking token with p()
    config.discord.token = nil