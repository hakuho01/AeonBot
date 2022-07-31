# frozen_string_literal: true

class Reminder
  def initialize(reminder_id, time, message, channel_id, user_id, done = false)
    @reminder_id = reminder_id
    @time = time
    @message = message
    @channel_id = channel_id
    @user_id = user_id
    @done = done
  end

  attr_reader :reminder_id, :time, :message, :channel_id, :user_id
  attr_accessor :done
end
