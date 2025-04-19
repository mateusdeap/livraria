class CreateStaffs < ActiveRecord::Migration[8.0]
  def change
    create_table :staffs do |t|
      t.string :name
      t.string :email
      t.string :position

      t.timestamps
    end
  end
end
