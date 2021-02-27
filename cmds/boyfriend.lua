local boyfriend = commands 'boyfriend' '[text]'
boyfriend.help = "aa-ba bop skda baap-aa skde be-bap baap-bop-bep\n"..
    "(converts text to friday night funkin gibberish)"
    boyfriend.alias = {'bf', 'fnf', 'funkin'}

local dialog = {
    "ee", "oo", "aa",
    "be", "bo", "ba",
    "de", "do", "da",
    "pe", "po", "pa",
    "bep", "bop", "bap",
    "beep", "boop", "baap",
    "skde", "skdo", "skda",
}

function boyfriend:run(param)
    if not param then
        return "aa-bap skde aa beep skda-bep........ (sorry guy but text needed........)"
    end

    return string.gsub(param, "%a+", function(word)
        local word = word:lower()

        local syll = help.countSyllables(word)

        if syll > 0 then
            local n = help.text2decimal(word)

            math.randomseed(n)

            local ret = {}
            for i = 1, syll do
                ret[#ret+1] = dialog[math.random(#dialog)]
            end

            return table.concat(ret, "-")
        else
            return word
        end
    end)
end