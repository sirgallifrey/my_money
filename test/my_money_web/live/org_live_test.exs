defmodule MyMoneyWeb.OrgLiveTest do
  use MyMoneyWeb.ConnCase

  import Phoenix.LiveViewTest
  import MyMoney.UserAccountsFixtures

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  setup :register_and_log_in_user

  defp create_org(%{scope: scope}) do
    org = org_fixture(scope)

    %{org: org}
  end

  describe "Index" do
    setup [:create_org]

    test "lists all orgs", %{conn: conn, org: org} do
      {:ok, _index_live, html} = live(conn, ~p"/orgs")

      assert html =~ "Listing Orgs"
      assert html =~ org.name
    end

    test "saves new org", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/orgs")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Org")
               |> render_click()
               |> follow_redirect(conn, ~p"/orgs/new")

      assert render(form_live) =~ "New Org"

      assert form_live
             |> form("#org-form", org: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#org-form", org: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/orgs")

      html = render(index_live)
      assert html =~ "Org created successfully"
      assert html =~ "some name"
    end

    test "updates org in listing", %{conn: conn, org: org} do
      {:ok, index_live, _html} = live(conn, ~p"/orgs")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#orgs-#{org.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/orgs/#{org}/edit")

      assert render(form_live) =~ "Edit Org"

      assert form_live
             |> form("#org-form", org: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#org-form", org: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/orgs")

      html = render(index_live)
      assert html =~ "Org updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes org in listing", %{conn: conn, org: org} do
      {:ok, index_live, _html} = live(conn, ~p"/orgs")

      assert index_live |> element("#orgs-#{org.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#orgs-#{org.id}")
    end
  end

  describe "Show" do
    setup [:create_org]

    test "displays org", %{conn: conn, org: org} do
      {:ok, _show_live, html} = live(conn, ~p"/orgs/#{org}")

      assert html =~ "Show Org"
      assert html =~ org.name
    end

    test "updates org and returns to show", %{conn: conn, org: org} do
      {:ok, show_live, _html} = live(conn, ~p"/orgs/#{org}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/orgs/#{org}/edit?return_to=show")

      assert render(form_live) =~ "Edit Org"

      assert form_live
             |> form("#org-form", org: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#org-form", org: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/orgs/#{org}")

      html = render(show_live)
      assert html =~ "Org updated successfully"
      assert html =~ "some updated name"
    end
  end
end
