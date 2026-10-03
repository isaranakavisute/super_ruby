# Two-factor authentication is now required for everyone. Sessions started before this only
# checked the password, so sign everyone out once; they sign in again with 2FA.
class SignOutSessionsWithoutTwoFactor < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM sessions"
  end

  def down
    # Deleted sessions can't be restored; users simply sign in again
  end
end
