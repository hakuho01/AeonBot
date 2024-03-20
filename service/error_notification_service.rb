# frozen_string_literal: true

require './util/api_util'
require './framework/component'

Dotenv.load
ERROR_CH_ID = ENV['ERROR_CH_ID']

class ErrorNotificationService < Component
  def error_notification(error)
    ApiUtil.post(
      "https://discordapp.com/api/channels/#{ERROR_CH_ID}/messages",
      {
        "content": "エラーが……発生した……\n### 日時\n#{Time.now}\n### エラー内容\n#{error.inspect}\n```#{error.backtrace}```"
      },
      { 'Content-Type' => 'application/json', 'Authorization' => "Bot #{TOKEN}" }
    )
  end
end
