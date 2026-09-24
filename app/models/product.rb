# Stored in the PostgreSQL database (table created by db/postgres/products.sql)
class Product < PostgresRecord
  CATEGORIES = [ "Electronics", "Fashion", "Home & Living", "Beauty", "Sports", "Groceries" ].freeze

  validates :name, presence: true, uniqueness: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :emoji, :location, presence: true
  validates :price, numericality: { only_integer: true, greater_than: 0 }
  validates :original_price, numericality: { only_integer: true, greater_than: :price }, allow_nil: true

  scope :on_sale, -> { where.not(original_price: nil) }

  def self.search(query)
    query.present? ? where("name ILIKE ?", "%#{sanitize_sql_like(query)}%") : all
  end

  # Percentage off the original price, e.g. 25 for "-25%"
  def discount_percent
    return unless original_price

    ((original_price - price) * 100.0 / original_price).round
  end
end
