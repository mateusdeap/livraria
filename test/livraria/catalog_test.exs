defmodule Livraria.CatalogTest do
  use Livraria.DataCase

  alias Livraria.Catalog

  describe "products" do
    alias Livraria.Catalog.Product

    import Livraria.CatalogFixtures

    @invalid_attrs %{cost_price: nil, description: nil, sell_price: nil, title: nil}

    test "list_products/0 returns all products" do
      product = product_fixture()
      assert Catalog.list_products() == [product]
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      assert Catalog.get_product!(product.id) == product
    end

    test "create_product/1 with valid data creates a product" do
      valid_attrs = %{cost_price: "120.5", description: "some description", sell_price: "120.5", title: "some title"}

      assert {:ok, %Product{} = product} = Catalog.create_product(valid_attrs)
      assert product.cost_price == Decimal.new("120.5")
      assert product.description == "some description"
      assert product.sell_price == Decimal.new("120.5")
      assert product.title == "some title"
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Catalog.create_product(@invalid_attrs)
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()
      update_attrs = %{cost_price: "456.7", description: "some updated description", sell_price: "456.7", title: "some updated title"}

      assert {:ok, %Product{} = product} = Catalog.update_product(product, update_attrs)
      assert product.cost_price == Decimal.new("456.7")
      assert product.description == "some updated description"
      assert product.sell_price == Decimal.new("456.7")
      assert product.title == "some updated title"
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = product_fixture()
      assert {:error, %Ecto.Changeset{}} = Catalog.update_product(product, @invalid_attrs)
      assert product == Catalog.get_product!(product.id)
    end

    test "delete_product/1 deletes the product" do
      product = product_fixture()
      assert {:ok, %Product{}} = Catalog.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset" do
      product = product_fixture()
      assert %Ecto.Changeset{} = Catalog.change_product(product)
    end
  end
end
