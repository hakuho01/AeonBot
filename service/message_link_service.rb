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
      embed.colour = 0x1DA1F2
      embed.timestamp = Time.parse(parsed_response['timestamp'])
      #embed.footer = Discordrb::Webhooks::EmbedFooter.new(
      #  text: footer_text
      #)
      embed.author = Discordrb::Webhooks::EmbedAuthor.new(
        name: parsed_response['author']['display_name'],
        #url: author_url,
        #icon_url: author_icon
      )
    end
  end
end
