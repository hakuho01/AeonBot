require './framework/component'
require './repository/lootbox_repository'

class LootBoxService < Component
  private

  def construct(bot)
    @bot = bot
    @lootbox_repository = LootBoxRepository.instance.init
  end

  public

  def add_reaction(event)
    return unless Time.now - event.message.timestamp <= 600

    discord_user_id = event.message.author.id
    discord_message_id = event.message.id

    # 新規ユーザー追加
    @lootbox_repository.add_user(discord_user_id) unless @lootbox_repository.get_user(discord_user_id).first

    # ユーザーID取得
    user_id = @lootbox_repository.get_user(discord_user_id).first[:id]

    # リアクション数計算
    reactions = 0
    event.message.reactions.each do |reaction|
      reactions += reaction.count
    end

    # 新規メッセージ追加
    @lootbox_repository.add_message(discord_message_id, user_id) unless @lootbox_repository.get_message(discord_message_id).first

    latest_reactions = @lootbox_repository.get_message(discord_message_id).first[:reactions]
    if reactions > latest_reactions
      @lootbox_repository.update_message_reactions(discord_message_id, reactions)
      additional_points = reactions - latest_reactions
      @lootbox_repository.add_user_points(user_id, additional_points)
    end
  end

  def lottery(event)
    lottery_times = event.message.content.split(' ')[2].to_i # TODO: 整数以外が入ってきた場合
    use_points = lottery_times * 3

    discord_user_id = event.message.user.id

    # ユーザーがなければ追加
    @lootbox_repository.add_user(discord_user_id) unless @lootbox_repository.get_user(discord_user_id).first

    # そうでなければユーザーID取得
    user = @lootbox_repository.get_user(discord_user_id).first
    user_id = user[:id]

    # 回す回数が不適切な場合
    unless 0 < lottery_times && lottery_times < 11
      event.respond('ボックスを開ける数を正しく指定して。一度に開けられるのは10箱まで。')
      return
    end

    # ポイントが足りない場合
    if user[:reaction_point] < use_points
      event.respond("……ポイントが足りない。あと#{user[:reaction_point] / 3}回までなら箱を開けられる。")
      return
    end

    # ポイント支払い
    @lootbox_repository.use_user_points(user_id, use_points)

    # ガチャ回す処理
    ratio = [65, 85, 95] # TODO: CONSTANTSに移す
    rarity_result = { c: 0, u: 0, r: 0, m: 0 }
    lottery_times.times do
      r_num = rand(1..100)
      case r_num
      when 1..ratio[0]
        rarity_result[:c] = rarity_result[:c] + 1
      when (ratio[0] + 1)..ratio[1]
        rarity_result[:u] = rarity_result[:u] + 1
      when (ratio[1] + 1)..ratio[2]
        rarity_result[:r] = rarity_result[:r] + 1
      when (ratio[2] + 1)..100
        rarity_result[:m] = rarity_result[:m] + 1
      end
    end

    content = ''
    if rarity_result[:c].positive?
      common_items = @lootbox_repository.get_items_by_rarity(1)
      rarity_result[:c].times do
        item = common_items.sample
        content << "## <:lb_#{item[:id]}:#{item[:icon_id]}> #{item[:item_name]} <:lb_common:1225000300172283935>```#{item[:flavor]}```
        "
        @lootbox_repository.add_inventory(user_id, item[:id])
      end
    end
    if rarity_result[:u].positive?
      uncommon_items = @lootbox_repository.get_items_by_rarity(2)
      rarity_result[:u].times do
        item = uncommon_items.sample
        content << "## <:lb_#{item[:id]}:#{item[:icon_id]}> #{item[:item_name]} <:lb_uncommon:1225000296950796338>```#{item[:flavor]}```
        "
        @lootbox_repository.add_inventory(user_id, item[:id])
      end
    end
    if rarity_result[:r].positive?
      rare_items = @lootbox_repository.get_items_by_rarity(3)
      rarity_result[:r].times do
        item = rare_items.sample
        content << "## <:lb_#{item[:id]}:#{item[:icon_id]}> #{item[:item_name]} <:lb_rare:1225000298750279700>```#{item[:flavor]}```
        "
        @lootbox_repository.add_inventory(user_id, item[:id])
      end
    end
    if rarity_result[:m].positive?
      mythic_items = @lootbox_repository.get_items_by_rarity(4)
      rarity_result[:m].times do
        item = mythic_items.sample
        content << "## <:lb_#{item[:id]}:#{item[:icon_id]}> #{item[:item_name]} <a:lb_mythic:1225000326428495982>```#{item[:flavor]}```
        "
        @lootbox_repository.add_inventory(user_id, item[:id])
      end
    end
    event.respond(content)
  end

  def check_point(event)
    discord_user_id = event.user.id

    # ユーザーがなければ追加
    @lootbox_repository.add_user(discord_user_id) unless @lootbox_repository.get_user(discord_user_id).first

    user = @lootbox_repository.get_user(discord_user_id).first
    response_sentense = "#{user[:reaction_point]}ポイントあるみたい。あと#{user[:reaction_point] / 3}回、箱を開けられる。"
    event.respond(response_sentense)
  end

  def check_inventory(event)
    discord_user_id = event.user.id

    # ユーザーがなければ追加
    @lootbox_repository.add_user(discord_user_id) unless @lootbox_repository.get_user(discord_user_id).first

    user = @lootbox_repository.get_user(discord_user_id).first

    inventories = @lootbox_repository.get_inventory(user[:id]).all
    grouped_inventories = inventories.group_by { |i| i[:item_id] }
    response_sentense = '## '
    inventory_list = []
    grouped_inventories.each_key do |n|
      inventory = @lootbox_repository.get_items(n).first
      response_sentense << "<:lb_#{inventory[:id]}:#{inventory[:icon_id]}>"
      inventory_list.push({ id: inventory[:id], rarity: inventory[:rarity] })
    end
    event.respond(response_sentense)

    all_items = @lootbox_repository.get_all_items.all

    total_item_number = all_items.length
    c_total_item_number = all_items.count { |item| item[:rarity] == 1 }
    u_total_item_number = all_items.count { |item| item[:rarity] == 2 }
    r_total_item_number = all_items.count { |item| item[:rarity] == 3 }
    m_total_item_number = all_items.count { |item| item[:rarity] == 4 }

    users_total_item_number = grouped_inventories.length
    users_c_total_item_number = inventory_list.count { |item| item[:rarity] == 1 }
    users_u_total_item_number = inventory_list.count { |item| item[:rarity] == 2 }
    users_r_total_item_number = inventory_list.count { |item| item[:rarity] == 3 }
    users_m_total_item_number = inventory_list.count { |item| item[:rarity] == 4 }

    total_possession_rate = (users_total_item_number.to_f / total_item_number * 100).floor
    c_possession_rate = (users_c_total_item_number.to_f / c_total_item_number * 100).floor
    u_possession_rate = (users_u_total_item_number.to_f / u_total_item_number * 100).floor
    r_possession_rate = (users_r_total_item_number.to_f / r_total_item_number * 100).floor
    m_possession_rate = (users_m_total_item_number.to_f / m_total_item_number * 100).floor

    possession_message = "総合 #{users_total_item_number}/#{total_item_number} (#{total_possession_rate}%)
コモン #{users_c_total_item_number}/#{c_total_item_number} (#{c_possession_rate}%)
アンコモン #{users_u_total_item_number}/#{u_total_item_number} (#{u_possession_rate}%)
レア #{users_r_total_item_number}/#{r_total_item_number} (#{r_possession_rate}%)
神話レア #{users_m_total_item_number}/#{m_total_item_number} (#{m_possession_rate}%)"

    event.respond(possession_message)
  end

  def check_inventory_stats(event)
    discord_user_id = event.user.id

    # ユーザーがなければ追加
    @lootbox_repository.add_user(discord_user_id) unless @lootbox_repository.get_user(discord_user_id).first

    user = @lootbox_repository.get_user(discord_user_id).first

    inventories = @lootbox_repository.get_inventory(user[:id]).all
    grouped_inventories = inventories.group_by { |i| i[:item_id] }
    inventory_list = []
    grouped_inventories.each_key do |n|
      inventory = @lootbox_repository.get_items(n).first
      inventory_list.push({ id: inventory[:id], rarity: inventory[:rarity] })
    end

    all_items = @lootbox_repository.get_all_items.all

    total_item_number = all_items.length
    c_total_item_number = all_items.count { |item| item[:rarity] == 1 }
    u_total_item_number = all_items.count { |item| item[:rarity] == 2 }
    r_total_item_number = all_items.count { |item| item[:rarity] == 3 }
    m_total_item_number = all_items.count { |item| item[:rarity] == 4 }

    users_total_item_number = grouped_inventories.length
    users_c_total_item_number = inventory_list.count { |item| item[:rarity] == 1 }
    users_u_total_item_number = inventory_list.count { |item| item[:rarity] == 2 }
    users_r_total_item_number = inventory_list.count { |item| item[:rarity] == 3 }
    users_m_total_item_number = inventory_list.count { |item| item[:rarity] == 4 }

    total_possession_rate = (users_total_item_number.to_f / total_item_number * 100).floor
    c_possession_rate = (users_c_total_item_number.to_f / c_total_item_number * 100).floor
    u_possession_rate = (users_u_total_item_number.to_f / u_total_item_number * 100).floor
    r_possession_rate = (users_r_total_item_number.to_f / r_total_item_number * 100).floor
    m_possession_rate = (users_m_total_item_number.to_f / m_total_item_number * 100).floor

    possession_message = "総合 #{users_total_item_number}/#{total_item_number} (#{total_possession_rate}%)
コモン #{users_c_total_item_number}/#{c_total_item_number} (#{c_possession_rate}%)
アンコモン #{users_u_total_item_number}/#{u_total_item_number} (#{u_possession_rate}%)
レア #{users_r_total_item_number}/#{r_total_item_number} (#{r_possession_rate}%)
神話レア #{users_m_total_item_number}/#{m_total_item_number} (#{m_possession_rate}%)"

    event.respond(possession_message)
  end
end
