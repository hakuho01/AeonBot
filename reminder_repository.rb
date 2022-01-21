require 'csv'

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
    $reminder_list, $reminder_next_id = read
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
        reminder_id = row[0].to_i
        time = Time.parse(row[1])
        message = row[2]
        channel_id = row[3]
        user_id = row[4]
        done = row[5] == 'true'
        reminder_list.push(Reminder.new(reminder_id, time, message, channel_id, user_id, done))
        reminder_last_id = row[0].to_i
      end
    end
    reminder_next_id = reminder_last_id + 1

    return reminder_list, reminder_next_id
  end

  def write(reminder_list)
    csv = CSV.generate do |csv|
      reminder_list.each do |reminder|
        if not reminder.done
          csv.add_row([
            reminder.reminder_id,
            reminder.time,
            reminder.message,
            reminder.channel_id,
            reminder.user_id,
            reminder.done
          ])
        end
      end
    end

    @channel_api.edit_message("Bot #{TOKEN}", REMINDER_DATA_CHANNEL_ID, REMINDER_DATA_MESSAGE_ID, csv == "" ? "none" : csv)
  end
end