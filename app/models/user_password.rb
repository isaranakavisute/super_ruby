class UserPassword < PostgresRecord
  self.table_name = "user_password"

  # Returns the row whose myuser and mypassword match, or nil.
  # mypassword is stored as plain text, so compare in constant time to avoid leaking it through timing.
  def self.authenticate(username, password)
    return if username.blank? || password.blank?

    where(myuser: username.to_s.strip).find do |account|
      account.mypassword.present? && ActiveSupport::SecurityUtils.secure_compare(account.mypassword, password.to_s)
    end
  end
end
