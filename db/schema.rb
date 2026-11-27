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

ActiveRecord::Schema[8.1].define(version: 2026_11_27_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "address_line", null: false
    t.string "door_no", null: false
    t.string "street", null: false
    t.string "city", null: false
    t.string "state", null: false
    t.string "country", default: "India"
    t.boolean "is_default"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "latitude", precision: 10, scale: 6, null: false
    t.decimal "longitude", precision: 10, scale: 6, null: false
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "admins", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_admins_on_user_id"
  end

  create_table "booking_assignments", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "partner_id", null: false
    t.bigint "booking_offer_id", null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_booking_assignments_on_booking_id"
    t.index ["booking_offer_id"], name: "index_booking_assignments_on_booking_offer_id"
    t.index ["partner_id"], name: "index_booking_assignments_on_partner_id"
  end

  create_table "booking_offers", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "partner_id", null: false
    t.string "response", default: "pending"
    t.bigint "assigned_by_admin_id"
    t.string "source"
    t.datetime "offered_at"
    t.integer "search_radius_km"
    t.datetime "expires_at"
    t.datetime "responded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "booking_search_round_id"
    t.index ["assigned_by_admin_id"], name: "index_booking_offers_on_assigned_by_admin_id"
    t.index ["booking_id", "response"], name: "index_booking_offers_on_booking_id_and_response"
    t.index ["booking_id"], name: "index_booking_offers_on_booking_id"
    t.index ["booking_search_round_id"], name: "index_booking_offers_on_booking_search_round_id"
    t.index ["partner_id"], name: "index_booking_offers_on_partner_id"
  end

  create_table "booking_search_rounds", force: :cascade do |t|
    t.integer "radius_km"
    t.string "status"
    t.datetime "started_at"
    t.datetime "deadline_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "booking_id", null: false
    t.index ["booking_id"], name: "index_booking_search_rounds_on_booking_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "partner_id"
    t.bigint "service_category_id", null: false
    t.bigint "address_id", null: false
    t.datetime "scheduled_at", precision: nil, null: false
    t.integer "duration_mins", null: false
    t.string "description"
    t.string "assignment_mode"
    t.string "status", default: "pending_admin_review"
    t.string "customer_search_decision"
    t.datetime "customer_search_deadline_at"
    t.datetime "customer_decided_at"
    t.datetime "extended_search_deadline_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_bookings_on_address_id"
    t.index ["customer_id"], name: "index_bookings_on_customer_id"
    t.index ["partner_id"], name: "index_bookings_on_partner_id"
    t.index ["service_category_id"], name: "index_bookings_on_service_category_id"
  end

  create_table "customers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

  create_table "partner_services", force: :cascade do |t|
    t.bigint "partner_id", null: false
    t.bigint "service_category_id", null: false
    t.string "experience"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["partner_id"], name: "index_partner_services_on_partner_id"
    t.index ["service_category_id"], name: "index_partner_services_on_service_category_id"
  end

  create_table "partners", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "current_lat", precision: 10, scale: 6, null: false
    t.decimal "current_long", precision: 10, scale: 6, null: false
    t.datetime "location_updated_at", precision: nil
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_currently_working", default: false, null: false
    t.bigint "residential_address_id"
    t.index ["residential_address_id"], name: "index_partners_on_residential_address_id"
    t.index ["user_id"], name: "index_partners_on_user_id"
  end

  create_table "service_categories", force: :cascade do |t|
    t.string "category_name", null: false
    t.string "description"
    t.decimal "min_price", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "min_price > 0::numeric", name: "category_min_price_check"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
  end

  add_foreign_key "addresses", "users"
  add_foreign_key "admins", "users"
  add_foreign_key "booking_assignments", "booking_offers"
  add_foreign_key "booking_assignments", "bookings"
  add_foreign_key "booking_assignments", "partners"
  add_foreign_key "booking_offers", "admins", column: "assigned_by_admin_id"
  add_foreign_key "booking_offers", "booking_search_rounds"
  add_foreign_key "booking_offers", "bookings"
  add_foreign_key "booking_offers", "partners"
  add_foreign_key "booking_search_rounds", "bookings"
  add_foreign_key "bookings", "addresses"
  add_foreign_key "bookings", "customers"
  add_foreign_key "bookings", "partners"
  add_foreign_key "bookings", "service_categories"
  add_foreign_key "customers", "users"
  add_foreign_key "partner_services", "partners"
  add_foreign_key "partner_services", "service_categories"
  add_foreign_key "partners", "addresses", column: "residential_address_id"
  add_foreign_key "partners", "users"
end
