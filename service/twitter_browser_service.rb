# frozen_string_literal: true

require './framework/component'
require 'ferrum'
require 'json'
require 'uri'
require 'time'

class TwitterBrowserService < Component
  USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' \
               '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'
  PAGE_WAIT_SECONDS = 3
  SESSION_PATH = File.expand_path('../.twitter_session.json', __dir__)
  HOME_URL = 'https://x.com/home'

  def construct
    @mutex = Mutex.new
    @browser = nil
    @cookies_applied = false
  end

  def fetch_tweet(tweet_url)
    @mutex.synchronize do
      ensure_browser
      apply_cookies unless @cookies_applied

      @browser.goto(tweet_url)
      sleep PAGE_WAIT_SECONDS
      refresh_ct0_from_browser
      parse_tweet_page(tweet_url)
    end
  rescue StandardError
    reset_browser
    raise
  end

  def shutdown
    @mutex.synchronize do
      @browser&.quit
      @browser = nil
      @cookies_applied = false
    end
  end

  private

  def ensure_browser
    return if @browser

    options = {
      headless: true,
      timeout: 30,
      browser_options: {
        'no-sandbox': nil,
        'disable-dev-shm-usage': nil,
        'disable-gpu': nil,
        'user-agent': USER_AGENT
      }
    }
    options[:browser_path] = ENV['CHROME_PATH'] if ENV['CHROME_PATH']

    @browser = Ferrum::Browser.new(**options)
  end

  def apply_cookies
    auth_token = present(ENV['TWITTER_AUTH_TOKEN'])
    return unless auth_token

    ct0 = load_ct0

    %w[.x.com .twitter.com].each do |domain|
      @browser.cookies.set(name: 'auth_token', value: auth_token, domain: domain, path: '/')
      @browser.cookies.set(name: 'ct0', value: ct0, domain: domain, path: '/') if ct0
    end

    # ct0 が無い／古い場合でも、ホームを開いてサーバー側に再発行させる
    @browser.goto(HOME_URL)
    sleep PAGE_WAIT_SECONDS
    refresh_ct0_from_browser

    @cookies_applied = true
  end

  def load_ct0
    present(read_session['ct0']) || present(ENV['TWITTER_CT0'])
  end

  def refresh_ct0_from_browser
    cookie = @browser.cookies['ct0']
    new_ct0 = present(cookie&.value)
    return unless new_ct0
    return if new_ct0 == ENV['TWITTER_CT0'] && new_ct0 == read_session['ct0']

    ENV['TWITTER_CT0'] = new_ct0
    write_session('ct0' => new_ct0)
  end

  def read_session
    return {} unless File.exist?(SESSION_PATH)

    JSON.parse(File.read(SESSION_PATH))
  rescue JSON::ParserError, Errno::ENOENT
    {}
  end

  def write_session(attrs)
    session = read_session.merge(attrs)
    session['updated_at'] = Time.now.iso8601
    File.write(SESSION_PATH, JSON.pretty_generate(session))
  end

  def present(value)
    str = value.to_s
    str.empty? ? nil : str
  end

  def reset_browser
    @browser&.quit
    @browser = nil
    @cookies_applied = false
  end

  def parse_tweet_page(tweet_url)
    tweet_id = tweet_url[%r{/status/([0-9]+)}, 1]
    username = tweet_url[%r{x\.com/([a-zA-Z0-9_]+)/status}, 1]
    data = @browser.evaluate(extract_script(tweet_id))

    raise TweetNotFoundError, tweet_url if data['not_found']

    author = parse_author(data['og_title'], data['page_title'], username)
    images = collect_images(data)

    {
      text: extract_text(data),
      author_name: author[:name],
      author_handle: author[:handle],
      author_icon: profile_image_url?(data['og_image']) ? data['og_image'] : present(data['author_icon']),
      tweet_url: tweet_url,
      images: images
    }
  end

  def extract_script(tweet_id)
    <<~JS
      (function() {
        function metaContent(name) {
          var el = document.querySelector('meta[property="' + name + '"]') ||
                   document.querySelector('meta[name="' + name + '"]');
          return el ? el.content : null;
        }

        var ogTitle = metaContent('og:title') || '';
        var ogDescription = metaContent('og:description') || '';
        var ogImage = metaContent('og:image') || '';
        var pageTitle = document.title || '';
        var notFound = /404|見つかりません|not found/i.test(ogTitle + pageTitle + ogDescription);

        var mainArticle = document.querySelector('article[data-testid="tweet"]') ||
                          document.querySelector('article');
        var tweetTextEl = mainArticle ? mainArticle.querySelector('[data-testid="tweetText"]') : null;
        var tweetText = tweetTextEl ? tweetTextEl.innerText : '';

        var photoImages = [];
        if (mainArticle) {
          photoImages = Array.from(mainArticle.querySelectorAll('[data-testid="tweetPhoto"] img, a[href*="/status/#{tweet_id}/photo/"] img'))
            .map(function(img) { return img.src; });
        }
        if (!photoImages.length) {
          photoImages = Array.from(document.querySelectorAll('a[href*="/status/#{tweet_id}/photo/"] img'))
            .map(function(img) { return img.src; });
        }

        var avatar = mainArticle ? mainArticle.querySelector('img[src*="profile_images"]') : null;

        return {
          og_title: ogTitle,
          description: ogDescription,
          og_image: ogImage,
          page_title: pageTitle,
          tweet_text: tweetText,
          author_icon: avatar ? avatar.src : null,
          not_found: notFound,
          photo_images: photoImages
        };
      })()
    JS
  end

  def extract_text(data)
    present(data['description']) ||
      text_from_title(data['og_title']) ||
      text_from_title(data['page_title']) ||
      present(data['tweet_text']) ||
      ''
  end

  # "Name on X: \"本文\" / X" または「XユーザーのNameさん: 「本文」 / X」から本文を取り出す
  def text_from_title(title)
    return nil if title.to_s.empty?

    if (match = title.match(/on X:\s*"(.*)"\s*\/\s*X\z/m))
      return match[1].gsub('\\n', "\n").strip
    end

    if (match = title.match(/[：:]\s*[「\"](.*)[」\"]\s*\/\s*X\z/m))
      return match[1].gsub('\\n', "\n").strip
    end

    nil
  end

  def parse_author(og_title, page_title, username = nil)
    handle = username ? "@#{username}" : nil

    if (match = og_title.match(/[@（(](@?[A-Za-z0-9_]+)[）)]/))
      handle ||= "@#{match[1].delete_prefix('@')}"
      name = og_title[/Xユーザーの(.+?)[（(]/, 1] ||
             og_title[/^(.+?) on X/i, 1] ||
             page_title[/Xユーザーの(.+?)さん/, 1] ||
             match[1]
      return { name: name.strip, handle: handle }
    end

    if (match = og_title.match(/^(.+?) on X/i))
      return { name: match[1].strip, handle: handle }
    end

    if (match = page_title.match(/Xユーザーの(.+?)さん/))
      return { name: match[1].strip, handle: handle }
    end

    { name: og_title.split(/[:：]/).first.to_s.strip, handle: handle }
  end

  def collect_images(data)
    images = []
    images << upscale_image(data['og_image']) if media_image_url?(data['og_image'])

    Array(data['photo_images']).each do |url|
      images << upscale_image(url) if media_image_url?(url)
    end

    images.uniq
  end

  def media_image_url?(url)
    url.to_s.include?('pbs.twimg.com/media')
  end

  def profile_image_url?(url)
    url.to_s.include?('profile_images')
  end

  def upscale_image(url)
    uri = URI.parse(url)
    params = URI.decode_www_form(uri.query || '').to_h
    params['name'] = 'large'
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end
end

class TweetNotFoundError < StandardError; end
