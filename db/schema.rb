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

ActiveRecord::Schema[8.1].define(version: 2026_10_14_180611) do
  create_table "status_transitions", force: :cascade do |t|
    t.integer "changed_by_id", null: false
    t.datetime "created_at", null: false
    t.integer "from_status", null: false
    t.text "note"
    t.integer "to_status", null: false
    t.datetime "updated_at", null: false
    t.integer "work_order_id", null: false
    t.index ["changed_by_id"], name: "index_status_transitions_on_changed_by_id"
    t.index ["work_order_id"], name: "index_status_transitions_on_work_order_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "phone"
    t.integer "role", default: 1, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "work_orders", force: :cascade do |t|
    t.string "asset_name", null: false
    t.string "asset_serial_number"
    t.integer "assigned_to_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "created_by_id", null: false
    t.string "customer_name", null: false
    t.text "description"
    t.datetime "due_at", null: false
    t.string "facility_location", null: false
    t.string "order_number", null: false
    t.integer "priority", default: 1, null: false
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_work_orders_on_assigned_to_id"
    t.index ["created_by_id"], name: "index_work_orders_on_created_by_id"
    t.index ["due_at"], name: "index_work_orders_on_due_at"
    t.index ["order_number"], name: "index_work_orders_on_order_number", unique: true
    t.index ["status"], name: "index_work_orders_on_status"
  end

  add_foreign_key "status_transitions", "users", column: "changed_by_id"
  add_foreign_key "status_transitions", "work_orders"
  add_foreign_key "work_orders", "users", column: "assigned_to_id"
  add_foreign_key "work_orders", "users", column: "created_by_id"
end
