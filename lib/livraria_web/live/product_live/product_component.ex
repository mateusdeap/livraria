defmodule LivrariaWeb.ProductLive.ProductComponent do
  use Phoenix.Component

  import LivrariaWeb.CoreComponents

  def card(assigns) do
    ~H"""
    <div class="group product" id={@id}>
      <div class="aspect-h-1 aspect-w-1 w-full overflow-hidden rounded-lg bg-gray-200 xl:aspect-h-8 xl:aspect-w-7">
        <img
          src={@product.image}
          alt={@product.description}
          class="h-full w-full object-cover object-center group-hover:opacity-75"
        />
      </div>
      <h3 class="mt-4 text-sm text-gray-700"><%= @product.name %></h3>
      <p class="mt-1 text-lg font-medium text-gray-900"><%= @product.sell_price %></p>
      <hr />
      <.simple_form for={@form} id="cart-form" phx-submit="add_to_cart">
        <.input field={@form[:product_id]} value={@product.id} type="hidden" />
        <.input field={@form[:name]} value={@product.name} type="hidden" />
        <.input field={@form[:quantity]} value="1" type="number" />
        <:actions>
          <.button phx-disable-with="Adding...">Add to cart</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
