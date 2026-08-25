require './config/constants'
require './util/api_util'
require './service/twitter_open_service'

require 'net/http'
require 'open-uri'
require 'nokogiri'
require 'openssl'
require 'cgi'
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
    event_msg_id = event.message.id.to_s
    event_msg_ch = event.message.channel.id.to_s

    parsed_res = fetch_discord_message(event_msg_ch, event_msg_id)
    return if parsed_res.nil? || parsed_res['embeds'].nil?

    content = event.message.content
    return unless TwitterOpenService.instance.init.expandable_tweet_urls?(content)

    if broken_twitter_embed?(parsed_res)
      TwitterOpenService.instance.init.open_tweets_from_content(event, content)
      suppress_message_embeds(event_msg_ch, event_msg_id, existing_flags: parsed_res['flags'].to_i)
    elsif t_co_link_broken?(parsed_res)
      repost_fixed_t_co_embed(parsed_res, event_msg_ch, event_msg_id, event)
    end
  end

  def broken_twitter_embed?(parsed_res)
    return true if parsed_res['embeds'].empty?

    title = parsed_res['embeds'][0]['title']
    return true if title.nil?

    title.casecmp?('post') || title == 'X'
  end

  def t_co_link_broken?(parsed_res)
    description = parsed_res.dig('embeds', 0, 'description')
    !description.nil? && description.include?('https://t\\.co')
  end

  def fetch_discord_message(channel_id, message_id)
    uri = URI.parse("https://discord.com/api/v9/channels/#{channel_id}/messages/#{message_id}")
    res = Net::HTTP.get_response(uri, 'Authorization' => "Bot #{TOKEN}")
    JSON.parse(res.body)
  end

  SUPPRESS_EMBEDS_FLAG = 1 << 2

  def suppress_message_embeds(channel_id, message_id, event = nil, existing_flags: 0)
    uri = URI.parse("https://discord.com/api/v9/channels/#{channel_id}/messages/#{message_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Patch.new(uri.request_uri)
    request['Authorization'] = "Bot #{TOKEN}"
    request['Content-Type'] = 'application/json'
    request.body = { flags: existing_flags.to_i | SUPPRESS_EMBEDS_FLAG }.to_json

    response = http.request(request)
    return if response.is_a?(Net::HTTPSuccess)

    # 元メッセージの埋め込み抑制に失敗しても本文展開自体は成功しているので、チャンネルには出さない
    warn "suppress embeds failed: #{response.code} #{response.body} (channel=#{channel_id} message=#{message_id})"
  rescue StandardError => e
    warn "suppress embeds error: #{e.class}: #{e.message}"
  end

  def repost_fixed_t_co_embed(parsed_res, channel_id, message_id, event)
    embed_body = parsed_res['embeds'][0].dup
    embed_body['description'] = embed_body['description'].gsub('https://t\\.co', 'https://t.co/')

    uri = URI.parse("https://discord.com/api/v9/channels/#{channel_id}/messages")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    params = { content: '', tts: false, embeds: [embed_body] }
    headers = { 'Content-Type' => 'application/json', 'Authorization' => "Bot #{TOKEN}" }
    response = http.post(uri.path, params.to_json, headers)
    response.value

    suppress_message_embeds(channel_id, message_id, existing_flags: parsed_res['flags'].to_i)
  rescue StandardError => e
    warn "repost fixed t.co embed failed: #{e.class}: #{e.message}"
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

  def update_channel_name(channel)
    channel_id = channel.id.to_s
    new_name = channel.name

    # NotionからチャンネルIDに該当するページを検索
    headers = {
      'Notion-Version': '2022-06-28',
      'Authorization': "Bearer #{NOTION_API_KEY}",
      'Content-Type': 'application/json'
    }

    # チャンネルIDでフィルタリング
    query_uri = "https://api.notion.com/v1/databases/#{NOTION_CHANNNEL_DESCRIPTION_ID}/query"
    query_body = {
      "filter": {
        "property": 'channel_id',
        "rich_text": {
          "equals": channel_id
        }
      }
    }

    query_response = ApiUtil.post(query_uri, query_body, headers)

    # 該当するページが存在する場合のみ更新
    return if query_response['results'].empty?

    page_id = query_response['results'][0]['id']

    # Notionページの名前を更新
    update_uri = "https://api.notion.com/v1/pages/#{page_id}"
    update_body = {
      "properties": {
        "name": {
          "title": [
            {
              "text": {
                "content": new_name
              }
            }
          ]
        }
      }
    }

    uri = URI.parse(update_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme === 'https'

    request = Net::HTTP::Patch.new(uri.request_uri)
    request.body = update_body.to_json
    headers.each { |key, value| request[key] = value }

    response = http.request(request)

    if response.code == '200'
      puts "Notion updated: Channel #{channel_id} name changed to '#{new_name}'"
    else
      puts "Notion update failed: #{response.code} - #{response.body}"
    end
  rescue StandardError => e
    puts "Error updating Notion: #{e.message}"
  end

  def create_channel_in_notion(channel)
    channel_id = channel.id.to_s
    channel_name = channel.name

    headers = {
      'Notion-Version': '2022-06-28',
      'Authorization': "Bearer #{NOTION_API_KEY}",
      'Content-Type': 'application/json'
    }

    # 既に存在するかチェック
    query_uri = "https://api.notion.com/v1/databases/#{NOTION_CHANNNEL_DESCRIPTION_ID}/query"
    query_body = {
      "filter": {
        "property": 'channel_id',
        "rich_text": {
          "equals": channel_id
        }
      }
    }

    query_response = ApiUtil.post(query_uri, query_body, headers)
    return unless query_response['results'].empty? # 既に存在する場合はスキップ

    # 新しいページを作成
    create_uri = "https://api.notion.com/v1/pages"
    create_body = {
      "parent": {
        "database_id": NOTION_CHANNNEL_DESCRIPTION_ID
      },
      "properties": {
        "channel_id": {
          "rich_text": [
            {
              "text": {
                "content": channel_id
              }
            }
          ]
        },
        "name": {
          "title": [
            {
              "text": {
                "content": channel_name
              }
            }
          ]
        },
        "description": {
          "rich_text": []
        }
      }
    }

    uri = URI.parse(create_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme === 'https'

    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = create_body.to_json
    headers.each { |key, value| request[key] = value }

    response = http.request(request)

    if response.code == '200'
      puts "Notion created: Channel #{channel_id} (#{channel_name}) added to Notion"
    else
      puts "Notion create failed: #{response.code} - #{response.body}"
    end
  rescue StandardError => e
    puts "Error creating channel in Notion: #{e.message}"
  end
end
