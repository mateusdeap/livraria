defmodule Livraria.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :cost_price, :decimal
    field :description, :string
    field :sell_price, :decimal
    field :title, :string
    field :supplier_id, :id

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:title, :description, :sell_price, :cost_price, :supplier_id])
    |> validate_required([:title, :description, :sell_price, :supplier_id])
  end
end
