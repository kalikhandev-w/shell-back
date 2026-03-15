defmodule Lobby.Repo.Migrations.CreatePackages do
  use Ecto.Migration

  def change do
    create table(:packages, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :string, null: false
      add :type, :string, null: false
      add :hours, :integer
      add :price, :integer, null: false
      add :validity_days, :integer, default: 30
      add :is_active, :boolean, default: true
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:packages, [:club_id])

    create table(:gamer_packages, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :hours_remaining, :decimal
      add :purchased_at, :utc_datetime, null: false
      add :expires_at, :utc_datetime, null: false
      add :status, :string, default: "active"
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all), null: false
      add :package_id, references(:packages, type: :uuid, on_delete: :restrict), null: false
      add :sold_by, references(:users, type: :uuid, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:gamer_packages, [:user_id, :club_id])
    create index(:gamer_packages, [:status])

    # Link sessions to packages
    alter table(:sessions) do
      add :package_id, references(:gamer_packages, type: :uuid, on_delete: :nilify_all)
    end
  end
end
