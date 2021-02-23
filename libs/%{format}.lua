local meta = getmetatable''

return function()
    function meta:__mod(vals)
        return string.format(self, table.unpack(vals))
    end
end