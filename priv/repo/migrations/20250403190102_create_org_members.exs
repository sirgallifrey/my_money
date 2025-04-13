defmodule MyMoney.Repo.Migrations.CreateOrgMembers do
  use Ecto.Migration

  def change do
    create table(:org_members) do
      add :role, :integer
      add :user_id, references(:users, type: :id, on_delete: :delete_all)
      add :org_id, references(:orgs, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end
  end
end
