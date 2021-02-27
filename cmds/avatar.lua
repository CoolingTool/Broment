local avatar = commands 'avatar' '[user]*'
avatar.help = 'fetches users avatar link for you'
avatar.alias = {'avater', 'pfp', 'profilePicture', 'profile-picture', 'profile_picture', 'icon'}
avatar.flags = {
    {'default',
    'shows default avatar'},
    {'size',
    'changes image size (16 - 4096)', 'NUMBER'}
}

function avatar:run(...)
    local param, args = help.dashParse(...)

    local user = help.resolveUser(self, param)

    local size = tonumber(args.s) and 
        math.clamp(
            math.pow(2, math.ceil(math.log(args.s)/math.log(2))),
            16, 4096
        ) or 1024

    return (args.d and 
        user:getDefaultAvatarURL(size) or
        user:getAvatarURL(size))
        ..' _ _',
        {safe = true}
end