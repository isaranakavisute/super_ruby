require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup { create_products_table }

  test "shop requires login" do
    get root_path

    assert_redirected_to login_path
  end

  test "shop lists products with prices, discounts and flash sale" do
    sign_in_as users(:admin)

    get root_path

    assert_response :success
    assert_select "header", /admin/
    assert_select "article", minimum: Product.count
    assert_select "article", /Wireless Bluetooth Earbuds/
    assert_select "article", /฿599/
    assert_select "article", /-54%/
    assert_select "h2", /FLASH SALE/
  end

  test "search filters products by name" do
    sign_in_as users(:admin)

    get root_path(q: "rice")

    assert_select "article", count: 1
    assert_select "article", /Thai Jasmine Rice/
    assert_select "h2", text: /FLASH SALE/, count: 0
  end

  test "category filters products" do
    sign_in_as users(:admin)

    get root_path(category: "Fashion")

    assert_select "article", count: 1
    assert_select "article", /T-Shirt/
  end

  test "no results message" do
    sign_in_as users(:admin)

    get root_path(q: "does-not-exist")

    assert_select "article", count: 0
    assert_select "p", /No products found/
  end
end
