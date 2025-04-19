class Product < ApplicationRecord
  has_many :order_items
  has_many :orders, through: :order_items

  validates :name, :price, presence: true
  validates :price, numericality: {greater_than_or_equal_to: 0}
  validates :inventory_count, numericality: {only_integer: true, greater_than_or_equal_to: 0}
end
