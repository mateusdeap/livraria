defmodule Livraria.InventoryTest do
  use Livraria.DataCase

  alias Livraria.Inventory

  describe "suppliers" do
    alias Livraria.Inventory.Supplier

    import Livraria.InventoryFixtures

    @invalid_attrs %{name: nil}

    test "list_suppliers/0 returns all suppliers" do
      supplier = supplier_fixture()
      assert Inventory.list_suppliers() == [supplier]
    end

    test "get_supplier!/1 returns the supplier with given id" do
      supplier = supplier_fixture()
      assert Inventory.get_supplier!(supplier.id) == supplier
    end

    test "create_supplier/1 with valid data creates a supplier" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Supplier{} = supplier} = Inventory.create_supplier(valid_attrs)
      assert supplier.name == "some name"
    end

    test "create_supplier/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_supplier(@invalid_attrs)
    end

    test "update_supplier/2 with valid data updates the supplier" do
      supplier = supplier_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Supplier{} = supplier} = Inventory.update_supplier(supplier, update_attrs)
      assert supplier.name == "some updated name"
    end

    test "update_supplier/2 with invalid data returns error changeset" do
      supplier = supplier_fixture()
      assert {:error, %Ecto.Changeset{}} = Inventory.update_supplier(supplier, @invalid_attrs)
      assert supplier == Inventory.get_supplier!(supplier.id)
    end

    test "delete_supplier/1 deletes the supplier" do
      supplier = supplier_fixture()
      assert {:ok, %Supplier{}} = Inventory.delete_supplier(supplier)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_supplier!(supplier.id) end
    end

    test "change_supplier/1 returns a supplier changeset" do
      supplier = supplier_fixture()
      assert %Ecto.Changeset{} = Inventory.change_supplier(supplier)
    end
  end
end
