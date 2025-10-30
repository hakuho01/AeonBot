require './framework/repository'

class ChannelActivityRepository < Repository
  # 分バケットのカウントを+1
  def increment_bucket(channel_id, minute_ts)
    @db[:channel_activity].insert_conflict(
      target: %i[channel_id minute_ts],
      update: { msg_count: Sequel[:channel_activity][:msg_count] + 1 }
    ).insert(channel_id:, minute_ts:, msg_count: 1)
  end

  # 直近window_min分の合計メッセージ数
  def total_count_last_minutes(channel_id, now_ts, window_min)
    from_ts = now_ts - window_min * 60
    @db[:channel_activity]
      .where(channel_id:)
      .where { minute_ts >= Time.at(from_ts) }
      .sum(:msg_count) || 0
  end

  # TTLより古いバケットを削除
  def delete_older_than(cutoff_ts)
    @db[:channel_activity].where { minute_ts < cutoff_ts }.delete
  end

  # 最近活動のあったチャンネル一覧
  def active_channel_ids_since(since_ts)
    @db[:channel_activity]
      .where { minute_ts >= since_ts }
      .select_map(:channel_id)
      .uniq
  end
end
