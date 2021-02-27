local top = commands 'top'
top.help = 'replies to the first message in the channel'
top.alias = 'first' 

function top:run()
    return {
        content = e.rocket,
        message_reference = {
            message_id = self.channel:getFirstMessage().id
        }
    }, {safe = true}
end