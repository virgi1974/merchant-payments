class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders, id: false do |t|
      t.string :id, primary_key: true
      t.string :merchant_reference, null: false, index: true
      t.integer :amount_cents, null: false
      t.string :amount_currency, null: false, default: "EUR"

      t.timestamps
    end

    add_foreign_key :orders, :merchants,
                    column: :merchant_reference,
                    primary_key: :reference
  end
end
