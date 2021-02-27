local o = commands 'o' '[o] [o]'
o.alias = {}
for _o = 1, 32 do
    table.insert(o.alias, 'o')
end
o.help = 'o'
o.hidden = true

local list = {'.', '!', '?', ',', ''}

function o:run(param)
    return 'o' .. list[math.random(#list)], {safe = true}
end


local lavadrop = commands 'lavadrop'
lavadrop.superDuperHidden = true

function lavadrop:run(param, perms)
    if perms.bot:has'embedLinks' then
        return {
            embed = {
                title = "__**Incorrect usage**__",
                color = 0xff0056,
                fields = {{
                    name = "Correct Usage:",
                    value = "lava help <command>(optional)"
                }},
                description = "**That's not a valid command**"
            }
        }
    end
end


local error = commands 'error' '[command]*; [error]*'
error.help = "you talk a lotta big game for someone with such a small truck"
error.hidden = true

function error:run(param)
    local cmd, err = help.split(param)
    return string.format(
        'sorry guy there was a error when running command `%s`\n%s',
        cmd, help.code(help.concat"\n"(err, debug.traceback()),'rs')
    ), {safe = true}
end


local sorry = commands 'sorry' '[text]*'
sorry.help = "stupid horse, i just fell out of the porsche"
sorry.hidden = true

function sorry:run(param)
    return string.format(
        'sorry guy but %s........',
        param
    ), {safe = true}
end


local hidden = commands 'hidden'
hidden.superDuperHidden = true

function hidden:run(param)
    return nil, 'you werent supposed to see me, im supposed to be hidden'
end


local init = commands 'init'
init.superDuperHidden = true

function init:run(param)
    return nil, 'meta (not a command)'
end



