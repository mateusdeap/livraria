defmodule Livraria.CatalogTest do
  use Livraria.DataCase

  alias Livraria.Catalog

  describe "suppliers" do
    alias Livraria.Catalog.Supplier

    import Livraria.CatalogFixtures

    @invalid_attrs %{name: nil}

    test "list_suppliers/0 returns all suppliers" do
      supplier = supplier_fixture()
      assert Catalog.list_suppliers() == [supplier]
    end

    test "get_supplier!/1 returns the supplier with given id" do
      supplier = supplier_fixture()
      assert Catalog.get_supplier!(supplier.id) == supplier
    end

    test "create_supplier/1 with valid data creates a supplier" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Supplier{} = supplier} = Catalog.create_supplier(valid_attrs)
      assert supplier.name == "some name"
    end

    test "create_supplier/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Catalog.create_supplier(@invalid_attrs)
    end

    test "update_supplier/2 with valid data updates the supplier" do
      supplier = supplier_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Supplier{} = supplier} = Catalog.update_supplier(supplier, update_attrs)
      assert supplier.name == "some updated name"
    end

    test "update_supplier/2 with invalid data returns error changeset" do
      supplier = supplier_fixture()
      assert {:error, %Ecto.Changeset{}} = Catalog.update_supplier(supplier, @invalid_attrs)
      assert supplier == Catalog.get_supplier!(supplier.id)
    end

    test "delete_supplier/1 deletes the supplier" do
      supplier = supplier_fixture()
      assert {:ok, %Supplier{}} = Catalog.delete_supplier(supplier)
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_supplier!(supplier.id) end
    end

    test "change_supplier/1 returns a supplier changeset" do
      supplier = supplier_fixture()
      assert %Ecto.Changeset{} = Catalog.change_supplier(supplier)
    end
  end
end
