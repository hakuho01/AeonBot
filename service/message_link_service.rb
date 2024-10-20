# frozen_string_literal: true

require 'net/http'
require './util/api_util'

class MessageLinkService < Component
  def message_link(event)
    pattern = %r{https://discord\.com/channels/[0-9]+/[0-9]+/[0-9a-zA-Z]+}
    message_urls = event.message.content.scan(pattern)
    message_urls.each do |url|
      message = get_message(url)
      embeds = {
        "embeds": [
          {
            "url": url,
            "description": message['content'],
            "author": {
              "name": message['author']['global_name'] || message['author']['username'],
              "icon_url": "https://cdn.discordapp.com/avatars/#{message['author']['id']}/#{message['author']['avatar']}.png"
            },
            "timestamp": message['timestamp']
          }
        ]
      }
      message['attachments'].each do |attachment|
        embeds[:embeds] << {
          url: url,
          image: {
            url: attachment['url']
          }
        }
      end
      ApiUtil.post(
        "https://discordapp.com/api/channels/#{event.channel.id}/messages",
        embeds,
        { 'Content-Type' => 'application/json', 'Authorization' => "Bot #{TOKEN}" }
      )
    end
  end

  def get_message(message_url)
    a = message_url.to_s.slice!(29..-1).split('/')
    channel_id = a[1]
    message_id = a[2]
    res = ApiUtil.get(
      "https://discord.com/api/v9/channels/#{channel_id}/messages/#{message_id}",
      { 'Authorization' => "Bot #{TOKEN}" }
    )
    return res
  end
end
