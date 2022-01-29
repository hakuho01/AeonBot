# frozen_string_literal: true

require './framework/component'
require './service/daily_task_service'

class DailyTaskController < Component

  private

  def construct(bot)
    @service = DailyTaskSerivice.instance.init(bot)
  end

  public

  def check_daily_task
    now = TimeUtil.now
    # 2時〜5時（4時台）まで5分おき
    if now.hour >= 2 && now.hour <= 4 && now - @service.last_warned_time >= 300
      fps_players = @service.get_fps_players
      if not fps_players.empty?
        @service.warn_fps_players(fps_players)
      end
    end
  end
end
