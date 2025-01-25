class CreateMonthlyFeeAdjustments < ActiveRecord::Migration[8.0]
  def change
    create_table :monthly_fee_adjustments do |t|
      t.references :merchant, null: false, foreign_key: true, type: :string
      t.integer :amount_cents, null: false
      t.integer :month, null: false
      t.integer :year, null: false
      t.timestamps

      t.index [ :merchant_id, :month, :year ], unique: true,
        name: "idx_monthly_fee_adjustments_on_merchant_month_year"
    end
  end
end
