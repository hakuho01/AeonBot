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

    discord_user_id = event.user.id
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
    user = @lootbox_repository.get_user(discord_user_id).first

    return unless user # ユーザー未登録ならreturn

    user_id = user[:id] # そうでなければユーザーID取得

    # 回す回数が不適切な場合
    unless 0 < lottery_times && lottery_times < 11
      event.respond('ガチャを回す数を正しく指定して。')
      return
    end

    # ポイントが足りない場合
    if user[:reaction_point] < use_points
      event.respond('……ポイントが足りない。')
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

    result = ''
    if rarity_result[:c].positive?
      common_items = @lootbox_repository.get_items_by_rarity(1)
      rarity_result[:c].times do
        item = common_items.sample
        result << item[:item_name] << ' '
        @lootbox_repository.add_inventory(user_id, item[:id])
      end
    end
    if rarity_result[:u].positive?
      uncommon_items = @lootbox_repository.get_items_by_rarity(2)
      rarity_result[:u].times do
        item = uncommon_items.sample
        result << item[:item_name] << ' '
        @lootbox_repository.add_inventory(user_id, item[:id])
      end
    end
    if rarity_result[:r].positive?
      rare_items = @lootbox_repository.get_items_by_rarity(3)
      rarity_result[:r].times do
        item = rare_items.sample
        result << item[:item_name] << ' '
        @lootbox_repository.add_inventory(user_id, item[:id])
      end
    end
    if rarity_result[:m].positive?
      mythic_items = @lootbox_repository.get_items_by_rarity(4)
      rarity_result[:m].times do
        item = mythic_items.sample
        result << item[:item_name] << ' '
        @lootbox_repository.add_inventory(user_id, item[:id])
      end
    end

    event.respond(result)
  end

  def check_point(event)
    discord_user_id = event.user.id
    user = @lootbox_repository.get_user(discord_user_id).first
    response_sentense = if user.nil?
                          '……あなたのデータが、見当たらない。'
                        else
                          "#{user[:reaction_point]}ポイントあるみたい。あと#{(user[:reaction_point] / 3).floor}回、ガチャが回せる。"
                        end
    event.respond(response_sentense)
  end

  def check_inventory(event)
    discord_user_id = event.user.id
    user = @lootbox_repository.get_user(discord_user_id).first
    if user.nil?
      response_sentense = '……あなたのデータが、見当たらない。'
    else
      inventories = @lootbox_repository.get_inventory(user[:id]).group_by(:item_id).select_group(:item_id)
      inventory_list = ''
      inventories.each do |n|
        inventory = @lootbox_repository.get_items(n[:item_id]).first
        inventory_list << inventory[:item_name] << ' '
      end
      response_sentense = "#{inventory_list}"
    end
    event.respond(response_sentense)
  end
end
