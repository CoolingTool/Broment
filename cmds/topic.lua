local topic = commands 'topic' '[text]'
topic.help = 'sets the topic of the current channel'
topic.channelCooldown = {10 * 60, 2}

function topic:run(param, perms)
    if not class.isInstance(self.channel, classes.GuildTextChannel) then
        return nil, 'only works in guild text channels'
    end

    if not perms.user:has('manageChannels') then return nil, 'you need the manage channels perm' end
    if not perms.bot:has('manageChannels') then return nil, 'i need the manage channels perm' end

    if param then 
        if len(param) > 1024 then
            return nil, 'channel topic must not be above 1024 character'
        end
        self.channel:setTopic(param)
        return 'channel topic set as '..help.truncate(param, 500, "..."), {safe = true}
    else
        self.channel:setTopic()
        return 'channel topic reset'
    end 
end