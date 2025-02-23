class SailorsLogSetNotificationPrefJob < ApplicationJob
  queue_as :default

  def perform(slack_uid, slack_channel_id, enabled)
    slnp = SailorsLogNotificationPreference.find_or_initialize_by(slack_uid: slack_uid, slack_channel_id: slack_channel_id)
    slnp.enabled = enabled
    slnp.save!
  end
end
