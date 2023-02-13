require './controller/timer_controller'
require './service/daily_task_service'
require './service/reminder_service'

describe 'TimerControllerのテスト' do
  let(:bot) { double(:bot) }
  let(:daily_spec_service) { double(:daily_spec_service) }
  let(:reminder_service) { double(:reminder_service) }
  let(:event) { double(:event) }

  before do
    allow(DailyTaskSerivice).to receive_message_chain(:instance, :init).and_return(daily_spec_service)
    allow(ReminderService).to receive_message_chain(:instance, :init).and_return(reminder_service)
  end

  context 'リマインダのチェックが走ったとき' do
    let(:reminder_to_send) { Reminder.new(1, TimeUtil.now, 'test', 'test', 'test', false) }
    let(:reminder_already_sent) { Reminder.new(1, TimeUtil.now, 'test', 'test', 'test', true) }
    let(:reminder_not_yet) { Reminder.new(1, TimeUtil.now+3600, 'test', 'test', 'test', false) }

    before do
      allow(reminder_service).to receive(:fetch_reminder_list).and_return([])
    end

    it '必ずリマインダリストを取得する' do
      controller = TimerController.instance.init(bot)
      expect(reminder_service).to receive(:fetch_reminder_list)
      controller.check_reminder
    end

    context '実行すべきリマインダがあったら' do
      before do
        allow(reminder_service).to receive(:fetch_reminder_list).and_return([reminder_to_send])
      end

      it 'リマインダを送信し、送信完了ステータスを設定し、リマインダリストを保存する' do
        controller = TimerController.instance.init(bot)
        expect(reminder_service).to receive(:remind).with(reminder_to_send)
        expect(reminder_service).to receive(:save_reminder_list).with([reminder_to_send])
        controller.check_reminder
        expect(reminder_to_send.done).to eq true
      end
    end

    context '実行済みのリマインダしかなかったら' do
      before do
        allow(reminder_service).to receive(:fetch_reminder_list).and_return([reminder_already_sent])
      end

      it 'リマインダを送信せず、保存も行わない' do
        controller = TimerController.instance.init(bot)
        expect(reminder_service).not_to receive(:remind)
        expect(reminder_service).not_to receive(:save_reminder_list)
        controller.check_reminder
      end
    end

    context 'まだ実行時間が来ていないリマインダしかなかったら' do
      before do
        allow(reminder_service).to receive(:fetch_reminder_list).and_return([reminder_not_yet])
      end

      it 'リマインダを送信せず、保存も行わない' do
        controller = TimerController.instance.init(bot)
        expect(reminder_service).not_to receive(:remind)
        expect(reminder_service).not_to receive(:save_reminder_list)
        controller.check_reminder
      end
    end
  end

  context '日次タスクのチェックが走ったとき' do
    let(:fps_player_1) { double(:fps_player_1) }
    let(:fps_player_2) { double(:fps_player_2) }

    before do
      allow(daily_spec_service).to receive(:last_warned_time).and_return(Time.at(0))
    end

    context '2時になっていたら（2:00ちょうど）' do
      before do
        allow(TimeUtil).to receive(:now).and_return(TimeUtil.parse_min_time('202201260200'))
      end

      context 'VCに入っているメンバーがいれば' do
        before do
          allow(fps_player_1).to receive(:id).and_return(1)
          allow(fps_player_2).to receive(:id).and_return(2)
          allow(daily_spec_service).to receive(:get_fps_players).and_return([fps_player_1, fps_player_2])
        end

        it '叱る' do
          controller = TimerController.instance.init(bot)
          expect(daily_spec_service).to receive(:warn_fps_players).with([fps_player_1, fps_player_2])
          controller.check_daily_task
        end
      end

      context 'VCに入っているメンバーがいなければ' do
        before do
          allow(daily_spec_service).to receive(:get_fps_players).and_return([])
        end

        it '何もしない' do
          controller = TimerController.instance.init(bot)
          expect(daily_spec_service).not_to receive(:warn_fps_players)
          controller.check_daily_task
        end
      end
    end

    context '5時になっていなければ（4:59）' do
      before do
        allow(fps_player_1).to receive(:id).and_return(1)
        allow(fps_player_2).to receive(:id).and_return(2)
        allow(TimeUtil).to receive(:now).and_return(TimeUtil.parse_min_time('202201260459'))
      end

      context 'VCに入っているメンバーがいれば' do
        before do
          allow(daily_spec_service).to receive(:get_fps_players).and_return([fps_player_1, fps_player_2])
        end

        it '叱る' do
          controller = TimerController.instance.init(bot)
          expect(daily_spec_service).to receive(:warn_fps_players).with([fps_player_1, fps_player_2])
          controller.check_daily_task
        end
      end

      context '5分以内に既に叱っていたら' do
        before do
          allow(daily_spec_service).to receive(:get_fps_players).and_return([fps_player_1, fps_player_2])
          allow(daily_spec_service).to receive(:last_warned_time).and_return(TimeUtil.parse_min_time('202201260455'))
        end

        it '何もしない' do
          controller = TimerController.instance.init(bot)
          expect(daily_spec_service).not_to receive(:get_fps_players)
          expect(daily_spec_service).not_to receive(:warn_fps_players)
          controller.check_daily_task
        end
      end
    end

    context '2時になってなければ（1:59）' do
      before do
        allow(TimeUtil).to receive(:now).and_return(TimeUtil.parse_min_time('202201260159'))
        allow(fps_player_1).to receive(:id).and_return(1)
        allow(fps_player_2).to receive(:id).and_return(2)
      end

      it '何もしない' do
        controller = TimerController.instance.init(bot)
        expect(daily_spec_service).not_to receive(:get_fps_players)
        expect(daily_spec_service).not_to receive(:warn_fps_players)
        controller.check_daily_task
      end
    end

    context '5時になっていたら（4:59）' do
      before do
        allow(TimeUtil).to receive(:now).and_return(TimeUtil.parse_min_time('202201260500'))
        allow(fps_player_1).to receive(:id).and_return(1)
        allow(fps_player_2).to receive(:id).and_return(2)
      end

      it '何もしない' do
        controller = TimerController.instance.init(bot)
        expect(daily_spec_service).not_to receive(:get_fps_players)
        expect(daily_spec_service).not_to receive(:warn_fps_players)
        controller.check_daily_task
      end
    end
  end
end
