--[[ variables ]]
    local discordia = require('discordia')
    local client = discordia.Client{cacheAllMembers = true, logFile = '',}
    local time = discordia.Time()
    local date = discordia.Date()
    local color = discordia.Color
    local API = client._api
    local enum = discordia.enums

    local requireDiscordia = require('require')(select(2, module:resolve('discordia')))
    local class = requireDiscordia('class')
    local classes = class.classes
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
    local len = utf8.len

    local defaultColor = color.fromRGB(38, 101, 144)
    local config = lip.load('config.ini')

    for i, p in pairs(config.paths) do
        local new = p:gsub("%%([^%%]+)%%", process.env)
        config.paths[i] = path.resolve(new)
    end

    local variables = { -- update when new variable added -- }
        requireDiscordia = requireDiscordia, module = module,
        resolver = resolver, time = time, class = class, 
        path = path, lpeg = lpeg, timer = timer, json = json,
        fs = fs, http = http, url = url, API = API, pp = pp,
        client = client, uv = uv, date = date, enum = enum, 
        discordia = discordia, classes = classes, len = len,
        defaultColor = defaultColor, require = require,}
        variables.variables = variables 

    local bot, prefixes, cucumba, appInfo, help, commands, apiPing, e
    client:once('ready', function()
        bot = client.user
        prefixes = {
            '<@%s>'%{bot.id},
            '<@!%s>'%{bot.id},
        }
        apiPing = 0/0
        cucumba = client:getEmoji'767783439097135144'
        appInfo = client:getApplicationInformation()
        variables.cucumba = cucumba; variables.bot = bot; variables.apiPing = apiPing
        variables.prefixes = prefixes; variables.appInfo = appInfo
    end)
--[[ functions ]]
    help = {} do
    variables.help = help
    --[[ boolNil ]]
        function help.boolNil(bool)
            if bool then return bool end
        end
    --[[ embed / textEmbed]]
        function help.embed(title, add)
            local embed = {
                author = {name = help.concat" "(bot.name, title), icon_url = bot.avatarURL},
                description = '',
                color = defaultColor.value
            }
            if add then
                for i, v in pairs(add) do
                    embed[i] = v
                end
            end
            return {embed = embed}
        end

        function help.textEmbed(title, str)
            return help.concat"\n"('>>> '..e.people_hugging.."  **"..help.concat" "(bot.name, title).."**",str)
        end
    --[[ concat ]]
        function help.concat(sep, func)
            func = func or tostring
            return function(...)
                local ret, t, n = "", {...}, select("#", ...)
                if type(...) == 'table' then
                    t, n = n > 1 and t or  ..., n > 1 and n or #...
                end

                for i = 1, n do
                    ret = ret .. func(t[i])
                    if i < n then ret = ret .. sep end
                end
                return ret
            end
        end
    --[[ rowConcat ]]
        function help.rowConcat(sep, wrap, func)
            func = func or tostring
            return function(...)
                local rows, t, n = {}, {...}, select("#", ...)
                if type(...) == 'table' then
                    t, n = n > 1 and t or  ..., n > 1 and n or #...
                end

                for i = 1, n do
                    local s = func(t[i])
                    if i == 1 then
                        rows[1] = s
                    else
                        if len(rows[#rows]) + len(s) <= (wrap or 22) then
                            rows[#rows] = rows[#rows] .. sep .. s
                        else
                            rows[#rows + 1] = s
                        end
                    end
                end
                return rows
            end
        end
    --[[ linePad ]]
        function help.linePad(str, n)
            return str..("\n"):rep(n - (1 + select(2, str:gsub("\n","\n"))))..utf8.char(0x200b)
        end
    --[[ truncate ]]
        function help.truncate(s, w, e)
            if len(s) > w then
                return s:sub(1, utf8.offset(s, w - len(e) + 1) - 1) .. e
            end
            return s
        end
    --[[ dashParse ]]
        function help.dashParse(str)
            local ret2 = {}

            if not str then return false, ret2 end

            local ret = string.trim(str:gsub("(%S+)(%s-)",function(word, spaces)
                local capture, value = word:match("^%-%-(%a)%a+=?(.*)$")
                if not capture then
                    capture, value = word:match("^%-(%a)=?(.*)$")
                end
                
                if capture then
                    ret2[capture:lower()] = value == '' and true or value
                    return spaces
                end
                return word
            end))

            return ret ~= '' and ret, ret2
        end
    --[[ textFlag ]]
        help.textFlag =
            {'text',
            'shows text based version'}
    --[[ type ]]
        function help.type(v)
            return (type(v) == 'table' and v.__name) or type(v)
        end
    --[[ getNick ]]
        function help.getNick(user, channel)
            local member = channel.guild and channel.guild._members:get(user.id)
            if member then
                return member.name
            end
            return user.name
        end
    --[[ countSyllables ]]
        function help.countSyllables(word)
            local vowels = { 'a','e','i','o','u','y' }
            local numVowels = 0
            local lastWasVowel = false
        
            for i = 1, #word do
            local wc = string.sub(word,i,i)
            local foundVowel = false;
            for _,v in pairs(vowels) do
                if (v == string.lower(wc) and lastWasVowel) then
                foundVowel = true
                lastWasVowel = true
                elseif (v == string.lower(wc) and not lastWasVowel) then
                numVowels = numVowels + 1
                foundVowel = true
                lastWasVowel = true
                end
            end
        
            if not foundVowel then
                lastWasVowel = false
            end
            end
        
            local exception = false
            if string.len(word) > 2 and string.sub(word,string.len(word) - 1) == "es" then
            numVowels = numVowels - 1
            exception = true
            elseif string.len(word) > 1 and string.sub(word,string.len(word)) == "e" then
            numVowels = numVowels - 1
            exception = true
            end
        
            return exception and math.max(1,numVowels) or numVowels
        end
    --[[ codeEsc ]]
        function help.codeEsc(str)
            return str:gsub('`', utf8.char(0x02CB))
        end
    --[[ code ]]
        function help.code(str, lang, wrap)
            wrap = wrap or ''
            return wrap.."```"..(lang or '')..'\n'..help.codeEsc(str).."```"..wrap
        end
    --[[ cmdParse ]]
        help.cmdParse = {}

        function help.cmdParse.parse(msg, pfx)
            if type(pfx) == 'string' and (msg:lower():find(pfx:lower(),1,true)==1) then
                local cmd, param = msg:sub(#pfx+1):match'%s*(%S*)%s*(.*)'

                if cmd then
                    return cmd:lower(), #param > 0 and param
                end
            end
        end

        local function _(self, msg, pfxs)
            msg = msg.content or msg

            local cmd, param
            for _, pfx in pairs(prefixes) do
                cmd, param = self.parse(msg, pfx)
                if cmd then return cmd, param end
            end
            if pfxs then
                for _, pfx in pairs(pfxs) do
                    cmd, param = self.parse(msg, pfx)
                    if cmd then return cmd, param end
                end
            end
        end

        setmetatable(help.cmdParse,{__call = _})
    --[[ getBotRole ]]
        function help.getBotRole(guild, member)
            member = member or guild.me

            local roles = member.roles
            for id, role in pairs(roles) do
                if role.managed and #role.members == 1 then
                    return role
                end
            end
        end
    --[[ printLine / prettyLine ]]
        function help.printLine(...)
            local ret = {}
            for i = 1, select('#', ...) do
                table.insert(ret, tostring(select(i, ...)))
            end
            return table.concat(ret, '\t')..'\n'
        end

        function help.prettyLine(...)
            local ret = {}
            for i = 1, select('#', ...) do
                table.insert(ret, pp.dump(select(i, ...), nil, true))
            end
            return table.concat(ret, '\t')..'\n'
        end
    --[[ haste ]]
        function help.haste(text, domain, keyOnly)
            domain = domain or 'https://hastebin.com/'

            local success, res, body = pcall(http.request,
                'POST',
                url.resolve(domain, 'documents'),
                nil,
                text
            )

            if success then
                local key = assert(json.parse(body)).key
                return keyOnly and key or url.resolve(domain, key)
            else
                error(body)
            end
        end
    --[[ channelPerm ]]
        help.channelPerm = {}

        --https://github.com/SinisterRectus/Discordia/wiki/Enumerations#permission

        help.channelPerm.dm = {
            addReactions = true, readMessages = true, sendMessages = true,
            embedLinks = true, attachFiles = true, readMessageHistory = true,
            useExternalEmojis = true, 

        }

        local function _(self, perm, channel, member)
            if channel.guild then
                local guild = channel.guild 
                local member = guild:getMember(resolver.userId(member or guild.me))
                return member and member:hasPermission(channel, enum.permission[perm])
            else
                return self.dm[perm]
            end
        end

        setmetatable(help.channelPerm,{__call = _})
    --[[ canReply ]]
        function help.canReply(message)
            local user = message.author
            return (
                -- can reply at all
                help.channelPerm('sendMessages', message.channel) and
                -- ignore system messages
                message.type == 0 and
                -- stop resursion
                user ~= user.client.user and
                -- ignore bots and webhooks
                user.bot ~= true and user.discriminator ~= '0000'
            )
        end
    --[[ APIsend ]]
        function help.APIsend(channel, content)
            local content = (type(content) == 'string' and {content = content}) or content

            local data, err = API:createMessage(channel.id, content)

            if data then
                return channel._messages:_insert(data)
            else
                return nil, err
            end
        end
    --[[ APIget ]]
        function help.APIget(channel, id)
            return API:getChannelMessage(channel.id, id)
        end
    --[[ getAllMembers ]]
        function help.getAllMembers(guild)
            if table.count(guild.members) < 
            guild.totalMemberCount then
                guild:requestMembers()
            end
            return guild.members
        end
    --[[ searchMembers ]]
        function help.searchMembers(guild, query, threshold)
            local username, discrim = query:match("^@?(.-)#(%d%d%d%d)$")
            username = username or query:match("^@?(.*)$")

            query = username:lower()

            local n = 0
            local member, value
            for i, m in pairs(help.getAllMembers(guild)) do
                if not discrim then
                    local s1, s2 = m.name:lower(), m.user.name:lower()

                    local i1, j1 = s1:find(query, 1, true)
                    local i2, j2 = s2:find(query, 1, true)
                    
                    local c1 = i1 and ((j1 - (i1 - 1)) / #s1)
                    local c2 = i2 and ((j2 - (i2 - 1)) / #s2)

                    local c = (c1 and c2 and math.min(c1, c2)) or
                        c1 or c2

                    if c then
                        if (not value) or value < c then
                            member, value, n = m, c, n + 1
                        elseif value == c then
                            if date.fromISO(member.joinedAt):toSeconds()
                            < date.fromISO(m.joinedAt):toSeconds() then
                                member, value, n = m, c, n + 1
                            end
                        end
                    end
                else
                    if (m.user.name:lower() == query) and
                    (tostring(m.user.discriminator) == discrim) then
                        return m
                    end
                end
            end
            return value and ((threshold or 0) <= value) and member
        end
    --[[ resolveMessage ]]
        function help.resolveMessage(msg, param, strict)
            local ret
            if tonumber(param) then
                ret = msg.channel:getMessage(param)
            elseif param then
                local c, m = param:match('https?://.-%.?discorda?p?p?%.com/channels/.-/(%d+)/(%d+)')
                c = client:getChannel(c)
                ret = c and c:getMessage(m)
            end
            if not ret then
                local raw = help.APIget(msg.channel, msg.id)
                if raw.message_reference then
                    ret = msg.channel:getMessage(raw.message_reference.message_id)
                end
            end
            return ret or ((not strict) and msg)
        end
    --[[ resolveUser ]]
        function help.resolveUser(msg, param, strict, threshold)
            local ret
            if tonumber(param) then
                ret = client:getUser(param)
            elseif param then
                local mat = param:match("<@!?(%d+)>")
                if mat then ret = client:getUser(mat)
                elseif param:lower() == 'me' then ret = client:getUser(msg.author)
                elseif msg.guild then
                    if param:lower() == 'random' then
                        return help.getAllMembers(msg.guild):random()
                    else
                        help.getAllMembers(msg.guild)
                        local m = help.searchMembers(msg.guild, param, threshold)
                        if m then ret = m.user end
                    end
                end
            end
            if not ret then
                local raw = help.APIget(msg.channel, msg.id)
                if raw.message_reference then
                    ret = msg.channel:getMessage(raw.message_reference.message_id).author
                end
            end
            return ret or ((not strict) and msg.author)
        end
    --[[ getMemberFromUser ]]
        function help.getMemberFromUser(user)
            for i, v in pairs(user.mutualGuilds) do
                local m = v:getMember(user.id)
                if m then return m end
            end
        end
    --[[ getWebhookFromUser ]]
        function help.getWebhookFromUser(user)
            if user.discriminator == '0000' and user.bot then
                return client:getWebhook(user.id)
            end
        end
    --[[ getTypeOfUser ]]
        local systemAccounts = {
            ['669627189624307712'] = true
        }    

        function help.getTypeOfUser(user)
            if systemAccounts[user.id] then
                return "System"
            end
            local w = help.getWebhookFromUser(user)
            if w then
                if systemAccounts[w.user and w.user.id] then
                    return "System"
                end
                if w.type == 2 then
                    return "Server"
                else
                    return "Webhook"
                end
            elseif user.bot and user.discriminator == '0000' then
                return 'Webhook'
            elseif user.bot then
                return "Bot"
            end
        end
    --[[ alphasort ]]
        function help.alphasort(a, b)
            local function padnum(d) local dec, n = string.match(d, "(%.?)0*(.+)")
                return #dec > 0 and ("%.12f"):format(d) or ("%s%03d%s"):format(dec, #n, n) end
            return tostring(a):gsub("%.?%d+",padnum)..("%3d"):format(#b)
                 < tostring(b):gsub("%.?%d+",padnum)..("%3d"):format(#a)
        end
    --[[ apng2gif ]]
        function help.apng2gif(apngSource)
            local tmp = os.tmpname()
            fs.writeFileSync(tmp, apngSource)
            spawn(config.paths.apng2gif, {args = {
                tmp,
                tmp,
            }}).waitExit()
            local gifSource = fs.readFileSync(tmp)
            fs.unlink(tmp)
            return gifSource
        end
    --[[ svg2png ]]
        function help.svg2png(svgSource, w, h)
            local tmp = os.tmpname()
            local out = tmp..'.png'
            fs.writeFileSync(tmp, svgSource)
            spawn(config.paths.inkscape, {args = {
                '-w',
                tostring(math.clamp(w or 1024, 10, 1024)),
                '-h',
                tostring(math.clamp(h or 1024, 10, 1024)),
                tmp,
                '--export-filename',
                out, 
            }}).waitExit()
            local pngSource = fs.readFileSync(out)
            fs.unlink(tmp)
            fs.unlink(out)
            return pngSource
        end
    --[[ lottie2gif ]]
        function help.lottie2gif(jsonSource, w, h)
            local tmp = os.tmpname()
            local out = tmp..'.gif'
            fs.writeFileSync(tmp, jsonSource)
            spawn(config.paths.puppeteer_lottie,{args = {
                '-i', tmp,
                '-o', out,
                '-w', tostring(math.clamp(w or 160, 10, 1024)),
                '-h', tostring(math.clamp(w or 160, 10, 1024))
            }}).waitExit()
            local gifSource = fs.readFileSync(out)
            fs.unlink(tmp)
            fs.unlink(out)
            return gifSource
        end
    --[[ codepoint ]]
        function help.codepoint(str)
            return string.gsub(
                string.rep('%x-', len(str)):format(utf8.codepoint(str, 1, -1)):sub(1, -2),
                len(str) > 3 and '' or '%-fe0f', ''
            )
        end
    --[[ twemoji ]]
        function help.twemoji(emoji, options)
            options = options or {}
            return help.concat""(
                options.base or 'https://twemoji.maxcdn.com/v/latest/',
                options.size or '72x72',
                '/',
                help.codepoint(emoji),
                options.ext or '.png'
            )
        end
    --[[ shortcode ]]
        help.shortcode = {}

        help.shortcode.main = json.parse(fs.readFileSync(path.resolve("misc/emojis.json")))
        help.shortcode.shortcuts = json.parse(fs.readFileSync(path.resolve("misc/emoji-shortcuts.json")))
        help.shortcode.cache = {}

        local function _(self, query)
            if self.cache[query] then
                return self.cache[query]
            end

            if not query:match("^[%w_%+%-]+$") then
                for i, emoji in pairs(self.shortcuts) do
                    for i, shortcut in pairs(emoji.shortcuts) do
                        if shortcut == query then query = emoji.emoji break end
                    end
                    if query:match("^[_%w]+$") then break end
                end
            end

            query = query:match('^:?(.-):?$'):lower()

            for i, category in pairs(self.main) do
                for i, emoji in pairs(category) do
                    for i, name in pairs(emoji.names) do
                        if name == query then
                            self.cache[query] = emoji.surrogates
                            return emoji.surrogates
                        end
                        if emoji.hasDiversity then
                            for i, child in pairs(emoji.diversityChildren) do
                                for i, cname in pairs(child.names) do
                                    if cname == query then
                                        self.cache[query] = emoji.surrogates
                                        return child.surrogates
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        setmetatable(help.shortcode,{__call = _})
        e = setmetatable({}, {
            __index = function(t, ...) return help.shortcode(...) end
        })
        variables.e = e
    --[[ split ]]
        function help.split(s, delim, exact)
            if not s then return end

            delim = delim or  lpeg.P";"

            if type(delim) == 'string' then
                delim = P(delim)
            end

            local char = lpeg.P[[\]] * lpeg.P(1)
                       + (lpeg.P(1) - delim)
            
            local word = char^0 / function(s) s = s:gsub('\\([^%w%s])','%1') return s end

            local words = word * (delim * word)^0

            local tbl = lpeg.Ct(words):match(s)

            if not exact then
                for i, s in pairs(tbl) do
                    tbl[i] = s:trim()
                end
            end

            return unpack(tbl)
        end
    --[[ limits ]]
        help.limits = {
            content = 2000,
            embed = {
                title = 256,
                description = 2048,
                fields = {
                    25, {name = 256, value = 1024}
                },
                footer = {text = 2048},
                author = {name = 256},
            }
        }
        
        function _(raw)
            if type(raw) == 'string' then
                raw = {content = raw}
            end

        end

        setmetatable(help.limits,{__call = _})
    --[[ runCmd ]]
        function help.runCmd(cmd, msg, param, cantErr)
            local succ, ret, ret2 = pcall(cmd.run, msg, param)

            if succ then
                ret = (ret ~= nil) and (class.isObject(ret) or
                    type(ret) ~= 'table')
                    and tostring(ret) or ret

                if type(ret) == 'string' and len(ret) > 2000 then
                    succ, ret = msg:reply{
                        content = 'sorry guy but message too long',
                        file = {'message.txt', ret}
                    }
                else
                    if succ and ret then
                        if ret == '' then
                            if help.channelPerm('embedLinks', msg.channel) then
                                succ, ret = msg:reply{embed={description=''}}
                                if succ then
                                    succ._keepEmbedHidden = true
                                    succ:hideEmbeds()
                                end
                            else
                                succ, ret = msg:reply("_ _")
                            end
                        elseif type(ret2) == 'table' then
                            local raw = type(ret) == 'table' and ret or {}

                            if type(ret) == 'string' then
                                raw.content = ret
                            end

                            raw.allowed_mentions = raw.allowed_mentions or
                                ret2['safe'] and {parse = {}}

                            succ, ret = help.APIsend(msg.channel, raw)
                        else
                            succ, ret = msg:reply(ret)
                        end
                    elseif succ and (not ret) and (ret2) then
                        help.runCmd(commands.sorry, msg, ret2, true)
                        return nil
                    end
                end
            end

            if (not succ) and (not cantErr) then
                help.runCmd(commands.error, msg, help.concat";"(cmd.name, ret), true)
            end
        end
    --[[ text2decimal ]]
        function help.text2decimal(text)
            local n = 0
            for i, v in pairs{utf8.codepoint(text, 1 , -1)} do
                n = n + v^i
            end
            return n
        end
    --[[ style (for consistent styling) ]]
        help.style = {}

        help.style.line = "***__~~`===================================`~~__***"
        help.style.multiLine = help.style.line..' '..help.style.line..'\n'

        function help.style.code(...)
            return help.code(..., 'xml')
        end

        function help.style.name(name)
            local filter = name:gsub("[^%s%w_%-%.]", ""):trim()
            if filter == '' then return '' end
            return '<'..filter:gsub("%s+", ">%1<")..'>'
        end

        function help.style.help(help)
            return '<!--'..(help or 'No description...'):gsub("\n+", "-->%1<!--")..'-->'
        end

        function help.style.format(t)
            return help.concat"\n\n"{help.concat" "{
                help.style.name(t.name), t.param
            }..'\n'..help.style.help(t.help),
                t.flags and (
                    help.concat("\n", function(f)
                        return '--'..f[1]..
                            (f[3] and ('='..f[3]) or '')..
                            (' (-'..f[1]:sub(1,1)..
                                (f[3] and ('='..f[3]) or '')..
                                ')\n'
                            )..
                            '['..f[2]..']'
                    end)(t.flags)
                )
            }
        end

        function help.style.groupFormat(t)
            return help.style.code(help.concat("\n\n",help.style.format)(t))
        end

    end--of functions
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

        function Lavadrop:run()
            if help.channelPerm('embedLinks', self.channel) then
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

        function Stats:run(...)
            local param, args = help.dashParse(...)
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

            if args.t or not help.channelPerm('embedLinks', self.channel) then
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

        function Sticker:run(param)
            local message = help.resolveMessage(self, param, true)
            if not message then
                return nil, 'need a valid message to steal sticker'
            end
            if not help.channelPerm('attachFiles', self.channel) then return nil, 'i need image perms' end
            
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

        function Help:run(...)
            local param, args = help.dashParse(...)

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

            if args.t or not help.channelPerm('embedLinks', self.channel) then
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

        function Emote:run(param)
            if not param then return nil, 'emoji needed' end
            if not help.channelPerm('attachFiles', self.channel) then return nil, 'i need image perms' end

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

        function ServerEmojis:run(...)
            local param, args = help.dashParse(...)
            param = param and param:lower()

            local tone = tonumber(args.t) and
                string.format('%x', 0x1F3FA + args.t)

            local guild = param and 
                (client:getGuild(param) or 
                help.shortcode.main[param == 'activities' and
                'activity' or param]) or self.guild

            if not help.channelPerm('embedLinks', self.channel) then return nil, 'i need embed perms' end
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

        function Bro:run(...)
            local param, args = help.dashParse(...)
            local p1, p2 = help.split(param)

            if not p1 or not p2 then
                return nil, '`[p1]; [p2]` expected'
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

            if args.t or not help.channelPerm('embedLinks', self.channel) then
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
        Avatar.alias = {'pfp', 'profilePicture', 'profile-picture', 'profile_picture', 'icon'}
        Avatar.flags = {
            {'default',
            'shows default avatar'}
        }

        function Avatar:run(...)
            local param, args = help.dashParse(...)

            local user = help.resolveUser(self, param)

            return (args.d and 
                user.defaultAvatarURL or
                user.avatarURL)
                ..'?size=1024 _ _',
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
                client:getApplicationInformation().id..
                "&permissions=2147483639&scope=bot>"
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

        function User:run(param)
            if not help.channelPerm('embedLinks', self.channel) then return nil, 'i need embed perms' end

            local u = help.resolveUser(self, param)
            local m = help.getMemberFromUser(u) or {}
            local a = m.activity or {}

            local status = statuses[a.type == 1 and
                'streaming' or m.status or 'unknown']
            local platform = (m.mobileStatus and m.mobileStatus ~= 'offline' and
                e.calling or e.desktop) .. ' '

            local creation = date.fromSnowflake(u.id):toHeader()
            local mention = '<@!'..u.id..'>'

            local type = help.getTypeOfUser(u)

            local fields = {
                {name = 'User ID', value = u.id},
            }

            if status[1] then
                table.insert(fields,
                {name = 'Status', value = platform..status[1], inline = true})
            end
            if type then
                table.insert(fields,
                {name = 'Type', value = type, inline = true})
            end

            table.insert(fields, 
            {name = 'Discord Join Date', value = creation})

            return {
                content = mention,
                embed = {
                    url = u.avatarURL..'?size=1024',
                    title = u.tag,
                    thumbnail = {url = u.avatarURL},
                    fields = fields,
                    color = status[2],
                }
            }, {safe = true}
        end
    end--of commands 
--[[ events ]]
    client:on('messageCreate', function(msg)
        local author, channel, guild = msg.author, msg.channel, msg.guild

        local role = ((guild and help.getBotRole(guild)) or {})
        local botRole = role.mentionString
        local semiMention = '@'..(msg.guild and msg.guild.me.name or bot.name)
        local semiRoleMention = botRole and '@'..(role.name)

        local isCmd
        local canSend = help.canReply(msg)
        

        if canSend then
            local cmdQuery, param = help.cmdParse(msg, {
                ';',
                botRole,
                bot.name,
                semiMention,
                semiRoleMention,
                e.people_hugging,
                channel.type == enum.channelType.private and '',
            })

            if cmdQuery then 
                local cmd = commands:find(cmdQuery)
                if cmd then
                    isCmd = true
                    
                    help.runCmd(cmd, msg, param)
                end
            end
        end

        if canSend and (not isCmd)
        and help.cmdParse(msg, {botRole, semiMention, semiRoleMention}) == '' then
            msg:reply("prefix is ; mention work tooooo hahahhahaha")
        end

        if msg.content:find(e.cucumber) or
        msg.content:lower():find'c?u?%-?cumb[ae]r?' then
            msg:addReaction(cucumba)
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

    client:run((config.discord.bot and 'Bot ' or '') .. config.discord.token) 