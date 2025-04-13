defmodule MyMoneyWeb.OrgMemberLive.Show do
  use MyMoneyWeb, :live_view

  alias MyMoney.UserAccounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Org member {@org_member.id}
        <:subtitle>This is a org_member record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/org_members"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/org_members/#{@org_member}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit org_member
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Role">{@org_member.role}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    UserAccounts.subscribe_org_members(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Show Org member")
     |> assign(:org_member, UserAccounts.get_org_member!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %MyMoney.UserAccounts.OrgMember{id: id} = org_member},
        %{assigns: %{org_member: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :org_member, org_member)}
  end

  def handle_info(
        {:deleted, %MyMoney.UserAccounts.OrgMember{id: id}},
        %{assigns: %{org_member: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current org_member was deleted.")
     |> push_navigate(to: ~p"/org_members")}
  end
end
