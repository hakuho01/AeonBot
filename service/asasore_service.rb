# frozen_string_literal: true

require 'nokogiri'
require './framework/component'

class AsasoreService < Component
  # 朝それお題出題メソッド
  def asasore_theme(event)
    html = URI.open(Constants::URLs::ASASORE).read
    doc = Nokogiri::HTML.parse(html)
    theme = doc.at_css('#wrap-question').text
    odai_id = event.message.timestamp + 32_400 # 投稿時間をidとする
    @timestamp = odai_id.strftime('%Y/%m/%d %H:%M').to_s
    event.send_embed do |embed|
      embed.title = theme
      embed.colour = 0xFF00FF
      embed.footer = Discordrb::Webhooks::EmbedFooter.new(
        text: @timestamp
      )
    end
  end

  # 朝それお題代理出題メソッド
  def asasore_proxy(args, event)
    odai_id = event.message.timestamp + 32_400 # 投稿時間をidとする
    @timestamp = odai_id.strftime('%Y/%m/%d %H:%M').to_s
    event.send_embed do |embed|
      embed.title = args.join(' ')
      embed.colour = 0xFF00FF
      embed.footer = Discordrb::Webhooks::EmbedFooter.new(
        text: @timestamp
      )
    end
    event.message.delete
  end

  # 朝それスタート時メソッド。開始人数と日付を記録します
  def asasore_start(args, event)
    @players = args[0].to_i
    event.respond("#{@players}人で朝それを……始める……")
  end

  # 朝それリアクションチェックメソッド
  def asasore_check(event)
    return if event.message.embeds[0].footer.text != @timestamp # 最新のお題かチェック

    players = @players
    return if event.message.reactions.count != players

    event.respond('みんなの準備が、できたみたい……')
  end
end
