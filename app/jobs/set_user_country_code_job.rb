class SetUserCountryCodeJob < ApplicationJob
  queue_as :literally_whenever

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user
    return if user.country_code.present?

    # Get unique IPs from user's heartbeats
    ips = user.heartbeats.where.not(ip_address: nil).distinct.pluck(:ip_address)
    return if ips.empty?

    # Try each IP until we get a valid country code
    ips.each do |ip|
      begin
        puts "Getting country code for IP #{ip}"
        response = HTTP.get("https://ip.hackclub.com/ip/#{ip}")
        next unless response.status.success?

        data = JSON.parse(response.body.to_s)
        puts "Data: #{data}"
        country_code = data.dig("country_iso_code")
        next unless country_code.present?

        # Update user's country code if it's valid
        if ISO3166::Country.codes.include?(country_code)
          user.update!(country_code: country_code)
          return
        end
      rescue => e
        Rails.logger.error "Error getting country code for IP #{ip}: #{e.message}"
        next
      end
    end
  end
end
