require 'discordrb'
require 'dotenv'

require './bot_service'

Dotenv.load
IS_LOCAL = ENV['IS_LOCAL']

class BotController

  def initialize
    @service = BotService.new
  end

  def handle_mention(event)
    if IS_LOCAL
      # 開発時はここに書くとサーバーで動いてる死天使本体が発火しなくなるはず
    else
      message = event.message.to_s
      if message.match?(/おはよ|おは〜|おはー|good morning/i)
        @service.say_good_morning(event)
      elsif message.match?(/おやす|おやす〜|おやすー|good night/i)
        @service.say_good_night(event)
      elsif message.match?('楽天')
        @service.suggest_rakuten(event)
      elsif message.match?(/wiki/i)
        @service.suggest_wikipedia(event)
      else
        @service.say_random(event)
      end
    end
  end

  def handle_message(event, message_type)
    case message_type 
    when :hash then
      @service.judge_detected_hash(event)
    end
  end
end