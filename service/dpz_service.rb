# frozen_string_literal: true

require './framework/component'

class DPZService < Component
  def open_dpz(event)
    # 埋め込み内容(ツイート内容)を取得
    embed_desc = event.message.embeds[0].description
    # URLを抽出
    dpz_url = embed_desc.match(%r{https://t.co/[a-zA-Z0-9_]+}).to_s
    event.respond(dpz_url)

    event.message.delete
  end
end
