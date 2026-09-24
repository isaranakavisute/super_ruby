class ProductsController < ApplicationController
  # Shop home page (requires login, like every page by default)
  def index
    @category = params[:category].presence_in(Product::CATEGORIES)
    @query = params[:q].to_s.strip

    @flash_sale = Product.on_sale.order(Arel.sql("(original_price - price) * 1.0 / original_price DESC")).limit(6)

    @products = Product.search(@query).order(sold_count: :desc)
    @products = @products.where(category: @category) if @category
  end
end
