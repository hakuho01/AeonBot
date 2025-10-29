require './framework/repository'

class ReactionRepository < Repository
  # リアクションIDでレコードを検索
  def get_reaction(reaction_id)
    @db[:reactions].where(reaction_id:).first
  end

  # リアクションカウントを1増やす
  def increment_count(reaction_id)
    @db[:reactions].where(reaction_id:).update(count: Sequel[:count] + 1)
  end

  # 新規リアクションレコードを作成（count初期値1）
  def add_reaction(reaction_id, emoji_name, is_custom)
    @db[:reactions].insert(reaction_id:, emoji_name:, is_custom:, count: 1)
  end

  # リアクションIDに該当するレコードがあれば+1、なければ新規作成
  def record_reaction(reaction_id, emoji_name, is_custom)
    # PostgreSQLのINSERT ... ON CONFLICT を使用して、競合を回避
    @db[:reactions].insert_conflict(
      target: :reaction_id,
      update: { count: Sequel[:reactions][:count] + 1 }
    ).insert(
      reaction_id:,
      emoji_name:,
      is_custom:,
      count: 1
    )
  rescue Sequel::DatabaseError => e
    # fallback: 既存の方法で再試行
    puts "Upsert failed, using fallback method: #{e.message}"
    existing_reaction = get_reaction(reaction_id)

    if existing_reaction
      increment_count(reaction_id)
    else
      add_reaction(reaction_id, emoji_name, is_custom)
    end
  end

  # 使用回数の多い順に上位N件を取得
  def get_top_reactions(limit = 10)
    @db[:reactions].order(Sequel.desc(:count)).limit(limit).all
  end
end
