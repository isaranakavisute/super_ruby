# Account page for the signed-in user: connect or disconnect Google / Facebook sign-in
class AccountsController < ApplicationController
  before_action :set_account

  def show
    @identities = @account.identities.order(:provider).index_by(&:provider)
  end

  # DELETE /account/connections/:id
  def disconnect
    identity = @account.identities.find_by(id: params[:id])
    identity&.destroy
    redirect_to account_path, notice: (identity ? "#{identity.provider_label} has been disconnected." : nil), status: :see_other
  end

  private
    def set_account
      @account = Current.user.user_password_account
      redirect_to root_path, alert: "Your account could not be found." unless @account
    end
end
