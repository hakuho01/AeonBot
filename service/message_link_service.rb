# frozen_string_literal: true

require 'net/http'

class MessageLinkService < Component
  def message_link(event)
    message_url = event.message.content.match(%r{https://discord.com/channels/([0-9]+)/([0-9]+)/([0-9]+)})
    a = message_url.to_s.slice!(29..-1).split('/')
    channel_id = a[1]
    message_id = a[2]
    uri = URI("https://discord.com/api/v9/channels/#{channel_id}/messages/#{message_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bot #{TOKEN}"

    parsed_response = JSON.parse(http.request(request).body)

    event.send_embed do |embed|
      embed.description = parsed_response['content']
      embed.timestamp = Time.parse(parsed_response['timestamp'])
      embed.author = Discordrb::Webhooks::EmbedAuthor.new(
        name: parsed_response['author']['global_name'],
        icon_url: "https://cdn.discordapp.com/avatars/#{parsed_response['author']['id']}/#{parsed_response['author']['avatar']}.png"
      )
      embed.image = Discordrb::Webhooks::EmbedImage.new(url: parsed_response['attachments'][0]['url']) unless parsed_response['attachments'].empty?
    end
  end
end
