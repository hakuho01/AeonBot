# frozen_string_literal: true

require './framework/component'
require './util/api_util'
require 'time'
require 'tempfile'
require 'net/http'
require 'json'
require 'securerandom'

class TweetNotFoundError < StandardError; end

class TwitterOpenService < Component
  TWEET_URL_PATTERN = %r{https://(?:twitter\.com|x\.com)/([a-zA-Z0-9_]+)/status/([0-9]+)}
  SPOILER_PATTERN = /\|\|.+?\|\|/m
  # Discord の通常アップロード上限より少し余裕を見る
  MAX_ATTACHMENT_BYTES = 24 * 1024 * 1024

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
      urls = video_candidate_urls(video)
      videos << urls if urls.any?
    end

    # photos/videos が空のときだけ all を見る（両方拾うとサムネ+mp4で二重になる）
    if images.empty? && videos.empty?
      Array(media['all']).each do |item|
        case item['type']
        when 'video', 'gif', 'animated_gif'
          urls = video_candidate_urls(item)
          videos << urls if urls.any?
        else
          images << (item['url'] || item['image'] || item['thumbnail_url'])
        end
      end
    end

    [images.compact.uniq, videos]
  end

  # bitrate が高い順の mp4 URL 一覧（大きすぎる場合は下位を試す）
  def video_candidate_urls(video)
    candidates = Array(video['variants']) + Array(video['formats'])
    mp4s = candidates.select do |variant|
      url = variant['url']
      next false unless url

      variant['content_type'] == 'video/mp4' ||
        variant['container'] == 'mp4' ||
        url.include?('.mp4')
    end
    urls = mp4s.sort_by { |variant| -variant['bitrate'].to_i }.filter_map { |variant| variant['url'] }
    urls << video['url'] if video['url']
    urls.compact.uniq.select { |url| valid_http_url?(url) }
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
    video_candidates = Array(tweet[:videos])
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

    if video_candidates.any?
      return send_tweet_with_videos(event, main_embed, video_candidates)
    end

    main_embed[:image] = { url: images.first } if images.any?
    embeds = [main_embed]
    images.drop(1).each do |image_url|
      embeds << { image: { url: image_url } }
    end

    post_json_message(event.channel.id, '', embeds)
  end

  def send_tweet_with_videos(event, main_embed, video_candidates)
    files = []
    begin
      video_candidates.each_with_index do |urls, index|
        file = download_video_tempfile(urls, index)
        files << file if file
      end

      if files.empty?
        # ダウンロードできない場合のみ URL フォールバック
        fallback = video_candidates.filter_map(&:first).join("\n")
        return post_json_message(event.channel.id, fallback, [main_embed])
      end

      post_multipart_message(event.channel.id, [main_embed], files)
    ensure
      files.each do |file|
        path = file.path
        file.close
        file.unlink if path && File.exist?(path)
      rescue StandardError
        nil
      end
    end
  end

  def download_video_tempfile(candidate_urls, index)
    Array(candidate_urls).each do |url|
      body = download_bytes(url)
      next if body.nil? || body.bytesize.zero? || body.bytesize > MAX_ATTACHMENT_BYTES

      tmp = Tempfile.new(["tweet-video-#{index}", '.mp4'])
      tmp.binmode
      tmp.write(body)
      tmp.flush
      tmp.rewind
      return tmp
    rescue StandardError => e
      warn "video download failed (#{url}): #{e.class}: #{e.message}"
      next
    end
    nil
  end

  def download_bytes(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 10
    http.read_timeout = 60

    response = http.request_get(uri.request_uri)
    return response.body if response.is_a?(Net::HTTPSuccess)

    # リダイレクト追従（最大3回）
    3.times do
      break unless response.is_a?(Net::HTTPRedirection)

      uri = URI.parse(response['location'])
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      response = http.request_get(uri.request_uri)
      return response.body if response.is_a?(Net::HTTPSuccess)
    end

    nil
  end

  def post_json_message(channel_id, content, embeds)
    ApiUtil.post(
      "https://discord.com/api/v9/channels/#{channel_id}/messages",
      { content: content, tts: false, embeds: embeds },
      { 'Content-Type' => 'application/json', 'Authorization' => "Bot #{TOKEN}" }
    )
  end

  def post_multipart_message(channel_id, embeds, files)
    boundary = "----AeonBot#{SecureRandom.hex(16)}"
    payload = { content: '', tts: false, embeds: embeds }.to_json

    body = +''.b
    body << "--#{boundary}\r\n".b
    body << "Content-Disposition: form-data; name=\"payload_json\"\r\n".b
    body << "Content-Type: application/json\r\n\r\n".b
    body << payload.b
    body << "\r\n".b

    files.each_with_index do |file, index|
      filename = "tweet-#{index + 1}.mp4"
      body << "--#{boundary}\r\n".b
      body << "Content-Disposition: form-data; name=\"files[#{index}]\"; filename=\"#{filename}\"\r\n".b
      body << "Content-Type: video/mp4\r\n\r\n".b
      body << file.read.b
      body << "\r\n".b
      file.rewind
    end
    body << "--#{boundary}--\r\n".b

    uri = URI.parse("https://discord.com/api/v9/channels/#{channel_id}/messages")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 120

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Authorization'] = "Bot #{TOKEN}"
    request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
    request.body = body

    response = http.request(request)
    raise "Error: #{response.code} - #{response.message}" unless response.code == '200'

    JSON.parse(response.body)
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
