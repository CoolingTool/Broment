local base64image = commands 'base64image' '[base64]'
base64image.help = 'turn a base64 image to its original form'
base64image.alias = {
    'base64-image', 'base64_image',
    'base64img', 'base64-img', 'base64_img',
    'b64image', 'b64-image', 'b64_image',
    'b64img', 'b64-image', 'b64_image'
}

function base64image:run(param, perms)
    if not perms.bot:has'attachFiles' then 
        return nil, 'need image perms'
    end

    self.channel:broadcastTyping()
    
    local url = self.attachment and self.attachment.url:find(".txt$") and self.attachment.url  
    if url then
        local succ, res, source = pcall(http.request, "GET", url, nil, nil, 10000)
        assert(succ, res)

        param = source
    end

    if not param then return nil, 'base64 expected' end

    local ext, data = param:match"^data:image/(%a+);base64,([%w%//%+%=]+)$"

    if ext then
        return {
            file = {table.concat({self.id,ext},'.'), openssl.base64(data,false)}
        }
    else
        return nil, '`data:image/{ext};base64,{base64}}` expected'
    end
end