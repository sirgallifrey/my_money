defmodule MyMoneyWeb.OrgMemberLive.Form do
  use MyMoneyWeb, :live_view

  alias MyMoney.UserAccounts
  alias MyMoney.UserAccounts.OrgMember

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage org_member records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="org_member-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:role]} type="number" label="Role" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Org member</.button>
          <.button navigate={return_path(@current_scope, @return_to, @org_member)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    org_member = UserAccounts.get_org_member!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Org member")
    |> assign(:org_member, org_member)
    |> assign(:form, to_form(UserAccounts.change_org_member(socket.assigns.current_scope, org_member)))
  end

  defp apply_action(socket, :new, _params) do
    org_member = %OrgMember{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Org member")
    |> assign(:org_member, org_member)
    |> assign(:form, to_form(UserAccounts.change_org_member(socket.assigns.current_scope, org_member)))
  end

  @impl true
  def handle_event("validate", %{"org_member" => org_member_params}, socket) do
    changeset = UserAccounts.change_org_member(socket.assigns.current_scope, socket.assigns.org_member, org_member_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"org_member" => org_member_params}, socket) do
    save_org_member(socket, socket.assigns.live_action, org_member_params)
  end

  defp save_org_member(socket, :edit, org_member_params) do
    case UserAccounts.update_org_member(socket.assigns.current_scope, socket.assigns.org_member, org_member_params) do
      {:ok, org_member} ->
        {:noreply,
         socket
         |> put_flash(:info, "Org member updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, org_member)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_org_member(socket, :new, org_member_params) do
    case UserAccounts.create_org_member(socket.assigns.current_scope, org_member_params) do
      {:ok, org_member} ->
        {:noreply,
         socket
         |> put_flash(:info, "Org member created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, org_member)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _org_member), do: ~p"/org_members"
  defp return_path(_scope, "show", org_member), do: ~p"/org_members/#{org_member}"
end
