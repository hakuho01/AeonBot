require 'time'

module TimeUtil
  def parse_date_time(date_str, time_str)
    return Time.strptime(date_str + ' ' + time_str + '+9:00', '%Y/%m/%d %H:%M%z')
  end

  def parse_min_time(time_str)
    return Time.strptime(time_str + '+9:00', '%Y%m%d%H%M%z')
  end

  def format_min_time(time)
    return time.strftime('%Y%m%d%H%M')
  end

  module_function :parse_date_time, :parse_min_time, :format_min_time
end