# frozen_string_literal: true

module Constants
  module Speech
    RESPONSE_MENTION = [
      '……何？',
      'イチゴのショートケーキ……ふふっ……。',
      '……チョコレートケーキがいい。',
      '……チーズケーキ？　……うん、チーズケーキなら、いい。',
      'どうしたの……？　モンブランみたいな顔してる……。',
      'ねえ……あなたは、ミルクレープって知ってる……？　クリームと、クレープが重なって、ふわふわ……。',
      'ロールケーキって……なんで渦を巻いているんだろう……。',
      '味方にキレるなんて……体に、悪い……。',
      '味方にキレた時……ケルベロスは、あなたに牙を剥く……。',
      'あなたも、味方にキレる者……？',
      '味方にキレる者を断罪する……それだけが、黒衣の死天使が存在する理由……。',
      '野良にゲームを破壊されても……あなたの灯火は、消えない……。人が死ぬのは……人が人であることを忘れ、味方にキレた時……。',
      '……本当に、味方にキレたの……？　気持ち悪い……。味方にキレるのが許されるのは……アイアン帯まで……。',
      'これ……？　これは、不要なカンをした人間に、高圧電流を流すスイッチ……。',
      '話しかけないで。',
      'ケルベロスが……哭いている……。',
      '私は……帝国の剣……剣に、感情など……。',
      '……？　何か、用……？',
      '黙示録の鐘が……鳴り響く……。',
      '死は……全ての者に、平等……故に、死天使は……誰とも、馴れ合わない……。',
      '帝国に歯向かうこと……それこそが、罪……。',
      '……これは、一体……。',
      'これもまた、罪……。',
      '……何を言っているの……？',
      '……気持ち悪い……近寄らないで……。',
      'ここは、騒がしい……居心地が悪い……。',
      '……そんなこと、初めて言われた……。',
      'まだ……あなたは死すべきでない……。',
      '……虚しい人生ね……。',
      'あなたの心にも……闇がある……。',
      '少し黙って。',
      '私の全ては、帝国のために……。',
      '……研究所は、嫌い……。',
      '余暇があるなら……訓練に、戻って……。',
      '死に触れたがるのなんて……あなたくらい……。',
      '……行こう、ケルベロス。ここにいても意味がない。',
      '命は……灯火……私が吹けば、皆消える……。これ以上、私に近寄らないで……。',
      'そんなこと、帝国では教わらなかった……。',
      '聞いてなかった。もう一回は話さなくていい、聞く気ないから。',
      'それは……私に言われても、困る……。',
      '壁とでも話してて。',
      '……死にたいの？',
      '……はあ……。',
      'どいて。魔骸の調整に行かなくちゃ。',
      'あまりこっちを見ないで。気色が悪い。',
      'あっちに行って。ケーキがまずくなる。',
      '何を言っているの？　帝国の公用語で話して。',
      '死を恐れない、それこそがあなたのあかさたな……えっと……浅はかさ。',
      'そんなこと、あなたには関係ない。',
      '……少なくとも、あなたのことは好きじゃない。'
    ].freeze

    # ハッシュ値検知関連
    DETECT_HASH = 'ハッシュ値やアクセストークンの疑いがある文字列を、検出……この空間においては、許可されない……。'
    PURGE = '警告はした……あなたの罪、『黒衣の死天使』が粛清する……！'
    PURGE_TEST_MODE = '……テストモード……。命拾いしたわね……。'

    # リマインダ関連
    ADD_REMINDER = '%sに「%s」とリマインドする。……覚えた。'
    DENY_TOO_LONG_REMINDER = '……長すぎる。覚えられない。'
    REMIND = '「%s」……あなたは覚えてる？'
    DENY_NOT_SETUP_REMINDER = '今は何も覚えられないわ……研究員に相談して。'

    WARN_FPS_PLAYERS = [
      '寝なさい。',
      '寝ることくらい、赤子だってできるのに。'
    ]

    CHOICE_RANDOM = '選ばれたのは……「%s」。'
    TOSS_COIN = [':coin:　……表。', ':yellow_circle:　……裏。']
  end

  module URLs
    WIKIPEDIA = 'https://ja.wikipedia.org/w/api.php?format=json&action=query&generator=random&grnnamespace=0&prop=info&inprop=url&indexpageids'
    RAKUTEN_GENRE = 'https://app.rakuten.co.jp/services/api/IchibaGenre/Search/20140222?applicationId=1081731812152273419&genreId=0'
    RAKUTEN_RANKING = 'https://app.rakuten.co.jp/services/api/IchibaItem/Ranking/20170628?format=json&applicationId=1081731812152273419&genreId='
    BC_DICE = 'https://bcdice.onlinesession.app'
    BC_DICE_BACKUP = 'https://bcdice.museru.com/org'
    ASASORE = 'https://soreseikai.com/'
  end
end
