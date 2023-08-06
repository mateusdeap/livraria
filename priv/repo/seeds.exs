# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Livraria.Repo.insert!(%Livraria.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

NimbleCSV.define(Parser, separator: ";", escape: "\"")

alias Livraria.Catalog.Product
alias Livraria.Inventory
alias Livraria.Inventory.Supplier
alias Livraria.Repo

"catalog.csv"
|> File.read!()
|> Parser.parse_string()
|> Enum.each(fn [title, description, sell_price, cost_price, quantity, supplier_name, image] ->
  {:ok, supplier} =
    case Supplier |> Repo.get_by(name: supplier_name) do
      nil -> Inventory.create_supplier(%{name: supplier_name})
      supplier -> {:ok, supplier}
    end

  decimal_sell_price = String.to_float(sell_price) |> Float.to_string() |> Decimal.new()
  decimal_cost_price = String.to_float(cost_price) |> Float.to_string() |> Decimal.new()

  %Product{
    name: title,
    description: description,
    sell_price: decimal_sell_price,
    cost_price: decimal_cost_price,
    quantity: String.to_integer(quantity),
    supplier_id: supplier.id,
    image: image
  }
  |> Repo.insert()
end)
