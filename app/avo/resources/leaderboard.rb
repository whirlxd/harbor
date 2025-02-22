class Avo::Resources::Leaderboard < Avo::BaseResource
  def fields
    field :id, as: :id
    field :start_date, as: :date
    field :finished_generating_at, as: :date_time
    field :has_generated, as: :boolean do
      record.finished_generating_at.present?
    end
    field :entries_count, as: :number do
      record.entries.count
    end
    field :deleted, as: :boolean do
      record.deleted_at.present?
    end
  end
end
