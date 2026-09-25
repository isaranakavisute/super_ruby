class UserPassword < PostgresRecord
  self.table_name = "user_password"

  normalizes :myuser, with: ->(u) { u.strip }

  # Rules for new accounts created on the registration page
  validates :myuser, presence: true, length: { maximum: 50 },
                     format: { with: /\A[a-zA-Z0-9._-]+\z/, message: "can only contain letters, numbers, dots, dashes and underscores" },
                     uniqueness: { case_sensitive: false, message: "is already taken" }
  validates :mypassword, presence: true, length: { in: 6..72 }, confirmation: true
  validates :mypassword_confirmation, presence: true, on: :create

  # Returns the row whose myuser and mypassword match, or nil.
  # mypassword is stored as plain text, so compare in constant time to avoid leaking it through timing.
  def self.authenticate(username, password)
    return if username.blank? || password.blank?

    where(myuser: username.to_s.strip).find do |account|
      account.mypassword.present? && ActiveSupport::SecurityUtils.secure_compare(account.mypassword, password.to_s)
    end
  end
end
