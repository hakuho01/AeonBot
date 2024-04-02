require './framework/repository'

class LootBoxRepository < Repository
  def add_user(discord_user_id)
    @db[:lb_user].insert(discord_id: discord_user_id, reaction_point: 0, opened_lootbox: 0)
  end

  def add_message(discord_message_id, user_id)
    @db[:lb_messages].insert(user_id: user_id, message_id: discord_message_id, reactions: 0)
  end

  def get_user(discord_user_id)
    @db['SELECT * FROM "lb_user" WHERE discord_id = ?', discord_user_id]
  end

  def get_message(discord_message_id)
    @db['SELECT * FROM "lb_messages" WHERE message_id = ?', discord_message_id]
  end

  def update_message_reactions(discord_message_id, reactions)
    @db[:lb_messages].where(message_id: discord_message_id).update(reactions: reactions)
  end

  def add_user_points(user_id, additional_points)
    @db[:lb_user].where(id: user_id).update(reaction_point: Sequel[:reaction_point] + additional_points)
  end
end
