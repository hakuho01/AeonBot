# frozen_string_literal: true

require './framework/component'
require './service/daily_task_service'
require './service/reminder_service'

class TimerController < Component

  private

  def construct(bot)
    @daily_task_service = DailyTaskSerivice.instance.init(bot)
    @reminder_service = ReminderService.instance.init(bot)
  end

  public

  def check_daily_task
    now = TimeUtil.now
    # 2時〜5時（4時台）まで5分おき
    if now.hour >= 2 && now.hour <= 4 && now - @daily_task_service.last_warned_time >= 300
      fps_players = @daily_task_service.get_fps_players
      if not fps_players.empty?
        @daily_task_service.warn_fps_players(fps_players)
      end
    end
  end

  def check_reminder
    reminder_list = @reminder_service.fetch_reminder_list
    now = TimeUtil.now
    reminder_list.each do |reminder|
      if not reminder.done and now >= reminder.time
        @reminder_service.remind(reminder)
        reminder.done = true
        @reminder_service.save_reminder_list(reminder_list)
        sleep 1
      end
    end
  end
end
