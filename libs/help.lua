local help = {}
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
            local capture, value = word:match("^%-(%a)%a*=?(.*)$")
            
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
        if not user then return nil end
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
--[[ perms ]]
    help.perm = {}

    --https://github.com/SinisterRectus/Discordia/wiki/Enumerations#permission

    help.perm.dm = classes.Permissions.fromMany(
        'addReactions', 'readMessages',
        'sendMessages', 'embedLinks',
        'attachFiles', 'readMessageHistory',
        'useExternalEmojis'
    )

    local function _(self, member, guild)
        local channel 
        if class.isInstance(guild, classes.TextChannel) then
            channel = guild
            guild = channel.guild
        end
        if (not guild) and class.isInstance(member, classes.Member) then
            guild = member.guild
        end

        if guild then
            local member = guild._members:get(resolver.userId(member))
            return member and member:getPermissions(channel)
        else
            return self.dm
        end
    end

    setmetatable(help.perm,{__call = _})
--[[ canReply ]]
    function help.canReply(message)
        local user = message.author
        return (
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
        query = query:lower()

        local n = 0
        local member, value
        for i, m in pairs(help.getAllMembers(guild)) do
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
            local name, discrim = param:match("^@?([^#]+)#(%d%d%d%d)$")
            if mat then ret = client:getUser(mat)
            elseif name then
                name = name:lower()
                for i, u in pairs(client._users) do
                    if (u.name:lower() == name) and
                    (tostring(u.discriminator) == discrim) then
                        ret = u
                    end
                end
            elseif param:lower() == 'me' then ret = msg.author
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
--[[ userFlag ]]
    function help.userFlag(user, flag)
        return bit.band(user._public_flags or 0, bit.lshift(1, flag)) > 0
    end
--[[ getTypeOfUser ]]
    function help.getTypeOfUser(user)
        if user._system then
            return "System"
        end
        local w = help.getWebhookFromUser(user)
        if w then
            if w.user and w.user._system then
                return "System"
            end
            if w.type == 2 then
                return "Server"
            else
                return "Webhook"
            end
        elseif user.bot and help.userFlag(user, 16) then
            return "Verified Bot"
        elseif user.bot and user.discriminator == '0000' then
            return 'Webhook'
        elseif user.bot then
            return "Bot"
        end
        return 'User'
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
        local out = tmp..'.gif'
        fs.writeFileSync(tmp, apngSource)
        assert(spawn(config.paths.apng2gif, {args = {tmp}})).waitExit()
        local gifSource = fs.readFileSync(out)
        fs.unlink(tmp); fs.unlink(out)
        return gifSource
    end
--[[ svg2png ]]
    function help.svg2png(svgSource, w, h)
        local tmp = os.tmpname()
        local out = tmp..'.png'
        fs.writeFileSync(tmp, svgSource)
        assert(spawn(config.paths.inkscape, {args = {
            '-w',
            tostring(math.clamp(w or 1024, 10, 1024)),
            '-h',
            tostring(math.clamp(h or 1024, 10, 1024)),
            tmp,
            '--export-filename',
            out, 
        }})).waitExit()
        local pngSource = fs.readFileSync(out)
        fs.unlink(tmp)
        fs.unlink(out)
        return pngSource
    end
--[[ lottie2gif ]]
    function help.lottie2gif(jsonSource, w, h) -- this is a complex mess
        local tmpdir = path.resolve(uv.os_tmpdir(),'lottie_'..os.time())
        local _in = path.resolve(tmpdir,"src.json")
        local out = path.resolve(tmpdir,"out.gif")
        local img = path.resolve(tmpdir,"img")
        fs.mkdirSync(tmpdir)
        fs.writeFileSync(_in, jsonSource)
        assert(spawn(config.paths.lottieconverter, {args = {
            _in,
            img,
            'pngs',
            tostring(math.clamp(w or 160, 10, 240))..'x'..tostring(math.clamp(w or 160, 10, 240)),
            '36'
        }})).waitExit()

        local imgs = fs.readdirSync(tmpdir)
        imgs[table.search(imgs,'src.json')] = nil

        for i, v in pairs(imgs) do
            imgs[i] = path.resolve(tmpdir,v)
        end

        table.insert(imgs, '-r')
        table.insert(imgs, '36')
        table.insert(imgs, '-o')
        table.insert(imgs, out)

        assert(spawn(config.paths.gifski, {args = imgs})).waitExit()
        local gifSource = assert(fs.readFileSync(out))
        for i, v in pairs(fs.readdirSync(tmpdir)) do fs.unlink(path.resolve(tmpdir,v)) end
        fs.rmdir(tmpdir)
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
                                    self.cache[query] = child.surrogates
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
    variables.variables.e = e
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
    function help.runCmd(cmd, msg, param, perms, cantErr)
        local channel = msg.channel
        local cmdCooldown
        if cmd.channelCooldown then
            channel._cooldown = channel._cooldown or {}

            channel._cooldown[cmd.name] = channel._cooldown[cmd.name] or {os.time(), 0}
            cmdCooldown = channel._cooldown[cmd.name]

            if cmdCooldown[1] <= os.time() then
                cmdCooldown[1] = cmd.channelCooldown[1] + os.time()
                cmdCooldown[2] = 0
            end
            if cmdCooldown[2] >= cmd.channelCooldown[2] then
                help.runCmd(commands.channelcooldown, msg,
                    help.concat";"(
                        cmd.name,
                        time.fromSeconds(cmdCooldown[1] - os.time()):toString()
                    ),
                perms, true)
                return nil
            end

            cmdCooldown[2] = cmdCooldown[2] + 1

        end

        local succ, ret, ret2 = pcall(cmd.run, msg, param, perms)

        local options = type(ret2) == 'table' and ret2 or {}

        if succ then
            ret = (ret ~= nil) and (class.isObject(ret) or
                type(ret) ~= 'table')
                and tostring(ret) or ret

            if type(ret) == 'string' and len(ret) > 2000 then
                succ, ret = msg:reply{
                    content = 'sorry guy but message too long',
                    file = {F'message${date():toISO()}.txt', ret}
                }
            else
                if succ and ret then
                    if ret == '' then
                        if perms.bot:has'embedLinks' then
                            succ, ret = msg:reply{embed={description=''}}
                            if succ then
                                succ._keepEmbedHidden = true
                                succ:hideEmbeds()
                            end
                        else
                            succ, ret = msg:reply("_ _")
                        end
                    elseif options.safe or options.reply then
                        local raw = type(ret) == 'table' and ret or {}

                        if type(ret) == 'string' then
                            raw.content = ret
                        end

                        raw.allowed_mentions = raw.allowed_mentions or
                            options.safe and {parse = {}}
                        raw.message_reference = raw.message_reference or
                            options.reply and {message_id = resolver.messageId(options.reply)}

                        succ, ret = help.APIsend(channel, raw)
                    else
                        succ, ret = msg:reply(ret)
                    end
                elseif succ and (not ret) and (ret2) then
                    help.runCmd(commands.sorry, msg, ret2, perms, true)
                    if cmdCooldown then cmdCooldown[2] = cmdCooldown[2] - 1 end
                    return nil
                end
            end
        end

        if (not succ) and (not cantErr) then
            help.runCmd(commands.error, msg, help.concat";"(cmd.name, ret), perms, true)
        elseif options.remove then
            options.remove:delete()
        end
    end
--[[ wait ]]
    function help:wait(data)
        local wait = self:reply(data)
        self.channel:broadcastTyping()
        return wait
    end
--[[ work ]]
    function help.work(func, ...)
        local current = coroutine.running()
        local dump = string.dump(func)
        local cwd = (getfenv(2).module or {}).path
        local args = table.pack(...)
        timer.setTimeout(1, function()
            local w = thread.work(function(_dump, _cwd, ...)
            
                if _cwd then
                    _G.require, _G.module = require('require')(_cwd)
                end

                local complie, err =  load(_dump, "thread", "b", _G)
                if complie then
                    return pcall(complie, ...)
                else
                    return false, err
                end

            end, function(...) coroutine.resume(current, ...) end)

            local succ, err = pcall(w.queue, w, dump, cwd, table.unpack(args))

            if not succ then
                coroutine.resume(current, false, err)
            end
        end)
        local ret = table.pack(coroutine.yield())

        if not ret[1] then
            error(ret[2], 0)
        else
            return unpack(ret, 2, ret.n)
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
                    return '-'..f[1]..
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

return help