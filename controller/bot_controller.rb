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
require './service/dpz_service'
require './service/social_gacha_service'
require './service/message_link_service'
require './service/routine_service'
require './service/error_notification_service'
require './service/lootbox_service'

Dotenv.load
IS_LOCAL = ENV['IS_LOCAL']
KUSA_ID = ENV['KUSA_ID']
ASASORE_CH_ID = ENV['ASASORE_CH_ID']

class BotController < Component
  private

  def construct(bot)
    $todays_date = Date.new(1, 1, 1)
    @service = BotService.instance.init(bot)
    @asasore_service = AsasoreService.instance.init
    @api_service = ApiService.instance.init
    @test_service = TestService.instance.init
    @twitter_open_service = TwitterOpenService.instance.init
    @planechaser_service = PlaneChaserService.instance.init
    @favstar_service = FavstarService.instance.init(bot)
    @dpz_service = DPZService.instance.init
    @social_gacha_service = SocialGachaService.instance.init
    @message_link_service = MessageLinkService.instance.init
    @routine_service = RoutineService.instance.init
    @error_notification_service = ErrorNotificationService.instance.init
    @lootbox_service = LootBoxService.instance.init(bot)
  end

  public

  def routine
    @routine_service.daily_routine
  rescue => e
    @error_notification_service.error_notification(e)
  end

  def reaction_control(event)
    # Lootbox
    @lootbox_service.add_reaction(event)

    if event.channel.id == ASASORE_CH_ID.to_i
      @asasore_service.asasore_check(event)
    end
    if event.emoji.id == KUSA_ID.to_i
      @favstar_service.memory_fav(event)
    end
  rescue => e
    @error_notification_service.error_notification(e)
  end

  def handle_mention(event)
    message = event.message.to_s
    if message.match?(/おはよ|おは〜|おはー|good morning/i)
      @service.say_good_morning(event)
    elsif message.match?(/おやす|おやす〜|おやすー|good night/i)
      @service.say_good_night(event)
    elsif message.match?(/プリコネ10連/)
      @social_gacha_service.priconne_gacha(event)
    elsif message.match?(/ガチャ|10連/)
      @service.challenge_gacha(event)
    elsif message.match?('楽天')
      @api_service.rakuten(event)
    elsif message.match?(/wiki/i)
      @api_service.wikipedia(event)
    elsif message.match?('コイン')
      @service.toss_coin(event)
    elsif message.match?(/朝それ|お題/)
      @asasore_service.asasore_theme(event)
    elsif message.match?(/help|ヘルプ|使い方/)
      @service.how_to_use(event)
    elsif message.match?(/ルートボックスインベントリ|lootboxinventory/)
      @lootbox_service.check_inventory(event)
    elsif message.match?(/ルートボックスポイント|lootboxpoint/)
      @lootbox_service.check_point(event)
    elsif message.match?(/ルートボックス|lootbox/)
      @lootbox_service.lottery(event)
    else
      @service.say_ai(event)
    end
  rescue => e
    @error_notification_service.error_notification(e)
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
    when :prof_sheet
      @service.show_prof_sheet(event)
    when :weight
      @weight_service.draw_graph(event)
    when :asasore
      @asasore_service.asasore_start(args, event)
    when :odai
      @asasore_service.asasore_proxy(args, event)
    end
  rescue => e
    @error_notification_service.error_notification(e)
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
    when :message_link
      @message_link_service.message_link(event)
    when :dpz
      @dpz_service.open_dpz(event)
    end
  rescue => e
    @error_notification_service.error_notification(e)
  end
end
