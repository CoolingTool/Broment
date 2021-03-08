local regional = commands 'regional' '[text]'
regional.help = 'turn text into the big blue emoji'

function regional:run(param)
    if not param then return nil, 'text needed' end

    return param
        :gsub('[%d%#%*]', '%1\239\184\143\226\131\163') -- numbers
        :gsub('%a+', function(word)
            local tbl = {}
            for l in word:gmatch('.') do
                table.insert(tbl, utf8.char(l:upper():byte() - 65 + 127462))
            end
            return table.concat(tbl, utf8.char(0x200b))
        end)
end