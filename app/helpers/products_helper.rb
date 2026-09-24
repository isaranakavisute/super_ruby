module ProductsHelper
  CATEGORY_ICONS = {
    "Electronics" => "📱", "Fashion" => "👕", "Home & Living" => "🛋️",
    "Beauty" => "💄", "Sports" => "⚽", "Groceries" => "🛒"
  }.freeze

  # 1290 => "฿1,290"
  def baht(amount)
    number_to_currency(amount, unit: "฿", precision: 0)
  end

  # 12500 => "12.5k"
  def sold_count(count)
    count >= 1000 ? "#{number_with_precision(count / 1000.0, precision: 1, strip_insignificant_zeros: true)}k" : count.to_s
  end
end
