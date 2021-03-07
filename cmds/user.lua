local user = commands 'user' '[user]*'
user.help = 'get a users public info'
user.alias = {
    'userInfo', 'user-info', 'user_info',
    'memberInfo', 'member-info', 'member_info',
    'member', 'whois'
}

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

function user:run(param, perms)
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

    local description = ''
    local fields = {}

    if status[1] then
        table.insert(fields,
        {name = 'Status', value = platform..status[1], inline = true})
    end
    if type ~= 'User' then
        table.insert(fields,
        {name = 'Type', value = type, inline = true})
    end
    if localM then
        local roles = {}
        description = {}
        for i, r in pairs(m.roles) do
            if r.position ~= 0 and not r.managed  then
                table.insert(roles, r)
            end
        end
        table.sort(roles, function(a, b) return a.position > b.position end)
        for i = 1, math.min(#roles, 80) do
            description[i] = roles[i].mentionString
        end 

        description = table.concat(description, ' ')

        if m.nickname then
            table.insert(fields,
            {name = 'Nickname', value = m.nickname, inline = true})
        end

        if self.guild.ownerId == u.id then
            table.insert(fields, {name = 'Owner', value = "Yes", inline = true})
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
            {name = 'Badges', value = out..utf8.char(0x200B), inline = true})
        end
    end

    if localM then
        if m.premiumSince then
            table.insert(fields,
            {name = 'Boosting Since', value = date.fromISO(m.premiumSince):toHeader(), inline = true})
        end
        if m.joinedAt then
            table.insert(fields,
            {name = 'Server Join Date', value = date.fromISO(m.joinedAt):toHeader(), inline = true})
        end
    end

    table.insert(fields, 
    {name = 'Discord Join Date', value = date.fromSnowflake(u.id):toHeader(), inline = true})

    if localM then
        local members = self.guild.members:toArray()
        table.sort(members, function(a, b) return date.fromISO(a.joinedAt) < date.fromISO(b.joinedAt) end)

        local key = 0
        for i, m in pairs(members) do if m.id == u.id then key = i break end end

        local i = math.clamp(key - 3, 0, math.max(0, self.guild.totalMemberCount - 5))
        
        local order = help.concat(F" ${e.arrow_right} ", function(m)
            i = i + 1
            return string.format(key == i and "%s %s" or "%s", m.mentionString, F"**(#${i})**")
        end)(table.slice(members, i + 1, i + 5))

        table.insert(fields, {name = 'Join Order', value = order})
    end

    local author
    if a and a.type == 4 then
        author = {name = utf8.char(0x200B)}
        if a.emojiHash then
            author.icon_url = a.emojiURL or help.twemoji(a.emojiHash)
        end
        if a.state then
            author.name = author.name .. a.state
        end
    end

    return {
        embed = {
            color = status[2],
            thumbnail = {url = u.avatarURL},
            author = author,
            url = u:getAvatarURL(1024), title = u.tag,
            description = help.boolNil(description ~= '' and ('**Roles**\n'..description)),
            fields = fields,
            footer = {text = u.id}
        }
    }, {safe = true}
end