class SailorsLog < ApplicationRecord
  validates :slack_uid, presence: true, uniqueness: true
  validates :projects_summary, presence: true

  before_validation :initialize_projects_summary

  has_many :notification_preferences,
           class_name: "SailorsLogNotificationPreference",
           foreign_key: :slack_uid,
           primary_key: :slack_uid

  has_many :notifications,
           class_name: "SailorsLogSlackNotification",
           foreign_key: :slack_uid,
           primary_key: :slack_uid

  private

  def initialize_projects_summary
    return unless projects_summary.blank?
    self.projects_summary = Heartbeat.where(user_id: slack_uid).group(:project).duration_seconds
  end
end
