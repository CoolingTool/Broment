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