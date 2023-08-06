defmodule LivrariaWeb.SupplierLiveTest do
  use LivrariaWeb.ConnCase

  import Phoenix.LiveViewTest
  import Livraria.InventoryFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_supplier(_) do
    supplier = supplier_fixture()
    %{supplier: supplier}
  end

  describe "Index" do
    setup [:create_supplier]

    test "lists all suppliers", %{conn: conn, supplier: supplier} do
      {:ok, _index_live, html} = live(conn, ~p"/suppliers")

      assert html =~ "Listing Suppliers"
      assert html =~ supplier.name
    end

    test "saves new supplier", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/suppliers")

      assert index_live |> element("a", "New Supplier") |> render_click() =~
               "New Supplier"

      assert_patch(index_live, ~p"/suppliers/new")

      assert index_live
             |> form("#supplier-form", supplier: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#supplier-form", supplier: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/suppliers")

      html = render(index_live)
      assert html =~ "Supplier created successfully"
      assert html =~ "some name"
    end

    test "updates supplier in listing", %{conn: conn, supplier: supplier} do
      {:ok, index_live, _html} = live(conn, ~p"/suppliers")

      assert index_live |> element("#suppliers-#{supplier.id} a", "Edit") |> render_click() =~
               "Edit Supplier"

      assert_patch(index_live, ~p"/suppliers/#{supplier}/edit")

      assert index_live
             |> form("#supplier-form", supplier: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#supplier-form", supplier: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/suppliers")

      html = render(index_live)
      assert html =~ "Supplier updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes supplier in listing", %{conn: conn, supplier: supplier} do
      {:ok, index_live, _html} = live(conn, ~p"/suppliers")

      assert index_live |> element("#suppliers-#{supplier.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#suppliers-#{supplier.id}")
    end
  end

  describe "Show" do
    setup [:create_supplier]

    test "displays supplier", %{conn: conn, supplier: supplier} do
      {:ok, _show_live, html} = live(conn, ~p"/suppliers/#{supplier}")

      assert html =~ "Show Supplier"
      assert html =~ supplier.name
    end

    test "updates supplier within modal", %{conn: conn, supplier: supplier} do
      {:ok, show_live, _html} = live(conn, ~p"/suppliers/#{supplier}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Supplier"

      assert_patch(show_live, ~p"/suppliers/#{supplier}/show/edit")

      assert show_live
             |> form("#supplier-form", supplier: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#supplier-form", supplier: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/suppliers/#{supplier}")

      html = render(show_live)
      assert html =~ "Supplier updated successfully"
      assert html =~ "some updated name"
    end
  end
end
