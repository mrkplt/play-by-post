class CreateUserProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :user_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :display_name
      t.datetime :last_login_at

      t.timestamps
    end
  end
end
