# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_01_000003) do
  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message_checksum", null: false
    t.string "message_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "character_versions", force: :cascade do |t|
    t.integer "character_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "edited_by_id", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_character_versions_on_character_id"
    t.index ["edited_by_id"], name: "index_character_versions_on_edited_by_id"
  end

  create_table "characters", force: :cascade do |t|
    t.datetime "archived_at"
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.boolean "hidden", default: false, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["game_id"], name: "index_characters_on_game_id"
    t.index ["user_id"], name: "index_characters_on_user_id"
  end

  create_table "game_files", force: :cascade do |t|
    t.integer "byte_size"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename"
    t.integer "game_id", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_game_files_on_game_id"
  end

  create_table "game_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.string "role", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["game_id", "user_id"], name: "index_game_members_on_game_id_and_user_id", unique: true
    t.index ["game_id"], name: "index_game_members_on_game_id"
    t.index ["user_id"], name: "index_game_members_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "images_disabled", default: false, null: false
    t.string "name", null: false
    t.integer "post_edit_window_minutes"
    t.boolean "sheets_hidden", default: false, null: false
    t.datetime "updated_at", null: false
  end

  create_table "invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.integer "game_id", null: false
    t.integer "invited_by_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_invitations_on_game_id"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "muted", default: false, null: false
    t.integer "scene_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["scene_id", "user_id"], name: "index_notification_preferences_on_scene_id_and_user_id", unique: true
    t.index ["scene_id"], name: "index_notification_preferences_on_scene_id"
    t.index ["user_id"], name: "index_notification_preferences_on_user_id"
  end

  create_table "post_reads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "post_id", null: false
    t.datetime "read_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["post_id", "user_id"], name: "index_post_reads_on_post_id_and_user_id", unique: true
    t.index ["post_id"], name: "index_post_reads_on_post_id"
    t.index ["user_id"], name: "index_post_reads_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.boolean "draft", default: false, null: false
    t.boolean "is_ooc", default: false, null: false
    t.datetime "last_edited_at"
    t.integer "scene_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["scene_id"], name: "index_posts_on_scene_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "scene_participants", force: :cascade do |t|
    t.integer "character_id"
    t.datetime "created_at", null: false
    t.datetime "last_visited_at"
    t.integer "scene_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["character_id"], name: "index_scene_participants_on_character_id"
    t.index ["scene_id", "user_id"], name: "index_scene_participants_on_scene_id_and_user_id", unique: true
    t.index ["scene_id"], name: "index_scene_participants_on_scene_id"
    t.index ["user_id"], name: "index_scene_participants_on_user_id"
  end

  create_table "scenes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "game_id", null: false
    t.integer "parent_scene_id"
    t.boolean "private", default: false, null: false
    t.text "resolution"
    t.datetime "resolved_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_scenes_on_game_id"
    t.index ["parent_scene_id"], name: "index_scenes_on_parent_scene_id"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name"
    t.boolean "hide_ooc", default: false, null: false
    t.datetime "last_login_at"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "magic_link_token"
    t.datetime "magic_link_token_sent_at"
    t.datetime "remember_created_at"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["magic_link_token"], name: "index_users_on_magic_link_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "character_versions", "characters"
  add_foreign_key "character_versions", "users", column: "edited_by_id"
  add_foreign_key "characters", "games"
  add_foreign_key "characters", "users"
  add_foreign_key "game_files", "games"
  add_foreign_key "game_members", "games"
  add_foreign_key "game_members", "users"
  add_foreign_key "invitations", "games"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "post_reads", "posts"
  add_foreign_key "post_reads", "users"
  add_foreign_key "notification_preferences", "scenes"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "posts", "scenes"
  add_foreign_key "posts", "users"
  add_foreign_key "scene_participants", "characters"
  add_foreign_key "scene_participants", "scenes"
  add_foreign_key "scene_participants", "users"
  add_foreign_key "scenes", "games"
  add_foreign_key "scenes", "scenes", column: "parent_scene_id"
  add_foreign_key "user_profiles", "users"
end
