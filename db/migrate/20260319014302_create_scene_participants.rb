class CreateSceneParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :scene_participants do |t|
      t.references :scene, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :last_visited_at

      t.timestamps
    end

    add_index :scene_participants, %i[scene_id user_id], unique: true
  end
end
