defmodule MyMoneyWeb.OrgLive.Form do
  use MyMoneyWeb, :live_view

  alias MyMoney.UserAccounts
  alias MyMoney.UserAccounts.Org
  alias MyMoney.Orgs

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage org records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="org-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Org</.button>
          <.button navigate={return_path(@current_scope, @return_to, @org)}>Cancel</.button>
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
    org = Orgs.get_org!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Org")
    |> assign(:org, org)
    |> assign(:form, to_form(Orgs.change_org(socket.assigns.current_scope, org)))
  end

  defp apply_action(socket, :new, _params) do
    org = %Org{}

    socket
    |> assign(:page_title, "New Org")
    |> assign(:org, org)
    |> assign(:form, to_form(Orgs.change_org(socket.assigns.current_scope, org)))
  end

  @impl true
  def handle_event("validate", %{"org" => org_params}, socket) do
    changeset = Orgs.change_org(socket.assigns.current_scope, socket.assigns.org, org_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"org" => org_params}, socket) do
    save_org(socket, socket.assigns.live_action, org_params)
  end

  defp save_org(socket, :edit, org_params) do
    case Orgs.update_org(socket.assigns.current_scope, socket.assigns.org, org_params) do
      {:ok, org} ->
        {:noreply,
         socket
         |> put_flash(:info, "Org updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, org)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_org(socket, :new, org_params) do
    case Orgs.create_org(socket.assigns.current_scope, org_params) do
      {:ok, org} ->
        {:noreply,
         socket
         |> put_flash(:info, "Org created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, org)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _org), do: ~p"/orgs"
  defp return_path(_scope, "show", org), do: ~p"/orgs/#{org}"
end
