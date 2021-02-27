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