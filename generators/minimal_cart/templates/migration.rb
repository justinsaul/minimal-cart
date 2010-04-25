# See LICENSE file in the root for details
class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    create_table :shippings do |table|
      table.column :first_name, :string
      table.column :last_name, :string
      table.column :email, :string
      table.column :phone, :string
      table.column :street_address, :string
      table.column :street_address2, :string
      table.column :zip_code, :string
      table.column :state, :string
      table.column :country, :string
      table.column :city, :string
      table.column :shipping_method, :string
    end

    create_table :billings do |table|
      table.column :first_name, :string
      table.column :last_name, :string
      table.column :phone, :string
      table.column :address1, :string
      table.column :address2, :string
      table.column :zip, :string
      table.column :state, :string
      table.column :country, :string
      table.column :city, :string
      table.column :card_type, :string
      table.column :encrypted_card_number, :text
      table.column :obfuscated_card_number, :string
      table.column :expiration_month, :integer
      table.column :expiration_year, :integer
    end 

    # orders 
    create_table :orders do |table|
      table.column :transaction_id, :integer
      table.column :quantity, :integer
      table.column :orderable_id, :integer
      table.column :orderable_type, :string
      table.column :price, :decimal, :precision => 9, :scale => 4
    end
    
    
    # shopping transactions
    create_table :shopping_transactions do |table|
      table.column :date, :datetime
      table.column :status_transaction_id, :integer
      table.column :total, :decimal, :precision => 9, :scale => 4
      table.column :subtotal, :decimal, :precision => 9, :scale => 4
      table.column :tax_cost, :decimal, :precision => 9, :scale => 4
      table.column :shipping_cost, :decimal, :precision => 9, :scale => 4
      table.column :shipping_id, :integer
      table.column :billing_id, :integer
      table.column :shopper_id, :integer
      table.column :shopper_type, :string
      table.column :transaction_code, :string 
      table.column :coupon_discount, :decimal, :precision => 9, :scale => 4
      table.index :transaction_code, :unique => true
    end
    
    
    # shopping transaction statuses
    create_table :shopping_transaction_statuses do |table|
      table.column :status, :string
      table.column :description, :string
    end
    
    
    # country groups
    create_table :country_groups do |table|
      table.column :country, :string
      table.column :group_id, :integer
    end
    
    
    # shipping rates 
    create_table :shipping_rates do |table|
      table.column :from_weight, :float
      table.column :to_weight, :float
      table.column :method, :string
      table.column :rate, :float
      table.column :country_group, :integer
    end
    
    
    # tax rates
    create_table :tax_rates do |table|
      table.column :rate, :float      table.column :state, :string
      table.column :country, :string
    

    # gateway responses
    create_table :gateway_responses do |table|
      table.column :shopping_transaction_id, :integer
      table.column :success, :boolean
      table.column :response_object, :text
      table.timestamps
    end

    # coupons
    create_table :coupons do |t|
      t.string :type
      t.string :coupon_code
      t.decimal :value, :precision => 9, :scale => 4
      t.integer :times_used
      t.boolean :enabled
      t.boolean :expire_after_use, :default => false
      t.timestamps
      table.index :coupon_code, :unique => true
    end

    create_table :coupon_uses do |t|
      t.integer :coupon_id
      t.integer :shopping_transaction_id
      t.timestamps
    end
  end
  
  def self.down
    drop_table :shippings
    drop_table :orders
    drop_table :shopping_transactions
    drop_table :shopping_transaction_statuses
    drop_table :country_groups
    drop_table :shipping_rates
    drop_table :tax_rates
    drop_table :gateway_responses
    drop_table :coupons
    drop_table :coupon_uses
  end
end
