# frozen_string_literal: true

class TwitterOpenService < Component
  def tweet_opening(args, event)
    # ツイート情報を取得する
    content = args[0]
    twitter_url = content.match(%r{https://twitter.com/([a-zA-Z0-9_]+)/status/([0-9]+)})
    twitter_id = twitter_url[2]
    token = ENV['TWITTER_BEARER_TOKEN']
    client = SimpleTwitter::Client.new(bearer_token: token)
    response = client.get_raw("#{Constants::URLs::TWITTER}#{twitter_id}?tweet.fields=created_at,attachments,possibly_sensitive,public_metrics,entities&expansions=author_id,attachments.media_keys&user.fields=profile_image_url&media.fields=media_key,type,url")
    parsed_response = JSON.parse(response)

    likes = parsed_response['data']['public_metrics']['like_count']
    rts = parsed_response['data']['public_metrics']['retweet_count']
    footer_text = "#{likes} Favs, #{rts} RTs"
    author_name = parsed_response['includes']['users'][0]['name']
    author_icon = parsed_response['includes']['users'][0]['profile_image_url']
    author_url = "https://twitter.com/#{parsed_response['includes']['users'][0]['username']}"
    event.send_embed do |embed|
      embed.description = parsed_response['data']['text']
      embed.colour = 0x1DA1F2
      embed.timestamp = Time.parse(parsed_response['data']['created_at'])
      embed.footer = Discordrb::Webhooks::EmbedFooter.new(
        text: footer_text
      )
      embed.author = Discordrb::Webhooks::EmbedAuthor.new(
        name: author_name,
        url: author_url,
        icon_url: author_icon
      )
    end
    parsed_response['includes']['media'].each do |n|
      event.respond n['url']
    end
    return
  end
end
