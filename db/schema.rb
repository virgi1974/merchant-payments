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

ActiveRecord::Schema[8.0].define(version: 2025_01_25_185912) do
  create_table "disbursements", id: :string, force: :cascade do |t|
    t.string "merchant_id", null: false
    t.integer "amount_cents", null: false
    t.integer "fees_amount_cents", null: false
    t.datetime "disbursed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id"], name: "index_disbursements_on_merchant_id"
  end

  create_table "merchants", id: :string, force: :cascade do |t|
    t.string "reference", null: false
    t.string "email", null: false
    t.date "live_on", null: false
    t.integer "disbursement_frequency", null: false
    t.integer "minimum_monthly_fee_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reference"], name: "index_merchants_on_reference", unique: true
  end

  create_table "monthly_fee_adjustments", force: :cascade do |t|
    t.string "merchant_id", null: false
    t.integer "amount_cents", null: false
    t.integer "month", null: false
    t.integer "year", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id", "month", "year"], name: "idx_monthly_fee_adjustments_on_merchant_month_year", unique: true
    t.index ["merchant_id"], name: "index_monthly_fee_adjustments_on_merchant_id"
  end

  create_table "orders", id: :string, force: :cascade do |t|
    t.string "merchant_reference", null: false
    t.integer "amount_cents", null: false
    t.string "amount_currency", default: "EUR", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "disbursement_id"
    t.boolean "pending_disbursement", default: true, null: false
    t.index ["disbursement_id"], name: "index_orders_on_disbursement_id"
    t.index ["merchant_reference", "pending_disbursement", "created_at"], name: "idx_orders_on_merchant_pending_created"
  end

  add_foreign_key "disbursements", "merchants"
  add_foreign_key "monthly_fee_adjustments", "merchants"
  add_foreign_key "orders", "disbursements"
  add_foreign_key "orders", "merchants", column: "merchant_reference", primary_key: "reference"
end
