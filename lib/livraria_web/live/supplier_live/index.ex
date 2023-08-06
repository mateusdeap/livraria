defmodule LivrariaWeb.SupplierLive.Index do
  use LivrariaWeb, :live_view

  alias Livraria.Inventory
  alias Livraria.Inventory.Supplier

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :suppliers, Inventory.list_suppliers())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Supplier")
    |> assign(:supplier, Inventory.get_supplier!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Supplier")
    |> assign(:supplier, %Supplier{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Suppliers")
    |> assign(:supplier, nil)
  end

  @impl true
  def handle_info({LivrariaWeb.SupplierLive.FormComponent, {:saved, supplier}}, socket) do
    {:noreply, stream_insert(socket, :suppliers, supplier)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    supplier = Inventory.get_supplier!(id)
    {:ok, _} = Inventory.delete_supplier(supplier)

    {:noreply, stream_delete(socket, :suppliers, supplier)}
  end
end
