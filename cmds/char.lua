local char = commands 'char' '[chars]'
char.help = 'get char info (limited to 15 at a time)'

function char:run(param)
    if not param then return nil, 'text characters needed' end
    if len(param) > 15 then return nil, 'no more than 15 characters at a time' end

    local info = {}
    for p, c in utf8.codes(param) do
        local link = F'https://www.fileformat.info/info/unicode/char/${c:%x}/index.htm'

        local name, code = select(3, pcall(http.request, 'GET', link))
            :match('"og:title" content="([^%(]+)%(([^%)]+)%)"')

        local char = utf8.char(c)

        table.insert(info, F"`${code}`: ${name}(${char}) - ${link}")
    end

    return table.concat(info, "\n")
end