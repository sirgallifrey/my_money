defmodule MyMoneyWeb.OrgSession do
  use MyMoneyWeb, :verified_routes
  import Plug.Conn
  import Phoenix.Controller

  alias MyMoney.UserAccounts.{Org, OrgMember, Scope}
  alias MyMoney.Orgs
  alias MyMoney.UserAccounts

  @remember_selected_org_cookie "_my_money_web_remember_selected_org"
  @remember_selected_org_options [sign: true, same_site: "Lax"]

  defp put_selected_org_in_session(conn, org_id) do
    conn
    |> put_session(:selected_org_id, org_id)
  end

  # TODO: might use this one day to save last selected ORG on cookies
  # defp write_remember_me_cookie(conn, token) do
  #   conn
  #   |> put_session(:user_remember_me, true)
  #   |> put_resp_cookie(@remember_me_cookie, token, @remember_me_options)
  # end

  defp scope_with_org_and_membership(%Scope{} = scope, org_id) do
    with {:ok, %{org_member: %OrgMember{} = org_member, org: %Org{} = org}} <-
           Orgs.get_org_and_membership!(scope, org_id) do
      Scope.with_org(scope, org, org_member)
    else
      _ -> scope
    end
  end

  defp mount_org_membership(org_id, socket, _session) do
    socket =
      Phoenix.Component.assign(
        socket,
        :current_scope,
        scope_with_org_and_membership(socket.assigns.current_scope, org_id)
      )

    socket
  end

  def on_mount(:require_org_membership, params, session, socket) do
    socket = mount_org_membership(params["org_id"], socket, session)

    IO.inspect(socket.assigns.current_scope)

    if socket.assigns.current_scope && socket.assigns.current_scope.org &&
         socket.assigns.current_scope.org_member do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "Organization not found.")
        |> Phoenix.LiveView.redirect(to: ~p"/orgs")

      {:halt, socket}
    end
  end

  defp ensure_selected_org(conn) do
    if org_id = get_session(conn, :selected_org_id) do
      {org_id, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_selected_org_cookie])

      if token = conn.cookies[@remember_selected_org_cookie] do
        {token, put_selected_org_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end
end
