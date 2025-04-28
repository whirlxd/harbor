module Api
  module V1
    class ExternalSlackController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :verify_stats_api_token

      def create_user
        token = params[:token]
        return render json: { error: "Token is required" }, status: :bad_request unless token.present?

        # First get user ID from auth.test
        auth_response = HTTP.auth("Bearer #{token}")
          .get("https://slack.com/api/auth.test")

        auth_data = JSON.parse(auth_response.body.to_s)
        puts "Auth data: #{auth_data}"
        return render json: { error: "Invalid Slack token" }, status: :unauthorized unless auth_data["ok"]

        user_id = auth_data["user_id"]
        return render json: { error: "User ID not found" }, status: :bad_request unless user_id.present?

        # Then get user info
        user_response = HTTP.auth("Bearer #{token}")
          .get("https://slack.com/api/users.info?user=#{user_id}")

        user_data = JSON.parse(user_response.body.to_s)
        puts "User data: #{user_data}"
        return render json: { error: "Invalid Slack token" }, status: :unauthorized unless user_data["ok"]

        email = user_data.dig("user", "profile", "email")
        return render json: { error: "Email not found" }, status: :bad_request unless email.present?

        # Find or create user
        email_address = EmailAddress.find_or_initialize_by(email: email)
        user = email_address.user
        user ||= begin
          u = User.find_or_initialize_by(slack_uid: user_id)
          u.email_addresses << email_address
          u
        end

        user.slack_uid = user_id
        user.username ||= user_data.dig("user", "profile", "username")
        user.username ||= user_data.dig("user", "profile", "display_name_normalized")
        user.slack_username = user_data.dig("user", "profile", "username")
        user.slack_avatar_url = user_data.dig("user", "profile", "image_192") || user_data.dig("user", "profile", "image_72")
        user.slack_access_token = token
        # user.slack_scopes = auth_data["scopes"]

        # Set timezone from Slack
        user.parse_and_set_timezone(user_data.dig("user", "tz"))

        if user.save
          render json: {
            user_id: user.id,
            username: user.username,
            email: email
          }, status: :created
        else
          render json: { error: user.errors.full_messages }, status: :unprocessable_entity
        end
      rescue => e
        Rails.logger.error "Error creating user from external Slack data: #{e.message}"
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      private

      def verify_stats_api_token
        token = request.headers["Authorization"]&.split(" ")&.last
        render json: { error: "Invalid API token" }, status: :unauthorized unless token == ENV["STATS_API_KEY"]
      end
    end
  end
end
