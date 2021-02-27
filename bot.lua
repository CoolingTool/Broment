local discordia = require('discordia')
local client = discordia.Client{cacheAllMembers = true, logFile = '', logLevel = 0}
local time = discordia.Time
local date = discordia.Date
local class = discordia.class
local classes = class.classes
local color = discordia.Color
local API = client._api
local enum = discordia.enums
local logger = discordia.Logger(enum.logLevel.debug, '%F %T', '')
local log = function(...)
    logger:log(...)
end

local requireDiscordia = require('require')(select(2, module:resolve('discordia')))
local resolver = requireDiscordia('client/Resolver')

discordia.extensions()
require('%{format}')()

local http = require('coro-http')
local fs = require('fs')
local path = require('path')
local url = require('url')    
local json = require('json')
local timer = require('timer')
local pp = require('pretty-print')
local uv = require('uv')
local spawn = require('coro-spawn')
local lpeg = require('lpeg')
local lip = require('LIP')
local dofile = require('dofile')
local len = utf8.len

local defaultColor = color.fromRGB(38, 101, 144)
local config = lip.load('config.ini')

for i, p in pairs(config.paths) do
    local new = p:gsub("%%([^%%]+)%%", process.env)
    config.paths[i] = path.resolve(new)
end

local games = {}

for g in io.lines('misc/games.txt') do
    table.insert(games, g)
end

local variables = { -- update when new variable added -- }
    requireDiscordia = requireDiscordia, module = module,
    resolver = resolver, time = time, class = class, color = color,
    path = path, lpeg = lpeg, timer = timer, json = json,
    fs = fs, http = http, url = url, API = API, pp = pp,
    client = client, uv = uv, date = date, enum = enum, dofile = dofile,
    discordia = discordia, classes = classes, len = len,
    defaultColor = defaultColor, require = require, lip = lip,
    logger = logger, log = log, config = config, spawn = spawn,
    games = games,} variables.variables = variables 

local bot, prefixes, custom, appInfo, apiPing
client:once('ready', function()
    bot = client.user
    prefixes = {
        '<@%s>'%{bot.id},
        '<@!%s>'%{bot.id},
    }
    apiPing = 0/0
    custom = {}
    config.discord.emoji_server_id = config.discord.emoji_server_id:match'^"(.-)"$'
    local emojiServer = client:getGuild(config.discord.emoji_server_id)
    if emojiServer then
        for i, e in pairs(emojiServer.emojis) do
            custom[e.name] = e
        end
    end
    appInfo = client:getApplicationInformation()
    variables.custom = custom; variables.bot = bot; variables.apiPing = apiPing
    variables.prefixes = prefixes; variables.appInfo = appInfo

    log(enum.logLevel.info,
        "Successfully started with %s users in %s servers.",
        table.count(client._users), table.count(client.guilds)
    )

    timer.setInterval(10000, function()
        coroutine.wrap(client.setGame)(client, games[math.random(#games)])
    end)
end)

local help = dofile('libs/help.lua', variables)
variables.help = help
local e = variables.e

commands = dofile('cmds', variables)
variables.commands = commands
for _, file in pairs(fs.readdirSync('cmds')) do
    if file ~= 'init.lua' then
        dofile(path.join('cmds', file), variables)
    end
end

client:on('messageCreate', function(msg)
    local author, channel, guild = msg.author, msg.channel, msg.guild

    local role = ((guild and help.getBotRole(guild)) or {})
    local botRole = role.mentionString

    local semiMention = '@'..(help.getNick(bot, channel))
    local semiRoleMention = botRole and '@'..(role.name)
    
    local hasCumber = msg.content:find(e.cucumber) or
        msg.content:lower():find'c?u?%-?cumb[ae]r?'

    local cmdQuery, param = help.cmdParse(msg, {
        ';',
        botRole,
        bot.name,
        semiMention,
        semiRoleMention,
        e.people_hugging,
        channel.type == enum.channelType.private and '',
    })

    if hasCumber or cmdQuery then
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
end)

client:on('messageUpdate',function(msg)
    if msg.author == bot
    and msg:hasFlag(enum.messageFlag.suppressEmbeds)
    and not msg._keepEmbedHidden  then
        msg:showEmbeds()
    end
end)

client:on('heartbeat', function(_, ping)
    apiPing = ping
    variables.apiPing = apiPing
end)

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

client:on('commandTriggered', function(interaction)
    interaction:reply(5)
end)

client:on('info', function(message)
    log(enum.logLevel.info, message)
end)

client:on('error', function(message)
    log(enum.logLevel.error, message)
end)

client:run((config.discord.bot and 'Bot ' or '') .. config.discord.token) 

--to prevent me from accidentally leaking token with p()
config.discord.token = nil