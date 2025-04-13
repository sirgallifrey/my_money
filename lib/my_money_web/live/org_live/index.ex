defmodule MyMoneyWeb.OrgLive.Index do
  alias MyMoney.Orgs
  use MyMoneyWeb, :live_view

  alias MyMoney.UserAccounts
  alias MyMoney.Orgs

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Orgs
        <:actions>
          <.button variant="primary" navigate={~p"/orgs/new"}>
            <.icon name="hero-plus" /> New Org
          </.button>
        </:actions>
      </.header>

      <.table
        id="orgs"
        rows={@streams.orgs}
        row_click={fn {_id, org} -> JS.navigate(~p"/orgs/#{org}") end}
      >
        <:col :let={{_id, org}} label="Name">{org.name}</:col>
        <:col :let={{_id, org}} label="Description">{org.description}</:col>
        <:action :let={{_id, org}}>
          <div class="sr-only">
            <.link navigate={~p"/orgs/#{org}"}>Show</.link>
          </div>
          <.link navigate={~p"/orgs/#{org}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, org}}>
          <.link
            phx-click={JS.push("delete", value: %{id: org.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # UserAccounts.subscribe_orgs(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Listing Orgs")
     |> stream(:orgs, Orgs.list_orgs(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    org = Orgs.get_org!(socket.assigns.current_scope, id)
    {:ok, _} = Orgs.delete_org(socket.assigns.current_scope, org)

    {:noreply, stream_delete(socket, :orgs, org)}
  end

  @impl true
  def handle_info({type, %MyMoney.UserAccounts.Org{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :orgs, Orgs.list_orgs(socket.assigns.current_scope), reset: true)}
  end
end
