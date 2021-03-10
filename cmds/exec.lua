local exec = commands 'exec'
exec.alias = 'eval'
exec.hidden = true

function exec:run(param, perms)
    if self.author.id ~= client.owner.id then
        return nil, 'you can\'t use this command'
    end

    if not param then return nil, 'need code' end

    param = param:match('^```.-\n(.+)\n?```$') or param 

    local out = ''

    local sandbox = table.copy(variables)

    sandbox.self = self
    sandbox.param = param
    sandbox.perms = perms
    sandbox.io = table.copy(io)

    function sandbox.print(...) out = out .. help.printLine(...) end
    function sandbox.p(...) out = out .. help.prettyLine(...) end
    function sandbox.io.write(...) out = out .. table.concat{...} end
        
    setmetatable(sandbox,{__index=_G})

    local f, err = load(param, "exec", 't', sandbox)

    local stored
    if err then
        error(err, 0)
    else
        stored = table.pack(f())
    end

    out = out:gsub(' *\n','\n')

    if #out > 0 then
        local form = '>>> `%s`'
        local msgLimit = 2000 - (len(form) - 2)
        local rep = math.ceil(len(out) / msgLimit)
        for i = 1, rep do 
            assert(help.APIsend(self.channel, {content = form%{help.codeEsc(out:sub(msgLimit * (i - 1) + 1, msgLimit * i))}, allowed_mentions = {parse = {}}}))
        end
    end

    return table.unpack(stored)
end