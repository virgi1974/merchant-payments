class CreateMerchants < ActiveRecord::Migration[8.0]
  def change
    create_table :merchants, id: false do |t|
      t.string :id, primary_key: true
      t.string :reference, null: false
      t.string :email, null: false
      t.date :live_on, null: false
      t.integer :disbursement_frequency, null: false
      t.integer :minimum_monthly_fee_cents, null: false, default: 0

      t.timestamps

      t.index :reference, unique: true
    end
  end
end
