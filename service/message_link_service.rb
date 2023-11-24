# frozen_string_literal: true

require 'net/http'

class MessageLinkService < Component
  def message_link(event)
    pattern = %r{https://discord\.com/channels/[0-9]+/[0-9]+/[0-9a-zA-Z]+}
    message_urls = event.message.content.scan(pattern)
    message_urls.each do |url|
      message = get_message(url)
      event.send_embed do |embed|
        embed.description = message['content']
        embed.timestamp = Time.parse(message['timestamp'])
        embed.author = Discordrb::Webhooks::EmbedAuthor.new(
          name: message['author']['global_name'],
          icon_url: "https://cdn.discordapp.com/avatars/#{message['author']['id']}/#{message['author']['avatar']}.png"
        )
        embed.image = Discordrb::Webhooks::EmbedImage.new(url: message['attachments'][0]['url']) unless message['attachments'].empty?
      end
    end
  end

  def get_message(message_url)
    a = message_url.to_s.slice!(29..-1).split('/')
    channel_id = a[1]
    message_id = a[2]
    uri = URI("https://discord.com/api/v9/channels/#{channel_id}/messages/#{message_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bot #{TOKEN}"

    return JSON.parse(http.request(request).body)
  end
end
