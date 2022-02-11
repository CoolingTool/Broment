local suppress = commands 'suppress' '[message]'
suppress.help = 'hide/show the embeds of a message'
suppress.alias = {
    'supress',
    'hideEmbeds', 'hide-embeds', 'hide_embeds',
    'hideEmbed', 'hide-embed', 'hide_embed',
    'showEmbeds', 'show-embeds', 'show_embeds',
    'showEmbed', 'show-embed', 'show_embed',
}

function suppress:run(param, perms)
    local msg = help.resolveMessage(self, param, true)

    if not msg then return nil, 'message needed' end
    if not perms.user:has'manageMessages' then
        return nil, 'you must have the manage messages permission'
    end
    if not perms.bot:has'manageMessages' then
        return nil, 'i must have the manage messages permission'
    end

    local flag = msg:hasFlag(enum.messageFlag.suppressEmbeds)

    local done = e.ballot_box_with_check

    if flag then msg:showEmbeds() else msg:hideEmbeds() end

    if perms.bot:has'addReactions' then
        self:addReaction(done)
    else
        return done
    end
end