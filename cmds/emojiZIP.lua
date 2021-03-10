local emojiZIP = commands 'emojiZIP' '[server]'
emojiZIP.help = 'archive every emoji in a server'
emojiZIP.alias = {
    'emoji-zip', 'emoji_zip',
    'emojiArchive', 'emoji-archive', 'emoji_archive',
    'stealEmojis', 'steal-emojis', 'steal_emojis'
}

function emojiZIP:run(param, perms)
    if not perms.bot:has('attachFiles') then  return nil, 'need post file perms' end

    local guild = param and client:getGuild(param) or (not param and self.guild)

    if not guild then return nil, 'guild needed' end

    if #guild.emojis == 0 then return nil, 'this server has no emojis' end

    local write = miniz.new_writer()
    local message = self:reply('please wait im downloading every emoji in this server and putting it into a zip')
    self.channel:broadcastTyping()

    for i, e in pairs(guild.emojis) do
        local data = select(3, pcall(http.request, 'GET', e.url))
        write:add(e.name..F".${e.animated and 'gif' or 'png'}", data, 9)
    end

    return {file = {F'${guild.name:lower()} emojis ${date():toISO()}.zip', write:finalize()}}, {remove = message}
end