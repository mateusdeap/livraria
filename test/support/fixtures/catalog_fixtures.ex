defmodule Livraria.CatalogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Livraria.Catalog` context.
  """

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
        title: "some title"
      })
      |> Livraria.Catalog.create_product()

    product
  end
end
