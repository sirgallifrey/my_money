defmodule MyMoneyWeb.OrgMemberLive.Index do
  use MyMoneyWeb, :live_view

  alias MyMoney.UserAccounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Org members
        <:actions>
          <.button variant="primary" navigate={~p"/org_members/new"}>
            <.icon name="hero-plus" /> New Org member
          </.button>
        </:actions>
      </.header>

      <.table
        id="org_members"
        rows={@streams.org_members}
        row_click={fn {_id, org_member} -> JS.navigate(~p"/org_members/#{org_member}") end}
      >
        <:col :let={{_id, org_member}} label="Role">{org_member.role}</:col>
        <:action :let={{_id, org_member}}>
          <div class="sr-only">
            <.link navigate={~p"/org_members/#{org_member}"}>Show</.link>
          </div>
          <.link navigate={~p"/org_members/#{org_member}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, org_member}}>
          <.link
            phx-click={JS.push("delete", value: %{id: org_member.id}) |> hide("##{id}")}
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
    UserAccounts.subscribe_org_members(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Listing Org members")
     |> stream(:org_members, UserAccounts.list_org_members(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    org_member = UserAccounts.get_org_member!(socket.assigns.current_scope, id)
    {:ok, _} = UserAccounts.delete_org_member(socket.assigns.current_scope, org_member)

    {:noreply, stream_delete(socket, :org_members, org_member)}
  end

  @impl true
  def handle_info({type, %MyMoney.UserAccounts.OrgMember{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :org_members, UserAccounts.list_org_members(socket.assigns.current_scope), reset: true)}
  end
end
