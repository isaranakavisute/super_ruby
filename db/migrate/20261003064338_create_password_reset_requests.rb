# "Forgot password" requests, shown to the admin in the Admin Panel (REQUESTS screen).
# username is user_password.myuser in PostgreSQL, a different database, so it is stored as text, not a foreign key.
class CreatePasswordResetRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :password_reset_requests do |t|
      t.string :username, null: false
      t.string :ip_address
      t.datetime :resolved_at

      t.timestamps
    end
    add_index :password_reset_requests, [ :username, :resolved_at ]
  end
end
