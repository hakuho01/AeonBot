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

  def handle_command(event, args, command_type)
    case command_type
    when :remind then
      date = args[0]
      time = args[1]
      message = args[2]
      @service.add_reminder(date, time, message, event)
    end
  end

  def handle_message(event, message_type)
    case message_type 
    when :hash then
      @service.judge_detected_hash(event)
    end
  end

  def wait_reminder
    reminder_list = @service.fetch_reminder_list
    loop do
      now = Time.now
      reminder_list.each do |reminder|
        if not reminder.done and now > reminder.time
          @service.remind(reminder)
          reminder.done = true
          @service.save_reminder_list(reminder_list)
          sleep 3
        end
      end
      sleep 30
    end
  end
end