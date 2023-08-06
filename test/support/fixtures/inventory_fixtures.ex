defmodule Livraria.InventoryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Livraria.Inventory` context.
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
      |> Livraria.Inventory.create_supplier()

    supplier
  end
end
