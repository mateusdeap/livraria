defmodule LivrariaWeb.Acceptance.CartTest do
  use LivrariaWeb.ConnCase
  use Hound.Helpers

  hound_session()

  setup do
    alias Livraria.Repo
    alias Livraria.Catalog.Product
    alias Livraria.Inventory.Supplier

    {:ok, supplier} = Repo.insert(%Supplier{name: "Teste"})

    Repo.insert(%Product{
      name: "Crime e Castigo",
      description: "Um clássico russo",
      sell_price: 30,
      cost_price: 20,
      quantity: 3,
      image: "https://placehold.co/400x600@3x.png",
      supplier_id: supplier.id
    })

    Repo.insert(%Product{
      name: "O Senhor dos Anéis",
      description: "Um clássico da fantasia",
      sell_price: 34,
      cost_price: 25,
      quantity: 5,
      image: "https://placehold.co/400x600@3x.png",
      supplier_id: supplier.id
    })

    :ok
  end

  test "presence of cart form for each product" do
    navigate_to("/products")

    products = find_all_elements(:css, ".product")

    assert Enum.count(products) != 0

    products
    |> Enum.each(fn product ->
      button = find_within_element(product, :tag, "button")
      assert visible_text(button) == "Add to cart"
    end)
  end

  test "add to cart" do
    navigate_to("/products")

    [product | _rest] = find_all_elements(:css, ".product")

    product_title =
      find_within_element(product, :name, "cart[name]")
      |> attribute_value("value")

    find_within_element(product, :name, "cart[quantity]")
    |> fill_field(2)

    find_within_element(product, :tag, "button")
    |> click()

    message =
      find_element(:css, "#flash")
      |> visible_text()

    assert message =~ "Product added to cart - #{product_title} x 2"
  end
end
