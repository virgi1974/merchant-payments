class CreateDisbursements < ActiveRecord::Migration[8.0]
  def change
    create_table :disbursements, id: false do |t|
      t.string :id, primary_key: true
      t.references :merchant, null: false, foreign_key: true, type: :string
      t.integer :amount_cents, null: false
      t.integer :fees_amount_cents, null: false
      t.datetime :disbursed_at
      t.timestamps
    end
  end
end
