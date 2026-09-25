class AdminController < ApplicationController
  # Signed-in users only (the default), and only the admin
  before_action :require_admin

  # The page itself is static; admin_users_controller.js fills in the table from GET /user
  def index
  end

  private
    def require_admin
      redirect_to root_path, alert: "Only the admin can open the Admin Panel." unless Current.user.admin?
    end
end
