# frozen_string_literal: true

require 'dotenv'
require './framework/component'
require './repository/channel_activity_repository'
require './repository/summary_repository'
require './config/constants'
require './util/api_util'

Dotenv.load
SERVER_ID = ENV['SERVER_ID']&.to_i
SUMMARY_CH_ID = ENV['SUMMARY_CH_ID']
GEMINI_API_KEY = ENV['GEMINI_API_KEY']

class SummaryService < Component
  private

  def construct(bot)
    @bot = bot
    @activity_repo = ChannelActivityRepository.instance.init
    @summary_repo = SummaryRepository.instance.init
  end

  public

  # メッセージ1件ごとに分バケットへカウント
  def record_activity(event)
    return unless event.server&.id == SERVER_ID
    return if event.author&.bot_account

    minute_ts = Time.at((Time.now.to_i / 60) * 60)
    @activity_repo.increment_bucket(event.channel.id.to_s, minute_ts)
  rescue StandardError => e
    puts "Summary record_activity error: #{e.message}"
  end

  # 毎分実行想定
  def process
    return if SERVER_ID.nil? || SUMMARY_CH_ID.nil?

    now_i = Time.now.to_i
    # TTL 15分
    ttl_cutoff = Time.at(now_i - 15 * 60)
    @activity_repo.delete_older_than(ttl_cutoff)

    # 直近15分に活動のあったチャンネルを対象に、直近10分の流速判定
    active_channels = @activity_repo.active_channel_ids_since(ttl_cutoff)
    active_channels.each do |ch_id|
      # クールダウン（15分）
      next if @summary_repo.summarized_recently?(ch_id, now_i, 15)

      total = @activity_repo.total_count_last_minutes(ch_id, now_i, 10)
      next unless total >= 30

      summarize_and_post(ch_id)
    end
  rescue StandardError => e
    puts "Summary process error: #{e.message}"
  end

  def summarize_and_post(channel_id)
    ch = @bot.channel(channel_id)
    return if ch.nil?

    # 直近15分・最大50件を取得
    cutoff_time = Time.now - (15 * 60)
    # history は新しい順で返るため、必要数を多めに取得してフィルタ
    msgs = ch.history(200)
      .select { |m| m.timestamp && m.timestamp >= cutoff_time }
      .reject { |m| m.author&.bot_account }
      .first(50)

    return if msgs.empty?

    # 要約入力を組み立て
    lines = msgs.reverse.map do |m|
      content = m.content.to_s.strip
      next nil if content.empty?
      name = m.author&.display_name || m.author&.username || 'unknown'
      time = m.timestamp.getlocal.strftime('%H:%M') rescue ''
      "[#{time}] @#{name}: #{content}"
    end.compact

    return if lines.empty?

    prompt = <<~TXT
    あなたはDiscordの議事メモ係です。以下は直近15分の会話ログです。重要な論点・合意・未解決事項・アクションを簡潔に日本語で要約してください。挨拶・スタンプは省略。箇条書き推奨。150文字以内。
    ---
    #{lines.join("\n")}
    TXT

    body = {
      "contents": [
        {
          "parts": [
            { "text": prompt }
          ]
        }
      ]
    }

    header = { 'Content-Type': 'application/json', 'X-goog-api-key': GEMINI_API_KEY }
    response = ApiUtil.post(Constants::URLs::GEMINI_URL, body, header)
    summary_text = if response['candidates'] && response['candidates'][0] && response['candidates'][0]['content'] && response['candidates'][0]['content']['parts']
                     response['candidates'][0]['content']['parts'][0]['text']
                   else
                     '（要約を生成できませんでした）'
                   end

    # 投稿先へ送信
    posted = @bot.send_message(SUMMARY_CH_ID, "#{ch.name}が盛り上がっています！\n" + summary_text)

    start_ts = msgs.map(&:timestamp).compact.min
    end_ts = msgs.map(&:timestamp).compact.max
    @summary_repo.save_summary_record(channel_id, start_ts, end_ts, posted&.id&.to_s)
  rescue StandardError => e
    puts "Summary summarize_and_post error: #{e.message}"
  end
end


