module My
  class MailroomController < ApplicationController
    def index
      @user = current_user
      @physical_mails = @user.physical_mails.order(created_at: :desc)
      @has_mailing_address = @user.mailing_address.present?
    end
  end
end
