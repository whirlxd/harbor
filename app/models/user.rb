class User < ApplicationRecord
  has_paper_trail
  encrypts :slack_access_token

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

  def update_slack_status
    return unless uses_slack_status?

    current_project = heartbeats.order(time: :desc).first&.project
    current_project_heartbeats = heartbeats.today.where(project: current_project)
    current_project_duration = Heartbeat.duration_seconds(current_project_heartbeats)
    current_project_duration_formatted = Heartbeat.duration_simple(current_project_heartbeats)

    status_emoji =
      case current_project_duration
      when 0...30.minutes
        %w[thinking cat-on-the-laptop loading-tumbleweed rac-yap]
      when 30.minutes...1.hour
        %w[working-parrot meow_code]
      when 1.hour...2.hours
        %w[working-parrot meow-code]
      when 2.hours...3.hours
        %w[working-parrot cat-typing bangbang]
      when 3.hours...5.hours
        %w[cat-typing meow-code laptop-fire bangbang]
      when 5.hours...8.hours
        %w[cat-typing laptop-fire hole-mantelpiece_clock keyboard-fire bangbang bangbang]
      when 8.hours...15.hours
        %w[laptop-fire bangbang bangbang rac_freaking rac_freakinghole-mantelpiece_clock]
      when 15.hours...20.hours
        %w[bangbang bangbang rac_freaking hole-mantelpiece_clock]
      else
        %w[areyousure time-to-stop]
      end.sample

    status_emoji = ":#{status_emoji}:"
    status_text = "#{current_project_duration_formatted} spent on #{current_project} today"

    # Update the user's status
    HTTP.auth("Bearer #{slack_access_token}")
      .post("https://slack.com/api/users.profile.set", form: {
        profile: {
          status_text:,
          status_emoji:
        }
      })
  end

  def self.authorize_url(redirect_uri)
    params = {
      client_id: ENV["SLACK_CLIENT_ID"],
      redirect_uri: redirect_uri,
      state: SecureRandom.hex(24),
      user_scope: "users.profile:read,users.profile:write"
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
    puts "data: #{data}"

    return nil unless data["ok"]

    # Get user info
    user_response = HTTP.auth("Bearer #{data['authed_user']['access_token']}")
      .get("https://slack.com/api/users.identity")

    user_data = JSON.parse(user_response.body.to_s)

    puts "user_data: #{user_data}"

    return nil unless user_data["ok"]

    user = find_or_initialize_by(slack_uid: user_data["user"]["id"])
    user.email = user_data["user"]["email"]
    user.username = user_data["user"]["name"]
    user.avatar_url = user_data["user"]["image_192"] || user_data["user"]["image_72"]
    # Store the OAuth data
    user.slack_access_token = data["authed_user"]["access_token"]
    user.slack_scopes = data["authed_user"]["scope"]&.split(/,\s*/)
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
