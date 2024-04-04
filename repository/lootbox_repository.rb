require './framework/repository'

class LootBoxRepository < Repository

  # lb_user
  def add_user(discord_user_id)
    @db[:lb_user].insert(discord_id: discord_user_id, reaction_point: 30, opened_lootbox: 0)
  end

  def get_user(discord_user_id)
    @db['SELECT * FROM "lb_user" WHERE discord_id = ?', discord_user_id]
  end

  def add_user_points(user_id, additional_points)
    @db[:lb_user].where(id: user_id).update(reaction_point: Sequel[:reaction_point] + additional_points)
  end

  def use_user_points(user_id, use_points)
    @db[:lb_user].where(id: user_id).update(reaction_point: Sequel[:reaction_point] - use_points)
  end

  # lb_messages
  def add_message(discord_message_id, user_id)
    @db[:lb_messages].insert(user_id: user_id, message_id: discord_message_id, reactions: 0)
  end

  def get_message(discord_message_id)
    @db['SELECT * FROM "lb_messages" WHERE message_id = ?', discord_message_id]
  end

  def update_message_reactions(discord_message_id, reactions)
    @db[:lb_messages].where(message_id: discord_message_id).update(reactions: reactions)
  end

  # lb_items
  def get_items(item_id)
    @db[:lb_items].where(id: item_id)
  end

  def get_items_by_rarity(rarity)
    @db[:lb_items].where(rarity: rarity).all
  end

  def get_all_items
    @db[:lb_items]
  end

  # lb_user_inventory
  def add_inventory(user_id, item_id)
    @db[:lb_user_inventory].insert(user_id: user_id, item_id: item_id, get_date: Time.now)
  end

  def get_inventory(user_id)
    @db[:lb_user_inventory].where(user_id: user_id)
  end
end
