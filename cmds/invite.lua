local invite = commands 'invite'
invite.help = 'invite broment to your own server!'

function invite:run()
    return
    "<https://discord.com/api/oauth2/authorize?client_id="..
        appInfo.id..
        "&permissions=2147483639&scope=applications.commands%20bot>"
end