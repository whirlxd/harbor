module Api
  module Admin
    module V1
      class StatsController < Api::Admin::V1::ApplicationController
        def index
          render json: {
            platform_stats: {
              total_users: User.count,
              admin_users: User.where(admin: true).count,
              active_users_last_7_days: User.joins(:heartbeats)
                                           .where(heartbeats: { time: 7.days.ago.. })
                                           .distinct.count,
              active_users_last_30_days: User.joins(:heartbeats)
                                            .where(heartbeats: { time: 30.days.ago.. })
                                            .distinct.count,
              total_heartbeats: Heartbeat.count,
              heartbeats_last_7_days: Heartbeat.where(time: 7.days.ago..).count,
              heartbeats_last_30_days: Heartbeat.where(time: 30.days.ago..).count,
              total_api_keys: ApiKey.count,
              total_admin_api_keys: AdminApiKey.active.count,
              trust_levels: User.group(:trust_level).count
            },
            generated_at: Time.current
          }
        end

        def heartbeats
          limit = [ params[:limit]&.to_i || 100, 1000 ].min
          offset = params[:offset]&.to_i || 0

          heartbeats = Heartbeat.includes(:user)
                              .order(time: :desc)
                              .limit(limit)
                              .offset(offset)

          if params[:user_id].present?
            heartbeats = heartbeats.where(user_id: params[:user_id])
          end

          if params[:from].present?
            heartbeats = heartbeats.where("time >= ?", Time.parse(params[:from]))
          end

          if params[:to].present?
            heartbeats = heartbeats.where("time <= ?", Time.parse(params[:to]))
          end

          render json: {
            heartbeats: heartbeats.map do |hb|
              {
                id: hb.id,
                user_id: hb.user_id,
                user_display_name: hb.user&.display_name,
                time: hb.time,
                project: hb.project,
                language: hb.language,
                entity: hb.entity,
                duration: hb.duration,
                is_debugging: hb.is_debugging
              }
            end,
            meta: {
              limit: limit,
              offset: offset,
              total_count: heartbeats.count
            }
          }
        rescue ArgumentError => e
          render json: { error: "tf is that date buddy #{e.message}" }, status: :bad_request
        end
      end
    end
  end
end
