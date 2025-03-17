class HandleEmailSigninJob < ApplicationJob
  queue_as :default

  def perform(email)
    email_address = ActiveRecord::Base.transaction do
      EmailAddress.find_by(email: email) || begin
        user = User.create!
        user.email_addresses.create!(email: email)
      end
    end

    LoopsMailer.sign_in_email(email_address).deliver_now
  end
end
