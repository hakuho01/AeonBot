require 'discordrb'
require 'dotenv'

require './service/bot_service'

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
      elsif message.match?(/ガチャ|10連/)
        @service.challenge_gacha(event)
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
      if message.length <= 40  # TODO: validationはどこかに切り出したい
        begin
          @service.add_reminder(date, time, message, event)
        rescue
          @service.deny_not_setup_reminder(event)
        end
      else
        @service.deny_too_long_reminder(event)
      end
    when :profile then
      @service.make_prof(args, event)
    end
  end

  def handle_message(event, message_type)
    case message_type
    when :hash then
      @service.judge_detected_hash(event)
    end
  end

  def check_reminder
    reminder_list = @service.fetch_reminder_list
    now = TimeUtil.now
    reminder_list.each do |reminder|
      if not reminder.done and now >= reminder.time
        @service.remind(reminder)
        reminder.done = true
        @service.save_reminder_list(reminder_list)
        sleep 1
      end
    end
  end
end
