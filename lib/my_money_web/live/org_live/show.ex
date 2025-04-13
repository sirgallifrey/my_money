defmodule MyMoneyWeb.OrgLive.Show do
  alias MyMoney.Orgs
  use MyMoneyWeb, :live_view

  alias MyMoney.UserAccounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Org {@org.id}
        <:subtitle>This is a org record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/orgs"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/orgs/#{@org}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit org
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@org.name}</:item>
        <:item title="Description">{@org.description}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"org_id" => id}, _session, socket) do
    #    UserAccounts.subscribe_orgs(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Show Org")
     |> assign(:org, Orgs.get_org!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %MyMoney.UserAccounts.Org{id: id} = org},
        %{assigns: %{org: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :org, org)}
  end

  def handle_info(
        {:deleted, %MyMoney.UserAccounts.Org{id: id}},
        %{assigns: %{org: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current org was deleted.")
     |> push_navigate(to: ~p"/orgs")}
  end
end
