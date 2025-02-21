class UserSlackStatusUpdateJob < ApplicationJob
  queue_as :default

  def perform
    users = User.where(uses_slack_status: true)
    users.map(&:update_slack_status)
  end
end
