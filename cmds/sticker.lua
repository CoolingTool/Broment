local sticker = commands 'sticker' '[message]'
sticker.alias = {'stealsticker', 'stickerSteal', 'getsticker', 's'}
sticker.help = 'gets sticker and converts it to gif'

local format = {
    --type 1 is just a normal png but link is unknown
    [2] = {'https://media.discordapp.net/stickers/','.png', help.apng2gif},
    [3] = {'https://discord.com/stickers/','.json', help.lottie2gif}
}

function sticker:run(param, perms)
    local message = help.resolveMessage(self, param)
    if not perms.bot:has'attachFiles' then return nil, 'i need image perms' end
    
    local data = help.APIget(message.channel, message.id)
    local stickers = data.stickers

    if not stickers then 
        local messages = API:getChannelMessages(self.channel.id)
        for i, m in pairs(messages) do
            if m.stickers then
                stickers = m.stickers
                break
            end
        end
    end

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
        return nil, 'need some stickers'
    end
end