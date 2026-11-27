class PrepareUsersForAuthentication < ActiveRecord::Migration[8.1]
  # 1. has_secure_password (bcrypt) stores its hash in a column named password_digest.
  #    Existing rows hold plain placeholder text, not bcrypt hashes, so those users must be
  #    re-created / re-seeded (the login service treats them as "invalid credentials").
  # 2. Emails are the login name: they must be unique, ignoring upper/lower case.
  #    (This fails if two existing users share an email, ignoring case.)
  def change
    rename_column :users, :password_hash, :password_digest
    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"
  end
end
