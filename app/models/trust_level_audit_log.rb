class TrustLevelAuditLog < ApplicationRecord
  belongs_to :user
  belongs_to :changed_by, class_name: "User"

  validates :previous_trust_level, presence: true
  validates :new_trust_level, presence: true
  validates :user_id, presence: true
  validates :changed_by_id, presence: true

  enum :previous_trust_level, {
    blue: "blue",
    red: "red",
    green: "green",
    yellow: "yellow"
  }, prefix: :previous

  enum :new_trust_level, {
    blue: "blue",
    red: "red",
    green: "green",
    yellow: "yellow"
  }, prefix: :new

  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :by_admin, ->(admin) { where(changed_by: admin) }

  def trust_level_change_description
    "#{previous_trust_level.capitalize} → #{new_trust_level.capitalize}"
  end

  def admin_name
    changed_by.display_name
  end
end
