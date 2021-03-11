local events = {}

function events.messageCreate(msg)
    local author, channel, guild = msg.author, msg.channel, msg.guild

    local role = ((guild and help.getBotRole(guild)) or {})
    local botRole = role.mentionString

    local semiMention = '@'..(help.getNick(bot, channel))
    local semiRoleMention = botRole and '@'..(role.name)
    
    local hasCumber = msg.content:find(e.cucumber) or
        msg.content:lower():find'c?u?%-?cumb[ae]r?'

    local cmdQuery, param = help.cmdParse(msg, {
        ';', botRole, bot.name, semiMention, semiRoleMention,
        e.people_hugging, channel.type == enum.channelType.private and '',
    })

    if hasCumber or hasBoyTone5 or cmdQuery then
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
end

function events.messageUpdate(msg)
    if msg.author == bot then
        if (msg:hasFlag(enum.messageFlag.suppressEmbeds))
        and (not msg._keepEmbedHidden) then
            timer.sleep(1000)
            msg:showEmbeds()
        elseif (not msg:hasFlag(enum.messageFlag.suppressEmbeds))
        and (msg._keepEmbedHidden) then
            timer.sleep(1000)
            msg:hideEmbeds()

        end
    end
end

function events.heartbeat(_, ping)
    apiPing = ping
    variables.apiPing = apiPing
end

function events.commandTriggered(interaction)
    interaction:reply(5)
end

function events.info(message)
    log(enum.logLevel.info, message)
end

function events.error(message)
    log(enum.logLevel.error, message)
end




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

return events