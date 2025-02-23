class SailorsLogLeaderboardJob < ApplicationJob
  queue_as :default
  include ApplicationHelper

  def perform(channel_id, response_url)
    # Generate leaderboard
    leaderboard = SailorsLog.generate_leaderboard(channel_id)
    message = "*:boat: Sailor's Log - Today*"
    medals = [ "first_place_medal", "second_place_medal", "third_place_medal" ]

    leaderboard.each_with_index do |entry, index|
      medal = medals[index] || "white_small_square"
      message += "\n:#{medal}: `<@#{entry[:user_id]}>`: #{short_time_simple entry[:duration]} → "
      message += entry[:projects].map do |project|
        language = project[:language_emoji] ? "#{project[:language_emoji]} #{project[:language]}" : project[:language]

        project_entry = []
        project_entry << "#{project[:name]}"
        project_entry << "[#{language}]" unless language.nil?
        project_entry << "#{short_time_simple project[:duration]}"
        project_entry.join(" ")
      end.join(" + ")
    end

    # Update with final message
    response = HTTP.post(response_url, json: {
      response_type: "in_channel",
      replace_original: true,
      text: message
    })

    puts "Response: #{response.body}"
  end
end
