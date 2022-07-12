# frozen_string_literal: true

require 'dotenv'
require './framework/component'

Dotenv.load
FAVSTAR_CH_ID = ENV['FAVSTAR_CH_ID']

class FavstarService < Component
  private

  def construct(bot)
    @bot = bot
  end

  public

  def memory_fav(event)
    kusas = event.message.reactions.find { |n| n.id == KUSA_ID.to_i }.count
    return if kusas != 10

    req_json = {
      "embeds": [
        {
          "description": event.message.content.to_s,
          "author": {
            "name": event.message.author.display_name,
            "url": "https://discord.com/channels/#{event.server.id}/#{event.channel.id}/#{event.message.id}",
            "icon_url": event.message.author.avatar_url
          },
          "footer": {
            "text": event.message.timestamp.strftime('%Y/%m/%d %H:%M')
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
    response.code
    response.body
  end
end
