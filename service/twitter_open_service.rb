# frozen_string_literal: true

require './framework/component'
require './util/api_util'
require 'time'

class TweetNotFoundError < StandardError; end

class TwitterOpenService < Component
  TWEET_URL_PATTERN = %r{https://(?:twitter\.com|x\.com)/([a-zA-Z0-9_]+)/status/([0-9]+)}
  SPOILER_PATTERN = /\|\|.+?\|\|/m

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
    tweet = fetch_tweet_data(tweet_url)
    send_tweet_embed(event, tweet) if tweet
  rescue TweetNotFoundError
    nil
  end

  private

  # Heroku では Chrome が R15 (メモリ超過) になるため、常に fxtwitter JSON を使う。
  # ローカルだけ TWITTER_USE_BROWSER=true でヘッドレスを有効化できる。
  def fetch_tweet_data(tweet_url)
    fetch_tweet_via_fxtwitter(tweet_url)
  rescue StandardError => e
    raise unless use_browser?

    warn "fxtwitter fetch failed, trying browser: #{e.class}: #{e.message}"
    browser_service.fetch_tweet(tweet_url)
  end

  def use_browser?
    ENV['TWITTER_USE_BROWSER'] == 'true' && ENV['DYNO'].to_s.empty?
  end

  def browser_service
    require './service/twitter_browser_service'
    @browser_service ||= TwitterBrowserService.instance.init
  end

  def fetch_tweet_via_fxtwitter(tweet_url)
    username, tweet_id = tweet_url.match(TWEET_URL_PATTERN)&.captures
    raise TweetNotFoundError, tweet_url unless tweet_id

    path = username ? "#{username}/status/#{tweet_id}" : "status/#{tweet_id}"
    response = ApiUtil.get("https://api.fxtwitter.com/#{path}")
    tweet = response['tweet']
    raise TweetNotFoundError, tweet_url if tweet.nil? || response['code'].to_i != 200

    author = tweet['author'] || {}
    images, videos = extract_media(tweet['media'] || {})

    {
      text: tweet['text'].to_s,
      author_name: author['name'],
      author_handle: author['screen_name'] ? "@#{author['screen_name']}" : nil,
      author_icon: author['avatar_url'],
      tweet_url: tweet_url,
      created_at: tweet['created_at'] || tweet['created_timestamp'],
      images: images,
      videos: videos
    }
  end

  def extract_media(media)
    images = []
    videos = []

    Array(media['photos']).each do |photo|
      images << (photo['url'] || photo['image'])
    end

    Array(media['videos']).each do |video|
      videos << best_video_url(video)
    end

    # photos/videos が空のときだけ all を見る（両方拾うとサムネ+mp4で二重になる）
    if images.empty? && videos.empty?
      Array(media['all']).each do |item|
        case item['type']
        when 'video', 'gif', 'animated_gif'
          videos << best_video_url(item)
        else
          images << (item['url'] || item['image'] || item['thumbnail_url'])
        end
      end
    end

    [images.compact.uniq, videos.compact.uniq]
  end

  def best_video_url(video)
    candidates = Array(video['variants']) + Array(video['formats'])
    mp4s = candidates.select do |variant|
      url = variant['url']
      next false unless url

      variant['content_type'] == 'video/mp4' ||
        variant['container'] == 'mp4' ||
        url.include?('.mp4')
    end
    best = mp4s.max_by { |variant| variant['bitrate'].to_i }
    best&.fetch('url', nil) || video['url']
  end

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

    description = tweet[:text].to_s.strip
    images = Array(tweet[:images]).select { |url| valid_http_url?(url) }
    videos = Array(tweet[:videos]).select { |url| valid_http_url?(url) }
    created_at = parse_tweet_time(tweet[:created_at])

    main_embed = {
      color: 0x1DA1F2,
      url: tweet[:tweet_url],
      author: author
    }
    main_embed[:description] = description unless description.empty?
    if created_at
      main_embed[:footer] = { text: created_at.getlocal('+09:00').strftime('%Y/%m/%d %H:%M') }
    end

    # 動画は embed.image に入れると空埋め込みになるので content に載せて再生させる
    if videos.any?
      ApiUtil.post(
        "https://discord.com/api/channels/#{event.channel.id}/messages",
        { content: videos.join("\n"), tts: false, embeds: [main_embed] },
        { 'Content-Type' => 'application/json', 'Authorization' => "Bot #{TOKEN}" }
      )
      return
    end

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

  def parse_tweet_time(value)
    return if value.nil?

    case value
    when Time
      value
    when Integer, Float
      Time.at(value.to_i)
    when String
      Time.parse(value)
    end
  rescue ArgumentError, TypeError
    nil
  end

  def valid_http_url?(url)
    url.to_s.match?(%r{\Ahttps?://\S+\z})
  end
end
