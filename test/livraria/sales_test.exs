defmodule Livraria.SalesTest do
  use Livraria.DataCase

  alias Livraria.{Sales, Repo}
  alias Livraria.Sales.Order

  test "create_cart" do
    assert %Order{status: "In Cart"} = Sales.create_cart()
  end

  test "get_cart/1" do
    cart1 = Sales.create_cart()
    cart2 = Sales.get_cart(cart1.id)

    assert cart2.id == cart1.id
  end

  test "get_cart/1 only retrieves orders with In Cart status" do
    order = %Order{status: "Another Status"} |> Repo.insert!()
    cart = Sales.get_cart(order.id)

    assert cart == nil
  end
end
