Rails.application.configure do
  config.good_job.preserve_job_records = true
  config.good_job.enable_cron = true
  config.good_job.execution_mode = :async

  config.good_job.cron = {
    update_slack_status: {
      cron: "*/15 * * * *",
      class: "UserSlackStatusUpdateJob"
    },
    leaderboard_update: {
      cron: "*/5 * * * *",
      class: "LeaderboardUpdateJob"
    }
  }
end
