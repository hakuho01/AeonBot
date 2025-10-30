require './framework/repository'

class SummaryRepository < Repository
  # 直近cooldown_min分以内に要約済みか
  def summarized_recently?(channel_id, now_ts, cooldown_min)
    cutoff = Time.at(now_ts - cooldown_min * 60)
    !@db[:summaries].where(channel_id:).where { created_at >= cutoff }.empty?
  end

  def save_summary_record(channel_id, start_ts, end_ts, posted_message_id)
    @db[:summaries].insert(
      channel_id:,
      start_ts:,
      end_ts:,
      posted_message_id:,
      created_at: Time.now
    )
  end
end
