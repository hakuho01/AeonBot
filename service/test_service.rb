# frozen_string_literal: true

class TestService < Component
  def testing(event, args)
    # ここにテストしたい処理を書く
    uri = URI.parse('https://discordapp.com/api/channels/725471441260118097/messages')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme === 'https'
    params = {
      "embeds": [
        {
          "url": "https://twitter.com/GrapeColorSoft/status/1205289368786620416",
          "description": "複数枚画像投稿テスト",
          "author": {
            "name": "GrapeColor (@GrapeColorSoft)",
            "url": "https://twitter.com/GrapeColorSoft",
            "icon_url": "https://pbs.twimg.com/profile_images/1063236006135062528/493Dm2lD_bigger.jpg"
          },
          "image": {"url": "https://pbs.twimg.com/media/ELoMRwLVUAAFlm_.jpg:large"}
        },
        {
          "url": "https://twitter.com/GrapeColorSoft/status/1205289368786620416",
          "image": {"url": "https://pbs.twimg.com/media/ELoMRwNU8AEMaoO.jpg:large"}
        },
        {
          "url": "https://twitter.com/GrapeColorSoft/status/1205289368786620416",
          "image": {"url": "https://pbs.twimg.com/media/ELoMRwNUwAAWako.jpg:large"}
        },
        {
          "url": "https://twitter.com/GrapeColorSoft/status/1205289368786620416",
          "image": {"url": "https://pbs.twimg.com/media/ELoMRwMU8AELiyj.jpg:large"}
        }
      ]
    }
    headers = { 'Content-Type' => 'application/json', 'Authorization' => 'Bot OTIyODU5NTA3OTE3NDEwMzA0.YcHl5A.yMBjjkhHFSsZcO5HDtyvWQKvmyI' }
    response = http.post(uri.path, params.to_json, headers)
    puts response.code
    puts response.body
    puts event
    puts args
  end
end
