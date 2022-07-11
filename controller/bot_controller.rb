require 'discordrb'
require 'dotenv'

require './framework/component'
require './service/bot_service'
require './service/asasore_service'
require './service/api_service'
require './service/test_service'
require './service/twitter_open_service'
require './service/planechaser_service'
require './service/favstar_service'

Dotenv.load
IS_LOCAL = ENV['IS_LOCAL']
KUSA_ID = ENV['KUSA_ID']

class BotController < Component
  private

  def construct(bot)
    @service = BotService.instance.init(bot)
    @asasore_service = AsasoreService.instance.init
    @api_service = ApiService.instance.init
    @test_service = TestService.instance.init
    @twitter_open_service = TwitterOpenService.instance.init
    @planechaser_service = PlaneChaserService.instance.init
    @favstar_service = FavstarService.instance.init(bot)
  end

  public

  def reaction_control(event)
    if event.emoji.id == KUSA_ID.to_i
      @favstar_service.memory_fav(event)
    end
  end

  def handle_mention(event)
    message = event.message.to_s
    if message.match?(/おはよ|おは〜|おはー|good morning/i)
      @service.say_good_morning(event)
    elsif message.match?(/おやす|おやす〜|おやすー|good night/i)
      @service.say_good_night(event)
    elsif message.match?(/ガチャ|10連/)
      @service.challenge_gacha(event)
    elsif message.match?('楽天')
      @api_service.rakuten(event)
    elsif message.match?(/wiki/i)
      @api_service.wikipedia(event)
    elsif message.match?('コイン')
      @service.toss_coin(event)
    elsif message.match?(/asasore|朝それ|お題/)
      @asasore_service.asasore_theme(event)
    else
      @service.say_random(event)
    end
  end

  def handle_command(event, args, command_type)
    case command_type
    when :remind
      date = args[0]
      time = args[1]
      message = args.slice(2..args.length - 1).join(' ')
      if message.length <= 40  # TODO: validationはどこかに切り出したい
        begin
          @service.add_reminder(date, time, message, event)
        rescue ReminderRepositoryNotSetUpError
          @service.deny_not_setup_reminder(event)
        end
      else
        @service.deny_too_long_reminder(event)
      end
    when :profile
      @service.make_prof(args, event)
    when :roll
      @service.roll_dice(args, event)
    when :rand
      @service.random_choice(args, event)
    when :test
      @test_service.testing(args, event)
    when :open
      @twitter_open_service.tweet_opening(args, event)
    when :plane
      @planechaser_service.planes(args, event)
    end
  end

  def handle_message(event, message_type)
    case message_type
    when :hash
      @service.judge_detected_hash(event)
    when :thumb
      @api_service.twitter_thumbnail(event)
    when :wg
      @api_service.wisdom_guild(event)
    when :dfc
      @api_service.scryfall(event)
    end
  end
end
