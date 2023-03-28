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
end
