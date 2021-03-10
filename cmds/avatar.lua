local avatar = commands 'avatar' '[user]*'
avatar.help = 'fetches users avatar link for you'
avatar.alias = {'avater', 'pfp', 'profilePicture', 'profile-picture', 'profile_picture', 'icon'}
avatar.flags = {
    {'default',
    'shows default avatar'},
    {'size',
    'changes image size (16 - 4096)', 'NUMBER'},
    {'archive',
    'downloads image incase avatar link expires'}
}

function avatar:run(...)
    local param, args = help.dashParse(...)

    local user = help.resolveUser(self, param)

    local size = tonumber(args.s) and 
        math.clamp(
            math.pow(2, math.ceil(math.log(args.s)/math.log(2))),
            16, 4096
        ) or 1024

    local link = args.d and user:getDefaultAvatarURL(size) or user:getAvatarURL(size)
    local ext = user._avatar:find('a_') == 1 and 'gif' or 'png'

    if args.a then
        local wait = self:reply('downloading avatar...')
        self.channel:broadcastTyping()
        local data = select(3, pcall(http.request, 'GET', link))

        return {content = '<'..link..'>', file = {
            user.name..'.'..(user._avatar:find('a_') == 1 and 'gif' or 'png'),
            data
        }}, {remove = wait}
    else
        return link..' _ _'
    end
end