require "test_helper"

class ProductTest < ActiveSupport::TestCase
  setup { create_products_table }

  test "discount percent is rounded" do
    assert_equal 54, Product.find_by!(name: "Wireless Bluetooth Earbuds").discount_percent
  end

  test "no discount when not on sale" do
    assert_nil Product.find_by!(name: "Thai Jasmine Rice 5kg").discount_percent
  end

  test "original price must be higher than price" do
    product = Product.find_by!(name: "Wireless Bluetooth Earbuds")
    product.original_price = product.price

    assert_not product.valid?
  end

  test "search escapes LIKE wildcards" do
    assert_empty Product.search("%")
  end
end
