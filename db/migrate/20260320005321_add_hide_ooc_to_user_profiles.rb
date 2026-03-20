class AddHideOocToUserProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :user_profiles, :hide_ooc, :boolean, null: false, default: false
  end
end
