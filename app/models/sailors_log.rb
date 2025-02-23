class SailorsLog < ApplicationRecord
  validates :slack_uid, presence: true, uniqueness: true
  validates :projects_summary, presence: true

  before_create :initialize_projects_summary

  has_many :notification_preferences,
           class_name: "SailorsLogNotificationPreference",
           foreign_key: :slack_uid,
           primary_key: :slack_uid

  has_many :notifications,
           class_name: "SailorsLogSlackNotification",
           foreign_key: :slack_uid,
           primary_key: :slack_uid

  def self.generate_leaderboard(channel)
    # Get all users with enabled preferences in the channel
    users_in_channel = SailorsLogNotificationPreference.where(enabled: true, slack_channel_id: channel)
                                                   .distinct
                                                   .pluck(:slack_uid)

    # Get all durations for users in channel
    user_durations = Heartbeat.where(user_id: users_in_channel)
                             .today
                             .group(:user_id)
                             .duration_seconds

    # Sort and take top 10 users
    top_user_ids = user_durations.sort_by { |_, duration| -duration }.first(10).map(&:first)

    # Now get detailed project info only for top 10 users
    top_user_ids.map do |user_id|
      user_heartbeats = Heartbeat.where(user_id: user_id).today

      # Get most common language per project using ActiveRecord
      most_common_languages = user_heartbeats
        .group(:project, :language)
        .count
        .group_by { |k, _| k[0] }  # Group by project
        .transform_values { |langs| langs.max_by { |_, count| count }&.first&.last } # Get most common language

      # Get all project durations in one query
      project_durations = user_heartbeats
        .group(:project)
        .duration_seconds

      projects = project_durations.map do |project, duration|
        print "project: #{project}, duration: #{duration}, language: #{most_common_languages[project]}"
        {
          name: project,
          duration: duration,
          language: most_common_languages[project],
          language_emoji: self.language_emoji(most_common_languages[project])
        }
      end

      projects = projects.filter { |project| project[:duration] > 1.minute }.sort_by { |project| -project[:duration] }

      {
        user_id: user_id,
        duration: user_durations[user_id],
        projects: projects
      }
    end
  end

  def self.language_emoji(language)
    language = language.downcase
    case language
    when "ruby"
      ":#{language}:"
    when "javascript"
      ":js:"
    when "typescript"
      ":ts:"
    when "html"
      ":#{language}:"
    when "java"
      [ ":java:", ":java_duke:" ].sample
    when "unity"
      [ ":unity:", ":unity_new:" ].sample
    when "c++"
      ":#{language}:"
    when "c"
      [ ":c:", ":c_1:" ].sample
    when "rust"
      [ ":ferris:", ":crab:", ":ferrisowo:" ].sample
    when "python"
      [ ":snake:", ":python:", ":pf:", ":tw_snake:" ].sample
    when "nix"
      [ ":nix:", ":parrot-nix:" ].sample
    when "go"
      [ ":golang:", ":gopher:", ":gothonk:" ].sample
    when "kotlin"
      ":#{language}:"
    when "astro"
      ":#{language}:"
    else
      nil
    end
  end

  private

  def initialize_projects_summary
    return unless projects_summary.blank?
    Heartbeat.where(user_id: slack_uid).distinct.pluck(:project).each do |project|
      self.projects_summary[project] = Heartbeat.where(user_id: slack_uid, project: project).duration_seconds
    end
  end
end
