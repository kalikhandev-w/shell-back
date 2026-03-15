defmodule Lobby.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :status, :string, default: "active"
      add :duration_minutes, :integer, null: false
      add :total_price_tiyn, :integer, default: 0
      add :started_at, :utc_datetime, null: false
      add :ended_at, :utc_datetime
      add :user_id, references(:users, type: :uuid, on_delete: :nilify_all)
      add :pc_id, references(:pcs, type: :uuid, on_delete: :nilify_all)
      add :tariff_id, references(:tariffs, type: :uuid, on_delete: :nilify_all)
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:sessions, [:user_id])
    create index(:sessions, [:pc_id])
    create index(:sessions, [:club_id])
    create index(:sessions, [:status])
  end
end
