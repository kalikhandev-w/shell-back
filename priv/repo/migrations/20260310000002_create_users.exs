defmodule Lobby.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :email, :string
      add :username, :string
      add :password_hash, :string
      add :steam_id, :string
      add :is_guest, :boolean, default: false
      add :is_admin, :boolean, default: false
      add :balance_tiyn, :integer, default: 0
      add :total_sessions, :integer, default: 0
      add :total_minutes, :integer, default: 0
      add :club_id, references(:clubs, type: :uuid, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email], where: "email IS NOT NULL")
    create unique_index(:users, [:steam_id], where: "steam_id IS NOT NULL")
    create index(:users, [:club_id])
  end
end
