require './controller/daily_task_controller'
require './service/daily_task_service'

describe 'DailyTaskControllerのテスト' do

  let(:bot) {double(:bot)}
  let(:service) { double(:service) }
  let(:event) { double(:event) }

  before do
    allow(DailyTaskSerivice).to receive_message_chain(:instance, :init).and_return(service)
  end

  context '日次タスクのチェックが走ったとき' do

    let(:fps_player_1) { double(:fps_player_1) }
    let(:fps_player_2) { double(:fps_player_2) }

    before do
      allow(service).to receive(:last_warned_time).and_return(Time.at(0))
    end

    context '2時になっていたら（2:00ちょうど）' do
      before do
        allow(TimeUtil).to receive(:now).and_return(TimeUtil.parse_min_time('202201260200'))
      end
      
      context 'VCに入っているメンバーがいれば' do
        before do
          allow(fps_player_1).to receive(:id).and_return(1)
          allow(fps_player_2).to receive(:id).and_return(2)
          allow(service).to receive(:get_fps_players).and_return([fps_player_1, fps_player_2])
        end

        it '叱る' do
          controller = DailyTaskController.instance.init(bot)
          expect(service).to receive(:warn_fps_players).with([fps_player_1, fps_player_2])
          controller.check_daily_task
        end
      end

      context 'VCに入っているメンバーがいなければ' do
        before do
          allow(service).to receive(:get_fps_players).and_return([])
        end

        it '何もしない' do
          controller = DailyTaskController.instance.init(bot)
          expect(service).not_to receive(:warn_fps_players)
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
          allow(service).to receive(:get_fps_players).and_return([fps_player_1, fps_player_2])
        end

        it '叱る' do
          controller = DailyTaskController.instance.init(bot)
          expect(service).to receive(:warn_fps_players).with([fps_player_1, fps_player_2])
          controller.check_daily_task
        end
      end

      context '5分以内に既に叱っていたら' do
        before do
          allow(service).to receive(:get_fps_players).and_return([fps_player_1, fps_player_2])
          allow(service).to receive(:last_warned_time).and_return(TimeUtil.parse_min_time('202201260455'))
        end

        it '何もしない' do
          controller = DailyTaskController.instance.init(bot)
          expect(service).not_to receive(:get_fps_players)
          expect(service).not_to receive(:warn_fps_players)
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
        controller = DailyTaskController.instance.init(bot)
        expect(service).not_to receive(:get_fps_players)
        expect(service).not_to receive(:warn_fps_players)
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
        controller = DailyTaskController.instance.init(bot)
        expect(service).not_to receive(:get_fps_players)
        expect(service).not_to receive(:warn_fps_players)
        controller.check_daily_task
      end
    end
  end
end
