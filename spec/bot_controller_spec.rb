require './controller/bot_controller'
require './service/bot_service'
require './model/reminder'

describe 'BotControllerのテスト' do

  let(:bot) {double(:bot)}
  let(:service) { double(:service) }
  let(:event) { double(:event) }
  let(:args) { double(:args) }

  before do
    allow(BotService).to receive_message_chain(:instance, :init).and_return(service)
  end

  context 'メンションが来たとき' do
    context '「おはよう」の場合' do
      before do
        allow(event).to receive_message_chain(:message, :to_s).and_return('おはよう')
      end

      it 'おはようと返す' do
        controller = BotController.instance.init(bot)
        expect(service).to receive(:say_good_morning).with(event)
        controller.handle_mention(event)
      end
    end

    context '「おやすみ」の場合' do
      before do
        allow(event).to receive_message_chain(:message, :to_s).and_return('おやすみ')
      end

      it 'おやすみと返す' do
        controller = BotController.instance.init(bot)
        expect(service).to receive(:say_good_night).with(event)
        controller.handle_mention(event)
      end
    end

    context '「楽天」の場合' do
      before do
        allow(event).to receive_message_chain(:message, :to_s).and_return('黒衣の楽天使')
      end

      it '楽天の商品をサジェストする' do
        controller = BotController.instance.init(bot)
        expect(service).to receive(:suggest_rakuten).with(event)
        controller.handle_mention(event)
      end
    end

    context '「wiki」の場合' do
      before do
        allow(event).to receive_message_chain(:message, :to_s).and_return('今日のwikipedia')
      end

      it 'Wikipediaの記事をサジェストする' do
        controller = BotController.instance.init(bot)
        expect(service).to receive(:suggest_wikipedia).with(event)
        controller.handle_mention(event)
      end
    end

    context '「ガチャ」の場合' do
      before do
        allow(event).to receive_message_chain(:message, :to_s).and_return('ガチャを回す')
      end

      it 'リアクション10連ガチャを回す' do
        controller = BotController.instance.init(bot)
        expect(service).to receive(:challenge_gacha).with(event)
        controller.handle_mention(event)
      end
    end

    context '「10連」の場合' do
      before do
        allow(event).to receive_message_chain(:message, :to_s).and_return('今日の10連')
      end

      it 'リアクション10連ガチャを回す' do
        controller = BotController.instance.init(bot)
        expect(service).to receive(:challenge_gacha).with(event)
        controller.handle_mention(event)
      end
    end

    context 'その他のメンションの場合' do
      before do
        allow(event).to receive_message_chain(:message, :to_s).and_return('可愛いね')
      end

      it 'ランダムな返答をする' do
        controller = BotController.instance.init(bot)
        expect(service).to receive(:say_random).with(event)
        controller.handle_mention(event)
      end
    end
  end

  context 'コマンドが来たとき' do
    context 'remindコマンドの場合' do
      context '適正なリマインダ情報が入力されていたら' do
        it 'リマインダを登録する' do
          controller = BotController.instance.init(bot)
          date = '2022/1/23'
          time = '4:56'
          message = '0123456789abcdefghijあいうえおかきくけこアイウエオカキクケコ'
          expect(service).to receive(:add_reminder).with(date, time, message, event)
          controller.handle_command(event, [date, time, message], :remind)
        end
      end

      context 'メッセージの長さが適正でなかったら' do
        it '長過ぎる旨の返答を行い、リマインダ登録は行わない' do
          controller = BotController.instance.init(bot)
          date = '2022/1/23'
          time = '4:56'
          message = '0123456789abcdefghijあいうえおかきくけこアイウエオカキクケコA'
          expect(service).to receive(:deny_too_long_reminder).with(event)
          expect(service).to_not receive(:add_reminder)
          controller.handle_command(event, [date, time, message], :remind)
        end
      end

      context '未セットアップエラーが発生したら' do
        before do
          allow(service).to receive(:add_reminder).and_raise(ReminderRepositoryNotSetUpError)
        end

        it '現在は登録できない旨の返答を行う' do
          controller = BotController.instance.init(bot)
          date = '2022/1/23'
          time = '4:56'
          message = '0123456789abcdefghijあいうえおかきくけこアイウエオカキクケコ'
          expect(service).to receive(:deny_not_setup_reminder).with(event)
          controller.handle_command(event, [date, time, message], :remind)
        end
      end
    end
  end

  context 'profコマンドの場合' do
    it 'プロフを生成する' do
      controller = BotController.instance.init(bot)
      expect(service).to receive(:make_prof).with(args, event)
      controller.handle_command(event, args, :profile)
    end
  end
end
