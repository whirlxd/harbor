class SailorsLog < ApplicationRecord
  validates :slack_uid, presence: true, uniqueness: true
  after_create :initialize_projects_summary

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
    self.projects_summary = {}
    Heartbeat.where(user_id: slack_uid).distinct.pluck(:project).each do |project|
      self.projects_summary[project] = Heartbeat.where(user_id: slack_uid, project: project).duration_seconds
    end
    save! if changed?
  end
end
