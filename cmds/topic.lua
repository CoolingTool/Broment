local topic = commands 'topic' '[text]'
topic.help = 'sets the topic of the current channel'
topic.channelCooldown = 5 * 60

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
    else
        self.channel:setTopic()
    end 

    return 'channel topic set as '..help.truncate(param, 50, "..."), {safe = true}
end