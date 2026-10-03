class UserPassword < PostgresRecord
  self.table_name = "user_password"

  normalizes :myuser, with: ->(u) { u.strip }

  # Linked Google / Facebook accounts (deleted with the account by the database's ON DELETE CASCADE)
  has_many :identities, class_name: "UserIdentity", dependent: :delete_all

  # The user_password columns are varchar(30) in mydb
  USERNAME_MAX_LENGTH = 30

  # Rules for new accounts created on the registration page
  validates :myuser, presence: true, length: { maximum: 50 },
                     format: { with: /\A[a-zA-Z0-9._-]+\z/, message: "can only contain letters, numbers, dots, dashes and underscores" },
                     uniqueness: { case_sensitive: false, message: "is already taken" }
  validates :mypassword, presence: true, length: { in: 6..72 }, confirmation: true
  validates :mypassword_confirmation, presence: true, on: :create

  # Two-factor authentication (columns added by db/postgres/user_password_2fa.sql).
  # Codes follow the TOTP standard that Microsoft Authenticator uses: 6 digits, a new one every 30 seconds.
  OTP_ISSUER = "MyShop"
  RECOVERY_CODE_COUNT = 10

  # Stored encrypted, so reading the table (or an old copy of the /user API) doesn't reveal it
  encrypts :otp_secret

  def two_factor_enabled?
    otp_enabled_at.present? && otp_secret.present?
  end

  # otpauth:// link inside the setup QR code: "MyShop (bob)" in the authenticator app
  def self.otp_provisioning_uri(secret, username)
    ROTP::TOTP.new(secret, issuer: OTP_ISSUER).provisioning_uri(username)
  end

  # Phone and server clocks are rarely exactly in step, so the codes just before and just after the
  # current one are accepted too. Without drift_ahead, a phone a few seconds fast shows the next code
  # before the server reaches it, and a freshly appeared code is rejected.
  OTP_DRIFT = { drift_behind: 30, drift_ahead: 30 }.freeze

  # True if code is valid for secret right now (allowing for clock differences)
  def self.valid_otp?(secret, code)
    ROTP::TOTP.new(secret).verify(normalize_otp(code), **OTP_DRIFT).present?
  end

  def self.normalize_otp(code)
    code.to_s.gsub(/\s/, "")
  end

  # Turns on 2FA with a secret the user has just confirmed. Returns the recovery codes, shown once.
  def enable_two_factor!(secret)
    codes = Array.new(RECOVERY_CODE_COUNT) { SecureRandom.alphanumeric(10).downcase.insert(5, "-") }
    self.otp_secret = secret
    self.otp_enabled_at = Time.current
    self.otp_last_used_at = nil
    self.otp_recovery_digests = codes.map { |code| self.class.recovery_digest(code) }
    save!(validate: false) # only the 2FA columns change; don't re-check the registration rules
    codes
  end

  # Checks a 6-digit code from the authenticator app. Each code is accepted only once.
  def verify_otp(code)
    return false unless two_factor_enabled?

    used_at = ROTP::TOTP.new(otp_secret).verify(self.class.normalize_otp(code), **OTP_DRIFT, after: otp_last_used_at&.to_i)
    return false unless used_at

    update_column(:otp_last_used_at, Time.at(used_at))
    true
  end

  # True if code is a real code from the app that was already used (e.g. signing in twice within
  # 30 seconds), so the user can be told to wait for the next one rather than that it's wrong
  def otp_already_used?(code)
    two_factor_enabled? && otp_last_used_at.present? && self.class.valid_otp?(otp_secret, code)
  end

  # Checks a recovery code (e.g. "abcde-12345"). Each one works once, then is removed.
  def use_recovery_code(code)
    digest = self.class.recovery_digest(code)
    return false unless two_factor_enabled? && otp_recovery_digests.include?(digest)

    update_column(:otp_recovery_digests, otp_recovery_digests - [ digest ])
    true
  end

  def recovery_codes_left
    otp_recovery_digests.size
  end

  # Used by the admin when a user has lost their phone: they set up 2FA again at their next sign-in
  def reset_two_factor!
    update_columns(otp_secret: nil, otp_enabled_at: nil, otp_last_used_at: nil, otp_recovery_digests: [])
  end

  def self.recovery_digest(code)
    Digest::SHA256.hexdigest(code.to_s.strip.downcase)
  end

  # New account for someone signing in with Google / Facebook for the first time. The username comes
  # from their email (e.g. "somchai.k@gmail.com" => "somchai.k", or "somchai.k2" if taken). The password
  # is random and never shown: they sign in with Google / Facebook (or ask the admin for a reset).
  def self.create_for_social_login!(email:, name:)
    password = SecureRandom.alphanumeric(24)
    create!(myuser: available_username(email.to_s.split("@").first.presence || name),
            mypassword: password, mypassword_confirmation: password)
  end

  def self.available_username(wanted)
    base = wanted.to_s.downcase.gsub(/\s+/, ".").gsub(/[^a-z0-9._-]/, "").first(USERNAME_MAX_LENGTH - 4).presence || "user"
    candidates = [ base ] + (2..99).map { |n| "#{base}#{n}" }
    taken = where("LOWER(myuser) IN (?)", candidates).pluck(Arel.sql("LOWER(myuser)"))
    (candidates - taken).first || "#{base}#{SecureRandom.random_number(1000..9999)}"
  end

  # Returns the row whose myuser and mypassword match, or nil.
  # mypassword is stored as plain text, so compare in constant time to avoid leaking it through timing.
  def self.authenticate(username, password)
    return if username.blank? || password.blank?

    where(myuser: username.to_s.strip).find do |account|
      account.mypassword.present? && ActiveSupport::SecurityUtils.secure_compare(account.mypassword, password.to_s)
    end
  end
end
