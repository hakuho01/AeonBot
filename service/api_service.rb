# frozen_string_literal: true

require './config/constants'
require './util/api_util'

require 'net/http'
require 'open-uri'
require 'nokogiri'
require 'openssl'
require 'cgi'
require 'simple_twitter'
require 'time'

class ApiService < Component
  # 楽天
  def rakuten(event)
    parsed_response = ApiUtil.get(Constants::URLs::RAKUTEN_GENRE)
    random_genre = parsed_response['children'].sample
    genreid = random_genre['child']['genreId']
    request_uri = Constants::URLs::RAKUTEN_RANKING + genreid.to_s
    parsed_response = ApiUtil.get(request_uri)
    product = parsed_response['Items'].sample
    product_name = product['Item']['itemName']
    product_price = product['Item']['itemPrice']
    product_image = product['Item']['mediumImageUrls'][0]['imageUrl']
    product_url = product['Item']['itemUrl']
    event.send_embed do |embed|
      embed.title = product_name
      embed.description = "￥#{product_price}"
      embed.url = product_url
      embed.colour = 0xBF0000
      embed.image = Discordrb::Webhooks::EmbedImage.new(url: product_image.to_s)
    end
  end

  # wikipedia
  def wikipedia(event)
    parsed_response = ApiUtil.get(Constants::URLs::WIKIPEDIA)
    pageid = parsed_response['query']['pageids']
    wikipedia_url = parsed_response['query']['pages'][pageid[0]]['fullurl']
    wikipedia_title = parsed_response['query']['pages'][pageid[0]]['title']
    event.send_embed do |embed|
      embed.title = wikipedia_title
      embed.url = wikipedia_url
      embed.colour = 0xFFFFFF
    end
  end

  # wisdom guild
  def wisdom_guild(event)
    cardname = event.message.to_s.slice(/{{.*?}}/)[2..-3]
    encoded_cardname = CGI.escape(cardname)
    scryfall = ApiUtil.get('https://api.scryfall.com/cards/named?fuzzy=' + encoded_cardname)
    encoded_accurate_cardname = CGI.escape(scryfall['name'])
    html = URI.open('http://wonder.wisdom-guild.net/price/' + encoded_accurate_cardname).read
    doc = Nokogiri::HTML.parse(html)
    price = doc.at_css('.wg-wonder-price-summary > .contents > big').text
    name_jp = doc.at_css('.wg-title').text
    event.send_embed do |embed|
      embed.title = name_jp
      embed.url = 'http://wonder.wisdom-guild.net/price/' + encoded_accurate_cardname
      embed.description = price
      embed.colour = 0x6EB0FF
    end
    rescue
      event.respond('……エラー。もう少し丁寧にできないの？')
  #      unixtime = Time.now.to_i
  #      puts unixtime
  #      querystr = 'api_key=hakuho01\nname=' << cardname << '\ntimestamp=' << unixtime.to_s
  #      puts querystr
  #      api_sig = OpenSSL::HMAC.hexdigest('sha256', 'z9uY6YXsxxK49vtGr8vBedVw', querystr)
  #      wgurl = 'http://wonder.wisdom-guild.net/api/card-price/v1/' << '?' << 'api_key=hakuho01&name=' << cardname << '&timestamp=' << unixtime.to_s << '&api_sig=' << api_sig
  #      puts wgurl
  #      ApiUtil::get(wgurl)
  end

  # TwitterNSFWサムネイル表示
  def twitter_thumbnail(event)
    # discordが展開しているか確認する
    sleep 2
    event_msg_id = event.message.id.to_s
    event_msg_ch = event.message.channel.id.to_s
    uri = URI.parse('https://discord.com/api/channels/' + event_msg_ch + '/messages/' + event_msg_id)
    res = Net::HTTP.get_response(uri, 'Authorization' => "Bot #{TOKEN}")
    parsed_res = JSON.parse(res.body)
    if parsed_res['embeds'].empty?
      # ツイート情報を取得する
      content = event.message.content
      twitter_url = content.match(/https:\/\/twitter.com\/([a-zA-Z0-9_]+)\/status\/([0-9]+)/)
      twitter_id = twitter_url[2]
      token = ENV['TWITTER_BEARER_TOKEN']
      client = SimpleTwitter::Client.new(bearer_token: token)
      response = client.get_raw(Constants::URLs::TWITTER + twitter_id + '?tweet.fields=created_at,attachments,possibly_sensitive,public_metrics,entities&expansions=author_id,attachments.media_keys&user.fields=profile_image_url&media.fields=media_key,type,url')
      parsed_response = JSON.parse(response)

      # sensitiveか、mediaがvideoでないか確認する
      return if parsed_response['data']['possibly_sensitive'] == false
      return if parsed_response['includes']['media'][0]['type'] == 'video'

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
    end
  end
end
