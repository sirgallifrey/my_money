defmodule MyMoney.UserAccountsTest do
  use MyMoney.DataCase

  alias MyMoney.UserAccounts

  import MyMoney.UserAccountsFixtures
  alias MyMoney.UserAccounts.{User, UserToken}

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute UserAccounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = UserAccounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute UserAccounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture() |> set_password()
      refute UserAccounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture() |> set_password()

      assert %User{id: ^id} =
               UserAccounts.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        UserAccounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = UserAccounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email to be set" do
      {:error, changeset} = UserAccounts.register_user(%{})

      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email when given" do
      {:error, changeset} = UserAccounts.register_user(%{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum values for email for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = UserAccounts.register_user(%{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = UserAccounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = UserAccounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users without password" do
      email = unique_user_email()
      {:ok, user} = UserAccounts.register_user(valid_user_attributes(email: email))
      assert user.email == email
      assert is_nil(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "sudo_mode?/2" do
    test "validates the authenticated_at time" do
      now = DateTime.utc_now()

      assert UserAccounts.sudo_mode?(%User{authenticated_at: DateTime.utc_now()})
      assert UserAccounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -19, :minute)})
      refute UserAccounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -21, :minute)})

      # minute override
      refute UserAccounts.sudo_mode?(
               %User{authenticated_at: DateTime.add(now, -11, :minute)},
               -10
             )

      # not authenticated
      refute UserAccounts.sudo_mode?(%User{})
    end
  end

  describe "change_user_email/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = UserAccounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          UserAccounts.deliver_user_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = unconfirmed_user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          UserAccounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert UserAccounts.update_user_email(user, token) == :ok
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert UserAccounts.update_user_email(user, "oops") == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert UserAccounts.update_user_email(%{user | email: "current@example.com"}, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert UserAccounts.update_user_email(user, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = UserAccounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        UserAccounts.change_user_password(
          %User{},
          %{
            "password" => "new valid password"
          },
          hash_password: false
        )

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        UserAccounts.update_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        UserAccounts.update_user_password(user, %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, user, expired_tokens} =
        UserAccounts.update_user_password(user, %{
          password: "new valid password"
        })

      assert expired_tokens == []
      assert is_nil(user.password)
      assert UserAccounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = UserAccounts.generate_user_session_token(user)

      {:ok, _, _} =
        UserAccounts.update_user_password(user, %{
          password: "new valid password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = UserAccounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = UserAccounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = UserAccounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute UserAccounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute UserAccounts.get_user_by_session_token(token)
    end
  end

  describe "get_user_by_magic_link_token/1" do
    setup do
      user = user_fixture()
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      %{user: user, token: encoded_token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = UserAccounts.get_user_by_magic_link_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute UserAccounts.get_user_by_magic_link_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute UserAccounts.get_user_by_magic_link_token(token)
    end
  end

  describe "login_user_by_magic_link/1" do
    test "confirms user and expires tokens" do
      user = unconfirmed_user_fixture()
      refute user.confirmed_at
      {encoded_token, hashed_token} = generate_user_magic_link_token(user)

      assert {:ok, user, [%{token: ^hashed_token}]} =
               UserAccounts.login_user_by_magic_link(encoded_token)

      assert user.confirmed_at
    end

    test "returns user and (deleted) token for confirmed user" do
      user = user_fixture()
      assert user.confirmed_at
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      assert {:ok, ^user, []} = UserAccounts.login_user_by_magic_link(encoded_token)
      # one time use only
      assert {:error, :not_found} = UserAccounts.login_user_by_magic_link(encoded_token)
    end

    test "raises when unconfirmed user has password set" do
      user = unconfirmed_user_fixture()
      {1, nil} = Repo.update_all(User, set: [hashed_password: "hashed"])
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)

      assert_raise RuntimeError, ~r/magic link log in is not allowed/, fn ->
        UserAccounts.login_user_by_magic_link(encoded_token)
      end
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = UserAccounts.generate_user_session_token(user)
      assert UserAccounts.delete_user_session_token(token) == :ok
      refute UserAccounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_login_instructions/2" do
    setup do
      %{user: unconfirmed_user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          UserAccounts.deliver_login_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "login"
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "orgs" do
    alias MyMoney.UserAccounts.Org

    import MyMoney.UserAccountsFixtures, only: [user_scope_fixture: 0]
    import MyMoney.UserAccountsFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_orgs/1 returns all scoped orgs" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      org = org_fixture(scope)
      other_org = org_fixture(other_scope)
      assert UserAccounts.list_orgs(scope) == [org]
      assert UserAccounts.list_orgs(other_scope) == [other_org]
    end

    test "get_org!/2 returns the org with given id" do
      scope = user_scope_fixture()
      org = org_fixture(scope)
      other_scope = user_scope_fixture()
      assert UserAccounts.get_org!(scope, org.id) == org
      assert_raise Ecto.NoResultsError, fn -> UserAccounts.get_org!(other_scope, org.id) end
    end

    test "create_org/2 with valid data creates a org" do
      valid_attrs = %{name: "some name", description: "some description"}
      scope = user_scope_fixture()

      assert {:ok, %Org{} = org} = UserAccounts.create_org(scope, valid_attrs)
      assert org.name == "some name"
      assert org.description == "some description"
      assert org.user_id == scope.user.id
    end

    test "create_org/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = UserAccounts.create_org(scope, @invalid_attrs)
    end

    test "update_org/3 with valid data updates the org" do
      scope = user_scope_fixture()
      org = org_fixture(scope)
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Org{} = org} = UserAccounts.update_org(scope, org, update_attrs)
      assert org.name == "some updated name"
      assert org.description == "some updated description"
    end

    test "update_org/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      org = org_fixture(scope)

      assert_raise MatchError, fn ->
        UserAccounts.update_org(other_scope, org, %{})
      end
    end

    test "update_org/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      org = org_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = UserAccounts.update_org(scope, org, @invalid_attrs)
      assert org == UserAccounts.get_org!(scope, org.id)
    end

    test "delete_org/2 deletes the org" do
      scope = user_scope_fixture()
      org = org_fixture(scope)
      assert {:ok, %Org{}} = UserAccounts.delete_org(scope, org)
      assert_raise Ecto.NoResultsError, fn -> UserAccounts.get_org!(scope, org.id) end
    end

    test "delete_org/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      org = org_fixture(scope)
      assert_raise MatchError, fn -> UserAccounts.delete_org(other_scope, org) end
    end

    test "change_org/2 returns a org changeset" do
      scope = user_scope_fixture()
      org = org_fixture(scope)
      assert %Ecto.Changeset{} = UserAccounts.change_org(scope, org)
    end
  end

  describe "org_members" do
    alias MyMoney.UserAccounts.OrgMember

    import MyMoney.UserAccountsFixtures, only: [user_scope_fixture: 0]
    import MyMoney.UserAccountsFixtures

    @invalid_attrs %{role: nil}

    test "list_org_members/1 returns all scoped org_members" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      org_member = org_member_fixture(scope)
      other_org_member = org_member_fixture(other_scope)
      assert UserAccounts.list_org_members(scope) == [org_member]
      assert UserAccounts.list_org_members(other_scope) == [other_org_member]
    end

    test "get_org_member!/2 returns the org_member with given id" do
      scope = user_scope_fixture()
      org_member = org_member_fixture(scope)
      other_scope = user_scope_fixture()
      assert UserAccounts.get_org_member!(scope, org_member.id) == org_member
      assert_raise Ecto.NoResultsError, fn -> UserAccounts.get_org_member!(other_scope, org_member.id) end
    end

    test "create_org_member/2 with valid data creates a org_member" do
      valid_attrs = %{role: 42}
      scope = user_scope_fixture()

      assert {:ok, %OrgMember{} = org_member} = UserAccounts.create_org_member(scope, valid_attrs)
      assert org_member.role == 42
      assert org_member.user_id == scope.user.id
    end

    test "create_org_member/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = UserAccounts.create_org_member(scope, @invalid_attrs)
    end

    test "update_org_member/3 with valid data updates the org_member" do
      scope = user_scope_fixture()
      org_member = org_member_fixture(scope)
      update_attrs = %{role: 43}

      assert {:ok, %OrgMember{} = org_member} = UserAccounts.update_org_member(scope, org_member, update_attrs)
      assert org_member.role == 43
    end

    test "update_org_member/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      org_member = org_member_fixture(scope)

      assert_raise MatchError, fn ->
        UserAccounts.update_org_member(other_scope, org_member, %{})
      end
    end

    test "update_org_member/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      org_member = org_member_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = UserAccounts.update_org_member(scope, org_member, @invalid_attrs)
      assert org_member == UserAccounts.get_org_member!(scope, org_member.id)
    end

    test "delete_org_member/2 deletes the org_member" do
      scope = user_scope_fixture()
      org_member = org_member_fixture(scope)
      assert {:ok, %OrgMember{}} = UserAccounts.delete_org_member(scope, org_member)
      assert_raise Ecto.NoResultsError, fn -> UserAccounts.get_org_member!(scope, org_member.id) end
    end

    test "delete_org_member/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      org_member = org_member_fixture(scope)
      assert_raise MatchError, fn -> UserAccounts.delete_org_member(other_scope, org_member) end
    end

    test "change_org_member/2 returns a org_member changeset" do
      scope = user_scope_fixture()
      org_member = org_member_fixture(scope)
      assert %Ecto.Changeset{} = UserAccounts.change_org_member(scope, org_member)
    end
  end
end
