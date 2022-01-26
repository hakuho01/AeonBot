require './service/daily_task_service'

class DailyTaskController

  def initialize(bot)
    @service = DailyTaskSerivice.new(bot)
  end

  def check_daily_task
    now = TimeUtil.now
    # 2時〜5時（4時台）まで5分おき
    if now.hour >= 2 and now.hour <= 4 and now - @service.last_warned_time >= 300
      fps_players = @service.get_fps_players
      if not fps_players.empty?
        @service.warn_fps_players(fps_players)
      end
    end
  end
end