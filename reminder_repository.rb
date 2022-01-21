require 'csv'
require './util/time_util'

Dotenv.load
REMINDER_DATA_CHANNEL_ID = ENV['REMINDER_DATA_CHANNEL_ID']
REMINDER_DATA_MESSAGE_ID = ENV['REMINDER_DATA_MESSAGE_ID']

$reminder_list = []
$reminder_next_id = 0

class ReminderRepository
  def initialize
    @channel_api = Discordrb::API::Channel
  end

  def fetch_all
    $reminder_list = read
    dump = Marshal.dump($reminder_list)
    return Marshal.load(dump)
  end

  def add(reminder)
    $reminder_list.push(reminder)
    write($reminder_list)
  end

  def get_next_id
    $reminder_next_id += 1
    return $reminder_next_id.dup
  end

  def save_all(reminder_list)
    $reminder_list = reminder_list
    write($reminder_list)
  end

  private

  def read
    response = @channel_api.message("Bot #{TOKEN}", REMINDER_DATA_CHANNEL_ID, REMINDER_DATA_MESSAGE_ID)
    csv = JSON.parse(response.body)['content']

    reminder_list = []
    reminder_last_id = 0
    if csv != "none"
      CSV.parse(csv).each do |row|
        time = TimeUtil::parse_min_time(row[0])
        message = row[1]
        channel_id = row[2]
        user_id = row[3]
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

    @channel_api.edit_message("Bot #{TOKEN}", REMINDER_DATA_CHANNEL_ID, REMINDER_DATA_MESSAGE_ID, csv == "" ? "none" : csv)
  end
end