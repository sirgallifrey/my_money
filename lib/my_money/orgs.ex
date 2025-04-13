defmodule MyMoney.Orgs do
  @moduledoc """
  The Orgs context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Repo
  alias ElixirLS.LanguageServer.Plugins.Phoenix.Scope
  alias MyMoney.Repo

  alias MyMoney.UserAccounts.{User, Org, OrgMember, Scope}

  @doc """
  Returns the list of orgs.

  ## Examples

      iex> list_orgs(scope)
      [%Org{}, ...]

  """
  def list_orgs(%Scope{} = scope) do
    member_orgs = from m in OrgMember, where: m.user_id == ^scope.user.id, select: m.org_id
    Repo.all(from org in Org, where: org.id in subquery(member_orgs))
  end

  @doc """
  Gets a single org.

  Raises `Ecto.NoResultsError` if the Org does not exist.

  ## Examples

      iex> get_org!(123)
      %Org{}

      iex> get_org!(456)
      ** (Ecto.NoResultsError)

  """
  def get_org!(%Scope{} = scope, id) do
    # TODO: ensure only a member can read the org!!
    Repo.get_by!(Org, id: id)
  end

  def get_org_and_membership!(%Scope{} = scope, org_id) do
    # TODO: convert this to a join!
    query =
      from m in OrgMember,
        where: m.user_id == ^scope.user.id and m.org_id == ^org_id,
        join: o in Org,
        on: o.id == m.org_id,
        select: %{org_member: m, org: o}

    result = Repo.one!(query)
    {:ok, result}
    # with {:ok, org_member, org} <-
    #       Ecto.Multi.new()
    #       |> Ecto.Multi.one(
    #         :org_member,
    #         Repo.get_by!(OrgMember, user_id: scope.user.id, org_id: org_id)
    #       )
    #       |> Ecto.Multi.one(:org, Repo.get_by!(Org, id: org_id))
    #       |> Repo.transaction() do
    #  {:ok, org_member, org}
    # end
  end

  @doc """
  Creates a org.

  ## Examples

      iex> create_org(%{field: value})
      {:ok, %Org{}}

      iex> create_org(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_org(%Scope{} = scope, attrs \\ %{}) do
    org_changeset =
      %Org{}
      |> Org.changeset(attrs)

    with {:ok, org, org_member} <-
           Ecto.Multi.new()
           |> Ecto.Multi.insert(:org, org_changeset)
           |> Ecto.Multi.insert(:org_member, fn %{org: org} ->
             OrgMember.new_owner_changeset(org, scope)
           end)
           |> Repo.transaction() do
      {:ok, org, org_member}
    end

    # broadcast(scope, {:created, org})
  end

  @doc """
  Updates a org.

  ## Examples

      iex> update_org(org, %{field: new_value})
      {:ok, %Org{}}

      iex> update_org(org, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_org(%Scope{} = scope, %Org{} = org, attrs) do
    true = OrgMember.can_edit_org(org, scope)

    with {:ok, org = %Org{}} <-
           org
           |> Org.changeset(attrs)
           |> Repo.update() do
      # broadcast(scope, {:updated, org})
      {:ok, org}
    end
  end

  @doc """
  Deletes a org.

  ## Examples

      iex> delete_org(org)
      {:ok, %Org{}}

      iex> delete_org(org)
      {:error, %Ecto.Changeset{}}

  """
  def delete_org(%Scope{} = scope, %Org{} = org) do
    # true = org.user_id == scope.user.id

    with {:ok, org = %Org{}} <-
           Repo.delete(org) do
      # broadcast(scope, {:deleted, org})
      {:ok, org}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking org changes.

  ## Examples

      iex> change_org(org)
      %Ecto.Changeset{data: %Org{}}

  """
  def change_org(%Scope{} = scope, %Org{} = org, attrs \\ %{}) do
    # TODO: do I have to add some checks here?
    Org.changeset(org, attrs)
  end

  alias MyMoney.UserAccounts.OrgMember
  alias MyMoney.UserAccounts.Scope

  @doc """
  Subscribes to scoped notifications about any org_member changes.

  The broadcasted messages match the pattern:

    * {:created, %OrgMember{}}
    * {:updated, %OrgMember{}}
    * {:deleted, %OrgMember{}}

  """
  def subscribe_org_members(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(MyMoney.PubSub, "user:#{key}:org_members")
  end

  @doc """
  Returns the list of org_members.

  ## Examples

      iex> list_org_members(scope)
      [%OrgMember{}, ...]

  """
  def list_org_members(%Scope{} = scope) do
    Repo.all(from org_member in OrgMember, where: org_member.user_id == ^scope.user.id)
  end

  @doc """
  Gets a single org_member.

  Raises `Ecto.NoResultsError` if the Org member does not exist.

  ## Examples

      iex> get_org_member!(123)
      %OrgMember{}

      iex> get_org_member!(456)
      ** (Ecto.NoResultsError)

  """
  def get_org_member!(%Scope{} = scope, id) do
    Repo.get_by!(OrgMember, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a org_member.

  ## Examples

      iex> create_org_member(%{field: value})
      {:ok, %OrgMember{}}

      iex> create_org_member(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_org_member(%Scope{} = scope, attrs \\ %{}) do
    with {:ok, org_member = %OrgMember{}} <-
           %OrgMember{}
           |> OrgMember.changeset(attrs, scope)
           |> Repo.insert() do
      # broadcast(scope, {:created, org_member})
      {:ok, org_member}
    end
  end

  @doc """
  Updates a org_member.

  ## Examples

      iex> update_org_member(org_member, %{field: new_value})
      {:ok, %OrgMember{}}

      iex> update_org_member(org_member, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_org_member(%Scope{} = scope, %OrgMember{} = org_member, attrs) do
    true = org_member.user_id == scope.user.id

    with {:ok, org_member = %OrgMember{}} <-
           org_member
           |> OrgMember.changeset(attrs, scope)
           |> Repo.update() do
      # broadcast(scope, {:updated, org_member})
      {:ok, org_member}
    end
  end

  @doc """
  Deletes a org_member.

  ## Examples

      iex> delete_org_member(org_member)
      {:ok, %OrgMember{}}

      iex> delete_org_member(org_member)
      {:error, %Ecto.Changeset{}}

  """
  def delete_org_member(%Scope{} = scope, %OrgMember{} = org_member) do
    true = org_member.user_id == scope.user.id

    with {:ok, org_member = %OrgMember{}} <-
           Repo.delete(org_member) do
      # broadcast(scope, {:deleted, org_member})
      {:ok, org_member}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking org_member changes.

  ## Examples

      iex> change_org_member(org_member)
      %Ecto.Changeset{data: %OrgMember{}}

  """
  def change_org_member(%Scope{} = scope, %OrgMember{} = org_member, attrs \\ %{}) do
    true = org_member.user_id == scope.user.id

    OrgMember.changeset(org_member, attrs, scope)
  end
end
