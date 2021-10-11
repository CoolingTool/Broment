local sticker = commands 'sticker' '[message]'
sticker.alias = {
    'stealSticker', 'steal-sticker', 'steal_sticker',
    'stickerSteal', 'sticker-steal', 'sticker_steal',
    'getSticker', 'get-sticker', 'get_sticker',
    's'
}
sticker.help = 'gets sticker and converts it to gif'

local format = {
    [1] = {'https://media.discordapp.net/stickers/','.png', nil},
    [2] = {'https://media.discordapp.net/stickers/','.png', help.apng2gif},
    [3] = {'https://discord.com/stickers/','.json', help.lottie2gif}
}

function sticker:run(param, perms)
    local message = help.resolveMessage(self, param)
    if not perms.bot:has'attachFiles' then return nil, 'i need image perms' end
    
    local data = help.APIget(message.channel, message.id)
    local stickers = data.stickers or data.sticker_items -- thanks for being inconsistant discord

    if not stickers then 
        local messages = table.reversed(API:getChannelMessages(self.channel.id))
        for i, m in pairs(messages) do
            if (m.stickers or m.sticker_items) then
                stickers = m.stickers or m.sticker_items
            end
        end
    end

    if stickers then
        local wait = self:reply("this might take a minute")
        self.channel:broadcastTyping()
        local sticker = select(2, next(stickers))
        local known = format[sticker.format_type]
        if known then
            local link = known[1]..sticker.id..known[2]
            
            local succ, res, source = pcall(http.request, 'GET', link)

            local action = known[3]
            if not action then -- if action is nil discord can probably display it on its own
                return link..' _ _', {remove = wait}
            else
                local result = action(source)
                
                return {
                    content = '<'..link..'>',
                    file = {'%s.gif'%{sticker.name}, result}
                }, {remove = wait}
            end
        else
            return nil, 'i don\'t know how to get the link of this sticker'
        end
    else
        return nil, 'need some stickers'
    end
end