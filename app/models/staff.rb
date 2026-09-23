class Staff < PostgresRecord
  self.table_name = "staff"

  # Mirror the table's NOT NULL / CHECK constraints so bad input gets a clear error message
  validates :full_name, presence: true
  validates :gender, inclusion: { in: %w[M F] }, allow_nil: true
end
