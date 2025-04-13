defmodule MyMoney.UserAccounts.OrgMember do
  use Ecto.Schema
  import Ecto.Changeset
  alias MyMoney.UserAccounts.Org
  alias MyMoney.UserAccounts.Scope

  schema "org_members" do
    field :role, :integer
    field :user_id, :id
    field :org_id, :id

    timestamps(type: :utc_datetime)
  end

  def get_role_int(:owner) do
    10
  end

  def get_role_int(:admin) do
    20
  end

  def get_role_int(:member) do
    30
  end

  def get_role_int(:viewer) do
    40
  end

  def can_edit_org(%Org{} = org, %Scope{} = scope) do
    org.id == scope.org_member.org_id && scope.org_member.role <= 20
  end

  def new_owner_changeset(%Org{} = org, user_scope) do
    org_member =
      %__MODULE__{}
      |> cast(%{role: get_role_int(:owner)}, [:role])
      |> put_change(:org_id, org.id)
      |> put_change(:user_id, user_scope.user.id)

    org_member
  end

  @doc false
  def changeset(org_member, attrs, user_scope) do
    org_member
    |> cast(attrs, [:role])
    |> validate_required([:role])
    |> put_change(:user_id, user_scope.user.id)
    |> put_change(:org_id, user_scope.org.id)
  end
end
