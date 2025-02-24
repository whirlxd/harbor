class ProjectLabel < WakatimeRecord
  self.table_name = "project_labels"

  has_many :heartbeats,
    ->(project) { where(user_id: project.user_id) },
    foreign_key: :project,
    primary_key: :project_key,
    class_name: "Heartbeat"

  belongs_to :user,
    foreign_key: :user_id,
    primary_key: :slack_uid,
    class_name: "User"
end
