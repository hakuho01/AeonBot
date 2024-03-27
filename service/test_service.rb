# frozen_string_literal: true

class TestService < Component
  def testing(args, event)
    # ここにテストしたい処理を書く
    puts event
    puts args
  end
end
