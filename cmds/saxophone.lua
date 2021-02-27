local saxophone = commands 'saxophone' '[emoji]*'
saxophone.help = 'puts an animal infront of a '..e.saxophone
saxophone.alias = {'sax', 'saxo'}

local list = {
    e.monkey, e.bird, e.baby_chick,
    e.duck, e.dodo, e.eagel, e.bug,
    e.snail, e.ant, e.cricket, e.snake,
    e.lizard, e.shrimp, e.blowfish,
    e.seal, e.dolphin, e.shark, e.bison,
    e.dromedary_camel, e.camel, e.giraffe,
    e.kangaroo, e.water_buffalo, e.ox,
    e.cow2, e.racehorse, e.pig2, e.ram,
    e.llama, e.goat, e.dog2, e.poodle,
    e.guide_dog, e.service_dog, e.cat2
}

function saxophone:run(param)
    local em
    if param then
        em = e[param]
        local c = param:find'^<a?:.+:%d+>$'
        if c then
            em = param
        end
        if not em then
            local l = help.twemoji(param)

            local s, r = pcall(http.request, 'HEAD', l)
            if s and (r.code == 200) then
                em = param
            end
        end
    end
    em = em or list[math.random(#list)]

    return e.saxophone..em
end