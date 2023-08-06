defmodule Livraria.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :cost_price, :decimal
    field :description, :string
    field :sell_price, :decimal
    field :name, :string
    field :quantity, :integer
    field :image, :string
    field :supplier_id, :id

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [
      :name,
      :description,
      :sell_price,
      :cost_price,
      :quantity,
      :image,
      :supplier_id
    ])
    |> validate_required([
      :name,
      :description,
      :sell_price,
      :cost_price,
      :quantity,
      :image,
      :supplier_id
    ])
  end
end
