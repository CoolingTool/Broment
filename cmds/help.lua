local cmds = commands 'help' '[command]*'
cmds.flags = {help.textFlag}
cmds.alias = {'commands', 'cmd', 'command', 'cmds', 'h', 'helper'}
cmds.help = 'gets a list of commands'

local ignore = {
    name = true, run = true, help = true,
    param = true, alias = true, index = true
}

function cmds:run(param, perms)
    local param, args = help.dashParse(param)

    if math.random(1,100) <= 1 then
        return "Your BotGhost premium trial has expired! Please visit https://www.botghost.com/ for more information"
    end

    local tip, list, list2, rows
    local title, title2
    if param then --get command
        local param = param:lower()
        local cmd = commands:find(param)
        if (not cmd) or cmd.superDuperHidden then return param..' is not a command', {safe = true} end

        local aliases = {}
        if type(cmd.alias) == 'string' then
            aliases[1] = cmd.alias
        elseif cmd.alias then
            for i, a in pairs(cmd.alias) do
                table.insert(aliases, a)
            end
        else
            aliases[1] = 'None'
        end
        table.sort(aliases)

        rows = help.rowConcat"> <"(aliases)

        tip = help.style.format(cmd)

        title =  '<!--Aliases-->\n'
        list =  help.style.name(table.concat(rows, "\n", 1, math.ceil(#rows / 2)))
        title2 = '<!--       -->\n'
        list2 = help.style.name(table.concat(rows, "\n", math.ceil(#rows / 2) + 1, #rows))
    else --get commands
        local main = {}
        for i, c in pairs(commands) do
            if (not c.hidden) and (not c.superDuperHidden) then
                table.insert(main, c.name)
            end
        end
        table.sort(main)

        rows = help.rowConcat("> <")(main)
        
        tip = help.style.help('Get info on a command\n'..
            'by running help [cmd]')

        title =  '<!--Commands-->\n'
        list = help.style.name(table.concat(rows, "\n", 1, math.ceil(#rows / 2)))
        title2 = '<!--        -->\n'
        list2 = help.style.name(table.concat(rows, "\n", math.ceil(#rows / 2) + 1, #rows))
    end

    if args.t or not perms.bot:has'embedLinks' then
        return help.textEmbed("Commands",
            help.style.line..'\n'..
            help.style.code(
                tip..'\n\n'..

                title..list..'\n'..list2
            )
        ), {safe = true}
    else
        return help.embed("Commands", {
            description = help.style.multiLine..help.style.code(tip),
            fields = {
                {name = help.style.multiLine, value = help.style.code(title..list), inline = true},
                {name = help.style.multiLine, value = help.style.code(title2..help.linePad(list2, math.ceil(#rows / 2))), inline = true},
            }
        })
    end
end