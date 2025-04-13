defmodule MyMoney.UserAccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MyMoney.UserAccounts` context.
  """

  import Ecto.Query

  alias MyMoney.UserAccounts
  alias MyMoney.UserAccounts.Scope

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email()
    })
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> UserAccounts.register_user()

    user
  end

  def user_fixture(attrs \\ %{}) do
    user = unconfirmed_user_fixture(attrs)

    token =
      extract_user_token(fn url ->
        UserAccounts.deliver_login_instructions(user, url)
      end)

    {:ok, user, _expired_tokens} = UserAccounts.login_user_by_magic_link(token)

    user
  end

  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  def user_scope_fixture(user) do
    Scope.for_user(user)
  end

  def set_password(user) do
    {:ok, user, _expired_tokens} =
      UserAccounts.update_user_password(user, %{password: valid_user_password()})

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_inserted_at(token, inserted_at) when is_binary(token) do
    MyMoney.Repo.update_all(
      from(t in UserAccounts.UserToken,
        where: t.token == ^token
      ),
      set: [inserted_at: inserted_at]
    )
  end

  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = UserAccounts.UserToken.build_email_token(user, "login")
    MyMoney.Repo.insert!(user_token)
    {encoded_token, user_token.token}
  end

  @doc """
  Generate a org.
  """
  def org_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        description: "some description",
        name: "some name"
      })

    {:ok, org} = MyMoney.UserAccounts.create_org(scope, attrs)
    org
  end

  @doc """
  Generate a org_member.
  """
  def org_member_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        role: 42
      })

    {:ok, org_member} = MyMoney.UserAccounts.create_org_member(scope, attrs)
    org_member
  end
end
