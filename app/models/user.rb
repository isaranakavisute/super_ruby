class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :username, with: ->(u) { u.strip.downcase }

  validates :username, uniqueness: true, allow_nil: true

  # Local record that login sessions belong to, for a user who signed in with their
  # user_password (PostgreSQL) account. Passwords are checked against user_password, not here,
  # so the local password is random and never used.
  def self.for_user_password(account)
    find_or_create_by!(username: account.myuser) do |user|
      user.email_address = "user-password-#{account.id}@mydb.invalid"
      user.password = SecureRandom.base58(24)
    end
  end
end
