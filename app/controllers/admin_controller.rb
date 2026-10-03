class AdminController < ApplicationController
  RESET_PASSWORD = "123456"

  # Signed-in users only (the default), and only the admin
  before_action :require_admin

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "User not found" }, status: :not_found
  end

  rescue_from ActiveRecord::ConnectionNotEstablished do |e|
    render json: { error: "Could not connect to PostgreSQL: #{e.message}" }, status: :service_unavailable
  end

  # USER screen. The page itself is static; admin_users_controller.js fills in the table from GET /user
  def index
  end

  # PRODUCT screen: every column and row of the products table (PostgreSQL)
  def products
    @columns = Product.column_names
    @products = Product.order(:id).to_a
  rescue ActiveRecord::ConnectionNotEstablished => e
    @columns, @products = [], []
    @error = "Could not connect to PostgreSQL: #{e.message}"
    render :products, status: :service_unavailable
  end

  # POST /admin/users/:id/reset_password: sets that one user's mypassword to RESET_PASSWORD
  def reset_password
    account = UserPassword.find(params[:id])
    # Only this column changes; skip the registration rules so accounts created before them
    # (e.g. with a username those rules would not allow) can still be reset.
    account.update_columns(mypassword: RESET_PASSWORD)
    PasswordResetRequest.resolve_for(account.myuser)

    render json: account.slice(:id, :myuser, :mypassword)
  end

  # POST /admin/users/:id/reset_two_factor: for a user who lost their phone. Their authenticator
  # app entry stops working, and they set up 2FA again at their next sign-in.
  def reset_two_factor
    account = UserPassword.find(params[:id])
    account.reset_two_factor!

    render json: account.slice(:id, :myuser, :mypassword)
  end

  # PATCH /admin/users/:id: saves the username and password edited in the Admin Panel's edit dialog
  def update_user
    account = UserPassword.find(params[:id])

    # Renaming the admin account would lock the admin out, and let someone else register as "admin"
    if account.myuser == User::ADMIN_USERNAME && params[:myuser].to_s.strip != account.myuser
      return render json: { errors: { myuser: [ "The admin account cannot be renamed" ] } }, status: :unprocessable_content
    end

    if account.update(params.permit(:myuser, :mypassword))
      PasswordResetRequest.resolve_for(account.myuser_before_last_save) if account.saved_change_to_mypassword?
      render json: account.slice(:id, :myuser, :mypassword)
    else
      render json: { errors: account.errors.to_hash(true) }, status: :unprocessable_content
    end
  end

  # REQUESTS screen: "Forgot password" requests waiting for the admin, oldest first
  def reset_requests
    @requests = PasswordResetRequest.pending.order(:created_at)
  end

  # POST /admin/reset_requests/:id/resolve: resets that user's password to RESET_PASSWORD
  def resolve_reset_request
    reset_request = PasswordResetRequest.pending.find_by(id: params[:id])
    return redirect_to admin_reset_requests_path, alert: "That request has already been handled." unless reset_request

    if account = UserPassword.find_by(myuser: reset_request.username)
      account.update_columns(mypassword: RESET_PASSWORD)
      PasswordResetRequest.resolve_for(account.myuser)
      redirect_to admin_reset_requests_path, notice: "Password for #{account.myuser} has been reset to #{RESET_PASSWORD}. Please let them know."
    else
      redirect_to admin_reset_requests_path, alert: "There is no account named #{reset_request.username} any more. You can dismiss this request."
    end
  rescue ActiveRecord::ConnectionNotEstablished => e
    redirect_to admin_reset_requests_path, alert: "Could not connect to PostgreSQL: #{e.message}"
  end

  # DELETE /admin/reset_requests/:id: closes the request without changing the password
  def dismiss_reset_request
    PasswordResetRequest.pending.find_by(id: params[:id])&.resolve!
    redirect_to admin_reset_requests_path, notice: "Request dismissed.", status: :see_other
  end

  private
    def require_admin
      return if Current.user.admin?

      respond_to do |format|
        format.html { redirect_to root_path, alert: "Only the admin can open the Admin Panel." }
        format.json { render json: { error: "Only the admin can do this" }, status: :forbidden }
      end
    end
end
