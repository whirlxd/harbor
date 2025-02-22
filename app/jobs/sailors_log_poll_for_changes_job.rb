class SailorsLogPollForChangesJob < ApplicationJob
  queue_as :default

  def perform
    # Get all users with enabled preferences
    slack_ids = SailorsLogNotificationPreference.where(enabled: true).distinct.pluck(:slack_uid)

    # for each user, check if their logs have changed
    logs = SailorsLog.where(slack_uid: slack_ids).includes(:notification_preferences)
    logs.each do |log|
      # get all projects for the user
      projects = Heartbeat.today.where(user_id: log.slack_uid).distinct.pluck(:project)

      new_notification = []

      projects.each do |project|
        new_project_time = Heartbeat.where(user_id: log.slack_uid, project: project).duration_seconds
        if new_project_time > (log.projects_summary[project] || 0) + 1.hour
          # create a new SailorsLogSlackNotification
          log.notification_preferences.each do |preference|
            log.notifications << SailorsLogSlackNotification.new(
              slack_uid: log.slack_uid,
              slack_channel_id: preference.slack_channel_id,
              project_name: project,
              project_duration: new_project_time
            )
          end
          log.projects_summary[project] = new_project_time
        end
      end
      ActiveRecord::Base.transaction do
        log.save! if log.changed?
      end
    end
  end
end
