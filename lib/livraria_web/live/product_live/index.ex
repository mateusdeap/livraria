defmodule LivrariaWeb.ProductLive.Index do
  use LivrariaWeb, :live_view

  alias Livraria.Inventory
  alias Livraria.Catalog
  alias Livraria.Catalog.Product
  alias Livraria.Sales

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form, to_form(%{"product_id" => nil, "quantity" => nil}, as: "cart"))
     |> stream(:products, Catalog.list_products())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Product")
    |> assign(:product, Catalog.get_product!(id))
    |> assign(:suppliers, Inventory.list_suppliers())
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Product")
    |> assign(:product, %Product{})
    |> assign(:suppliers, Inventory.list_suppliers())
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Products")
    |> assign(:product, nil)
    |> assign(:suppliers, nil)
  end

  @impl true
  def handle_info({LivrariaWeb.ProductLive.FormComponent, {:saved, product}}, socket) do
    {:noreply, stream_insert(socket, :products, product)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Catalog.get_product!(id)
    {:ok, _} = Catalog.delete_product(product)

    {:noreply, stream_delete(socket, :products, product)}
  end

  @impl true
  def handle_event("add_to_cart", %{"cart" => cart_params}, socket) do
    cart = "?"

    case Sales.add_to_cart(cart, cart_params) do
      {:ok, _} ->
        %{"name" => name, "quantity" => quantity} = cart_params
        {:noreply, put_flash(socket, :info, "Product added to cart - #{name} x #{quantity}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Error adding product to cart")}
    end
  end
end
