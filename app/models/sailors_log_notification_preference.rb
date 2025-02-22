class SailorsLogNotificationPreference < ApplicationRecord
  belongs_to :sailors_log,
             class_name: "SailorsLog",
             foreign_key: :slack_uid,
             primary_key: :slack_uid
end
