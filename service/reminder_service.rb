# frozen_string_literal: true

require './framework/component'
require './config/constants'

class ReminderService < Component
  
  private

  def construct(bot)
    @reminder_repository = ReminderRepository.instance.init(bot)
    @bot = bot
  end

  public

  def remind(reminder)
    message = "<@!#{reminder.user_id}>" + Constants::Speech::REMIND % reminder.message
    @bot.channel(reminder.channel_id).send_message(message)
  end

  def fetch_reminder_list
    @reminder_repository.fetch_all
  end

  def save_reminder_list(reminder_list)
    @reminder_repository.save_all(reminder_list)
  end

end
