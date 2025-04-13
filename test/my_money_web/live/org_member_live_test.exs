defmodule MyMoneyWeb.OrgMemberLiveTest do
  use MyMoneyWeb.ConnCase

  import Phoenix.LiveViewTest
  import MyMoney.UserAccountsFixtures

  @create_attrs %{role: 42}
  @update_attrs %{role: 43}
  @invalid_attrs %{role: nil}

  setup :register_and_log_in_user

  defp create_org_member(%{scope: scope}) do
    org_member = org_member_fixture(scope)

    %{org_member: org_member}
  end

  describe "Index" do
    setup [:create_org_member]

    test "lists all org_members", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/org_members")

      assert html =~ "Listing Org members"
    end

    test "saves new org_member", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/org_members")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Org member")
               |> render_click()
               |> follow_redirect(conn, ~p"/org_members/new")

      assert render(form_live) =~ "New Org member"

      assert form_live
             |> form("#org_member-form", org_member: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#org_member-form", org_member: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/org_members")

      html = render(index_live)
      assert html =~ "Org member created successfully"
    end

    test "updates org_member in listing", %{conn: conn, org_member: org_member} do
      {:ok, index_live, _html} = live(conn, ~p"/org_members")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#org_members-#{org_member.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/org_members/#{org_member}/edit")

      assert render(form_live) =~ "Edit Org member"

      assert form_live
             |> form("#org_member-form", org_member: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#org_member-form", org_member: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/org_members")

      html = render(index_live)
      assert html =~ "Org member updated successfully"
    end

    test "deletes org_member in listing", %{conn: conn, org_member: org_member} do
      {:ok, index_live, _html} = live(conn, ~p"/org_members")

      assert index_live |> element("#org_members-#{org_member.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#org_members-#{org_member.id}")
    end
  end

  describe "Show" do
    setup [:create_org_member]

    test "displays org_member", %{conn: conn, org_member: org_member} do
      {:ok, _show_live, html} = live(conn, ~p"/org_members/#{org_member}")

      assert html =~ "Show Org member"
    end

    test "updates org_member and returns to show", %{conn: conn, org_member: org_member} do
      {:ok, show_live, _html} = live(conn, ~p"/org_members/#{org_member}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/org_members/#{org_member}/edit?return_to=show")

      assert render(form_live) =~ "Edit Org member"

      assert form_live
             |> form("#org_member-form", org_member: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#org_member-form", org_member: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/org_members/#{org_member}")

      html = render(show_live)
      assert html =~ "Org member updated successfully"
    end
  end
end
