defmodule MyMoney.UserAccounts.Scope do
  @moduledoc """
  Defines the scope of the caller to be used throughout the app.

  The `MyMoney.UserAccounts.UserScope` allows public interfaces to receive
  information about the caller, such as if the call is initiated from an
  end-user, and if so, which user. Additionally, such a scope can carry fields
  such as "super user" or other privileges for use as authorization, or to
  ensure specific code paths can only be access for a given scope.

  It is useful for logging as well as for scoping pubsub subscriptions and
  broadcasts when a caller subscribes to an interface or performs a particular
  action.

  Feel free to extend the fields on this struct to fit the needs of
  growing application requirements.
  """

  alias MyMoney.UserAccounts.OrgMember
  alias MyMoney.UserAccounts.User
  alias MyMoney.UserAccounts.Org

  defstruct user: nil, org: nil, org_member: nil

  @doc """
  Creates a scope for the given user.

  Returns nil if no user is given.
  """
  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end

  def for_user(nil), do: nil

  @doc """
  Returns new scope with given org
  """
  def with_org(%__MODULE__{} = scope, %Org{} = org, %OrgMember{} = org_member) do
    %__MODULE__{scope | org: org, org_member: org_member}
  end
end
