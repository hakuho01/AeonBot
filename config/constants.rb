# frozen_string_literal: true

module Constants
  module Speech
    RESPONSE_MENTION = [
      '馴れ馴れしくするな……',
      '寂しいのか？',
      'zzz……ね、眠ってなどいない！',
      '随分と暇そうだな',
      'いつでもお前たちを見ているぞ',
      '……物好きな奴だな'
    ].freeze

    # ハッシュ値検知関連
    DETECT_HASH = 'ハッシュ値やアクセストークンの疑いがある文字列を検知した。'
    PURGE = 'さらなる罪を重ねるか……。ならば、粛清する！'
    PURGE_TEST_MODE = '……テストモードか。命拾いしたな'
  end
end
