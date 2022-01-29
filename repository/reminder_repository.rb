require 'csv'

require './framework/component'
require './util/time_util'

Dotenv.load
REMINDER_DATA_CHANNEL_ID = ENV['REMINDER_DATA_CHANNEL_ID'].to_i
REMINDER_DATA_MESSAGE_ID = ENV['REMINDER_DATA_MESSAGE_ID'].to_i

# グローバル変数でリマインダ一覧を管理している
# 他のクラスから直接参照せず、かならずReminderRepositoryのメソッドを使用すること
$reminder_list = []
$reminder_next_id = 0

class ReminderRepository < Component

  private

  def construct(bot)
    @bot = bot
    if REMINDER_DATA_CHANNEL_ID != nil and REMINDER_DATA_MESSAGE_ID != nil
      $reminder_list = read
      @never_fetched = false
    else
      @never_fetched = true
    end
  end

  public

  def fetch_all
    if @never_fetched
      raise ReminderRepositoryNotSetUpError
    end
    # そのまま渡すと直接書き換えられてしまうため、コピーオブジェクトを渡す
    # dumpを経由することで深いコピーにしている
    dump = Marshal.dump($reminder_list)
    return Marshal.load(dump)
  end

  def add(reminder)
    if @never_fetched
      raise ReminderRepositoryNotSetUpError
    end
    $reminder_list.push(reminder)
    write($reminder_list)
  end

  def get_next_id
    if @never_fetched
      raise ReminderRepositoryNotSetUpError
    end
    $reminder_next_id += 1
    # そのまま渡すと直接書き換えられてしまうため、コピーオブジェクトを渡す
    return $reminder_next_id.dup
  end

  def save_all(reminder_list)
    if @never_fetched
      raise ReminderRepositoryNotSetUpError
    end
    $reminder_list = reminder_list
    write($reminder_list)
  end

  private

  def read
    # 保存用メッセージから読み込み
    csv = @bot.channel(REMINDER_DATA_CHANNEL_ID).message(REMINDER_DATA_MESSAGE_ID).content
    reminder_list = []
    reminder_last_id = 0
    if csv != 'none'
      CSV.parse(csv).each do |row|
        # リマインダ情報として読み取れない行があったらその時点で読み込み終了する
        begin
          time = TimeUtil::parse_min_time(row[0])
          message = row[1]
          channel_id = row[2]
          user_id = row[3]
        rescue
          break
        end
        reminder_list.push(Reminder.new(reminder_last_id+1, time, message, channel_id, user_id, false))
      end
    end

    return reminder_list
  end

  def write(reminder_list)
    csv = CSV.generate do |csv|
      reminder_list.each do |reminder|
        if not reminder.done
          csv.add_row([
            TimeUtil::format_min_time(reminder.time),
            reminder.message,
            reminder.channel_id,
            reminder.user_id
          ])
        end
      end
    end
    @bot.channel(REMINDER_DATA_CHANNEL_ID).message(REMINDER_DATA_MESSAGE_ID).edit(csv == '' ? 'none' : csv)
  end
end

class ReminderRepositoryNotSetUpError < StandardError
  def initialize(msg='Reminder repository has not set up yet. Cannot use reminder function.')
  end
end