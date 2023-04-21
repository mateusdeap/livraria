defmodule Livraria.CatalogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Livraria.Catalog` context.
  """

  @doc """
  Generate a supplier.
  """
  def supplier_fixture(attrs \\ %{}) do
    {:ok, supplier} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Livraria.Catalog.create_supplier()

    supplier
  end

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        cost_price: "120.5",
        description: "some description",
        sell_price: "120.5",
        title: "some title",
        image: "/some/path",
        supplier_id: supplier_fixture(%{name: "some name"}).id,
        quantity: 1
      })
      |> Livraria.Catalog.create_product()

    product
  end
end
