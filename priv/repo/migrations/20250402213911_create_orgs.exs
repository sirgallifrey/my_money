defmodule MyMoney.Repo.Migrations.CreateOrgs do
  use Ecto.Migration

  def change do
    create table(:orgs) do
      add :name, :string
      add :description, :string

      timestamps(type: :utc_datetime)
    end
  end
end
