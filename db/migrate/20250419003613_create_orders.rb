class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.decimal :total_amount
      t.string :payment_method
      t.references :staff_id, null: false, foreign_key: true
      t.datetime :completed_at

      t.timestamps
    end
  end
end
