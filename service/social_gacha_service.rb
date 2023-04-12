class SocialGachaService < Component
  def priconne_gacha(event)
    gacha_p = Constants::Social_gacha::PRICONNE_GACHA
    gacha_result = ''
    10.times do |n|
      r_num = rand(1..100)
      if n == 9
        case r_num
        when 0..gacha_p[1][0]
          gacha_result << '<:3_:787988959506333708>'
        when (gacha_p[1][0] + 1)..gacha_p[1][1]
          gacha_result << '<:SR:787988959661260801>'
        when (gacha_p[1][1] + 1)..100
          gacha_result << '<:SSR:787988959728893972>'
        end
      else
        case r_num
        when 0..gacha_p[0][0]
          gacha_result << '<:3_:787988959506333708>'
        when (gacha_p[0][0] + 1)..gacha_p[0][1]
          gacha_result << '<:SR:787988959661260801>'
        when (gacha_p[0][1] + 1)..100
          gacha_result << '<:SSR:787988959728893972>'
        end
      end
    end
    event.respond gacha_result
  end
end
