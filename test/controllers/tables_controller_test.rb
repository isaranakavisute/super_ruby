require "test_helper"

# Reads the table list of the PostgreSQL database configured as "postgres" in config/database.yml (read-only)
class TablesControllerTest < ActionDispatch::IntegrationTest
  test "lists the tables in the postgres database" do
    get show_tables_url

    assert_response :success
    body = response.parsed_body
    assert_equal PostgresRecord.connection.current_database, body["database"]
    assert_equal body["tables"].size, body["count"]
    assert body["tables"].all? { |t| t.keys.sort == %w[name schema] }
    assert_empty body["tables"].select { |t| %w[pg_catalog information_schema].include?(t["schema"]) }
  end
end
