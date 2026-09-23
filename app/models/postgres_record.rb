class PostgresRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { writing: :postgres }
end
