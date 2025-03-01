class SlackCommand::TimedumpJob < ApplicationJob
  def perform(params)
    puts "Timedump: #{params}"
    slack_uid = params[:user_id]
    # get email from user profile
    user_profile = HTTP.get("https://slack.com/api/users.profile.get?user=#{slack_uid}")
    email = JSON.parse(user_profile.body)["profile"]["email"]
    # find or create user in wakatime
    wakatime_user = WakatimeUser.find_by(email: email)


    HTTP.post(params[:response_url], json: {
      response_type: "ephemeral",
      text: "Timedump: #{wakatime_user.to_json}"
    })
  end
end
