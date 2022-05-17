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
    wgurl = Constants::URLs::WISDOM_GUILD_URL
    cardname = event.message.to_s.slice(/{{.*?}}/)[2..-3]
    encoded_cardname = CGI.escape(cardname)
    scryfall = ApiUtil.get('https://api.scryfall.com/cards/named?fuzzy=' + encoded_cardname)
    encoded_accurate_cardname = CGI.escape(scryfall['name'])
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
  #      unixtime = Time.now.to_i
  #      puts unixtime
  #      querystr = 'api_key=hakuho01\nname=' << cardname << '\ntimestamp=' << unixtime.to_s
  #      puts querystr
  #      api_sig = OpenSSL::HMAC.hexdigest('sha256', 'z9uY6YXsxxK49vtGr8vBedVw', querystr)
  #      wgurl = 'http://wonder.wisdom-guild.net/api/card-price/v1/' << '?' << 'api_key=hakuho01&name=' << cardname << '&timestamp=' << unixtime.to_s << '&api_sig=' << api_sig
  #      puts wgurl
  #      ApiUtil::get(wgurl)
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
    html = URI.open('http://whisper.wisdom-guild.net/search.php?q=' + encoded_cardname).read
    doc = Nokogiri::HTML.parse(html)
    h1_txt = doc.at_css('h1').text
    cardname_en = h1_txt.split('/')[1]
    encoded_cardname_en = CGI.escape(cardname_en)
    gatherer = ApiUtil.get('https://api.magicthegathering.io/v1/cards?name=' + encoded_cardname_en)
    return if gatherer['cards'][0]['layout'] != 'transform' && gatherer['cards'][0]['layout'] != 'modal_dfc'

    if put_img_flg
      2.times do |n|
        multiverseid = gatherer['cards'][n]['multiverseid']
        imageurl = gatherer['cards'][n]['imageUrl']
        event.send_embed do |embed|
          embed.url = 'https://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=' + multiverseid
          embed.image = Discordrb::Webhooks::EmbedImage.new(url: imageurl)
          embed.colour = 0x2B253A
        end
      end
    else
      q = doc.at_css('.owl-tip-mtgwiki').attribute('q').to_s
      q.gsub!('%2F', '/')
      q.gsub!('+', '_')
      html = URI.open('http://mtgwiki.com/wiki/' + q).read
      doc = Nokogiri::HTML.parse(html)
      card_text = doc.at_css('.card').text
      multiverseid = gatherer['cards'][0]['multiverseid']
      event.send_embed do |embed|
        embed.title = h1_txt
        embed.url = 'https://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=' + multiverseid
        embed.description = card_text
        embed.colour = 0x2B253A
      end
    end
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

      #mediaがvideoでないか確認する
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
      # uri = URI.parse('https://discord.com/api/channels/' + event_msg_ch + '/messages/')
      # http = Net::HTTP.new(uri.host, uri.port)
      # http.use_ssl = true
      # http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      # request = Net::HTTP::Post.new(uri.request_uri)
      # request.body = { name: 'web', config: { url: 'hogehogehogehoge' } }.to_json
      # request['Authorization'] = "Bot #{TOKEN}"
      # request['Content-Type'] = 'application/json'

      # res = http.request(request)

      # puts res.code, res.msg, res.body
      parsed_response['includes']['media'].each do |n|
        event.respond n['url']
      end
    end
  end
end
