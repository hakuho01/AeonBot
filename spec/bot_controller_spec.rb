require './controller/bot_controller'
require './service/bot_service'
require './model/reminder'

describe 'BotControllerのテスト' do

  let(:service) { double(:service) }
  let(:event) { double(:event) }

  before do
    allow(BotService).to receive(:new).and_return(service)
  end

  context "メンションが来たとき" do
    context "「おはよう」の場合" do
      before do
        allow(event).to receive_message_chain(:message, :to_s).and_return("おはよう")
      end

      it 'おはようと返す' do
        controller = BotController.new
        expect(service).to receive(:say_good_morning).with(event)
        controller.handle_mention(event)
      end
    end

    context "「おやすみ」の場合" do
      before do
        allow(event).to receive_message_chain(:message, :to_s).and_return("おやすみ")
      end

      it 'おやすみと返す' do
        controller = BotController.new
        expect(service).to receive(:say_good_night).with(event)
        controller.handle_mention(event)
      end
    end

    context "「楽天」の場合" do
      before do
        allow(event).to receive_message_chain(:message, :to_s).and_return("黒衣の楽天使")
      end

      it '楽天の商品をサジェストする' do
        controller = BotController.new
        expect(service).to receive(:suggest_rakuten).with(event)
        controller.handle_mention(event)
      end
    end

    context "「wiki」の場合" do
      before do
        allow(event).to receive_message_chain(:message, :to_s).and_return("今日のwikipedia")
      end

      it 'Wikipediaの記事をサジェストする' do
        controller = BotController.new
        expect(service).to receive(:suggest_wikipedia).with(event)
        controller.handle_mention(event)
      end
    end

    context "その他のメンションの場合" do
      before do
        allow(event).to receive_message_chain(:message, :to_s).and_return("可愛いね")
      end

      it 'ランダムな返答をする' do
        controller = BotController.new
        expect(service).to receive(:say_random).with(event)
        controller.handle_mention(event)
      end
    end
  end

  context "コマンドが来たとき" do
    context "remindコマンドの場合" do
      context "適正なリマインダ情報が入力されていたら" do
        it 'リマインダを登録する' do
          controller = BotController.new
          date = "2022/1/23"
          time = "4:56"
          message = "0123456789abcdefghijあいうえおかきくけこアイウエオカキクケコ"
          expect(service).to receive(:add_reminder).with(date, time, message, event)
          controller.handle_command(event, [date, time, message], :remind)
        end
      end

      context "メッセージの長さが適正でなかったら" do
        it '長過ぎる旨の返答を行い、リマインダ登録は行わない' do
          controller = BotController.new
          date = "2022/1/23"
          time = "4:56"
          message = "0123456789abcdefghijあいうえおかきくけこアイウエオカキクケコA"
          expect(service).to receive(:deny_too_long_reminder).with(event)
          expect(service).to_not receive(:add_reminder)
          controller.handle_command(event, [date, time, message], :remind)
        end
      end
    end
  end

  context "リマインダのチェックが走ったとき" do

    let(:reminder_to_send) { Reminder.new(1, Time.now, "test", "test", "test", false) }
    let(:reminder_already_sent) { Reminder.new(1, Time.now, "test", "test", "test", true) }
    let(:reminder_not_yet) { Reminder.new(1, Time.now+3600, "test", "test", "test", false) }

    context "実行すべきリマインダがあったら" do
      before do
        allow(service).to receive(:fetch_reminder_list).and_return([reminder_to_send])
      end

      it "リマインダを送信し、送信完了ステータスを設定し、リマインダリストを保存する" do
        controller = BotController.new
        expect(service).to receive(:remind).with(reminder_to_send)
        expect(service).to receive(:save_reminder_list).with([reminder_to_send])
        controller.check_reminder
        expect(reminder_to_send.done).to eq true
      end
    end

    context "実行済みのリマインダしかなかったら" do
      before do
        allow(service).to receive(:fetch_reminder_list).and_return([reminder_already_sent])
      end

      it "リマインダを送信せず、保存も行わない" do
        controller = BotController.new
        expect(service).not_to receive(:remind)
        expect(service).not_to receive(:save_reminder_list)
        controller.check_reminder
      end
    end

    context "まだ実行時間が来ていないリマインダしかなかったら" do
      before do
        allow(service).to receive(:fetch_reminder_list).and_return([reminder_not_yet])
      end

      it "リマインダを送信せず、保存も行わない" do
        controller = BotController.new
        expect(service).not_to receive(:remind)
        expect(service).not_to receive(:save_reminder_list)
        controller.check_reminder
      end
    end
  end
end
