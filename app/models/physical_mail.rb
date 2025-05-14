class PhysicalMail < ApplicationRecord
  belongs_to :user

  scope :going_out, -> { where(status: :pending).or(where(status: :sent)) }

  enum :status, {
    pending: 0,
    sent: 1,
    failed: 2
  }

  enum :mission_type, {
    hackatime_first_time_7_streak: 0
  }

  def deliver!
    slug = "hackatime_#{mission_type.to_s.underscore.gsub("_", "-")}"

    flavors = FlavorText.compliment
    flavors.concat(FlavorText.rare_compliment) if rand(10) == 0

    # authorization: Bearer <token>
    response = HTTP.auth("Bearer #{ENV["MAIL_HACKCLUB_TOKEN"]}").post("https://mail.hackclub.com/api/v1/letter_queues/#{slug}", json: {
      recipient_email: user.email,
      address: user_address,
      rubber_stamps: flavors.sample,
      idempotency_key: "physical_mail_#{id}",
      metadata: {
        attributes: attributes
      }
    })

    if response.status.success?
      update(status: :sent)
    else
      update(status: :failed)
      raise "Failed to deliver physical mail: #{response.body}"
    end
  rescue => e
    update(status: :failed)
    raise e
  end

  private

  def user_address
    user.address
  end
end
