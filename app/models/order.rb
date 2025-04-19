class Order < ApplicationRecord
  belongs_to :staff
  has_many :order_items, dependant: :destroy
  has_many :products, through: :order_items

  validates :payment_method, presence: true

  def add_product(product, quantity = 1)
    current_item = order_items.find_by(product: product)

    if current_item
      current_item.quantity += quantity
      current_item.save
    else
      order_items.create(product: product, quantity: quantity, unit_price:  product.price)
    end

    update_total
  end

  def update_total
    update(total_amount: order_items.sum { |item| item.unit_price * item.quantity })
  end

  def complete_sale
    update(completed_at: Time.current)

    order_items.each do |item|
      product = item.product
      product.inventory_count -= item.quantity
      product.save
    end
  end
end
