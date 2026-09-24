require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "discount percent is rounded" do
    assert_equal 54, products(:earbuds).discount_percent
  end

  test "no discount when not on sale" do
    assert_nil products(:rice).discount_percent
  end

  test "original price must be higher than price" do
    product = products(:earbuds)
    product.original_price = product.price

    assert_not product.valid?
  end

  test "search escapes LIKE wildcards" do
    assert_empty Product.search("%")
  end
end
