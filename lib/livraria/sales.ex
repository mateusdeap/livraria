defmodule Livraria.Sales do
  alias Livraria.Repo
  alias Livraria.Sales.Order

  def create_cart() do
    %Order{status: "In Cart"}
    |> Repo.insert!()
  end

  def get_cart(id) do
    Order
    |> Repo.get_by(id: id, status: "In Cart")
  end

  def add_to_cart(cart, cart_params) do
    {:ok, nil}
  end
end