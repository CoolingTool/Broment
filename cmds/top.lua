local top = commands 'top'
top.help = 'replies to the first message in the channel'
top.alias = 'first' 

function top:run()
    return e.rocket, {safe = true, reply = self.channel:getFirstMessage()}
end