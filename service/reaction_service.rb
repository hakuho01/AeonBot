# frozen_string_literal: true

require './framework/component'
require './repository/reaction_repository'
require 'dotenv'

Dotenv.load
REACTION_TARGET_SERVER_ID = ENV['SERVER_ID'].to_i

class ReactionService < Component
  private

  def construct(bot = nil)
    @bot = bot
    @reaction_repository = ReactionRepository.instance.init
  end

  public

  def record_reaction(event)
    # イオン鯖のみカウント
    return unless event.server&.id == REACTION_TARGET_SERVER_ID

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

  def get_all_reaction_stats(server_id)
    return 'サーバー情報が取得できません。' if @bot.nil?

    server = @bot.server(server_id)
    return 'サーバーが見つかりません。' if server.nil?

    # DBから全リアクションを取得
    all_reactions = @reaction_repository.get_all_reactions
    reaction_map = {}
    all_reactions.each do |reaction|
      reaction_map[reaction[:reaction_id]] = reaction
    end

    # サーバーのカスタム絵文字を取得
    custom_emojis = server.emoji.to_a.map { |_k, emoji| emoji }

    # カスタム絵文字も含めたランキングを作成
    all_rankings = []

    # 通常絵文字（DBにあるもの）
    all_reactions.each do |reaction|
      next if reaction[:is_custom] # カスタム絵文字は後で処理

      all_rankings << {
        reaction_id: reaction[:reaction_id],
        emoji_name: reaction[:emoji_name],
        is_custom: false,
        count: reaction[:count]
      }
    end

    # カスタム絵文字（サーバーにあるものすべて、0件でも含める）
    custom_emojis.each do |emoji|
      reaction_id_str = emoji.id.to_s
      db_reaction = reaction_map[reaction_id_str]

      all_rankings << {
        reaction_id: reaction_id_str,
        emoji_name: emoji.name,
        is_custom: true,
        count: db_reaction ? db_reaction[:count] : 0
      }
    end

    # カウント順にソート
    all_rankings.sort_by! { |r| -r[:count] }

    return ['まだリアクションのデータがありません。'] if all_rankings.empty?

    # 統計メッセージを分割して作成（2000文字制限対策）
    messages = []
    current_message = "**リアクション統計（全件）**\n\n"
    max_length = 1900 # 安全マージン

    all_rankings.each_with_index do |reaction, index|
      # カスタム絵文字の場合は <:name:id> 形式、通常絵文字の場合はそのまま表示
      emoji_display = if reaction[:is_custom]
                        "<:#{reaction[:emoji_name]}:#{reaction[:reaction_id]}>"
                      else
                        reaction[:emoji_name]
                      end

      line = "#{index + 1}. #{emoji_display}：#{reaction[:count]}回\n"

      # メッセージが長くなりすぎる場合は分割
      if (current_message.length + line.length) > max_length
        messages << current_message
        current_message = "(続き)\n\n"
      end

      current_message += line
    end

    # 最後のメッセージを追加
    messages << current_message unless current_message.empty?

    messages
  rescue StandardError => e
    puts "Error getting all reaction stats: #{e.message}"
    ['統計の取得中にエラーが発生しました。']
  end
end
