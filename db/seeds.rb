# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# Create a book
Book.create(
  name: "The Rails Way",
  title: "The Rails Way",
  author: "Obie Fernandez",
  publisher: "Addison-Wesley",
  isbn: "978-0321601667",
  price: 49.99,
  inventory_count: 10,
  category: "Programming"
)

# Create a regular product
Product.create(
  name: "Bookstore Mug",
  price: 12.99,
  inventory_count: 25,
  category: "Merchandise"
)
