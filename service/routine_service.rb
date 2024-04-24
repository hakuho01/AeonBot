# frozen_string_literal: true

require 'rss'
require 'date'
require './util/api_util'
require './framework/component'
require './repository/lootbox_repository'

Dotenv.load
CUBE_CH_ID = ENV['CUBE_CH_ID']

class RoutineService < Component
  def construct
    @lootbox_repository = LootBoxRepository.instance.init
  end

  def daily_routine
    # 毎日1回実行する内容 bot再起動時は再実行されるので注意

    # キューブの更新を取得 日付が変わった瞬間(GMT)に機能付で更新されているキューブがないか調べる
    yesterdays_date = Date.today - 1
    # 各キューブのRSS URL
    rss_urls = ['https://cubecobra.com/cube/rss/5d2cb3f44153591614458e5d', 'https://cubecobra.com/cube/rss/5d617ac6c2a85f3b75fe95a4', 'https://cubecobra.com/cube/rss/61df975d6a83dc0fea28522b']
    rss_urls.each do |url|
      rss = RSS::Parser.parse(url)
      updated_date = rss.channel.item.pubDate.to_date

      ApiUtil.post(
        "https://discordapp.com/api/channels/725471441260118097/messages",
        {
          "content": "以下の内容でチェック：#{rss.channel.title}, #{yesterdays_date}, #{updated_date}"
        },
        { 'Content-Type' => 'application/json', 'Authorization' => "Bot #{TOKEN}" }
      )

      next unless updated_date == yesterdays_date

      ApiUtil.post(
        "https://discordapp.com/api/channels/#{CUBE_CH_ID}/messages",
        {
          "content": "#{rss.channel.title}が更新されました"
        },
        { 'Content-Type' => 'application/json', 'Authorization' => "Bot #{TOKEN}" }
      )
    end

    # ルートボックスのメッセージ削除
    timestamp = Time.now
    @lootbox_repository.delete_message(timestamp)
  end
end
