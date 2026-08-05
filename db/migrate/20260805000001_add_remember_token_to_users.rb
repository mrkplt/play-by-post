# typed: false

# `remember_token` is the per-user secret behind two things:
#   1. `User#authenticatable_salt` (session validation / revocation), and
#   2. Devise `:rememberable`'s cookie value.
# The passwordless model has no encrypted_password, so `authenticatable_salt`
# was nil and both mechanisms were inert. Every user needs a token, so existing
# rows are backfilled. Introducing a non-nil salt invalidates any session cookie
# signed against the old nil salt — a one-time re-login on deploy (see
# REQUIREMENTS "Sessions").
class AddRememberTokenToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :remember_token, :string

    # Backfill before adding the unique index so no NULLs collide.
    say_with_time "Backfilling remember_token for existing users" do
      User.reset_column_information
      User.where(remember_token: nil).find_each do |user|
        user.update_column(:remember_token, Devise.friendly_token)
      end
    end

    add_index :users, :remember_token, unique: true
  end

  def down
    remove_column :users, :remember_token
  end
end
