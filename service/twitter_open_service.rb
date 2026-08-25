# frozen_string_literal: true

require './framework/component'
require './service/twitter_browser_service'
require './util/api_util'

class TwitterOpenService < Component
  TWEET_URL_PATTERN = %r{https://(?:twitter\.com|x\.com)/([a-zA-Z0-9_]+)/status/([0-9]+)}
  SPOILER_PATTERN = /\|\|.+?\|\|/m

  def construct
    @browser_service = TwitterBrowserService.instance.init
  end

  def tweet_opening(args, event)
    open_tweets_from_content(event, args[0])
  end

  def open_tweets_from_content(event, content)
    extract_tweet_urls(content).each do |tweet_url|
      open_tweet(event, tweet_url)
    end
  end

  # Discord の ||spoiler|| 内の URL は除外する
  def extract_tweet_urls(content)
    content.to_s.gsub(SPOILER_PATTERN, '').scan(TWEET_URL_PATTERN).map do |username, tweet_id|
      "https://x.com/#{username}/status/#{tweet_id}"
    end
  end

  def expandable_tweet_urls?(content)
    extract_tweet_urls(content).any?
  end

  def open_tweet(event, tweet_url)
    tweet = @browser_service.fetch_tweet(tweet_url)
    send_tweet_embed(event, tweet)
  rescue TweetNotFoundError
    nil
  end

  private

  def send_tweet_embed(event, tweet)
    author_url = if tweet[:author_handle]
                   "https://x.com/#{tweet[:author_handle].delete_prefix('@')}"
                 else
                   tweet[:tweet_url]
                 end

    author_name = [tweet[:author_name], tweet[:author_handle]].compact.join(' ').strip
    author_name = 'X' if author_name.empty?

    author = { name: author_name, url: author_url }
    author[:icon_url] = tweet[:author_icon] if valid_http_url?(tweet[:author_icon])

    description = tweet[:text].to_s
    description = '(本文なし)' if description.empty?

    images = Array(tweet[:images]).select { |url| valid_http_url?(url) }

    main_embed = {
      description: description,
      color: 0x1DA1F2,
      url: tweet[:tweet_url],
      author: author
    }
    main_embed[:image] = { url: images.first } if images.any?

    embeds = [main_embed]
    images.drop(1).each do |image_url|
      embeds << { image: { url: image_url } }
    end

    ApiUtil.post(
      "https://discord.com/api/channels/#{event.channel.id}/messages",
      { content: '', tts: false, embeds: embeds },
      { 'Content-Type' => 'application/json', 'Authorization' => "Bot #{TOKEN}" }
    )
  end

  def valid_http_url?(url)
    url.to_s.match?(%r{\Ahttps?://\S+\z})
  end
end
