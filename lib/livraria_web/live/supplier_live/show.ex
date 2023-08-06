defmodule LivrariaWeb.SupplierLive.Show do
  use LivrariaWeb, :live_view

  alias Livraria.Inventory

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:supplier, Inventory.get_supplier!(id))}
  end

  defp page_title(:show), do: "Show Supplier"
  defp page_title(:edit), do: "Edit Supplier"
end
