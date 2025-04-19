class Book < Product
  validates :title, presence: true
  validates :isbn, uniqueness: true, allow_blank: true
end
