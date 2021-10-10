local discordia = require('discordia')
local slash = require("discordia-slash")
local client = discordia.Client{cacheAllMembers = true, logFile = '', logLevel = 0}:useSlashCommands()
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
local F = require("F")
local dofile = require('dofile')
local miniz = require('miniz')
local openssl = require('openssl')
local thread = require('thread')
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
    openssl = openssl, miniz = miniz, thread = thread,
<<<<<<< HEAD
    querystring = querystring, slash = slash, 
=======
>>>>>>> parent of bcb47c3 (add fapi (the thing notsobot uses for images))
    games = games, F = F} variables.variables = variables 

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

local commands = dofile('cmds', variables)
variables.commands = commands
for i, f in pairs(fs.readdirSync('cmds')) do
    if f ~= 'init.lua' then
        dofile(path.join('cmds', f), variables)
    end
end

local events = dofile('libs/events.lua', variables)
variables.events = events
for i, e in pairs(events) do
    client:on(i, e)
end

client:run((config.discord.bot and 'Bot ' or '') .. config.discord.token) 
config.discord.token = nil