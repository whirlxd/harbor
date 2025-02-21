class User < ApplicationRecord
  has_paper_trail

  validates :email, presence: true, uniqueness: true
  validates :slack_uid, presence: true, uniqueness: true
  validates :username, presence: true

  has_many :heartbeats,
    foreign_key: :user_id,
    primary_key: :slack_uid,
    class_name: "Heartbeat"

  has_many :projects,
    foreign_key: :user_id,
    primary_key: :slack_uid,
    class_name: "Project"

  def admin?
    is_admin
  end

  def make_admin!
    update!(is_admin: true)
  end

  def remove_admin!
    update!(is_admin: false)
  end

  def self.authorize_url(redirect_uri)
    params = {
      client_id: ENV["SLACK_CLIENT_ID"],
      # scope: "identity.basic,identity.email",
      redirect_uri: redirect_uri,
      state: SecureRandom.hex(24),
      user_scope: "identity.basic,identity.email,identity.avatar"
    }

    URI.parse("https://slack.com/oauth/v2/authorize?#{params.to_query}")
  end

  def self.from_slack_token(code, redirect_uri)
    # Exchange code for token
    response = HTTP.post("https://slack.com/api/oauth.v2.access", form: {
      client_id: ENV["SLACK_CLIENT_ID"],
      client_secret: ENV["SLACK_CLIENT_SECRET"],
      code: code,
      redirect_uri: redirect_uri
    })

    data = JSON.parse(response.body.to_s)

    return nil unless data["ok"]

    # Get user info
    user_response = HTTP.auth("Bearer #{data['authed_user']['access_token']}")
      .get("https://slack.com/api/users.identity")

    user_data = JSON.parse(user_response.body.to_s)

    return nil unless user_data["ok"]

    user = find_or_initialize_by(slack_uid: user_data["user"]["id"])
    user.email = user_data["user"]["email"]
    user.username = user_data["user"]["name"]
    user.avatar_url = user_data["user"]["image_192"] || user_data["user"]["image_72"]
    user.save!
    user
  rescue => e
    Rails.logger.error "Error creating user from Slack data: #{e.message}"
    nil
  end

  def project_names
    heartbeats.select(:project).distinct.pluck(:project)
  end

  def active_project
    heartbeats.order(time: :desc).first&.project
  end

  def active_project_duration
    return nil unless active_project

    Heartbeat.duration_formatted(heartbeats.where(project: active_project))
  end
end
