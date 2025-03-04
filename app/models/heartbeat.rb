class Heartbeat < ApplicationRecord
  # This is to prevent Rails from trying to use STI even though we have a "type" column
  self.inheritance_column = nil

  belongs_to :user

  validates :time, presence: true
  validates :time, uniqueness: { scope: [ :user_id, :project, :branch, :language, :dependencies, :lineno, :cursorpos, :is_write, :entity, :type, :category, :project_root_count ] }
end
