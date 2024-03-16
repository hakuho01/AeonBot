# frozen_string_literal: true

require 'rss'
require 'date'
require './util/api_util'
require './framework/component'

class RoutineService < Component
  def daily_routine
    # 毎日1回実行する内容

    # キューブの更新を取得
    # 各キューブのRSS URL
    rss_urls = ['https://cubecobra.com/cube/rss/5d2cb3f44153591614458e5d', 'https://cubecobra.com/cube/rss/5d617ac6c2a85f3b75fe95a4', 'https://cubecobra.com/cube/rss/61df975d6a83dc0fea28522b']
    rss_urls.each do |url|
      rss = RSS::Parser.parse(url)
      updated_date = rss.channel.item.pubDate.to_date
      next unless updated_date == Date.today

      ApiUtil.post(
        'https://discordapp.com/api/channels/872712594639695880/messages',
        {
          "content": "#{rss.channel.title}が更新されました"
        },
        { 'Content-Type' => 'application/json', 'Authorization' => "Bot #{TOKEN}" }
      )
    end
  end
end
