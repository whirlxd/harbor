module Api
  module Admin
    module V1
      class UsersController < Api::Admin::V1::ApplicationController
        def index
          users = User.includes(:email_addresses, :api_keys)
                     .order(created_at: :desc)
                     .limit(params[:limit]&.to_i || 50)

          if params[:admin_only] == "true"
            users = users.where(admin: true)
          end

          render json: {
            users: users.map do |user|
              {
                id: user.id,
                username: user.username,
                display_name: user.display_name,
                slack_uid: user.slack_uid,
                github_username: user.github_username,
                admin: user.admin?,
                superadmin: user.superadmin?,
                trust_level: user.trust_level,
                timezone: user.timezone,
                created_at: user.created_at,
                last_heartbeat_at: user.heartbeats.maximum(:time),
                api_keys_count: user.api_keys.count,
                total_heartbeats: user.heartbeats.count
              }
            end,
            meta: {
              total_count: users.count,
              limit: params[:limit]&.to_i || 50
            }
          }
        end

        def show
          user = User.find(params[:id])

          render json: {
            user: {
              id: user.id,
              username: user.username,
              display_name: user.display_name,
              slack_uid: user.slack_uid,
              slack_username: user.slack_username,
              github_username: user.github_username,
              admin: user.admin?,
              superadmin: user.superadmin?,
              trust_level: user.trust_level,
              timezone: user.timezone,
              country_code: user.country_code,
              created_at: user.created_at,
              updated_at: user.updated_at,
              last_heartbeat_at: user.heartbeats.maximum(:time),
              api_keys: user.api_keys.map do |key|
                {
                  id: key.id,
                  name: key.name,
                  token_preview: "#{key.token[0..8]}...",
                  created_at: key.created_at
                }
              end,
              email_addresses: user.email_addresses.map(&:email),
              stats: {
                total_heartbeats: user.heartbeats.count,
                total_coding_time: user.heartbeats.sum(:duration) || 0,
                languages_used: user.heartbeats.distinct.pluck(:language).compact.count,
                projects_worked_on: user.heartbeats.distinct.pluck(:project).compact.count,
                days_active: user.heartbeats.distinct.pluck(:date).compact.count
              }
            }
          }
        rescue ActiveRecord::RecordNotFound
          render json: { error: "who tf is that lmao" }, status: :not_found
        end

        def update_trust_level
          user = User.find(params[:id])
          trust_level = params[:trust_level]
          reason = params[:reason] || "updated via the api"
          notes = params[:notes]

          unless User.trust_levels.key?(trust_level)
            return render json: { error: "tf is that lmao" }, status: :unprocessable_entity
          end

          if trust_level == "red" && !current_user.can_convict_users?
            return render json: { error: "you dont got perms for that lmao" }, status: :forbidden
          end

          success = user.set_trust(
            trust_level,
            changed_by_user: current_user,
            reason: reason,
            notes: notes
          )

          if success
            render json: {
              success: true,
              message: "okay, gotcha, that user is now #{trust_level}",
              user: {
                id: user.id,
                trust_level: user.trust_level,
                updated_at: user.updated_at
              }
            }
          else
            render json: { error: "whomp that didnt work" }, status: :unprocessable_entity
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: "who tf is that lmao" }, status: :not_found
        end
      end
    end
  end
end
