# frozen_string_literal: true

require './framework/component'
require './repository/reaction_repository'

class ReactionService < Component
  private

  def construct
    @reaction_repository = ReactionRepository.instance.init
  end

  public

  def record_reaction(event)
    # カスタム絵文字かどうかを判定
    is_custom = !event.emoji.id.nil?

    # リアクションIDを取得（カスタム絵文字の場合はID、通常絵文字の場合はUnicode）
    reaction_id = event.emoji.id || event.emoji.name
    reaction_id_str = reaction_id.to_s

    # 絵文字の名前を取得
    emoji_name = event.emoji.name

    # DBに記録
    @reaction_repository.record_reaction(reaction_id_str, emoji_name, is_custom)
  rescue StandardError => e
    puts "Error recording reaction: #{e.message}"
  end

  def get_reaction_stats
    top_reactions = @reaction_repository.get_top_reactions(10)

    return 'まだリアクションのデータがありません。' if top_reactions.empty?

    # 統計メッセージを作成
    stats_message = "**リアクション統計 Top 10**\n\n"

    top_reactions.each_with_index do |reaction, index|
      # カスタム絵文字の場合は <:name:id> 形式、通常絵文字の場合はそのまま表示
      emoji_display = if reaction[:is_custom]
                        "<:#{reaction[:emoji_name]}:#{reaction[:reaction_id]}>"
                      else
                        reaction[:emoji_name]
                      end

      stats_message += "#{index + 1}. #{emoji_display}：#{reaction[:count]}回\n"
    end

    stats_message
  rescue StandardError => e
    puts "Error getting reaction stats: #{e.message}"
    '統計の取得中にエラーが発生しました。'
  end
end
