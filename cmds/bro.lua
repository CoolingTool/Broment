local bro = commands 'bro' '[p1]; [p2]'
bro.help = 'tests how much of bros two people are'
bro.flags = {
    help.textFlag
}
bro.alias = {'bromometer', 'ship'}

local icons = {
    e.bust_in_silhouette,
    e.speaking_head,
    e.busts_in_silhouette,
    e.people_hugging,
}

function bro:run(param, perms)
    local param, args = help.dashParse(param)
    local p1, p2 = help.split(param)

    if (not p1) then p1 = self.author.id end
    if (not p2) and self.guild then p2 = 'random' end 

    if not p2 then
        return nil, '`[p2]` expected'
    end

    p1 = help.resolveUser(self, p1, true, .75) or p1
    p2 = help.resolveUser(self, p2, true, .75) or p2

    math.randomseed(
        (class.isObject(p1) and p1.id or help.text2decimal(p1:lower()))
        +
        (class.isObject(p2) and p2.id or help.text2decimal(p2:lower()))
        +
        (os.date('%H'))
    )

    math.random(); math.random(); math.random(); 

    local n = math.random(100)
    local p = math.round(n / 10)

    local title =
        e.people_hugging..
        ' **BROMOMETER** '..
        e.people_hugging..'\n'..

        e.small_blue_diamond..
        (class.isObject(p1) and help.getNick(p1, self.channel) or p1)..'\n'..
        e.small_blue_diamond..
        (class.isObject(p2) and help.getNick(p2, self.channel) or p2)

    local desc = 
        '**'..n..'%'..'** '..
        e.blue_square:rep(p)..
        e.black_large_square:rep(10 - p)

    local icon = icons[math.ceil(n / 25)]

    if args.t or not perms.bot:has'embedLinks' then
        return '>>> '..title..'\n'..desc..' '..icon,
        {safe = true}
    else
        return help.embed(nil, {
            title = title,
            description = desc,
            thumbnail = {url = help.twemoji(icon)},
            author = {},
        })
    end
end