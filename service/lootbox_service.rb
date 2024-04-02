# frozen_string_literal: true

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
end
