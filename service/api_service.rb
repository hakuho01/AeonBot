require './config/constants'
require './util/api_util'

require 'net/http'
require 'open-uri'
require 'nokogiri'
require 'openssl'
require 'cgi'
require 'simple_twitter'
require 'time'
require 'dotenv'

Dotenv.load
NOTION_API_KEY = ENV['NOTION_API_KEY']
NOTION_CHANNNEL_DESCRIPTION_ID = ENV['NOTION_CHANNNEL_DESCRIPTION_ID']
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
    wgurl = Constants::URLs::WISDOM_GUILD_URL
    cardname = event.message.to_s.slice(/{{.*?}}/)[2..-3]
    encoded_cardname = CGI.escape(cardname)
    scryfall = ApiUtil.get("https://api.scryfall.com/cards/named?fuzzy=#{encoded_cardname}")
    if scryfall['name'].include?('//')
      scryfall_name = scryfall['name'].split('//')[0]
    else
      scryfall_name = scryfall['name']
    end
    encoded_accurate_cardname = CGI.escape(scryfall_name)
    html = URI.open(wgurl + encoded_accurate_cardname).read
    doc = Nokogiri::HTML.parse(html)
    price = doc.at_css('.wg-wonder-price-summary > .contents > big').text
    name_jp = doc.at_css('.wg-title').text
    event.send_embed do |embed|
      embed.title = name_jp
      embed.url = wgurl + encoded_accurate_cardname
      embed.description = price
      embed.colour = 0x6EB0FF
    end
    rescue
      event.respond('……エラー。もう少し丁寧にできないの？')
    # unixtime = Time.now.to_i
    # puts unixtime
    # querystr = 'api_key=hakuho01\nname=' << cardname << '\ntimestamp=' << unixtime.to_s
    # puts querystr
    # api_sig = OpenSSL::HMAC.hexdigest('sha256', 'z9uY6YXsxxK49vtGr8vBedVw', querystr)
    # wgurl = 'http://wonder.wisdom-guild.net/api/card-price/v1/' << '?' << 'api_key=hakuho01&name=' << cardname << '&timestamp=' << unixtime.to_s << '&api_sig=' << api_sig
    # puts wgurl
    # ApiUtil::get(wgurl)
  end

  # ScryfallDFC
  def scryfall(event)
    cardname = event.message.to_s.slice(/\[\[.*?\]\]/)[2..-3]
    # 画像要求かの確認
    if cardname.chr == '!'
      put_img_flg = true
      cardname.delete!('!')
    end
    encoded_cardname = CGI.escape(cardname)
    html = URI.open("http://whisper.wisdom-guild.net/search.php?q=#{encoded_cardname}").read
    doc = Nokogiri::HTML.parse(html)
    h1_txt = doc.at_css('h1').text
    cardname_en = h1_txt.split('/')[1]
    return if cardname.nil?

    encoded_cardname_en = CGI.escape(cardname_en)
    gatherer = ApiUtil.get("https://api.magicthegathering.io/v1/cards?name=#{encoded_cardname_en}")
    return if !gatherer['cards'][0].nil? && gatherer['cards'][0]['layout'] != 'transform' && gatherer['cards'][0]['layout'] != 'modal_dfc'

    scryfall = ApiUtil.get("https://api.scryfall.com/cards/search?q=#{encoded_cardname_en}")
    scryfall_url = scryfall['data'][0]['scryfall_uri']
    if put_img_flg
      2.times do |n|
        imageurl = scryfall['data'][0]['card_faces'][n]['image_uris']['png']
        card_title = scryfall['data'][0]['card_faces'][n]['name']
        event.send_embed do |embed|
          embed.title = card_title
          embed.url = scryfall_url
          embed.image = Discordrb::Webhooks::EmbedImage.new(url: imageurl)
          embed.colour = 0x2B253A
        end
      end
    else
      q = doc.at_css('.owl-tip-mtgwiki').attribute('q').to_s
      q.gsub!('%2F', '/')
      q.gsub!('+', '_')
      html = URI.open("http://mtgwiki.com/wiki/#{q}").read
      doc = Nokogiri::HTML.parse(html)
      card_text = doc.at_css('.card').text
      event.send_embed do |embed|
        embed.title = h1_txt
        embed.url = scryfall_url
        embed.description = card_text
        embed.colour = 0x2B253A
      end
    end
  end

  # TwitterNSFWサムネイル表示
  def twitter_control(event)
    # discordが展開しているか確認する
    event_msg_id = event.message.id.to_s
    event_msg_ch = event.message.channel.id.to_s

    uri = URI.parse("https://discord.com/api/channels/#{event_msg_ch}/messages/#{event_msg_id}")
    res = Net::HTTP.get_response(uri, 'Authorization' => "Bot #{TOKEN}")
    parsed_res = JSON.parse(res.body)
    return if parsed_res.nil? || parsed_res['embeds'].nil?

    if parsed_res['embeds'].empty? || parsed_res['embeds'][0]['title'] == 'X' # discordが埋め込みをやっていない場合
      # ツイート情報を取得する
      content = event.message.content
      return if content.match(/\|\|http/) # 埋め込みがなくてもスポイラーなら展開しない

      twitter_urls = content.scan(%r{(https://twitter.com/[a-zA-Z0-9_]+/status/[0-9]+)|(https://x.com/([a-zA-Z0-9_]+)/status/([0-9]+))})
      post_content = ''

      twitter_urls.each do |item|
        twitter_url = item.select { |e| e.to_s.match?(%r{https?://\S+})}
        vx_twitter_url = twitter_url[0].to_s[8, 1] == 't' ? twitter_url[0].to_s.insert(8, 'fx') : twitter_url[0].to_s.sub(/x.com/, 'fxtwitter.com')
        post_content = post_content << vx_twitter_url << "\n"
      end
      event.respond(post_content)

      # 元投稿の埋込削除
      uri = URI.parse("https://discordapp.com/api/channels/#{event_msg_ch}/messages/#{event_msg_id}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme === 'https'
      params = {
        "flags": 4
      }
      headers = { 'Content-Type' => 'application/json', 'Authorization' => "Bot #{TOKEN}" }
      response = http.patch(uri.path, params.to_json, headers)
      begin
        response.value
      rescue => e
        # エラー発生時はエラー内容を白鳳にメンションする
        event.respond "#{e.message} ¥r¥n #{response.body} <@!306022413139705858>"
      end
    else # 埋め込みをやっている場合
      return unless !parsed_res['embeds'][0]['description'].nil? && parsed_res['embeds'][0]['description'].include?('https://t\\.co')

      embed_body = parsed_res['embeds'][0]
      embed_body['description'].gsub!('https://t\\.co', 'https://t.co/')

      # API経由で投稿
      uri = URI.parse("https://discordapp.com/api/channels/#{event_msg_ch}/messages")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme === 'https'
      params = {
        "content": "",
        "tts": false,
        "embeds": [
          embed_body
        ]
      }
      headers = { 'Content-Type' => 'application/json', 'Authorization' => "Bot #{TOKEN}" }
      response = http.post(uri.path, params.to_json, headers)
      begin
        response.value
      rescue => e
        # エラー発生時はエラー内容を白鳳にメンションする
        event.respond "#{e.message} ¥r¥n #{response.body} <@!306022413139705858>"
      end

      # 元投稿の埋込削除
      uri = URI.parse("https://discordapp.com/api/channels/#{event_msg_ch}/messages/#{event_msg_id}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme === 'https'
      params = {
        "flags": 4
      }
      headers = { 'Content-Type' => 'application/json', 'Authorization' => "Bot #{TOKEN}" }
      response = http.patch(uri.path, params.to_json, headers)
      begin
        response.value
      rescue => e
        # エラー発生時はエラー内容を白鳳にメンションする
        event.respond "#{e.message} ¥r¥n #{response.body} <@!306022413139705858>"
      end
    end
  end

  def channel_description(event)
    channel_id = event.channel.id.to_s
    headers = {
      'Notion-Version': '2022-06-28',
      'Authorization': "Bearer #{NOTION_API_KEY}",
      'Content-Type': 'application/json'
    }
    request_uri = "https://api.notion.com/v1/databases/#{NOTION_CHANNNEL_DESCRIPTION_ID}/query"
    body = {
      "filter": {
        "property": 'channel_id',
        "rich_text": {
          "equals": channel_id
        }
      }
    }
    parsed_response = ApiUtil.post(request_uri, body, headers)
    ch_name = parsed_response['results'][0]['properties']['name']['title'][0]['text']['content']
    ch_desc = parsed_response['results'][0]['properties']['description']['rich_text'][0]['text']['content']
    event.respond "【#{ch_name}】：#{ch_desc}"
  end
end
