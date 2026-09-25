ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require_relative "test_helpers/user_password_test_helper"
require_relative "test_helpers/product_test_helper"

module ActiveSupport
  class TestCase
    # Run in a single process. Parallel workers would each need their own copy of every database
    # (e.g. "postgres_5"), but the PostgreSQL database is external and not managed by Rails.
    # Forked workers using the pg gem can also hang on macOS.
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
