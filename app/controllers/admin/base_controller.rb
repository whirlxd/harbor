class Admin::BaseController < ApplicationController
  before_action :authenticate_admin!

  private

  def authenticate_admin!
    unless current_user && (current_user.admin_level == "admin" || current_user.admin_level == "superadmin")
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end
end
