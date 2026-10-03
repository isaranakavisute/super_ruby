# One CAPTCHA shown on the login page, stored in PostgreSQL (table created by db/postgres/login_captchas.sql).
# Each challenge can be checked only once, then it's deleted.
class LoginCaptcha < PostgresRecord
  # No look-alike characters (0/O, 1/I, and after distortion U/V, 2/Z), so every answer can be read correctly
  ALPHABET = "ABCDEFGHJKLMNPQRSTUWXY23456789".chars.freeze
  LENGTH = 5
  LIFETIME = 10.minutes

  # A new challenge with a random answer. Old expired challenges are cleaned up at the same time.
  def self.issue!
    where(expires_at: ...Time.current).delete_all
    create!(answer: Array.new(LENGTH) { ALPHABET.sample(random: SecureRandom) }.join, expires_at: LIFETIME.from_now)
  end

  # True if input matches challenge id's answer (not case-sensitive). The challenge is used up either way.
  def self.solve(id, input)
    captcha = find_by(id: id)
    return false unless captcha

    captcha.delete
    guess = input.to_s.gsub(/\s/, "").upcase
    captcha.expires_at.future? && guess.size == LENGTH && ActiveSupport::SecurityUtils.secure_compare(captcha.answer, guess)
  end

  def to_png
    CaptchaImage.new(answer).to_png
  end
end
