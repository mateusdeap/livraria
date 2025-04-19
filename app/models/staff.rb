class Staff < ApplicationRecord
  has_many :orders

  validates :name, :email, presence: true
  validates :email, uniqueness: true
end
