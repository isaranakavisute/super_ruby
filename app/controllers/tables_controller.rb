class TablesController < ApplicationController
  # Public JSON API used by Postman and other non-browser clients, so no login is required
  allow_unauthenticated_access

  def index
    connection = PostgresRecord.connection
    rows = connection.select_rows(<<~SQL)
      SELECT table_schema, table_name
      FROM information_schema.tables
      WHERE table_type = 'BASE TABLE'
        AND table_schema NOT IN ('pg_catalog', 'information_schema')
      ORDER BY table_schema, table_name
    SQL

    render json: {
      database: connection.current_database,
      count: rows.size,
      tables: rows.map { |schema, name| { schema: schema, name: name } }
    }
  rescue ActiveRecord::ConnectionNotEstablished => e
    render json: { error: "Could not connect to PostgreSQL: #{e.message}" }, status: :service_unavailable
  end
end
