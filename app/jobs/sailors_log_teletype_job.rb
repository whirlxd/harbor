class SailorsLogTeletypeJob < ApplicationJob
  queue_as :default

  def perform(message)
    HTTP.auth("Bearer #{ENV['TELETYPE_API_KEY']}")
      .post("https://printer.schmitworks.dev/api/raw",
            body: message)
  end
end
