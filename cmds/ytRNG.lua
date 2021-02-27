local ytRNG = commands 'ytRNG'
ytRNG.help = 'scrapes random youtube video from petittube.com'
ytRNG.alias = {'petittube', 'yt-rng', 'yt_rng'}

function ytRNG:run()
    self.channel:broadcastTyping()
    
    local succ, body, res = pcall(http.request, "GET", "https://petittube.com/" )

    return 'http://youtu.be/'..
    res:match("https://www%.youtube%.com/embed/([^?]+)?")
end