module StaffTestHelper
  # The test database (mydb) has no staff table, so create a temporary one with the same columns
  # and constraints the staff API relies on. It is dropped automatically when the test's transaction
  # is rolled back. (The original table's email is citext; text is enough for these tests.)
  def create_staff_table
    PostgresRecord.connection.execute(<<~SQL)
      CREATE TEMP TABLE staff (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        staff_ref text CONSTRAINT staff_staff_ref_key UNIQUE, title text, forename text, middle_names text,
        surname text, full_name text NOT NULL, initials text,
        gender text CONSTRAINT staff_gender_check CHECK (gender IN ('M', 'F')),
        date_of_birth date, email text CONSTRAINT staff_email_key UNIQUE,
        is_teacher boolean NOT NULL DEFAULT true, active boolean NOT NULL DEFAULT true,
        created_at timestamptz NOT NULL DEFAULT now(), nickname text,
        divisions text[] NOT NULL DEFAULT '{}', job_title text, phone text, extension text, room text,
        email_verified boolean NOT NULL DEFAULT false, birthday text,
        provisional boolean NOT NULL DEFAULT false, created_by uuid, house_code text
      ) ON COMMIT DROP;
      INSERT INTO staff (full_name, email) VALUES ('Existing Teacher', 'existing@example.test');
    SQL
    Staff.reset_column_information
  end
end

ActiveSupport.on_load(:active_support_test_case) { include StaffTestHelper }
