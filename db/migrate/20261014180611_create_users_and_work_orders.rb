class CreateUsersAndWorkOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.integer :role, default: 1, null: false # 0: manager, 1: technician
      t.string :title
      t.string :phone
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :work_orders do |t|
      t.string :order_number, null: false
      t.string :title, null: false
      t.text :description
      t.integer :priority, default: 1, null: false # 0: low, 1: medium, 2: high, 3: critical
      t.integer :status, default: 0, null: false   # 0: new_order, 1: assigned, 2: in_progress, 3: completed, 4: blocked, 5: cancelled
      t.datetime :due_at, null: false
      t.string :customer_name, null: false
      t.string :facility_location, null: false
      t.string :asset_name, null: false
      t.string :asset_serial_number
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end
    add_index :work_orders, :order_number, unique: true
    add_index :work_orders, :status
    add_index :work_orders, :due_at

    create_table :status_transitions do |t|
      t.references :work_order, null: false, foreign_key: true
      t.references :changed_by, null: false, foreign_key: { to_table: :users }
      t.integer :from_status, null: false
      t.integer :to_status, null: false
      t.text :note
      t.timestamps
    end
  end
end
