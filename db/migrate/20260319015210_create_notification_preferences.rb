class CreateNotificationPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_preferences do |t|
      t.references :scene, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :muted, null: false, default: false

      t.timestamps
    end

    add_index :notification_preferences, %i[scene_id user_id], unique: true
  end
end
