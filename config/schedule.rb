every 1.hour do
  runner "UpdateLeaderboardJob.perform_later"
end
