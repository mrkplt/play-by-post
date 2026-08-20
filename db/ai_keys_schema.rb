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

ActiveRecord::Schema[8.1].define(version: 2026_08_20_203042) do
  create_table "ai_private_keys", force: :cascade do |t|
    t.bigint "ai_keypair_id", null: false
    t.datetime "created_at", null: false
    t.text "encrypted_private_key", null: false
    t.datetime "updated_at", null: false
    t.index ["ai_keypair_id"], name: "index_ai_private_keys_on_ai_keypair_id", unique: true
  end
end
