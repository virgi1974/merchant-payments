class UpdateOrdersTrackingAndIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add disbursement tracking
    add_reference :orders, :disbursement, foreign_key: true, null: true, type: :string
    add_column :orders, :pending_disbursement, :boolean, default: true, null: false

    # Remove old index and add optimized composite index
    remove_index :orders, :merchant_reference
    add_index :orders, [ :merchant_reference, :pending_disbursement, :created_at ],
      name: "idx_orders_on_merchant_pending_created"
  end
end
