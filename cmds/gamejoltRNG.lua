local gamejoltRNG = commands 'gamejoltRNG'
gamejoltRNG.help = 'brings up a completely random game from gamejolt.com'
gamejoltRNG.alias = {'gjRNG', 'gj-rng', 'gj_rng', 'gamejolt-rng', 'gamejolt_rng'}

local host = 'https://gamejolt.com'
local header = {{'User-Agent', 'Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)'}}
-- pretend to be discord : troll :

function gamejoltRNG:run()
    for i = 1, 30 do
        local link = host..'/games/a/'..math.random(2,670000)
        -- as of december 10th 2021 games above 670000 don't exist
        
        local succ, res = pcall(http.request, 'HEAD', link, header)

        if res.code == 301 then
            for i = 1, #res do
                local key, location = unpack(res[i])
                if key == "location" then
                    return host .. location 
                end
            end
        end
    end

    return nil, 'couldnt find a game'
end