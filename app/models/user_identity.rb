# A Google or Facebook account linked to a user_password account, stored in PostgreSQL
# (table created by db/postgres/user_identities.sql).
class UserIdentity < PostgresRecord
  belongs_to :user_password

  validates :provider, inclusion: { in: SocialLogin::PROVIDERS.keys }
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :provider, uniqueness: { scope: :user_password_id, message: "is already connected to this account" }

  def provider_label
    SocialLogin.label(provider)
  end
end
