# frozen_string_literal: true

require 'dotenv'
require './framework/component'
require './repository/favstar_repository'

Dotenv.load
FAVSTAR_CH_ID = ENV['FAVSTAR_CH_ID']

class FavstarService < Component
  private

  def construct(bot)
    @bot = bot
    @favstar_repository = FavstarRepository.instance.init
  end

  public

  def memory_fav(event)
    kusas = event.message.reactions.find { |n| n.id == KUSA_ID.to_i }.count
    return if kusas < 10 # 草が10以上であるか確認

    # DBに問い合わせ、既知なら終了
    message_id = event.message.id
    return if @favstar_repository.check_faved_message(message_id)[:message_id]
    images = event.message.attachments.find{|attachments| attachments.image?}
    images_url = images.url if images

    # API経由で投稿
    timestamp = event.message.timestamp + 32400 # 投稿のタイムスタンプに9時間加算して日本標準時に
    name = event.message.author.respond_to?(:display_name) ? event.message.author.display_name : event.message.author.username
    req_json = {
      "components": [
        {
          "type": 1,
          "components": [
            {
              "style": 5,
              "label": 'View Original',
              "url": "https://discord.com/channels/#{event.server.id}/#{event.channel.id}/#{event.message.id}",
              "disabled": false,
              "type": 2
            }
          ]
        }
      ],
      "embeds": [
        {
          "description": event.message.content.to_s,
          "author": {
            "name": name,
            "icon_url": event.message.author.avatar_url
          },
          "footer": {
            "text": "#{timestamp.strftime('%Y/%m/%d %H:%M')} via #{event.message.channel.name}"
          },
          "image": {
            "url": images_url
          }
        }
      ]
    }
    uri = URI.parse("https://discordapp.com/api/channels/#{FAVSTAR_CH_ID}/messages")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme === 'https'
    params = req_json
    headers = { 'Content-Type' => 'application/json', 'Authorization' => "Bot #{TOKEN}" }
    response = http.post(uri.path, params.to_json, headers)
    begin
      response.value
    rescue => e
      # エラー発生時はエラー内容を白鳳にメンションする
      event.respond "#{e.message} ¥r¥n #{response.body} <@!306022413139705858>"
    else
      # エラーなく投稿できたら新規発言はid登録
      @favstar_repository.add_faved_message(message_id)
    end
  end
end
