local emote = commands 'emote' '[emoji]'
emote.alias = {'enlarge', 'emoji', 'e', 'em', 'hugeemoji', 'hugemoji'}
emote.help = 'posts the image of the emoji you put in'

function emote:run(param, perms)
    if not param then return nil, 'emoji needed' end
    if not perms.bot:has'attachFiles'then return nil, 'i need image perms' end

    local query = param

    self.channel:broadcastTyping()

    local a, custom, id = query:match'^<(a?):(.+):(%d+)>$'

    id = query:find("^%d+$") and query or id

    local filename, source, link, show
    if id then
        local ext = a == '' and '.png' or '.gif'
        
        if not a then
            local success, res, ret = pcall(http.request, 'HEAD', 'https://cdn.discordapp.com/emojis/%s.gif'%{id})

            if res.reason ~= "OK" then 
                local success, res, ret = pcall(http.request, 'HEAD', 'https://cdn.discordapp.com/emojis/%s.png'%{id})
            
                if not success then return nil, 'had an oopsie' end
                if res.reason ~= "OK" then return nil, 'not an emoji' end
            end

            custom, ext = id, res.reason ~= "OK" and ".png" or ".gif"
        end

        link = 'https://cdn.discordapp.com/emojis/%s%s'%{id, ext}
    else
        local success, res, svgSource
        for i = 1, 2 do
            if i == 2 then 
                query = e[query]
                if not query then return nil, 'not an emoji' end 
            end
            link = help.twemoji(query, {size = 'svg', ext = '.svg'})

            success, res, svgSource = pcall(http.request, 'GET', link)

            if not success then return nil, 'had an oopsie' end
            if res.code == 200 then break end
        end
        
        filename, source = 'emoji.png', help.svg2png(svgSource, 512, 512)
    end
    return {
        content = (filename and '<'..link..'>' or link)..' _ _',
        file = help.boolNil(filename and {filename, source})
    }
end