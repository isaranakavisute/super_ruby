# A user's "Forgot password" request. It stays pending until the admin resets that user's
# password or dismisses the request in the Admin Panel.
class PasswordResetRequest < ApplicationRecord
  normalizes :username, with: ->(u) { u.strip }

  validates :username, presence: true

  scope :pending, -> { where(resolved_at: nil) }

  # Records a request for username, unless one is already waiting
  def self.submit(username, ip_address:)
    pending.find_or_create_by!(username: username) { |request| request.ip_address = ip_address }
  end

  # Called when the admin resets username's password: its waiting requests are done
  def self.resolve_for(username)
    pending.where(username: username).update_all(resolved_at: Time.current, updated_at: Time.current)
  end

  def resolve!
    update!(resolved_at: Time.current)
  end
end
